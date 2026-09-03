import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/photo_backdrop.dart';
import '../widgets/auth_components.dart';
import 'otp_screen.dart';

const _bgPhotos = <String>[
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=80',
  'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=1200&q=80',
  'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=80',
];

const _kirkukZones = <String>[
  'شۆڕجە',
  'ڕاپەرین',
  'ناوەڕاستی شار',
  'ئیمام قاسم',
  'ئازادی',
  'گرناتە',
  'ڕاهیمناوە',
  'شەقامی ٦٠ مەتری',
];

/// Kirkuk zone names are stored/compared as raw Kurdish (matches the shared
/// mock data in `core/mock/kirkuk_neighborhoods.dart`), so only the
/// _displayed_ label is localized here — the underlying value never changes.
String _kirkukZoneLabel(String zone) {
  switch (zone) {
    case 'شۆڕجە':
      return 'zones.shorja'.tr();
    case 'ڕاپەرین':
      return 'zones.raparin'.tr();
    case 'ناوەڕاستی شار':
      return 'zones.city_center'.tr();
    case 'ئیمام قاسم':
      return 'zones.imam_qasim'.tr();
    case 'ئازادی':
      return 'zones.azadi'.tr();
    case 'گرناتە':
      return 'zones.granata'.tr();
    case 'ڕاهیمناوە':
      return 'edit_business_profile.zone_raihimawa'.tr();
    case 'شەقامی ٦٠ مەتری':
      return 'zones.sixty_meter_street'.tr();
    default:
      return zone;
  }
}

/// Client self-registration only — agency/company/complex accounts are
/// always admin-created (see `CreateAgencyContractScreen`), so this screen
/// never needs to branch on account role.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  File? _profileImage;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _agreedToTerms = false;
  bool _showZoneError = false;
  double _strength = 0;
  String? _selectedZone;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updateStrength);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _updateStrength() {
    final password = _passwordController.text;
    double value = 0;
    if (password.length >= 6) value += 0.34;
    if (password.length >= 9) value += 0.22;
    if (RegExp(r'[0-9]').hasMatch(password)) value += 0.22;
    if (RegExp(r'[A-Z]').hasMatch(password) ||
        RegExp(r'[!@#\$%^&*]').hasMatch(password)) {
      value += 0.22;
    }
    if (mounted) setState(() => _strength = value.clamp(0.0, 1.0).toDouble());
  }

  Color get _strengthColor {
    if (_strength < 0.4) return AppColors.error;
    if (_strength < 0.75) return AppColors.gold;
    return AppColors.success;
  }

  String get _strengthLabel {
    if (_strength == 0) return '';
    if (_strength < 0.4) return 'auth.strength_weak'.tr();
    if (_strength < 0.75) return 'auth.strength_medium'.tr();
    return 'auth.strength_strong'.tr();
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

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!email.hasMatch(value.trim())) return 'auth.email_invalid'.tr();
    return null;
  }

  String? _validatePassword(String? value) {
    final requiredMessage = _required(value);
    if (requiredMessage != null) return requiredMessage;
    if (value!.length < 6) return 'auth.password_short'.tr();
    return null;
  }

  String? _validateConfirmation(String? value) {
    final requiredMessage = _required(value);
    if (requiredMessage != null) return requiredMessage;
    if (value != _passwordController.text) return 'auth.password_mismatch'.tr();
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null && mounted) setState(() => _profileImage = File(picked.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.image_error'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickZone() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ZonePickerSheet(zones: _kirkukZones, selected: _selectedZone),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedZone = result;
        _showZoneError = false;
      });
    }
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    final zoneValid = _selectedZone != null;

    setState(() => _showZoneError = !zoneValid);

    if (!fieldsValid || !zoneValid) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.accept_terms'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: AppMotion.expressive,
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
          child: OtpScreen(phone: _phoneController.text.trim()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: AppColors.emeraldDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PhotoBackdrop(photos: _bgPhotos),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF061D19).withOpacity(0.78),
                    const Color(0xFF083B34).withOpacity(0.54),
                    const Color(0xFF0C1210).withOpacity(0.25),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _RegisterHeader(),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: palette.background.withOpacity(0.97),
                          border: Border(
                            top: BorderSide(color: Colors.white.withOpacity(0.22)),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              24,
                              25,
                              24,
                              24 + MediaQuery.paddingOf(context).bottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ProfilePhoto(
                                  image: _profileImage,
                                  onTap: _pickImage,
                                ),
                                const SizedBox(height: 23),
                                AuthSectionLabel(label: 'auth.personal_info'.tr()),
                                AuthTextFormField(
                                  controller: _nameController,
                                  label: 'auth.full_name'.tr(),
                                  icon: Icons.person_outline_rounded,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  validator: _required,
                                ),
                                const SizedBox(height: 13),
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
                                  controller: _emailController,
                                  label: 'auth.optional_email'.tr(),
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 13),
                                _ZoneSelector(
                                  selectedZone: _selectedZone,
                                  hasError: _showZoneError,
                                  onTap: _pickZone,
                                ),
                                const SizedBox(height: 24),
                                AuthSectionLabel(label: 'auth.password_section'.tr()),
                                AuthTextFormField(
                                  controller: _passwordController,
                                  label: 'auth.password'.tr(),
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.newPassword],
                                  validator: _validatePassword,
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: palette.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _PasswordStrength(
                                  value: _strength,
                                  color: _strengthColor,
                                  label: _strengthLabel,
                                ),
                                const SizedBox(height: 13),
                                AuthTextFormField(
                                  controller: _confirmController,
                                  label: 'auth.confirm_password'.tr(),
                                  icon: Icons.lock_reset_rounded,
                                  obscureText: _obscureConfirmation,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.newPassword],
                                  validator: _validateConfirmation,
                                  onFieldSubmitted: (_) => _submit(),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureConfirmation = !_obscureConfirmation,
                                    ),
                                    icon: Icon(
                                      _obscureConfirmation
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: palette.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _TermsRow(
                                  checked: _agreedToTerms,
                                  onChanged: () => setState(
                                    () => _agreedToTerms = !_agreedToTerms,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                AuthPrimaryButton(
                                  label: 'auth.register'.tr(),
                                  icon: Icons.verified_user_outlined,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'auth.have_account'.tr(),
                                      style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'auth.login'.tr(),
                                        style: TextStyle(
                                          color: palette.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
        child: Row(
          children: [
            _HeaderButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'auth.register'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'auth.as_client'.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.auto_awesome_rounded, color: AppColors.goldLight, size: 22),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.image, required this.onTap});

  final File? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: palette.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.gold.withOpacity(0.65), width: 1.4),
                    image: image == null
                        ? null
                        : DecorationImage(image: FileImage(image!), fit: BoxFit.cover),
                  ),
                  child: image == null
                      ? Icon(Icons.person_outline_rounded, color: palette.textMuted, size: 34)
                      : null,
                ),
                PositionedDirectional(
                  bottom: -2,
                  end: -2,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.background, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'auth.profile_photo_optional'.tr(),
            style: TextStyle(color: palette.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _ZoneSelector extends StatelessWidget {
  const _ZoneSelector({required this.selectedZone, required this.hasError, required this.onTap});

  final String? selectedZone;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: hasError ? palette.error : palette.divider.withOpacity(0.75),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: palette.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedZone == null ? 'auth.location'.tr() : _kirkukZoneLabel(selectedZone!),
                    style: TextStyle(
                      color: selectedZone == null ? palette.textSecondary : palette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: palette.textSecondary),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 13, top: 6),
            child: Text(
              'auth.field_required'.tr(),
              style: TextStyle(color: palette.error, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.value, required this.color, required this.label});

  final double value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: palette.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 9),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.checked, required this.onChanged});

  final bool checked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.quick,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? palette.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: checked ? palette.primary : palette.divider,
                  width: 1.4,
                ),
              ),
              child: checked ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'auth.terms'.tr(),
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonePickerSheet extends StatelessWidget {
  const _ZonePickerSheet({required this.zones, required this.selected});

  final List<String> zones;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: palette.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: palette.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'auth.location'.tr(),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: zones.map((zone) {
                final isSelected = zone == selected;
                return InkWell(
                  onTap: () => Navigator.pop(context, zone),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? palette.primary : palette.surfaceElevated,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: isSelected ? palette.primary : palette.divider,
                      ),
                    ),
                    child: Text(
                      _kirkukZoneLabel(zone),
                      style: TextStyle(
                        color: isSelected ? Colors.white : palette.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
