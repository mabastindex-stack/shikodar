import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/shikodar_mark.dart';
import '../widgets/auth_components.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'auth.field_required'.tr();
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'auth.phone_invalid'.tr();
    return null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      final devOtpCode = await context.read<AuthRepository>().forgotPassword(phone: phone);
      if (!mounted) return;
      if (devOtpCode != null) {
        showAppSnackBar(context, message: 'OTP: $devOtpCode');
      }
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: AppMotion.expressive,
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
            child: ResetPasswordScreen(phone: phone),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -130,
            right: -110,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withOpacity(0.07),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                18,
                24,
                28 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: ShikodarMark(size: 72, showShadow: false))
                        .animate()
                        .fadeIn(duration: 380.ms, curve: AppMotion.enter)
                        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), curve: AppMotion.emphasized),
                    const SizedBox(height: 24),
                    Text(
                      'auth.forgot_password_title'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ).entrance(index: 1),
                    const SizedBox(height: 10),
                    Text(
                      'auth.forgot_password_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ).entrance(index: 2),
                    const SizedBox(height: 30),
                    AuthTextFormField(
                      controller: _phoneController,
                      label: 'auth.phone'.tr(),
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      validator: _validatePhone,
                      onFieldSubmitted: (_) => _submit(),
                    ).entrance(index: 3),
                    const SizedBox(height: 26),
                    AuthPrimaryButton(
                      label: 'auth.send_code'.tr(),
                      icon: Icons.sms_outlined,
                      onPressed: _submit,
                      loading: _isSubmitting,
                    ).entrance(base: 420.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
