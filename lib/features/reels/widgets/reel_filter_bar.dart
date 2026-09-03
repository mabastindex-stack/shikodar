import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';

class ReelFilterBar extends StatelessWidget {
  final ListingPurpose purpose;
  final String type;
  final ValueChanged<ListingPurpose> onPurposeChanged;
  final ValueChanged<String> onTypeChanged;

  const ReelFilterBar({
    super.key,
    required this.purpose,
    required this.type,
    required this.onPurposeChanged,
    required this.onTypeChanged,
  });

  static const _types = [
    ('all', Icons.apps_rounded, 'filters.all'),
    ('house', Icons.house_outlined, 'filters.house'),
    ('villa', Icons.villa_outlined, 'filters.villa'),
    ('land', Icons.map_outlined, 'filters.land'),
    ('shop', Icons.storefront_outlined, 'filters.shop'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.38),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Column(
              children: [
                // Rent / Sale segmented control with icons.
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Expanded(child: _pillTab(context, ListingPurpose.rent, 'filters.rent'.tr(), Icons.vpn_key_outlined)),
                      Expanded(child: _pillTab(context, ListingPurpose.sale, 'filters.sale'.tr(), Icons.sell_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Type chips.
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _types.map((t) => _typeChip(t.$1, t.$2, t.$3.tr())).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).entrance();
  }

  Widget _pillTab(BuildContext context, ListingPurpose value, String label, IconData icon) {
    final selected = purpose == value;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onPurposeChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.goldGradient : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? AppColors.ink : Colors.white70),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: selected ? AppColors.ink : Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String value, IconData icon, String label) {
    final selected = type == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => onTypeChanged(value),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected ? AppColors.goldGradient : null,
              color: selected ? null : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: selected ? null : Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: selected ? AppColors.ink : Colors.white70),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(color: selected ? AppColors.ink : Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
