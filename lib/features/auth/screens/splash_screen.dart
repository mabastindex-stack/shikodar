import 'dart:math' as math;

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

/// App entry point — a cinematic wordmark reveal ("MULK" set as one flowing
/// hand-lettered script under a breathing glow, framed above and below by
/// two scattered bands of twenty gently-bobbing, jeweled property-icon
/// medallions) while a previous session restores in the background, then a
/// cross-fade into onboarding or straight into the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _ambient;

  /// Kicked off immediately so it resolves alongside (not after) the brief
  /// wordmark reveal below — a previously signed-in user shouldn't have to
  /// log in again every time the app restarts.
  late final Future<AuthResult?> _restoreSessionFuture;

  /// Flips true right before navigating, so the whole reveal gets a
  /// deliberate soft fade-and-drift goodbye instead of being cut off by
  /// the incoming page's own fade-in.
  bool _leaving = false;

  /// Size of the wordmark stage — wide enough to fan out ten badges per
  /// icon band without crowding.
  static const _stageWidth = 420.0;
  static const _stageHeight = 290.0;

  /// Cycled through to fill both icon bands — repeating the same handful of
  /// property glyphs (like a repeated bird/tree motif on a hand-lettered
  /// badge) reads as a deliberate pattern rather than needing 20 distinct
  /// icons.
  static const _icons = [
    Icons.home_rounded,
    Icons.villa_rounded,
    Icons.apartment_rounded,
    Icons.storefront_rounded,
    Icons.location_on_rounded,
    Icons.terrain_rounded,
  ];

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

  /// One small badge in either icon band (above or below the wordmark) — a
  /// real property-themed glyph in a glass-highlighted, jeweled medallion.
  /// Fades/pops in on entrance, then gently bobs in place for the rest of
  /// the reveal — it never drifts toward the sides, staying strictly in its
  /// horizontal band above or below the lettering.
  Widget _iconBadge({
    required IconData icon,
    required double dx,
    required double dy,
    required int delayMs,
    required double bobPhase,
    double size = 26,
    bool goldVariant = false,
  }) {
    final gradient = goldVariant
        ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark])
        : AppColors.brandGradient;
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, child) {
        final bob = math.sin((_ambient.value + bobPhase) * math.pi) * 3.5;
        return Positioned(
          left: dx,
          top: dy + bob,
          child: child!,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.3),
          boxShadow: [BoxShadow(color: AppColors.emeraldDark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: size * 0.5, color: Colors.white),
            // A small glassy highlight near the top-left, so each medallion
            // reads as a polished bead rather than a flat painted disc.
            Positioned(
              top: size * 0.14,
              left: size * 0.16,
              child: Container(
                width: size * 0.32,
                height: size * 0.16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  gradient: LinearGradient(colors: [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0)]),
                ),
              ),
            ),
          ],
        ),
      )
          .animate(delay: delayMs.ms)
          .fadeIn(duration: 550.ms, curve: AppMotion.emphasized)
          .scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1), curve: AppMotion.emphasized, duration: 620.ms),
    );
  }

  /// Twenty of [_iconBadge] laid out as two loose scattered rows — one above
  /// the wordmark, one below — never at its sides. [stageWidth]/[stageHeight]
  /// are the size of the enclosing Stack, used to convert the -1..1 spread
  /// below into actual pixel positions.
  List<Widget> _iconBands({required double stageWidth, required double stageHeight}) {
    const perRow = 10;
    final widgets = <Widget>[];
    for (var row = 0; row < 2; row++) {
      final isTop = row == 0;
      for (var i = 0; i < perRow; i++) {
        final icon = _icons[i % _icons.length];
        final t = i / (perRow - 1); // 0..1 across the row
        final x = stageWidth * (0.06 + t * 0.88) - 13;
        // A gentle scattered arc instead of a razor-straight line — every
        // third badge sits a little further from the wordmark.
        final jitter = (i % 3 == 0) ? 14.0 : (i % 3 == 1 ? 0.0 : 7.0);
        final y = isTop ? jitter : stageHeight - 26 - jitter;
        widgets.add(
          _iconBadge(
            icon: icon,
            dx: x,
            dy: y,
            delayMs: 500 + i * 55 + (isTop ? 0 : 400),
            bobPhase: i * 0.31 + (isTop ? 0 : 0.5),
            size: i.isEven ? 27 : 22,
            goldVariant: i.isOdd,
          ),
        );
      }
    }
    return widgets;
  }

  /// A single tiny twinkling highlight — purely decorative sparkle that
  /// loops for as long as the splash is on screen.
  Widget _sparkle({required Alignment alignment, required int delayMs, required Duration period, double size = 5}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.goldLight,
          boxShadow: [BoxShadow(color: AppColors.goldLight.withOpacity(0.8), blurRadius: size * 1.6)],
        ),
      )
          .animate(delay: delayMs.ms, onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: 0.1, end: 0.95, duration: period, curve: Curves.easeInOut)
          .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.15, 1.15), duration: period, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion = AppMotion.reduce(context);

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
              // Two slowly counter-drifting color washes — emerald and gold —
              // for a richer, more "alive" ambient light than a single tint.
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
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.35 - ambient * 0.16, 0.4),
                    radius: 1.1,
                    colors: [
                      AppColors.goldLight.withOpacity(0.10),
                      Colors.transparent,
                    ],
                    stops: const [0, 1],
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
                          width: _stageWidth,
                          height: _stageHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Twenty icon badges in two scattered bands —
                              // strictly above and below the wordmark, never
                              // at its sides.
                              if (!reduceMotion) ..._iconBands(stageWidth: _stageWidth, stageHeight: _stageHeight),

                              // Soft breathing halo behind the wordmark.
                              Positioned(
                                left: _stageWidth / 2 - 115,
                                top: _stageHeight / 2 - 115,
                                child: Transform.scale(
                                  scale: 1 + glow * 0.1,
                                  child: Container(
                                    width: 230,
                                    height: 230,
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
                              ),

                              if (!reduceMotion) ...[
                                _sparkle(alignment: const Alignment(-0.5, -0.3), delayMs: 1400, period: 1400.ms),
                                _sparkle(alignment: const Alignment(0.55, -0.22), delayMs: 1900, period: 1700.ms, size: 4),
                                _sparkle(alignment: const Alignment(0.48, 0.32), delayMs: 2100, period: 1500.ms),
                                _sparkle(alignment: const Alignment(-0.44, 0.26), delayMs: 1650, period: 1850.ms, size: 4),
                              ],

                              // "MULK" set as one flowing hand-lettered
                              // script — Yellowtail — instead of boxed
                              // block letters, so the connecting swashes
                              // between letters read naturally.
                              Positioned.fill(
                                child: Center(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                                    child: const Text(
                                      'MULK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Yellowtail',
                                        fontSize: 108,
                                        height: 1,
                                      ),
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(delay: 350.ms, duration: 700.ms, curve: AppMotion.emphasized)
                                      .scale(delay: 350.ms, begin: const Offset(0.72, 0.72), end: const Offset(1, 1), duration: 780.ms, curve: AppMotion.emphasized)
                                      .then(delay: 250.ms)
                                      .shimmer(duration: 1300.ms, color: Colors.white.withOpacity(0.7)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.transparent, palette.gold, Colors.transparent],
                          ).createShader(bounds),
                          child: Container(width: 64, height: 2.4, color: Colors.white),
                        ).animate(delay: 1750.ms).fadeIn(duration: 500.ms).scaleX(begin: 0, end: 1, curve: AppMotion.emphasized),
                        const SizedBox(height: 16),
                        Text(
                          'splash.tagline'.tr(),
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        )
                            .animate(delay: 1900.ms)
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
