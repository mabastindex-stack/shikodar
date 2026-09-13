import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/package_repository.dart';
import '../../../core/shikodar_contact.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class Package {
  final String id;
  final String title;
  final String? description;
  final int? listingsLimit;
  final int? reelsLimit;
  final double price;
  final String currency;
  final int? durationDays;
  final String? imageUrl;
  final String? homeImageUrl;
  final String? logoUrl;
  final String? videoUrl;

  const Package({
    required this.id,
    required this.title,
    this.description,
    this.listingsLimit,
    this.reelsLimit,
    required this.price,
    this.currency = 'usd',
    this.durationDays,
    this.imageUrl,
    this.homeImageUrl,
    this.logoUrl,
    this.videoUrl,
  });

  /// Mirrors Package::formattedPrice() on the backend.
  String get formattedPrice => currency == 'usd' ? '\$${price.toStringAsFixed(2)}' : '${price.toStringAsFixed(0)} د.ع';

  factory Package.fromJson(Map<String, dynamic> json) => Package(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        description: (json['description'] as String?)?.isNotEmpty == true ? json['description'] as String : null,
        listingsLimit: json['listings_limit'] == null ? null : int.tryParse(json['listings_limit'].toString()),
        reelsLimit: json['reels_limit'] == null ? null : int.tryParse(json['reels_limit'].toString()),
        price: double.tryParse(json['price'].toString()) ?? 0,
        currency: json['currency'] as String? ?? 'usd',
        durationDays: json['duration_days'] == null ? null : int.tryParse(json['duration_days'].toString()),
        imageUrl: (json['image_url'] as String?)?.isNotEmpty == true ? json['image_url'] as String : null,
        homeImageUrl: (json['home_image_url'] as String?)?.isNotEmpty == true ? json['home_image_url'] as String : null,
        logoUrl: (json['logo_url'] as String?)?.isNotEmpty == true ? json['logo_url'] as String : null,
        videoUrl: (json['video_url'] as String?)?.isNotEmpty == true ? json['video_url'] as String : null,
      );
}

/// Packages have no admin-picked icon (unlike Offer) — cycle a fixed set so
/// cards stay visually distinct at a glance regardless of how many exist.
const _tierIcons = [Icons.eco_rounded, Icons.trending_up_rounded, Icons.handshake_rounded, Icons.workspace_premium_rounded, Icons.auto_awesome_rounded];
const _tierColors = [AppColors.tierStarter, AppColors.tierBasic, AppColors.tierBusiness, AppColors.tierPremium, AppColors.tierEnterprise];

Color _tierColor(int i) => _tierColors[i % _tierColors.length];
IconData _tierIcon(int i) => _tierIcons[i % _tierIcons.length];

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  List<Package> _packages = [];
  bool _isLoading = true;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    context.read<PackageRepository>().fetchAll().then((packages) {
      if (mounted) setState(() { _packages = packages; _isLoading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final packages = _packages;
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
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: palette.primary))
                  : packages.isEmpty
                      ? Center(child: Text('packages.empty'.tr(), style: TextStyle(color: palette.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          itemCount: packages.length,
                          itemBuilder: (context, i) => _tierCard(context, i),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: (_isLoading || packages.isEmpty) ? null : _ctaBar(palette),
    );
  }

  Widget _tierCard(BuildContext context, int i) {
    final palette = context.palette;
    final package = _packages[i];
    final color = _tierColor(i);
    final selected = i == _selected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => setState(() => _selected = i),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surface,
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
                    child: Icon(_tierIcon(i), color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                package.title,
                                style: TextStyle(color: palette.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                            ),
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
                        if (package.description != null) ...[
                          const SizedBox(height: 2),
                          Text(package.description!, style: TextStyle(color: palette.textSecondary, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(package.formattedPrice, style: TextStyle(color: palette.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
                      Text(
                        package.durationDays == null ? 'packages.unlimited_duration'.tr() : 'packages.duration_days'.tr(args: [package.durationDays.toString()]),
                        style: TextStyle(color: palette.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              if (package.imageUrl != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: package.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: palette.surfaceElevated),
                      errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _detailRow(
                      palette,
                      Icons.home_work_outlined,
                      package.listingsLimit == null ? 'packages.unlimited_listings'.tr() : 'packages.listings_limit_label'.tr(args: [package.listingsLimit.toString()]),
                      color,
                      isFirst: true,
                    ),
                    _detailRow(
                      palette,
                      Icons.play_circle_outline,
                      package.reelsLimit == null ? 'packages.unlimited_reels'.tr() : 'packages.reels_limit_label'.tr(args: [package.reelsLimit.toString()]),
                      color,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (60 * i).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _detailRow(AppPalette palette, IconData icon, String label, Color accent, {bool isFirst = false, bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: accent.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
              Icon(Icons.check_rounded, size: 16, color: accent),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 10, endIndent: 10, color: palette.divider),
      ],
    );
  }

  void _showContactSheet(Package package) {
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
                      child: Icon(_tierIcon(_selected), color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('packages.plan_title'.tr(args: [package.title]), style: TextStyle(color: sheetPalette.textPrimary, fontSize: 15.5, fontWeight: FontWeight.w800)),
                          Text(package.formattedPrice, style: TextStyle(color: sheetPalette.textSecondary, fontSize: 12)),
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
                      Uri.parse('https://wa.me/$shikodarPhoneDigits?text=${Uri.encodeComponent('packages.whatsapp_message'.tr(args: [package.title]))}'),
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
                    onPressed: () => launchUrl(Uri.parse('tel:+$shikodarPhoneDigits')),
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
    final package = _packages[_selected];
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
            child: Icon(_tierIcon(_selected), color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(package.title, style: TextStyle(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                Text(package.formattedPrice, style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showContactSheet(package),
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
