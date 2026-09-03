import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/listing.dart';
import '../../../core/session/admin_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

/// Demo-only client rows — there's no real per-user account/backend to
/// track yet, so these stay clearly illustrative. The agency rows below
/// them are real, live data from AdminStore.
const _demoClients = [
  ('ئارام حسێن', 'کەرکوک، ڕاپەرین'),
  ('شنۆ ئازاد', 'کەرکوک، ئیمام قاسم'),
  ('هەڵۆ کەریم', 'کەرکوک، ڕاپەرین'),
];

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  int _tab = 0; // 0 all, 1 clients, 2 agencies

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final agencies = context.watch<AdminStore>().agencies;
    final showClients = _tab == 0 || _tab == 1;
    final showAgencies = _tab == 0 || _tab == 2;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('admin.users_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              children: [
                Expanded(child: _tabChip(palette, 'filters.all'.tr(), 0)),
                const SizedBox(width: 8),
                Expanded(child: _tabChip(palette, 'admin.users_label_client'.tr(), 1)),
                const SizedBox(width: 8),
                Expanded(child: _tabChip(palette, 'admin.users_label_business'.tr(), 2)),
              ],
            ),
          ),
          if (showClients)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: palette.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: palette.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('admin.users_demo_notice'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 10.5))),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              children: [
                if (showClients)
                  ..._demoClients.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _userRow(palette, name: e.value.$1, subtitle: e.value.$2, badge: 'admin.users_label_client'.tr(), isAgency: false, delay: e.key * 50),
                      )),
                if (showAgencies)
                  ...agencies.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _userRow(
                          palette,
                          name: e.value.name,
                          subtitle: e.value.serviceAreas.isNotEmpty ? 'admin.users_service_areas_with_kirkuk'.tr(args: [e.value.serviceAreas.join('، ')]) : 'packages.plan_title'.tr(args: [e.value.tier.label]),
                          badge: 'admin.users_label_business'.tr(),
                          isAgency: true,
                          delay: (_demoClients.length + e.key) * 50,
                        ),
                      )),
                if (showClients && showAgencies && agencies.isEmpty && _demoClients.isEmpty)
                  Center(child: Text('admin.users_empty'.tr(), style: TextStyle(color: palette.textSecondary))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userRow(AppPalette palette, {required String name, required String subtitle, required String badge, required bool isAgency, required int delay}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: isAgency ? AppColors.goldGradient : null,
              color: isAgency ? null : palette.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(isAgency ? Icons.storefront_rounded : Icons.person, size: 17, color: isAgency ? AppColors.ink : palette.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(subtitle, style: TextStyle(color: palette.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: isAgency ? AppColors.gold.withOpacity(0.15) : palette.surfaceElevated, borderRadius: BorderRadius.circular(20)),
            child: Text(badge, style: TextStyle(color: isAgency ? AppColors.goldDark : palette.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 280.ms).slideX(begin: 0.04, end: 0);
  }

  Widget _tabChip(AppPalette palette, String label, int value) {
    final selected = _tab == value;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _tab = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? palette.textPrimary : palette.surfaceElevated, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: TextStyle(color: selected ? palette.background : palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
