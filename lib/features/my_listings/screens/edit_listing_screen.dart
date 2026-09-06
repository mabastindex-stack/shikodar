import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/models/listing.dart';
import '../../../core/models/zone.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/listing_repository.dart';
import '../../../core/network/upload_repository.dart';
import '../../../core/network/zone_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/zone_picker_sheet.dart';
import '../../home/screens/kirkuk_map_style.dart';

/// Fallback camera center when the listing's zone has no admin-set lat/lng.
const _kirkukCenter = LatLng(35.4681, 44.3922);

/// An edit form for the fields an owner can change after publishing —
/// title, price, negotiable, photos, and zone/location (the last two via
/// the same gallery-picker + map-pin flow used at creation, so editing
/// stays exactly as precise). Saves via the real API so every screen that
/// reads this listing (home feed, search, the owner's own profile grid)
/// reflects the edit on next fetch.
class EditListingScreen extends StatefulWidget {
  const EditListingScreen({super.key, required this.listing});

  final Listing listing;

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> with TickerProviderStateMixin {
  late final _titleController = TextEditingController(text: widget.listing.title);
  late final _priceController = TextEditingController(text: widget.listing.price.toStringAsFixed(0));
  late bool _negotiable = widget.listing.negotiable;
  bool _isSaving = false;

  late final List<String> _existingImageUrls = List.of(widget.listing.imageUrls);
  final List<File> _newPhotos = [];

  Zone? _zone;
  List<Zone> _zones = [];
  late LatLng? _pin = widget.listing.lat != null && widget.listing.lng != null ? LatLng(widget.listing.lat!, widget.listing.lng!) : null;
  late final AnimatedMapController _mapController = AnimatedMapController(vsync: this);

  @override
  void initState() {
    super.initState();
    context.read<ZoneRepository>().fetchAll().then((zones) {
      if (!mounted) return;
      Zone? match;
      for (final z in zones) {
        if (z.name == widget.listing.zone) {
          match = z;
          break;
        }
      }
      setState(() {
        _zones = zones;
        _zone = match ?? Zone(id: '', name: widget.listing.zone);
        _pin ??= (match?.lat != null && match?.lng != null) ? LatLng(match!.lat!, match.lng!) : _kirkukCenter;
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _pickZone() async {
    final result = await pickZoneSheet(
      context,
      _zones,
      title: 'my_listings.pick_neighborhood_title'.tr(),
      searchHint: 'my_listings.search_neighborhood_hint'.tr(),
      notFoundText: 'my_listings.no_neighborhood_found'.tr(),
    );
    if (result == null) return;
    setState(() {
      _zone = result;
      _pin = result.lat != null && result.lng != null ? LatLng(result.lat!, result.lng!) : _kirkukCenter;
    });
    _mapController.mapController.move(_pin!, result.lat != null ? 15.5 : 12.5);
  }

  Future<void> _pickPhotos() async {
    final total = _existingImageUrls.length + _newPhotos.length;
    if (total >= 10) {
      _showError('my_listings.error_photos_max'.tr());
      return;
    }
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1600, limit: 10 - total);
      if (picked.isEmpty) return;
      setState(() => _newPhotos.addAll(picked.map((x) => File(x.path))));
    } catch (_) {
      if (!mounted) return;
      _showError('my_listings.error_photos_pick_failed'.tr());
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    if (title.isEmpty || price == null || _zone == null || (_existingImageUrls.isEmpty && _newPhotos.isEmpty)) {
      _showError('my_listings.edit_validation_error'.tr());
      return;
    }

    final uploadRepository = context.read<UploadRepository>();
    final listingRepository = context.read<ListingRepository>();
    setState(() => _isSaving = true);
    try {
      final newUrls = _newPhotos.isEmpty ? <String>[] : await uploadRepository.uploadAll(_newPhotos.map((f) => f.path).toList());
      await listingRepository.update(widget.listing.id, {
        'title': title,
        'price': price,
        'zone': _zone!.name,
        'negotiable': _negotiable,
        'image_urls': [..._existingImageUrls, ...newUrls],
        if (_pin != null) 'lat': _pin!.latitude,
        if (_pin != null) 'lng': _pin!.longitude,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _negotiable,
            onChanged: (v) => setState(() => _negotiable = v),
            activeColor: palette.primary,
            title: Text('my_listings.edit_negotiable_toggle'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 14)),
          ),
          const SizedBox(height: 20),
          _label(palette, 'my_listings.neighborhood_label'.tr()),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickZone,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: palette.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _zone?.name ?? 'my_listings.select_neighborhood_placeholder'.tr(),
                      style: TextStyle(color: _zone == null ? palette.textMuted : palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: palette.textMuted),
                ],
              ),
            ),
          ),
          if (_zone != null && _pin != null) ...[
            const SizedBox(height: 10),
            Text('my_listings.map_pin_hint'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  mapController: _mapController.mapController,
                  options: MapOptions(
                    initialCenter: _pin!,
                    initialZoom: 15.5,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    onTap: (tapPosition, point) => setState(() => _pin = point),
                  ),
                  children: [
                    ColorFiltered(
                      colorFilter: kirkukTileFilter,
                      child: TileLayer(
                        urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.shikodar.app',
                        maxNativeZoom: 16,
                      ),
                    ),
                    TileLayer(
                      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.shikodar.app',
                      maxNativeZoom: 16,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pin!,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_on_rounded, color: palette.primary, size: 40, shadows: const [Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _label(palette, 'my_listings.step_photos_title'.tr()),
          const SizedBox(height: 10),
          _photoGrid(palette),
        ],
      ),
    );
  }

  Widget _photoGrid(AppPalette palette) {
    final total = _existingImageUrls.length + _newPhotos.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: total + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemBuilder: (_, i) {
        if (i == total) {
          return GestureDetector(
            onTap: _pickPhotos,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.divider, width: 1.4),
                color: palette.surfaceElevated,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: palette.primary, size: 24),
                  const SizedBox(height: 4),
                  Text('my_listings.add_photo'.tr(), style: TextStyle(color: palette.primary, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }
        final isExisting = i < _existingImageUrls.length;
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: isExisting
                  ? CachedNetworkImage(imageUrl: _existingImageUrls[i], fit: BoxFit.cover)
                  : Image.file(_newPhotos[i - _existingImageUrls.length], fit: BoxFit.cover),
            ),
            if (i == 0)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)),
                  child: Text('my_listings.primary_photo_badge'.tr(), style: const TextStyle(color: AppColors.ink, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ),
            Positioned(
              right: 6,
              top: 6,
              child: GestureDetector(
                onTap: () => setState(() {
                  if (isExisting) {
                    _existingImageUrls.removeAt(i);
                  } else {
                    _newPhotos.removeAt(i - _existingImageUrls.length);
                  }
                }),
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

  Widget _label(AppPalette palette, String text) => Text(text, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600));
}
