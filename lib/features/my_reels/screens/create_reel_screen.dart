import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/listing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/listing_repository.dart';
import '../../../core/network/reel_repository.dart';
import '../../../core/network/upload_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/listing_image.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key, this.existing});

  /// When set, the screen edits this reel in place instead of publishing a
  /// new one — the existing video/listing are pre-filled, and a new video
  /// pick is optional (the current one is kept if the owner doesn't change it).
  final Reel? existing;

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  File? _video;
  VideoPlayerController? _preview;
  Listing? _listing;
  List<Listing> _myListings = [];
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    context.read<ListingRepository>().fetchMine().then((listings) {
      if (mounted) setState(() => _myListings = listings);
    });
    final existing = widget.existing;
    if (existing != null) {
      _listing = existing.listing;
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
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked == null) return;
      final file = File(picked.path);
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('my_reels.pick_video_error'.tr()), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _pickListing() async {
    final result = await showModalBottomSheet<Listing>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final palette = sheetContext.palette;
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(color: palette.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: palette.divider, borderRadius: BorderRadius.circular(2)))),
              Text('my_reels.pick_listing_sheet_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Expanded(
                child: _myListings.isEmpty
                    ? Center(child: Text('my_reels.no_listings'.tr(), style: TextStyle(color: palette.textSecondary)))
                    : ListView.separated(
                        itemCount: _myListings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final l = _myListings[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 52,
                                height: 52,
                                child: l.imageUrls.isEmpty
                                    ? Container(color: palette.surfaceElevated)
                                    : isNetworkImage(l.imageUrls.first)
                                        ? CachedNetworkImage(imageUrl: l.imageUrls.first, fit: BoxFit.cover)
                                        : Image.file(File(l.imageUrls.first), fit: BoxFit.cover),
                              ),
                            ),
                            title: Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                            subtitle: Text(l.zone, style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
                            onTap: () => Navigator.pop(sheetContext, l),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) setState(() => _listing = result);
  }

  Future<void> _submit() async {
    final existing = widget.existing;
    if (_video == null && existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('my_reels.select_video_error'.tr()), behavior: SnackBarBehavior.floating));
      return;
    }
    if (_listing == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('my_reels.select_listing_error'.tr()), behavior: SnackBarBehavior.floating));
      return;
    }

    final uploadRepository = context.read<UploadRepository>();
    final reelRepository = context.read<ReelRepository>();
    final thumbnailUrl = _listing!.imageUrls.isNotEmpty ? _listing!.imageUrls.first : null;
    final durationSeconds = _preview?.value.duration.inSeconds ?? existing?.duration.inSeconds;

    setState(() => _isSubmitting = true);
    try {
      final videoUrl = _video != null ? await uploadRepository.upload(_video!.path) : null;

      if (existing != null) {
        await reelRepository.update(
          existing.id,
          listingId: _listing!.id,
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
          durationSeconds: durationSeconds,
        );
      } else {
        await reelRepository.create(
          listingId: _listing!.id,
          videoUrl: videoUrl!,
          thumbnailUrl: thumbnailUrl,
          durationSeconds: durationSeconds,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
              ? Padding(padding: const EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: palette.primary)))
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
          Text('my_reels.related_listing_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickListing,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.home_work_outlined, color: palette.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _listing?.title ?? 'my_reels.select_listing_placeholder'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _listing == null ? palette.textMuted : palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: palette.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
