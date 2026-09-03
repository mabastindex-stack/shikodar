import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';

/// A thin, story-style progress track for the currently active reel.
class ReelProgressBar extends StatelessWidget {
  final VideoPlayerController? controller;
  const ReelProgressBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) {
      return Container(height: 3, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)));
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (context, value, child) {
        final total = value.duration.inMilliseconds;
        final pos = value.position.inMilliseconds;
        final progress = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 3,
            color: Colors.white.withOpacity(0.28),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(3))),
            ),
          ),
        );
      },
    );
  }
}
