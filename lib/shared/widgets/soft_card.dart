import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// The rounded, bordered, softly-shadowed surface used for cards throughout
/// the home feed and auth screens. Promoted here so every screen reaches
/// for the same card language instead of hand-rolling `Container` borders.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.onTap,
    this.elevatedShadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool elevatedShadow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.divider),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withOpacity(elevatedShadow ? 0.22 : 0.12),
            blurRadius: elevatedShadow ? 26 : 16,
            offset: Offset(0, elevatedShadow ? 14 : 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}
