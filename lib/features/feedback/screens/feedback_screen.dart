import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class _FeedbackType {
  final IconData icon;
  final String labelKey;
  const _FeedbackType(this.icon, this.labelKey);

  String get label => labelKey.tr();
}

List<_FeedbackType> get _types => const [
      _FeedbackType(Icons.bug_report_outlined, 'feedback.type_bug'),
      _FeedbackType(Icons.lightbulb_outline_rounded, 'feedback.type_suggestion'),
      _FeedbackType(Icons.report_gmailerrorred_outlined, 'feedback.type_complaint'),
      _FeedbackType(Icons.favorite_border_rounded, 'feedback.type_praise'),
    ];

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selectedType = 1;
  int _rating = 0;
  final _messageController = TextEditingController();
  bool _sent = false;
  File? _screenshot;

  void _submit() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.field_required'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _sent = true);
  }

  Future<void> _pickScreenshot() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) setState(() => _screenshot = File(picked.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('feedback.pick_image_error'.tr()), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('profile.feedback'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: _sent ? _successView(palette) : _formView(palette),
    );
  }

  Widget _formView(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
          child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.ink, size: 32),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
        const SizedBox(height: 14),
        Text(
          'feedback.intro'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
        ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 28),

        Text('feedback.type_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)).animate(delay: 120.ms).fadeIn(duration: 280.ms),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_types.length, (i) => _typeChip(palette, i)),
        ).animate(delay: 160.ms).fadeIn(duration: 300.ms),

        const SizedBox(height: 26),
        Text('feedback.rating_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)).animate(delay: 200.ms).fadeIn(duration: 280.ms),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => _starButton(palette, i + 1)),
        ).animate(delay: 240.ms).fadeIn(duration: 300.ms),

        const SizedBox(height: 26),
        Text('feedback.message_label'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)).animate(delay: 280.ms).fadeIn(duration: 280.ms),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: TextField(
            controller: _messageController,
            maxLines: 5,
            style: TextStyle(color: palette.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'feedback.message_hint'.tr(),
              hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: palette.surface,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ).animate(delay: 320.ms).fadeIn(duration: 320.ms),

        const SizedBox(height: 14),
        if (_screenshot != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_screenshot!, height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _screenshot = null),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _pickScreenshot,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.divider)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_file_rounded, size: 16, color: palette.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _screenshot == null ? 'feedback.add_screenshot'.tr() : 'feedback.change_screenshot'.tr(),
                    style: TextStyle(color: palette.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ).animate(delay: 360.ms).fadeIn(duration: 300.ms),

        const SizedBox(height: 24),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _submit,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Text('feedback.submit_button'.tr(), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ).animate(delay: 400.ms).fadeIn(duration: 320.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _typeChip(AppPalette palette, int i) {
    final selected = _selectedType == i;
    final type = _types[i];
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => setState(() => _selectedType = i),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? palette.textPrimary : palette.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected ? null : [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 16, color: selected ? palette.background : AppColors.goldDark),
              const SizedBox(width: 7),
              Text(type.label, style: TextStyle(color: selected ? palette.background : palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _starButton(AppPalette palette, int star) {
    final active = star <= _rating;
    return GestureDetector(
      onTap: () => setState(() => _rating = star),
      child: AnimatedScale(
        scale: active ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(active ? Icons.star_rounded : Icons.star_border_rounded, size: 34, color: active ? AppColors.amber : palette.textMuted),
        ),
      ),
    );
  }

  Widget _successView(AppPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(color: AppColors.whatsapp.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.whatsapp, size: 44),
            ).animate().scale(duration: 450.ms, curve: Curves.elasticOut).fadeIn(),
            const SizedBox(height: 22),
            Text('feedback.success_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800))
                .animate(delay: 150.ms)
                .fadeIn(duration: 350.ms),
            const SizedBox(height: 8),
            Text(
              'feedback.success_message'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.6),
            ).animate(delay: 220.ms).fadeIn(duration: 350.ms),
            const SizedBox(height: 26),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(color: palette.textPrimary, borderRadius: BorderRadius.circular(14)),
                  child: Text('feedback.ok_button'.tr(), style: TextStyle(color: palette.background, fontWeight: FontWeight.w700)),
                ),
              ),
            ).animate(delay: 280.ms).fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
