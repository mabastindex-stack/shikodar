import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_palette.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Status is kept as a stable, non-localized code ('open'/'answered') so
    // the equality check below stays correct across locale changes; the
    // display label is localized separately at render time.
    final tickets = const [
      ('ئارام حسێن', 'کێشەیەک لە بارکردنی وێنە هەم', 'open', 5),
      ('دەلال ئارام', 'پرسیار لەسەر پاکێجی Business', 'answered', 40),
      ('شنۆ ئازاد', 'داواکاری سڕینەوەی هەژمار', 'open', 120),
    ];
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        automaticallyImplyLeading: false,
        title: Text('admin.support_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final t = tickets[i];
          final isOpen = t.$3 == 'open';
          final statusLabel = isOpen ? 'admin.support_status_open'.tr() : 'admin.support_status_answered'.tr();
          final statusColor = isOpen ? palette.error : palette.success;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(Icons.support_agent_rounded, size: 19, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.$1, style: TextStyle(color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(t.$2, style: TextStyle(color: palette.textSecondary, fontSize: 11.5)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.13), borderRadius: BorderRadius.circular(20)),
                      child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 4),
                    Text('admin.support_minutes_ago'.tr(args: ['${t.$4}']), style: TextStyle(color: palette.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ).animate(delay: (60 * i).ms).fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);
        },
      ),
    );
  }
}
