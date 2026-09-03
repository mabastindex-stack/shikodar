import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/mock/kirkuk_neighborhoods.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';

List<String> get _stepTitles => [
      'my_projects.step_basics_title'.tr(),
      'my_projects.step_details_title'.tr(),
      'my_projects.step_photos_title'.tr(),
      'my_projects.step_units_title'.tr(),
    ];
List<String> get _stepSubtitles => [
      'my_projects.step_basics_subtitle'.tr(),
      'my_projects.step_details_subtitle'.tr(),
      'my_projects.step_photos_subtitle'.tr(),
      'my_projects.step_units_subtitle'.tr(),
    ];

IconData _typeIcon(ListingType type) {
  switch (type) {
    case ListingType.villa:
      return Icons.villa_rounded;
    case ListingType.house:
      return Icons.home_rounded;
    case ListingType.land:
      return Icons.terrain_rounded;
    case ListingType.shop:
      return Icons.storefront_rounded;
  }
}

String _typeLabel(ListingType type) {
  switch (type) {
    case ListingType.villa:
      return 'filters.villa'.tr();
    case ListingType.house:
      return 'my_projects.type_house'.tr();
    case ListingType.land:
      return 'filters.land'.tr();
    case ListingType.shop:
      return 'filters.shop'.tr();
  }
}

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  static const _stepCount = 4;
  final _pageController = PageController();
  int _step = 0;

  final _nameController = TextEditingController();
  KirkukNeighborhood? _neighborhood;
  ProjectStatus _status = ProjectStatus.underConstruction;
  final _priceFromController = TextEditingController();
  final _priceToController = TextEditingController();
  final _paymentPlanController = TextEditingController();
  final _completionInfoController = TextEditingController();
  final _videoUrlController = TextEditingController();

  final _descriptionController = TextEditingController();
  final List<TextEditingController> _highlightControllers = [];
  final List<TextEditingController> _amenityControllers = [];

  final List<File> _photos = [];

  final List<UnitType> _unitTypes = [];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _priceFromController.dispose();
    _priceToController.dispose();
    _paymentPlanController.dispose();
    _completionInfoController.dispose();
    _videoUrlController.dispose();
    _descriptionController.dispose();
    for (final c in [..._highlightControllers, ..._amenityControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _errorForStep(int step) {
    switch (step) {
      case 0:
        if (_nameController.text.trim().length < 3) return 'my_projects.error_name_required'.tr();
        if (_neighborhood == null) return 'my_projects.error_zone_required'.tr();
        final from = double.tryParse(_priceFromController.text.trim());
        final to = double.tryParse(_priceToController.text.trim());
        if (from == null || to == null || from <= 0 || to < from) return 'my_projects.error_price_range_invalid'.tr();
        return null;
      case 1:
        if (_descriptionController.text.trim().length < 30) return 'my_projects.error_description_length'.tr();
        return null;
      case 2:
        if (_photos.length < 3) return 'my_projects.error_photos_min'.tr();
        return null;
      default:
        return null;
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));

  void _next() {
    final error = _errorForStep(_step);
    if (error != null) {
      _showError(error);
      return;
    }
    if (_step == _stepCount - 1) {
      _submit();
      return;
    }
    setState(() => _step++);
    _pageController.animateToPage(_step, duration: const Duration(milliseconds: 340), curve: Curves.easeInOutCubic);
  }

  void _back() {
    if (_step == 0) {
      _confirmDiscard();
      return;
    }
    setState(() => _step--);
    _pageController.animateToPage(_step, duration: const Duration(milliseconds: 340), curve: Curves.easeInOutCubic);
  }

  Future<void> _confirmDiscard() async {
    final palette = context.palette;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('my_projects.discard_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('my_projects.discard_message'.tr(), style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('onboarding.next'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('my_projects.discard_confirm'.tr(), style: TextStyle(color: palette.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= 3) {
      _showError('my_projects.error_photos_max'.tr());
      return;
    }
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1600, limit: 3 - _photos.length);
      if (picked.isEmpty) return;
      setState(() => _photos.addAll(picked.map((x) => File(x.path))));
    } catch (_) {
      if (!mounted) return;
      _showError('my_projects.error_photos_pick_failed'.tr());
    }
  }

  void _addUnitType(UnitType unit) => setState(() => _unitTypes.add(unit));
  void _removeUnitType(int i) => setState(() => _unitTypes.removeAt(i));

  void _submit() {
    final project = Project(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      zone: _neighborhood!.name,
      images: _photos.map((f) => f.path).toList(),
      videoUrl: _videoUrlController.text.trim(),
      priceFrom: double.parse(_priceFromController.text.trim()),
      priceTo: double.parse(_priceToController.text.trim()),
      status: _status,
      description: _descriptionController.text.trim(),
      highlights: _highlightControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      amenities: _amenityControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
      unitTypes: _unitTypes,
      agencyName: MockData.agencyShiko.name,
      agency: MockData.agencyShiko,
      paymentPlan: _paymentPlanController.text.trim(),
      completionInfo: _completionInfoController.text.trim(),
      specs: const [],
    );
    mockProjects.add(project);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(palette),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _basicsStep(palette),
                  _detailsStep(palette),
                  _photosStep(palette),
                  _unitsStep(palette),
                ],
              ),
            ),
            _bottomBar(palette),
          ],
        ),
      ),
    );
  }

  Widget _header(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _back,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: palette.surfaceElevated, shape: BoxShape.circle),
                  child: Icon(_step == 0 ? Icons.close_rounded : Icons.arrow_forward_rounded, size: 19, color: palette.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_stepTitles[_step], style: TextStyle(color: palette.textPrimary, fontSize: 16.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(_stepSubtitles[_step], style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ),
              Text('${_step + 1}/$_stepCount', style: TextStyle(color: palette.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(_stepCount, (i) {
              final active = i <= _step;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == _stepCount - 1 ? 0 : 6),
                  child: AnimatedContainer(
                    duration: AppMotion.standard,
                    height: 4,
                    decoration: BoxDecoration(color: active ? palette.primary : palette.divider, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(AppPalette palette) {
    final isLast = _step == _stepCount - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: palette.surface, border: Border(top: BorderSide(color: palette.divider))),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _next,
          icon: Icon(isLast ? Icons.check_circle_rounded : Icons.arrow_back_rounded, size: 19),
          label: Text(isLast ? 'my_projects.publish_button'.tr() : 'my_projects.next_button'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isLast ? AppColors.gold : palette.primary,
            foregroundColor: isLast ? AppColors.ink : palette.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(AppPalette palette, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
      );

  InputDecoration _inputDecoration(AppPalette palette, {String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
        filled: true,
        fillColor: palette.surfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _basicsStep(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        _fieldLabel(palette, 'my_projects.name_label'.tr()),
        TextField(controller: _nameController, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'my_projects.name_hint'.tr())),
        const SizedBox(height: 20),
        _fieldLabel(palette, 'my_projects.zone_label'.tr()),
        GestureDetector(
          onTap: _pickNeighborhood,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: palette.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _neighborhood?.name ?? 'my_projects.select_neighborhood_placeholder'.tr(),
                    style: TextStyle(color: _neighborhood == null ? palette.textMuted : palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: palette.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _fieldLabel(palette, 'my_projects.status_label'.tr()),
        Row(
          children: [
            Expanded(child: _choiceChip(palette, 'my_projects.status_building_choice'.tr(), Icons.construction_rounded, _status == ProjectStatus.underConstruction, () => setState(() => _status = ProjectStatus.underConstruction))),
            const SizedBox(width: 10),
            Expanded(child: _choiceChip(palette, 'my_projects.status_done_choice'.tr(), Icons.check_circle_outline_rounded, _status == ProjectStatus.completed, () => setState(() => _status = ProjectStatus.completed))),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(palette, 'my_projects.price_from_label'.tr()),
                  TextField(controller: _priceFromController, keyboardType: TextInputType.number, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'my_projects.price_from_hint'.tr())),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(palette, 'my_projects.price_to_label'.tr()),
                  TextField(controller: _priceToController, keyboardType: TextInputType.number, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'my_projects.price_to_hint'.tr())),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _fieldLabel(palette, 'my_projects.payment_plan_label'.tr()),
        TextField(controller: _paymentPlanController, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'my_projects.payment_plan_hint'.tr())),
        const SizedBox(height: 20),
        _fieldLabel(palette, 'my_projects.completion_info_label'.tr()),
        TextField(controller: _completionInfoController, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'my_projects.completion_info_hint'.tr())),
        const SizedBox(height: 20),
        _fieldLabel(palette, 'my_projects.video_url_label'.tr()),
        TextField(controller: _videoUrlController, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'https://...')),
      ],
    );
  }

  Future<void> _pickNeighborhood() async {
    final result = await showModalBottomSheet<KirkukNeighborhood>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sheetPalette = context.palette;
            final filtered = query.trim().isEmpty ? kirkukNeighborhoods : kirkukNeighborhoods.where((n) => n.name.contains(query.trim())).toList();
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: BoxDecoration(color: sheetPalette.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: sheetPalette.divider, borderRadius: BorderRadius.circular(2))),
                    ),
                    Text('my_projects.pick_neighborhood_title'.tr(), style: TextStyle(color: sheetPalette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setSheetState(() => query = v),
                      style: TextStyle(color: sheetPalette.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'my_projects.search_neighborhood_hint'.tr(),
                        hintStyle: TextStyle(color: sheetPalette.textMuted, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: sheetPalette.textMuted, size: 20),
                        filled: true,
                        fillColor: sheetPalette.surfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: sheetPalette.divider),
                        itemBuilder: (_, i) {
                          final n = filtered[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.location_on_outlined, color: sheetPalette.primary, size: 20),
                            title: Text(n.name, style: TextStyle(color: sheetPalette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
                            onTap: () => Navigator.pop(sheetContext, n),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null) setState(() => _neighborhood = result);
  }

  Widget _choiceChip(AppPalette palette, String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? palette.primary : palette.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? palette.primary : palette.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? palette.onPrimary : palette.textSecondary),
            const SizedBox(width: 7),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? palette.onPrimary : palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  Widget _detailsStep(AppPalette palette) {
    final length = _descriptionController.text.trim().length;
    final enough = length >= 30;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        _fieldLabel(palette, 'my_projects.description_label'.tr()),
        TextField(
          controller: _descriptionController,
          minLines: 6,
          maxLines: 10,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: palette.textPrimary, height: 1.6),
          decoration: _inputDecoration(palette, hint: 'my_projects.description_hint'.tr()),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(enough ? 'my_projects.char_count'.tr(args: ['$length']) : 'my_projects.char_count_min'.tr(args: ['$length']), style: TextStyle(color: enough ? AppColors.whatsapp : palette.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 24),
        _dynamicListSection(palette, title: 'my_projects.highlights_title'.tr(), controllers: _highlightControllers, hint: 'my_projects.highlights_hint'.tr()),
        const SizedBox(height: 24),
        _dynamicListSection(palette, title: 'my_projects.amenities_title'.tr(), controllers: _amenityControllers, hint: 'my_projects.amenities_hint'.tr()),
      ],
    );
  }

  Widget _dynamicListSection(AppPalette palette, {required String title, required List<TextEditingController> controllers, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800)),
            TextButton.icon(
              onPressed: () => setState(() => controllers.add(TextEditingController())),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text('my_projects.add_button'.tr()),
            ),
          ],
        ),
        ...List.generate(controllers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: controllers[i], style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: hint)),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    controllers[i].dispose();
                    controllers.removeAt(i);
                  }),
                  icon: Icon(Icons.close_rounded, color: palette.error, size: 18),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _photosStep(AppPalette palette) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      itemCount: _photos.length + (_photos.length < 3 ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemBuilder: (_, i) {
        if (i == _photos.length) {
          return GestureDetector(
            onTap: _pickPhotos,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.divider, width: 1.4), color: palette.surfaceElevated),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: palette.primary, size: 24),
                  const SizedBox(height: 4),
                  Text('my_projects.add_button'.tr(), style: TextStyle(color: palette.primary, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_photos[i], fit: BoxFit.cover)),
            Positioned(
              right: 6,
              top: 6,
              child: GestureDetector(
                onTap: () => setState(() => _photos.removeAt(i)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _unitsStep(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: palette.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: palette.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('my_projects.units_info_hint'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 11.5, height: 1.6))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_unitTypes.length, (i) => _unitTypeCard(palette, _unitTypes[i], i)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openAddUnitSheet(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('my_projects.add_unit_type'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _unitTypeCard(AppPalette palette, UnitType unit, int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))]),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: palette.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_typeIcon(unit.type), color: palette.primary, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.name, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                Text('\$${unit.priceFrom.toStringAsFixed(0)} · ${unit.area}', style: TextStyle(color: palette.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          IconButton(onPressed: () => _removeUnitType(i), icon: Icon(Icons.delete_outline_rounded, color: palette.error, size: 19)),
        ],
      ),
    );
  }

  void _openAddUnitSheet(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final areaController = TextEditingController();
    final descController = TextEditingController();
    var type = ListingType.house;
    var purpose = ListingPurpose.sale;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final palette = context.palette;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                decoration: BoxDecoration(color: palette.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: palette.divider, borderRadius: BorderRadius.circular(2)))),
                      Text('my_projects.add_unit_type'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      _fieldLabel(palette, 'my_projects.unit_name_label'.tr()),
                      TextField(controller: nameController, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'my_projects.unit_name_hint'.tr())),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel(palette, 'my_projects.unit_price_label'.tr()),
                                TextField(controller: priceController, keyboardType: TextInputType.number, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'my_projects.unit_price_hint'.tr())),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel(palette, 'my_projects.unit_area_label'.tr()),
                                TextField(controller: areaController, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'my_projects.unit_area_hint'.tr())),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel(palette, 'my_projects.unit_type_label'.tr()),
                      Wrap(
                        spacing: 8,
                        children: ListingType.values.map((t) {
                          final selected = type == t;
                          return GestureDetector(
                            onTap: () => setSheetState(() => type = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(color: selected ? palette.primary : palette.surfaceElevated, borderRadius: BorderRadius.circular(20)),
                              child: Text(_typeLabel(t), style: TextStyle(color: selected ? palette.onPrimary : palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel(palette, 'my_projects.unit_purpose_label'.tr()),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => purpose = ListingPurpose.sale),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: purpose == ListingPurpose.sale ? palette.primary : palette.surfaceElevated, borderRadius: BorderRadius.circular(12)),
                                child: Text('filters.sale'.tr(), style: TextStyle(color: purpose == ListingPurpose.sale ? palette.onPrimary : palette.textSecondary, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheetState(() => purpose = ListingPurpose.rent),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: purpose == ListingPurpose.rent ? palette.primary : palette.surfaceElevated, borderRadius: BorderRadius.circular(12)),
                                child: Text('filters.rent'.tr(), style: TextStyle(color: purpose == ListingPurpose.rent ? palette.onPrimary : palette.textSecondary, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel(palette, 'my_projects.unit_description_label'.tr()),
                      TextField(controller: descController, maxLines: 3, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'my_projects.unit_description_hint'.tr())),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final price = double.tryParse(priceController.text.trim());
                            if (nameController.text.trim().isEmpty || price == null || areaController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('my_projects.error_fill_all_fields'.tr()), behavior: SnackBarBehavior.floating));
                              return;
                            }
                            _addUnitType(UnitType(
                              name: nameController.text.trim(),
                              priceFrom: price,
                              area: areaController.text.trim(),
                              images: _photos.map((f) => f.path).toList(),
                              description: descController.text.trim(),
                              type: type,
                              purpose: purpose,
                            ));
                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: palette.primary, foregroundColor: palette.onPrimary, padding: const EdgeInsets.symmetric(vertical: 15)),
                          child: Text('my_projects.add_button'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
