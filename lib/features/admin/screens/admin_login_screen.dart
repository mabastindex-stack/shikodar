import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_home_shell.dart';

/// Separate, low-visibility login for administrators only. Admin accounts
/// are never created through public sign-up — only reachable from here.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18), onPressed: () => Navigator.pop(context)),
              const SizedBox(height: 40),
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.ink, size: 32),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
              const SizedBox(height: 20),
              Text('admin.dashboard_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 320.ms),
              const SizedBox(height: 6),
              Text('admin.login_subtitle'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 12.5))
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 320.ms),
              const SizedBox(height: 32),
              _field(_phoneController, Icons.badge_outlined, 'admin.login_identifier_hint'.tr(), 220),
              const SizedBox(height: 14),
              _field(_passwordController, Icons.lock_outline, 'auth.password'.tr(), 260, obscure: true),
              const SizedBox(height: 28),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    if (_phoneController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('auth.field_required'.tr()), behavior: SnackBarBehavior.floating),
                      );
                      return;
                    }
                    context.read<UserSession>().setRole(AccountRole.admin);
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AdminHomeShell()),
                      (route) => false,
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: Text('auth.login'.tr(), style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 320.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, IconData icon, String hint, int delay, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure && _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: obscure
            ? IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white54), onPressed: () => setState(() => _obscure = !_obscure))
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 320.ms).slideX(begin: 0.06, end: 0);
  }
}
