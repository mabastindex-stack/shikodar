import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/mock/kirkuk_neighborhoods.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';
import '../../listing/screens/listing_detail_screen.dart';
import '../widgets/listing_card.dart';
import 'kirkuk_map_style.dart';

/// Kirkuk city center — default camera position for the map filter view.
const _kirkukCenter = LatLng(35.4681, 44.3922);

/// Below this zoom, the map shows real listing pins; above/below it toggles
/// between the two neighbourhood tiers below — the "get close to a zone"
/// behaviour.
const _zoomThreshold = 14.5;

/// Below this zoom, only the handful of "major" neighbourhoods are labelled,
/// keeping the widest city view legible; at or above it (but still under
/// [_zoomThreshold]) every real Kirkuk neighbourhood gets its own outline
/// and label.
const _neighborhoodZoomThreshold = 12.6;

// Raw zone values match `Listing.zone` in the mock data (which stays in
// Kurdish) — only the label shown to the user is localized, via
// `_kirkukZoneLabel` below, so filtering keeps working regardless of locale.
const _kirkukZones = ['هەموو', 'شۆڕجە', 'ڕاپەرین', 'ناوەڕاستی شار', 'ئیمام قاسم', 'ئازادی', 'گرناتە', 'شەقامی ٦٠ مەتری'];

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
  State<SearchMapScreen> createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends State<SearchMapScreen> with TickerProviderStateMixin {
  bool _showMap = true;
  ListingPurpose? _purpose; // null = both
  String _type = 'all';
  String _zone = 'هەموو';
  double _zoom = 11.8;

  late final AnimatedMapController _animatedMapController = AnimatedMapController(vsync: this);

  // Used only by the search-filter's zone picker (a handful of names tied to
  // MockData's own `zone` field) — unrelated to the real-neighbourhood map
  // layer below, which covers the whole city regardless of listing data.
  late final Map<String, LatLng> _zoneCenters = _computeZoneCenters();

  // The real, citywide neighbourhood layer — points, their organic outlines
  // (sized off how close their nearest neighbour is, so dense clusters get
  // smaller shapes and sparse ones get bigger, roughly tiling instead of
  // piling on top of each other), and which ones count as "major".
  late final List<LatLng> _nbPoints = kirkukNeighborhoods.map((n) => LatLng(n.lat, n.lng)).toList();
  late final List<double> _nbNearestDist = _computeNearestDistances();
  late final List<List<LatLng>> _nbPolygons = [
    for (var i = 0; i < _nbPoints.length; i++) _organicPolygon(_nbPoints[i], i, _nbNearestDist[i]),
  ];
  late final List<int> _majorIndexes = [
    for (var i = 0; i < kirkukNeighborhoods.length; i++)
      if (kirkukNeighborhoods[i].major) i,
  ];
  late final List<int> _nbUnitCounts = _computeNeighborhoodCounts();

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }

  bool get _filtersActive => _purpose != null || _type != 'all' || _zone != 'هەموو';

  List<Listing> get _filtered => MockData.listings.where((l) {
        if (_purpose != null && l.purpose != _purpose) return false;
        if (_type != 'all' && l.type.name != _type) return false;
        if (_zone != 'هەموو' && l.zone != _zone) return false;
        return true;
      }).toList();

  Map<String, LatLng> _computeZoneCenters() {
    final sums = <String, List<double>>{}; // [latSum, lngSum, count]
    for (final l in MockData.listings) {
      if (l.lat == null || l.lng == null) continue;
      final cur = sums.putIfAbsent(l.zone, () => [0, 0, 0]);
      cur[0] += l.lat!;
      cur[1] += l.lng!;
      cur[2] += 1;
    }
    return sums.map((zone, v) => MapEntry(zone, LatLng(v[0] / v[2], v[1] / v[2])));
  }

  /// Distance (metres) from each neighbourhood point to its single nearest
  /// neighbour — used to size that point's outline so dense clusters of real
  /// quarters don't draw shapes that swallow each other.
  List<double> _computeNearestDistances() {
    const distance = Distance();
    final result = <double>[];
    for (var i = 0; i < _nbPoints.length; i++) {
      var best = double.infinity;
      for (var j = 0; j < _nbPoints.length; j++) {
        if (i == j) continue;
        final d = distance(_nbPoints[i], _nbPoints[j]);
        if (d < best) best = d;
      }
      result.add(best.isFinite ? best : 900);
    }
    return result;
  }

  /// A soft, organic (not perfectly circular) territory outline — deterministic
  /// per point (seeded on its index) so it stays stable across rebuilds, and
  /// sized off [nearestDistMeters] so neighbouring shapes roughly tile instead
  /// of overlapping heavily.
  List<LatLng> _organicPolygon(LatLng center, int index, double nearestDistMeters) {
    final rand = Random(index * 97 + 13);
    const distance = Distance();
    const pointCount = 12;
    final baseRadius = (nearestDistMeters * 0.4).clamp(140, 480);
    return List.generate(pointCount, (i) {
      final angle = (360 / pointCount) * i;
      final wobble = 0.8 + rand.nextDouble() * 0.4;
      return distance.offset(center, baseRadius * wobble, angle);
    });
  }

  /// How many mock listings sit closest to each neighbourhood point (capped
  /// at 3km so far-flung listings don't get claimed by an unrelated
  /// neighbourhood) — shown as the little count badge on its bubble.
  List<int> _computeNeighborhoodCounts() {
    const distance = Distance();
    final counts = List<int>.filled(_nbPoints.length, 0);
    for (final l in MockData.listings) {
      if (l.lat == null || l.lng == null) continue;
      final p = LatLng(l.lat!, l.lng!);
      var bestIndex = -1;
      var bestDist = double.infinity;
      for (var i = 0; i < _nbPoints.length; i++) {
        final d = distance(p, _nbPoints[i]);
        if (d < bestDist) {
          bestDist = d;
          bestIndex = i;
        }
      }
      if (bestIndex >= 0 && bestDist < 3000) counts[bestIndex]++;
    }
    return counts;
  }

  double _zoneBubbleWidth(String name) => (name.length * 12.5 + 42).clamp(78, 155);

  /// Shrinks the neighbourhood bubbles the further out you zoom, so a label
  /// never outgrows the tiny on-screen outline it belongs to. Two segments:
  /// the major-only tier (fewer labels, so a gentler shrink) and the
  /// all-76 tier, which starts noticeably smaller right where the crowd of
  /// labels jumps from ~22 to 76, then grows back to full size as the
  /// visitor zooms in and real screen space opens up between them.
  double _bubbleScaleFor(double zoom) {
    const lo = 11.0; // matches MapOptions.minZoom
    if (zoom < _neighborhoodZoomThreshold) {
      final t = ((zoom - lo) / (_neighborhoodZoomThreshold - lo)).clamp(0.0, 1.0);
      return 0.6 + 0.25 * t;
    }
    final t = ((zoom - _neighborhoodZoomThreshold) / (_zoomThreshold - _neighborhoodZoomThreshold)).clamp(0.0, 1.0);
    return 0.4 + 0.6 * t;
  }

  void _onCameraMove(MapCamera camera) {
    final z = camera.zoom;
    if ((z - _zoom).abs() > 0.05) {
      setState(() => _zoom = z);
    } else {
      _zoom = z;
    }
  }

  void _zoomToZone(String zone) {
    final center = _zoneCenters[zone];
    if (center == null) return;
    setState(() => _zone = zone);
    _animatedMapController.centerOnPoint(
      center,
      zoom: 16,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
    );
  }

  void _zoomToNeighborhood(LatLng point) {
    _animatedMapController.centerOnPoint(
      point,
      zoom: 16,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
    );
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
                            onPressed: () => launchUrl(Uri.parse('https://wa.me/964${(listing.whatsapp ?? listing.phone ?? '7700000000').replaceFirst(RegExp(r'^0'), '')}'), mode: LaunchMode.externalApplication),
                            icon: const Icon(Icons.chat, size: 16, color: AppColors.whatsapp),
                            label: Text('listing.contact_whatsapp'.tr(), style: const TextStyle(color: AppColors.whatsapp)),
                            style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.whatsapp.withOpacity(0.4))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => launchUrl(Uri.parse('tel:+964${(listing.phone ?? '7700000000').replaceFirst(RegExp(r'^0'), '')}')),
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

  Widget _zoneBubble(String name, Color color, int unitCount, double scale, VoidCallback onTap) {
    final bubble = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.4),
          boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place_rounded, size: 11, color: Colors.white),
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
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.28), borderRadius: BorderRadius.circular(20)),
                child: Text('$unitCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.04, 1.04),
          duration: 1500.ms,
          curve: Curves.easeInOut,
        );
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
                    children: _kirkukZones.map((z) {
                      final sel = z == _zone;
                      return GestureDetector(
                        onTap: () {
                          if (z == 'هەموو') {
                            setState(() => _zone = z);
                          } else {
                            _zoomToZone(z);
                          }
                          setModalState(() {});
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
    final showUnits = _zoom >= _zoomThreshold;
    final showAllNeighborhoods = !showUnits && _zoom >= _neighborhoodZoomThreshold;
    final neighborhoodIndexes = showUnits ? const <int>[] : (showAllNeighborhoods ? List.generate(kirkukNeighborhoods.length, (i) => i) : _majorIndexes);
    final bubbleScale = _bubbleScaleFor(_zoom);
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
                onPositionChanged: (camera, hasGesture) => _onCameraMove(camera),
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
                // Real neighbourhood outlines only render once there's enough
                // screen space between them (mid zoom) — at the widest view
                // they'd be a handful of screen-pixels each and the label
                // would spill far outside its own shape, so that tier shows
                // only labels for the best-known quarters, no outlines yet.
                if (showAllNeighborhoods)
                  PolygonLayer(
                    polygons: [
                      for (final i in neighborhoodIndexes)
                        Polygon(
                          points: _nbPolygons[i],
                          color: zoneColor(i).withOpacity(0.16),
                          borderColor: zoneColor(i).withOpacity(0.65),
                          borderStrokeWidth: 2,
                        ),
                    ],
                  ),
                if (!showUnits)
                  MarkerLayer(
                    markers: [
                      for (final i in neighborhoodIndexes)
                        Marker(
                          point: _nbPoints[i],
                          width: _zoneBubbleWidth(kirkukNeighborhoods[i].name),
                          height: 34,
                          child: _zoneBubble(
                            kirkukNeighborhoods[i].name,
                            zoneColor(i),
                            _nbUnitCounts[i],
                            bubbleScale,
                            () => _zoomToNeighborhood(_nbPoints[i]),
                          ),
                        ),
                    ],
                  ),
                if (showUnits)
                  MarkerLayer(
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
          else
            SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 110),
                itemCount: listings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, i) => SizedBox(height: 300, child: ListingCard(listing: listings[i], animationIndex: i)),
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

          // Compact header: title, filter icon (opens the filter sheet),
          // and the map/list toggle — the map itself stays fully visible
          // right from the top of the page.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('search.map_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.start),
                  ),
                  _filterIconButton(),
                  const SizedBox(width: 8),
                  _viewToggle(),
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
