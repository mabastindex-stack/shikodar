import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';
import '../../agency/screens/agency_profile_screen.dart';

/// Detail page for a single unit inside a project — deliberately mirrors
/// ListingDetailScreen's layout (gallery + counter, tappable agency card,
/// price block, specs row, amenities, sticky contact bar) so every property
/// in the app — standalone or inside a project — reads as one design.
class UnitDetailScreen extends StatefulWidget {
  final UnitType unit;
  final Project project;
  const UnitDetailScreen({super.key, required this.unit, required this.project});

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  final _galleryController = PageController();
  int _photoIndex = 0;
  // A UnitType has no id of its own (it's a value nested inside a Project),
  // so it can't plug into the app-wide FavoritesStore (which resolves ids
  // against MockData.listings) without a model change — kept as a local,
  // honest toggle instead of a heart that silently never shows up anywhere.
  bool _isFavorited = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final unit = widget.unit;
    final project = widget.project;
    final photos = unit.images.isNotEmpty ? unit.images : project.images;

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
                        itemBuilder: (_, i) => !isNetworkImage(photos[i])
                            ? Image.file(File(photos[i]), fit: BoxFit.cover)
                            : CachedNetworkImage(
                                imageUrl: photos[i],
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: palette.surfaceElevated),
                                errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated, child: Icon(Icons.image_outlined, color: palette.textMuted, size: 48)),
                              ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 70,
                      child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0x66000000)]))),
                    ),
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
                              _circleBtn(
                                _isFavorited ? Icons.favorite : Icons.favorite_border,
                                () => setState(() => _isFavorited = !_isFavorited),
                                color: _isFavorited ? AppColors.error : AppColors.ink,
                              ),
                              const SizedBox(width: 8),
                              _circleBtn(Icons.flag_outlined, () => _reportUnit(palette)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(color: palette.background, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Agency identity — identical tappable card to ListingDetailScreen.
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgencyProfileScreen(agency: project.agency))),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
                            border: Border.all(color: AppColors.gold.withOpacity(0.18)),
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
                                        Flexible(child: Text(project.agency.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w800))),
                                        if (project.agency.verified) ...[
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
                                        Text(project.zone, style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (project.agency.rating != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                                      const SizedBox(width: 2),
                                      Text(project.agency.rating!.toStringAsFixed(1), style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right_rounded, color: palette.textMuted, size: 20),
                            ],
                          ),
                        ),
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          const Icon(Icons.apartment_rounded, size: 13, color: AppColors.goldDark),
                          const SizedBox(width: 5),
                          Text('unit_detail.part_of_project'.tr(args: [project.name]), style: const TextStyle(color: AppColors.goldDark, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ],
                      ).animate(delay: 40.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 8),
                      Text(unit.name, style: TextStyle(color: palette.textPrimary, fontSize: 21, fontWeight: FontWeight.w800))
                          .animate(delay: 70.ms)
                          .fadeIn(duration: 320.ms)
                          .slideX(begin: -0.04, end: 0),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Text('${'unit_detail.price_from_prefix'.tr()} \$${unit.priceFrom.toStringAsFixed(0)}', style: TextStyle(color: palette.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.negotiable.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(unit.purpose.name == 'rent' ? 'filters.rent'.tr() : 'filters.sale'.tr(), style: const TextStyle(color: AppColors.negotiable, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ).animate(delay: 110.ms).fadeIn(duration: 320.ms),
                      const SizedBox(height: 20),

                      Wrap(
                        spacing: 10,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.square_foot, size: 16, color: AppColors.goldDark),
                                const SizedBox(width: 6),
                                Text(unit.area, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ).animate(delay: 150.ms).fadeIn(duration: 320.ms),

                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.goldDark),
                          ),
                          const SizedBox(width: 8),
                          Text('unit_detail.project_features_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ).animate(delay: 190.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3.0,
                        children: project.amenities.map((a) => _amenityChip(palette, a)).toList(),
                      ).animate(delay: 220.ms).fadeIn(duration: 320.ms),

                      const SizedBox(height: 26),
                      Text('unit_detail.about_unit_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)).animate(delay: 260.ms).fadeIn(duration: 300.ms),
                      const SizedBox(height: 10),
                      Text(unit.description, style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.7)).animate(delay: 290.ms).fadeIn(duration: 320.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _contactBar()),
        ],
      ),
    );
  }

  void _reportUnit(AppPalette palette) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('unit_detail.report_dialog_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('unit_detail.report_dialog_message'.tr(), style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('unit_detail.report_success_snackbar'.tr()), behavior: SnackBarBehavior.floating));
            },
            child: Text('profile.report'.tr(), style: TextStyle(color: palette.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color = AppColors.ink}) {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 17, color: color)),
        ),
      ),
    );
  }

  Widget _amenityChip(AppPalette palette, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.goldDark),
          const SizedBox(width: 7),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _contactBar() {
    final palette = context.palette;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(color: palette.background.withOpacity(0.92), border: Border(top: BorderSide(color: palette.divider))),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://wa.me/9647700000000'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.chat, size: 18),
                  label: Text('listing.contact_whatsapp'.tr()),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.whatsapp, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:+9647700000000')),
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
