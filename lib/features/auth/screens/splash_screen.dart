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

/// App entry point — a soft wordmark reveal (no logo mark) while a previous
/// session restores in the background, then a cross-fade into onboarding
/// or straight into the app.
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

  /// One small badge in the "constellation" around the wordmark — a real
  /// property-themed icon (house / villa / land / shop / pin / building),
  /// softly floating and staggered in after the text so it reads as an
  /// orbit, not clutter.
  Widget _orbitIcon({
    required IconData icon,
    required Alignment alignment,
    required double bob,
    required int delayMs,
    double size = 34,
  }) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(0, bob),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
            boxShadow: [BoxShadow(color: AppColors.emerald.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Icon(icon, size: size * 0.48, color: Colors.white),
        ),
      ),
    )
        .animate(delay: delayMs.ms)
        .fadeIn(duration: 650.ms, curve: AppMotion.emphasized)
        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: AppMotion.emphasized, duration: 750.ms);
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
          final bob = reduceMotion ? 0.0 : (ambient - 0.5) * 14;
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.2 + ambient * 0.1, -0.3),
                    radius: 1.3,
                    colors: [
                      AppColors.emeraldLight.withOpacity(0.16),
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
                          width: 340,
                          height: 190,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              if (!reduceMotion) ...[
                                _orbitIcon(icon: Icons.home_rounded, alignment: const Alignment(-0.95, -0.78), bob: bob, delayMs: 650),
                                _orbitIcon(icon: Icons.villa_rounded, alignment: const Alignment(0.98, -0.7), bob: -bob, delayMs: 760),
                                _orbitIcon(icon: Icons.terrain_rounded, alignment: const Alignment(-1.08, 0.15), bob: -bob, delayMs: 870, size: 30),
                                _orbitIcon(icon: Icons.storefront_rounded, alignment: const Alignment(1.1, 0.1), bob: bob, delayMs: 980, size: 30),
                                _orbitIcon(icon: Icons.location_on_rounded, alignment: const Alignment(-0.88, 0.9), bob: -bob, delayMs: 1090, size: 30),
                                _orbitIcon(icon: Icons.apartment_rounded, alignment: const Alignment(0.92, 0.85), bob: bob, delayMs: 1200, size: 30),
                              ],
                              ShaderMask(
                                shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                                child: Text(
                                  'app_name'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 72,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 850.ms, curve: AppMotion.emphasized)
                                  .scale(begin: const Offset(0.82, 0.82), end: const Offset(1, 1), curve: AppMotion.emphasized, duration: 900.ms)
                                  .then(delay: 300.ms)
                                  .shimmer(duration: 1300.ms, color: AppColors.goldLight.withOpacity(0.7)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 34,
                          height: 2.4,
                          decoration: BoxDecoration(color: palette.gold, borderRadius: BorderRadius.circular(99)),
                        ).animate(delay: 600.ms).fadeIn(duration: 500.ms).scaleX(begin: 0, end: 1, curve: AppMotion.emphasized),
                        const SizedBox(height: 16),
                        Text(
                          'splash.tagline'.tr(),
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ).animate(delay: 720.ms).fadeIn(duration: 600.ms).slideY(begin: 0.15, end: 0, curve: AppMotion.emphasized),
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
