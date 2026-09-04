import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/network/home_placement_repository.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';

/// Continuously, smoothly auto-scrolling logo marquee — driven by a single
/// AnimationController translating the row (no per-frame jumpTo jitter).
/// The logo list itself is admin-curated, editable only from the separate
/// web admin panel.
class PartnerLogosRow extends StatefulWidget {
  const PartnerLogosRow({super.key});

  @override
  State<PartnerLogosRow> createState() => _PartnerLogosRowState();
}

class _PartnerLogosRowState extends State<PartnerLogosRow> with SingleTickerProviderStateMixin {
  static const _itemExtent = 84.0; // 72 badge + 12 gap
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  List<String> _logos = [];

  @override
  void initState() {
    super.initState();
    context.read<HomePlacementRepository>().fetchSponsorLogos().then((logos) {
      if (mounted) setState(() => _logos = logos);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logos = _logos;
    if (logos.isEmpty) return const SizedBox.shrink();
    final setWidth = _itemExtent * logos.length;
    // Duration scales with content so the marquee speed stays constant
    // however many sponsors admin adds or removes.
    _controller.duration = Duration(milliseconds: (setWidth * 40).round());

    return SizedBox(
      height: 72,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final dx = -(_controller.value * setWidth);
            // OverflowBox gives the (much wider than the screen) Row an
            // unconstrained width to lay out in, so it never trips a
            // RenderFlex overflow — ClipRect still clips what's actually
            // painted to the viewport.
            return OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: Transform.translate(offset: Offset(dx, 0), child: child),
            );
          },
          // Three copies back-to-back so the wrap-around point is never visible.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [...logos, ...logos, ...logos].map((a) => _badge(context, a)).toList(),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 420.ms);
  }

  Widget _badge(BuildContext context, String path) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 14),
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(18)),
        child: isNetworkImage(path)
            ? CachedNetworkImage(imageUrl: path, fit: BoxFit.contain)
            : Image.asset(path, fit: BoxFit.contain),
      ),
    );
  }
}
