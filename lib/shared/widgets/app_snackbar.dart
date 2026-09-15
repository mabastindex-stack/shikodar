import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// One consistent, on-brand snackbar for the whole app — floating, rounded,
/// icon-led, with a colored accent — instead of Flutter's plain default
/// snackbar, which reads as an out-of-place white banner against our dark
/// surfaces (most visible on the auth screens).
void showAppSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final palette = context.palette;
  final accent = isError ? palette.error : palette.success;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withOpacity(0.5),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
