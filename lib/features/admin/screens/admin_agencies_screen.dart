import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/listing.dart';
import '../../../core/session/admin_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import 'create_agency_contract_screen.dart';

class AdminAgenciesScreen extends StatelessWidget {
  const AdminAgenciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final agencies = context.watch<AdminStore>().agencies;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        automaticallyImplyLeading: false,
        title: Text('admin.agencies_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateAgencyContractScreen())),
        backgroundColor: palette.textPrimary,
        icon: Icon(Icons.add_rounded, color: palette.background),
        label: Text('admin.agencies_new_fab'.tr(), style: TextStyle(color: palette.background, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.ink, Color(0xFF2A2620)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: AppColors.gold, size: 16),
                  const SizedBox(width: 8),
                  Text('admin.agencies_active_count'.tr(args: ['${agencies.length}']), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),
          Expanded(
            child: agencies.isEmpty
                ? Center(child: Text('admin.agencies_empty'.tr(), style: TextStyle(color: palette.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: agencies.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _agencyCard(context, palette, agencies[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _agencyCard(BuildContext context, AppPalette palette, Agency a, int i) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openEditSheet(context, a),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                child: const Icon(Icons.storefront_rounded, color: AppColors.ink, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(a.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w700))),
                        if (a.verified) ...[const SizedBox(width: 5), const Icon(Icons.verified_rounded, color: AppColors.goldDark, size: 15)],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('packages.plan_title'.tr(args: [a.tier.label]), style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: palette.textMuted, size: 20),
            ],
          ),
        ),
      ),
    ).animate(delay: (60 * i).ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
  }

  void _openEditSheet(BuildContext context, Agency agency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _AgencyEditSheet(agency: agency),
    );
  }
}

class _AgencyEditSheet extends StatefulWidget {
  const _AgencyEditSheet({required this.agency});
  final Agency agency;

  @override
  State<_AgencyEditSheet> createState() => _AgencyEditSheetState();
}

class _AgencyEditSheetState extends State<_AgencyEditSheet> {
  late PackageTier _tier = widget.agency.tier;
  late bool _verified = widget.agency.verified;

  void _confirmDelete() {
    final palette = context.palette;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('admin.agencies_delete_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('admin.agencies_delete_message'.tr(args: [widget.agency.name]), style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () {
              context.read<AdminStore>().removeAgency(widget.agency.id);
              Navigator.pop(dialogContext); // dialog
              Navigator.pop(context); // sheet
            },
            child: Text('my_listings.delete_action'.tr(), style: TextStyle(color: palette.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _save() {
    context.read<AdminStore>().updateAgency(widget.agency.copyWith(tier: _tier, verified: _verified));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.agencies_save_success'.tr()), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(22, 20, 22, 22 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: palette.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: palette.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.ink, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.agency.name, style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 20),
            Text('admin.package_field_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PackageTier.values.map((t) {
                final selected = _tier == t;
                return GestureDetector(
                  onTap: () => setState(() => _tier = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.goldGradient : null,
                      color: selected ? null : palette.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(t.label, style: TextStyle(color: selected ? AppColors.ink : palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _verified,
              onChanged: (v) => setState(() => _verified = v),
              activeColor: palette.primary,
              title: Text('admin.agencies_verified_toggle_label'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: palette.primary, foregroundColor: palette.onPrimary, padding: const EdgeInsets.symmetric(vertical: 15)),
                child: Text('common.save'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmDelete,
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: palette.error),
                label: Text('admin.agencies_delete_title'.tr(), style: TextStyle(color: palette.error)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: palette.error.withOpacity(0.4)), padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
