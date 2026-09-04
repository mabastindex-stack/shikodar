import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/project.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/project_repository.dart';
import '../../../core/theme/app_palette.dart';

/// The Project equivalent of EditListingScreen — the fields a company can
/// realistically change about a residential complex after publishing it.
class EditProjectScreen extends StatefulWidget {
  const EditProjectScreen({super.key, required this.project});

  final Project project;

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late final _nameController = TextEditingController(text: widget.project.name);
  late final _zoneController = TextEditingController(text: widget.project.zone);
  late final _priceFromController = TextEditingController(text: widget.project.priceFrom.toStringAsFixed(0));
  late final _priceToController = TextEditingController(text: widget.project.priceTo.toStringAsFixed(0));
  late final _descriptionController = TextEditingController(text: widget.project.description);
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _zoneController.dispose();
    _priceFromController.dispose();
    _priceToController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final priceFrom = double.tryParse(_priceFromController.text.trim());
    final priceTo = double.tryParse(_priceToController.text.trim());
    if (name.isEmpty || priceFrom == null || priceTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('my_projects.edit_validation_error'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final projectRepository = context.read<ProjectRepository>();
    setState(() => _isSaving = true);
    try {
      await projectRepository.update(widget.project.id, {
        'name': name,
        'zone': _zoneController.text.trim(),
        'price_from': priceFrom,
        'price_to': priceTo,
        'description': _descriptionController.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('my_projects.edit_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          _isSaving
              ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)))
              : TextButton(onPressed: _save, child: Text('common.save'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w800))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _label(palette, 'my_projects.edit_name_field'.tr()),
          const SizedBox(height: 8),
          TextField(controller: _nameController, style: TextStyle(color: palette.textPrimary)),
          const SizedBox(height: 20),
          _label(palette, 'my_projects.edit_zone_field'.tr()),
          const SizedBox(height: 8),
          TextField(controller: _zoneController, style: TextStyle(color: palette.textPrimary)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(palette, 'my_projects.edit_price_from_field'.tr()),
                    const SizedBox(height: 8),
                    TextField(controller: _priceFromController, keyboardType: TextInputType.number, style: TextStyle(color: palette.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(palette, 'my_projects.edit_price_to_field'.tr()),
                    const SizedBox(height: 8),
                    TextField(controller: _priceToController, keyboardType: TextInputType.number, style: TextStyle(color: palette.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _label(palette, 'my_projects.edit_description_field'.tr()),
          const SizedBox(height: 8),
          TextField(controller: _descriptionController, maxLines: 4, style: TextStyle(color: palette.textPrimary)),
        ],
      ),
    );
  }

  Widget _label(AppPalette palette, String text) => Text(text, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600));
}
