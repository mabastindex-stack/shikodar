import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/session/admin_store.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../home/screens/home_shell.dart';
import 'admin_agencies_screen.dart';
import 'admin_home_placements_screen.dart';
import 'admin_offers_screen.dart';
import 'admin_users_screen.dart';
import 'create_agency_contract_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final store = context.watch<AdminStore>();
    final agencyCount = store.agencies.length;
    final listingCount = MockData.listings.length;
    final featuredCount = MockData.listings.where((l) => l.featured).length;
    final offerCount = store.offers.length;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ink, Color(0xFF2A2620)]),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.ink, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('admin.dashboard_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text('admin.dashboard_subtitle'.tr(), style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _confirmLogout(context, palette),
                    icon: Icon(Icons.logout_rounded, color: Colors.white.withOpacity(0.85), size: 20),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 320.ms),

            const SizedBox(height: 22),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _statCard(palette, Icons.storefront_outlined, '$agencyCount', 'admin.dashboard_stat_agencies'.tr(), 40),
                _statCard(palette, Icons.home_work_outlined, '$listingCount', 'dashboard.stat_active_listings_label'.tr(), 90),
                _statCard(palette, Icons.star_outline_rounded, '$featuredCount', 'admin.dashboard_stat_featured'.tr(), 140),
                _statCard(palette, Icons.campaign_outlined, '$offerCount', 'admin.dashboard_stat_active_offers'.tr(), 190),
              ],
            ),

            const SizedBox(height: 28),
            Text('admin.dashboard_quick_actions_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)).animate(delay: 220.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 14),
            _quickAction(
              context,
              palette,
              icon: Icons.add_business_rounded,
              title: 'admin.dashboard_create_agency_title'.tr(),
              subtitle: 'admin.dashboard_create_agency_subtitle'.tr(),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateAgencyContractScreen())),
              delay: 260,
            ),
            const SizedBox(height: 12),
            _quickAction(
              context,
              palette,
              icon: Icons.storefront_outlined,
              title: 'admin.dashboard_manage_agencies_title'.tr(),
              subtitle: 'admin.dashboard_manage_agencies_subtitle'.tr(),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminAgenciesScreen())),
              delay: 300,
            ),
            const SizedBox(height: 12),
            _quickAction(
              context,
              palette,
              icon: Icons.home_work_outlined,
              title: 'admin.home_placements_title'.tr(),
              subtitle: 'admin.dashboard_home_placements_subtitle'.tr(),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminHomePlacementsScreen())),
              delay: 340,
            ),
            const SizedBox(height: 12),
            _quickAction(
              context,
              palette,
              icon: Icons.campaign_outlined,
              title: 'admin.dashboard_manage_offers_title'.tr(),
              subtitle: 'admin.dashboard_manage_offers_subtitle'.tr(),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminOffersScreen())),
              delay: 380,
            ),
            const SizedBox(height: 12),
            _quickAction(
              context,
              palette,
              icon: Icons.people_alt_outlined,
              title: 'admin.dashboard_view_users_title'.tr(),
              subtitle: 'admin.dashboard_view_users_subtitle'.tr(),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
              delay: 420,
            ),

            const SizedBox(height: 28),
            Text('admin.dashboard_expiring_contracts_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)).animate(delay: 450.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 12),
            ..._expiringContractsList(store, palette),
          ],
        ),
      ),
    );
  }

  List<Widget> _expiringContractsList(AdminStore store, AppPalette palette) {
    final now = DateTime.now();
    final sorted = List.of(store.contracts)..sort((a, b) => a.endDate.compareTo(b.endDate));
    final upcoming = sorted.take(3).toList();
    if (upcoming.isEmpty) {
      return [
        Text('admin.dashboard_no_expiring_contracts'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12.5)),
      ];
    }
    return List.generate(upcoming.length, (i) {
      final contract = upcoming[i];
      final daysLeft = contract.endDate.difference(now).inDays.clamp(0, 9999);
      return Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
        child: _expiringContract(palette, contract.agencyName, contract.tier.label, daysLeft, 480 + i * 40),
      );
    });
  }

  void _confirmLogout(BuildContext context, AppPalette palette) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('settings_page.logout_dialog_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('settings_page.logout_dialog_message'.tr(), style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () {
              context.read<UserSession>().logOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeShell()),
                (route) => false,
              );
            },
            child: Text('settings_page.logout_dialog_title'.tr(), style: TextStyle(color: palette.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(AppPalette palette, IconData icon, String value, String label, int delay) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 15, color: AppColors.goldDark),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: palette.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 10.5)),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 320.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _quickAction(BuildContext context, AppPalette palette, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required int delay}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.ink, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: palette.textMuted, size: 20),
            ],
          ),
        ),
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 320.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _expiringContract(AppPalette palette, String name, String tier, int daysLeft, int delay) {
    final urgent = daysLeft <= 5;
    final statusColor = urgent ? palette.error : palette.success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                Text('packages.plan_title'.tr(args: [tier]), style: TextStyle(color: palette.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(
            daysLeft == 0 ? 'admin.dashboard_contract_expires_today'.tr() : 'admin.dashboard_days_left'.tr(args: ['$daysLeft']),
            style: TextStyle(color: statusColor, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 320.ms);
  }
}
