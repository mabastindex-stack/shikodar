import 'package:flutter/material.dart';

/// The MULK brand mark — the real logo artwork (assets/branding), not a
/// code-drawn shape. Kept as a small reusable widget (rather than inlining
/// `Image.asset` at each call site) so every screen that shows the mark
/// stays in sync if the artwork or its styling ever changes again.
class ShikodarMark extends StatelessWidget {
  const ShikodarMark({
    super.key,
    this.size = 108,
    this.progress = 1,
    this.showShadow = true,
  });

  final double size;

  /// Unused now that the mark is a static image rather than a hand-drawn,
  /// progressively-revealed path — kept only so existing call sites don't
  /// need to change.
  final double progress;

  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;
    return Semantics(
      image: true,
      label: 'MULK',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            'assets/branding/app_icon_transparent.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
