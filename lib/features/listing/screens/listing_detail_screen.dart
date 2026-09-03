import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';
import '../../agency/screens/agency_profile_screen.dart';
import '../../home/screens/favorites_screen.dart';

Map<ListingType, List<(IconData, String)>> get _amenityIcons => {
      ListingType.villa: [
        (Icons.pool_outlined, 'listing_detail.amenity_villa_pool'.tr()),
        (Icons.local_parking_outlined, 'listing_detail.amenity_villa_garage'.tr()),
        (Icons.yard_outlined, 'listing_detail.amenity_villa_garden'.tr()),
        (Icons.security_outlined, 'listing_detail.amenity_villa_security_system'.tr()),
      ],
      ListingType.house: [
        (Icons.local_parking_outlined, 'listing_detail.amenity_house_parking'.tr()),
        (Icons.balcony_outlined, 'listing_detail.amenity_house_balcony'.tr()),
        (Icons.ac_unit_outlined, 'listing_detail.amenity_house_ac'.tr()),
        (Icons.security_outlined, 'listing_detail.amenity_house_security'.tr()),
      ],
      ListingType.land: [
        (Icons.map_outlined, 'listing_detail.amenity_land_flat_topography'.tr()),
        (Icons.electrical_services_outlined, 'listing_detail.amenity_land_electricity_nearby'.tr()),
        (Icons.water_drop_outlined, 'listing_detail.amenity_land_water_nearby'.tr()),
      ],
      ListingType.shop: [
        (Icons.storefront_outlined, 'listing_detail.amenity_shop_large_display'.tr()),
        (Icons.local_parking_outlined, 'listing_detail.amenity_shop_parking'.tr()),
        (Icons.security_outlined, 'listing_detail.amenity_shop_security_camera'.tr()),
      ],
    };

class ListingDetailScreen extends StatefulWidget {
  final Listing listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _galleryController = PageController();
  int _photoIndex = 0;
  Timer? _autoTimer;
  late final int _photoCount;

  @override
  void initState() {
    super.initState();
    _photoCount = widget.listing.imageUrls.isNotEmpty ? widget.listing.imageUrls.length : 1;
    if (_photoCount > 1) {
      _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_galleryController.hasClients) return;
        final next = (_photoIndex + 1) % _photoCount;
        _galleryController.animateToPage(next, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final listing = widget.listing;
    final photos = listing.imageUrls.isNotEmpty ? listing.imageUrls : [''];
    final amenities = _amenityIcons[listing.type] ?? const [];

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SizedBox(
                      height: 340,
                      child: PageView.builder(
                        controller: _galleryController,
                        itemCount: photos.length,
                        onPageChanged: (i) => setState(() => _photoIndex = i),
                        itemBuilder: (_, i) => photos[i].isEmpty
                            ? Container(color: palette.surfaceElevated, child: Icon(Icons.image_outlined, color: palette.textMuted, size: 48))
                            : !isNetworkImage(photos[i])
                                ? Image.file(File(photos[i]), fit: BoxFit.cover)
                                : CachedNetworkImage(
                                    imageUrl: photos[i],
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: palette.surfaceElevated),
                                    errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated, child: Icon(Icons.image_outlined, color: palette.textMuted, size: 48)),
                                  ),
                      ),
                    ),
                    // Bottom scrim so dots/counter always read clearly.
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 70,
                      child: DecoratedBox(
                        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0x66000000)])),
                      ),
                    ),
                    // Photo counter badge.
                    if (photos.length > 1)
                      Positioned(
                        bottom: 14,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_camera_outlined, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('${_photoIndex + 1}/${photos.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    // Dot indicators.
                    if (photos.length > 1)
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(photos.length, (i) {
                            final active = i == _photoIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(color: active ? AppColors.gold : Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(3)),
                            );
                          }),
                        ),
                      ),
                    // Floating top actions.
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _circleBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                          Row(
                            children: [
                              ValueListenableBuilder<Set<String>>(
                                valueListenable: FavoritesStore.ids,
                                builder: (_, ids, __) => _circleBtn(
                                  ids.contains(listing.id) ? Icons.favorite : Icons.favorite_border,
                                  () => FavoritesStore.toggle(listing.id),
                                  color: ids.contains(listing.id) ? AppColors.error : AppColors.ink,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _circleBtn(Icons.ios_share_rounded, () async {
                                await Clipboard.setData(ClipboardData(text: '${listing.title}\n\$${listing.price.toStringAsFixed(0)} — ${listing.zone}'));
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('listing.info_copied'.tr()), behavior: SnackBarBehavior.floating));
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -8))],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 130),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Agency identity — a distinct, clearly-tappable premium card.
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgencyProfileScreen(agency: listing.agency))),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: AppColors.cardShadow,
                              border: Border.all(color: palette.gold.withOpacity(0.30)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                                  child: const Icon(Icons.storefront_rounded, color: AppColors.ink, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(child: Text(listing.agency.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w800))),
                                          if (listing.agency.verified) ...[
                                            const SizedBox(width: 5),
                                            const Icon(Icons.verified_rounded, color: AppColors.goldDark, size: 15),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 12, color: palette.textSecondary),
                                          const SizedBox(width: 3),
                                          Text(listing.zone, style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (listing.agency.rating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                                        const SizedBox(width: 2),
                                        Text(listing.agency.rating!.toStringAsFixed(1), style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: 18),
                        Text(listing.title, style: TextStyle(color: palette.textPrimary, fontSize: 21, fontWeight: FontWeight.w800))
                            .animate(delay: 60.ms)
                            .fadeIn(duration: 320.ms)
                            .slideX(begin: -0.04, end: 0),
                        const SizedBox(height: 18),
                        _priceBlock(listing).animate(delay: 120.ms).fadeIn(duration: 320.ms),
                        const SizedBox(height: 20),
                        _specsRow(listing).animate(delay: 160.ms).fadeIn(duration: 320.ms),

                        if (amenities.isNotEmpty) ...[
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.goldDark),
                              ),
                              const SizedBox(width: 8),
                              Text('listing_detail.amenities_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                            ],
                          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: palette.divider)),
                            child: Column(
                              children: List.generate(amenities.length, (i) {
                                final a = amenities[i];
                                final isLast = i == amenities.length - 1;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                                            child: Icon(a.$1, size: 18, color: AppColors.goldDark),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(a.$2, style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w700))),
                                          const Icon(Icons.check_circle_rounded, size: 17, color: AppColors.whatsapp),
                                        ],
                                      ),
                                    ),
                                    if (!isLast) const Divider(height: 1, indent: 14, endIndent: 14),
                                  ],
                                );
                              }),
                            ),
                          ).animate(delay: 240.ms).fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0),
                        ],

                        const SizedBox(height: 28),
                        Text('listing_detail.description_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800))
                            .animate(delay: 280.ms)
                            .fadeIn(duration: 300.ms),
                        const SizedBox(height: 10),
                        Text(
                          listing.description.trim().isNotEmpty
                              ? listing.description
                              : 'listing_detail.fallback_description'.tr(args: [
                                  listing.type == ListingType.villa
                                      ? 'listing_detail.type_villa_word'.tr()
                                      : listing.type == ListingType.land
                                          ? 'listing_detail.type_land_word'.tr()
                                          : listing.type == ListingType.shop
                                              ? 'listing_detail.type_shop_word'.tr()
                                              : 'listing_detail.type_house_word'.tr(),
                                  listing.zone,
                                ]),
                          style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.7),
                        ).animate(delay: 320.ms).fadeIn(duration: 320.ms),
                    ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Sticky contact bar.
          Positioned(left: 0, right: 0, bottom: 0, child: _contactBar(context, listing)),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color = AppColors.ink}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }

  Widget _priceBlock(Listing listing) {
    final palette = context.palette;
    if (listing.negotiable && listing.priceLow != null && listing.priceHigh != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _priceCol('listing.price_low'.tr(), listing.priceLow!),
            _priceCol('listing.price_mid'.tr(), (listing.priceLow! + listing.priceHigh!) / 2),
            _priceCol('listing.price_final'.tr(), listing.priceHigh!),
          ],
        ),
      );
    }
    return Row(
      children: [
        Text('\$${listing.price.toStringAsFixed(0)}', style: TextStyle(color: palette.primary, fontSize: 26, fontWeight: FontWeight.w800)),
        if (listing.negotiable) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: AppColors.negotiable.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('listing.negotiable'.tr(), style: const TextStyle(color: AppColors.negotiable, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  Widget _priceCol(String label, double value) {
    final palette = context.palette;
    return Column(
        children: [
          Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          Text('\$${value.toStringAsFixed(0)}', style: TextStyle(color: palette.primary, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      );
  }

  Widget _specsRow(Listing listing) {
    final palette = context.palette;
    final specs = <(IconData, String)>[
      if (listing.areaSqm != null) (Icons.square_foot, '${listing.areaSqm!.toStringAsFixed(0)} ${'listing.sqm'.tr()}'),
      if (listing.rooms != null) (Icons.bed_outlined, '${listing.rooms} ${'listing.rooms'.tr()}'),
    ];
    return Wrap(
      spacing: 10,
      children: specs
          .map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s.$1, size: 16, color: palette.gold),
                    const SizedBox(width: 6),
                    Text(s.$2, style: TextStyle(color: palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _amenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.goldDark),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _contactBar(BuildContext context, Listing listing) {
    final palette = context.palette;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(color: palette.background.withOpacity(0.94), border: Border(top: BorderSide(color: palette.divider))),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://wa.me/964${(listing.whatsapp ?? listing.phone ?? '7700000000').replaceFirst(RegExp(r'^0'), '')}'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.chat, size: 18),
                  label: Text('listing.contact_whatsapp'.tr()),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.whatsapp, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:+964${(listing.phone ?? '7700000000').replaceFirst(RegExp(r'^0'), '')}')),
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text('listing.contact_call'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
