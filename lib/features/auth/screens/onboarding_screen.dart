import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/shikodar_mark.dart';
import '../../home/screens/home_shell.dart';
import '../widgets/auth_components.dart';

const _hasSeenOnboardingKey = 'has_seen_onboarding';

class _OnboardPage {
  const _OnboardPage({required this.titleKey, required this.descriptionKey, required this.icon});

  final String titleKey;
  final String descriptionKey;
  final IconData icon;
}

const _pages = <_OnboardPage>[
  _OnboardPage(
    titleKey: 'onboarding.discover_title',
    descriptionKey: 'onboarding.discover_description',
    icon: Icons.location_city_rounded,
  ),
  _OnboardPage(
    titleKey: 'onboarding.reels_title',
    descriptionKey: 'onboarding.reels_description',
    icon: Icons.play_arrow_rounded,
  ),
  _OnboardPage(
    titleKey: 'onboarding.trust_title',
    descriptionKey: 'onboarding.trust_description',
    icon: Icons.verified_user_rounded,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
    if (!mounted) return;
    // Onboarding only ever runs once — from here on the app opens straight
    // to browsing as a guest. Signing in/registering happens later, from
    // the profile tab, only if the visitor asks for it.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: AppMotion.expressive,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
          child: const HomeShell(),
        ),
      ),
    );
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finishOnboarding();
      return;
    }
    _controller.nextPage(duration: AppMotion.expressive, curve: AppMotion.emphasized);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _OnboardingBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      const ShikodarMark(size: 42, showShadow: false),
                      const SizedBox(width: 11),
                      Text(
                        'app_name'.tr(),
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: isLast ? 0 : 1,
                        duration: AppMotion.standard,
                        child: TextButton(
                          onPressed: isLast ? null : _finishOnboarding,
                          child: Text(
                            'onboarding.skip'.tr(),
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (value) => setState(() => _page = value),
                    itemCount: _pages.length,
                    itemBuilder: (_, index) => _OnboardPageView(
                      page: _pages[index],
                      index: index,
                      controller: _controller,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                  child: Column(
                    children: [
                      _PageIndicator(activeIndex: _page, count: _pages.length),
                      const SizedBox(height: 22),
                      AuthPrimaryButton(
                        label: isLast ? 'onboarding.start'.tr() : 'onboarding.next'.tr(),
                        icon: isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                        onPressed: _next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPageView extends StatelessWidget {
  const _OnboardPageView({required this.page, required this.index, required this.controller});

  final _OnboardPage page;
  final int index;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentPage = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : 0.0;
        final distance =
            (currentPage - index).abs().clamp(0.0, 1.0).toDouble();
        final scale = 1 - distance * 0.055;
        final opacity = 1 - distance * 0.28;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: AspectRatio(
                        aspectRatio: 0.92,
                        child: _PropertyScene(index: index, icon: page.icon),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    page.titleKey.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 13),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Text(
                      page.descriptionKey.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PropertyScene extends StatelessWidget {
  const _PropertyScene({required this.index, required this.icon});

  final int index;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17685B), Color(0xFF0E554A), Color(0xFF083B34)],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0x4DE1C58F)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withOpacity(0.65),
            blurRadius: 38,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(33),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _ArchitecturePainter(variant: index)),
            Positioned(
              top: 22,
              right: 22,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: Icon(icon, color: AppColors.goldLight, size: 26),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 22,
              child: Row(
                children: [
                  _SceneMetric(value: index == 1 ? 'HD' : '24/7'),
                  const SizedBox(width: 8),
                  _SceneMetric(value: index == 2 ? '✓' : 'KIRKUK'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneMetric extends StatelessWidget {
  const _SceneMetric({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ArchitecturePainter extends CustomPainter {
  const _ArchitecturePainter({required this.variant});

  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), gridPaint);
    }

    final goldPaint = Paint()
      ..color = AppColors.goldLight.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    final ivoryPaint = Paint()
      ..color = AppColors.creamOnDark.withOpacity(0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    final baseY = size.height * 0.72;
    final building = Path();
    if (variant == 0) {
      building
        ..moveTo(size.width * 0.16, baseY)
        ..lineTo(size.width * 0.16, size.height * 0.48)
        ..lineTo(size.width * 0.42, size.height * 0.30)
        ..lineTo(size.width * 0.68, size.height * 0.48)
        ..lineTo(size.width * 0.68, baseY)
        ..moveTo(size.width * 0.68, baseY)
        ..lineTo(size.width * 0.84, baseY)
        ..lineTo(size.width * 0.84, size.height * 0.39)
        ..lineTo(size.width * 0.68, size.height * 0.39);
    } else if (variant == 1) {
      building
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.20, size.height * 0.24, size.width * 0.60, size.height * 0.48),
          const Radius.circular(12),
        ))
        ..moveTo(size.width * 0.30, size.height * 0.35)
        ..lineTo(size.width * 0.70, size.height * 0.35)
        ..moveTo(size.width * 0.30, size.height * 0.47)
        ..lineTo(size.width * 0.70, size.height * 0.47)
        ..moveTo(size.width * 0.30, size.height * 0.59)
        ..lineTo(size.width * 0.70, size.height * 0.59);
    } else {
      building
        ..moveTo(size.width * 0.18, baseY)
        ..lineTo(size.width * 0.18, size.height * 0.40)
        ..quadraticBezierTo(size.width * 0.50, size.height * 0.14, size.width * 0.82, size.height * 0.40)
        ..lineTo(size.width * 0.82, baseY)
        ..moveTo(size.width * 0.38, baseY)
        ..lineTo(size.width * 0.38, size.height * 0.47)
        ..quadraticBezierTo(size.width * 0.50, size.height * 0.37, size.width * 0.62, size.height * 0.47)
        ..lineTo(size.width * 0.62, baseY);
    }
    canvas.drawPath(building, ivoryPaint);
    canvas.drawLine(
      Offset(size.width * 0.12, baseY + 9),
      Offset(size.width * 0.88, baseY + 9),
      goldPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.18),
      size.width * 0.045,
      Paint()..color = AppColors.gold.withOpacity(0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _ArchitecturePainter oldDelegate) => oldDelegate.variant != variant;
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.activeIndex, required this.count});

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = activeIndex == index;
        return AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.enter,
          width: active ? 28 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? palette.primary : palette.divider,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.8, -0.9),
          radius: 1.25,
          colors: [
            AppColors.goldLight.withOpacity(0.14),
            palette.background,
            palette.background,
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
    );
  }
}
