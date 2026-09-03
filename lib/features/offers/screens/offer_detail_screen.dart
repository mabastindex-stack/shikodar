import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import 'offers_list_screen.dart';

class OfferDetailScreen extends StatefulWidget {
  final Offer offer;
  const OfferDetailScreen({super.key, required this.offer});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _kenBurns;

  @override
  void initState() {
    super.initState();
    // A very slow, continuous zoom on the hero photo — the "cinematic" touch
    // used across the app's other media-forward screens.
    _kenBurns = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _kenBurns.dispose();
    super.dispose();
  }

  Offer get offer => widget.offer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: palette.surface,
            expandedHeight: 260,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _circleBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _kenBurns,
                    builder: (context, child) => Transform.scale(scale: 1 + 0.07 * _kenBurns.value, child: child),
                    child: CachedNetworkImage(
                      imageUrl: offer.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: palette.surfaceElevated),
                      errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.15), Colors.transparent, palette.background],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.45), blurRadius: 26, spreadRadius: 2)],
                      ),
                      child: Icon(offer.icon, color: AppColors.ink, size: 38),
                    ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack).fadeIn(),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
                        child: Text('offers.special_offer_badge'.tr(), style: const TextStyle(color: AppColors.ink, fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(20)),
                        child: Text(offer.audience, style: TextStyle(color: palette.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 16),
                  Text(offer.title, style: TextStyle(color: palette.textPrimary, fontSize: 22, fontWeight: FontWeight.w800))
                      .animate(delay: 60.ms)
                      .fadeIn(duration: 320.ms)
                      .slideX(begin: -0.04, end: 0),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 17, color: AppColors.goldDark),
                        const SizedBox(width: 8),
                        Expanded(child: Text('offers.active_until'.tr(args: [offer.validUntil]), style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 320.ms),
                  const SizedBox(height: 22),
                  Text('offers.details_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)).animate(delay: 140.ms).fadeIn(duration: 300.ms),
                  const SizedBox(height: 8),
                  Text(offer.intro, style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.6))
                      .animate(delay: 170.ms)
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: 16),
                  ...List.generate(offer.highlights.length, (i) => _highlightRow(palette, offer.highlights[i], i)),
                  const SizedBox(height: 30),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => launchUrl(Uri.parse('https://wa.me/9647700000000'), mode: LaunchMode.externalApplication),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
                        ),
                        child: Text('offers.contact_to_redeem'.tr(), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                  ).animate(delay: 480.ms).fadeIn(duration: 320.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightRow(AppPalette palette, String text, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.check_rounded, size: 15, color: AppColors.goldDark),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.5))),
          ],
        ),
      ),
    ).animate(delay: (200 + 70 * index).ms).fadeIn(duration: 320.ms).slideX(begin: 0.06, end: 0);
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 17, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
