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
    final heroImage = package.homeImageUrl ?? package.imageUrl;
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
                  if (package.description != null) ...[
                    const SizedBox(height: 22),
                    Text('packages.details_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)).animate(delay: 140.ms).fadeIn(duration: 300.ms),
                    const SizedBox(height: 8),
                    Text(package.description!, style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.6))
                        .animate(delay: 170.ms)
                        .fadeIn(duration: 300.ms),
                  ],
                  const SizedBox(height: 22),
                  ..._buildDetailRows(context),
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

  /// Logo and video (each only when the package has one) come first as their
  /// own media rows, then the listings/reels limits — same pattern used for
  /// Offer's optional media, all sharing one running animation-delay index.
  List<Widget> _buildDetailRows(BuildContext context) {
    final rows = <Widget>[];
    var index = 0;
    if (package.logoUrl != null) {
      rows.add(_logoHighlightRow(index++));
    }
    if (package.videoUrl != null) {
      rows.add(_videoHighlightRow(context, index++));
    }
    rows.add(_highlightRow(
      package.listingsLimit == null ? 'packages.unlimited_listings'.tr() : 'packages.listings_limit_label'.tr(args: [package.listingsLimit.toString()]),
      index++,
      icon: Icons.home_work_outlined,
    ));
    rows.add(_highlightRow(
      package.reelsLimit == null ? 'packages.unlimited_reels'.tr() : 'packages.reels_limit_label'.tr(args: [package.reelsLimit.toString()]),
      index++,
      icon: Icons.play_circle_outline,
    ));
    return rows;
  }

  Widget _logoHighlightRow(int index) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(imageUrl: package.logoUrl!, width: 44, height: 44, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('packages.logo_highlight'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    ).animate(delay: (200 + 70 * index).ms).fadeIn(duration: 320.ms).slideX(begin: 0.06, end: 0);
  }

  Widget _videoHighlightRow(BuildContext context, int index) {
    final palette = context.palette;
    final thumbnail = package.imageUrl ?? package.homeImageUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PackageVideoPage(videoUrl: package.videoUrl!))),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))]),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: thumbnail != null
                          ? CachedNetworkImage(imageUrl: thumbnail, width: 56, height: 44, fit: BoxFit.cover)
                          : Container(width: 56, height: 44, color: color.withOpacity(0.15)),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('packages.video_highlight'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600))),
                Icon(Icons.chevron_left_rounded, size: 18, color: palette.textMuted),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (200 + 70 * index).ms).fadeIn(duration: 320.ms).slideX(begin: 0.06, end: 0);
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

/// Full-screen playback for a package's promo video — same simple
/// tap-to-play pattern as the offer detail screen's video.
class _PackageVideoPage extends StatefulWidget {
  final String videoUrl;
  const _PackageVideoPage({required this.videoUrl});

  @override
  State<_PackageVideoPage> createState() => _PackageVideoPageState();
}

class _PackageVideoPageState extends State<_PackageVideoPage> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (_ready)
            GestureDetector(
              onTap: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
              child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
            )
          else
            const CircularProgressIndicator(color: Colors.white),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
