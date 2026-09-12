import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_route_observer.dart';
import 'core/network/activity_repository.dart';
import 'core/network/api_client.dart';
import 'core/network/auth_repository.dart';
import 'core/network/dashboard_repository.dart';
import 'core/network/favorite_repository.dart';
import 'core/network/feedback_repository.dart';
import 'core/network/home_placement_repository.dart';
import 'core/network/listing_repository.dart';
import 'core/network/notification_repository.dart';
import 'core/network/offer_repository.dart';
import 'core/network/project_repository.dart';
import 'core/network/push_repository.dart';
import 'core/network/reel_repository.dart';
import 'core/network/review_repository.dart';
import 'core/network/upload_repository.dart';
import 'core/network/zone_repository.dart';
import 'core/theme/app_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/session/business_profile_store.dart';
import 'core/session/user_session.dart';
import 'features/auth/screens/splash_screen.dart';

/// Runs in a separate isolate when a push arrives while the app is fully
/// closed or backgrounded — must be a top-level function per
/// firebase_messaging's contract. Left empty on purpose: we only ever send
/// plain notification-style pushes, which the OS displays on its own
/// without any app code running; this just registers the isolate.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Not initialized on web — there's no google-services.json equivalent
  // there, and web push (VAPID keys, service workers) is a separate setup
  // we haven't done. PushRepository already no-ops on web to match.
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  final apiClient = await ApiClient.create();
  final authRepository = AuthRepository(apiClient);
  final listingRepository = ListingRepository(apiClient);
  final projectRepository = ProjectRepository(apiClient);
  final reelRepository = ReelRepository(apiClient);
  final offerRepository = OfferRepository(apiClient);
  final favoriteRepository = FavoriteRepository(apiClient);
  final feedbackRepository = FeedbackRepository(apiClient);
  final uploadRepository = UploadRepository(apiClient);
  final homePlacementRepository = HomePlacementRepository(apiClient);
  final zoneRepository = ZoneRepository(apiClient);
  final notificationRepository = NotificationRepository(apiClient);
  final reviewRepository = ReviewRepository(apiClient);
  final activityRepository = ActivityRepository(apiClient);
  final dashboardRepository = DashboardRepository(apiClient);
  final pushRepository = PushRepository(apiClient);

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
      // Only used before the visitor has ever picked a language (or saved
      // one) — once they choose Kurdish/Arabic/English/Turkmen in Settings,
      // easy_localization persists and restores that choice on every later
      // launch, overriding this default.
      startLocale: const Locale('ar'),
      child: MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: apiClient),
          Provider<AuthRepository>.value(value: authRepository),
          Provider<ListingRepository>.value(value: listingRepository),
          Provider<ProjectRepository>.value(value: projectRepository),
          Provider<ReelRepository>.value(value: reelRepository),
          Provider<OfferRepository>.value(value: offerRepository),
          Provider<FavoriteRepository>.value(value: favoriteRepository),
          Provider<FeedbackRepository>.value(value: feedbackRepository),
          Provider<UploadRepository>.value(value: uploadRepository),
          Provider<HomePlacementRepository>.value(value: homePlacementRepository),
          Provider<ZoneRepository>.value(value: zoneRepository),
          Provider<NotificationRepository>.value(value: notificationRepository),
          Provider<ReviewRepository>.value(value: reviewRepository),
          Provider<ActivityRepository>.value(value: activityRepository),
          Provider<DashboardRepository>.value(value: dashboardRepository),
          Provider<PushRepository>.value(value: pushRepository),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => UserSession()),
          ChangeNotifierProvider(create: (_) => BusinessProfileStore()),
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
      title: 'MULK',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
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
