import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/session/user_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/photo_backdrop.dart';
import '../../../shared/widgets/shikodar_mark.dart';
import '../../admin/screens/admin_login_screen.dart';
import '../widgets/auth_components.dart';
import 'register_screen.dart';
import 'server_settings_screen.dart';

const _bgPhotos = <String>[
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80',
  'https://images.unsplash.com/photo-1613977257363-707ba9348227?w=1200&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=80',
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  AccountRole _selectedRole = AccountRole.client;
  bool _obscure = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'auth.field_required'.tr();
    return null;
  }

  String? _validatePhone(String? value) {
    final requiredMessage = _required(value);
    if (requiredMessage != null) return requiredMessage;
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'auth.phone_invalid'.tr();
    return null;
  }

  String? _validatePassword(String? value) {
    final requiredMessage = _required(value);
    if (requiredMessage != null) return requiredMessage;
    if (value!.length < 6) return 'auth.password_short'.tr();
    return null;
  }

  void _submit() {
    // No backend yet — skip field validation entirely so the demo flow is
    // never blocked by an empty phone/password. Re-enable the validate()
    // gate once real authentication is wired up.
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<UserSession>().logIn(_selectedRole);
    // Reached by pushing from the profile tab's guest prompt, on top of the
    // guest HomeShell already showing — pop back to it (now reactively
    // showing the logged-in profile) instead of building a whole new one.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showForgotPasswordInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('auth.forgot_unavailable'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = (screenHeight * 0.39).clamp(260.0, 340.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.emeraldDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PhotoBackdrop(photos: _bgPhotos),
          const _PhotoOverlay(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  SizedBox(
                    height: headerHeight,
                    child: const _LoginBrandHeader(),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: screenHeight - headerHeight + 24,
                        ),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          28,
                          24,
                          20 + MediaQuery.paddingOf(context).bottom,
                        ),
                        decoration: BoxDecoration(
                          color: palette.background.withOpacity(0.97),
                          border: Border(
                            top: BorderSide(color: Colors.white.withOpacity(0.22)),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'auth.welcome_back'.tr(),
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'auth.login_subtitle'.tr(),
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _RoleSelector(
                                selected: _selectedRole,
                                onChanged: (value) => setState(() => _selectedRole = value),
                              ),
                              const SizedBox(height: 18),
                              AuthTextFormField(
                                controller: _phoneController,
                                label: 'auth.phone'.tr(),
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.telephoneNumber],
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: 13),
                              AuthTextFormField(
                                controller: _passwordController,
                                label: 'auth.password'.tr(),
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                validator: _validatePassword,
                                onFieldSubmitted: (_) => _submit(),
                                suffixIcon: IconButton(
                                  tooltip: _obscure ? 'Show password' : 'Hide password',
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: palette.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: _showForgotPasswordInfo,
                                  child: Text(
                                    'auth.forgot_password'.tr(),
                                    style: TextStyle(
                                      color: palette.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              AuthPrimaryButton(
                                label: 'auth.login'.tr(),
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 17),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'auth.no_account'.tr(),
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  TextButton(
                                    // Self-registration is client-only from
                                    // here on — agency/company/complex
                                    // accounts are created by the admin (see
                                    // CreateAgencyContractScreen), so this
                                    // link ignores whatever role is selected
                                    // above (that selector is for signing
                                    // in to an existing account of any role).
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    ),
                                    child: Text(
                                      'auth.register'.tr(),
                                      style: TextStyle(
                                        color: palette.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Center(
                                child: Text(
                                  'auth.business_signup_note'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: palette.textMuted, fontSize: 10.5),
                                ),
                              ),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AdminLoginScreen(),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.admin_panel_settings_outlined,
                                    size: 15,
                                    color: palette.textMuted,
                                  ),
                                  label: Text(
                                    'auth.admin_login'.tr(),
                                    style: TextStyle(
                                      color: palette.textMuted,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: MediaQuery.paddingOf(context).top + 10,
            end: 14,
            child: _GlassIconButton(
              icon: Icons.tune_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
              ),
            ),
          ),
          // Only shown when there's actually somewhere to go back to — this
          // screen is reached by pushing from the profile tab's guest
          // prompt now, not as the app's unskippable root anymore.
          if (Navigator.of(context).canPop())
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + 10,
              start: 14,
              child: _GlassIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoOverlay extends StatelessWidget {
  const _PhotoOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF061D19).withOpacity(0.74),
            const Color(0xFF083B34).withOpacity(0.50),
            const Color(0xFF0C1210).withOpacity(0.22),
          ],
          stops: const [0, 0.62, 1],
        ),
      ),
    );
  }
}

class _LoginBrandHeader extends StatelessWidget {
  const _LoginBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ShikodarMark(size: 76, showShadow: true),
          const SizedBox(height: 16),
          Text(
            'app_name'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'onboarding.tagline'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.goldLight, size: 15),
                const SizedBox(width: 7),
                Text(
                  'auth.trust_note'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.selected, required this.onChanged});

  final AccountRole selected;
  final ValueChanged<AccountRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.divider.withOpacity(0.7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _RoleOption(
                  label: 'auth.as_client'.tr(),
                  icon: Icons.person_outline_rounded,
                  selected: selected == AccountRole.client,
                  onTap: () => onChanged(AccountRole.client),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _RoleOption(
                  label: 'auth.as_agency'.tr(),
                  icon: Icons.storefront_outlined,
                  selected: selected == AccountRole.agency,
                  onTap: () => onChanged(AccountRole.agency),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _RoleOption(
                  label: 'auth.as_company'.tr(),
                  icon: Icons.apartment_rounded,
                  selected: selected == AccountRole.company,
                  onTap: () => onChanged(AccountRole.company),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _RoleOption(
                  label: 'auth.as_complex'.tr(),
                  icon: Icons.location_city_rounded,
                  selected: selected == AccountRole.complex,
                  onTap: () => onChanged(AccountRole.complex),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.enter,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? palette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.shadow.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : palette.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : palette.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
