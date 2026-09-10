import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/dashboard_stats.dart';
import '../../../core/network/dashboard_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _range = 0; // 0 = week, 1 = month
  bool _loading = true;
  DashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await context.read<DashboardRepository>().fetchStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<int> get _chartValues {
    final stats = _stats!;
    return _range == 0 ? stats.daily.map((d) => d.views).toList() : stats.weekly.map((w) => w.views).toList();
  }

  static const _weekdayKeys = {6: 'dashboard.day_sat', 7: 'dashboard.day_sun', 1: 'dashboard.day_mon', 2: 'dashboard.day_tue', 3: 'dashboard.day_wed', 4: 'dashboard.day_thu', 5: 'dashboard.day_fri'};

  List<String> get _chartLabels {
    final stats = _stats!;
    return _range == 0
        ? stats.daily.map((d) => _weekdayKeys[d.date.weekday]!.tr()).toList()
        : List.generate(stats.weekly.length, (i) => 'dashboard.week_label'.tr(args: ['${i + 1}']));
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'dashboard.time_just_now'.tr();
    if (diff.inMinutes < 60) return 'dashboard.time_minutes_ago'.tr(args: ['${diff.inMinutes}']);
    if (diff.inHours < 24) return 'dashboard.time_hours_ago'.tr(args: ['${diff.inHours}']);
    return 'dashboard.time_days_ago'.tr(args: ['${diff.inDays}']);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('profile.dashboard'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: palette.primary))
          : _stats == null
              ? Center(child: Text('dashboard.load_error'.tr(), style: TextStyle(color: palette.textSecondary)))
              : _content(palette, _stats!),
    );
  }

  Widget _content(AppPalette palette, DashboardStats stats) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        _rangeToggle(palette).animate().fadeIn(duration: 280.ms),
        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(child: _statCard(palette, Icons.visibility_outlined, '${stats.totalViews}', 'dashboard.stat_views_label'.tr(), stats.viewsChangePercent, 0)),
            const SizedBox(width: 12),
            Expanded(child: _statCard(palette, Icons.chat_bubble_outline, '${stats.totalContacts}', 'dashboard.stat_contacts_label'.tr(), stats.contactsChangePercent, 60)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard(palette, Icons.home_work_outlined, '${stats.activeListings}', 'dashboard.stat_active_listings_label'.tr(), null, 120)),
            Expanded(child: _statCard(palette, Icons.percent_rounded, '${stats.responseRatePercent.toStringAsFixed(0)}%', 'dashboard.stat_response_rate_label'.tr(), null, 180)),
          ],
        ),

        const SizedBox(height: 28),
        Text('dashboard.weekly_views_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)).animate(delay: 220.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 16),
        _weeklyChart(palette).animate(delay: 260.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),

        const SizedBox(height: 28),
        Text('dashboard.package_usage_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)).animate(delay: 300.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 14),
        _packageUsageCard(stats).animate(delay: 340.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),

        const SizedBox(height: 28),
        Text('dashboard.recent_activity_title'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)).animate(delay: 380.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 12),
        ..._activityItems(palette, stats.recentActivity),
      ],
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

  Widget _statCard(AppPalette palette, IconData icon, String value, String label, double? changePercent, int delay) {
    final trendUp = changePercent == null ? null : changePercent >= 0;
    final trend = changePercent == null ? null : '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(0)}%';
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
    final maxVal = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1 : maxVal;
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
                final heightFactor = values[i] / safeMax;
                final isPeak = values[i] == maxVal && maxVal > 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: heightFactor),
                      duration: Duration(milliseconds: 600 + i * 80),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => FractionallySizedBox(
                        heightFactor: t.clamp(0.02, 1.0),
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

  Widget _packageUsageCard(DashboardStats stats) {
    final hasPackage = stats.packageTitle != null;
    final listingsLimit = stats.listingsLimit;
    final reelsLimit = stats.reelsLimit;
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
              Text(
                hasPackage ? 'dashboard.package_title'.tr(args: [stats.packageTitle!]) : 'dashboard.no_active_package_title'.tr(),
                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasPackage) ...[
            _usageRow(
              'dashboard.usage_listings_label'.tr(),
              listingsLimit == null ? 'dashboard.unlimited_label'.tr() : '${stats.activeListings}/$listingsLimit',
              listingsLimit == null ? 1.0 : (stats.activeListings / listingsLimit).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 12),
            _usageRow(
              'dashboard.usage_reels_label'.tr(),
              reelsLimit == null ? 'dashboard.unlimited_label'.tr() : '${stats.activeReels}/$reelsLimit',
              reelsLimit == null ? 1.0 : (stats.activeReels / reelsLimit).clamp(0.0, 1.0),
            ),
          ] else
            Text('dashboard.no_active_package_subtitle'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

  List<Widget> _activityItems(AppPalette palette, List<RecentActivityItem> items) {
    if (items.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(14)),
          child: Text('dashboard.no_activity'.tr(), style: TextStyle(color: palette.textSecondary, fontSize: 12.5)),
        ),
      ];
    }
    return List.generate(items.length, (i) {
      final item = items[i];
      final isView = item.type == 'view';
      final label = (isView ? 'dashboard.activity_view' : 'dashboard.activity_contact').tr(args: [item.title]);
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
                child: Icon(isView ? Icons.visibility_outlined : Icons.chat_bubble_outline, size: 17, color: AppColors.goldDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_relativeTime(item.createdAt), style: TextStyle(color: palette.textMuted, fontSize: 10.5)),
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
