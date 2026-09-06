import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/network/notification_repository.dart';
import '../../../core/theme/app_palette.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final notifications = await context.read<NotificationRepository>().fetchAll();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
      if (notifications.any((n) => n.isNew)) {
        context.read<NotificationRepository>().markRead();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('notifications.title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _emptyState(palette)
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _notificationTile(palette, _notifications[i]),
                ),
    );
  }

  Widget _emptyState(AppPalette palette) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: palette.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.notifications_none_rounded, color: palette.textMuted, size: 28),
          ),
          const SizedBox(height: 14),
          Text('home.no_new_notifications'.tr(), style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _notificationTile(AppPalette palette, AppNotification n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: palette.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.campaign_outlined, color: palette.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                    if (n.isNew)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsetsDirectional.only(start: 6),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(n.body, style: TextStyle(color: palette.textSecondary, fontSize: 13, height: 1.5)),
                const SizedBox(height: 8),
                Text(_formatDate(n.createdAt), style: TextStyle(color: palette.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A plain numeric date — intl's DateFormat locale data doesn't recognize
/// 'ku' (Kurdish isn't an ICU locale), so a locale-aware formatter throws
/// here even though easy_localization otherwise handles 'ku' fine for
/// regular .tr() strings.
String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}
