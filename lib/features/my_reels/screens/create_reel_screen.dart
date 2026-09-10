import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/listing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/reel_repository.dart';
import '../../../core/network/upload_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';
import 'reel_trim_screen.dart';

/// Hard cap on reel length — keeps every published reel short (and, once
/// compressed, small) regardless of what the visitor originally recorded.
const _maxReelDuration = Duration(seconds: 60);

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key, this.existing});

  /// When set, the screen edits this reel in place instead of publishing a
  /// new one — the existing video/price are pre-filled, and a new video
  /// pick is optional (the current one is kept if the owner doesn't change it).
  final Reel? existing;

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  File? _video;
  VideoPlayerController? _preview;
  final _priceController = TextEditingController();
  bool _isSubmitting = false;
  String? _statusText;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _priceController.text = existing.price > 0 ? existing.price.toStringAsFixed(0) : '';
      final controller = isNetworkImage(existing.videoUrl)
          ? VideoPlayerController.networkUrl(Uri.parse(existing.videoUrl))
          : VideoPlayerController.file(File(existing.videoUrl));
      controller.initialize().then((_) {
        if (!mounted) return;
        controller.setLooping(true);
        controller.setVolume(0);
        controller.play();
        setState(() => _preview = controller);
      });
    }
  }

  @override
  void dispose() {
    _preview?.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _setVideo(File file) async {
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    await controller.setLooping(true);
    await controller.setVolume(0);
    controller.play();
    if (!mounted) return;
    _preview?.dispose();
    setState(() {
      _video = file;
      _preview = controller;
    });
  }

  Future<void> _pickVideo() async {
    try {
      // `maxDuration` caps the in-app camera recorder and is honored by
      // some gallery pickers too, but not all — a video that still comes
      // back longer than the cap goes to the trim screen instead of being
      // rejected outright.
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery, maxDuration: _maxReelDuration);
      if (picked == null) return;
      final file = File(picked.path);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();

      if (duration > _maxReelDuration) {
        if (!mounted) return;
        final trimmedPath = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => ReelTrimScreen(file: file, maxLength: _maxReelDuration)),
        );
        if (trimmedPath == null) return;
        await _setVideo(File(trimmedPath));
        return;
      }

      await _setVideo(file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('my_reels.pick_video_error'.tr()), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _submit() async {
    final existing = widget.existing;
    if (_video == null && existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('my_reels.select_video_error'.tr()), behavior: SnackBarBehavior.floating));
      return;
    }
    final price = double.tryParse(_priceController.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('my_reels.price_required_error'.tr()), behavior: SnackBarBehavior.floating));
      return;
    }

    final uploadRepository = context.read<UploadRepository>();
    final reelRepository = context.read<ReelRepository>();
    final durationSeconds = _preview?.value.duration.inSeconds ?? existing?.duration.inSeconds;

    setState(() {
      _isSubmitting = true;
      _statusText = _video != null ? 'my_reels.compressing_status'.tr() : null;
    });
    try {
      String? uploadPath = _video?.path;
      if (_video != null) {
        // Shrinks storage/bandwidth a lot for what's typically a
        // phone-camera clip going into a short in-app reel — falls back to
        // the original file if compression fails for any reason, so a
        // publish never gets blocked by it.
        try {
          // Caps every reel at 720p regardless of the source resolution —
          // keeps the visual quality high enough for a vertical feed while
          // making the output size predictable (a 4K phone clip compresses
          // far more than MediumQuality's relative scaling would give it).
          final compressed = await VideoCompress.compressVideo(
            _video!.path,
            quality: VideoQuality.Res1280x720Quality,
            deleteOrigin: false,
            includeAudio: true,
            frameRate: 30,
          );
          if (compressed?.path != null) uploadPath = compressed!.path;
        } catch (_) {
          // Keep the original path.
        }
      }
      if (!mounted) return;
      setState(() => _statusText = _video != null ? 'my_reels.uploading_status'.tr() : null);

      final videoUrl = uploadPath != null ? await uploadRepository.upload(uploadPath) : null;

      if (existing != null) {
        await reelRepository.update(
          existing.id,
          videoUrl: videoUrl,
          price: price,
          durationSeconds: durationSeconds,
        );
      } else {
        await reelRepository.create(
          videoUrl: videoUrl!,
          price: price,
          durationSeconds: durationSeconds,
        );
      }

      if (_video != null) unawaited(VideoCompress.deleteAllCache());
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _statusText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text(_isEditing ? 'my_reels.edit_reel_title'.tr() : 'my_reels.new_reel_fab'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          _isSubmitting
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.4, color: palette.primary)),
                      if (_statusText != null) ...[
                        const SizedBox(width: 8),
                        Text(_statusText!, style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                )
              : TextButton(onPressed: _submit, child: Text('my_reels.publish_action'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w800))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          GestureDetector(
            onTap: _pickVideo,
            child: AspectRatio(
              aspectRatio: 9 / 14,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(20),
                  border: _video == null ? Border.all(color: palette.divider, width: 1.4) : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: _preview != null && _preview!.value.isInitialized
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(fit: BoxFit.cover, child: SizedBox(width: _preview!.value.size.width, height: _preview!.value.size.height, child: VideoPlayer(_preview!))),
                          Positioned(
                            left: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                              child: Text('my_reels.change_video_badge'.tr(), style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_call_outlined, color: palette.textMuted, size: 40),
                          const SizedBox(height: 10),
                          Text('my_reels.tap_pick_video_hint'.tr(), style: TextStyle(color: palette.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('my_reels.price_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.surfaceElevated,
              prefixIcon: Icon(Icons.attach_money_rounded, color: palette.primary, size: 20),
              hintText: 'my_reels.price_placeholder'.tr(),
              hintStyle: TextStyle(color: palette.textMuted, fontWeight: FontWeight.w600),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
