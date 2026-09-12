import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/listing_image.dart';

/// Plays a single reel's video: autoplay+loop when [isActive], paused
/// otherwise (used so only the on-screen reel in the vertical PageView ever
/// plays). Tap toggles play/pause with a brief center icon flash. The
/// listing's real photo shows underneath at all times — while the video
/// buffers, and as a graceful fallback if playback ever fails — so the
/// screen is never just a dark box.
///
/// Built on media_kit rather than video_player: on the device this was
/// debugged against (a Samsung Galaxy S23 Ultra), a Material+InkWell placed
/// directly over a video_player-rendered video produced no ripple at all on
/// tap — proof the touch never reached Flutter's gesture system in that
/// screen region, regardless of which Dart-side widget wrapped it. That
/// pointed at video_player_android's SurfaceProducer output surface being
/// excluded from normal touch dispatch on this hardware. media_kit_video
/// renders through a different Android output path and doesn't share that
/// failure mode.
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
  Player? _player;
  VideoController? _videoController;
  bool _ready = false;
  bool _failed = false;
  bool _showPauseFlash = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final player = Player();
    _player = player;
    _videoController = VideoController(player);
    player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    try {
      // .single loops the current media indefinitely; .loop would restart
      // a whole (here, one-item) playlist instead — same visible effect
      // for us, but .single is the mode actually meant for this.
      await player.setPlaylistMode(PlaylistMode.single);
      await player.setVolume(widget.muted ? 0 : 100);
      final media = isNetworkImage(widget.videoUrl) ? Media(widget.videoUrl) : Media(File(widget.videoUrl).uri.toString());
      await player.open(media, play: false);
      if (mounted) setState(() => _ready = true);
      if (widget.isActive) player.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant ReelVideoPlayer old) {
    super.didUpdateWidget(old);
    if (_player == null) return;
    // Deferred to the next frame so a play()/pause() triggered from here
    // (didUpdateWidget runs mid-build) never lands while the framework is
    // still in the middle of building this same subtree.
    final isActive = widget.isActive;
    final wasActive = old.isActive;
    final muted = widget.muted;
    final wasMuted = old.muted;
    if (isActive != wasActive || muted != wasMuted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final p = _player;
        if (p == null) return;
        if (isActive != wasActive) {
          isActive ? p.play() : p.pause();
        }
        if (muted != wasMuted) {
          p.setVolume(muted ? 0 : 100);
        }
      });
    }
  }

  void togglePlayPause() {
    // Closes the reels search keyboard on the same tap, if it was open —
    // tapping the video is the natural "I'm done searching" gesture, and
    // without this the keyboard just sat there until the visitor found
    // the search field again to dismiss it manually.
    FocusManager.instance.primaryFocus?.unfocus();
    final p = _player;
    if (p == null || !_ready) return;
    _isPlaying ? p.pause() : p.play();
    setState(() => _showPauseFlash = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showPauseFlash = false);
    });
  }

  @override
  void dispose() {
    _player?.dispose();
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Real photo always underneath — never a flat black screen.
        _photoBackground(),
        // BoxFit.contain shows the video at its own real aspect ratio — a
        // vertical clip still fills the screen edge to edge, but a
        // horizontal or square one is no longer cropped/zoomed to
        // force-fill a 9:16 frame; the photo behind it fills the rest, the
        // same way TikTok letterboxes a non-vertical video.
        if (_ready && _videoController != null)
          Video(controller: _videoController!, fit: BoxFit.contain, controls: NoVideoControls)
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
        // A transparent tap layer painted OVER the video, not wrapped
        // around it, so it sits above the video in the compositor and
        // actually gets the touch. InkWell (not a bare GestureDetector) so
        // its splash gives real visible proof taps are landing here.
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: togglePlayPause,
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
            ),
          ),
        ),
        if (_showPauseFlash)
          Center(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showPauseFlash ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                  child: Icon(
                    _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Player? get player => _player;
}
