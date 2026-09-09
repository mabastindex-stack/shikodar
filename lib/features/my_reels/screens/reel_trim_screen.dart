import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

/// Shown only when a picked video is longer than the reel cap — lets the
/// publisher pick which 60-second window of it to actually use, instead of
/// just rejecting the video outright. Pops with the trimmed file's local
/// path, or null if the visitor backs out.
class ReelTrimScreen extends StatefulWidget {
  final File file;
  final Duration maxLength;
  const ReelTrimScreen({super.key, required this.file, required this.maxLength});

  @override
  State<ReelTrimScreen> createState() => _ReelTrimScreenState();
}

class _ReelTrimScreenState extends State<ReelTrimScreen> {
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0;
  double _endValue = 0;
  bool _isPlaying = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _trimmer.loadVideo(videoFile: widget.file);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (outputPath) {
        if (mounted) Navigator.pop(context, outputPath);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        title: Text('my_reels.trim_title'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          _isSaving
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)))
              : TextButton(onPressed: _save, child: Text('my_reels.trim_done_action'.tr(), style: const TextStyle(color: AppColors.emeraldLight, fontWeight: FontWeight.w800))),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'my_reels.trim_hint'.tr(args: [widget.maxLength.inSeconds.toString()]),
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textMuted, fontSize: 12.5),
              ),
            ),
            Expanded(child: Center(child: VideoViewer(trimmer: _trimmer))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TrimViewer(
                trimmer: _trimmer,
                viewerHeight: 50,
                viewerWidth: MediaQuery.of(context).size.width - 32,
                durationStyle: DurationStyle.FORMAT_MM_SS,
                maxVideoLength: widget.maxLength,
                editorProperties: const TrimEditorProperties(
                  borderPaintColor: AppColors.gold,
                  borderWidth: 3,
                  borderRadius: 5,
                  circlePaintColor: AppColors.goldLight,
                ),
                areaProperties: TrimAreaProperties.edgeBlur(thumbnailQuality: 60),
                onChangeStart: (value) => _startValue = value,
                onChangeEnd: (value) => _endValue = value,
                onChangePlaybackState: (value) => setState(() => _isPlaying = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IconButton(
                iconSize: 52,
                color: Colors.white,
                icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                onPressed: () async {
                  final playing = await _trimmer.videoPlaybackControl(startValue: _startValue, endValue: _endValue);
                  if (mounted) setState(() => _isPlaying = playing);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
