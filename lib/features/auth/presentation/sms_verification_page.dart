import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/debug/provider_error_screen.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_routes.dart';
import 'phone_login_page.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../repositories/auth_repository.dart';
import '../../../shared/widgets/app_theme_picker_sheet.dart';

class SmsVerificationPage extends ConsumerStatefulWidget {
  const SmsVerificationPage({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  ConsumerState<SmsVerificationPage> createState() =>
      _SmsVerificationPageState();
}

class _SmsVerificationPageState extends ConsumerState<SmsVerificationPage>
    with TickerProviderStateMixin {
  static const _otpLength = 6;

  final _codeController = TextEditingController();
  final _otpFocusNode = FocusNode();

  late final AnimationController _enter;
  late final AnimationController _caret;
  late final Animation<double> _illustrationFade;
  late final Animation<double> _illustrationScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _otpFade;
  late final Animation<double> _buttonFade;

  bool _loading = false;
  bool _resendLoading = false;
  String? _errorKey;
  String? _otherError;

  int _resendSecondsLeft = 30;
  Ticker? _resendTicker;

  @override
  void initState() {
    super.initState();
    debugPrint('[otp] screen opened phone=${widget.phoneNumber}');
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _caret = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    _illustrationFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _illustrationScale = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.16, 0.62, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.16, 0.68, curve: Curves.easeOut),
      ),
    );
    _otpFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.34, 0.82, curve: Curves.easeOut),
    );
    _buttonFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.5, 0.95, curve: Curves.easeOut),
    );
    _enter.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });
    _resetOtpState();
    _startResendCountdown();
  }

  @override
  void didUpdateWidget(covariant SmsVerificationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneNumber != widget.phoneNumber) {
      _resetOtpState();
      _startResendCountdown();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _otpFocusNode.dispose();
    _resendTicker?.dispose();
    _enter.dispose();
    _caret.dispose();
    super.dispose();
  }

  String get _codeDigits => _codeController.text.replaceAll(RegExp(r'\D'), '');

  void _setCodeDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final next = digits.length > _otpLength ? digits.substring(0, _otpLength) : digits;
    if (next == _codeDigits) return;
    _codeController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  void _resetOtpState() {
    _setCodeDigits('');
    _errorKey = null;
    _otherError = null;
  }

  String _maskedUzPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final last9 = digits.length >= 9 ? digits.substring(digits.length - 9) : digits;
    if (last9.length < 9) {
      return '+998 ${'X' * last9.length}';
    }
    final a = last9.substring(0, 2);
    final b = last9.substring(2, 5);
    final c = last9.substring(5, 7);
    final d = last9.substring(7, 9);
    return '+998 $a $b $c $d';
  }

  String _expectedOtpFromPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < _otpLength) return '';
    return digits.substring(digits.length - _otpLength);
  }

  bool get _isComplete => _codeDigits.length == _otpLength;

  void _clearErrorIfAny() {
    if (_errorKey != null || _otherError != null) {
      setState(() {
        _errorKey = null;
        _otherError = null;
      });
    }
  }

  void _startResendCountdown() {
    _resendTicker?.dispose();
    setState(() => _resendSecondsLeft = 30);
    _resendTicker = createTicker((elapsed) {
      final left = 30 - elapsed.inSeconds;
      if (left <= 0) {
        _resendTicker?.stop();
        if (mounted) setState(() => _resendSecondsLeft = 0);
        return;
      }
      if (mounted && left != _resendSecondsLeft) {
        setState(() => _resendSecondsLeft = left);
      }
    })..start();
  }

  Future<void> _verify(AuthRepository repo, String phone) async {
    if (_loading) return;
    if (!_isComplete) return;

    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final expectedCode = cleanedPhone.length >= _otpLength
        ? cleanedPhone.substring(cleanedPhone.length - _otpLength)
        : cleanedPhone;
    if (expectedCode.isEmpty || _codeDigits != expectedCode) {
      setState(() {
        _errorKey = 'code';
        _otherError = null;
      });
      _setCodeDigits('');
      _otpFocusNode.requestFocus();
      return;
    }

    setState(() {
      _loading = true;
      _errorKey = null;
      _otherError = null;
    });
    try {
      final verifiedUser = await repo.verifySms(
        phone: phone,
        code: _codeController.text.trim(),
      );
      await ref.read(authSessionProvider.notifier).refresh();

      // OTP tasdiqlangandan keyin oferta shartnomasi ekranini ochamiz,
      // profil setup bosqichini skiplash mumkin emas.
      if (mounted) {
        final encodedPhone = Uri.encodeComponent(verifiedUser.phone);
        context.go('${AppRoutes.offer}?phone=$encodedPhone');
      }
    } on FormatException catch (e) {
      setState(() {
        if (e.message == 'invalid_code') {
          _errorKey = 'code';
          _otherError = null;
        } else if (e.message == 'invalid_phone') {
          _errorKey = 'phone';
          _otherError = null;
        } else {
          _errorKey = null;
          _otherError = e.toString();
        }
      });
      if (mounted && e.message == 'invalid_code') {
        _setCodeDigits('');
        _otpFocusNode.requestFocus();
      }
    } catch (e, st) {
      debugPrint('verifySms: $e\n$st');
      setState(() {
        _errorKey = null;
        _otherError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resend(AuthRepository repo, String phone) async {
    if (_resendLoading || _loading) return;
    if (_resendSecondsLeft > 0) return;
    setState(() {
      _resendLoading = true;
      _errorKey = null;
      _otherError = null;
    });
    try {
      await repo.submitPhone(phone);
      if (mounted) _startResendCountdown();
    } catch (e, st) {
      debugPrint('resendSms: $e\n$st');
      if (mounted) {
        setState(() {
          _errorKey = null;
          _otherError = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  void _handleBackNavigation() {
    _resetOtpState();
    debugPrint('[otp] back pressed -> go phone input (edit mode)');
    try {
      context.go('${AppRoutes.phone}?editPhone=1');
    } catch (_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const PhoneLoginPage(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[otp] build authStep=otp_verification phone=${widget.phoneNumber}');
    final l10n = AppLocalizations.of(context);
    final repoAsync = ref.watch(authRepositoryProvider);
    final resolvedPhone = widget.phoneNumber;
    final canSubmit = !_loading && _isComplete;
    final errorText = _otherError ??
        (_errorKey == 'code'
            ? "Kod noto'g'ri, qaytadan kiriting"
            : _errorKey == 'phone'
                ? l10n.errorInvalidPhone
                : null);

    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: l10n.createJobMenuChangeTheme,
                onPressed: () => showAppThemeBottomSheet(context),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isLight
                        ? const [Color(0xFFF7F6F2), Color(0xFFFBFAF7)]
                        : [scheme.surface, scheme.surfaceContainerHighest],
                  ),
                ),
                child: repoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(24),
              child: ProviderErrorScreen(
                error: error,
                stackTrace: stack,
                onRetry: () {
                  ref.invalidate(appDatabaseProvider);
                  ref.invalidate(sharedPreferencesProvider);
                  ref.invalidate(authRepositoryProvider);
                },
              ),
            ),
            data: (repo) {
              void onSubmit() => _verify(repo, resolvedPhone);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final contentMaxWidth =
                      constraints.maxWidth > 520 ? 420.0 : double.infinity;
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        child: Shortcuts(
                          shortcuts: const <ShortcutActivator, Intent>{
                            SingleActivator(LogicalKeyboardKey.enter):
                                ActivateIntent(),
                            SingleActivator(LogicalKeyboardKey.numpadEnter):
                                ActivateIntent(),
                          },
                          child: Actions(
                            actions: <Type, Action<Intent>>{
                              ActivateIntent: CallbackAction<ActivateIntent>(
                                onInvoke: (_) {
                                  if (_loading) return null;
                                  if (!canSubmit) return null;
                                  onSubmit();
                                  return null;
                                },
                              ),
                            },
                            child: Focus(
                              autofocus: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  FadeTransition(
                                    opacity: _illustrationFade,
                                    child: ScaleTransition(
                                      scale: _illustrationScale,
                                      child: _OtpHeroHeader(
                                        height: constraints.maxHeight < 680
                                            ? 252
                                            : 296,
                                        onBack: _handleBackNavigation,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FadeTransition(
                                    opacity: _titleFade,
                                    child: SlideTransition(
                                      position: _titleSlide,
                                      child: Column(
                                        children: [
                                          Text(
                                            'Tasdiqlash kodi',
                                            textAlign: TextAlign.center,
                                            style: _OtpPageStyles.titleStyle,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Telefoningizga yuborilgan kodni kiriting',
                                            textAlign: TextAlign.center,
                                            style: _OtpPageStyles.subtitleStyle,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Kod ${_maskedUzPhone(resolvedPhone)} raqamiga yuborildi',
                                            textAlign: TextAlign.center,
                                            style: _OtpPageStyles.phoneInfoStyle,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  FadeTransition(
                                    opacity: _otpFade,
                                    child: _OtpInputArea(
                                      controller: _codeController,
                                      focusNode: _otpFocusNode,
                                      enabled: !_loading,
                                      hasError: errorText != null,
                                      caretT: _caret,
                                      onChangedDigits: (digits) {
                                        _setCodeDigits(digits);
                                        _clearErrorIfAny();
                                        setState(() {});
                                        if (!_loading && digits.length == _otpLength) {
                                          onSubmit();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Hozircha tasdiqlash kodi sifatida telefon raqamingizning oxirgi 6 ta raqami ishlatiladi",
                                    textAlign: TextAlign.center,
                                    style: _OtpPageStyles.hintStyle,
                                  ),
                                  if (errorText != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      errorText,
                                      textAlign: TextAlign.center,
                                      style: _OtpPageStyles.errorStyle,
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  FadeTransition(
                                    opacity: _buttonFade,
                                    child: _PrimaryGradientButton(
                                      label: 'Tasdiqlash',
                                      loading: _loading,
                                      enabled: canSubmit,
                                      onPressed: canSubmit ? onSubmit : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: _ResendArea(
                                      secondsLeft: _resendSecondsLeft,
                                      loading: _resendLoading,
                                      onResend: () => _resend(repo, resolvedPhone),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpHeroHeader extends StatelessWidget {
  const _OtpHeroHeader({
    required this.height,
    required this.onBack,
  });

  final double height;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (MediaQuery.sizeOf(context).width * dpr).round();
    final cacheH = (height * dpr).round();

    return Stack(
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xFFEFF4FF),
          ),
          child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/otp_hero.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  cacheWidth: cacheW > 0 ? cacheW : null,
                  cacheHeight: cacheH > 0 ? cacheH : null,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: SafeArea(
            bottom: false,
            child: Material(
              color: Colors.white.withValues(alpha: 0.72),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF0D2D6C),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResendArea extends StatelessWidget {
  const _ResendArea({
    required this.secondsLeft,
    required this.loading,
    required this.onResend,
  });

  final int secondsLeft;
  final bool loading;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    String mmss(int totalSeconds) {
      final m = (totalSeconds ~/ 60).clamp(0, 99);
      final s = (totalSeconds % 60).clamp(0, 59);
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    if (secondsLeft > 0) {
      return Text(
        'Kodni qayta yuborish (${mmss(secondsLeft)})',
        style: _OtpPageStyles.resendStyle,
        textAlign: TextAlign.center,
      );
    }

    return TextButton(
      onPressed: loading ? null : onResend,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF0D2D6C),
        textStyle: _OtpPageStyles.resendActionStyle,
      ),
      child: loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Kodni qayta yuborish'),
    );
  }
}

class _OtpInputArea extends StatelessWidget {
  const _OtpInputArea({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasError,
    required this.caretT,
    required this.onChangedDigits,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasError;
  final Animation<double> caretT;
  final ValueChanged<String> onChangedDigits;

  @override
  Widget build(BuildContext context) {
    final digits = controller.text.replaceAll(RegExp(r'\D'), '');
    final compact = MediaQuery.sizeOf(context).width < 380;
    final boxSize = compact ? 44.0 : 48.0;
    final gap = compact ? 6.0 : 8.0;

    final activeIndex =
        digits.length.clamp(0, _SmsVerificationPageState._otpLength - 1);
    final hasFocus = focusNode.hasFocus;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_SmsVerificationPageState._otpLength, (i) {
              final ch = i < digits.length ? digits[i] : '';
              final isActive = hasFocus && i == activeIndex && enabled;
              final borderColor = isActive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFBFDBFE);
              final markerColor = isActive
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFFCBD5E1);
              const fill = Color(0xFFFFFFFF);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: gap / 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: fill,
                    border: Border.all(color: borderColor, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(
                          alpha: isActive ? 0.16 : 0.08,
                        ),
                        blurRadius: isActive ? 14 : 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (ch.isNotEmpty)
                        Text(
                          ch,
                          style: GoogleFonts.inter(
                            fontSize: 21,
                            height: 1.0,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E3A8A),
                          ),
                        )
                      else if (isActive)
                        FadeTransition(
                          opacity: caretT,
                          child: Container(
                            width: 2,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8).withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 7,
                        child: Container(
                          width: 2,
                          height: 10,
                          decoration: BoxDecoration(
                            color: markerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          // Hidden input capturing all digits for smooth UX (type once, fills boxes).
          SizedBox(
            width: 1,
            height: 1,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_SmsVerificationPageState._otpLength),
              ],
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChangedDigits,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryGradientButton extends StatefulWidget {
  const _PrimaryGradientButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
    required this.loading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;

  @override
  State<_PrimaryGradientButton> createState() => _PrimaryGradientButtonState();
}

class _PrimaryGradientButtonState extends State<_PrimaryGradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.enabled ? widget.onPressed : null;

    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      scale: _pressed ? 0.985 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: onPressed == null
                ? const [Color(0xFF5B9DFF), Color(0xFF3B82F6)]
                : const [Color(0xFF0B5FFF), Color(0xFF0047CC)],
          ),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF0B5FFF).withValues(alpha: 0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _OtpPageStyles {
  static final TextStyle titleStyle = GoogleFonts.cormorantGaramond(
    fontSize: 46,
    height: 1.02,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    color: const Color(0xFF0D2D6C),
  );

  static final TextStyle subtitleStyle = GoogleFonts.inter(
    fontSize: 16.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF1E293B),
  );

  static final TextStyle phoneInfoStyle = GoogleFonts.inter(
    fontSize: 14.5,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF334155),
  );

  static final TextStyle errorStyle = GoogleFonts.inter(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: const Color(0xFFE11D48),
  );

  static final TextStyle hintStyle = GoogleFonts.inter(
    fontSize: 13.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF475569),
  );

  static final TextStyle resendStyle = GoogleFonts.inter(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF475569),
  );

  static final TextStyle resendActionStyle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}
