import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/session/admin_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../offers/screens/offers_list_screen.dart';

const _offerIconChoices = [
  Icons.card_giftcard_rounded,
  Icons.vpn_key_rounded,
  Icons.video_camera_back_rounded,
  Icons.local_offer_rounded,
  Icons.celebration_rounded,
  Icons.workspace_premium_rounded,
  Icons.star_rounded,
  Icons.bolt_rounded,
];

/// Manages the REAL, user-facing `Offer` list shown in `OffersListScreen` —
/// deliberately separate from `PackagesScreen`'s pricing tiers (package ≠
/// offer, per the product rule).
class AdminOffersScreen extends StatelessWidget {
  const AdminOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final offers = context.watch<AdminStore>().offers;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        automaticallyImplyLeading: false,
        title: Text('offers.title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _OfferFormScreen())),
        backgroundColor: palette.textPrimary,
        icon: Icon(Icons.add_rounded, color: palette.background),
        label: Text('admin.offers_new_title'.tr(), style: TextStyle(color: palette.background, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.ink, Color(0xFF2A2620)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: AppColors.gold, size: 16),
                  const SizedBox(width: 8),
                  Text('admin.offers_active_count'.tr(args: ['${offers.length}']), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),
          Expanded(
            child: offers.isEmpty
                ? Center(child: Text('admin.offers_empty'.tr(), style: TextStyle(color: palette.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: offers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _offerRow(context, palette, offers[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _offerRow(BuildContext context, AppPalette palette, Offer o, int i) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _OfferFormScreen(existing: o))),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CachedNetworkImage(
                    imageUrl: o.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: palette.surfaceElevated),
                    errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated, child: Icon(o.icon, color: palette.textMuted)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(o.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w700))),
                        if (o.isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(20)),
                            child: Text('offers.new_badge'.tr(), style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(o.audience, style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(o.validUntil, style: TextStyle(color: palette.textMuted, fontSize: 10)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _confirmDelete(context, palette, o),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: palette.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.delete_outline_rounded, size: 17, color: palette.error),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (60 * i).ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
  }

  void _confirmDelete(BuildContext context, AppPalette palette, Offer o) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('admin.offers_delete_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('admin.offers_delete_message'.tr(args: [o.title]), style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () {
              context.read<AdminStore>().removeOffer(o.id);
              Navigator.pop(dialogContext);
            },
            child: Text('my_listings.delete_action'.tr(), style: TextStyle(color: palette.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _OfferFormScreen extends StatefulWidget {
  const _OfferFormScreen({this.existing});
  final Offer? existing;

  @override
  State<_OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<_OfferFormScreen> {
  late final _titleController = TextEditingController(text: widget.existing?.title ?? '');
  late final _previewController = TextEditingController(text: widget.existing?.preview ?? '');
  late final _introController = TextEditingController(text: widget.existing?.intro ?? '');
  late final _audienceController = TextEditingController(text: widget.existing?.audience ?? '');
  late final _validUntilController = TextEditingController(text: widget.existing?.validUntil ?? '');
  late final _imageUrlController = TextEditingController(text: widget.existing?.imageUrl ?? '');
  late final List<TextEditingController> _highlightControllers = (widget.existing?.highlights ?? const ['']).map((h) => TextEditingController(text: h)).toList();
  late IconData _icon = widget.existing?.icon ?? _offerIconChoices.first;
  late bool _isNew = widget.existing?.isNew ?? false;

  @override
  void dispose() {
    _titleController.dispose();
    _previewController.dispose();
    _introController.dispose();
    _audienceController.dispose();
    _validUntilController.dispose();
    _imageUrlController.dispose();
    for (final c in _highlightControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addHighlight() => setState(() => _highlightControllers.add(TextEditingController()));

  void _removeHighlight(int i) => setState(() {
        _highlightControllers[i].dispose();
        _highlightControllers.removeAt(i);
      });

  void _save() {
    if (_titleController.text.trim().isEmpty || _imageUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.offers_validation_error'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final highlights = _highlightControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    final store = context.read<AdminStore>();
    if (widget.existing != null) {
      store.updateOffer(widget.existing!.copyWith(
        icon: _icon,
        title: _titleController.text.trim(),
        preview: _previewController.text.trim(),
        intro: _introController.text.trim(),
        highlights: highlights,
        audience: _audienceController.text.trim(),
        validUntil: _validUntilController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        isNew: _isNew,
      ));
    } else {
      store.addOffer(Offer(
        id: store.nextOfferId(),
        icon: _icon,
        title: _titleController.text.trim(),
        preview: _previewController.text.trim(),
        intro: _introController.text.trim(),
        highlights: highlights,
        audience: _audienceController.text.trim(),
        validUntil: _validUntilController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        isNew: _isNew,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text(widget.existing != null ? 'admin.offers_edit_title'.tr() : 'admin.offers_new_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          TextButton(onPressed: _save, child: Text('common.save'.tr(), style: TextStyle(color: palette.primary, fontWeight: FontWeight.w800))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _label(palette, 'admin.offers_field_icon_label'.tr()),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _offerIconChoices.map((icon) {
              final selected = _icon == icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = icon),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.goldGradient : null,
                    color: selected ? null : palette.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: selected ? AppColors.ink : palette.textSecondary, size: 20),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _label(palette, 'admin.offers_field_title_label'.tr()),
          _field(palette, _titleController, 'admin.offers_field_title_hint'.tr()),
          const SizedBox(height: 16),
          _label(palette, 'admin.offers_field_preview_label'.tr()),
          _field(palette, _previewController, 'admin.offers_field_preview_hint'.tr(), maxLines: 2),
          const SizedBox(height: 16),
          _label(palette, 'admin.offers_field_image_url_label'.tr()),
          _field(palette, _imageUrlController, 'admin.url_hint'.tr()),
          const SizedBox(height: 16),
          _label(palette, 'admin.offers_field_intro_label'.tr()),
          _field(palette, _introController, 'admin.offers_field_intro_hint'.tr(), maxLines: 3),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label(palette, 'admin.offers_field_highlights_label'.tr()),
              TextButton.icon(onPressed: _addHighlight, icon: const Icon(Icons.add_rounded, size: 16), label: Text('my_listings.add_photo'.tr())),
            ],
          ),
          ...List.generate(_highlightControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: _field(palette, _highlightControllers[i], 'admin.offers_field_highlight_item_hint'.tr())),
                  IconButton(onPressed: () => _removeHighlight(i), icon: Icon(Icons.close_rounded, color: palette.error, size: 18)),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(palette, 'admin.offers_field_audience_label'.tr()),
                    _field(palette, _audienceController, 'admin.offers_field_audience_hint'.tr()),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(palette, 'admin.offers_field_valid_until_label'.tr()),
                    _field(palette, _validUntilController, 'admin.offers_field_valid_until_hint'.tr()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isNew,
            onChanged: (v) => setState(() => _isNew = v),
            activeColor: palette.primary,
            title: Text('admin.offers_field_is_new_toggle_label'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _label(AppPalette palette, String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)));

  Widget _field(AppPalette palette, TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: TextStyle(color: palette.textPrimary),
      decoration: InputDecoration(hintText: hint),
    );
  }
}
