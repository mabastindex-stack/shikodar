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

/// App entry point — a cinematic wordmark reveal ("MULK" cascades in letter
/// by letter, each one a retro stepped-extrusion stack of brand colors,
/// under a breathing glow) orbited by eight jeweled property-icon medallions
/// slowly revolving full-circle around it, while a previous session restores
/// in the background, then a cross-fade into onboarding or straight into
/// the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _orbitSpin;

  /// Kicked off immediately so it resolves alongside (not after) the brief
  /// wordmark reveal below — a previously signed-in user shouldn't have to
  /// log in again every time the app restarts.
  late final Future<AuthResult?> _restoreSessionFuture;

  /// Flips true right before navigating, so the whole reveal gets a
  /// deliberate soft fade-and-drift goodbye instead of being cut off by
  /// the incoming page's own fade-in.
  bool _leaving = false;

  static const _wordmark = ['M', 'U', 'L', 'K'];

  /// Eight badges evenly spaced around a full circle (starting straight up),
  /// so the constellation reads above AND below the wordmark, not just to
  /// its sides.
  static const _orbitIcons = [
    Icons.home_rounded,
    Icons.vpn_key_rounded,
    Icons.villa_rounded,
    Icons.storefront_rounded,
    Icons.apartment_rounded,
    Icons.location_on_rounded,
    Icons.terrain_rounded,
    Icons.business_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _restoreSessionFuture = context.read<AuthRepository>().restoreSession();
    _ambient = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _orbitSpin = AnimationController(vsync: this, duration: const Duration(seconds: 46))..repeat();
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
    _orbitSpin.dispose();
    super.dispose();
  }

  /// One jeweled badge in the constellation around the wordmark — a real
  /// property-themed icon in a glass-highlighted, gold-ringed medallion,
  /// entrance-staggered in, then left to slowly and continuously revolve
  /// around the mark for the rest of the reveal so the whole thing reads as
  /// alive, not a static poster. Alternates emerald/gold medallions for
  /// jeweled variety instead of one flat repeated color.
  Widget _orbitIcon({
    required IconData icon,
    required double baseAngle,
    required double radiusX,
    required double radiusY,
    required int delayMs,
    double size = 38,
    bool goldVariant = false,
  }) {
    final gradient = goldVariant
        ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark])
        : AppColors.brandGradient;
    return AnimatedBuilder(
      animation: _orbitSpin,
      builder: (context, child) {
        final angle = baseAngle + _orbitSpin.value * 2 * math.pi;
        return Align(
          alignment: Alignment(math.cos(angle) * radiusX, math.sin(angle) * radiusY),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.6),
          boxShadow: [BoxShadow(color: AppColors.emeraldDark.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: size * 0.46, color: Colors.white),
            // A small glassy highlight near the top-left, so each medallion
            // reads as a polished sphere rather than a flat painted disc.
            Positioned(
              top: size * 0.14,
              left: size * 0.18,
              child: Container(
                width: size * 0.34,
                height: size * 0.18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  gradient: LinearGradient(colors: [Colors.white.withOpacity(0.65), Colors.white.withOpacity(0)]),
                ),
              ),
            ),
          ],
        ),
      )
          .animate(delay: delayMs.ms)
          .fadeIn(duration: 650.ms, curve: AppMotion.emphasized)
          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: AppMotion.emphasized, duration: 750.ms),
    );
  }

  /// A single letter of the wordmark, rendered as a stack of the same glyph
  /// offset diagonally in deepening emerald shades — the retro "block
  /// extrusion" look (a stepped drop-shadow of solid color layers) applied
  /// to MULK in the app's own brand palette instead of a rainbow.
  Widget _retroLetter(String letter) {
    const style = TextStyle(fontFamily: 'Quicksand', fontSize: 92, fontWeight: FontWeight.w700, height: 1);
    return Padding(
      padding: const EdgeInsets.only(right: 9, bottom: 9),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(offset: const Offset(9, 9), child: Text(letter, style: style.copyWith(color: AppColors.emeraldDark))),
          Transform.translate(offset: const Offset(6, 6), child: Text(letter, style: style.copyWith(color: AppColors.emerald))),
          Transform.translate(offset: const Offset(3, 3), child: Text(letter, style: style.copyWith(color: AppColors.goldDark))),
          Text(letter, style: style.copyWith(color: AppColors.creamOnDark)),
        ],
      ),
    );
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
                          width: 380,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              if (!reduceMotion) ...[
                                _sparkle(alignment: const Alignment(-0.62, -1.02), delayMs: 1400, period: 1400.ms),
                                _sparkle(alignment: const Alignment(0.7, -0.86), delayMs: 1900, period: 1700.ms, size: 4),
                                _sparkle(alignment: const Alignment(0.86, 0.62), delayMs: 2100, period: 1500.ms),
                                _sparkle(alignment: const Alignment(-0.9, 0.5), delayMs: 1650, period: 1850.ms, size: 4),

                                for (var i = 0; i < _orbitIcons.length; i++)
                                  _orbitIcon(
                                    icon: _orbitIcons[i],
                                    baseAngle: -math.pi / 2 + i * (math.pi / 4),
                                    radiusX: 1.18,
                                    radiusY: 1.02,
                                    delayMs: 650 + i * 80,
                                    size: i.isEven ? 40 : 34,
                                    goldVariant: i.isOdd,
                                  ),
                              ],

                              // Soft breathing halo behind the wordmark.
                              Transform.scale(
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

                              // "MULK" cascades in one letter at a time —
                              // each letter itself a stepped stack of
                              // offset color layers (the retro block-
                              // extrusion look) — instead of popping in as
                              // one flat block.
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var i = 0; i < _wordmark.length; i++)
                                    _retroLetter(_wordmark[i])
                                        .animate(delay: (350 + i * 160).ms)
                                        .fadeIn(duration: 520.ms, curve: AppMotion.emphasized)
                                        .slideY(begin: 0.55, end: 0, duration: 600.ms, curve: AppMotion.emphasized)
                                        .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 600.ms, curve: AppMotion.emphasized),
                                ],
                              ).animate(delay: 350.ms).shimmer(delay: 900.ms, duration: 1300.ms, color: Colors.white.withOpacity(0.55)),
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
