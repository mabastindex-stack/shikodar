import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/network/offer_repository.dart';
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
  final String? logoUrl;
  final String? videoUrl;
  final int? listingsLimit;
  final int? reelsLimit;
  final String? currency;
  final double? price;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<String> targetRoles;
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
    this.logoUrl,
    this.videoUrl,
    this.listingsLimit,
    this.reelsLimit,
    this.currency,
    this.price,
    this.startsAt,
    this.endsAt,
    this.targetRoles = const [],
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
        logoUrl: logoUrl,
        videoUrl: videoUrl,
        listingsLimit: listingsLimit,
        reelsLimit: reelsLimit,
        currency: currency,
        price: price,
        startsAt: startsAt,
        endsAt: endsAt,
        targetRoles: targetRoles,
        isNew: isNew ?? this.isNew,
      );

  /// Mirrors Offer::formattedPrice() on the backend — null when no price was set.
  String? get formattedPrice {
    final p = price;
    if (p == null) return null;
    return currency == 'usd' ? '\$${p.toStringAsFixed(2)}' : '${p.toStringAsFixed(0)} د.ع';
  }

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id'].toString(),
        icon: iconFromName(json['icon'] ?? ''),
        title: json['title'] ?? '',
        preview: json['preview'] ?? '',
        intro: json['intro'] ?? '',
        highlights: (json['highlights'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        audience: json['audience'] ?? '',
        validUntil: json['valid_until'] ?? '',
        imageUrl: json['image_url'] ?? '',
        logoUrl: (json['logo_url'] as String?)?.isNotEmpty == true ? json['logo_url'] as String : null,
        videoUrl: (json['video_url'] as String?)?.isNotEmpty == true ? json['video_url'] as String : null,
        listingsLimit: json['listings_limit'] == null ? null : int.tryParse(json['listings_limit'].toString()),
        reelsLimit: json['reels_limit'] == null ? null : int.tryParse(json['reels_limit'].toString()),
        currency: json['currency'] as String?,
        price: json['price'] == null ? null : double.tryParse(json['price'].toString()),
        startsAt: json['starts_at'] == null ? null : DateTime.tryParse(json['starts_at'].toString())?.toLocal(),
        endsAt: json['ends_at'] == null ? null : DateTime.tryParse(json['ends_at'].toString())?.toLocal(),
        targetRoles: (json['target_roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        isNew: json['is_new'] ?? false,
      );
}

/// Zero-padded d/m/y — avoids intl's DateFormat, which throws on locale
/// 'ku' (Kurdish isn't in its ICU data).
String formatOfferDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

const Map<String, String> offerTargetRoleLabels = {
  'agency': 'عقارات',
  'company': 'کۆمپانیا',
  'complex': 'مجمع سکنی',
};

/// The badge text shown for who an offer is for — falls back to the legacy
/// free-text `audience` field for offers created before target_roles existed.
String offerAudienceLabel(Offer offer) {
  final roles = offer.targetRoles;
  if (roles.isEmpty || roles.contains('all')) {
    return offer.audience.isNotEmpty ? offer.audience : 'offers.all_business_accounts'.tr();
  }
  return roles.map((r) => offerTargetRoleLabels[r] ?? r).join('، ');
}

/// Prefers the new `ends_at` schedule field, falling back to the legacy
/// free-text `valid_until` for offers created before scheduling existed.
/// Null means neither is set, so the caller should hide the badge entirely.
String? offerValidUntilText(Offer offer) {
  if (offer.endsAt != null) return formatOfferDate(offer.endsAt!);
  if (offer.validUntil.isNotEmpty) return offer.validUntil;
  return null;
}

/// Maps the backend's icon-name string (admin picks one when creating an
/// offer) to a real Material icon constant. Extend as new offer icons are
/// introduced.
IconData iconFromName(String name) {
  switch (name) {
    case 'card_giftcard_rounded':
      return Icons.card_giftcard_rounded;
    case 'vpn_key_rounded':
      return Icons.vpn_key_rounded;
    case 'video_camera_back_rounded':
      return Icons.video_camera_back_rounded;
    default:
      return Icons.local_offer_rounded;
  }
}

/// One accent per offer, cycling through the app's own emerald/jade family —
/// enough to tell cards apart at a glance without introducing a second hue.
const _offerAccents = [AppColors.emeraldDark, AppColors.gold, AppColors.emerald];

class OffersListScreen extends StatefulWidget {
  const OffersListScreen({super.key});

  @override
  State<OffersListScreen> createState() => _OffersListScreenState();
}

class _OffersListScreenState extends State<OffersListScreen> {
  List<Offer> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<OfferRepository>().fetchAll().then((offers) {
      if (mounted) setState(() { _offers = offers; _isLoading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final offers = _offers;
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
          if (_isLoading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: palette.primary)),
            )
          else if (offers.isEmpty)
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
                  if (offerValidUntilText(offer) != null)
                    Positioned(
                      left: 14,
                      bottom: 12,
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(offerValidUntilText(offer)!, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  if (offer.formattedPrice != null)
                    Positioned(
                      right: 14,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.priceAccent, borderRadius: BorderRadius.circular(20)),
                        child: Text(offer.formattedPrice!, style: const TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  if (offer.videoUrl != null)
                    const Positioned.fill(
                      child: Center(
                        child: Icon(Icons.play_circle_fill_rounded, size: 46, color: Colors.white70),
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
                                child: Text(offerAudienceLabel(offer), style: TextStyle(color: palette.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
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
