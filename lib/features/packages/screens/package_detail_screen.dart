import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../core/shikodar_contact.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import 'packages_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final Package package;
  final Color color;
  final IconData icon;
  const PackageDetailScreen({super.key, required this.package, required this.color, required this.icon});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _kenBurns;

  @override
  void initState() {
    super.initState();
    _kenBurns = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _kenBurns.dispose();
    super.dispose();
  }

  Package get package => widget.package;
  Color get color => widget.color;
  Color get deepColor => Color.lerp(color, Colors.black, 0.28)!;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // The hero uses the package's own image only — home_image_url gets its
    // own big showcase block further down, per the admin's explicit request
    // to keep the two visually distinct rather than falling back between them.
    final heroImage = package.imageUrl;
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
                  if (heroImage != null)
                    AnimatedBuilder(
                      animation: _kenBurns,
                      builder: (context, child) => Transform.scale(scale: 1 + 0.07 * _kenBurns.value, child: child),
                      child: CachedNetworkImage(
                        imageUrl: heroImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: palette.surfaceElevated),
                        errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated),
                      ),
                    )
                  else
                    DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [color, deepColor]))),
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
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, deepColor]),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.45), blurRadius: 26, spreadRadius: 2)],
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 38),
                    ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack).fadeIn(),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, deepColor]), borderRadius: BorderRadius.circular(20)),
                      child: Text(package.formattedPrice, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ).animate(delay: 120.ms).fadeIn(duration: 300.ms),
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
                  Text(package.title, style: TextStyle(color: palette.textPrimary, fontSize: 22, fontWeight: FontWeight.w800))
                      .animate(delay: 60.ms)
                      .fadeIn(duration: 320.ms)
                      .slideX(begin: -0.04, end: 0),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 17, color: deepColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            package.durationDays == null ? 'packages.unlimited_duration'.tr() : 'packages.duration_days'.tr(args: [package.durationDays.toString()]),
                            style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 320.ms),
                  if (package.homeImageUrl != null) ...[
                    const SizedBox(height: 20),
                    Text('packages.home_image_label'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800))
                        .animate(delay: 130.ms)
                        .fadeIn(duration: 300.ms),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: package.homeImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: palette.surfaceElevated),
                          errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated),
                        ),
                      ),
                    ).animate(delay: 160.ms).fadeIn(duration: 340.ms).slideY(begin: 0.06, end: 0),
                  ],
                  if (package.logoUrl != null) ...[
                    const SizedBox(height: 22),
                    Center(
                      child: Container(
                        width: 128,
                        height: 128,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withOpacity(0.35), width: 2),
                          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.18), blurRadius: 22, offset: const Offset(0, 10))],
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: package.logoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: palette.surfaceElevated),
                            errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated),
                          ),
                        ),
                      ),
                    ).animate(delay: 200.ms).fadeIn(duration: 340.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
                  ],
                  if (package.description != null) ...[
                    const SizedBox(height: 22),
                    Text('packages.details_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)).animate(delay: 220.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: 8),
                    Text(package.description!, style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.6))
                        .animate(delay: 250.ms)
                        .fadeIn(duration: 300.ms),
                  ],
                  if (package.videoUrl != null) ...[
                    const SizedBox(height: 22),
                    Text('packages.video_section_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)).animate(delay: 260.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: 10),
                    _InlineAutoplayVideo(videoUrl: package.videoUrl!).animate(delay: 290.ms).fadeIn(duration: 340.ms).slideY(begin: 0.06, end: 0),
                  ],
                  const SizedBox(height: 22),
                  _highlightRow(
                    package.listingsLimit == null ? 'packages.unlimited_listings'.tr() : 'packages.listings_limit_label'.tr(args: [package.listingsLimit.toString()]),
                    0,
                    icon: Icons.home_work_outlined,
                  ),
                  _highlightRow(
                    package.reelsLimit == null ? 'packages.unlimited_reels'.tr() : 'packages.reels_limit_label'.tr(args: [package.reelsLimit.toString()]),
                    1,
                    icon: Icons.play_circle_outline,
                  ),
                  const SizedBox(height: 30),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => launchUrl(
                        Uri.parse('https://wa.me/$shikodarPhoneDigits?text=${Uri.encodeComponent('packages.whatsapp_message'.tr(args: [package.title]))}'),
                        mode: LaunchMode.externalApplication,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, deepColor]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
                        ),
                        child: Text('packages.contact_to_activate'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
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

  Widget _highlightRow(String text, int index, {IconData icon = Icons.check_rounded}) {
    final palette = context.palette;
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
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 15, color: deepColor),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.5))),
          ],
        ),
      ),
    ).animate(delay: (320 + 70 * index).ms).fadeIn(duration: 320.ms).slideX(begin: 0.06, end: 0);
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

/// Plays a package's promo video right on the page — autoplaying, muted,
/// looping, no tap required — instead of the tap-to-open full-screen
/// player used elsewhere, per the admin's explicit request for this screen.
class _InlineAutoplayVideo extends StatefulWidget {
  final String videoUrl;
  const _InlineAutoplayVideo({required this.videoUrl});

  @override
  State<_InlineAutoplayVideo> createState() => _InlineAutoplayVideoState();
}

class _InlineAutoplayVideoState extends State<_InlineAutoplayVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller = controller;
    controller.initialize().then((_) async {
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.setVolume(0);
      setState(() => _ready = true);
      controller.play();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: (_ready && controller != null) ? controller.value.aspectRatio : 16 / 9,
        child: (_ready && controller != null) ? VideoPlayer(controller) : Container(color: palette.surfaceElevated),
      ),
    );
  }
}
