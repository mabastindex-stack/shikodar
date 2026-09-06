import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/models/project.dart';
import '../../../core/models/zone.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/project_repository.dart';
import '../../../core/network/upload_repository.dart';
import '../../../core/network/zone_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/zone_picker_sheet.dart';
import '../../home/screens/kirkuk_map_style.dart';

/// Fallback camera center when the project's zone has no admin-set lat/lng.
const _kirkukCenter = LatLng(35.4681, 44.3922);

/// The Project equivalent of EditListingScreen — the fields a company can
/// change about a residential complex after publishing it, including its
/// 3 identity photos, video, and zone/location (the same gallery-picker +
/// map-pin flow used at creation).
class EditProjectScreen extends StatefulWidget {
  const EditProjectScreen({super.key, required this.project});

  final Project project;

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> with TickerProviderStateMixin {
  late final _nameController = TextEditingController(text: widget.project.name);
  late final _priceFromController = TextEditingController(text: widget.project.priceFrom.toStringAsFixed(0));
  late final _priceToController = TextEditingController(text: widget.project.priceTo.toStringAsFixed(0));
  late final _descriptionController = TextEditingController(text: widget.project.description);
  bool _isSaving = false;

  late final List<String> _existingImageUrls = List.of(widget.project.images);
  final List<File> _newPhotos = [];

  late String? _existingVideoUrl = widget.project.videoUrl.isEmpty ? null : widget.project.videoUrl;
  File? _newVideoFile;

  Zone? _zone;
  List<Zone> _zones = [];
  late LatLng? _pin = widget.project.lat != null && widget.project.lng != null ? LatLng(widget.project.lat!, widget.project.lng!) : null;
  late final AnimatedMapController _mapController = AnimatedMapController(vsync: this);

  @override
  void initState() {
    super.initState();
    context.read<ZoneRepository>().fetchAll().then((zones) {
      if (!mounted) return;
      Zone? match;
      for (final z in zones) {
        if (z.name == widget.project.zone) {
          match = z;
          break;
        }
      }
      setState(() {
        _zones = zones;
        _zone = match ?? Zone(id: '', name: widget.project.zone);
        _pin ??= (match?.lat != null && match?.lng != null) ? LatLng(match!.lat!, match.lng!) : _kirkukCenter;
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceFromController.dispose();
    _priceToController.dispose();
    _descriptionController.dispose();
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
      title: 'my_projects.pick_neighborhood_title'.tr(),
      searchHint: 'my_projects.search_neighborhood_hint'.tr(),
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
    if (total >= 3) return;
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1600, limit: 3 - total);
      if (picked.isEmpty) return;
      setState(() => _newPhotos.addAll(picked.map((x) => File(x.path))));
    } catch (_) {
      if (!mounted) return;
      _showError('my_projects.error_photos_pick_failed'.tr());
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked == null) return;
      setState(() => _newVideoFile = File(picked.path));
    } catch (_) {
      if (!mounted) return;
      _showError('my_projects.error_photos_pick_failed'.tr());
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final priceFrom = double.tryParse(_priceFromController.text.trim());
    final priceTo = double.tryParse(_priceToController.text.trim());
    final totalPhotos = _existingImageUrls.length + _newPhotos.length;
    if (name.isEmpty || priceFrom == null || priceTo == null || _zone == null || totalPhotos == 0) {
      _showError('my_projects.edit_validation_error'.tr());
      return;
    }

    final uploadRepository = context.read<UploadRepository>();
    final projectRepository = context.read<ProjectRepository>();
    setState(() => _isSaving = true);
    try {
      final newImageUrls = _newPhotos.isEmpty ? <String>[] : await uploadRepository.uploadAll(_newPhotos.map((f) => f.path).toList());
      final newVideoUrl = _newVideoFile != null ? await uploadRepository.upload(_newVideoFile!.path) : null;

      await projectRepository.update(widget.project.id, {
        'name': name,
        'zone': _zone!.name,
        if (_pin != null) 'lat': _pin!.latitude,
        if (_pin != null) 'lng': _pin!.longitude,
        'images': [..._existingImageUrls, ...newImageUrls],
        'video_url': newVideoUrl ?? _existingVideoUrl,
        'price_from': priceFrom,
        'price_to': priceTo,
        'description': _descriptionController.text.trim(),
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
                      _zone?.name ?? 'my_projects.select_neighborhood_placeholder'.tr(),
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
          const SizedBox(height: 24),
          _label(palette, 'my_projects.step_photos_title'.tr()),
          const SizedBox(height: 10),
          _photoGrid(palette),
          const SizedBox(height: 24),
          _label(palette, 'my_projects.video_url_label'.tr()),
          const SizedBox(height: 10),
          _videoCard(palette),
        ],
      ),
    );
  }

  Widget _photoGrid(AppPalette palette) {
    final total = _existingImageUrls.length + _newPhotos.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: total + (total < 3 ? 1 : 0),
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

  Widget _videoCard(AppPalette palette) {
    if (_newVideoFile != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: palette.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.play_circle_fill_rounded, color: palette.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _newVideoFile!.path.split(Platform.pathSeparator).last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _newVideoFile = null),
              icon: Icon(Icons.close_rounded, color: palette.textMuted, size: 18),
            ),
          ],
        ),
      );
    }
    if (_existingVideoUrl != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.play_circle_fill_rounded, color: AppColors.goldDark, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('my_projects.video_current_label'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
            TextButton(onPressed: _pickVideo, child: Text('my_projects.video_replace_button'.tr(), style: TextStyle(color: palette.primary, fontSize: 12, fontWeight: FontWeight.w700))),
            IconButton(
              onPressed: () => setState(() => _existingVideoUrl = null),
              icon: Icon(Icons.close_rounded, color: palette.textMuted, size: 18),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: _pickVideo,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.divider, width: 1.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_call_outlined, color: palette.primary, size: 26),
            const SizedBox(height: 6),
            Text('my_projects.video_pick_button'.tr(), style: TextStyle(color: palette.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _label(AppPalette palette, String text) => Text(text, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600));
}
