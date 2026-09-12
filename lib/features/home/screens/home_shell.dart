import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../profile/screens/profile_screen.dart';
import '../../projects/screens/projects_list_screen.dart';
import '../../reels/screens/reels_screen.dart';
import 'home_feed_screen.dart';
import 'search_map_screen.dart';

const _homeIndex = 2;

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

const _searchIndex = 0;
const _reelsIndex = 1;

class _HomeShellState extends State<HomeShell> {
  int _index = _homeIndex;

  final _searchMapKey = GlobalKey<SearchMapScreenState>();
  final _reelsKey = GlobalKey<ReelsScreenState>();
  final _homeFeedKey = GlobalKey<HomeFeedScreenState>();

  late final _screens = <Widget>[
    SearchMapScreen(key: _searchMapKey),
    ReelsScreen(key: _reelsKey),
    HomeFeedScreen(key: _homeFeedKey),
    const ProjectsListScreen(),
    const ProfileScreen(),
  ];

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    // Reels stays mounted (and playing) inside the IndexedStack below —
    // pause it the moment we leave, or its video/audio keeps running
    // invisibly in the background on whatever tab we switch to.
    if (_index == _reelsIndex) _reelsKey.currentState?.pauseActive();
    setState(() => _index = index);
    // These tabs stay alive in the IndexedStack for the whole app session,
    // so without this they'd keep showing whatever existed at app launch —
    // never anything published afterwards.
    if (index == _searchIndex) _searchMapKey.currentState?.refresh();
    if (index == _reelsIndex) {
      _reelsKey.currentState?.refresh();
      _reelsKey.currentState?.resumeActive();
    }
    if (index == _homeIndex) _homeFeedKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      extendBody: true,
      // Without this, focusing Reels' search field made THIS Scaffold (the
      // ancestor of every tab, not just Reels' own nested one) squeeze its
      // whole IndexedStack upward to clear the keyboard — the reel video
      // visibly shrank even after Reels' own Scaffold got the same fix,
      // because this outer one was resizing the body first.
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 86,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LuxuryNavigationBar(index: _index, onSelect: _select),
              ),
              Positioned(
                bottom: 24,
                child: _HomeButton(
                  selected: _index == _homeIndex,
                  onTap: () => _select(_homeIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

// Verified directly against the Flutter SDK's CupertinoIcons source before
// use — the earlier build broke on a guessed `building_2` outline that
// doesn't actually exist; only `building_2_fill` does, so that tab reuses
// it for both states and leans on color (like the rest of the bar) to show
// selection.
List<_NavDestination> get _destinations => <_NavDestination>[
      _NavDestination(CupertinoIcons.compass, CupertinoIcons.compass_fill, 'nav.search'.tr()),
      _NavDestination(CupertinoIcons.play_circle, CupertinoIcons.play_circle_fill, 'nav.reels'.tr()),
      _NavDestination(CupertinoIcons.building_2_fill, CupertinoIcons.building_2_fill, 'nav.projects'.tr()),
      _NavDestination(CupertinoIcons.person, CupertinoIcons.person_fill, 'nav.me'.tr()),
    ];

const _destinationIndexes = <int>[0, 1, 3, 4];

class _LuxuryNavigationBar extends StatelessWidget {
  const _LuxuryNavigationBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(29),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: palette.surface.withOpacity(isDark ? 0.88 : 0.86),
            borderRadius: BorderRadius.circular(29),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.09)
                  : Colors.white.withOpacity(0.75),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withOpacity(isDark ? 0.55 : 0.34),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              _item(context, 0),
              _item(context, 1),
              const SizedBox(width: 68),
              _item(context, 2),
              _item(context, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int destinationIndex) {
    final palette = context.palette;
    final screenIndex = _destinationIndexes[destinationIndex];
    final destination = _destinations[destinationIndex];
    final selected = index == screenIndex;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: InkWell(
          onTap: () => onSelect(screenIndex),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: AppMotion.standard,
            curve: AppMotion.enter,
            margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [palette.primary.withOpacity(0.16), palette.primary.withOpacity(0.06)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: AppMotion.quick,
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    key: ValueKey(selected),
                    color: selected ? palette.primary : palette.textMuted,
                    size: 23,
                  ),
                ),
                AnimatedSize(
                  duration: AppMotion.quick,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            destination.label,
                            maxLines: 1,
                            style: TextStyle(
                              color: palette.primary,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatefulWidget {
  const _HomeButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'nav.home'.tr(),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: AppMotion.quick,
          curve: AppMotion.enter,
          child: AnimatedContainer(
            duration: AppMotion.standard,
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
              border: Border.all(color: palette.background, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withOpacity(widget.selected ? 0.38 : 0.24),
                  blurRadius: widget.selected ? 24 : 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.selected ? CupertinoIcons.house_fill : CupertinoIcons.house,
                  color: Colors.white,
                  size: 26,
                ),
                Positioned(
                  bottom: 10,
                  child: AnimatedContainer(
                    duration: AppMotion.quick,
                    width: widget.selected ? 13 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
