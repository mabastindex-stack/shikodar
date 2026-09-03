import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/session/business_profile_store.dart';
import '../../../core/theme/app_palette.dart';

// NOTE: these lists are the actual stored/compared values (BusinessProfileStore
// keeps specialties/serviceAreas as raw Kurdish strings), so the values below
// must stay exactly as-is for selection state to keep matching. Only the
// *displayed* chip label is localized, via _specialtyLabel/_zoneLabel below.
const _specialtyOptions = <String>['خانوو/شوقە', 'ڤیلا', 'زەوی', 'موڵکی بازرگانی', 'مجمع سکنی'];
const _zoneOptions = <String>['شۆڕجە', 'ڕاپەرین', 'ناوەڕاستی شار', 'ئیمام قاسم', 'ئازادی', 'گرناتە', 'ڕاهیمناوە', 'شەقامی ٦٠ مەتری'];

String _specialtyLabel(String option) => switch (option) {
      'خانوو/شوقە' => 'edit_business_profile.specialty_house_shop'.tr(),
      'ڤیلا' => 'filters.villa'.tr(),
      'زەوی' => 'filters.land'.tr(),
      'موڵکی بازرگانی' => 'edit_business_profile.specialty_commercial'.tr(),
      'مجمع سکنی' => 'edit_business_profile.specialty_complex'.tr(),
      _ => option,
    };

String _identityLabel(String option) => option;

String _zoneLabel(String option) => switch (option) {
      'شۆڕجە' => 'zones.shorja'.tr(),
      'ڕاپەرین' => 'zones.raparin'.tr(),
      'ناوەڕاستی شار' => 'zones.city_center'.tr(),
      'ئیمام قاسم' => 'zones.imam_qasim'.tr(),
      'ئازادی' => 'zones.azadi'.tr(),
      'گرناتە' => 'zones.granata'.tr(),
      'ڕاهیمناوە' => 'edit_business_profile.zone_raihimawa'.tr(),
      'شەقامی ٦٠ مەتری' => 'zones.sixty_meter_street'.tr(),
      _ => option,
    };
const _milestoneIcons = <IconData>[
  Icons.flag_circle_rounded,
  Icons.apartment_rounded,
  Icons.groups_rounded,
  Icons.verified_rounded,
  Icons.star_rounded,
  Icons.trending_up_rounded,
];

/// Everything a business account sets about itself that shows up on the
/// PUBLIC profile (AgencyProfileScreen's "About" tab, or — for a company —
/// DeveloperProfileScreen's achievement timeline). Reached from the owner's
/// own Profile tab; writes go straight to BusinessProfileStore, so the
/// public profile reflects the edit immediately.
class EditBusinessProfileScreen extends StatefulWidget {
  const EditBusinessProfileScreen({super.key, required this.isCompany});

  final bool isCompany;

  @override
  State<EditBusinessProfileScreen> createState() => _EditBusinessProfileScreenState();
}

class _EditBusinessProfileScreenState extends State<EditBusinessProfileScreen> {
  late final TextEditingController _bioController;
  late Set<String> _specialties;
  late Set<String> _serviceAreas;

  @override
  void initState() {
    super.initState();
    final store = context.read<BusinessProfileStore>();
    _bioController = TextEditingController(text: store.bio);
    _specialties = Set.of(store.specialties);
    _serviceAreas = Set.of(store.serviceAreas);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _save() {
    context.read<BusinessProfileStore>().updateAbout(
          bio: _bioController.text.trim(),
          specialties: _specialties,
          serviceAreas: _serviceAreas,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('edit_business_profile.save_success'.tr()), behavior: SnackBarBehavior.floating),
    );
    Navigator.pop(context);
  }

  Future<void> _addMilestone() async {
    final result = await showModalBottomSheet<Milestone>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AddMilestoneSheet(),
    );
    if (result != null && mounted) {
      context.read<BusinessProfileStore>().addMilestone(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('edit_business_profile.title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('common.save'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _label(palette, 'edit_business_profile.about_company_label'.tr()),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: TextField(
              controller: _bioController,
              maxLines: 5,
              style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'edit_business_profile.bio_hint'.tr(),
                hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: palette.surface,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _label(palette, 'edit_business_profile.specialties_label'.tr()),
          const SizedBox(height: 10),
          _chipWrap(palette, options: _specialtyOptions, selected: _specialties, onToggle: (v) => setState(() => _specialties.contains(v) ? _specialties.remove(v) : _specialties.add(v)), labelBuilder: _specialtyLabel),
          const SizedBox(height: 24),
          _label(palette, 'edit_business_profile.service_areas_label'.tr()),
          const SizedBox(height: 10),
          _chipWrap(palette, options: _zoneOptions, selected: _serviceAreas, onToggle: (v) => setState(() => _serviceAreas.contains(v) ? _serviceAreas.remove(v) : _serviceAreas.add(v)), labelBuilder: _zoneLabel),
          if (widget.isCompany) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(child: _label(palette, 'edit_business_profile.experience_label'.tr())),
                TextButton.icon(
                  onPressed: _addMilestone,
                  icon: Icon(Icons.add_rounded, color: palette.primary, size: 18),
                  label: Text('my_projects.add_button'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            Consumer<BusinessProfileStore>(
              builder: (context, store, _) => Column(
                children: List.generate(store.milestones.length, (i) {
                  final m = store.milestones[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: palette.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Icon(m.icon, size: 17, color: palette.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.year, style: TextStyle(color: palette.primary, fontSize: 11.5, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(m.title, style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.read<BusinessProfileStore>().removeMilestoneAt(i),
                            icon: Icon(Icons.close_rounded, color: palette.textMuted, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(AppPalette palette, String text) => Text(text, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600));

  Widget _chipWrap(AppPalette palette, {required List<String> options, required Set<String> selected, required ValueChanged<String> onToggle, String Function(String) labelBuilder = _identityLabel}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          child: InkWell(
            onTap: () => onToggle(option),
            borderRadius: BorderRadius.circular(99),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? palette.primary : palette.surfaceElevated,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: isSelected ? palette.primary : palette.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                  ],
                  Text(labelBuilder(option), style: TextStyle(color: isSelected ? Colors.white : palette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AddMilestoneSheet extends StatefulWidget {
  const _AddMilestoneSheet();

  @override
  State<_AddMilestoneSheet> createState() => _AddMilestoneSheetState();
}

class _AddMilestoneSheetState extends State<_AddMilestoneSheet> {
  final _yearController = TextEditingController();
  final _titleController = TextEditingController();
  IconData _selectedIcon = _milestoneIcons.first;

  @override
  void dispose() {
    _yearController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_yearController.text.trim().isEmpty || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.field_required'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    Navigator.pop(
      context,
      Milestone(year: _yearController.text.trim(), title: _titleController.text.trim(), icon: _selectedIcon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              Text('edit_business_profile.add_milestone_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: palette.textPrimary),
                decoration: InputDecoration(hintText: 'edit_business_profile.milestone_year_hint'.tr()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                style: TextStyle(color: palette.textPrimary),
                decoration: InputDecoration(hintText: 'edit_business_profile.milestone_event_hint'.tr()),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: _milestoneIcons.map((icon) {
                  final selected = icon == _selectedIcon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icon),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selected ? palette.primary : palette.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: selected ? Colors.white : palette.textSecondary, size: 20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _confirm, child: Text('my_projects.add_button'.tr())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
