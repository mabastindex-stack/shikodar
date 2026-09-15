import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_repository.dart';
import '../../../core/network/favorite_repository.dart';
import '../../../core/network/push_repository.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/shikodar_mark.dart';
import '../../home/screens/favorites_screen.dart';
import '../widgets/auth_components.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.phone});

  final String phone;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _codeNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'auth.field_required'.tr();
    if (value.length < 8) return 'auth.password_short'.tr();
    return null;
  }

  String? _validateConfirmation(String? value) {
    final requiredMessage = _validatePassword(value);
    if (requiredMessage != null) return requiredMessage;
    if (value != _passwordController.text) return 'auth.password_mismatch'.tr();
    return null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _codeControllers.map((controller) => controller.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.otp_incomplete'.tr()), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await context.read<AuthRepository>().resetPassword(
            phone: widget.phone,
            code: code,
            newPassword: _passwordController.text,
          );
      if (!mounted) return;

      context.read<UserSession>().logIn(
            result.role,
            name: result.name,
            agencyId: result.agencyId,
            tier: result.tier,
            contractEndDate: result.contractEndDate,
            logoUrl: result.logoUrl,
            agencyPhone: result.agencyPhone,
            agencyWhatsapp: result.agencyWhatsapp,
            agencyCoverUrl: result.agencyCoverUrl,
            rating: result.rating,
            reviewCount: result.reviewCount,
            yearsActive: result.yearsActive,
            dealsCompleted: result.dealsCompleted,
            profilePhotoUrl: result.profilePhotoUrl,
            coverUrl: result.coverUrl,
          );
      FavoritesStore.loadFromServer(context.read<FavoriteRepository>());
      context.read<PushRepository>().registerDevice();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.reset_password_success'.tr()), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
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
                    const Center(child: ShikodarMark(size: 64, showShadow: false))
                        .animate()
                        .fadeIn(duration: 380.ms, curve: AppMotion.enter)
                        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), curve: AppMotion.emphasized),
                    const SizedBox(height: 20),
                    Text(
                      'auth.reset_password_title'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ).entrance(index: 1),
                    const SizedBox(height: 8),
                    Text(
                      'auth.reset_password_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ).entrance(index: 2),
                    const SizedBox(height: 7),
                    Text(
                      widget.phone,
                      textAlign: TextAlign.center,
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ).entrance(index: 2),
                    const SizedBox(height: 26),
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final boxWidth = ((constraints.maxWidth - 40) / 6).clamp(38.0, 52.0).toDouble();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) => _CodeBox(
                                width: boxWidth,
                                controller: _codeControllers[index],
                                node: _codeNodes[index],
                                nextNode: index < 5 ? _codeNodes[index + 1] : null,
                              ).entrance(index: index, delay: 40.ms, base: 260.ms),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 26),
                    AuthTextFormField(
                      controller: _passwordController,
                      label: 'auth.new_password'.tr(),
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: _validatePassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: palette.textSecondary,
                          size: 20,
                        ),
                      ),
                    ).entrance(base: 500.ms),
                    const SizedBox(height: 13),
                    AuthTextFormField(
                      controller: _confirmController,
                      label: 'auth.confirm_new_password'.tr(),
                      icon: Icons.lock_reset_rounded,
                      obscureText: _obscureConfirmation,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: _validateConfirmation,
                      onFieldSubmitted: (_) => _submit(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscureConfirmation = !_obscureConfirmation),
                        icon: Icon(
                          _obscureConfirmation ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: palette.textSecondary,
                          size: 20,
                        ),
                      ),
                    ).entrance(base: 560.ms),
                    const SizedBox(height: 26),
                    AuthPrimaryButton(
                      label: 'auth.reset_password_button'.tr(),
                      icon: Icons.verified_rounded,
                      onPressed: _submit,
                      loading: _isSubmitting,
                    ).entrance(base: 620.ms),
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

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.width, required this.controller, required this.node, this.nextNode});

  final double width;
  final TextEditingController controller;
  final FocusNode node;
  final FocusNode? nextNode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: width,
      height: 58,
      child: TextField(
        controller: controller,
        focusNode: node,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: nextNode == null ? TextInputAction.done : TextInputAction.next,
        maxLength: 1,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: palette.surface,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: palette.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: palette.primary, width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && nextNode != null) nextNode!.requestFocus();
        },
      ),
    );
  }
}
