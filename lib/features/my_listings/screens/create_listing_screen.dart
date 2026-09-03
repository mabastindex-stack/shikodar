import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/mock/kirkuk_neighborhoods.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../home/screens/kirkuk_map_style.dart';

List<String> get _stepTitles => [
      'my_listings.step_basics_title'.tr(),
      'my_listings.step_details_title'.tr(),
      'my_listings.step_photos_title'.tr(),
      'my_listings.step_location_title'.tr(),
      'my_listings.step_contact_title'.tr(),
    ];
List<String> get _stepSubtitles => [
      'my_listings.step_basics_subtitle'.tr(),
      'my_listings.step_details_subtitle'.tr(),
      'my_listings.step_photos_subtitle'.tr(),
      'my_listings.step_location_subtitle'.tr(),
      'my_listings.step_contact_subtitle'.tr(),
    ];
const _phonePattern = r'^07[0-9]{9}$';

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
      return 'filters.house'.tr();
    case ListingType.land:
      return 'filters.land'.tr();
    case ListingType.shop:
      return 'filters.shop'.tr();
  }
}

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> with TickerProviderStateMixin {
  static const _stepCount = 5;
  final _pageController = PageController();
  int _step = 0;

  final _titleController = TextEditingController();
  ListingPurpose? _purpose;
  ListingType? _type;
  final _priceController = TextEditingController();
  bool _negotiable = false;
  final _areaController = TextEditingController();
  final _roomsController = TextEditingController();

  final _descriptionController = TextEditingController();

  final List<File> _photos = [];

  KirkukNeighborhood? _neighborhood;
  LatLng? _pin;
  late final AnimatedMapController _mapController = AnimatedMapController(vsync: this);

  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  bool _sameAsPhone = true;

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _roomsController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String? _errorForStep(int step) {
    switch (step) {
      case 0:
        if (_titleController.text.trim().length < 4) return 'my_listings.error_title_length'.tr();
        if (_purpose == null) return 'my_listings.error_purpose_required'.tr();
        if (_type == null) return 'my_listings.error_type_required'.tr();
        final price = double.tryParse(_priceController.text.trim());
        if (price == null || price <= 0) return 'my_listings.error_price_invalid'.tr();
        final area = double.tryParse(_areaController.text.trim());
        if (area == null || area <= 0) return 'my_listings.error_area_invalid'.tr();
        if (_type == ListingType.house || _type == ListingType.villa) {
          final rooms = int.tryParse(_roomsController.text.trim());
          if (rooms == null || rooms <= 0) return 'my_listings.error_rooms_required'.tr();
        }
        return null;
      case 1:
        if (_descriptionController.text.trim().length < 30) return 'my_listings.error_description_length'.tr();
        return null;
      case 2:
        if (_photos.length < 3) return 'my_listings.error_photos_min'.tr();
        return null;
      case 3:
        if (_neighborhood == null) return 'my_listings.error_neighborhood_required'.tr();
        return null;
      case 4:
        if (!RegExp(_phonePattern).hasMatch(_phoneController.text.trim())) return 'my_listings.error_phone_invalid'.tr();
        if (!_sameAsPhone && !RegExp(_phonePattern).hasMatch(_whatsappController.text.trim())) return 'my_listings.error_whatsapp_invalid'.tr();
        return null;
      default:
        return null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

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
        title: Text('my_listings.discard_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('my_listings.discard_message'.tr(), style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('onboarding.next'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('my_listings.discard_confirm'.tr(), style: TextStyle(color: palette.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= 10) {
      _showError('my_listings.error_photos_max'.tr());
      return;
    }
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1600, limit: 10 - _photos.length);
      if (picked.isEmpty) return;
      setState(() => _photos.addAll(picked.map((x) => File(x.path))));
    } catch (_) {
      if (!mounted) return;
      _showError('my_listings.error_photos_pick_failed'.tr());
    }
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
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: sheetPalette.divider, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Text('my_listings.pick_neighborhood_title'.tr(), style: TextStyle(color: sheetPalette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: false,
                      onChanged: (v) => setSheetState(() => query = v),
                      style: TextStyle(color: sheetPalette.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'my_listings.search_neighborhood_hint'.tr(),
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
                      child: filtered.isEmpty
                          ? Center(child: Text('my_listings.no_neighborhood_found'.tr(), style: TextStyle(color: sheetPalette.textSecondary)))
                          : ListView.separated(
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
    if (result == null) return;
    setState(() {
      _neighborhood = result;
      _pin = LatLng(result.lat, result.lng);
    });
    _mapController.mapController.move(_pin!, 15.5);
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    final whatsapp = _sameAsPhone ? phone : _whatsappController.text.trim();
    final listing = Listing(
      id: 'l_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      zone: _neighborhood!.name,
      purpose: _purpose!,
      type: _type!,
      price: double.parse(_priceController.text.trim()),
      negotiable: _negotiable,
      imageUrls: _photos.map((f) => f.path).toList(),
      areaSqm: double.parse(_areaController.text.trim()),
      rooms: (_type == ListingType.house || _type == ListingType.villa) ? int.tryParse(_roomsController.text.trim()) : null,
      lat: _pin!.latitude,
      lng: _pin!.longitude,
      agency: MockData.agencyShiko,
      createdAt: DateTime.now(),
      description: _descriptionController.text.trim(),
      phone: phone,
      whatsapp: whatsapp,
    );
    MockData.listings.insert(0, listing);
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
                  _locationStep(palette),
                  _contactStep(palette),
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
                    decoration: BoxDecoration(
                      color: active ? palette.primary : palette.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
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
          label: Text(isLast ? 'my_listings.publish_button'.tr() : 'my_listings.next_button'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
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
        _fieldLabel(palette, 'my_listings.title_label'.tr()),
        TextField(controller: _titleController, style: TextStyle(color: palette.textPrimary), decoration: _inputDecoration(palette, hint: 'my_listings.title_hint'.tr())),
        const SizedBox(height: 20),
        _fieldLabel(palette, 'my_listings.purpose_label'.tr()),
        Row(
          children: [
            Expanded(child: _choiceChip(palette, 'filters.rent'.tr(), Icons.vpn_key_rounded, _purpose == ListingPurpose.rent, () => setState(() => _purpose = ListingPurpose.rent))),
            const SizedBox(width: 10),
            Expanded(child: _choiceChip(palette, 'filters.sale'.tr(), Icons.sell_rounded, _purpose == ListingPurpose.sale, () => setState(() => _purpose = ListingPurpose.sale))),
          ],
        ),
        const SizedBox(height: 20),
        _fieldLabel(palette, 'my_listings.type_label'.tr()),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ListingType.values.map((t) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 40 - 10) / 2,
              child: _choiceChip(palette, _typeLabel(t), _typeIcon(t), _type == t, () => setState(() => _type = t)),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(palette, 'my_listings.price_label'.tr()),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: palette.textPrimary),
                    decoration: _inputDecoration(palette, hint: 'my_listings.price_hint'.tr()),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(palette, 'my_listings.area_label'.tr()),
                  TextField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: palette.textPrimary),
                    decoration: _inputDecoration(palette, hint: 'my_listings.area_hint'.tr()),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_type == ListingType.house || _type == ListingType.villa) ...[
          const SizedBox(height: 20),
          _fieldLabel(palette, 'my_listings.rooms_label'.tr()),
          TextField(
            controller: _roomsController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: palette.textPrimary),
            decoration: _inputDecoration(palette, hint: 'my_listings.rooms_hint'.tr()),
          ),
        ],
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _negotiable,
          onChanged: (v) => setState(() => _negotiable = v),
          activeColor: palette.primary,
          title: Text('my_listings.negotiable_toggle'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
        ),
      ],
    );
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
            Icon(icon, size: 17, color: selected ? palette.onPrimary : palette.textSecondary),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(color: selected ? palette.onPrimary : palette.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
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
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: palette.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: palette.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'my_listings.details_tip'.tr(),
                  style: TextStyle(color: palette.textPrimary, fontSize: 12, height: 1.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _fieldLabel(palette, 'my_listings.description_label'.tr()),
        TextField(
          controller: _descriptionController,
          minLines: 8,
          maxLines: 14,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: palette.textPrimary, height: 1.6),
          decoration: _inputDecoration(palette, hint: 'my_listings.description_hint'.tr()),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            enough ? 'my_listings.char_count'.tr(args: ['$length']) : 'my_listings.char_count_min'.tr(args: ['$length']),
            style: TextStyle(color: enough ? AppColors.whatsapp : palette.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _photosStep(AppPalette palette) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      itemCount: _photos.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemBuilder: (_, i) {
        if (i == _photos.length) {
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
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_photos[i], fit: BoxFit.cover),
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

  Widget _locationStep(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        _fieldLabel(palette, 'my_listings.neighborhood_label'.tr()),
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
                    _neighborhood?.name ?? 'my_listings.select_neighborhood_placeholder'.tr(),
                    style: TextStyle(color: _neighborhood == null ? palette.textMuted : palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: palette.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (_neighborhood == null)
          Container(
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(18)),
            child: Text('my_listings.map_placeholder_hint'.tr(), style: TextStyle(color: palette.textMuted, fontSize: 12.5), textAlign: TextAlign.center),
          )
        else ...[
          Text('my_listings.map_pin_hint'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 240,
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
      ],
    );
  }

  Widget _contactStep(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        _fieldLabel(palette, 'my_listings.phone_label'.tr()),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: palette.textPrimary),
          decoration: _inputDecoration(palette, hint: 'my_listings.phone_hint'.tr()),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _sameAsPhone,
          onChanged: (v) => setState(() => _sameAsPhone = v),
          activeColor: palette.primary,
          title: Text('my_listings.same_as_phone_toggle'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
        ),
        if (!_sameAsPhone) ...[
          const SizedBox(height: 12),
          _fieldLabel(palette, 'my_listings.whatsapp_label'.tr()),
          TextField(
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: palette.textPrimary),
            decoration: _inputDecoration(palette, hint: 'my_listings.phone_hint'.tr()),
          ),
        ],
        const SizedBox(height: 28),
        Text('my_listings.summary_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow(palette, Icons.title_rounded, _titleController.text.trim().isEmpty ? '—' : _titleController.text.trim()),
              _summaryRow(palette, Icons.category_outlined, _type == null ? '—' : '${_typeLabel(_type!)} · ${_purpose == ListingPurpose.rent ? 'filters.rent'.tr() : 'filters.sale'.tr()}'),
              _summaryRow(palette, Icons.sell_outlined, _priceController.text.trim().isEmpty ? '—' : '\$${_priceController.text.trim()}'),
              _summaryRow(palette, Icons.location_on_outlined, _neighborhood?.name ?? '—'),
              _summaryRow(palette, Icons.photo_library_outlined, 'my_listings.summary_photos_count'.tr(args: ['${_photos.length}']), isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(AppPalette palette, IconData icon, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: palette.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
