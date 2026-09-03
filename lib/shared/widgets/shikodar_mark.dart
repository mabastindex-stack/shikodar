import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A code-native Shikodar mark: an architectural doorway and three gold dots
/// that subtly echo the Kurdish letter "ش". It stays crisp at every size.
class ShikodarMark extends StatelessWidget {
  const ShikodarMark({
    super.key,
    this.size = 108,
    this.progress = 1,
    this.showShadow = true,
  });

  final double size;
  final double progress;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    return Semantics(
      image: true,
      label: 'Shikodar',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: showShadow
              ? const [
                  BoxShadow(
                    color: Color(0x52083B34),
                    blurRadius: 34,
                    offset: Offset(0, 18),
                  ),
                ]
              : null,
        ),
        child: CustomPaint(
          painter: _ShikodarMarkPainter(progress: value),
        ),
      ),
    );
  }
}

class _ShikodarMarkPainter extends CustomPainter {
  const _ShikodarMarkPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final ivoryPaint = Paint()
      ..color = AppColors.creamOnDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arch = Path()
      ..moveTo(size.width * 0.27, size.height * 0.73)
      ..lineTo(size.width * 0.27, size.height * 0.48)
      ..cubicTo(
        size.width * 0.27,
        size.height * 0.29,
        size.width * 0.73,
        size.height * 0.29,
        size.width * 0.73,
        size.height * 0.48,
      )
      ..lineTo(size.width * 0.73, size.height * 0.73)
      ..lineTo(size.width * 0.58, size.height * 0.73)
      ..lineTo(size.width * 0.58, size.height * 0.52);

    for (final metric in arch.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        ivoryPaint,
      );
    }

    final goldPaint = Paint()..color = AppColors.goldLight;
    final dotsProgress =
        ((progress - 0.58) / 0.42).clamp(0.0, 1.0).toDouble();
    final radius = size.width * 0.029 * dotsProgress;
    final y = size.height * 0.235;
    for (final x in <double>[0.38, 0.5, 0.62]) {
      canvas.drawCircle(Offset(size.width * x, y), radius, goldPaint);
    }

    final threshold =
        ((progress - 0.72) / 0.28).clamp(0.0, 1.0).toDouble();
    final basePaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.80),
      Offset(size.width * (0.34 + 0.32 * threshold), size.height * 0.80),
      basePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShikodarMarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
