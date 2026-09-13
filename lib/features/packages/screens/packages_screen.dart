import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/network/package_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import 'package_detail_screen.dart';

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
    );
  }

  Widget _tierCard(BuildContext context, int i) {
    final palette = context.palette;
    final package = _packages[i];
    final color = _tierColor(i);
    final deepColor = Color.lerp(color, Colors.black, 0.28)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PackageDetailScreen(package: package, color: color, icon: _tierIcon(i))),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [palette.surface, Color.lerp(palette.surface, color, 0.08)!],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.18)),
              boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, deepColor]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Icon(_tierIcon(i), color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(package.title, style: TextStyle(color: palette.textPrimary, fontSize: 17.5, fontWeight: FontWeight.w800)),
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
                        Text(package.formattedPrice, style: TextStyle(color: deepColor, fontSize: 20, fontWeight: FontWeight.w900)),
                        Text(
                          package.durationDays == null ? 'packages.unlimited_duration'.tr() : 'packages.duration_days'.tr(args: [package.durationDays.toString()]),
                          style: TextStyle(color: palette.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_left_rounded, size: 20, color: palette.textMuted),
                  ],
                ),
                if (package.imageUrl != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: package.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: palette.surfaceElevated),
                            errorWidget: (_, __, ___) => Container(color: palette.surfaceElevated),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(height: 5, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, deepColor]))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(18)),
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
      ),
    )
        .animate(delay: (90 * i).ms)
        .fadeIn(duration: 420.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack, duration: 460.ms);
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
}
