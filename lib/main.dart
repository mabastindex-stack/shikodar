import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/session/admin_store.dart';
import 'core/session/business_profile_store.dart';
import 'core/session/user_session.dart';
import 'features/auth/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ku'), // Kurdish Sorani — primary
        Locale('ar'), // Arabic
        Locale('en'), // English
        Locale('tk'), // Turkmen
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ku'),
      startLocale: const Locale('ku'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => UserSession()),
          ChangeNotifierProvider(create: (_) => BusinessProfileStore()),
          ChangeNotifierProvider(create: (_) => AdminStore()),
        ],
        child: const SikodarApp(),
      ),
    ),
  );
}

/// Flutter's built-in Material/Cupertino localizations don't ship strings
/// for Kurdish ('ku') — only easy_localization's OWN delegate (our .tr()
/// strings) understands 'ku'. Without this fallback, any widget that reads
/// MaterialLocalizations directly (AppBar, TextField, etc.) throws when the
/// active locale is 'ku', because GlobalMaterialLocalizations.isSupported
/// returns false for it. We wrap the Global delegate so it reports 'ku' (and
/// our other app locales) as supported, and internally loads Arabic's
/// implementation instead (also RTL, so layout direction stays correct).
class _FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final effective = GlobalMaterialLocalizations.delegate.isSupported(locale) ? locale : const Locale('ar');
    return GlobalMaterialLocalizations.delegate.load(effective);
  }

  @override
  bool shouldReload(_FallbackMaterialLocalizationsDelegate old) => false;
}

class _FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    final effective = GlobalCupertinoLocalizations.delegate.isSupported(locale) ? locale : const Locale('ar');
    return GlobalCupertinoLocalizations.delegate.load(effective);
  }

  @override
  bool shouldReload(_FallbackCupertinoLocalizationsDelegate old) => false;
}

class SikodarApp extends StatelessWidget {
  const SikodarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final fontFamily = AppFonts.forLocale(context.locale);

    return MaterialApp(
      title: 'Şikodar',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        ...context.localizationDelegates,
        GlobalWidgetsLocalizations.delegate,
        const _FallbackMaterialLocalizationsDelegate(),
        const _FallbackCupertinoLocalizationsDelegate(),
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.light(fontFamily: fontFamily),
      darkTheme: AppTheme.dark(fontFamily: fontFamily),
      themeMode: themeProvider.themeMode,
      // ku and ar render RTL automatically via their Locale;
      // Directionality follows context.locale — no manual override needed.
      home: const SplashScreen(),
    );
  }
}
