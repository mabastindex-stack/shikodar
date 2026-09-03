import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _range = 0; // 0 = week, 1 = month

  // Mock weekly views (Sat..Fri) and the last 4 weeks' totals — swap for
  // real API data later.
  static const _weekViews = [42.0, 68.0, 55.0, 91.0, 130.0, 88.0, 104.0];
  static const _monthViews = [612.0, 745.0, 580.0, 810.0];

  List<double> get _chartValues => _range == 0 ? _weekViews : _monthViews;

  List<String> get _weekLabels => [
        'dashboard.day_sat'.tr(),
        'dashboard.day_sun'.tr(),
        'dashboard.day_mon'.tr(),
        'dashboard.day_tue'.tr(),
        'dashboard.day_wed'.tr(),
        'dashboard.day_thu'.tr(),
        'dashboard.day_fri'.tr(),
      ];

  List<String> get _chartLabels => _range == 0
      ? _weekLabels
      : List.generate(_monthViews.length, (i) => 'dashboard.week_label'.tr(args: ['${i + 1}']));

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('profile.dashboard'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          _rangeToggle(palette).animate().fadeIn(duration: 280.ms),
          const SizedBox(height: 18),

          // Top stat cards.
          Row(
            children: [
              Expanded(child: _statCard(palette, Icons.visibility_outlined, '1,284', 'dashboard.stat_views_label'.tr(), '+18%', true, 0)),
              const SizedBox(width: 12),
              Expanded(child: _statCard(palette, Icons.chat_bubble_outline, '96', 'dashboard.stat_contacts_label'.tr(), '+7%', true, 60)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard(palette, Icons.home_work_outlined, '24', 'dashboard.stat_active_listings_label'.tr(), null, null, 120)),
              Expanded(child: _statCard(palette, Icons.percent_rounded, '7.5%', 'dashboard.stat_response_rate_label'.tr(), '-2%', false, 180)),
            ],
          ),

          const SizedBox(height: 28),
          Text('dashboard.weekly_views_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)).animate(delay: 220.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          _weeklyChart(palette).animate(delay: 260.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 28),
          Text('dashboard.package_usage_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)).animate(delay: 300.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: 14),
          _packageUsageCard().animate(delay: 340.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 28),
          Text('dashboard.recent_activity_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)).animate(delay: 380.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
          ..._activityItems(palette),
        ],
      ),
    );
  }

  Widget _rangeToggle(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(child: _rangeTab(palette, 'dashboard.range_week'.tr(), 0)),
          Expanded(child: _rangeTab(palette, 'dashboard.range_month'.tr(), 1)),
        ],
      ),
    );
  }

  Widget _rangeTab(AppPalette palette, String label, int value) {
    final selected = _range == value;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: () => setState(() => _range = value),
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? palette.textPrimary : Colors.transparent, borderRadius: BorderRadius.circular(11)),
          child: Text(label, style: TextStyle(color: selected ? palette.background : palette.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _statCard(AppPalette palette, IconData icon, String value, String label, String? trend, bool? trendUp, int delay) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 16, color: AppColors.goldDark),
              ),
              if (trend != null)
                Row(
                  children: [
                    Icon(trendUp! ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 13, color: trendUp ? AppColors.whatsapp : palette.error),
                    const SizedBox(width: 2),
                    Text(trend, style: TextStyle(color: trendUp ? AppColors.whatsapp : palette.error, fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: palette.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 11)),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 320.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _weeklyChart(AppPalette palette) {
    final values = _chartValues;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final heightFactor = values[i] / maxVal;
                final isPeak = values[i] == maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: heightFactor),
                      duration: Duration(milliseconds: 600 + i * 80),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => FractionallySizedBox(
                        heightFactor: t,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isPeak ? AppColors.goldGradient : null,
                            color: isPeak ? null : palette.surfaceElevated,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _chartLabels.map((l) => Expanded(child: Text(l, textAlign: TextAlign.center, style: TextStyle(color: palette.textSecondary, fontSize: 10.5)))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _packageUsageCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.ink, Color(0xFF2A2620)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text('dashboard.enterprise_package_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          _usageRow('dashboard.usage_listings_label'.tr(), 'dashboard.unlimited_label'.tr(), 1.0),
          const SizedBox(height: 12),
          _usageRow('dashboard.usage_reels_label'.tr(), 'dashboard.unlimited_label'.tr(), 1.0),
        ],
      ),
    );
  }

  Widget _usageRow(String label, String valueLabel, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(valueLabel, style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => LinearProgressIndicator(
              value: t,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _activityItems(AppPalette palette) {
    final items = [
      (Icons.chat_bubble_outline, 'dashboard.activity_new_contact'.tr(), 'dashboard.time_1_day_ago'.tr()),
      (Icons.visibility_outlined, 'dashboard.activity_new_views'.tr(), 'dashboard.time_3_hours_ago'.tr()),
      (Icons.star_outline_rounded, 'dashboard.activity_new_review'.tr(), 'dashboard.time_2_days_ago'.tr()),
      (Icons.favorite_border, 'dashboard.activity_new_favorites'.tr(), 'dashboard.time_4_days_ago'.tr()),
    ];
    return List.generate(items.length, (i) {
      final item = items[i];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: palette.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                child: Icon(item.$1, size: 17, color: AppColors.goldDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$2, style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(item.$3, style: TextStyle(color: palette.textMuted, fontSize: 10.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: (420 + i * 60).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
    });
  }
}
