import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/session/business_profile_store.dart';
import '../../../core/session/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/shikodar_mark.dart';
import '../widgets/auth_components.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone, this.role = AccountRole.client, this.parentCompanyName});

  final String phone;
  final AccountRole role;

  /// Only meaningful when [role] is `complex` — the company that created
  /// this residential complex, if the owner said one exists at registration.
  final String? parentCompanyName;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verify() {
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _controllers.map((controller) => controller.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.otp_incomplete'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<UserSession>().logIn(widget.role);
    if (widget.role == AccountRole.complex) {
      context.read<BusinessProfileStore>().setParentCompany(widget.parentCompanyName);
    }
    // Registration is pushed from the profile tab's guest prompt, on top of
    // the guest HomeShell already showing — pop back to it (now reactively
    // logged in) instead of tearing down the stack and building a new one.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
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
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: ShikodarMark(size: 72, showShadow: false))
                      .animate()
                      .fadeIn(duration: 380.ms, curve: AppMotion.enter)
                      .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), curve: AppMotion.emphasized),
                  const SizedBox(height: 24),
                  Text(
                    'auth.verify_title'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ).entrance(index: 1),
                  const SizedBox(height: 10),
                  Text(
                    'auth.otp_sent'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ).entrance(index: 2),
                  const SizedBox(height: 34),
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boxWidth = ((constraints.maxWidth - 40) / 6)
                            .clamp(38.0, 52.0)
                            .toDouble();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (index) => _OtpBox(
                              width: boxWidth,
                              controller: _controllers[index],
                              node: _nodes[index],
                              nextNode: index < 5 ? _nodes[index + 1] : null,
                              onComplete: index == 5 ? _verify : null,
                            ).entrance(index: index, delay: 40.ms, base: 260.ms),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 34),
                  AuthPrimaryButton(
                    label: 'auth.verify'.tr(),
                    icon: Icons.verified_rounded,
                    onPressed: _verify,
                  ).entrance(base: 480.ms),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.surfaceElevated,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: palette.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, color: palette.gold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'auth.otp_security_note'.tr(),
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).entrance(base: 540.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.width,
    required this.controller,
    required this.node,
    this.nextNode,
    this.onComplete,
  });

  final double width;
  final TextEditingController controller;
  final FocusNode node;
  final FocusNode? nextNode;
  final VoidCallback? onComplete;

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
        textInputAction:
            nextNode == null ? TextInputAction.done : TextInputAction.next,
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
          if (value.isNotEmpty) {
            if (nextNode != null) {
              nextNode!.requestFocus();
            } else {
              onComplete?.call();
            }
          }
        },
      ),
    );
  }
}
