import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum NavGlyphType { search, reels, projects, profile, home }

/// A hand-drawn, single-family line icon for the bottom nav bar — every
/// glyph in the bar shares the same stroke language (rounded caps/joins,
/// consistent weight) instead of borrowing a generic system icon font.
/// Unselected is a thin muted outline; selected switches to a bolder stroke
/// painted with the brand gradient, so the whole bar reads as one designed
/// object rather than a row of unrelated symbols.
class NavGlyph extends StatelessWidget {
  const NavGlyph({
    super.key,
    required this.type,
    required this.selected,
    required this.mutedColor,
    this.overrideColor,
    this.size = 24,
  });

  final NavGlyphType type;
  final bool selected;
  final Color mutedColor;

  /// When set, both stroke and fill use this flat color instead of the
  /// usual muted-outline/brand-gradient pair — used for the center Home
  /// button, which sits on its own solid gradient circle and always shows
  /// a plain white glyph.
  final Color? overrideColor;

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _NavGlyphPainter(type: type, selected: selected, mutedColor: mutedColor, overrideColor: overrideColor),
    );
  }
}

class _NavGlyphPainter extends CustomPainter {
  _NavGlyphPainter({required this.type, required this.selected, required this.mutedColor, this.overrideColor});

  final NavGlyphType type;
  final bool selected;
  final Color mutedColor;
  final Color? overrideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = size.width * 0.11;
    final inner = size.width - pad * 2;
    Offset p(double x, double y) => Offset(pad + x * inner, pad + y * inner);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * (selected ? 0.085 : 0.072)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..style = PaintingStyle.fill;

    if (overrideColor != null) {
      stroke.color = overrideColor!;
      fill.color = overrideColor!;
    } else if (selected) {
      stroke.shader = AppColors.brandGradient.createShader(Offset.zero & size);
      fill.shader = AppColors.brandGradient.createShader(Offset.zero & size);
    } else {
      stroke.color = mutedColor;
      fill.color = mutedColor;
    }

    switch (type) {
      case NavGlyphType.home:
        final roof = Path()
          ..moveTo(p(0.04, 0.56).dx, p(0.04, 0.56).dy)
          ..lineTo(p(0.5, 0.04).dx, p(0.5, 0.04).dy)
          ..lineTo(p(0.96, 0.56).dx, p(0.96, 0.56).dy);
        canvas.drawPath(roof, stroke);
        final walls = Path()
          ..moveTo(p(0.16, 0.5).dx, p(0.16, 0.5).dy)
          ..lineTo(p(0.16, 0.92).dx, p(0.16, 0.92).dy)
          ..lineTo(p(0.84, 0.92).dx, p(0.84, 0.92).dy)
          ..lineTo(p(0.84, 0.5).dx, p(0.84, 0.5).dy);
        canvas.drawPath(walls, stroke);
        final door = Path()
          ..moveTo(p(0.39, 0.92).dx, p(0.39, 0.92).dy)
          ..lineTo(p(0.39, 0.66).dx, p(0.39, 0.66).dy)
          ..lineTo(p(0.61, 0.66).dx, p(0.61, 0.66).dy)
          ..lineTo(p(0.61, 0.92).dx, p(0.61, 0.92).dy);
        canvas.drawPath(door, stroke);
        break;

      case NavGlyphType.search:
        final center = p(0.4, 0.4);
        final radius = 0.28 * inner;
        canvas.drawCircle(center, radius, stroke);
        final handleStart = center + Offset.fromDirection(0.78, radius);
        final handleEnd = p(0.92, 0.92);
        canvas.drawLine(handleStart, handleEnd, stroke);
        break;

      case NavGlyphType.reels:
        final frame = RRect.fromRectAndRadius(
          Rect.fromLTRB(p(0.06, 0.06).dx, p(0.06, 0.06).dy, p(0.94, 0.94).dx, p(0.94, 0.94).dy),
          Radius.circular(inner * 0.26),
        );
        canvas.drawRRect(frame, stroke);
        final play = Path()
          ..moveTo(p(0.42, 0.34).dx, p(0.42, 0.34).dy)
          ..lineTo(p(0.42, 0.66).dx, p(0.42, 0.66).dy)
          ..lineTo(p(0.68, 0.5).dx, p(0.68, 0.5).dy)
          ..close();
        canvas.drawPath(play, fill);
        break;

      case NavGlyphType.projects:
        final left = RRect.fromRectAndRadius(
          Rect.fromLTRB(p(0.06, 0.4).dx, p(0.06, 0.4).dy, p(0.44, 0.92).dx, p(0.44, 0.92).dy),
          Radius.circular(inner * 0.06),
        );
        final right = RRect.fromRectAndRadius(
          Rect.fromLTRB(p(0.52, 0.16).dx, p(0.52, 0.16).dy, p(0.94, 0.92).dx, p(0.94, 0.92).dy),
          Radius.circular(inner * 0.06),
        );
        canvas.drawRRect(left, stroke);
        canvas.drawRRect(right, stroke);
        final dot = inner * 0.05;
        for (final c in [p(0.19, 0.54), p(0.31, 0.54), p(0.65, 0.32), p(0.81, 0.32), p(0.65, 0.5), p(0.81, 0.5)]) {
          canvas.drawCircle(c, dot, fill);
        }
        break;

      case NavGlyphType.profile:
        canvas.drawCircle(p(0.5, 0.28), 0.17 * inner, stroke);
        final body = Path()
          ..moveTo(p(0.2, 0.92).dx, p(0.2, 0.92).dy)
          ..quadraticBezierTo(p(0.5, 0.56).dx, p(0.5, 0.56).dy, p(0.8, 0.92).dx, p(0.8, 0.92).dy);
        canvas.drawPath(body, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _NavGlyphPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.selected != selected || oldDelegate.mutedColor != mutedColor;
}
