import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_page_transitions.dart';
import 'app_palette.dart';

const _pageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: ShikodarPageTransitionsBuilder(),
    TargetPlatform.iOS: ShikodarPageTransitionsBuilder(),
    TargetPlatform.windows: ShikodarPageTransitionsBuilder(),
    TargetPlatform.macOS: ShikodarPageTransitionsBuilder(),
    TargetPlatform.linux: ShikodarPageTransitionsBuilder(),
  },
);

class AppTheme {
  AppTheme._();

  /// Warm-ivory editorial theme led by Shikodar emerald.
  /// [fontFamily] is chosen per-locale by AppFonts.forLocale and passed in
  /// from the widget tree so switching languages switches the font too.
  static ThemeData light({String? fontFamily}) {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = const ColorScheme.light(
      primary: AppColors.emerald,
      onPrimary: AppColors.creamOnDark,
      primaryContainer: AppColors.emeraldDark,
      onPrimaryContainer: AppColors.creamOnDark,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.divider,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: scheme,
      pageTransitionsTheme: _pageTransitions,
      extensions: const <ThemeExtension<dynamic>>[AppPalette.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: AppColors.creamOnDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emerald,
          side: const BorderSide(color: AppColors.emerald, width: 1.1),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.emerald, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.ink,
            displayColor: AppColors.ink,
            fontFamily: fontFamily,
          )
          .copyWith(
            headlineLarge: const TextStyle(fontWeight: FontWeight.w800, height: 1.08),
            headlineMedium: const TextStyle(fontWeight: FontWeight.w800, height: 1.12),
            titleLarge: const TextStyle(fontWeight: FontWeight.w700, height: 1.2),
          ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Color(0x1F0E554A),
        elevation: 0,
      ),
      dividerColor: AppColors.divider,
    );
  }

  /// Dark theme, kept for the toggle — inverted tones of the same palette.
  static ThemeData dark({String? fontFamily}) {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = const ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.backgroundDark,
      primaryContainer: AppColors.emerald,
      onPrimaryContainer: AppColors.creamOnDark,
      secondary: AppColors.goldLight,
      onSecondary: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.creamOnDark,
      error: Color(0xFFD77A67),
      onError: AppColors.backgroundDark,
      outline: AppColors.dividerDark,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: scheme,
      pageTransitionsTheme: _pageTransitions,
      extensions: const <ThemeExtension<dynamic>>[AppPalette.dark],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.creamOnDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.backgroundDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevatedDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.creamOnDark,
            displayColor: AppColors.creamOnDark,
            fontFamily: fontFamily,
          )
          .copyWith(
            headlineLarge: const TextStyle(fontWeight: FontWeight.w800, height: 1.08),
            headlineMedium: const TextStyle(fontWeight: FontWeight.w800, height: 1.12),
            titleLarge: const TextStyle(fontWeight: FontWeight.w700, height: 1.2),
          ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: Color(0x2EC5A05E),
        elevation: 0,
      ),
      dividerColor: AppColors.dividerDark,
    );
  }
}
