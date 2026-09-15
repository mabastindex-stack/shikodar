import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../features/reels/widgets/reel_video_player.dart';

/// A reel's preview tile for a grid. Uses the real thumbnail image when one
/// exists — cheap, no video decode needed. When it doesn't (a reel created
/// without a generated thumbnail), falls back to a paused, muted live frame
/// of the actual video via [ReelVideoPlayer], so the tile still shows the
/// real reel instead of a generic camera-icon placeholder that gives no clue
/// which reel it is until tapped.
class ReelThumbnailTile extends StatelessWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final Duration duration;
  final VoidCallback? onTap;

  const ReelThumbnailTile({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          thumbnailUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: palette.surfaceElevated),
                  errorWidget: (_, __, ___) => _liveFramePreview(),
                )
              : _liveFramePreview(),
          const Positioned(top: 5, right: 5, child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 17)),
          Positioned(
            left: 5,
            bottom: 5,
            child: Text('${duration.inSeconds}s', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Paused so it never autoplays inside a grid of many tiles — just the
  /// first real frame, enough to tell reels apart at a glance.
  /// IgnorePointer so the player's own tap-to-toggle-play never steals the
  /// tile's onTap (opening the real full-screen player).
  Widget _liveFramePreview() {
    return IgnorePointer(
      child: ReelVideoPlayer(videoUrl: videoUrl, thumbnailUrl: thumbnailUrl, isActive: false, muted: true),
    );
  }
}
