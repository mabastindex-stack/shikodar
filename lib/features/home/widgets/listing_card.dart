import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';
import '../../agency/screens/agency_profile_screen.dart';
import '../../listing/screens/listing_detail_screen.dart';
import '../screens/favorites_screen.dart';

class ListingCard extends StatefulWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.animationIndex = 0,
  });

  final Listing listing;
  final int animationIndex;

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  bool _pressed = false;

  Color get _tierColor {
    switch (widget.listing.agency.tier) {
      case PackageTier.starter:
        return AppColors.tierStarter;
      case PackageTier.basic:
        return AppColors.tierBasic;
      case PackageTier.business:
        return AppColors.tierBusiness;
      case PackageTier.premium:
        return AppColors.tierPremium;
      case PackageTier.enterprise:
        return AppColors.tierEnterprise;
    }
  }

  void _openDetails() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: AppMotion.expressive,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
          child: ListingDetailScreen(listing: widget.listing),
        ),
      ),
    );
  }

  Future<void> _shareListing() async {
    final listing = widget.listing;
    final text = '${listing.title}\n\$${listing.price.toStringAsFixed(0)} — ${listing.zone}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('listing.info_copied'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final listing = widget.listing;

    return Semantics(
      button: true,
      label: listing.title,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _openDetails,
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1,
          duration: AppMotion.quick,
          curve: AppMotion.enter,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.divider.withOpacity(0.72)),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withOpacity(0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ListingImage(listing: listing),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x26000000), Colors.transparent, Color(0x8A000000)],
                            stops: [0, 0.58, 1],
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: 9,
                        start: 9,
                        child: _PurposeBadge(purpose: listing.purpose),
                      ),
                      PositionedDirectional(
                        top: 9,
                        end: 9,
                        child: Column(
                          children: [
                            ValueListenableBuilder<Set<String>>(
                              valueListenable: FavoritesStore.ids,
                              builder: (_, ids, __) {
                                final favorite = ids.contains(listing.id);
                                return _OverlayButton(
                                  icon: favorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: favorite ? palette.error : AppColors.ink,
                                  onTap: () => FavoritesStore.toggle(listing.id),
                                );
                              },
                            ),
                            const SizedBox(height: 7),
                            _OverlayButton(
                              icon: Icons.ios_share_rounded,
                              color: AppColors.ink,
                              onTap: _shareListing,
                            ),
                          ],
                        ),
                      ),
                      PositionedDirectional(
                        start: 10,
                        end: 10,
                        bottom: 9,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: AppColors.goldLight,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                listing.zone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (listing.agency.rating != null)
                              _RatingBadge(rating: listing.agency.rating!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AgencyProfileScreen(agency: listing.agency),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _tierColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  listing.agency.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.textSecondary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (listing.agency.verified)
                                Icon(Icons.verified_rounded, color: palette.gold, size: 12),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                '\$${listing.price.toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (listing.rooms != null)
                              _MiniSpec(icon: Icons.bed_outlined, label: '${listing.rooms}'),
                            if (listing.areaSqm != null) ...[
                              const SizedBox(width: 6),
                              _MiniSpec(
                                icon: Icons.square_foot_rounded,
                                label: listing.areaSqm!.toStringAsFixed(0),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (55 * widget.animationIndex).ms)
        .fadeIn(duration: 360.ms, curve: AppMotion.enter)
        .slideY(begin: 0.05, end: 0, duration: 360.ms, curve: AppMotion.enter);
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (listing.imageUrls.isEmpty) {
      return ColoredBox(
        color: palette.surfaceElevated,
        child: Icon(Icons.image_outlined, color: palette.textMuted, size: 30),
      );
    }
    if (!isNetworkImage(listing.imageUrls.first)) {
      return Image.file(File(listing.imageUrls.first), fit: BoxFit.cover);
    }
    return CachedNetworkImage(
      imageUrl: listing.imageUrls.first,
      fit: BoxFit.cover,
      fadeInDuration: AppMotion.standard,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: palette.surfaceElevated,
        highlightColor: palette.surface,
        child: ColoredBox(color: palette.surfaceElevated),
      ),
      errorWidget: (_, __, ___) => ColoredBox(
        color: palette.surfaceElevated,
        child: Icon(Icons.image_outlined, color: palette.textMuted, size: 30),
      ),
    );
  }
}

class _PurposeBadge extends StatelessWidget {
  const _PurposeBadge({required this.purpose});

  final ListingPurpose purpose;

  @override
  Widget build(BuildContext context) {
    final isRent = purpose == ListingPurpose.rent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isRent ? AppColors.goldLight : AppColors.emerald,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isRent ? 'filters.rent'.tr() : 'filters.sale'.tr(),
        style: TextStyle(
          color: isRent ? AppColors.emeraldDark : Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 29,
          height: 29,
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: AppColors.goldLight, size: 10),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSpec extends StatelessWidget {
  const _MiniSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: palette.textMuted),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
