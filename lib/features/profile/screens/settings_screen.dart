import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/screens/server_settings_screen.dart';
import '../../feedback/screens/feedback_screen.dart';

/// Everything that used to live at the bottom of the profile page — language,
/// appearance, server config, feedback, logout — now lives one tap away
/// behind the gear icon, so the profile itself can read like a clean social
/// profile instead of a settings list.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        title: Text('profile.settings'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _sectionCard(palette, delay: 0, children: [
            _langTile(context, palette),
            SwitchListTile(
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggle(),
              activeColor: palette.textPrimary,
              title: Text('profile.dark_mode'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 14)),
              secondary: Icon(Icons.dark_mode_outlined, color: palette.textSecondary),
            ),
            _tile(palette, Icons.settings_outlined, 'profile.server_settings'.tr(),
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServerSettingsScreen())),
                isLast: true),
          ]),
          const SizedBox(height: 16),
          _sectionCard(palette, delay: 60, children: [
            _tile(palette, Icons.feedback_outlined, 'profile.feedback'.tr(), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackScreen()))),
            _tile(palette, Icons.logout, 'profile.logout'.tr(), () => _confirmLogout(context, palette), color: palette.error, isLast: true),
          ]),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppPalette palette) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('settings_page.logout_dialog_title'.tr(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('settings_page.logout_dialog_message'.tr(), style: TextStyle(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('common.cancel'.tr(), style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () {
              context.read<UserSession>().logOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('settings_page.logout_dialog_title'.tr(), style: TextStyle(color: palette.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(AppPalette palette, {required List<Widget> children, int delay = 0}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: palette.shadow.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    ).animate(delay: delay.ms).fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _tile(AppPalette palette, IconData icon, String label, VoidCallback onTap, {Color? color, bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color ?? palette.textSecondary),
          title: Text(label, style: TextStyle(color: color ?? palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          trailing: Icon(Icons.chevron_right, color: palette.textMuted, size: 18),
          onTap: onTap,
        ),
        if (!isLast) Divider(height: 1, indent: 56, color: palette.divider),
      ],
    );
  }

  Widget _langTile(BuildContext context, AppPalette palette) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.language, color: palette.textSecondary),
          title: Text('profile.language'.tr(), style: TextStyle(color: palette.textPrimary, fontSize: 14)),
          trailing: DropdownButton<Locale>(
            value: context.locale,
            underline: const SizedBox(),
            style: const TextStyle(color: AppColors.goldDark, fontSize: 13, fontWeight: FontWeight.w600),
            items: const [
              DropdownMenuItem(value: Locale('ku'), child: Text('کوردی')),
              DropdownMenuItem(value: Locale('ar'), child: Text('عربي')),
              DropdownMenuItem(value: Locale('en'), child: Text('English')),
              DropdownMenuItem(value: Locale('tk'), child: Text('تۆرکمانی')),
            ],
            onChanged: (locale) {
              if (locale != null) context.setLocale(locale);
            },
          ),
        ),
        Divider(height: 1, indent: 56, color: palette.divider),
      ],
    );
  }
}
