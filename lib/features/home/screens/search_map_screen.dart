import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../../core/models/listing.dart';
import '../../../core/models/project.dart';
import '../../../core/models/zone.dart';
import '../../../core/network/activity_repository.dart';
import '../../../core/network/listing_repository.dart';
import '../../../core/network/project_repository.dart';
import '../../../core/network/zone_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';
import '../../listing/screens/listing_detail_screen.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../widgets/listing_card.dart';
import 'kirkuk_map_style.dart';

/// Kirkuk city center — default camera position for the map filter view.
const _kirkukCenter = LatLng(35.4681, 44.3922);

/// Below this zoom, the map shows real listing pins; above it, real-zone
/// name bubbles — the "get close to a zone" behaviour.
const _zoomThreshold = 14.5;

String _kirkukZoneLabel(String zone) {
  switch (zone) {
    case 'هەموو':
      return 'zones.all'.tr();
    case 'شۆڕجە':
      return 'zones.shorja'.tr();
    case 'ڕاپەرین':
      return 'zones.raparin'.tr();
    case 'ناوەڕاستی شار':
      return 'zones.city_center'.tr();
    case 'ئیمام قاسم':
      return 'zones.imam_qasim'.tr();
    case 'ئازادی':
      return 'zones.azadi'.tr();
    case 'گرناتە':
      return 'zones.granata'.tr();
    case 'شەقامی ٦٠ مەتری':
      return 'zones.sixty_meter_street'.tr();
    default:
      return zone;
  }
}

IconData _iconForType(ListingType type) {
  switch (type) {
    case ListingType.villa:
      return Icons.villa_rounded;
    case ListingType.house:
      return Icons.home_rounded;
    case ListingType.land:
      return Icons.terrain_rounded;
    case ListingType.shop:
      return Icons.storefront_rounded;
  }
}

/// A distinct accent per property type — all inside the emerald/jade family,
/// but different enough that villa/house/land/shop read apart at a glance.
Color _accentForType(ListingType type) {
  switch (type) {
    case ListingType.villa:
      return AppColors.gold;
    case ListingType.house:
      return AppColors.emerald;
    case ListingType.land:
      return AppColors.tierBusiness;
    case ListingType.shop:
      return AppColors.emeraldLight;
  }
}

String _priceLabel(Listing l) => l.purpose == ListingPurpose.rent ? '\$${l.price.toStringAsFixed(0)}' : '\$${(l.price / 1000).toStringAsFixed(0)}K';

class SearchMapScreen extends StatefulWidget {
  const SearchMapScreen({super.key});

  @override
  State<SearchMapScreen> createState() => SearchMapScreenState();
}

class SearchMapScreenState extends State<SearchMapScreen> with TickerProviderStateMixin {
  bool _showMap = true;
  ListingPurpose? _purpose; // null = both
  String _type = 'all';
  String _zone = 'هەموو';
  double _zoom = 11.8;

  // The list view's own quick-filter bar — entirely separate from
  // _type/_zone above, which belong to the map (its bubbles, the full
  // filter sheet, and _zoomToZone's "take me there" navigation). Picking a
  // zone or type here must only ever change what the list shows, never
  // the map's own filter or vice versa.
  String _listType = 'all';
  String _listZone = 'هەموو';

  /// Set when a zone bubble is tapped — spotlights that zone (dims
  /// everything else, draws its outline, shows its name) until the
  /// visitor manually zooms back out, which clears it again.
  String? _focusedZone;

  late final AnimatedMapController _animatedMapController = AnimatedMapController(vsync: this);

  List<Listing> _allListings = [];
  List<Project> _allProjects = [];
  bool _listingsLoading = true;
  bool _listingsFailed = false;

  // The one real, admin-managed zone list — same data the home page's zone
  // row, every zone filter, and registration's zone picker all read. This
  // is now also what draws the map's zone bubbles below, using each zone's
  // own admin-set lat/lng — previously the map drew a second, disconnected
  // set of ~76 OSM-sourced "neighbourhood" points that didn't correspond to
  // real Listing.zone values at all, so tapping one didn't reliably show a
  // zone's actual posts.
  List<Zone> _zones = [];

  // Only zones with a real lat/lng can get a bubble at all.
  List<Zone> get _zonesWithLocation => _zones.where((z) => z.lat != null && z.lng != null).toList();

  Map<String, LatLng> get _zoneCenters => {
        for (final z in _zonesWithLocation) z.name: LatLng(z.lat!, z.lng!),
      };

  // Same set as the map's own bubbles — a zone with no location can't be
  // zoomed to or shown as a bubble, so it shouldn't be offered as a filter
  // choice here either. Keeps this list and the map in lockstep: setting
  // or clearing a zone's lat/lng in admin adds/removes it from both at once.
  List<String> get _zoneNames => ['هەموو', ..._zonesWithLocation.map((z) => z.name)];

  /// How many of this zone's real listings exist right now — shown as the
  /// bubble's count badge, and what makes a zone with actual posts win a
  /// decluttering tie over an empty one.
  Map<String, int> get _zoneListingCounts {
    final counts = <String, int>{};
    for (final l in _allListings) {
      counts[l.zone] = (counts[l.zone] ?? 0) + 1;
    }
    return counts;
  }

  @override
  void initState() {
    super.initState();
    _loadListings();
    _loadProjects();
    _loadZones();
  }

  /// Kept alive by the bottom nav's IndexedStack, so it never rebuilds on
  /// its own when a listing is published elsewhere and the visitor switches
  /// back to this tab — called by HomeShell each time that happens so the
  /// map/list is never showing a stale snapshot from app launch. Also
  /// resets every filter back to its default — leaving this tab and coming
  /// back should never carry over a filter from the last visit.
  void refresh() {
    setState(() {
      _purpose = null;
      _type = 'all';
      _zone = 'هەموو';
      _focusedZone = null;
      _listType = 'all';
      _listZone = 'هەموو';
    });
    _loadListings();
    _loadProjects();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final zones = await context.read<ZoneRepository>().fetchAll();
      if (mounted) setState(() => _zones = zones);
    } catch (_) {
      // Falls back to just "all" — the map and its filters still work.
    }
  }

  Future<void> _loadListings() async {
    if (mounted) setState(() => _listingsLoading = true);
    try {
      final listings = await context.read<ListingRepository>().fetchAll();
      if (mounted) setState(() {
        _allListings = listings;
        _listingsLoading = false;
        _listingsFailed = false;
      });
    } catch (_) {
      // The map itself still works without listing data — just leave the
      // pins/counts empty rather than blocking the whole screen. The list
      // view surfaces this as a retry state instead of a silent blank page.
      if (mounted) setState(() {
        _listingsLoading = false;
        _listingsFailed = true;
      });
    }
  }

  /// Residential complexes get their own pin layer alongside individual
  /// listings — independent of the purpose/type filters (a complex isn't
  /// itself "for rent" or "for sale", its unit types are), but still
  /// scoped to the zone filter like everything else on this screen.
  Future<void> _loadProjects() async {
    try {
      final projects = await context.read<ProjectRepository>().fetchAll();
      if (mounted) setState(() => _allProjects = projects);
    } catch (_) {
      // Same graceful degradation as _loadListings.
    }
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }

  bool get _filtersActive => _purpose != null || _type != 'all' || _zone != 'هەموو';

  List<Listing> get _filtered => _allListings.where((l) {
        if (_purpose != null && l.purpose != _purpose) return false;
        if (_type != 'all' && l.type.name != _type) return false;
        if (_zone != 'هەموو' && l.zone != _zone) return false;
        return true;
      }).toList();

  List<Project> get _filteredProjects => _allProjects.where((p) => _zone == 'هەموو' || p.zone == _zone).toList();

  // The list's own filtered view, driven only by _listType/_listZone —
  // kept fully independent of _filtered/_filteredProjects above, which the
  // map (markers, bubbles, filter sheet) uses.
  List<Listing> get _listFiltered => _allListings.where((l) {
        if (_listType != 'all' && l.type.name != _listType) return false;
        if (_listZone != 'هەموو' && l.zone != _listZone) return false;
        return true;
      }).toList();

  /// A soft, organic (not perfectly circular) outline around a zone's real
  /// content — deterministic per zone name (seeded on its hash, so it's
  /// stable across rebuilds) and sized to comfortably contain every real
  /// listing/project point that zone actually has, not an arbitrary fixed
  /// radius. Empty when the zone has neither a point nor any real content
  /// to draw around.
  List<LatLng> _zoneSpotlightShape(String zone) {
    final zoneCenter = _zoneCenters[zone];
    final points = <LatLng>[
      for (final l in _allListings)
        if (l.zone == zone && l.lat != null && l.lng != null) LatLng(l.lat!, l.lng!),
      for (final p in _allProjects)
        if (p.zone == zone && p.lat != null && p.lng != null) LatLng(p.lat!, p.lng!),
    ];
    final center = zoneCenter ?? (points.isNotEmpty ? points.first : null);
    if (center == null) return const [];

    const distance = Distance();
    var maxDist = 260.0; // a sensible minimum even for a zone with no posts yet
    for (final p in points) {
      final d = distance(center, p);
      if (d > maxDist) maxDist = d;
    }
    final radius = maxDist + 220;
    final rand = Random(zone.hashCode);
    const pointCount = 16;
    return List.generate(pointCount, (i) {
      final angle = (360 / pointCount) * i;
      final wobble = 0.85 + rand.nextDouble() * 0.3;
      return distance.offset(center, radius * wobble, angle);
    });
  }

  /// The dimming mask for a spotlighted zone — a rectangle around the
  /// zone's own shape (padded well past anything the viewport could show
  /// at the zoom levels this is used at) with that shape cut out as a
  /// hole, so only the zone stays bright and everything else fades back.
  /// The hole's own boundary is what reads as the zone's outline.
  ///
  /// Deliberately NOT a world-spanning rectangle — at the map's actual
  /// render zoom, a polygon with corners that far apart tessellates badly
  /// (rendered as a thin sliver instead of covering the screen), which is
  /// exactly what a first pass at this looked like.
  Widget _zoneSpotlightMask(String zone) {
    final shape = _zoneSpotlightShape(zone);
    if (shape.isEmpty) return const SizedBox.shrink();

    final lats = shape.map((p) => p.latitude);
    final lngs = shape.map((p) => p.longitude);
    const pad = 0.4; // degrees — comfortably covers the viewport at any zoom this mask is shown at
    final minLat = lats.reduce((a, b) => a < b ? a : b) - pad;
    final maxLat = lats.reduce((a, b) => a > b ? a : b) + pad;
    final minLng = lngs.reduce((a, b) => a < b ? a : b) - pad;
    final maxLng = lngs.reduce((a, b) => a > b ? a : b) + pad;
    final outerBox = [
      LatLng(minLat, minLng),
      LatLng(minLat, maxLng),
      LatLng(maxLat, maxLng),
      LatLng(maxLat, minLng),
    ];

    return IgnorePointer(
      child: PolygonLayer(
        polygons: [
          Polygon(
            points: outerBox,
            holePointsList: [shape],
            color: Colors.black.withOpacity(0.55),
            borderColor: AppColors.gold,
            borderStrokeWidth: 2.5,
          ),
        ],
      ),
    );
  }

  double _zoneBubbleWidth(String name) => (name.length * 12.5 + 42).clamp(78, 155);

  /// Shrinks the zone bubbles the further out you zoom, so a label never
  /// outgrows the small on-screen area it has to sit in.
  double _bubbleScaleFor(double zoom) {
    const lo = 11.0; // matches MapOptions.minZoom
    final t = ((zoom - lo) / (_zoomThreshold - lo)).clamp(0.0, 1.0);
    return 0.55 + 0.45 * t;
  }

  void _onCameraMove(MapCamera camera, bool hasGesture) {
    final z = camera.zoom;
    if ((z - _zoom).abs() > 0.05) {
      setState(() => _zoom = z);
    } else {
      _zoom = z;
    }
    // Zooming in/out while a zone is spotlighted no longer clears it —
    // only the explicit close (×) button next to the zone's name does,
    // per explicit request.
  }

  /// Zooms to show EVERY real listing/project in this zone at once — not
  /// just the zone's own fixed point at a fixed zoom, which could leave a
  /// post outside the viewport if it sits a bit away from that point —
  /// and spotlights it: everything else dims, the zone's own soft outline
  /// draws around its real content, and its name shows on screen until the
  /// visitor zooms back out. Also switches to map view if the quick-filter
  /// bar is used from the list view — "take me there" has to mean the map.
  void _zoomToZone(String zone) {
    final wasShowingMap = _showMap;
    setState(() {
      _zone = zone;
      _focusedZone = zone;
      _showMap = true;
    });

    void applyZoom() {
      // Fit to the SAME shape the spotlight outline draws (not just the raw
      // listing points, which can be tighter than the shape) — so the zoom
      // always lands exactly where the whole outline is visible, and always
      // through the same smooth animated move regardless of how many real
      // posts this zone has.
      final shape = _zoneSpotlightShape(zone);
      if (shape.isEmpty) return;

      final fitted = CameraFit.bounds(bounds: LatLngBounds.fromPoints(shape), padding: const EdgeInsets.all(40))
          .fit(_animatedMapController.mapController.camera);
      _animatedMapController.centerOnPoint(
        fitted.center,
        zoom: fitted.zoom,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    }

    if (wasShowingMap) {
      // The map was already mounted — apply straight away, exactly as
      // before.
      applyZoom();
    } else {
      // Coming from list view: the FlutterMap widget only mounts once this
      // frame's setState rebuild completes, so the fit/animate call has to
      // wait for that frame instead of running against a controller with
      // nothing attached yet.
      WidgetsBinding.instance.addPostFrameCallback((_) => applyZoom());
    }
  }

  Widget _miniStat(IconData icon, String label) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: palette.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showPreview(Listing listing) {
    final palette = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.45), blurRadius: 30, offset: const Offset(0, 16))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: listing.imageUrls.isEmpty
                        ? Container(color: palette.surfaceElevated)
                        : isNetworkImage(listing.imageUrls.first)
                            ? CachedNetworkImage(imageUrl: listing.imageUrls.first, fit: BoxFit.cover)
                            : Image.file(File(listing.imageUrls.first), fit: BoxFit.cover),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.6)]),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  if (listing.featured)
                    Positioned(
                      left: 14,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: AppColors.ink),
                            const SizedBox(width: 3),
                            Text('listing.featured'.tr(), style: const TextStyle(color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: palette.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(listing.zone, style: TextStyle(color: palette.textSecondary, fontSize: 12))),
                        Text(_priceLabel(listing).replaceAll('K', ',000'), style: TextStyle(color: palette.primary, fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (listing.areaSqm != null) _miniStat(Icons.square_foot_rounded, '${listing.areaSqm!.toStringAsFixed(0)} ${'listing.sqm'.tr()}'),
                        if (listing.areaSqm != null && listing.rooms != null) const SizedBox(width: 16),
                        if (listing.rooms != null) _miniStat(Icons.bed_outlined, '${listing.rooms} ${'listing.rooms'.tr()}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)));
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text('listing.view_details'.tr()),
                        style: ElevatedButton.styleFrom(backgroundColor: palette.primary, foregroundColor: palette.onPrimary, padding: const EdgeInsets.symmetric(vertical: 13)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.read<ActivityRepository>().recordContact(type: 'listing', id: listing.id);
                              launchUrl(Uri.parse('https://wa.me/964${(listing.whatsapp ?? listing.phone ?? '7700000000').replaceFirst(RegExp(r'^0'), '')}'), mode: LaunchMode.externalApplication);
                            },
                            icon: const Icon(Icons.chat, size: 16, color: AppColors.whatsapp),
                            label: Text('listing.contact_whatsapp'.tr(), style: const TextStyle(color: AppColors.whatsapp)),
                            style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.whatsapp.withOpacity(0.4))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.read<ActivityRepository>().recordContact(type: 'listing', id: listing.id);
                              launchUrl(Uri.parse('tel:+964${(listing.phone ?? '7700000000').replaceFirst(RegExp(r'^0'), '')}'));
                            },
                            icon: Icon(Icons.phone, size: 16, color: palette.primary),
                            label: Text('listing.contact_call'.tr(), style: TextStyle(color: palette.primary)),
                            style: OutlinedButton.styleFrom(side: BorderSide(color: palette.primary.withOpacity(0.4))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// (value, icon, label) for the quick property-type row — built fresh
  /// each build so labels stay localized on a language switch.
  List<(String, IconData, String)> get _quickTypes => [
        ('all', Icons.apps_rounded, 'filters.all'.tr()),
        ('house', Icons.home_rounded, 'filters.house'.tr()),
        ('villa', Icons.villa_rounded, 'filters.villa'.tr()),
        ('land', Icons.terrain_rounded, 'filters.land'.tr()),
        ('shop', Icons.storefront_rounded, 'filters.shop'.tr()),
      ];

  /// A thin pill for the list view's quick zone row — this one only
  /// filters the list in place, using its own _listZone (never _zone, which
  /// belongs to the map/filter sheet), with no camera/spotlight and no
  /// view switch — unlike the map's own zone bubbles and the filter
  /// sheet's zone chips, which are "take me to the map" actions. This bar
  /// lives on the list page, so using it should keep you on the list page
  /// and never touch the map's own filter state.
  Widget _quickZoneChip(String zone) {
    final palette = context.palette;
    final sel = zone == _listZone;
    return GestureDetector(
      onTap: () => setState(() => _listZone = zone),
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? palette.primary : palette.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: sel ? Colors.transparent : palette.divider),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.16), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text(
          _kirkukZoneLabel(zone),
          style: TextStyle(color: sel ? palette.onPrimary : palette.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _quickTypeChip(String value, IconData icon, String label) {
    final palette = context.palette;
    final sel = value == _listType;
    return GestureDetector(
      onTap: () => setState(() => _listType = value),
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? palette.primary : palette.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: sel ? Colors.transparent : palette.divider),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.5, color: sel ? palette.onPrimary : palette.textSecondary),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: sel ? palette.onPrimary : palette.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  /// The spotlighted zone's own name badge, rendered as a real map marker
  /// at that zone's point (see the MarkerLayer that places this) — a
  /// close button sits right on it as a manual way out of the spotlight.
  Widget _zoneFocusLabel(String zone) {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.ink.withOpacity(0.9),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.gold.withOpacity(0.6)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place_rounded, size: 14, color: AppColors.goldLight),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'search.zone_focus_label'.tr(args: [zone]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 7),
            GestureDetector(
              onTap: () => setState(() {
                _focusedZone = null;
                _zone = 'هەموو';
              }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A zone's pill: a subtle diagonal gradient (not a flat fill) and a
  /// two-layer shadow for real depth. A zone with actual live listings gets
  /// a thin gold ring and a gentle breathing pulse — the map's own way of
  /// saying "there's something real posted here" — while an empty zone
  /// stays still and plain white-bordered, so attention naturally goes to
  /// the zones that matter instead of everything pulsing at once.
  Widget _zoneBubble(String name, Color color, int unitCount, double scale, VoidCallback onTap) {
    final hasListings = unitCount > 0;
    final darkColor = Color.lerp(color, Colors.black, 0.28)!;
    Widget bubble = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, darkColor]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasListings ? AppColors.gold.withOpacity(0.85) : Colors.white.withOpacity(0.4), width: hasListings ? 1.6 : 1.2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4, offset: const Offset(0, 1)),
            if (hasListings) BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 10, spreadRadius: 0.5),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_rounded, size: 11, color: hasListings ? AppColors.goldLight : Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
              ),
            ),
            if (unitCount > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                child: Text('$unitCount', style: const TextStyle(color: AppColors.ink, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
    );
    if (hasListings) {
      bubble = bubble.animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 1500.ms,
            curve: Curves.easeInOut,
          );
    }
    return Transform.scale(scale: scale, child: bubble);
  }

  /// A distinctive pin-shaped marker for a single unit: the teardrop colour
  /// signals rent vs. sale, the inner badge colour + icon signal the property
  /// type (villa/house/land/shop), and a small star flags featured listings —
  /// three layers of meaning readable before the price tag is even read.
  Widget _unitMarker(Listing listing) {
    final palette = context.palette;
    final pinColor = listing.purpose == ListingPurpose.rent ? palette.primary : AppColors.emeraldDark;
    final badgeColor = _accentForType(listing.type);
    return GestureDetector(
      onTap: () => _showPreview(listing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: pinColor.withOpacity(0.45)),
              boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Text(_priceLabel(listing), style: TextStyle(color: pinColor, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 3),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 42,
                color: pinColor,
                shadows: [Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.6)),
                  child: Icon(_iconForType(listing.type), size: 11, color: Colors.white),
                ),
              ),
              if (listing.featured)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.3)),
                    child: const Icon(Icons.star_rounded, size: 9, color: AppColors.ink),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).entrance();
  }

  /// A residential complex's pin — a distinct square badge (not the
  /// teardrop used for single units) in gold, since a project isn't itself
  /// "for rent" or "for sale" the way one listing is.
  Widget _projectMarker(Project project) {
    final palette = context.palette;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withOpacity(0.6)),
              boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Text(
              '\$${(project.priceFrom / 1000).toStringAsFixed(0)}K+',
              style: const TextStyle(color: AppColors.goldDark, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.apartment_rounded, size: 19, color: AppColors.ink),
          ),
        ],
      ),
    ).entrance();
  }

  /// The bubble shown in place of a tight cluster of pins — tapping it (via
  /// MarkerClusterLayerOptions.zoomToBoundsOnClick) zooms into that group,
  /// which then splits back into individual pins as they no longer overlap.
  Widget _clusterBubble(int count, Color color) {
    final darkColor = Color.lerp(color, Colors.black, 0.25)!;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, darkColor]),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      alignment: Alignment.center,
      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
          duration: 1400.ms,
          curve: Curves.easeInOut,
        );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final palette = context.palette;
            return Container(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(color: palette.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: palette.divider, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text('search.filters_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _purposeChip('filters.all'.tr(), null, onChanged: () => setModalState(() {}))),
                      const SizedBox(width: 6),
                      Expanded(child: _purposeChip('filters.rent'.tr(), ListingPurpose.rent, onChanged: () => setModalState(() {}))),
                      const SizedBox(width: 6),
                      Expanded(child: _purposeChip('filters.sale'.tr(), ListingPurpose.sale, onChanged: () => setModalState(() {}))),
                      const SizedBox(width: 6),
                      Expanded(child: _purposeChip('filters.installment'.tr(), ListingPurpose.installment, onChanged: () => setModalState(() {}))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _typeChip('all', 'filters.all'.tr(), Icons.apps_rounded, onChanged: () => setModalState(() {})),
                      _typeChip('house', 'filters.house'.tr(), Icons.home_rounded, onChanged: () => setModalState(() {})),
                      _typeChip('villa', 'filters.villa'.tr(), Icons.villa_rounded, onChanged: () => setModalState(() {})),
                      _typeChip('land', 'filters.land'.tr(), Icons.terrain_rounded, onChanged: () => setModalState(() {})),
                      _typeChip('shop', 'filters.shop'.tr(), Icons.storefront_rounded, onChanged: () => setModalState(() {})),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('filters.zone'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _zoneNames.map((z) {
                      final sel = z == _zone;
                      return GestureDetector(
                        onTap: () {
                          if (z == 'هەموو') {
                            setState(() => _zone = z);
                            setModalState(() {});
                          } else {
                            // Picking a real zone is a "take me there" action
                            // — close the sheet (its own smooth dismiss
                            // animation) and let the zoom/spotlight play out
                            // on the map underneath. Purpose/type are left
                            // exactly as they were: all three filters
                            // combine (AND together) via _filtered, so
                            // rent+villa picked first and Shorja picked after
                            // shows only rent+villa listings in Shorja — and
                            // if purpose/type were still at their defaults
                            // ("all"), every real post in Shorja shows.
                            _zoomToZone(z);
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(color: sel ? palette.primary : palette.surfaceElevated, borderRadius: BorderRadius.circular(20)),
                          child: Text(_kirkukZoneLabel(z), style: TextStyle(color: sel ? palette.onPrimary : palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final listings = _filtered;
    final projects = _filteredProjects;
    // The list view's own independent filter result — see _listFiltered.
    final listListings = _listFiltered;
    // While a zone is spotlighted, always show real pins (never zone
    // bubbles) — even if the fitted zoom for a large zone happens to land
    // below the normal threshold — so no other zone's bubble competes for
    // attention and only the focused zone's own real posts are visible.
    final showUnits = _focusedZone != null || _zoom >= _zoomThreshold;
    final bubbleScale = _bubbleScaleFor(_zoom);
    final zoneCounts = _zoneListingCounts;
    // Every real zone with a location shows its own bubble, always — no
    // hiding at wide zoom — so the whole city's zones are visible without
    // needing to zoom in first.
    final labelZones = showUnits ? const <Zone>[] : _zonesWithLocation;
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          if (_showMap)
            FlutterMap(
              mapController: _animatedMapController.mapController,
              options: MapOptions(
                initialCenter: _kirkukCenter,
                initialZoom: 11.8,
                minZoom: 11,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                onPositionChanged: (camera, hasGesture) => _onCameraMove(camera, hasGesture),
              ),
              children: [
                ColorFiltered(
                  colorFilter: kirkukTileFilter,
                  child: TileLayer(
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.shikodar.app',
                    maxNativeZoom: 16,
                  ),
                ),
                // Street/place-name labels only once the visitor has zoomed
                // into a zone — keeps the city-wide overview calm and
                // uncluttered so our own neighbourhood shapes read clearly.
                if (showUnits)
                  TileLayer(
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.shikodar.app',
                    maxNativeZoom: 16,
                  ),
                // The spotlight: dims everything outside the focused zone's
                // own real-content outline. Sits above the tiles but below
                // the marker layers, so the zone's own pins stay crisp.
                if (_focusedZone != null) _zoneSpotlightMask(_focusedZone!),
                // Just the real zone names — no territory outlines/shapes,
                // per explicit request. Tapping one calls _zoomToZone, which
                // both zooms in AND sets it as the active zone filter, so
                // every real post belonging to that exact zone (not a
                // distance guess) is what shows once zoomed in.
                if (!showUnits)
                  MarkerLayer(
                    markers: [
                      for (final z in labelZones)
                        Marker(
                          point: LatLng(z.lat!, z.lng!),
                          width: _zoneBubbleWidth(z.name),
                          height: 34,
                          child: _zoneBubble(
                            z.name,
                            zoneColor(z.name.hashCode),
                            zoneCounts[z.name] ?? 0,
                            bubbleScale,
                            () => _zoomToZone(z.name),
                          ),
                        ),
                    ],
                  ),
                // Real marker clustering (not just decluttering) for actual
                // listing/project pins — dense clusters collapse into one
                // count bubble that zooms in on tap, splitting apart
                // smoothly as you zoom further, the same pattern every
                // major map-based real-estate app uses.
                if (showUnits)
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 55,
                      size: const Size(44, 44),
                      alignment: Alignment.center,
                      disableClusteringAtZoom: 18,
                      zoomToBoundsOnClick: true,
                      markers: [
                        for (final l in listings)
                          if (l.lat != null && l.lng != null)
                            Marker(
                              point: LatLng(l.lat!, l.lng!),
                              width: 70,
                              height: 80,
                              alignment: Alignment.topCenter,
                              child: _unitMarker(l),
                            ),
                      ],
                      builder: (context, markers) => _clusterBubble(markers.length, context.palette.primary),
                    ),
                  ),
                if (showUnits)
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 55,
                      size: const Size(44, 44),
                      alignment: Alignment.center,
                      disableClusteringAtZoom: 18,
                      zoomToBoundsOnClick: true,
                      markers: [
                        for (final p in projects)
                          if (p.lat != null && p.lng != null)
                            Marker(
                              point: LatLng(p.lat!, p.lng!),
                              width: 70,
                              height: 76,
                              alignment: Alignment.topCenter,
                              child: _projectMarker(p),
                            ),
                      ],
                      builder: (context, markers) => _clusterBubble(markers.length, AppColors.goldDark),
                    ),
                  ),
                // The spotlighted zone's own name label — a real map
                // marker at the zone's own point, not a fixed screen
                // overlay, so it stays anchored inside the highlighted
                // shape as the visitor pans/zooms instead of floating
                // independently of where the zone actually is.
                if (_focusedZone != null && _zoneCenters[_focusedZone!] != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _zoneCenters[_focusedZone!]!,
                        width: 220,
                        height: 40,
                        child: _zoneFocusLabel(_focusedZone!),
                      ),
                    ],
                  ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: palette.surface.withOpacity(0.75), borderRadius: BorderRadius.circular(6)),
                      child: Text('© Esri — World Light Gray Canvas', style: TextStyle(color: palette.textMuted, fontSize: 8.5)),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 650.ms, curve: Curves.easeOut).scale(
                  begin: const Offset(0.97, 0.97),
                  end: const Offset(1, 1),
                  duration: 650.ms,
                  curve: Curves.easeOut,
                )
          else if (_listingsLoading && _allListings.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (_listingsFailed && _allListings.isEmpty)
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 184, 32, 110),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 40, color: palette.textMuted),
                      const SizedBox(height: 12),
                      Text('search.load_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: palette.textSecondary, fontSize: 13.5)),
                      const SizedBox(height: 14),
                      ElevatedButton(onPressed: _loadListings, child: Text('search.retry'.tr())),
                    ],
                  ),
                ),
              ),
            )
          else
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadListings,
                child: listListings.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(32, 184, 32, 110),
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 60),
                              Icon(Icons.search_off_rounded, size: 40, color: palette.textMuted),
                              const SizedBox(height: 12),
                              Text('search.no_results'.tr(), textAlign: TextAlign.center, style: TextStyle(color: palette.textSecondary, fontSize: 13.5)),
                            ],
                          ),
                        ],
                      )
                    : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 184, 20, 110),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.66,
                  ),
                  itemCount: listListings.length,
                  itemBuilder: (_, i) => ListingCard(listing: listListings[i], animationIndex: i),
                ),
              ),
            ),

          // A soft hint, visible only at the city-wide zoom, nudging the
          // visitor toward the "zoom into a zone" gesture.
          if (_showMap && !showUnits)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: palette.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 16, color: palette.primary),
                      const SizedBox(width: 7),
                      Text('search.zoom_hint'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ).entrance(),

          // Compact header: title, filter icon (opens the full filter
          // sheet), and the map/list toggle — followed by a thin, always-
          // visible quick-filter bar (zones, then property types, each its
          // own horizontal scroll) for the two things worth changing
          // without opening the sheet at all. The map itself stays fully
          // visible right from the top of the page either way. In list
          // mode this sits on an opaque background of its own so the
          // scrolling posts disappear behind it instead of bleeding
          // through the gaps between the title row and the chip rows.
          SafeArea(
            child: Container(
              width: double.infinity,
              decoration: !_showMap
                  ? BoxDecoration(
                      color: palette.background,
                      boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6))],
                    )
                  : null,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('search.map_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.start),
                      ),
                      _filterIconButton(),
                      const SizedBox(width: 8),
                      _viewToggle(),
                    ],
                  ),
                  if (!_showMap) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 30,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: _zoneNames.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => _quickZoneChip(_zoneNames[i]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: _quickTypes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => _quickTypeChip(_quickTypes[i].$1, _quickTypes[i].$2, _quickTypes[i].$3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).entrance(),

        ],
      ),
    );
  }

  Widget _filterIconButton() {
    final palette = context.palette;
    final active = _filtersActive;
    return GestureDetector(
      onTap: _openFilterSheet,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? palette.primary : palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.divider),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.tune_rounded, size: 19, color: active ? palette.onPrimary : palette.textSecondary),
            if (active)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle, border: Border.all(color: palette.surface, width: 1.5)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _viewToggle() {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          _toggleBtn(Icons.map_outlined, _showMap, () => setState(() => _showMap = true)),
          _toggleBtn(Icons.view_list_outlined, !_showMap, () => setState(() => _showMap = false)),
        ],
      ),
    );
  }

  Widget _toggleBtn(IconData icon, bool selected, VoidCallback onTap) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: selected ? palette.primary : Colors.transparent, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 18, color: selected ? palette.onPrimary : palette.textSecondary),
      ),
    );
  }

  Widget _purposeChip(String label, ListingPurpose? value, {VoidCallback? onChanged}) {
    final palette = context.palette;
    final selected = _purpose == value;
    return GestureDetector(
      onTap: () {
        setState(() => _purpose = value);
        onChanged?.call();
      },
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.primary : palette.surfaceElevated,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(label, style: TextStyle(color: selected ? palette.onPrimary : palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _typeChip(String value, String label, IconData icon, {VoidCallback? onChanged}) {
    final palette = context.palette;
    final selected = _type == value;
    return GestureDetector(
      onTap: () {
        setState(() => _type = value);
        onChanged?.call();
      },
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.primary : palette.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? palette.onPrimary : palette.textSecondary),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: selected ? palette.onPrimary : palette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
