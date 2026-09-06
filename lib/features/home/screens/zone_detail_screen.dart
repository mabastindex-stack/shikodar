import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/models/listing.dart';
import '../../../core/network/listing_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../listing/screens/listing_detail_screen.dart';
import '../widgets/filter_bar.dart';
import '../widgets/listing_card.dart';
import 'kirkuk_map_style.dart';

/// Kirkuk city center — fallback camera position when a zone has no
/// geotagged listings yet.
const _kirkukCenter = LatLng(35.4681, 44.3922);

/// Zone names are stored/compared as raw Kurdish (matching `ZoneCardRow`'s
/// data and the shared mock listings), so only the _displayed_ label is
/// localized here — the value passed in from navigation never changes.
String _zoneLabel(String zone) {
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

/// A dedicated page for one Kirkuk zone — its own type/purpose filter at
/// the top, a map/list toggle, and larger listing cards below, reached by
/// tapping a zone card on Home. In map mode, every listing that has a
/// device-picked location shows up as a real pin at its own coordinates —
/// not just somewhere inside the zone.
class ZoneDetailScreen extends StatefulWidget {
  final String zone;
  const ZoneDetailScreen({super.key, required this.zone});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> with TickerProviderStateMixin {
  final _filterState = HomeFilterState();
  List<Listing> _allListings = [];
  bool _isLoading = true;
  bool _showMap = false;

  late final AnimatedMapController _mapController = AnimatedMapController(vsync: this);

  @override
  void initState() {
    super.initState();
    context.read<ListingRepository>().fetchAll().then((listings) {
      if (mounted) setState(() { _allListings = listings; _isLoading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng _mapCenter(List<Listing> listings) {
    final withCoords = listings.where((l) => l.lat != null && l.lng != null).toList();
    if (withCoords.isEmpty) return _kirkukCenter;
    final latSum = withCoords.fold<double>(0, (sum, l) => sum + l.lat!);
    final lngSum = withCoords.fold<double>(0, (sum, l) => sum + l.lng!);
    return LatLng(latSum / withCoords.length, lngSum / withCoords.length);
  }

  void _openDetails(Listing listing) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)));
  }

  Widget _unitMarker(Listing listing) {
    final palette = context.palette;
    final pinColor = listing.purpose == ListingPurpose.rent ? palette.primary : AppColors.emeraldDark;
    final badgeColor = _accentForType(listing.type);
    return GestureDetector(
      onTap: () => _openDetails(listing),
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

  Widget _mapView(List<Listing> listings) {
    final pinned = listings.where((l) => l.lat != null && l.lng != null).toList();
    final hasPins = pinned.isNotEmpty;
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController.mapController,
          options: MapOptions(
            initialCenter: _mapCenter(listings),
            initialZoom: hasPins ? 15 : 12.5,
            minZoom: 11,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
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
            TileLayer(
              urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
              userAgentPackageName: 'com.shikodar.app',
              maxNativeZoom: 16,
            ),
            MarkerLayer(
              markers: [
                for (final l in pinned)
                  Marker(
                    point: LatLng(l.lat!, l.lng!),
                    width: 70,
                    height: 80,
                    alignment: Alignment.topCenter,
                    child: _unitMarker(l),
                  ),
              ],
            ),
          ],
        ),
        if (!hasPins)
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: context.palette.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [BoxShadow(color: context.palette.shadow.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: Text('zone_detail.no_pinned_listings'.tr(), style: TextStyle(color: context.palette.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _viewToggle() {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn(Icons.view_list_outlined, !_showMap, () => setState(() => _showMap = false)),
          _toggleBtn(Icons.map_outlined, _showMap, () => setState(() => _showMap = true)),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: selected ? palette.primary : Colors.transparent, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 17, color: selected ? palette.onPrimary : palette.textSecondary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final listings = _allListings.where((l) {
      if (widget.zone != 'هەموو' && l.zone != widget.zone) return false;
      if (_filterState.type != 'all' && l.type.name != _filterState.type) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_rounded, size: 17, color: palette.gold),
            const SizedBox(width: 6),
            Text(_zoneLabel(widget.zone), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16), child: _viewToggle()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: FilterBar(
              state: _filterState,
              onChanged: () => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: palette.primary))
                : listings.isEmpty
                ? Center(child: Text('zone_detail.no_listings'.tr(), style: TextStyle(color: palette.textSecondary)))
                : _showMap
                ? _mapView(listings).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                    itemCount: listings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => SizedBox(height: 320, child: ListingCard(listing: listings[i], animationIndex: i)),
                  ),
          ),
        ],
      ),
    );
  }
}
