import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/boost_sheet.dart';
import '../../../shared/widgets/listing_image.dart';
import 'create_reel_screen.dart';

class MyReelsScreen extends StatefulWidget {
  const MyReelsScreen({super.key});

  @override
  State<MyReelsScreen> createState() => _MyReelsScreenState();
}

class _MyReelsScreenState extends State<MyReelsScreen> {
  List<Reel> get _myReels => MockData.reels.where((r) => r.listing.agency.id == MockData.agencyShiko.id).toList();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reels = _myReels;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('profile.my_reels'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CreateReelScreen()));
          if (created == true && mounted) setState(() {});
        },
        backgroundColor: palette.textPrimary,
        icon: Icon(Icons.videocam_outlined, color: palette.background),
        label: Text('my_reels.new_reel_fab'.tr(), style: TextStyle(color: palette.background, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.ink, Color(0xFF2A2620)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_outline, color: AppColors.gold, size: 16),
                  const SizedBox(width: 8),
                  Text('my_reels.published_count'.tr(args: ['${reels.length}']), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
                    child: Text('my_reels.enterprise_badge'.tr(), style: const TextStyle(color: AppColors.ink, fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),
          Expanded(
            child: reels.isEmpty
                ? Center(child: Text('my_reels.empty'.tr(), style: TextStyle(color: palette.textSecondary)))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: reels.length,
                    itemBuilder: (_, i) => _reelCard(palette, reels[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _reelCard(AppPalette palette, Reel reel, int index) {
    final views = (index + 1) * 214;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                reel.thumbnailUrl.isEmpty
                    ? Container(color: palette.surfaceElevated, child: Icon(Icons.image_outlined, color: palette.textMuted))
                    : isNetworkImage(reel.thumbnailUrl)
                        ? CachedNetworkImage(imageUrl: reel.thumbnailUrl, fit: BoxFit.cover)
                        : Image.file(File(reel.thumbnailUrl), fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0x66000000)], stops: [0.6, 1.0]),
                  ),
                ),
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 34),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                    child: Text('${reel.duration.inSeconds}s', style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 12, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('$views', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reel.listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _actionIcon(palette, Icons.edit_outlined, () => _editReel(reel))),
                    const SizedBox(width: 6),
                    Expanded(child: _actionIcon(palette, Icons.trending_up_rounded, () => showBoostSheet(context, itemName: reel.listing.title))),
                    const SizedBox(width: 6),
                    Expanded(child: _actionIcon(palette, Icons.delete_outline_rounded, () => _confirmDelete(palette, reel), color: palette.error)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (60 * index).ms).fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0);
  }

  Future<void> _editReel(Reel reel) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateReelScreen(existing: reel)));
    if (saved == true && mounted) setState(() {});
  }

  Widget _actionIcon(AppPalette palette, IconData icon, VoidCallback onTap, {Color? color}) {
    final resolved = color ?? palette.textPrimary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(color: resolved.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 15, color: resolved),
        ),
      ),
    );
  }

  void _confirmDelete(AppPalette palette, Reel reel) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('my_reels.confirm_delete_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('my_reels.confirm_delete_message'.tr(), style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () {
              MockData.reels.removeWhere((r) => r.id == reel.id);
              Navigator.pop(context);
              setState(() {});
            },
            child: Text('my_reels.delete_action'.tr(), style: TextStyle(color: palette.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
