import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class _PackagePlan {
  final String name;
  final int price;
  final String tagline;
  final String listingsLimit;
  final String reelsLimit;
  final List<String> features;
  final bool isEnterprise;
  const _PackagePlan({
    required this.name,
    required this.price,
    required this.tagline,
    required this.listingsLimit,
    required this.reelsLimit,
    required this.features,
    this.isEnterprise = false,
  });
}

List<_PackagePlan> get _plans => [
      _PackagePlan(
        name: 'Starter',
        price: 50,
        tagline: 'packages.starter_tagline'.tr(),
        listingsLimit: 'packages.starter_listings_limit'.tr(),
        reelsLimit: 'packages.starter_reels_limit'.tr(),
        features: ['packages.starter_feature_1'.tr()],
      ),
      _PackagePlan(
        name: 'Basic',
        price: 100,
        tagline: 'packages.basic_tagline'.tr(),
        listingsLimit: 'packages.basic_listings_limit'.tr(),
        reelsLimit: 'packages.basic_reels_limit'.tr(),
        features: ['packages.basic_feature_1'.tr(), 'packages.basic_feature_2'.tr()],
      ),
      _PackagePlan(
        name: 'Business',
        price: 175,
        tagline: 'packages.business_tagline'.tr(),
        listingsLimit: 'packages.business_listings_limit'.tr(),
        reelsLimit: 'packages.business_reels_limit'.tr(),
        features: ['packages.business_feature_1'.tr(), 'packages.business_feature_2'.tr()],
      ),
      _PackagePlan(
        name: 'Premium',
        price: 250,
        tagline: 'packages.premium_tagline'.tr(),
        listingsLimit: 'packages.premium_listings_limit'.tr(),
        reelsLimit: 'packages.premium_reels_limit'.tr(),
        features: ['packages.premium_feature_1'.tr(), 'packages.premium_feature_2'.tr()],
      ),
      _PackagePlan(
        name: 'Enterprise',
        price: 400,
        tagline: 'packages.enterprise_tagline'.tr(),
        listingsLimit: 'packages.enterprise_listings_limit'.tr(),
        reelsLimit: 'packages.enterprise_reels_limit'.tr(),
        features: [
          'packages.enterprise_feature_1'.tr(),
          'packages.enterprise_feature_2'.tr(),
          'packages.enterprise_feature_3'.tr(),
        ],
        isEnterprise: true,
      ),
    ];

const _tierIcons = [Icons.eco_rounded, Icons.trending_up_rounded, Icons.handshake_rounded, Icons.workspace_premium_rounded, Icons.auto_awesome_rounded];
const _tierImages = [
  'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=900&q=80',
  'https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=900&q=80',
  'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=900&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=900&q=80',
  'https://images.unsplash.com/photo-1519501025264-65ba15a82390?w=900&q=80',
];

Color _tierColor(int i) {
  switch (i) {
    case 0:
      return AppColors.tierStarter;
    case 1:
      return AppColors.tierBasic;
    case 2:
      return AppColors.tierBusiness;
    case 3:
      return AppColors.tierPremium;
    default:
      return AppColors.tierEnterprise;
  }
}

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  int _selected = 3; // Premium pre-selected as the "recommended" anchor

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                        Text('packages.title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('packages.subtitle'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                itemCount: _plans.length,
                itemBuilder: (context, i) => _tierCard(context, i),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ctaBar(palette),
    );
  }

  Widget _tierCard(BuildContext context, int i) {
    final palette = context.palette;
    final plan = _plans[i];
    final color = _tierColor(i);
    final selected = i == _selected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => setState(() => _selected = i),
        child: Container(
          decoration: BoxDecoration(
            color: plan.isEnterprise ? AppColors.ink : palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border(right: BorderSide(color: color, width: 6)),
            boxShadow: [
              BoxShadow(
                color: (selected ? color : palette.shadow).withOpacity(selected ? 0.3 : 0.1),
                blurRadius: selected ? 20 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
                    child: Icon(_tierIcons[i], color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.name,
                              style: TextStyle(color: plan.isEnterprise ? AppColors.gold : palette.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            if (plan.isEnterprise) ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 15),
                            ],
                            if (selected) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                                child: Text('packages.selected_badge'.tr(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.tagline,
                          style: TextStyle(color: plan.isEnterprise ? Colors.white70 : palette.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${plan.price}', style: TextStyle(color: plan.isEnterprise ? Colors.white : palette.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
                      Text('packages.per_month'.tr(), style: TextStyle(color: plan.isEnterprise ? Colors.white54 : palette.textMuted, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: _tierImages[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: palette.surfaceElevated),
                    errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: plan.isEnterprise ? Colors.white.withOpacity(0.05) : palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _detailRow(palette, Icons.home_work_outlined, plan.listingsLimit, plan.isEnterprise, color, isFirst: true),
                    _detailRow(palette, Icons.play_circle_outline, plan.reelsLimit, plan.isEnterprise, color),
                    for (var f = 0; f < plan.features.length; f++)
                      _detailRow(palette, Icons.check_circle_outline, plan.features[f], plan.isEnterprise, color, isLast: f == plan.features.length - 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (60 * i).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _detailRow(AppPalette palette, IconData icon, String label, bool onDark, Color accent, {bool isFirst = false, bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: onDark ? Colors.white.withOpacity(0.1) : accent.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 16, color: onDark ? AppColors.gold : accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(color: onDark ? Colors.white : palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.check_rounded, size: 16, color: onDark ? AppColors.gold : accent),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 10, endIndent: 10, color: onDark ? Colors.white.withOpacity(0.08) : palette.divider),
      ],
    );
  }

  void _showContactSheet(_PackagePlan plan) {
    final color = _tierColor(_selected);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetPalette = sheetContext.palette;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.fromLTRB(22, 20, 22, 22 + MediaQuery.of(sheetContext).padding.bottom),
            decoration: BoxDecoration(color: sheetPalette.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(color: sheetPalette.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
                      child: Icon(_tierIcons[_selected], color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('packages.plan_title'.tr(args: [plan.name]), style: TextStyle(color: sheetPalette.textPrimary, fontSize: 15.5, fontWeight: FontWeight.w800)),
                          Text('\$${plan.price} ${'packages.per_month'.tr()}', style: TextStyle(color: sheetPalette.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('packages.contact_to_activate'.tr(), style: TextStyle(color: sheetPalette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('https://wa.me/9647700000000?text=${Uri.encodeComponent('packages.whatsapp_message'.tr(args: [plan.name]))}'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.chat, size: 18),
                    label: Text('packages.contact_via_whatsapp'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.whatsapp,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:+9647700000000')),
                    icon: Icon(Icons.phone, size: 18, color: sheetPalette.primary),
                    label: Text('packages.call_action'.tr(), style: TextStyle(color: sheetPalette.primary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: sheetPalette.primary.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ctaBar(AppPalette palette) {
    final plan = _plans[_selected];
    final color = _tierColor(_selected);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: Icon(_tierIcons[_selected], color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(plan.name, style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                Text('\$${plan.price} ${'packages.per_month'.tr()}', style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showContactSheet(plan),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('packages.choose_action'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
