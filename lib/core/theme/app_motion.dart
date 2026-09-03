import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// One motion language for the whole product.
class AppMotion {
  AppMotion._();

  static const Duration quick = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration expressive = Duration(milliseconds: 650);
  static const Duration splashEntrance = Duration(milliseconds: 2100);
  static const Duration splashExit = Duration(milliseconds: 820);

  static const Curve enter = Cubic(0.16, 1, 0.3, 1);
  static const Curve exit = Cubic(0.7, 0, 0.84, 0);
  static const Curve emphasized = Cubic(0.22, 1, 0.36, 1);

  static bool reduce(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// One staggered-entrance recipe for every list/grid/column in the app —
/// a soft rise + fade, delayed by [index] so items cascade in instead of
/// popping together. Use on cards, list tiles, form fields — anything that
/// appears as part of a group when a screen first builds.
extension AppEntranceMotion on Widget {
  Widget entrance({
    int index = 0,
    Duration delay = const Duration(milliseconds: 60),
    Duration base = Duration.zero,
  }) {
    return animate(delay: base + delay * index)
        .fadeIn(duration: 360.ms, curve: AppMotion.enter)
        .slideY(begin: 0.08, end: 0, duration: 420.ms, curve: AppMotion.emphasized);
  }
}
