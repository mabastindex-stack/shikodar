import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/session/admin_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import 'offer_detail_screen.dart';

class Offer {
  final String id;
  final IconData icon;
  final String title;
  final String preview;
  final String intro;
  final List<String> highlights;
  final String audience;
  final String validUntil;
  final String imageUrl;
  final bool isNew;
  const Offer({
    required this.id,
    required this.icon,
    required this.title,
    required this.preview,
    required this.intro,
    required this.highlights,
    required this.audience,
    required this.validUntil,
    required this.imageUrl,
    this.isNew = false,
  });

  Offer copyWith({
    IconData? icon,
    String? title,
    String? preview,
    String? intro,
    List<String>? highlights,
    String? audience,
    String? validUntil,
    String? imageUrl,
    bool? isNew,
  }) =>
      Offer(
        id: id,
        icon: icon ?? this.icon,
        title: title ?? this.title,
        preview: preview ?? this.preview,
        intro: intro ?? this.intro,
        highlights: highlights ?? this.highlights,
        audience: audience ?? this.audience,
        validUntil: validUntil ?? this.validUntil,
        imageUrl: imageUrl ?? this.imageUrl,
        isNew: isNew ?? this.isNew,
      );
}

/// One accent per offer, cycling through the app's own emerald/jade family —
/// enough to tell cards apart at a glance without introducing a second hue.
const _offerAccents = [AppColors.emeraldDark, AppColors.gold, AppColors.emerald];

/// Seed data for [AdminStore.offers] — admin can add/edit/delete from here on;
/// this list is only ever read once, at store construction.
const defaultOffers = [
  Offer(
    id: 'o1',
    icon: Icons.card_giftcard_rounded,
    title: 'داشکاندنی ٢٠٪ بۆ پاکێجی Premium',
    preview: 'کاتی زێڕینی گۆڕینی پاکێج — داشکاندنی تایبەت بۆ ماوەیەکی سنووردار.',
    intro: 'پاداشتێک بۆ دەلال و عقاراتە چالاکەکانی شکۆدار.',
    highlights: [
      'داشکاندنی ٢٠٪ بۆ گۆڕان بۆ Premium یان Enterprise',
      'چالاکە بۆ یەک مانگی یەکەم بەبێ گۆڕانکاری تایبەتمەندی',
      'پەیوەندی بکە پێش کۆتایی مانگ بۆ وەرگرتنی',
    ],
    audience: 'هەموو عقاراتەکان',
    validUntil: '٣٠ ی ئەم مانگە',
    imageUrl: 'https://images.unsplash.com/photo-1607344645866-009c320b63e0?w=900&q=80',
    isNew: true,
  ),
  Offer(
    id: 'o2',
    icon: Icons.vpn_key_rounded,
    title: 'بەخێرهاتنی ئەندامانی نوێ',
    preview: 'مانگێک بەخۆڕایی بۆ هەر عقاراتێکی نوێ کە تۆمار دەبێت.',
    intro: 'پاڵپشتیکردنی دەلالانی نوێی بازاڕی کەرکوک.',
    highlights: [
      'مانگێکی تەواوی بەخۆڕایی بە هەموو تایبەتمەندی Business',
      'تایبەتە بۆ عقاراتی نوێی تۆمارکراو لە ٣٠ ڕۆژی ڕابردوو',
      'خۆکار چالاک دەبێت دوای تۆمارکردنی هەژمار',
    ],
    audience: 'عقاراتی نوێ',
    validUntil: 'بەردەوامە',
    imageUrl: 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=900&q=80',
  ),
  Offer(
    id: 'o3',
    icon: Icons.video_camera_back_rounded,
    title: 'ڕیلی بەخۆڕایی زیاتر',
    preview: 'بۆ ماوەی ئەم هەفتەیە، ٥ ڕیلی زیادە بەخۆڕایی وەربگرە.',
    intro: 'هاندانی بەکارهێنانی زیاتری بەشی ڕیلز.',
    highlights: [
      '٥ ڕیلی زیادەی بەخۆڕایی سەرباری سنووری پاکێجەکەت',
      'بۆ عقاراتی ئاستی Business و سەرەوەتر',
      'ئەم ئۆفەرە تەنها بۆ ئەم هەفتەیە بەردەوامە',
    ],
    audience: 'Business و سەرەوەتر',
    validUntil: 'کۆتایی ئەم هەفتەیە',
    imageUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=900&q=80',
  ),
];

class OffersListScreen extends StatelessWidget {
  const OffersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final offers = context.watch<AdminStore>().offers;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: palette.surfaceElevated, shape: BoxShape.circle),
                      child: Icon(Icons.arrow_forward_rounded, size: 18, color: palette.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('offers.title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('offers.active_count'.tr(args: [offers.length.toString()]), style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.local_offer_rounded, color: AppColors.ink, size: 18),
                  ),
                ],
              ),
            ).entrance(),
          ),
          if (offers.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('offers.empty'.tr(), style: TextStyle(color: palette.textSecondary))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              sliver: SliverList.separated(
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, i) => _offerCard(context, offers[i], i),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _offerCard(BuildContext context, Offer offer, int index) {
    final palette = context.palette;
    final accent = _offerAccents[index % _offerAccents.length];
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OfferDetailScreen(offer: offer))),
        borderRadius: BorderRadius.circular(26),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.16), blurRadius: 26, offset: const Offset(0, 14))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: offer.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: palette.surfaceElevated),
                        errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated, child: Icon(Icons.image_outlined, color: palette.textMuted)),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                            stops: const [0.5, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (offer.isNew)
                    Positioned(
                      left: 14,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(20)),
                        child: Text('offers.new_badge'.tr(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(offer.validUntil, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -32),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: palette.surface, width: 3),
                          boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))],
                        ),
                        child: Icon(offer.icon, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(offer.title, style: TextStyle(color: palette.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(offer.preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textSecondary, fontSize: 12, height: 1.5)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(20)),
                                child: Text(offer.audience, style: TextStyle(color: palette.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_forward_ios_rounded, size: 11, color: palette.textMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).entrance(index: index, base: 80.ms);
  }
}
