import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/session/admin_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kenBurns;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _kenBurns = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final count = context.read<AdminStore>().heroPhotos.length;
      if (count == 0) return;
      setState(() => _index = (_index + 1) % count);
    });
  }

  @override
  void dispose() {
    _kenBurns.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reduceMotion = AppMotion.reduce(context);
    final heroPhotos = context.watch<AdminStore>().heroPhotos;
    final index = heroPhotos.isEmpty ? 0 : _index % heroPhotos.length;

    if (heroPhotos.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 224,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withOpacity(0.55),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 950),
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (current != null) current],
              ),
              child: AnimatedBuilder(
                key: ValueKey(index),
                animation: _kenBurns,
                builder: (context, child) => Transform.scale(
                  scale: reduceMotion ? 1.06 : 1.05 + 0.06 * _kenBurns.value,
                  child: child,
                ),
                child: CachedNetworkImage(
                  imageUrl: heroPhotos[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: palette.surfaceElevated),
                  errorWidget: (_, __, ___) => Container(
                    decoration: const BoxDecoration(gradient: AppColors.brandGradient),
                  ),
                ),
              ),
            ),
            // A faint bottom-only vignette — just enough depth for the dot
            // indicator and CTA to sit on, without ever competing with the
            // photo itself. No headline lives here; the image is the message.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x59083B34)],
                  stops: [0.68, 1],
                ),
              ),
            ),
            PositionedDirectional(
              start: 20,
              end: 20,
              bottom: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: List.generate(heroPhotos.length, (i) {
                      final selected = index == i;
                      return AnimatedContainer(
                        duration: AppMotion.standard,
                        width: selected ? 18 : 5,
                        height: 5,
                        margin: const EdgeInsetsDirectional.only(end: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.goldLight
                              : Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onExplore,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 14,
                              offset: Offset(0, 7),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.emeraldDark,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
