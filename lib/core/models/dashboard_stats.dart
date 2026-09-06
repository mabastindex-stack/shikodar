class DailyStat {
  final DateTime date;
  final int views;
  final int contacts;
  const DailyStat({required this.date, required this.views, required this.contacts});

  factory DailyStat.fromJson(Map<String, dynamic> json) => DailyStat(
        date: DateTime.parse(json['date']),
        views: json['views'] ?? 0,
        contacts: json['contacts'] ?? 0,
      );
}

class WeeklyStat {
  final int views;
  final int contacts;
  const WeeklyStat({required this.views, required this.contacts});

  factory WeeklyStat.fromJson(Map<String, dynamic> json) => WeeklyStat(
        views: json['views'] ?? 0,
        contacts: json['contacts'] ?? 0,
      );
}

class RecentActivityItem {
  final String type; // 'view' | 'contact'
  final String title;
  final DateTime createdAt;
  const RecentActivityItem({required this.type, required this.title, required this.createdAt});

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) => RecentActivityItem(
        type: json['type'] ?? 'view',
        title: json['title'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
      );
}

/// Backs dashboard_screen.dart — real view/contact counts from the last
/// 28 days of activity, bucketed daily (last 7 days) and weekly (last 4
/// weeks), with week-over-week percent change for the two stat cards,
/// plus the agency's real listing/reel counts, response rate, tier, and
/// a feed of its most recent view/contact events.
class DashboardStats {
  final int totalViews;
  final int totalContacts;
  final double? viewsChangePercent;
  final double? contactsChangePercent;
  final List<DailyStat> daily;
  final List<WeeklyStat> weekly;
  final int activeListings;
  final int activeReels;
  final double responseRatePercent;
  final String? tier;
  final List<RecentActivityItem> recentActivity;

  const DashboardStats({
    required this.totalViews,
    required this.totalContacts,
    this.viewsChangePercent,
    this.contactsChangePercent,
    required this.daily,
    required this.weekly,
    required this.activeListings,
    required this.activeReels,
    required this.responseRatePercent,
    this.tier,
    required this.recentActivity,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalViews: json['totals']['views'] ?? 0,
        totalContacts: json['totals']['contacts'] ?? 0,
        viewsChangePercent: (json['change']['views_percent'] as num?)?.toDouble(),
        contactsChangePercent: (json['change']['contacts_percent'] as num?)?.toDouble(),
        daily: (json['daily'] as List).map((d) => DailyStat.fromJson(d)).toList(),
        weekly: (json['weekly'] as List).map((w) => WeeklyStat.fromJson(w)).toList(),
        activeListings: json['active_listings'] ?? 0,
        activeReels: json['active_reels'] ?? 0,
        responseRatePercent: (json['response_rate_percent'] as num?)?.toDouble() ?? 0,
        tier: json['tier'],
        recentActivity: (json['recent_activity'] as List).map((a) => RecentActivityItem.fromJson(a)).toList(),
      );
}
