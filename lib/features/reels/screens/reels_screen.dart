import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/listing.dart';
import '../../../core/navigation/app_route_observer.dart';
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

class ReelsScreenState extends State<ReelsScreen> with RouteAware, WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  /// Backgrounding the whole app (home button, app switcher, phone lock)
  /// is a separate code path from in-app navigation — pause here too, or
  /// a reel's audio keeps playing while the app isn't even on screen.
  /// Goes straight to the controller rather than pauseActive()/resumeActive()
  /// so this never flips _isTabActive — foregrounding the app should only
  /// resume playback if Reels was genuinely the visible tab when it got
  /// backgrounded, not whichever tab happens to be selected right now.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseAll();
    } else if (state == AppLifecycleState.resumed && _isTabActive) {
      _keyFor(_activeIndex).currentState?.controller?.play();
    }
  }

  /// Pauses every reel player PageView has ever built (not just the one at
  /// _activeIndex) — PageView.builder keeps a page or two alive just
  /// outside the viewport for smooth swiping, so if bookkeeping ever drifts
  /// from what's actually on screen, this is the guarantee that leaving the
  /// tab genuinely silences every video instead of just the one we think is
  /// active.
  void _pauseAll() {
    for (final key in _playerKeys.values) {
      key.currentState?.controller?.pause();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  /// Another screen was just pushed on top of this one (e.g. tapping
  /// through to a listing or agency profile from a reel) — pause so its
  /// video/audio doesn't keep running behind the new screen.
  @override
  void didPushNext() => pauseActive();

  /// Back on top again after that screen was popped — resume where we
  /// left off.
  @override
  void didPopNext() => resumeActive();

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

  /// Whether Reels is the actual visible tab right now (as opposed to just
  /// mounted-but-hidden in HomeShell's IndexedStack) — tracked so an app
  /// foreground/background cycle (see didChangeAppLifecycleState) never
  /// resumes a reel the visitor had already navigated away from. Starts
  /// false: HomeShell's IndexedStack builds every tab (including this one)
  /// immediately at launch, but its default visible tab is Home, not
  /// Reels — starting this true made the very first reel autoplay (with
  /// sound) the instant the app opened, well before the visitor ever
  /// switched to this tab.
  bool _isTabActive = false;

  /// Pauses the currently on-screen reel's video — called by HomeShell the
  /// instant the visitor switches to a different bottom-nav tab. Without
  /// this, the reel (and its audio) kept playing invisibly in the
  /// background: this screen stays mounted inside HomeShell's IndexedStack
  /// rather than being disposed on tab switch, so nothing else ever told
  /// its VideoPlayerController to stop.
  void pauseActive() {
    _isTabActive = false;
    _pauseAll();
  }

  /// Resumes the on-screen reel — called by HomeShell right after
  /// switching back to this tab, mirroring pauseActive().
  void resumeActive() {
    _isTabActive = true;
    _keyFor(_activeIndex).currentState?.controller?.play();
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
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
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
                // Gated by _isTabActive too, not just the page index — this
                // PageView gets built (and would otherwise autoplay its
                // first item) the moment HomeShell mounts every tab into
                // its IndexedStack, long before Reels is the one on screen.
                isActive: i == _activeIndex && _isTabActive,
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
                          decoration: BoxDecoration(color: const Color(0xFF0E1917).withOpacity(0.55), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.24))),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 18, color: Colors.white70),
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
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5),
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
                    borderColor: Colors.white.withOpacity(0.24),
                    child: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white70, size: 18),
                  ).entrance(index: 1),
                  const SizedBox(width: 10),
                  _ReelIconButton(
                    onTap: _openFilters,
                    gradient: (_purpose != null || _type != 'all') ? AppColors.goldGradient : null,
                    color: (_purpose != null || _type != 'all') ? null : const Color(0xFF0E1917).withOpacity(0.55),
                    borderColor: (_purpose != null || _type != 'all') ? null : Colors.white.withOpacity(0.24),
                    child: Icon(Icons.tune_rounded, size: 18, color: (_purpose != null || _type != 'all') ? AppColors.ink : Colors.white70),
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
