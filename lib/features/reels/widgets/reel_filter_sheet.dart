import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';

/// Premium bottom sheet holding the purpose + type filters — opened by
/// tapping the single filter icon on Reels, so the video stays uncluttered
/// until the client actually wants to filter.
class ReelFilterSheet extends StatefulWidget {
  final ListingPurpose? purpose;
  final String type;
  const ReelFilterSheet({super.key, required this.purpose, required this.type});

  @override
  State<ReelFilterSheet> createState() => _ReelFilterSheetState();
}

class _ReelFilterSheetState extends State<ReelFilterSheet> {
  late ListingPurpose? _purpose = widget.purpose;
  late String _type = widget.type;

  static const _types = [
    ('all', Icons.apps_rounded, 'filters.all'),
    ('house', Icons.house_rounded, 'filters.house'),
    ('villa', Icons.villa_rounded, 'filters.villa'),
    ('land', Icons.terrain_rounded, 'filters.land'),
    ('shop', Icons.storefront_rounded, 'filters.shop'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(color: palette.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: palette.divider, borderRadius: BorderRadius.circular(2)))),
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.tune_rounded, size: 14, color: AppColors.ink),
              ),
              const SizedBox(width: 8),
              Text('reels.filter_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),

          Text('my_projects.unit_purpose_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _pill(context, 'filters.all'.tr(), _purpose == null, () => setState(() => _purpose = null))),
              const SizedBox(width: 8),
              Expanded(child: _pill(context, 'filters.rent'.tr(), _purpose == ListingPurpose.rent, () => setState(() => _purpose = ListingPurpose.rent))),
              const SizedBox(width: 8),
              Expanded(child: _pill(context, 'filters.sale'.tr(), _purpose == ListingPurpose.sale, () => setState(() => _purpose = ListingPurpose.sale))),
            ],
          ),
          const SizedBox(height: 20),

          Text('search.type_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) => _typeChip(context, t.$1, t.$3.tr(), t.$2)).toList(),
          ),

          const SizedBox(height: 26),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => Navigator.pop(context, (_purpose, _type)),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Text('reels.apply_filters'.tr(), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 14.5)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms, curve: AppMotion.enter).slideY(begin: 0.06, end: 0, duration: 340.ms, curve: AppMotion.emphasized);
  }

  Widget _pill(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(gradient: selected ? AppColors.goldGradient : null, color: selected ? null : palette.surfaceElevated, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: TextStyle(color: selected ? AppColors.ink : palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _typeChip(BuildContext context, String value, String label, IconData icon) {
    final palette = context.palette;
    final selected = _type == value;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => _type = value),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: selected ? AppColors.ink : palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : AppColors.goldDark),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: selected ? Colors.white : palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
