import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_palette.dart';
import 'admin_dashboard_screen.dart';
import 'admin_agencies_screen.dart';
import 'admin_home_placements_screen.dart';
import 'admin_offers_screen.dart';
import 'admin_support_screen.dart';

/// The administrator's own shell — entirely separate from the
/// client/agency HomeShell, since admins never browse listings, they run
/// the platform.
class AdminHomeShell extends StatefulWidget {
  const AdminHomeShell({super.key});

  @override
  State<AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends State<AdminHomeShell> {
  int _index = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminAgenciesScreen(),
    AdminHomePlacementsScreen(),
    AdminOffersScreen(),
    AdminSupportScreen(),
  ];

  // A getter (not a `static const`) so each label re-evaluates `.tr()`
  // against the current locale at call time, instead of being frozen at
  // compile time.
  static List<(IconData, IconData, String)> get _items => [
        (Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'profile.dashboard'.tr()),
        (Icons.storefront_outlined, Icons.storefront_rounded, 'admin.agencies_title'.tr()),
        (Icons.home_work_outlined, Icons.home_work_rounded, 'admin.nav_home_label'.tr()),
        (Icons.campaign_outlined, Icons.campaign_rounded, 'offers.title'.tr()),
        (Icons.support_agent_outlined, Icons.support_agent_rounded, 'admin.support_title'.tr()),
      ];

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        backgroundColor: palette.surface,
        indicatorColor: palette.gold.withOpacity(0.15),
        destinations: _items
            .map((it) => NavigationDestination(
                  icon: Icon(it.$1, color: palette.textSecondary),
                  selectedIcon: Icon(it.$2, color: palette.gold),
                  label: it.$3,
                ))
            .toList(),
      ),
    );
  }
}
