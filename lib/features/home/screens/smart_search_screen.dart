import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import 'search_results_screen.dart';

enum SortOption { newest, priceLow, priceHigh }

// Raw zone values match `Listing.zone` in the mock data (which stays in
// Kurdish) — only the label shown to the user is localized, via
// `_zoneLabel` below, so filtering keeps working regardless of locale.
const _zones = <String>[
  'هەموو',
  'شۆڕجە',
  'ڕاپەرین',
  'ناوەڕاستی شار',
  'ئیمام قاسم',
  'ئازادی',
  'گرناتە',
];

String _zoneLabel(String zone) {
  switch (zone) {
    case 'هەموو':
      return 'zones.all'.tr();
    case 'شۆڕجە':
      return 'zones.shorja'.tr();
    case 'ڕاپەرین':
      return 'zones.raparin'.tr();
    case 'ناوەڕاستی شار':
      return 'zones.city_center'.tr();
    case 'ئیمام قاسم':
      return 'zones.imam_qasim'.tr();
    case 'ئازادی':
      return 'zones.azadi'.tr();
    case 'گرناتە':
      return 'zones.granata'.tr();
    default:
      return zone;
  }
}

class SmartSearchScreen extends StatefulWidget {
  const SmartSearchScreen({super.key});

  @override
  State<SmartSearchScreen> createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends State<SmartSearchScreen> {
  final TextEditingController _keywordController = TextEditingController();
  ListingPurpose? _purpose;
  String _type = 'all';
  String _zone = 'هەموو';
  RangeValues _price = const RangeValues(0, 250000);
  RangeValues _area = const RangeValues(0, 500);
  int? _rooms;
  bool _verifiedOnly = false;
  SortOption _sort = SortOption.newest;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  List<Listing> get _matches => MockData.listings.where((listing) {
        final keyword = _keywordController.text.trim().toLowerCase();
        if (keyword.isNotEmpty &&
            !listing.title.toLowerCase().contains(keyword) &&
            !listing.zone.toLowerCase().contains(keyword) &&
            !listing.agency.name.toLowerCase().contains(keyword)) {
          return false;
        }
        if (_zone != 'هەموو' && listing.zone != _zone) return false;
        if (_purpose != null && listing.purpose != _purpose) return false;
        if (_type != 'all' && listing.type.name != _type) return false;
        if (listing.price < _price.start || listing.price > _price.end) return false;
        if (listing.areaSqm != null &&
            (listing.areaSqm! < _area.start || listing.areaSqm! > _area.end)) {
          return false;
        }
        if (_rooms != null &&
            (listing.rooms == null ||
                (_rooms == 4 ? listing.rooms! < 4 : listing.rooms != _rooms))) {
          return false;
        }
        if (_verifiedOnly && !listing.agency.verified) return false;
        return true;
      }).toList();

  void _reset() {
    setState(() {
      _keywordController.clear();
      _purpose = null;
      _type = 'all';
      _zone = 'هەموو';
      _price = const RangeValues(0, 250000);
      _area = const RangeValues(0, 500);
      _rooms = null;
      _verifiedOnly = false;
      _sort = SortOption.newest;
    });
  }

  void _search() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: AppMotion.expressive,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
          child: SearchResultsScreen(
            keyword: _keywordController.text.trim(),
            zone: _zone,
            purpose: _purpose,
            type: _type,
            priceRange: _price,
            areaRange: _area,
            rooms: _rooms,
            verifiedOnly: _verifiedOnly,
            sort: _sort,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resultCount = _matches.length;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        title: Text(
          'search.smart_search'.tr(),
          style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(
              'search.clear'.tr(),
              style: TextStyle(color: palette.primary, fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: _SearchButton(count: resultCount, onTap: _search),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: palette.divider),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _keywordController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'search.hint'.tr(),
                hintStyle: TextStyle(color: palette.textMuted, fontSize: 12.5),
                prefixIcon: Icon(Icons.search_rounded, color: palette.primary, size: 20),
                suffixIcon: _keywordController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _keywordController.clear();
                          setState(() {});
                        },
                        icon: Icon(Icons.close_rounded, color: palette.textMuted, size: 18),
                      ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ResultPreview(count: resultCount),
          const SizedBox(height: 18),
          _FilterPanel(
            title: 'search.location_label'.tr(),
            icon: Icons.location_on_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _zones.map((zone) {
                return _ChoicePill(
                  label: _zoneLabel(zone),
                  selected: _zone == zone,
                  onTap: () => setState(() => _zone = zone),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _FilterPanel(
            title: 'search.purpose_label'.tr(),
            icon: Icons.key_outlined,
            child: Row(
              children: [
                Expanded(
                  child: _Segment(
                    label: 'filters.all'.tr(),
                    selected: _purpose == null,
                    onTap: () => setState(() => _purpose = null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Segment(
                    label: 'filters.rent'.tr(),
                    selected: _purpose == ListingPurpose.rent,
                    onTap: () => setState(() => _purpose = ListingPurpose.rent),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Segment(
                    label: 'filters.sale'.tr(),
                    selected: _purpose == ListingPurpose.sale,
                    onTap: () => setState(() => _purpose = ListingPurpose.sale),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FilterPanel(
            title: 'search.type_label'.tr(),
            icon: Icons.apartment_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TypePill(value: 'all', label: 'filters.all'.tr(), icon: Icons.grid_view_rounded, selected: _type == 'all', onTap: _setType),
                _TypePill(value: 'house', label: 'filters.house'.tr(), icon: Icons.house_outlined, selected: _type == 'house', onTap: _setType),
                _TypePill(value: 'villa', label: 'filters.villa'.tr(), icon: Icons.villa_outlined, selected: _type == 'villa', onTap: _setType),
                _TypePill(value: 'land', label: 'filters.land'.tr(), icon: Icons.landscape_outlined, selected: _type == 'land', onTap: _setType),
                _TypePill(value: 'shop', label: 'filters.shop'.tr(), icon: Icons.storefront_outlined, selected: _type == 'shop', onTap: _setType),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _RangePanel(
            title: 'filters.price_range'.tr(),
            valueText: '\$${_price.start.toStringAsFixed(0)} — \$${_price.end.toStringAsFixed(0)}',
            values: _price,
            min: 0,
            max: 250000,
            divisions: 25,
            onChanged: (value) => setState(() => _price = value),
          ),
          const SizedBox(height: 14),
          _RangePanel(
            title: 'filters.area'.tr(),
            valueText: '${_area.start.toStringAsFixed(0)} — ${_area.end.toStringAsFixed(0)} ${'listing.sqm'.tr()}',
            values: _area,
            min: 0,
            max: 500,
            divisions: 25,
            onChanged: (value) => setState(() => _area = value),
          ),
          const SizedBox(height: 14),
          _FilterPanel(
            title: 'filters.rooms'.tr(),
            icon: Icons.bed_outlined,
            child: Row(
              children: [1, 2, 3, 4].map((room) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 7),
                    child: _RoomButton(
                      label: room == 4 ? '+٤' : '$room',
                      selected: _rooms == room,
                      onTap: () => setState(() => _rooms = _rooms == room ? null : room),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _FilterPanel(
            title: 'search.sort_label'.tr(),
            icon: Icons.swap_vert_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChoicePill(label: 'search.sort_newest'.tr(), selected: _sort == SortOption.newest, onTap: () => setState(() => _sort = SortOption.newest)),
                _ChoicePill(label: 'search.sort_price_low'.tr(), selected: _sort == SortOption.priceLow, onTap: () => setState(() => _sort = SortOption.priceLow)),
                _ChoicePill(label: 'search.sort_price_high'.tr(), selected: _sort == SortOption.priceHigh, onTap: () => setState(() => _sort = SortOption.priceHigh)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _VerifiedSwitch(
            value: _verifiedOnly,
            onChanged: (value) => setState(() => _verifiedOnly = value),
          ),
        ],
      ),
    );
  }

  void _setType(String value) => setState(() => _type = value);
}

class _ResultPreview extends StatelessWidget {
  const _ResultPreview({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.emeraldDark, AppColors.emerald]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x3DE1C58F)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.goldLight, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text('search.matching_results'.tr(), style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
          Text('$count', style: const TextStyle(color: AppColors.goldLight, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: palette.gold, size: 18), const SizedBox(width: 8), Text(title, style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? palette.primary : palette.surfaceElevated,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? palette.primary : palette.divider),
        ),
        child: Text(label, style: TextStyle(color: selected ? palette.onPrimary : palette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? palette.primary : palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
        child: Text(label, style: TextStyle(color: selected ? palette.onPrimary : palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.value, required this.label, required this.icon, required this.selected, required this.onTap});
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: selected ? palette.primary : palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: selected ? palette.onPrimary : palette.primary), const SizedBox(width: 6), Text(label, style: TextStyle(color: selected ? palette.onPrimary : palette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w700))]),
      ),
    );
  }
}

class _RangePanel extends StatelessWidget {
  const _RangePanel({required this.title, required this.valueText, required this.values, required this.min, required this.max, required this.divisions, required this.onChanged});
  final String title;
  final String valueText;
  final RangeValues values;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: palette.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(title, style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800)), const Spacer(), Text(valueText, style: TextStyle(color: palette.primary, fontSize: 11.5, fontWeight: FontWeight.w800))]), RangeSlider(values: values, min: min, max: max, divisions: divisions, activeColor: palette.primary, inactiveColor: palette.divider, onChanged: onChanged)]),
    );
  }
}

class _RoomButton extends StatelessWidget {
  const _RoomButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13), child: AnimatedContainer(duration: AppMotion.quick, height: 43, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? palette.primary : palette.surfaceElevated, borderRadius: BorderRadius.circular(13)), child: Text(label, style: TextStyle(color: selected ? palette.onPrimary : palette.textSecondary, fontWeight: FontWeight.w800))));
  }
}

class _VerifiedSwitch extends StatelessWidget {
  const _VerifiedSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: value ? palette.gold : palette.divider)),
      child: Row(children: [Icon(Icons.verified_rounded, color: palette.gold, size: 20), const SizedBox(width: 10), Expanded(child: Text('search.verified_only'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700))), Switch(value: value, onChanged: onChanged, activeColor: palette.primary)]),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.search_rounded, size: 20),
      label: Text('search.search_button'.tr(args: ['$count'])),
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
    );
  }
}
