import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/listing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/listing_repository.dart';
import '../../../core/theme/app_palette.dart';

/// A focused edit form for the fields an owner can realistically change
/// after publishing — title, price, zone, negotiable — without re-building
/// the full media-upload pipeline (that stays deferred, per the package/
/// offer-gated publishing plan). Saves via the real API so every screen
/// that reads this listing (home feed, search, the owner's own profile
/// grid) reflects the edit on next fetch.
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
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    if (title.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('my_listings.edit_validation_error'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final listingRepository = context.read<ListingRepository>();
    setState(() => _isSaving = true);
    try {
      await listingRepository.update(widget.listing.id, {
        'title': title,
        'price': price,
        'zone': _zoneController.text.trim(),
        'negotiable': _negotiable,
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
        title: Text('my_listings.edit_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          _isSaving
              ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)))
              : TextButton(onPressed: _save, child: Text('common.save'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w800))),
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
