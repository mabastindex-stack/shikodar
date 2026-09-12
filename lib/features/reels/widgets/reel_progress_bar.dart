import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../core/theme/app_colors.dart';

/// A thin, story-style progress track for the currently active reel.
class ReelProgressBar extends StatelessWidget {
  final Player? player;
  const ReelProgressBar({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final p = player;
    if (p == null) {
      return Container(height: 3, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)));
    }
    return StreamBuilder<Duration>(
      stream: p.stream.position,
      initialData: p.state.position,
      builder: (context, snapshot) {
        final total = p.state.duration.inMilliseconds;
        final pos = (snapshot.data ?? Duration.zero).inMilliseconds;
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
