import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/debug/provider_error_screen.dart';
import '../../../core/input/uz_phone_mask_formatter.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../repositories/auth_repository.dart';
import '../../../shared/widgets/app_theme_picker_sheet.dart';

class PhoneLoginPage extends ConsumerStatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  ConsumerState<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends ConsumerState<PhoneLoginPage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _loading = false;

  late final AnimationController _enter;
  late final Animation<double> _illustrationFade;
  late final Animation<double> _illustrationScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _inputFade;
  late final Animation<double> _buttonFade;

  /// `phone` / known validation; otherwise use [_otherError].
  String? _errorKey;
  String? _otherError;

  @override
  void initState() {
    super.initState();
    debugPrint('[phone] screen opened');
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
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
    _inputFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.34, 0.8, curve: Curves.easeOut),
    );
    _buttonFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.48, 0.95, curve: Curves.easeOut),
    );
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _digitsOnly() => _controller.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _submit(AuthRepository repo) async {
    if (_loading) return; // Double-submit (Enter spam) ni oldini oladi.
    final digits = _digitsOnly();
    debugPrint('[phone] phone submit pressed: "$digits"');
    setState(() {
      _loading = true;
      _errorKey = null;
      _otherError = null;
    });
    try {
      final raw = '+998$digits';
      final normalized = repo.debugValidatePhone(raw);
      if (normalized == null) {
        throw FormatException('invalid_phone');
      }
      debugPrint('[phone] validate passed: $normalized');
      debugPrint('[phone] request login started');
      final user = await repo.submitPhone(raw);
      debugPrint('[phone] auth repository success: user=${user.id}');
      debugPrint('[phone] session saved');
      await ref.read(authSessionProvider.notifier).refresh();
      if (mounted) {
        debugPrint('[phone] navigate to sms');
        final encodedPhone = Uri.encodeComponent(raw);
        context.go('${AppRoutes.sms}?phone=$encodedPhone');
      }
    } on FormatException catch (e) {
      debugPrint('[phone] format exception: ${e.message}');
      setState(() {
        if (e.message == 'invalid_phone') {
          _errorKey = 'phone';
          _otherError = null;
        } else {
          _errorKey = null;
          _otherError = e.toString();
        }
      });
    } catch (e, st) {
      debugPrint('submitPhone: $e\n$st');
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

  @override
  Widget build(BuildContext context) {
    final qp = GoRouterState.of(context).uri.queryParameters;
    debugPrint('[phone] build authStep=phone_input query=$qp');
    final l10n = AppLocalizations.of(context);
    final repoAsync = ref.watch(authRepositoryProvider);

    final digits = _digitsOnly();
    final canSubmit = !_loading && digits.isNotEmpty;

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
                  color: Theme.of(context).colorScheme.surface,
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
              final onSubmit = () => _submit(repo);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final contentMaxWidth = constraints.maxWidth > 520 ? 420.0 : double.infinity;
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),
                            FadeTransition(
                              opacity: _illustrationFade,
                              child: ScaleTransition(
                                scale: _illustrationScale,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: _TopIllustration(
                                    height: constraints.maxHeight < 680 ? 220 : 260,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            FadeTransition(
                              opacity: _titleFade,
                              child: SlideTransition(
                                position: _titleSlide,
                                child: Column(
                                  children: [
                                    Text(
                                      l10n.phoneLoginTitle,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                            color: const Color(0xFF0D2D6C),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tasdiqlash kodi orqali xavfsiz kirish',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: const Color(0xFF1F2A44),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),
                            FadeTransition(
                              opacity: _inputFade,
                              child: _PhoneInputCard(
                                controller: _controller,
                                enabled: !_loading,
                                errorText: _otherError ??
                                    (_errorKey == 'phone' ? l10n.errorInvalidPhone : null),
                                onSubmitted: () {
                                  if (_loading) return;
                                  onSubmit();
                                },
                                onChanged: (_) {
                                  if (_errorKey != null || _otherError != null) {
                                    setState(() {
                                      _errorKey = null;
                                      _otherError = null;
                                    });
                                  } else {
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            FadeTransition(
                              opacity: _buttonFade,
                              child: _PrimaryGradientButton(
                                label: l10n.sendCode,
                                loading: _loading,
                                enabled: canSubmit,
                                onPressed: canSubmit ? onSubmit : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Davom etish orqali xizmat shartlariga\nrozilik bildirasiz",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black.withOpacity(0.45),
                                    height: 1.25,
                                  ),
                            ),
                            const SizedBox(height: 10),
                          ],
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

class _TopIllustration extends StatelessWidget {
  const _TopIllustration({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cachePx = (height * dpr).round();
    final surface = Theme.of(context).colorScheme.surface;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ColoredBox(
        color: surface,
        child: Center(
          child: Image.asset(
            'assets/images/login_illustration.png',
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            cacheWidth: cachePx > 0 ? cachePx : null,
            cacheHeight: cachePx > 0 ? cachePx : null,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(
              height: height,
              width: height,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140D2D6C),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Color(0xFF0D2D6C),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneInputCard extends StatelessWidget {
  const _PhoneInputCard({
    required this.controller,
    required this.enabled,
    required this.errorText,
    required this.onSubmitted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: const Color(0xFFF8F8FA),
            border: Border.all(
              color: isError ? const Color(0x66E11D48) : const Color(0x140D2D6C),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D2D6C).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Text('🇺🇿', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(
                  '+998',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D2D6C),
                      ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 26,
                  color: const Color(0x220D2D6C),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmitted(),
                    onChanged: onChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                      const UzPhoneMaskFormatter(),
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '__ ___ __ __',
                      hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0x661F2A44),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF1F2A44),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.phone_iphone_rounded,
                  color: const Color(0xFF0D2D6C).withOpacity(0.55),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isError) ...[
          const SizedBox(height: 10),
          Text(
            errorText!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFE11D48),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
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
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: onPressed == null
                ? const [Color(0xFFB8C1D4), Color(0xFF9BA8C2)]
                : const [Color(0xFF0D2D6C), Color(0xFF17439A)],
          ),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF0D2D6C).withOpacity(0.28),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
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

