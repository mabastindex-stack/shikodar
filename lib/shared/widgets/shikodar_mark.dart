import 'package:flutter/material.dart';

/// The MULK brand mark — the real logo artwork (assets/branding), not a
/// code-drawn shape. Rendered on its own transparent PNG (no card/background
/// baked in) so it sits cleanly on whatever surface it's placed over. Kept
/// as a small reusable widget (rather than inlining `Image.asset` at each
/// call site) so every screen that shows the mark stays in sync if the
/// artwork ever changes again.
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

  /// Unused now that the mark is a transparent, irregularly-shaped PNG — a
  /// rectangular drop shadow doesn't read correctly behind it. Kept only so
  /// existing call sites don't need to change.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'MULK',
      child: Image.asset(
        'assets/branding/app_logo_mark.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
