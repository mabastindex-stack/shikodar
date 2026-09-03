import 'package:flutter/material.dart';

import 'app_motion.dart';

/// One cinematic transition for every push/pop in the app.
///
/// Wired into [ThemeData.pageTransitionsTheme] so it applies to every
/// existing `Navigator.push(MaterialPageRoute(...))` call site with zero
/// changes to the ~50 screens that already call it that way — a soft
/// fade + rise + gentle scale on the incoming page, with the page being
/// covered receding and dimming slightly for a sense of depth, instead of
/// the stock platform slide.
class ShikodarPageTransitionsBuilder extends PageTransitionsBuilder {
  const ShikodarPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduce(context)) return child;

    final incoming = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasized,
      reverseCurve: AppMotion.exit,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.emphasized,
      reverseCurve: AppMotion.exit,
    );

    return FadeTransition(
      opacity: incoming,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(incoming),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(incoming),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.55).animate(outgoing),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 0.96).animate(outgoing),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
