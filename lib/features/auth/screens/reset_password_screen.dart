import 'dart:async';
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
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/shikodar_mark.dart';
import '../../home/screens/favorites_screen.dart';
import '../widgets/auth_components.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFieldKey = GlobalKey();
  final _confirmFieldKey = GlobalKey();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;
  bool _codeVerified = false;
  bool _verifyingCode = false;

  // The box-by-box reveal after a verify response comes back: _waveIndex
  // boxes (0-6) have already picked up _waveResult's color, one at a time,
  // before the big result icon shows.
  int _waveIndex = -1;
  bool? _waveResult;
  bool _showResultIcon = false;

  static const _otpValiditySeconds = 300; // 5 minutes, matches the email's own stated validity.
  int _secondsRemaining = _otpValiditySeconds;
  Timer? _countdownTimer;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = _otpValiditySeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  /// A single typed digit just advances focus, same as before. Anything
  /// longer — a long-press paste of the full 6-digit code copied straight
  /// out of the email — gets spread across this box and the ones after it
  /// instead of being silently truncated to one character. Either way, once
  /// all 6 boxes are filled the code is checked automatically.
  void _handleCodeChanged(int index, String value) {
    if (value.length <= 1) {
      if (value.isNotEmpty && index < 5) _codeNodes[index + 1].requestFocus();
      _maybeAutoVerify();
      return;
    }
    // Deferred to the next frame: writing to this box's own controller
    // synchronously, from inside its own onChanged, races the platform text
    // input finishing its own update to that same controller — the paste
    // could otherwise get silently overwritten right back to a single
    // character a moment later.
    final pasted = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var i = 0; i < pasted.length && index + i < 6; i++) {
        _codeControllers[index + i].text = pasted[i];
      }
      final lastFilled = (index + pasted.length - 1).clamp(0, 5);
      if (lastFilled < 5) {
        _codeNodes[lastFilled + 1].requestFocus();
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _maybeAutoVerify();
    });
  }

  void _maybeAutoVerify() {
    if (_codeVerified || _verifyingCode) return;
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length == 6) _verifyCode(code);
  }

  void _clearCode() {
    for (final controller in _codeControllers) {
      controller.clear();
    }
    _codeNodes.first.requestFocus();
  }

  /// Confirms the code on its own, before the new-password fields ever
  /// appear — a wrong code here just clears the boxes for another try,
  /// without the visitor having to fill in a password first only to be
  /// told afterward that the code they typed was wrong. The result plays
  /// out as a box-by-box wave (green for right, red for wrong) followed by
  /// a big result icon, before moving on.
  Future<void> _verifyCode(String code) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _verifyingCode = true);
    bool success;
    String? errorMessage;
    try {
      await context.read<AuthRepository>().verifyResetCode(email: widget.email, code: code);
      success = true;
    } on ApiException catch (e) {
      success = false;
      errorMessage = e.message;
    }
    if (!mounted) return;
    setState(() => _verifyingCode = false);
    await _playResultWave(success);
    if (!mounted) return;
    if (success) {
      _countdownTimer?.cancel();
      setState(() => _codeVerified = true);
    } else {
      if (errorMessage != null) showAppSnackBar(context, message: errorMessage, isError: true);
      _clearCode();
    }
  }

  Future<void> _playResultWave(bool success) async {
    setState(() {
      _waveResult = success;
      _waveIndex = 0;
    });
    for (var i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() => _waveIndex = i + 1);
    }
    await Future.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    setState(() => _showResultIcon = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _showResultIcon = false;
      _waveIndex = -1;
      _waveResult = null;
    });
  }

  /// resizeToAvoidBottomInset is false on this screen (needed to keep the
  /// decorative background circle from tearing during resize), so nothing
  /// automatically scrolls a newly-focused field above the keyboard once it
  /// finishes animating in. Flutter's own focus->scroll behavior fires once,
  /// right as focus changes — before the keyboard has actually grown to its
  /// final height — so it undershoots. Re-run it after a short delay, once
  /// the keyboard (and the ScrollView's matching bottom padding) has caught up.
  void _scrollFieldIntoView(GlobalKey key) {
    Future.delayed(const Duration(milliseconds: 260), () {
      final fieldContext = key.currentContext;
      if (!mounted || fieldContext == null) return;
      Scrollable.ensureVisible(
        fieldContext,
        alignment: 0.15,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String get _formattedCountdown {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      await context.read<AuthRepository>().forgotPassword(email: widget.email);
      if (!mounted) return;
      showAppSnackBar(context, message: 'auth.otp_resent'.tr());
      _startCountdown();
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

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
    _countdownTimer?.cancel();
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
    if (!_codeVerified) {
      showAppSnackBar(context, message: 'auth.otp_incomplete'.tr(), isError: true);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await context.read<AuthRepository>().resetPassword(
            email: widget.email,
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

      await _showSuccessCelebration();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// A brief, dedicated celebration instead of the same generic snackbar
  /// used for every other success message in the app — this one moment
  /// (account recovered) earns something more deliberate. Dismisses itself
  /// and hands control back once its own beat has played out.
  Future<void> _showSuccessCelebration() async {
    if (!mounted) return;
    final palette = context.palette;
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'success',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, _, __) {
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
        });
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 44),
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: palette.shadow.withOpacity(0.45), blurRadius: 34, offset: const Offset(0, 18)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.emeraldLight, AppColors.emerald, AppColors.emeraldDark],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                ).animate().scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1), duration: 480.ms, curve: Curves.elasticOut).fadeIn(duration: 200.ms),
                const SizedBox(height: 22),
                Text(
                  'auth.reset_password_success'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                ).entrance(index: 1),
                const SizedBox(height: 8),
                Text(
                  'auth.reset_password_success_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary, fontSize: 12.5, height: 1.5),
                ).entrance(index: 2),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Collapse the logo/title block out of the way while the keyboard is
    // up — otherwise (with resizeToAvoidBottomInset false, so the Scaffold
    // itself never shrinks) it permanently eats the top of the screen and
    // the password field ends up hidden under the keyboard, same fix as
    // LoginScreen's header collapse.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      height: keyboardOpen ? 0 : 190,
                      child: ClipRect(
                        child: OverflowBox(
                          maxHeight: 190,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: 190,
                            child: Column(
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
                                  widget.email,
                                  textAlign: TextAlign.center,
                                  textDirection: ui.TextDirection.ltr,
                                  style: TextStyle(
                                    color: palette.primary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ).entrance(index: 2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
                                isLast: index == 5,
                                status: _codeVerified
                                    ? _BoxStatus.success
                                    : (index < _waveIndex && _waveResult != null)
                                        ? (_waveResult! ? _BoxStatus.success : _BoxStatus.error)
                                        : _BoxStatus.none,
                                locked: _codeVerified || _waveIndex >= 0 || _verifyingCode,
                                onChanged: (value) => _handleCodeChanged(index, value),
                              ).entrance(index: index, delay: 40.ms, base: 260.ms),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: _showResultIcon
                          ? Icon(
                              _waveResult == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              key: ValueKey(_waveResult),
                              size: 46,
                              color: _waveResult == true ? AppColors.success : palette.error,
                            )
                              .animate()
                              .scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1), duration: 340.ms, curve: Curves.elasticOut)
                              .fadeIn(duration: 160.ms)
                          : _codeVerified
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  'auth.otp_verified'.tr(),
                                  style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            )
                          : _verifyingCode
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
                                )
                              : _secondsRemaining > 0
                                  ? Text(
                                      'auth.otp_expires_in'.tr(args: [_formattedCountdown]),
                                      style: TextStyle(color: palette.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
                                    )
                                  : _isResending
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
                                        )
                                      : GestureDetector(
                                          onTap: _resendCode,
                                          child: Text(
                                            'auth.resend_code'.tr(),
                                            style: TextStyle(color: palette.primary, fontSize: 12.5, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                    ).entrance(index: 3),
                    // The new-password fields only exist once the code above
                    // is confirmed — there's nothing to submit before that,
                    // and it keeps the visitor from filling in a password
                    // only to be told afterward that the code was wrong.
                    if (_codeVerified) ...[
                      const SizedBox(height: 26),
                      Focus(
                        onFocusChange: (hasFocus) {
                          if (hasFocus) _scrollFieldIntoView(_passwordFieldKey);
                        },
                        child: KeyedSubtree(
                          key: _passwordFieldKey,
                          child: AuthTextFormField(
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
                          ),
                        ),
                      ).animate().fadeIn(duration: 320.ms, curve: AppMotion.enter).slideY(begin: 0.08, end: 0, duration: 320.ms, curve: AppMotion.enter),
                      const SizedBox(height: 13),
                      Focus(
                        onFocusChange: (hasFocus) {
                          if (hasFocus) _scrollFieldIntoView(_confirmFieldKey);
                        },
                        child: KeyedSubtree(
                          key: _confirmFieldKey,
                          child: AuthTextFormField(
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
                          ),
                        ),
                      ).animate(delay: 60.ms).fadeIn(duration: 320.ms, curve: AppMotion.enter).slideY(begin: 0.08, end: 0, duration: 320.ms, curve: AppMotion.enter),
                      const SizedBox(height: 26),
                      AuthPrimaryButton(
                        label: 'auth.reset_password_button'.tr(),
                        icon: Icons.verified_rounded,
                        onPressed: _submit,
                        loading: _isSubmitting,
                      ).animate(delay: 120.ms).fadeIn(duration: 320.ms, curve: AppMotion.enter).slideY(begin: 0.08, end: 0, duration: 320.ms, curve: AppMotion.enter),
                    ],
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

enum _BoxStatus { none, success, error }

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.width,
    required this.controller,
    required this.node,
    required this.isLast,
    required this.status,
    required this.locked,
    required this.onChanged,
  });

  final double width;
  final TextEditingController controller;
  final FocusNode node;
  final bool isLast;
  final _BoxStatus status;
  final bool locked;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final statusColor = switch (status) {
      _BoxStatus.success => AppColors.success,
      _BoxStatus.error => palette.error,
      _BoxStatus.none => null,
    };
    // A single 0-1 progress value drives every color lerp below — always
    // between two concrete (never-null) colors, so easing back to "no
    // status" lands cleanly on the normal palette colors instead of fading
    // toward transparent (which a null tween target would do, leaving the
    // digits nearly invisible on a retry).
    return SizedBox(
      width: width,
      height: 58,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: statusColor != null ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        builder: (context, t, child) {
          final activeColor = statusColor ?? palette.textPrimary;
          final borderColor = Color.lerp(palette.divider, activeColor, t)!;
          final fillColor = Color.lerp(palette.surface, activeColor.withOpacity(0.08), t)!;
          final textColor = Color.lerp(palette.textPrimary, activeColor, t)!;
          return AnimatedScale(
            scale: 1.0 + 0.06 * t,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: TextField(
              controller: controller,
              focusNode: node,
              // Locked once verified (or mid-result-wave/mid-check) — nothing
              // left to correct at that point.
              readOnly: locked,
              showCursor: !locked,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
              // No maxLength here — a long-press paste of the full 6-digit
              // code lands in whichever box is focused, and onChanged (wired
              // to the parent's _handleCodeChanged) spreads it across the
              // remaining boxes instead of a hard 1-char cap discarding it.
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: fillColor,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: borderColor, width: 1 + (0.5 * t)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: t > 0 ? borderColor : palette.primary, width: 1.5),
                ),
              ),
              onChanged: onChanged,
            ),
          );
        },
      ),
    );
  }
}
