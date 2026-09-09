import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/listing.dart';
import '../../../core/network/activity_repository.dart';
import '../../../core/network/reel_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../widgets/reel_filter_sheet.dart';
import '../widgets/reel_overlay.dart';
import '../widgets/reel_progress_bar.dart';
import '../widgets/reel_video_player.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => ReelsScreenState();
}

class ReelsScreenState extends State<ReelsScreen> {
  final _pageController = PageController();
  final _searchController = TextEditingController();
  final Map<int, GlobalKey<ReelVideoPlayerState>> _playerKeys = {};
  ListingPurpose? _purpose; // null = both
  String _type = 'all';
  int _activeIndex = 0;
  bool _muted = false;
  String _query = '';
  List<Reel> _allReels = [];
  bool _isLoading = true;
  final Set<String> _viewedReelIds = {};

  GlobalKey<ReelVideoPlayerState> _keyFor(int i) => _playerKeys.putIfAbsent(i, () => GlobalKey<ReelVideoPlayerState>());

  /// Counts a real view the first time a reel is actually scrolled to and
  /// starts playing — once per reel per visit to this tab, not on every
  /// scroll back and forth over it.
  void _recordView(Reel reel) {
    if (!_viewedReelIds.add(reel.id)) return;
    context.read<ActivityRepository>().recordView(type: 'reel', id: reel.id);
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Kept alive by the bottom nav's IndexedStack, so it never rebuilds on
  /// its own when a reel is published elsewhere and the visitor switches
  /// back to this tab — called by HomeShell each time that happens so the
  /// feed is never showing a stale snapshot from app launch.
  void refresh() {
    context.read<ReelRepository>().fetchAll().then((reels) {
      if (mounted) setState(() { _allReels = reels; _isLoading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

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
    final reels = _allReels.where((r) {
      if (_purpose != null && r.listing?.purpose != _purpose) return false;
      if (_type != 'all' && r.listing?.type.name != _type) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matches = r.agency.name.toLowerCase().contains(q) || (r.listing?.title.toLowerCase().contains(q) ?? false);
        if (!matches) return false;
      }
      return true;
    }).toList();

    if (reels.isNotEmpty && _activeIndex < reels.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recordView(reels[_activeIndex]));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.gold))
          else if (reels.isEmpty)
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
        ReelOverlay(reel: reel),
      ],
    ).animate().fadeIn(duration: 320.ms, curve: AppMotion.enter);
  }
}
