import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/listing_image.dart';

/// Auto-crossfading 3-photo carousel used as a project's visual "identity" —
/// same pattern as the agency portfolio cover, reused here at card scale.
class ProjectIdentityCarousel extends StatefulWidget {
  final List<String> images;
  const ProjectIdentityCarousel({super.key, required this.images});

  @override
  State<ProjectIdentityCarousel> createState() => _ProjectIdentityCarouselState();
}

class _ProjectIdentityCarouselState extends State<ProjectIdentityCarousel> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.images.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
          child: !isNetworkImage(widget.images[_index])
              ? Image.file(File(widget.images[_index]), key: ValueKey(_index), fit: BoxFit.cover)
              : CachedNetworkImage(
                  key: ValueKey(_index),
                  imageUrl: widget.images[_index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surfaceElevated),
                  errorWidget: (_, __, ___) => Container(color: AppColors.surfaceElevated, child: const Icon(Icons.apartment_rounded, color: AppColors.textMuted)),
                ),
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 5,
                  decoration: BoxDecoration(color: active ? AppColors.gold : Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(3)),
                );
              }),
            ),
          ),
      ],
    );
  }
}
