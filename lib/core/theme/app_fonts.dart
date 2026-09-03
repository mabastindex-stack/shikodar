import 'package:flutter/material.dart';

/// Maps each supported locale to its font family.
/// - Kurdish (ku) and Arabic (ar): K24Bold
/// - English (en): Plus Jakarta Sans — warmer and more premium-feeling than
///   Quicksand's rounded, playful shapes; a better match for the rest of the
///   app's elegant cream/emerald identity.
/// - Turkmen (tk): Quicksand (unchanged)
class AppFonts {
  AppFonts._();

  static const _kurdishArabic = 'K24Bold';
  static const _english = 'PlusJakartaSans';
  static const _turkmen = 'Quicksand';

  static String forLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'ku':
      case 'ar':
        return _kurdishArabic;
      case 'en':
        return _english;
      case 'tk':
        return _turkmen;
      default:
        return _english;
    }
  }
}
