import 'package:flutter/material.dart';

/// Shikodar's cinematic luxury palette.
///
/// Monochrome-emerald by design: warm cream/ivory neutrals carry the page,
/// and every accent — however bright or deep — stays inside the same green
/// family. There is no second hue anywhere in the system.
///
/// The old public names (`gold`, `goldLight`, `goldDark`, `amber`,
/// `goldGradient`) are intentionally kept so the ~50 screens that reference
/// them adopt the new all-emerald identity without a risky rename across the
/// whole codebase — only the values below changed, not the names.
class AppColors {
  AppColors._();

  // Core neutrals — warm, editorial and deliberately not pure white/black.
  static const Color background = Color(0xFFF5F0E7);
  static const Color surface = Color(0xFFFFFDF9);
  static const Color surfaceElevated = Color(0xFFECE6DA);
  static const Color ink = Color(0xFF101312);
  static const Color inkSoft = Color(0xFF2D3431);
  static const Color textSecondary = Color(0xFF6F756F);
  static const Color textMuted = Color(0xFF969B94);
  static const Color divider = Color(0xFFDDD6C9);

  // Dark mode counterparts (kept for the toggle, inverted tones)
  static const Color backgroundDark = Color(0xFF0C1210);
  static const Color surfaceDark = Color(0xFF141C19);
  static const Color surfaceElevatedDark = Color(0xFF1B2723);
  static const Color creamOnDark = Color(0xFFF5F0E7);
  static const Color textSecondaryDark = Color(0xFFAAB4AE);
  static const Color dividerDark = Color(0xFF2B3732);

  // Signature colors — one hue, three depths.
  static const Color emerald = Color(0xFF0E554A);
  static const Color emeraldLight = Color(0xFF2D7569);
  static const Color emeraldDark = Color(0xFF083B34);

  // "Jade" — the luminous, high-chroma accent that replaces gold. Same
  // family as emerald, just brighter, for glows/badges/premium highlights
  // and as the dark-mode primary (where it needs to pop off a near-black bg).
  static const Color gold = Color(0xFF3FAE8F);
  static const Color goldLight = Color(0xFFAEE3CF);
  static const Color goldDark = Color(0xFF0F6B57);
  static const Color amber = gold; // rating stars — jade, not gold

  // Semantic
  static const Color success = Color(0xFF27806D);
  static const Color whatsapp = Color(0xFF1D9E75);
  static const Color priceInk = ink;
  static const Color error = Color(0xFFB85C49);
  static const Color negotiable = Color(0xFF6C9987);

  // Package tier accents (Starter -> Enterprise) — a single ascending ramp
  // from warm stone to deep emerald, jade marking the "premium" step.
  static const Color tierStarter = Color(0xFFB7B0A0);
  static const Color tierBasic = Color(0xFF9C9382);
  static const Color tierBusiness = Color(0xFF6E8C7C);
  static const Color tierPremium = gold;
  static const Color tierEnterprise = emeraldDark;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emeraldLight, emerald, emeraldDark],
    stops: [0, 0.52, 1],
  );

  // "Jade shimmer" — the premium gradient, kept in-family instead of gold.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldLight, goldDark],
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x16083B34), blurRadius: 26, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> floatingShadow = [
    BoxShadow(color: Color(0x26083B34), blurRadius: 34, offset: Offset(0, 16)),
  ];

  // --- Back-compat aliases (screens not yet migrated to the light redesign) ---
  static const Color cream = creamOnDark;
  static const Color priceAccent = amber;
  static const Color backgroundLight = background;
  static const Color surfaceLight = surface;
  static const Color textPrimaryLight = ink;
  static const Color textSecondaryLight = textSecondary;
}
