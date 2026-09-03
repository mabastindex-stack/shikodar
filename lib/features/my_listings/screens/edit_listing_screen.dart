import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_palette.dart';

/// A focused edit form for the fields an owner can realistically change
/// after publishing — title, price, zone, negotiable — without re-building
/// the full media-upload pipeline (that stays deferred, per the package/
/// offer-gated publishing plan). Saves in place into MockData.listings so
/// every screen that reads it (home feed, search, the owner's own profile
/// grid) reflects the edit immediately.
class EditListingScreen extends StatefulWidget {
  const EditListingScreen({super.key, required this.listing});

  final Listing listing;

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late final _titleController = TextEditingController(text: widget.listing.title);
  late final _priceController = TextEditingController(text: widget.listing.price.toStringAsFixed(0));
  late final _zoneController = TextEditingController(text: widget.listing.zone);
  late bool _negotiable = widget.listing.negotiable;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    if (title.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('my_listings.edit_validation_error'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final updated = widget.listing.copyWith(
      title: title,
      price: price,
      zone: _zoneController.text.trim(),
      negotiable: _negotiable,
    );
    final index = MockData.listings.indexWhere((l) => l.id == widget.listing.id);
    if (index != -1) MockData.listings[index] = updated;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('my_listings.edit_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          TextButton(onPressed: _save, child: Text('common.save'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w800))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _label(palette, 'my_listings.edit_title_field'.tr()),
          const SizedBox(height: 8),
          TextField(controller: _titleController, style: TextStyle(color: palette.textPrimary)),
          const SizedBox(height: 20),
          _label(palette, 'my_listings.edit_price_field'.tr()),
          const SizedBox(height: 8),
          TextField(controller: _priceController, keyboardType: TextInputType.number, style: TextStyle(color: palette.textPrimary)),
          const SizedBox(height: 20),
          _label(palette, 'my_listings.edit_zone_field'.tr()),
          const SizedBox(height: 8),
          TextField(controller: _zoneController, style: TextStyle(color: palette.textPrimary)),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _negotiable,
            onChanged: (v) => setState(() => _negotiable = v),
            activeColor: palette.primary,
            title: Text('my_listings.edit_negotiable_toggle'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _label(AppPalette palette, String text) => Text(text, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600));
}
