import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';

/// Premium video showcase — fully automatic: each project's video autoplays
/// muted the moment it's shown, and the carousel advances to the next one
/// every 5 seconds on its own. No tap required.
class HomeVideoShowcase extends StatefulWidget {
  const HomeVideoShowcase({super.key});

  @override
  State<HomeVideoShowcase> createState() => _HomeVideoShowcaseState();
}

class _HomeVideoShowcaseState extends State<HomeVideoShowcase> {
  final _controller = PageController();
  Timer? _autoTimer;
  int _index = 0;

  List<Project> get _videos => mockProjects.where((p) => p.videoUrl.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _videos.length <= 1) return;
      final next = (_index + 1) % _videos.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videos = _videos;
    if (videos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _controller,
        onPageChanged: (i) => setState(() => _index = i),
        itemCount: videos.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _VideoCard(project: videos[i], isActive: i == _index),
        ),
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final Project project;
  final bool isActive;
  const _VideoCard({required this.project, required this.isActive});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? _video;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.project.videoUrl));
    _video = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      if (mounted) setState(() => _ready = true);
      if (widget.isActive) c.play();
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant _VideoCard old) {
    super.didUpdateWidget(old);
    if (_video == null) return;
    if (widget.isActive != old.isActive) {
      widget.isActive ? _video!.play() : _video!.pause();
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final p = widget.project;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emeraldDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withOpacity(0.42),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
          fit: StackFit.expand,
          children: [
            if (_ready && _video != null)
              FittedBox(fit: BoxFit.cover, child: SizedBox(width: _video!.value.size.width, height: _video!.value.size.height, child: VideoPlayer(_video!)))
            else if (!isNetworkImage(p.images.first))
              Image.file(File(p.images.first), fit: BoxFit.cover)
            else
              CachedNetworkImage(
                imageUrl: p.images.first,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: palette.surfaceElevated),
                errorWidget: (_, __, ___) => Container(
                  decoration: const BoxDecoration(gradient: AppColors.brandGradient),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x66000000), Colors.transparent, Color(0x99000000)], stops: [0.0, 0.4, 1.0]),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              left: 14,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      size: 15,
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.agencyName, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.videocam_rounded, size: 11, color: Colors.white), const SizedBox(width: 4), Text('home.project_video_badge'.tr(), style: const TextStyle(color: Colors.white, fontSize: 9.5))]),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text(p.zone, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
