import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/auth_repository.dart';
import '../../../core/network/favorite_repository.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../home/screens/favorites_screen.dart';
import '../../home/screens/home_shell.dart';
import 'onboarding_screen.dart';

const _hasSeenOnboardingKey = 'has_seen_onboarding';

/// The real brand mark, replacing the old code-drawn placeholder — a
/// transparent-cropped export of the logo (see assets/branding/ for the
/// original + how it was cleaned up for the app icon).
const _logoAsset = 'assets/branding/app_icon_transparent.png';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _exit;
  late final AnimationController _ambient;
  late final Animation<double> _exitDrift;
  late final Animation<double> _exitGlow;
  late final Animation<double> _exitFooter;
  late final Animation<double> _exitTitle;
  late final Animation<double> _exitMark;
  late final Animation<double> _markScale;
  late final Animation<double> _markBlur;
  late final Animation<double> _markTilt;
  late final Animation<double> _ring1;
  late final Animation<double> _ring2;
  late final Animation<double> _shine;
  late final Animation<double> _titleReveal;
  late final Animation<double> _dividerReveal;
  late final Animation<double> _taglineReveal;

  /// Kicked off immediately so it resolves alongside (not after) the splash
  /// animation delay below — a previously signed-in user shouldn't have to
  /// log in again every time the app restarts.
  late final Future<AuthResult?> _restoreSessionFuture;

  @override
  void initState() {
    super.initState();
    _restoreSessionFuture = context.read<AuthRepository>().restoreSession();
    _entrance = AnimationController(
      vsync: this,
      duration: AppMotion.splashEntrance,
    );
    _exit = AnimationController(
      vsync: this,
      duration: AppMotion.splashExit,
    );
    // The exit is staged rather than a single flat fade: the footer leaves
    // first, the wordmark follows, and the mark itself lingers a touch
    // longer with its own soft glow bloom — a gentler, more deliberate
    // departure than everything vanishing together.
    _exitDrift = CurvedAnimation(parent: _exit, curve: Curves.easeInOutCubic);
    _exitGlow = CurvedAnimation(parent: _exit, curve: const Interval(0, 0.55, curve: Curves.easeOut));
    _exitFooter = CurvedAnimation(parent: _exit, curve: const Interval(0, 0.5, curve: Curves.easeInCubic));
    _exitTitle = CurvedAnimation(parent: _exit, curve: const Interval(0.14, 0.72, curve: Curves.easeInCubic));
    _exitMark = CurvedAnimation(parent: _exit, curve: const Interval(0.3, 1, curve: Curves.easeInCubic));
    // The badge swings in from a soft blur with a dramatic scale overshoot —
    // a "focus pull" reveal instead of the old mark's stroke-by-stroke draw
    // (that trick only worked on a code-painted vector; a photographed logo
    // needs its own cinematic language).
    _markScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.075)
            .chain(CurveTween(curve: AppMotion.emphasized)),
        weight: 68,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.075, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 32,
      ),
    ]).animate(_entrance);
    _markBlur = Tween(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0, 0.56, curve: Curves.easeOut),
      ),
    );
    _markTilt = Tween(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0, 0.62, curve: AppMotion.emphasized),
      ),
    );
    // A double pulse of light announces the mark right as it starts drawing.
    _ring1 = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    _ring2 = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.1, 0.55, curve: Curves.easeOut),
    );
    // A single diagonal shine sweeps across the badge once it has settled.
    _shine = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.64, 0.94, curve: Curves.easeInOut),
    );
    // Wordmark, divider and tagline cascade in one after another instead of
    // all fading together — reads as a deliberate, staged reveal.
    _titleReveal = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.50, 0.72, curve: AppMotion.enter),
    );
    _dividerReveal = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.66, 0.84, curve: AppMotion.emphasized),
    );
    _taglineReveal = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.80, 1, curve: AppMotion.enter),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _entrance.forward();

    Future.delayed(const Duration(milliseconds: 3050), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool(_hasSeenOnboardingKey) ?? false;
      final restored = await _restoreSessionFuture;
      if (!mounted) return;
      if (restored != null) {
        context.read<UserSession>().logIn(restored.role, name: restored.name, agencyId: restored.agencyId);
        FavoritesStore.loadFromServer(context.read<FavoriteRepository>());
      }
      if (!mounted) return;
      await _exit.forward();
      if (!mounted) return;
      // First launch ever: walk through onboarding, then land in the app as
      // a guest. Every launch after that skips straight to the app — no
      // onboarding, no mandatory login. Signing in/registering only happens
      // if the visitor opens the profile tab and asks to.
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: AppMotion.expressive,
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
            child: seenOnboarding ? const HomeShell() : const OnboardingScreen(),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _exit.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion = AppMotion.reduce(context);
    const markSize = 196.0;

    return Scaffold(
      backgroundColor: palette.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([_entrance, _exit, _ambient]),
        builder: (context, _) {
          final ambient = reduceMotion ? 0.5 : _ambient.value;
          final driftT = reduceMotion ? 0.0 : _exitDrift.value;
          final glowT = reduceMotion ? 0.0 : math.sin(math.pi * _exitGlow.value.clamp(0.0, 1.0));
          final footerExit = reduceMotion ? 0.0 : _exitFooter.value;
          final titleExit = reduceMotion ? 0.0 : _exitTitle.value;
          final markExit = reduceMotion ? 0.0 : _exitMark.value;
          return Transform.translate(
            offset: Offset(0, -16 * driftT),
            child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.55 + ambient * 0.1, -0.75),
                    radius: 1.3,
                    colors: [
                      AppColors.goldLight.withOpacity(0.16),
                      palette.background,
                      palette.background,
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
              Positioned(
                top: -95 + ambient * 10,
                right: -85,
                child: _AmbientOrb(
                  size: 230,
                  color: AppColors.emerald.withOpacity(0.05 + 0.04 * ambient),
                ),
              ),
              Positioned(
                bottom: -135 - ambient * 8,
                left: -105,
                child: _AmbientOrb(
                  size: 280,
                  color: AppColors.gold.withOpacity(0.06 + 0.04 * ambient),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // A slow, always-on breathing glow — the badge
                          // reads as alive on screen, not just during its
                          // entrance/exit beats.
                          if (!reduceMotion)
                            Opacity(
                              opacity: (0.28 + 0.14 * ambient) * (1 - markExit),
                              child: _AmbientOrb(
                                size: markSize * 1.3 + 12 * ambient,
                                color: AppColors.goldLight.withOpacity(0.4),
                              ),
                            ),
                          if (!reduceMotion && glowT > 0)
                            Opacity(
                              opacity: glowT * 0.5,
                              child: _AmbientOrb(
                                size: markSize * 1.55,
                                color: AppColors.goldLight.withOpacity(0.5),
                              ),
                            ),
                          if (!reduceMotion) ...[
                            Transform.scale(
                              scale: 0.7 + 1.7 * _ring2.value,
                              child: Opacity(
                                opacity: (1 - _ring2.value).clamp(0.0, 1.0) * 0.38,
                                child: const _RevealRing(
                                  size: markSize,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.7 + 1.7 * _ring1.value,
                              child: Opacity(
                                opacity: (1 - _ring1.value).clamp(0.0, 1.0) * 0.45,
                                child: const _RevealRing(
                                  size: markSize,
                                  color: AppColors.goldLight,
                                ),
                              ),
                            ),
                          ],
                          Opacity(
                            opacity: 1 - markExit,
                            child: Transform.scale(
                              scale: (reduceMotion ? 1 : _markScale.value) * (1 + 0.14 * markExit),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0012)
                                  ..rotateX(reduceMotion ? 0 : (_markTilt.value - 0.22 * markExit)),
                                child: SizedBox(
                                  width: markSize * 1.3,
                                  height: markSize * 1.3,
                                  child: ImageFiltered(
                                    imageFilter: ui.ImageFilter.blur(
                                      sigmaX: reduceMotion ? 0 : _markBlur.value,
                                      sigmaY: reduceMotion ? 0 : _markBlur.value,
                                    ),
                                    child: Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(markSize * 0.22),
                                        child: SizedBox(
                                          width: markSize,
                                          height: markSize,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.asset(_logoAsset, fit: BoxFit.cover),
                                              if (!reduceMotion)
                                                _ShineSweep(progress: _shine.value, size: markSize),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      Opacity(
                        opacity: (reduceMotion ? 1 : _titleReveal.value) * (1 - titleExit),
                        child: Transform.translate(
                          offset: Offset(0, reduceMotion ? 0 : 10 * (1 - _titleReveal.value) - 6 * titleExit),
                          child: Text(
                            'app_name'.tr(),
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              height: 1.1,
                            ),
                          )
                              .animate(delay: 950.ms)
                              .shimmer(
                                duration: 1250.ms,
                                color: AppColors.goldLight.withOpacity(0.65),
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: (reduceMotion ? 1 : _dividerReveal.value) * (1 - footerExit),
                        child: Container(
                          width: reduceMotion ? 34 : 34 * _dividerReveal.value,
                          height: 2,
                          decoration: BoxDecoration(
                            color: palette.gold,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      Opacity(
                        opacity: (reduceMotion ? 1 : _taglineReveal.value) * (1 - footerExit),
                        child: Transform.translate(
                          offset: Offset(0, reduceMotion ? 0 : 8 * (1 - _taglineReveal.value) - 5 * footerExit),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'onboarding.tagline'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
              ),
          );
        },
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.2),
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 12),
          ],
        ),
      ),
    );
  }
}

/// A ring that expands and fades once — the "pulse" that announces the mark
/// at the start of the entrance, rather than a looping decoration.
class _RevealRing extends StatelessWidget {
  const _RevealRing({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.4),
        ),
      ),
    );
  }
}

/// A soft diagonal highlight that sweeps once across the mark once it has
/// finished drawing — the "premium reveal" beat of the entrance.
class _ShineSweep extends StatelessWidget {
  const _ShineSweep({required this.progress, required this.size});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    final fade = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
    return IgnorePointer(
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(-size + progress * size * 2.4, 0),
          child: Transform.rotate(
            angle: -0.5,
            child: Container(
              width: size * 0.3,
              height: size * 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
