import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/listing_image.dart';

/// Plays a single reel's video: autoplay+loop when [isActive], paused
/// otherwise (used so only the on-screen reel in the vertical PageView ever
/// plays). Tap toggles play/pause with a brief center icon flash. The
/// listing's real photo shows underneath at all times — while the video
/// buffers, and as a graceful fallback if playback ever fails — so the
/// screen is never just a dark box.
class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final bool isActive;
  final bool muted;
  const ReelVideoPlayer({super.key, required this.videoUrl, required this.thumbnailUrl, required this.isActive, required this.muted});

  @override
  State<ReelVideoPlayer> createState() => ReelVideoPlayerState();
}

class ReelVideoPlayerState extends State<ReelVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _showPauseFlash = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = isNetworkImage(widget.videoUrl) ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl)) : VideoPlayerController.file(File(widget.videoUrl));
    _controller = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(widget.muted ? 0 : 1);
      if (mounted) setState(() => _ready = true);
      if (widget.isActive) c.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant ReelVideoPlayer old) {
    super.didUpdateWidget(old);
    if (_controller == null) return;
    if (widget.isActive != old.isActive) {
      widget.isActive ? _controller!.play() : _controller!.pause();
    }
    if (widget.muted != old.muted) {
      _controller!.setVolume(widget.muted ? 0 : 1);
    }
  }

  void togglePlayPause() {
    final c = _controller;
    if (c == null || !_ready) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
      _showPauseFlash = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showPauseFlash = false);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _photoBackground() {
    if (widget.thumbnailUrl.isEmpty) {
      return Container(color: AppColors.ink);
    }
    if (!isNetworkImage(widget.thumbnailUrl)) {
      return Image.file(File(widget.thumbnailUrl), fit: BoxFit.cover, alignment: const Alignment(0, -0.2));
    }
    return CachedNetworkImage(
      imageUrl: widget.thumbnailUrl,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.2),
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, __) => Container(color: AppColors.ink),
      errorWidget: (_, __, ___) => Container(color: AppColors.ink),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: togglePlayPause,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Real photo always underneath — never a flat black screen.
          _photoBackground(),
          if (_ready && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (!_failed)
            const Center(child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.4))
          else
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 15),
                    const SizedBox(width: 6),
                    Text('reels.video_load_failed'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                  ],
                ),
              ),
            ),
          if (_showPauseFlash)
            Center(
              child: AnimatedOpacity(
                opacity: _showPauseFlash ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                  child: Icon(
                    (_controller?.value.isPlaying ?? false) ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  VideoPlayerController? get controller => _controller;
}
