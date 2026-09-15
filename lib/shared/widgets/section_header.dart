import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// The icon-badge + title + subtitle row used to introduce a section of
/// content. First established on the home feed; promoted here so every
/// screen in the app shares the exact same section-heading language.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.centered = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// True for a plain, icon-free heading centered on its own (no action
  /// button) — used where the icon badge and left-alignment would compete
  /// with content directly below it, like the zones/property-type sections.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (centered) {
      return Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: palette.primary, size: 19),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: palette.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}
