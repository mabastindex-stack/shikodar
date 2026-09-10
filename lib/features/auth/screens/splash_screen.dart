import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/auth_repository.dart';
import '../../../core/network/favorite_repository.dart';
import '../../../core/network/push_repository.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../home/screens/favorites_screen.dart';
import '../../home/screens/home_shell.dart';
import 'onboarding_screen.dart';

const _hasSeenOnboardingKey = 'has_seen_onboarding';

/// App entry point — a quiet, confident reveal: the real logo artwork large
/// over a softly breathing glow, the app name beneath it (Playfair Display
/// serif for Latin script) and its tagline — both following the visitor's
/// chosen language (English by default before they ever pick one) — nothing
/// else competing for attention, while a previous session restores in the
/// background, then a cross-fade into onboarding or straight into the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;

  /// Kicked off immediately so it resolves alongside (not after) the brief
  /// wordmark reveal below — a previously signed-in user shouldn't have to
  /// log in again every time the app restarts.
  late final Future<AuthResult?> _restoreSessionFuture;

  /// Flips true right before navigating, so the whole reveal gets a
  /// deliberate soft fade-and-drift goodbye instead of being cut off by
  /// the incoming page's own fade-in.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _restoreSessionFuture = context.read<AuthRepository>().restoreSession();
    _ambient = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(AppMotion.splashEntrance);
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool(_hasSeenOnboardingKey) ?? false;
    // Already kicked off in initState, so this just picks up a result that
    // (in practice) finished well before the reveal above did.
    final restored = await _restoreSessionFuture;
    if (!mounted) return;

    if (restored != null) {
      context.read<UserSession>().logIn(
            restored.role,
            name: restored.name,
            agencyId: restored.agencyId,
            tier: restored.tier,
            contractEndDate: restored.contractEndDate,
            logoUrl: restored.logoUrl,
            agencyPhone: restored.agencyPhone,
            agencyWhatsapp: restored.agencyWhatsapp,
          );
      FavoritesStore.loadFromServer(context.read<FavoriteRepository>());
      context.read<PushRepository>().registerDevice();
    }
    if (!mounted) return;

    setState(() => _leaving = true);
    await Future.delayed(AppMotion.splashExit);
    if (!mounted) return;

    // First launch ever: walk through onboarding, then land in the app as
    // a guest. Every launch after that skips straight to the app — no
    // onboarding, no mandatory login. Signing in/registering only happens
    // if the visitor opens the profile tab and asks to.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: AppMotion.splashExit,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
          child: seenOnboarding ? const HomeShell() : const OnboardingScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion = AppMotion.reduce(context);
    final isLatinScript = context.locale.languageCode == 'en' || context.locale.languageCode == 'tk';

    return Scaffold(
      backgroundColor: palette.background,
      body: AnimatedBuilder(
        animation: _ambient,
        builder: (context, child) {
          final ambient = reduceMotion ? 0.5 : _ambient.value;
          final glow = reduceMotion ? 0.5 : _ambient.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              // A single slow-drifting emerald wash — quiet ambient light,
              // nothing busy.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.2 + ambient * 0.16, -0.32),
                    radius: 1.3,
                    colors: [
                      AppColors.emeraldLight.withOpacity(0.18),
                      palette.background,
                      palette.background,
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: _leaving ? 0 : 1,
                duration: AppMotion.splashExit,
                curve: Curves.easeInOutCubic,
                child: AnimatedSlide(
                  offset: _leaving ? const Offset(0, -0.03) : Offset.zero,
                  duration: AppMotion.splashExit,
                  curve: Curves.easeInOutCubic,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Soft breathing halo behind the logo.
                              Transform.scale(
                                scale: 1 + glow * 0.1,
                                child: Container(
                                  width: 260,
                                  height: 260,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.emeraldLight.withOpacity(0.22 + glow * 0.14),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // The real logo artwork, large and unclipped —
                              // nothing else on stage to compete with it.
                              Image.asset(
                                'assets/branding/app_logo_mark.png',
                                width: 220,
                                height: 220,
                                fit: BoxFit.contain,
                              )
                                  .animate()
                                  .fadeIn(duration: 700.ms, curve: AppMotion.emphasized)
                                  .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 780.ms, curve: AppMotion.emphasized),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // The wordmark follows the active app language once
                        // the visitor has picked one (English by default
                        // before that) — set in Playfair Display, an
                        // elegant high-contrast serif, for Latin script;
                        // wide letter-spacing is skipped for Kurdish/Arabic
                        // so it doesn't break their connected letterforms.
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                          child: Text(
                            'app_name'.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: isLatinScript ? 'PlayfairDisplay' : null,
                              fontSize: 64,
                              fontWeight: FontWeight.w800,
                              letterSpacing: isLatinScript ? 1.5 : 0,
                              height: 1,
                            ),
                          ),
                        )
                            .animate(delay: 500.ms)
                            .fadeIn(duration: 650.ms, curve: AppMotion.emphasized)
                            .slideY(begin: 0.25, end: 0, duration: 700.ms, curve: AppMotion.emphasized)
                            .then(delay: 250.ms)
                            .shimmer(duration: 1300.ms, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(height: 10),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.transparent, palette.gold, Colors.transparent],
                          ).createShader(bounds),
                          child: Container(width: 64, height: 2.4, color: Colors.white),
                        ).animate(delay: 1050.ms).fadeIn(duration: 500.ms).scaleX(begin: 0, end: 1, curve: AppMotion.emphasized),
                        const SizedBox(height: 16),
                        // Same story for the tagline — localized, not
                        // hardcoded English, so it switches the moment the
                        // visitor picks a language in Settings.
                        Text(
                          'splash.tagline'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.gold,
                            fontFamily: isLatinScript ? 'PlayfairDisplay' : null,
                            fontStyle: isLatinScript ? FontStyle.italic : FontStyle.normal,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: isLatinScript ? 0.4 : 0.2,
                          ),
                        )
                            .animate(delay: 1200.ms)
                            .fadeIn(duration: 650.ms)
                            .slideY(begin: 0.18, end: 0, curve: AppMotion.emphasized),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
