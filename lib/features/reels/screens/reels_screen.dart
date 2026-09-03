import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../widgets/reel_filter_sheet.dart';
import '../widgets/reel_overlay.dart';
import '../widgets/reel_progress_bar.dart';
import '../widgets/reel_video_player.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final _pageController = PageController();
  final _searchController = TextEditingController();
  final Map<int, GlobalKey<ReelVideoPlayerState>> _playerKeys = {};
  ListingPurpose? _purpose; // null = both
  String _type = 'all';
  int _activeIndex = 0;
  bool _muted = false;
  String _query = '';

  GlobalKey<ReelVideoPlayerState> _keyFor(int i) => _playerKeys.putIfAbsent(i, () => GlobalKey<ReelVideoPlayerState>());

  void _resetToTop() {
    _activeIndex = 0;
    _playerKeys.clear();
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<(ListingPurpose?, String)>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ReelFilterSheet(purpose: _purpose, type: _type),
    );
    if (result != null) {
      setState(() {
        _purpose = result.$1;
        _type = result.$2;
        _resetToTop();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reels = MockData.reels.where((r) {
      if (_purpose != null && r.listing.purpose != _purpose) return false;
      if (_type != 'all' && r.listing.type.name != _type) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matches = r.listing.agency.name.toLowerCase().contains(q) || r.listing.title.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (reels.isEmpty)
            Center(child: Text('common.no_results'.tr(), style: const TextStyle(color: AppColors.textSecondary)))
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              onPageChanged: (i) => setState(() => _activeIndex = i),
              itemBuilder: (_, i) => _ReelItem(
                key: ValueKey(reels[i].id),
                reel: reels[i],
                playerKey: _keyFor(i),
                isActive: i == _activeIndex,
                muted: _muted,
              ),
            ),

          // Top bar: search (agency/project name) + a single filter icon.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: const Color(0xFF0E1917).withOpacity(0.55), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold.withOpacity(0.35))),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 18, color: AppColors.gold),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (v) => setState(() => _query = v),
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'reels.search_hint'.tr(),
                                    hintStyle: TextStyle(color: AppColors.gold.withOpacity(0.55), fontSize: 12.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).entrance(index: 0),
                  const SizedBox(width: 10),
                  _ReelIconButton(
                    onTap: () => setState(() => _muted = !_muted),
                    color: const Color(0xFF0E1917).withOpacity(0.55),
                    borderColor: AppColors.gold.withOpacity(0.35),
                    child: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: AppColors.gold, size: 18),
                  ).entrance(index: 1),
                  const SizedBox(width: 10),
                  _ReelIconButton(
                    onTap: _openFilters,
                    gradient: (_purpose != null || _type != 'all') ? AppColors.goldGradient : null,
                    color: (_purpose != null || _type != 'all') ? null : const Color(0xFF0E1917).withOpacity(0.55),
                    borderColor: (_purpose != null || _type != 'all') ? null : AppColors.gold.withOpacity(0.35),
                    child: Icon(Icons.tune_rounded, size: 18, color: (_purpose != null || _type != 'all') ? AppColors.ink : AppColors.gold),
                  ).entrance(index: 2),
                ],
              ),
            ),
          ),

          // Story-style progress bar, just under the top bar.
          if (reels.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 62, left: 16, right: 16),
                child: ReelProgressBar(controller: _keyFor(_activeIndex).currentState?.controller),
              ).entrance(base: 180.ms),
            ),
        ],
      ),
    );
  }
}

/// A circular glass icon button with real ink feedback — replaces the bare
/// `GestureDetector` the top bar used to rely on, so every tap in the reels
/// feed feels as soft/responsive as the rest of the app.
class _ReelIconButton extends StatelessWidget {
  const _ReelIconButton({
    required this.onTap,
    required this.child,
    this.color,
    this.gradient,
    this.borderColor,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          shape: BoxShape.circle,
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ReelItem extends StatelessWidget {
  final Reel reel;
  final GlobalKey<ReelVideoPlayerState> playerKey;
  final bool isActive;
  final bool muted;
  const _ReelItem({super.key, required this.reel, required this.playerKey, required this.isActive, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ReelVideoPlayer(key: playerKey, videoUrl: reel.videoUrl, thumbnailUrl: reel.thumbnailUrl, isActive: isActive, muted: muted),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55000000), Colors.transparent, Colors.transparent, Color(0xCC000000)],
              stops: [0.0, 0.22, 0.55, 1.0],
            ),
          ),
        ),
        ReelOverlay(listing: reel.listing),
      ],
    ).animate().fadeIn(duration: 320.ms, curve: AppMotion.enter);
  }
}
