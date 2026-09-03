import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';

class HomeFilterState {
  bool showRent = true;
  bool showSale = true;
  String type = 'all';
}

class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.state, required this.onChanged});

  final HomeFilterState state;
  final VoidCallback onChanged;

  static const _types = <(String, IconData, String)>[
    ('all', Icons.grid_view_rounded, 'filters.all'),
    ('house', Icons.house_outlined, 'filters.house'),
    ('villa', Icons.villa_outlined, 'filters.villa'),
    ('land', Icons.landscape_outlined, 'filters.land'),
    ('shop', Icons.storefront_outlined, 'filters.shop'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, index) {
          final item = _types[index];
          return _CategoryChip(
            label: item.$3.tr(),
            icon: item.$2,
            selected: state.type == item.$1,
            onTap: () {
              state.type = item.$1;
              onChanged();
            },
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.enter,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? palette.primary : palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? palette.primary : palette.divider,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.shadow.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? palette.onPrimary : palette.primary,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? palette.onPrimary : palette.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreFiltersSheet extends StatefulWidget {
  const MoreFiltersSheet({super.key});

  @override
  State<MoreFiltersSheet> createState() => _MoreFiltersSheetState();
}

class _MoreFiltersSheetState extends State<MoreFiltersSheet> {
  RangeValues _price = const RangeValues(20000, 200000);
  RangeValues _area = const RangeValues(80, 400);
  String? _zone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: palette.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'filters.more_filters'.tr(),
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _label(context, 'filters.zone'.tr()),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'zones.shorja'.tr(),
                'zones.raparin'.tr(),
                'search.zone_center_short'.tr(),
                'zones.imam_qasim'.tr(),
              ].map((zone) {
                final selected = _zone == zone;
                return ChoiceChip(
                  label: Text(zone),
                  selected: selected,
                  onSelected: (_) => setState(() => _zone = selected ? null : zone),
                  selectedColor: palette.primary,
                  backgroundColor: palette.surfaceElevated,
                  labelStyle: TextStyle(
                    color: selected ? palette.onPrimary : palette.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _label(context, 'filters.price_range'.tr()),
            RangeSlider(
              values: _price,
              min: 0,
              max: 500000,
              activeColor: palette.primary,
              inactiveColor: palette.divider,
              onChanged: (value) => setState(() => _price = value),
            ),
            _label(context, 'filters.area'.tr()),
            RangeSlider(
              values: _area,
              min: 0,
              max: 1000,
              activeColor: palette.primary,
              inactiveColor: palette.divider,
              onChanged: (value) => setState(() => _area = value),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text('common.save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: TextStyle(
          color: palette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
