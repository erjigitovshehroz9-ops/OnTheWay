import 'dart:io';

import 'package:courier_auction/shared/widgets/courier_registration_transport_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/debug/provider_error_screen.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/region_record.dart';
import '../../../models/user_role.dart';
import '../../../repositories/auth_repository.dart';

class OfferAgreementPage extends ConsumerStatefulWidget {
  const OfferAgreementPage({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  ConsumerState<OfferAgreementPage> createState() => _OfferAgreementPageState();
}

class _OfferAgreementPageState extends ConsumerState<OfferAgreementPage> {
  bool _accepted = false;
  bool _attempted = false;
  bool _loading = false;
  String? _actionError;

  static const Color _errorRed = Color(0xFFE11D48);

  Future<void> _accept(AuthRepository repo) async {
    setState(() {
      _attempted = true;
      _actionError = null;
    });
    if (!_accepted) return;

    setState(() => _loading = true);
    try {
      final nextUser = await repo.acceptOffer();
      await ref.read(authSessionProvider.notifier).refresh();
      if (!mounted) return;

      final encodedPhone = Uri.encodeComponent(nextUser.phone);
      // Oferta shartlari tasdiqlangandan keyin profil setupiga o'tamiz.
      context.go('${AppRoutes.role}?phone=$encodedPhone');
    } catch (e, st) {
      debugPrint('acceptOffer: $e\n$st');
      if (mounted) setState(() => _actionError = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(authRepositoryProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4F8FF), Color(0xFFFBFDFF)],
            ),
          ),
          child: repoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(24),
              child: ProviderErrorScreen(
                error: error,
                stackTrace: stack,
                onRetry: () => ref.invalidate(authRepositoryProvider),
              ),
            ),
            data: (repo) => LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth > 560 ? 440.0 : double.infinity;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFE3ECFF)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x163B82F6),
                              blurRadius: 30,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                l10n.offerTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF103B8F),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FBFF),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFDCE8FF)),
                                ),
                                child: Text(
                                  l10n.offerBody,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.45,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _attempted && !_accepted
                                      ? const Color(0xFFFFEEF2)
                                      : const Color(0xFFF9FBFF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _attempted && !_accepted
                                        ? _errorRed
                                        : const Color(0xFFBFD0EF),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _accepted,
                                      activeColor: const Color(0xFF0B5FFF),
                                      onChanged: (v) {
                                        setState(() {
                                          _accepted = v ?? false;
                                          if (_accepted) {
                                            _attempted = false;
                                          }
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        l10n.offerAcceptCheckbox,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_attempted && !_accepted) ...[
                                const SizedBox(height: 6),
                                Text(
                                  l10n.errorMustAcceptOffer,
                                  style: TextStyle(
                                    color: _errorRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (_actionError != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _actionError!,
                                  style: const TextStyle(
                                    color: _errorRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 50,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B5FFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed:
                                      _loading ? null : () => _accept(repo),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          l10n.continueWord,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _picker = ImagePicker();

  final _scrollController = ScrollController();
  final _fullNameFieldKey = GlobalKey();
  final _phoneFieldKey = GlobalKey();
  final _roleFieldKey = GlobalKey();
  final _regionFieldKey = GlobalKey();
  final _districtFieldKey = GlobalKey();
  final _birthDateFieldKey = GlobalKey();
  final _transportFieldKey = GlobalKey();

  final _fullNameFocusNode = FocusNode();

  bool _loading = false;
  String? _actionError;
  UserRole _selectedRole = UserRole.sender;
  String? _selectedRegionCode;
  String? _selectedDistrictCode;
  DateTime? _birthDate;
  String? _profileImagePath;
  String? _selectedGender;
  final Set<String> _selectedTransportTypes = <String>{};

  static const Color _errorRed = Color(0xFFE11D48);

  static const TextStyle _fieldTextStyle = TextStyle(
    color: Color(0xFF000000),
    fontSize: 16,
  );

  @override
  void initState() {
    super.initState();
    final user = ref.read(authSessionProvider).valueOrNull;
    final effectivePhone =
        widget.phoneNumber.trim().isNotEmpty ? widget.phoneNumber : (user?.phone ?? '');
    _phoneController.text = effectivePhone;
    _fullNameController.text =
        '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    _selectedRole = user?.role ?? UserRole.sender;
    _selectedRegionCode = user?.regionCode;
    _selectedDistrictCode = user?.districtCode;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _scrollController.dispose();
    _fullNameFocusNode.dispose();
    super.dispose();
  }

  bool _isFullNameMissing() => _fullNameController.text.trim().isEmpty;

  bool _isPhoneMissing() => _phoneController.text.trim().isEmpty;

  // `_selectedRole` is always set by the UI + initState, but keep this for
  // future safety and validation behavior.
  bool _isRoleMissing() =>
      _selectedRole != UserRole.sender && _selectedRole != UserRole.courier;

  bool _isRegionMissing() => _selectedRegionCode == null;

  bool _isDistrictMissing() => _selectedDistrictCode == null;

  bool _isBirthDateMissing() => _birthDate == null;

  bool get _isCourier => _selectedRole == UserRole.courier;

  bool _isTransportMissing() => _isCourier && _selectedTransportTypes.isEmpty;

  GlobalKey? _firstInvalidFieldKey() {
    if (_isFullNameMissing()) return _fullNameFieldKey;
    if (_isPhoneMissing()) return _phoneFieldKey;
    if (_isRoleMissing()) return _roleFieldKey;
    if (_isRegionMissing()) return _regionFieldKey;
    if (_isDistrictMissing()) return _districtFieldKey;
    if (_isBirthDateMissing()) return _birthDateFieldKey;
    if (_isTransportMissing()) return _transportFieldKey;
    return null;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 22, 1, 1),
      firstDate: DateTime(1940, 1, 1),
      lastDate: DateTime(now.year - 12, 12, 31),
      helpText: "Tug'ilgan sanani tanlang",
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryBlue,
              brightness: Brightness.light,
            ).copyWith(
              surface: Colors.white,
              onSurface: const Color(0xFF1F2937),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: AppColors.auctionDeepBlue,
              headerForegroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickProfileImage() async {
    const onSheet = Color(0xFF111827);
    const iconSheet = Color(0xFF2563EB);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Theme(
          data: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryBlue,
              brightness: Brightness.light,
            ).copyWith(
              surface: Colors.white,
              onSurface: onSheet,
              onSurfaceVariant: Color(0xFF374151),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Profil rasmini tanlang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: onSheet,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_outlined,
                      color: iconSheet,
                    ),
                    title: const Text(
                      'Galereyadan tanlash',
                      style: TextStyle(
                        color: onSheet,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_camera_outlined,
                      color: iconSheet,
                    ),
                    title: const Text(
                      'Kamera orqali olish',
                      style: TextStyle(
                        color: onSheet,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (source == null) return;

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (file == null) return;
    setState(() => _profileImagePath = file.path);
  }

  Future<void> _continue(AuthRepository repo) async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final fieldsValid = !_isFullNameMissing() &&
        !_isPhoneMissing() &&
        !_isRoleMissing() &&
        !_isRegionMissing() &&
        !_isDistrictMissing() &&
        !_isBirthDateMissing() &&
        !_isTransportMissing();

    if (!formValid || !fieldsValid) {
      final firstInvalidKey = _firstInvalidFieldKey();
      if (firstInvalidKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = firstInvalidKey.currentContext;
          if (ctx == null) return;

          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            alignment: 0.18,
          );

          if (firstInvalidKey == _fullNameFieldKey) {
            _fullNameFocusNode.requestFocus();
          }
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _actionError = null;
    });

    try {
      await repo.completeProfileSetup(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: _selectedRole,
        regionCode: _selectedRegionCode!,
        districtCode: _selectedDistrictCode!,
        birthDate: _birthDate!,
        gender: _selectedGender,
        selectedTransportTypes: _selectedTransportTypes.toList(growable: false),
        profileImagePath: _profileImagePath,
      );
      await ref.read(authSessionProvider.notifier).refresh();
      final uid = ref.read(authSessionProvider).valueOrNull?.id;
      if (uid != null) {
        ref.invalidate(profileImagePathProvider(uid));
      }
    } catch (e, st) {
      debugPrint('completeProfileSetup: $e\n$st');
      setState(() => _actionError = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd.$mm.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(authRepositoryProvider);
    final regionsAsync = ref.watch(regionsListProvider);
    final districtsAsync = _selectedRegionCode == null
        ? const AsyncValue<List<DistrictRecord>>.data(<DistrictRecord>[])
        : ref.watch(districtsForRegionProvider(_selectedRegionCode!));
    final locale = Localizations.localeOf(context);

    return Scaffold(
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4F8FF), Color(0xFFFBFDFF)],
            ),
          ),
          child: repoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(24),
              child: ProviderErrorScreen(
                error: error,
                stackTrace: stack,
                onRetry: () => ref.invalidate(authRepositoryProvider),
              ),
            ),
            data: (repo) => LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth > 560 ? 440.0 : double.infinity;
                final scrollHPad = constraints.maxWidth < 360 ? 12.0 : 18.0;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: scrollHPad,
                        vertical: 14,
                      ),
                      controller: _scrollController,
                      child: LayoutBuilder(
                        builder: (context, cardConstraints) {
                          final contentW = cardConstraints.maxWidth;
                          final narrow = contentW < 360;
                          final cardPad = narrow ? 12.0 : 16.0;
                          final regionGap = narrow ? 8.0 : 10.0;
                          return DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFE3ECFF)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x163B82F6),
                              blurRadius: 30,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            cardPad,
                            narrow ? 16 : 20,
                            cardPad,
                            narrow ? 14 : 16,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ProfileAvatarPicker(
                                  imagePath: _profileImagePath,
                                  onTap: _pickProfileImage,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  "Ma'lumotlaringizni kiriting",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF103B8F),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Profilingizni to'ldiring va xizmatdan foydalanishni boshlang",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.35,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  key: _fullNameFieldKey,
                                  focusNode: _fullNameFocusNode,
                                  controller: _fullNameController,
                                  style: _fieldTextStyle,
                                  textInputAction: TextInputAction.next,
                                  decoration: _inputDecoration("F.I.SH."),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return "F.I.SH. kiriting";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: _phoneFieldKey,
                                  controller: _phoneController,
                                  readOnly: true,
                                  style: _fieldTextStyle,
                                  decoration: _inputDecoration('Telefon raqam').copyWith(
                                    fillColor: const Color(0xFFF4F7FC),
                                  ),
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (v) {
                                    final phone = v?.trim() ?? '';
                                    if (phone.isEmpty) return "Telefon raqami kerak";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                DecoratedBox(
                                  key: _roleFieldKey,
                                  decoration: BoxDecoration(
                                    color: _isRoleMissing()
                                        ? const Color(0xFFFFEEF2)
                                        : const Color(0xFFF9FBFF),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _isRoleMissing() ? _errorRed : const Color(0xFFDCE8FF),
                                    ),
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: SegmentedButton<UserRole>(
                                      style: ButtonStyle(
                                        visualDensity: narrow
                                            ? VisualDensity.compact
                                            : VisualDensity.standard,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
                                        side: const WidgetStatePropertyAll(BorderSide.none),
                                        padding: WidgetStatePropertyAll(
                                          EdgeInsets.symmetric(
                                            horizontal: narrow ? 6 : 10,
                                            vertical: narrow ? 8 : 10,
                                          ),
                                        ),
                                        textStyle: WidgetStatePropertyAll(
                                          TextStyle(
                                            fontSize: narrow ? 12.5 : 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return const Color(0xFF2563EB);
                                          }
                                          return const Color(0x00000000);
                                        }),
                                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.white;
                                          }
                                          return const Color(0xFF1E3A8A);
                                        }),
                                        shape: const WidgetStatePropertyAll(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(12)),
                                          ),
                                        ),
                                      ),
                                      segments: [
                                        ButtonSegment<UserRole>(
                                          value: UserRole.sender,
                                          label: Text(
                                            'Yuboruvchi',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        ButtonSegment<UserRole>(
                                          value: UserRole.courier,
                                          label: Text(
                                            'Kuryer',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                      selected: <UserRole>{_selectedRole},
                                      onSelectionChanged: (s) =>
                                          setState(() => _selectedRole = s.first),
                                      showSelectedIcon: false,
                                    ),
                                  ),
                                ),
                                if (_isRoleMissing()) ...[
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Rolni tanlang',
                                    style: TextStyle(
                                      color: Color(0xFFE11D48),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (_selectedRole == UserRole.courier) ...[
                                  const SizedBox(height: 10),
                                  CourierRegistrationTransportRow(
                                    key: _transportFieldKey,
                                    selected: _selectedTransportTypes,
                                    showValidationError: _isTransportMissing(),
                                    onToggle: (value) {
                                      setState(() {
                                        if (_selectedTransportTypes
                                            .contains(value)) {
                                          _selectedTransportTypes.remove(value);
                                        } else {
                                          _selectedTransportTypes.add(value);
                                        }
                                      });
                                    },
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: regionsAsync.when(
                                        loading: () =>
                                            const LinearProgressIndicator(minHeight: 2),
                                        error: (_, __) =>
                                            const Text("Viloyatlarni yuklashda xatolik"),
                                        data: (regions) => DropdownButtonFormField<String>(
                                          key: _regionFieldKey,
                                          isExpanded: true,
                                          value: _selectedRegionCode,
                                          style: _fieldTextStyle,
                                          dropdownColor: Colors.white,
                                          iconEnabledColor: const Color(0xFF1F2937),
                                          decoration: _dropdownDecoration(
                                            'Viloyat/Hudud',
                                            icon: narrow ? null : Icons.map_outlined,
                                          ),
                                          autovalidateMode:
                                              AutovalidateMode.onUserInteraction,
                                          selectedItemBuilder: (context) {
                                            return regions.map((r) {
                                              return Align(
                                                alignment: AlignmentDirectional.centerStart,
                                                child: Text(
                                                  r.name.resolveLang(locale.languageCode),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: _fieldTextStyle,
                                                ),
                                              );
                                            }).toList();
                                          },
                                          items: regions
                                              .map(
                                                (r) => DropdownMenuItem<String>(
                                                  value: r.code,
                                                  child: Text(
                                                    r.name.resolveLang(locale.languageCode),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: _fieldTextStyle,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedRegionCode = value;
                                              _selectedDistrictCode = null;
                                            });
                                          },
                                          validator: (v) =>
                                              v == null ? 'Viloyatni tanlang' : null,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: regionGap),
                                    Expanded(
                                      child: districtsAsync.when(
                                        loading: () =>
                                            const LinearProgressIndicator(minHeight: 2),
                                        error: (_, __) =>
                                            const Text("Tumanlarni yuklashda xatolik"),
                                        data: (districts) => DropdownButtonFormField<String>(
                                          key: _districtFieldKey,
                                          isExpanded: true,
                                          value: _selectedDistrictCode,
                                          style: _fieldTextStyle,
                                          dropdownColor: Colors.white,
                                          iconEnabledColor: const Color(0xFF1F2937),
                                          decoration: _dropdownDecoration(
                                            'Tuman/Shahar',
                                            icon: narrow ? null : Icons.location_city_outlined,
                                          ),
                                          autovalidateMode:
                                              AutovalidateMode.onUserInteraction,
                                          selectedItemBuilder: (context) {
                                            return districts.map((d) {
                                              return Align(
                                                alignment: AlignmentDirectional.centerStart,
                                                child: Text(
                                                  d.name.resolveLang(locale.languageCode),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: _fieldTextStyle,
                                                ),
                                              );
                                            }).toList();
                                          },
                                          items: districts
                                              .map(
                                                (d) => DropdownMenuItem<String>(
                                                  value: d.code,
                                                  child: Text(
                                                    d.name.resolveLang(locale.languageCode),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: _fieldTextStyle,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: _selectedRegionCode == null
                                              ? null
                                              : (value) {
                                                  setState(() => _selectedDistrictCode = value);
                                                },
                                          validator: (v) =>
                                              v == null
                                                  ? 'Tuman/Shaharni tanlang'
                                                  : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  key: _birthDateFieldKey,
                                  readOnly: true,
                                  controller: _birthDateController,
                                  style: _fieldTextStyle,
                                  decoration: _inputDecoration("Tug'ilgan sana").copyWith(
                                    suffixIcon: const Icon(Icons.calendar_month_rounded),
                                  ),
                                  onTap: _pickBirthDate,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (_) => _birthDate == null
                                      ? "Tug'ilgan sanani tanlang"
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FBFF),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFBFD0EF),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _GenderChip(
                                            label: 'Erkak',
                                            selected: _selectedGender == 'erkak',
                                            onTap: () => setState(() => _selectedGender = 'erkak'),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _GenderChip(
                                            label: 'Ayol',
                                            selected: _selectedGender == 'ayol',
                                            onTap: () => setState(() => _selectedGender = 'ayol'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_actionError != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    _actionError!,
                                    style: const TextStyle(
                                      color: Color(0xFFE11D48),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 50,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF003A90),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          const Color(0xFF003A90).withValues(alpha: 0.5),
                                      disabledForegroundColor: Colors.white70,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: _loading ? null : () => _continue(repo),
                                    child: _loading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            "Davom etish",
                                            style: TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Viloyat/tuman tanlash: doimiy yorliq va ixtiyoriy ikon — maydon maqsadi aniq bo‘ladi.
  InputDecoration _dropdownDecoration(String label, {IconData? icon}) {
    return _inputDecoration(label).copyWith(
      hintText: null,
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: Color(0xFF4B5563),
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF2563EB),
        fontWeight: FontWeight.w600,
        fontSize: 11.5,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 22,
              color: const Color(0xFF2563EB).withValues(alpha: 0.88),
            ),
      prefixIconConstraints: icon == null
          ? null
          : const BoxConstraints(minWidth: 44, maxHeight: 48),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 16,
      ),
      filled: true,
      fillColor: const Color(0xFFF9FBFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBFD0EF), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBFD0EF), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _errorRed, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _errorRed, width: 1.6),
      ),
      errorStyle: const TextStyle(
        color: _errorRed,
        fontSize: 12,
        height: 1.2,
      ),
      errorMaxLines: 2,
    );
  }
}

class _ProfileAvatarPicker extends StatelessWidget {
  const _ProfileAvatarPicker({
    required this.imagePath,
    required this.onTap,
  });

  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Ink(
                height: 104,
                width: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8F0FF),
                  border: Border.all(color: const Color(0xFFDBE8FF), width: 1.2),
                ),
                child: ClipOval(
                  child: hasImage
                      ? Image.file(
                          File(imagePath!),
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 56,
                          color: Color(0xFF1D4ED8),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Ink(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0B5FFF),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.imagePath,
    required this.onTap,
  });

  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE8FF)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE5EEFF),
              child: Icon(
                hasImage ? Icons.image_rounded : Icons.cloud_upload_outlined,
                color: const Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Profil rasm yuklash",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF2563EB) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

