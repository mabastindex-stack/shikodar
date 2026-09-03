import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/listing.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/session/business_profile_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../home/widgets/listing_card.dart';

/// Real property photos (Unsplash) used for the cover carousel. Premium/
/// Enterprise agencies get the full rotating set; other tiers show only the
/// first photo, static — the tier gap made visible.
const _coverPhotos = [
  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&q=80',
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=80',
  'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=1200&q=80',
];

class _Review {
  final String name;
  final double rating;
  final String comment;
  const _Review(this.name, this.rating, this.comment);
}

final _mockReviews = [
  _Review('هەڵۆ کەریم', 5, 'agency_profile.review_comment_1'.tr()),
  _Review('شنۆ ئازاد', 4.5, 'agency_profile.review_comment_2'.tr()),
  _Review('ڕێباز سامان', 5, 'agency_profile.review_comment_3'.tr()),
];

/// Premium agency / broker portfolio page. Visual richness — animated cover,
/// glowing avatar, count-up stats — scales with package tier, so the tier
/// itself becomes the upsell.
class AgencyProfileScreen extends StatefulWidget {
  final Agency agency;
  const AgencyProfileScreen({super.key, required this.agency});

  @override
  State<AgencyProfileScreen> createState() => _AgencyProfileScreenState();
}

class _AgencyProfileScreenState extends State<AgencyProfileScreen> with TickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final AnimationController _glow;
  late final AnimationController _kenBurns;
  Timer? _carouselTimer;
  int _coverIndex = 0;
  int _tab = 0; // 0 listings, 1 reels, 2 reviews, 3 about

  bool get _isPremiumTier => widget.agency.tier == PackageTier.premium || widget.agency.tier == PackageTier.enterprise;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _glow = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _kenBurns = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    if (_isPremiumTier) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() => _coverIndex = (_coverIndex + 1) % _coverPhotos.length);
      });
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _glow.dispose();
    _kenBurns.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final a = widget.agency;
    final listings = MockData.listings.where((l) => l.agency.id == a.id).toList();
    final foundedYear = DateTime.now().year - a.yearsActive;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.ink,
                expandedHeight: 240,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _circleBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _circleBtn(Icons.ios_share_rounded, () async {
                      await Clipboard.setData(ClipboardData(text: '${a.name}\n${a.bio}'));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('agency_profile.info_copied'.tr()), behavior: SnackBarBehavior.floating));
                    }),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _cover(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      _identityCard(a, foundedYear).animate().fadeIn(duration: 380.ms).slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 14),
                      _statsRow(a).animate(delay: 120.ms).fadeIn(duration: 380.ms).slideY(begin: 0.12, end: 0),
                      const SizedBox(height: 18),
                      _tabsBar(),
                    ],
                  ),
                ),
              ),
              if (_tab == 0)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
                  sliver: listings.isEmpty
                      ? SliverToBoxAdapter(child: _emptyState('agency_profile.empty_listings'.tr()))
                      : SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.66,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => ListingCard(listing: listings[i], animationIndex: i),
                            childCount: listings.length,
                          ),
                        ),
                )
              else if (_tab == 1)
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 40, bottom: 130), child: _emptyState('agency_profile.empty_reels'.tr())))
              else if (_tab == 2)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _reviewCard(_mockReviews[i], i),
                      ),
                      childCount: _mockReviews.length,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                    child: _aboutSection(a, foundedYear),
                  ),
                ),
            ],
          ),
          // Sticky contact bar — always reachable regardless of scroll/tab.
          Positioned(left: 0, right: 0, bottom: 0, child: _contactBar()),
        ],
      ),
    );
  }

  /// The cover: real property photos, crossfading with a slow Ken-Burns
  /// zoom. Premium/Enterprise auto-advance through the full set with dot
  /// indicators; other tiers show a single static (still real, still
  /// beautiful) photo — the tier gap made visible, not just described.
  Widget _cover() {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 900),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
          child: AnimatedBuilder(
            key: ValueKey(_coverIndex),
            animation: _kenBurns,
            builder: (context, child) => Transform.scale(
              scale: 1.06 + 0.06 * _kenBurns.value,
              child: child,
            ),
            child: CachedNetworkImage(
              imageUrl: _coverPhotos[_coverIndex],
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 400),
              placeholder: (context, url) => Container(color: AppColors.ink),
              errorWidget: (context, url, error) => Container(
                color: AppColors.ink,
                child: const Icon(Icons.image_outlined, color: Colors.white24, size: 40),
              ),
            ),
          ),
        ),
        // Gradient scrim for status-bar / back-button legibility.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x88000000), Colors.transparent, Color(0xB3000000)],
              stops: [0.0, 0.35, 1.0],
            ),
          ),
        ),
        // Gold shimmer sweep for premium tiers — the "special, premium"
        // signal layered on top of the real photography.
        if (_isPremiumTier)
          AnimatedBuilder(
            animation: _shimmer,
            builder: (context, child) {
              final t = _shimmer.value;
              return Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + 2 * t, -1),
                      end: Alignment(0 + 2 * t, 1),
                      colors: [Colors.transparent, AppColors.gold.withOpacity(0.16), Colors.transparent],
                      stops: const [0.35, 0.5, 0.65],
                    ),
                  ),
                ),
              );
            },
          ),
        if (_isPremiumTier)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_coverPhotos.length, (i) {
                final active = i == _coverIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.gold : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _identityCard(Agency a, int foundedYear) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: palette.divider)),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _glow,
            builder: (context, child) {
              final glowT = a.verified ? _glow.value : 0.0;
              return Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.gold.withOpacity(0.25 + 0.2 * glowT), blurRadius: 14 + 10 * glowT, spreadRadius: 1 + glowT),
                    ...AppColors.cardShadow,
                  ],
                ),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: _isPremiumTier ? AppColors.goldGradient : null,
                color: _isPremiumTier ? null : AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: palette.surface, width: 3),
              ),
              child: Icon(Icons.storefront_rounded, color: _isPremiumTier ? AppColors.ink : palette.textMuted, size: 30),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(a.name, style: TextStyle(color: palette.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              if (a.verified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: AppColors.goldDark, size: 19),
              ],
            ],
          ),
          const SizedBox(height: 6),
          _tierBadge(a),
          const SizedBox(height: 10),
          Text('agency_profile.founded_year'.tr(args: ['$foundedYear']), style: TextStyle(color: palette.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tierBadge(Agency a) {
    final palette = context.palette;
    final label = switch (a.tier) {
      PackageTier.starter => 'Starter',
      PackageTier.basic => 'Basic',
      PackageTier.business => 'Business',
      PackageTier.premium => 'Premium',
      PackageTier.enterprise => 'Enterprise ✦',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: _isPremiumTier ? AppColors.goldGradient : null,
        color: _isPremiumTier ? null : palette.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: _isPremiumTier ? AppColors.ink : palette.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }

  Widget _statsRow(Agency a) {
    final palette = context.palette;
    final stats = [
      (Icons.star_rounded, a.rating?.toStringAsFixed(1) ?? '—', 'agency_profile.stat_rating'.tr()),
      (Icons.handshake_rounded, '${a.dealsCompleted}', 'agency_profile.stat_deals'.tr()),
      (Icons.schedule_rounded, '${a.yearsActive}', 'agency_profile.stat_years_experience'.tr()),
      (Icons.bolt_rounded, '%${a.responseRatePercent}', 'agency_profile.stat_response_rate'.tr()),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: palette.divider)),
      child: Row(
        children: stats
            .map((s) => Expanded(
                  child: Column(
                    children: [
                      Icon(s.$1, size: 18, color: AppColors.goldDark),
                      const SizedBox(height: 4),
                      _CountUpText(target: s.$2),
                      const SizedBox(height: 2),
                      Text(s.$3, style: TextStyle(color: palette.textSecondary, fontSize: 9.5), textAlign: TextAlign.center),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _tabsBar() {
    final palette = context.palette;
    final labels = ['agency_profile.tab_listings'.tr(), 'agency_profile.tab_reels'.tr(), 'agency_profile.tab_reviews'.tr(), 'agency_profile.tab_about'.tr()];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _tab == i;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                onTap: () => setState(() => _tab = i),
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: selected ? palette.primary : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                  alignment: Alignment.center,
                  child: Text(labels[i], style: TextStyle(color: selected ? palette.onPrimary : palette.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _reviewCard(_Review r, int i) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: palette.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: palette.surfaceElevated, child: Text(r.name.substring(0, 1), style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              Expanded(child: Text(r.name, style: TextStyle(color: palette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700))),
              Row(
                children: List.generate(5, (s) => Icon(s < r.rating.round() ? Icons.star_rounded : Icons.star_border_rounded, size: 14, color: AppColors.amber)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.comment, style: TextStyle(color: palette.textSecondary, fontSize: 12.5, height: 1.5)),
        ],
      ),
    ).animate(delay: (80 * i).ms).fadeIn(duration: 320.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _aboutSection(Agency a, int foundedYear) {
    final palette = context.palette;
    // "My own" agency's about section is owner-editable from the Profile
    // tab (EditBusinessProfileScreen) — reflect those edits live here.
    final isMine = a.id == MockData.agencyShiko.id;
    final store = isMine ? context.watch<BusinessProfileStore>() : null;
    final bio = store?.bio ?? a.bio;
    final specialties = store?.specialties.toList() ?? a.specialties;
    final serviceAreas = store?.serviceAreas.toList() ?? a.serviceAreas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: palette.divider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('agency_profile.about_company_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(bio.isNotEmpty ? bio : 'agency_profile.no_bio_fallback'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.6)),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 14),
        if (specialties.isNotEmpty) ...[
          _chipSection('agency_profile.specialties_title'.tr(), specialties, Icons.workspace_premium_outlined),
          const SizedBox(height: 14),
        ],
        if (serviceAreas.isNotEmpty) _chipSection('agency_profile.service_areas_title'.tr(), serviceAreas, Icons.map_outlined),
      ],
    );
  }

  Widget _chipSection(String title, List<String> items, IconData icon) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: palette.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 16, color: palette.gold), const SizedBox(width: 6), Text(title, style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(20)),
                      child: Text(s, style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 300.ms);
  }

  Widget _emptyState(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(text, style: TextStyle(color: context.palette.textSecondary)),
        ),
      );

  Widget _contactBar() {
    final palette = context.palette;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: palette.background.withOpacity(0.94),
            border: Border(top: BorderSide(color: palette.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://wa.me/9647700000000'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.chat, size: 18),
                  label: Text('listing.contact_whatsapp'.tr()),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.whatsapp, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:+9647700000000')),
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text('listing.contact_call'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 17, color: AppColors.ink)),
          ),
        ),
      );
}

/// Small count-up text — animates from 0 to the numeric part of [target] the
/// first time it appears, keeping any non-numeric suffix/prefix (like '%').
class _CountUpText extends StatelessWidget {
  final String target;
  const _CountUpText({required this.target});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final match = RegExp(r'[\d.]+').firstMatch(target);
    final numeric = match != null ? double.tryParse(match.group(0)!) : null;
    if (numeric == null) {
      return Text(target, style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800));
    }
    final prefix = target.substring(0, match!.start);
    final suffix = target.substring(match.end);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: numeric),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final display = numeric == numeric.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
        return Text('$prefix$display$suffix', style: TextStyle(color: palette.textPrimary, fontSize: 15, fontWeight: FontWeight.w800));
      },
    );
  }
}
