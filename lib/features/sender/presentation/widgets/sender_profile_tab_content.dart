import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/local_file_exists.dart';
import '../../../../shared/widgets/platform_file_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/phone_validator.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/app_user.dart';
import '../../../../models/job_transport_type.dart';
import '../../../../models/user_role.dart';
import '../../../../shared/utils/display_name_formatter.dart';
import '../../../../shared/widgets/courier_transport_setup_sheet.dart';

/// Yuboruvchi «Profil»: barqaror saqlash, aylana avatar (bosilganda rasm tanlash).
class SenderProfileTabContent extends ConsumerStatefulWidget {
  const SenderProfileTabContent({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<SenderProfileTabContent> createState() =>
      _SenderProfileTabContentState();
}

class _SenderProfileTabContentState extends ConsumerState<SenderProfileTabContent> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _secondaryCtrl;
  final ImagePicker _picker = ImagePicker();

  String? _pickedImagePath;
  bool _removeImage = false;
  bool _saving = false;

  static const double _avatarOuter = 112;

  static String _composeName(AppUser u) {
    return '${u.firstName} ${u.lastName}'.trim();
  }

  static String _roleLabel(AppLocalizations l10n, UserRole? role) {
    return switch (role) {
      UserRole.courier => l10n.roleCourier,
      UserRole.admin => l10n.roleAdmin,
      UserRole.sender => l10n.roleSender,
      null => l10n.roleSender,
    };
  }

  static String _languageLabel(AppLocalizations l10n, Locale locale) {
    switch (locale.languageCode) {
      case 'uz':
        return l10n.languageUzbek;
      case 'ru':
        return l10n.languageRussian;
      case 'en':
        return l10n.languageEnglish;
      default:
        return locale.languageCode;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _composeName(widget.user));
    _secondaryCtrl = TextEditingController();
    ref.read(sharedPreferencesProvider.future).then((prefs) {
      if (!mounted) return;
      final s = prefs.getString('profile_secondary_phone_${widget.user.id}');
      if (s != null && s.isNotEmpty) {
        setState(() => _secondaryCtrl.text = s);
      }
    });
  }

  @override
  void didUpdateWidget(SenderProfileTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _nameCtrl.text = _composeName(widget.user);
      _pickedImagePath = null;
      _removeImage = false;
      _secondaryCtrl.clear();
      ref.read(sharedPreferencesProvider.future).then((prefs) {
        if (!mounted) return;
        final s = prefs.getString('profile_secondary_phone_${widget.user.id}');
        setState(() => _secondaryCtrl.text = s ?? '');
      });
    } else if (oldWidget.user.firstName != widget.user.firstName ||
        oldWidget.user.lastName != widget.user.lastName) {
      _nameCtrl.text = _composeName(widget.user);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _secondaryCtrl.dispose();
    super.dispose();
  }

  String _storedImagePath(SharedPreferences? prefs) {
    return prefs?.getString('profile_image_path_${widget.user.id}') ?? '';
  }

  String _effectiveImagePath(SharedPreferences? prefs) {
    if (_removeImage) return '';
    if (_pickedImagePath != null && _pickedImagePath!.isNotEmpty) {
      return _pickedImagePath!;
    }
    return _storedImagePath(prefs);
  }

  bool _hasDisplayableImage(String path) {
    if (path.isEmpty) return false;
    if (kIsWeb) {
      final t = path.trim().toLowerCase();
      return t.startsWith('http://') || t.startsWith('https://');
    }
    return localFileExistsSync(path);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final m = ScaffoldMessenger.maybeOf(context);
    m?.clearSnackBars();
    m?.showSnackBar(SnackBar(content: Text(message)));
  }

  static String _courierTransportSummary(AppLocalizations l10n, List<String> keys) {
    if (keys.isEmpty) return l10n.courierTransportEmptyTitle;
    final set = keys.toSet();
    final labels = <String>[];
    for (final v in JobTransportType.values) {
      if (set.contains(v.storageKey)) labels.add(v.label(l10n));
    }
    return labels.join(', ');
  }

  /// `sharedPreferencesProvider` ni invalidate qilmaymiz — `_dependents` / rebuild ziddiyatini oldini oladi.
  Future<void> _runPersist({
    required String fullName,
    required String secondaryRaw,
    String? profileImagePathUpdate,
    required AppLocalizations l10n,
  }) async {
    if (_saving || !mounted) return;
    setState(() => _saving = true);
    try {
      final auth = await ref.read(authRepositoryProvider.future);
      if (!mounted) return;
      await auth.updateSenderProfileDetails(
        fullName: fullName,
        secondaryPhoneRaw: secondaryRaw,
        profileImagePathUpdate: profileImagePathUpdate,
      );
      if (!mounted) return;
      await ref.read(authSessionProvider.notifier).refresh();
      ref.invalidate(profileImagePathProvider(widget.user.id));
      if (!mounted) return;
      final prefsAfter = await ref.read(sharedPreferencesProvider.future);
      if (!mounted) return;
      final userId = widget.user.id;
      final sec = prefsAfter.getString('profile_secondary_phone_$userId');
      final u = ref.read(authSessionProvider).valueOrNull;
      setState(() {
        _saving = false;
        _pickedImagePath = null;
        _removeImage = false;
        _secondaryCtrl.text = sec ?? '';
        if (u != null) _nameCtrl.text = _composeName(u);
      });
      _showSnack(l10n.senderProfileSaveSuccess);
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final msg = e.message == 'secondary_same_as_primary'
          ? l10n.senderProfileSecondarySameAsPrimary
          : l10n.senderProfileInvalidSecondaryPhone;
      _showSnack(msg);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Sheet/route to‘liq yopilgandan keyin saqlash (InheritedWidget / `_dependents` xatolari oldini olish).
  void _persistAfterSheetClosed({
    required String fullName,
    required String secondaryRaw,
    String? profileImagePathUpdate,
    required AppLocalizations l10n,
  }) {
    Future<void>.delayed(Duration.zero, () async {
      if (!mounted) return;
      await _runPersist(
        fullName: fullName,
        secondaryRaw: secondaryRaw,
        profileImagePathUpdate: profileImagePathUpdate,
        l10n: l10n,
      );
    });
  }

  Future<void> _openPhotoSourceSheet(
    BuildContext context,
    AppLocalizations l10n,
    SharedPreferences? prefs,
  ) async {
    final path = _effectiveImagePath(prefs);
    final hasImg = _hasDisplayableImage(path);
    final stored = _storedImagePath(prefs).isNotEmpty;

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.senderProfileChangePhoto,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l10n.chooseFile),
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    final f = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 82,
                      maxWidth: 1200,
                    );
                    if (f == null || !mounted) return;
                    _persistAfterSheetClosed(
                      fullName: _nameCtrl.text,
                      secondaryRaw: _secondaryCtrl.text,
                      profileImagePathUpdate: f.path,
                      l10n: l10n,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l10n.takePhoto),
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    final f = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 82,
                      maxWidth: 1200,
                    );
                    if (f == null || !mounted) return;
                    _persistAfterSheetClosed(
                      fullName: _nameCtrl.text,
                      secondaryRaw: _secondaryCtrl.text,
                      profileImagePathUpdate: f.path,
                      l10n: l10n,
                    );
                  },
                ),
                if (hasImg || stored)
                  ListTile(
                    leading: Icon(Icons.delete_outline_rounded, color: Theme.of(sheetCtx).colorScheme.error),
                    title: Text(
                      l10n.senderProfileRemovePhoto,
                      style: TextStyle(color: Theme.of(sheetCtx).colorScheme.error),
                    ),
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      _persistAfterSheetClosed(
                        fullName: _nameCtrl.text,
                        secondaryRaw: _secondaryCtrl.text,
                        profileImagePathUpdate: '',
                        l10n: l10n,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openNameEditor(BuildContext context, AppLocalizations l10n) async {
    final nameController = TextEditingController(text: _nameCtrl.text);
    final formKey = GlobalKey<FormState>();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetCtx) {
          final bottom = MediaQuery.viewInsetsOf(sheetCtx).bottom;
          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottom + 20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.senderProfileFullNameLabel,
                    style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: l10n.senderProfileFullNameHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () {
                            if (!(formKey.currentState?.validate() ?? true)) return;
                            final text = nameController.text;
                            Navigator.of(sheetCtx).pop();
                            _persistAfterSheetClosed(
                              fullName: text,
                              secondaryRaw: _secondaryCtrl.text,
                              profileImagePathUpdate: null,
                              l10n: l10n,
                            );
                          },
                    child: Text(l10n.senderProfileSave),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _openSecondaryEditor(BuildContext context, AppLocalizations l10n) async {
    final phoneController = TextEditingController(text: _secondaryCtrl.text);
    final formKey = GlobalKey<FormState>();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetCtx) {
          return _SecondaryPhoneSheetBody(
            l10n: l10n,
            formKey: formKey,
            phoneController: phoneController,
            primaryPhone: widget.user.phone,
            saving: _saving,
            onSave: (raw) {
              Navigator.of(sheetCtx).pop();
              _persistAfterSheetClosed(
                fullName: _nameCtrl.text,
                secondaryRaw: raw,
                profileImagePathUpdate: null,
                l10n: l10n,
              );
            },
          );
        },
      );
    } finally {
      phoneController.dispose();
    }
  }

  Widget _buildTappableAvatar(
    BuildContext context,
    AppLocalizations l10n,
    SharedPreferences? prefs,
    String path,
    bool showImage,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : () => _openPhotoSourceSheet(context, l10n, prefs),
        customBorder: const CircleBorder(),
        child: Ink(
          width: _avatarOuter,
          height: _avatarOuter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.22),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: showImage
                ? platformFileImage(
                    path,
                    width: _avatarOuter,
                    height: _avatarOuter,
                    fit: BoxFit.cover,
                  )
                : _avatarPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return ColoredBox(
      color: AppColors.primaryBlue.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 52,
          color: AppColors.primaryBlue.withValues(alpha: 0.88),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale =
        ref.watch(localeControllerProvider).valueOrNull ?? const Locale('uz');
    final prefsAsync = ref.watch(sharedPreferencesProvider);
    final prefs = prefsAsync.valueOrNull;

    final path = _effectiveImagePath(prefs);
    final showImage = _hasDisplayableImage(path);

    final rawName = _nameCtrl.text.trim();
    final nameDisplay = rawName.isNotEmpty
        ? formatDisplayName(rawName)
        : l10n.senderProfileNameEmpty;

    final phoneText = widget.user.phone.trim().isNotEmpty
        ? widget.user.phone.trim()
        : l10n.senderProfilePhoneEmpty;

    final secondaryDisplay = _secondaryCtrl.text.trim().isNotEmpty
        ? _secondaryCtrl.text.trim()
        : '—';

    final statusText = widget.user.blocked
        ? l10n.senderProfileStatusBlocked
        : l10n.senderProfileStatusActive;
    final statusColor =
        widget.user.blocked ? theme.colorScheme.error : const Color(0xFF16A34A);

    final verifyText = widget.user.phoneVerified
        ? l10n.senderProfilePhoneVerified
        : l10n.senderProfilePhoneNotVerified;

    final userForTransport =
        ref.watch(authSessionProvider).valueOrNull ?? widget.user;
    final authRepo = ref.watch(authRepositoryProvider).valueOrNull;
    final transportKeys = authRepo != null
        ? authRepo.resolvedCourierTransportKeys(userForTransport)
        : JobTransportType.normalizeCourierKeyList(
            userForTransport.courierTransportTypes,
          );

    return ColoredBox(
      color: AppColors.lightBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            l10n.profileSection,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0B2A4A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          _ProfileCard(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      _buildTappableAvatar(context, l10n, prefs, path, showImage),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: Colors.white,
                          elevation: 3,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _saving ? null : () => _openPhotoSourceSheet(context, l10n, prefs),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 20,
                                color: AppColors.primaryBlue.withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.senderProfileChangePhoto,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _ProfileRowWithEdit(
                  theme: theme,
                  leading: Icon(
                    Icons.badge_outlined,
                    size: 22,
                    color: AppColors.primaryBlue.withValues(alpha: 0.88),
                  ),
                  label: l10n.senderProfileNameLabel,
                  value: nameDisplay,
                  onEdit: _saving ? null : () => _openNameEditor(context, l10n),
                  busy: _saving,
                  editTooltip: l10n.senderProfileEditTooltip,
                ),
                _profileDivider(theme),
                _ProfileInfoRow(
                  theme: theme,
                  icon: Icons.phone_rounded,
                  label: l10n.senderProfilePhoneLabel,
                  value: phoneText,
                ),
                _profileDivider(theme),
                _ProfileRowWithEdit(
                  theme: theme,
                  leading: Icon(
                    Icons.phone_callback_outlined,
                    size: 22,
                    color: AppColors.primaryBlue.withValues(alpha: 0.88),
                  ),
                  label: l10n.senderProfileSecondaryPhoneLabel,
                  value: secondaryDisplay,
                  onEdit: _saving ? null : () => _openSecondaryEditor(context, l10n),
                  busy: _saving,
                  editTooltip: l10n.senderProfileEditTooltip,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (widget.user.role == UserRole.courier) ...[
            _ProfileCard(
              child: _ProfileRowWithEdit(
                theme: theme,
                leading: Icon(
                  Icons.local_shipping_outlined,
                  size: 22,
                  color: AppColors.primaryBlue.withValues(alpha: 0.88),
                ),
                label: l10n.courierProfileTransportLabel,
                value: _courierTransportSummary(l10n, transportKeys),
                onEdit: _saving
                    ? null
                    : () async {
                        final ok = await showCourierTransportSetupBottomSheet(
                          context: context,
                          userId: widget.user.id,
                          profileEditMode: true,
                        );
                        if (ok == true && mounted) {
                          await ref
                              .read(authSessionProvider.notifier)
                              .refresh();
                        }
                      },
                busy: false,
                editTooltip: l10n.courierProfileTransportChange,
              ),
            ),
            const SizedBox(height: 14),
          ],
          _ProfileCard(
            child: Column(
              children: [
                _ProfileInfoRow(
                  theme: theme,
                  icon: Icons.swap_horiz_rounded,
                  label: l10n.senderProfileRoleLabel,
                  value: _roleLabel(l10n, widget.user.role),
                ),
                _profileDivider(theme),
                _ProfileInfoRow(
                  theme: theme,
                  icon: Icons.language_rounded,
                  label: l10n.senderProfileLanguageLabel,
                  value: _languageLabel(l10n, locale),
                ),
                _profileDivider(theme),
                _ProfileInfoRow(
                  theme: theme,
                  icon: Icons.shield_outlined,
                  label: l10n.senderProfileStatusLabel,
                  value: statusText,
                  valueColor: statusColor,
                ),
                _profileDivider(theme),
                _ProfileInfoRow(
                  theme: theme,
                  icon: Icons.verified_outlined,
                  label: l10n.senderProfileVerificationLabel,
                  value: verifyText,
                  valueColor: widget.user.phoneVerified
                      ? const Color(0xFF16A34A)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// StatefulBuilder alohida widget — sheet ichida `setState` parent `Element` ga bog‘lanmaydi.
class _SecondaryPhoneSheetBody extends StatefulWidget {
  const _SecondaryPhoneSheetBody({
    required this.l10n,
    required this.formKey,
    required this.phoneController,
    required this.primaryPhone,
    required this.saving,
    required this.onSave,
  });

  final AppLocalizations l10n;
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final String primaryPhone;
  final bool saving;
  final void Function(String raw) onSave;

  @override
  State<_SecondaryPhoneSheetBody> createState() => _SecondaryPhoneSheetBodyState();
}

class _SecondaryPhoneSheetBodyState extends State<_SecondaryPhoneSheetBody> {
  String? _localError;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottom + 20),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.l10n.senderProfileSecondaryPhoneLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: widget.l10n.senderProfileSecondaryPhoneHint,
                errorText: _localError,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (_) {
                if (_localError != null) setState(() => _localError = null);
              },
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: widget.saving
                  ? null
                  : () {
                      final t = widget.phoneController.text.trim();
                      if (t.isNotEmpty) {
                        final n = PhoneValidator.validateUzbekPhone(t);
                        if (n == null) {
                          setState(() => _localError = widget.l10n.senderProfileInvalidSecondaryPhone);
                          return;
                        }
                        if (n == widget.primaryPhone) {
                          setState(() => _localError = widget.l10n.senderProfileSecondarySameAsPrimary);
                          return;
                        }
                      }
                      widget.onSave(widget.phoneController.text);
                    },
              child: Text(widget.l10n.senderProfileSave),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _profileDivider(ThemeData theme) {
  return Divider(
    height: 1,
    thickness: 1,
    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EEFF)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 8),
            color: Color(0x10000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProfileRowWithEdit extends StatelessWidget {
  const _ProfileRowWithEdit({
    required this.theme,
    required this.leading,
    required this.label,
    required this.value,
    required this.onEdit,
    required this.busy,
    required this.editTooltip,
  });

  final ThemeData theme;
  final Widget leading;
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final bool busy;
  final String editTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: editTooltip,
            onPressed: onEdit,
            icon: busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue.withValues(alpha: 0.85),
                    ),
                  )
                : Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryBlue.withValues(alpha: 0.9),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final ThemeData theme;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: AppColors.primaryBlue.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? theme.colorScheme.onSurface,
                    height: 1.25,
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
