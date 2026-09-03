import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A full-bleed, auto-advancing real-photo backdrop: crossfades between
/// [photos] on a timer while each photo slowly Ken-Burns zooms. Used behind
/// the login/register glass cards so they never feel static.
class PhotoBackdrop extends StatefulWidget {
  final List<String> photos;
  final Duration interval;
  const PhotoBackdrop({super.key, required this.photos, this.interval = const Duration(seconds: 5)});

  @override
  State<PhotoBackdrop> createState() => _PhotoBackdropState();
}

class _PhotoBackdropState extends State<PhotoBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _kenBurns;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _kenBurns = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    if (widget.photos.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.photos.length);
      });
    }
  }

  @override
  void dispose() {
    _kenBurns.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1000),
          layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
          child: AnimatedBuilder(
            key: ValueKey(_index),
            animation: _kenBurns,
            builder: (context, child) => Transform.scale(scale: 1.08 + 0.06 * _kenBurns.value, child: child),
            child: CachedNetworkImage(
              imageUrl: widget.photos[_index],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.ink),
              errorWidget: (_, __, ___) => Container(color: AppColors.ink),
            ),
          ),
        ),
        // Dot indicators, small and unobtrusive.
        if (widget.photos.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.photos.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 5,
                  decoration: BoxDecoration(color: active ? AppColors.gold : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(3)),
                );
              }),
            ),
          ),
      ],
    );
  }
}
