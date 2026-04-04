import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/support_request_entity.dart';
import '../../../../shared/utils/support_request_l10n.dart';
import '../../../../shared/widgets/app_theme_picker_sheet.dart';
import 'sender_notifications_sheet.dart';

const int _kMinContactMessageLength = 15;

/// Sozlamalar menyusi faqat shu telefon uchun (masalan `+998988082846`).
bool isAppSettingsMenuAllowedForPhone(String? phone) {
  if (phone == null || phone.trim().isEmpty) return false;
  final d = phone.replaceAll(RegExp(r'\D'), '');
  return d == '998988082846' || d == '988082846';
}

void showSenderHomeContactBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => const _SenderContactSupportSheet(),
  );
}

/// Faqat: shikoyat, maqtov, ariza.
const List<SupportRequestType> _senderContactTypes = [
  SupportRequestType.complaint,
  SupportRequestType.praise,
  SupportRequestType.application,
];

class _SenderContactSupportSheet extends ConsumerStatefulWidget {
  const _SenderContactSupportSheet();

  @override
  ConsumerState<_SenderContactSupportSheet> createState() =>
      _SenderContactSupportSheetState();
}

class _SenderContactSupportSheetState extends ConsumerState<_SenderContactSupportSheet> {
  SupportRequestType? _type;
  final _message = TextEditingController();
  bool _showErrors = false;
  bool _submitting = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  String? _typeError(AppLocalizations l10n) {
    if (!_showErrors) return null;
    if (_type == null) return l10n.createJobValidationContactType;
    return null;
  }

  String? _messageError(AppLocalizations l10n) {
    if (!_showErrors) return null;
    final t = _message.text.trim();
    if (t.isEmpty) return l10n.createJobValidationContactMessage;
    if (t.length < _kMinContactMessageLength) {
      return l10n.createJobValidationMessageTooShort;
    }
    return null;
  }

  bool get _canSubmit {
    if (_type == null) return false;
    final t = _message.text.trim();
    return t.length >= _kMinContactMessageLength;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    setState(() => _showErrors = true);
    if (_typeError(l10n) != null || _messageError(l10n) != null) return;

    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final repo = await ref.read(supportRequestRepositoryProvider.future);
      await repo.submit(
        userId: user.id,
        userName: user.displayName,
        userPhone: user.phone,
        roleStorage: user.role?.name ?? 'unknown',
        requestType: _type!,
        message: _message.text.trim(),
      );
      ref.invalidate(adminSupportRequestsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.createJobContactSuccess)),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.createJobContactTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.createJobContactPickType,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (_typeError(l10n) != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _typeError(l10n)!,
                  style: TextStyle(color: scheme.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 10),
            ..._senderContactTypes.map((t) {
              final sel = _type == t;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: sel
                      ? scheme.primaryContainer.withValues(alpha: 0.35)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _type = t),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            _iconForType(t),
                            color: sel ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              supportRequestTypeLabel(l10n, t),
                              style: TextStyle(
                                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            sel ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: sel ? scheme.primary : scheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (_type != null) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _message,
                minLines: 5,
                maxLines: 8,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.createJobContactMessageLabel,
                  hintText: l10n.createJobContactMessageHint,
                  alignLabelWithHint: true,
                  errorText: _messageError(l10n),
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: !_canSubmit || _submitting ? null : () => _submit(l10n),
              child: _submitting
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : Text(l10n.createJobContactSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(SupportRequestType t) {
  return switch (t) {
    SupportRequestType.complaint => Icons.report_outlined,
    SupportRequestType.praise => Icons.thumb_up_alt_outlined,
    SupportRequestType.application => Icons.description_outlined,
    SupportRequestType.suggestion => Icons.lightbulb_outline_rounded,
  };
}

const double kHomeOverflowMenuIconSize = 20;
const double kHomeOverflowMenuIconSlotWidth = 28;

Icon homeOverflowMenuLeadingIcon(
  ThemeData theme,
  IconData icon, {
  Color? color,
}) {
  return Icon(
    icon,
    size: kHomeOverflowMenuIconSize,
    color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.78),
  );
}

void closeHomeOverflowMenu(BuildContext context) {
  MenuController.maybeOf(context)?.close();
}

Widget homeOverflowMenuActionRow(
  ThemeData theme,
  IconData icon,
  String label, {
  Color? textColor,
  FontWeight? fontWeight,
  Widget? trailing,
}) {
  final tc = textColor;
  return Row(
    children: [
      SizedBox(
        width: kHomeOverflowMenuIconSlotWidth,
        child: Align(
          alignment: Alignment.centerLeft,
          child: homeOverflowMenuLeadingIcon(theme, icon, color: tc),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: tc,
            fontWeight: fontWeight ?? FontWeight.w500,
          ),
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 8), trailing],
    ],
  );
}

Widget _homeOverflowLangSubmenuRow(ThemeData theme, String label, bool selected) {
  return Row(
    children: [
      SizedBox(
        width: kHomeOverflowMenuIconSlotWidth,
        child: Align(
          alignment: Alignment.centerLeft,
          child: homeOverflowMenuLeadingIcon(theme, Icons.language_rounded),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(label)),
      if (selected)
        Icon(Icons.check_rounded, size: kHomeOverflowMenuIconSize, color: theme.colorScheme.primary),
    ],
  );
}

/// Yuboruvchi `more_vert` va kuryer bosh paneli uchun umumiy menyular.
List<Widget> buildHomeOverflowMenuChildren({
  required BuildContext context,
  required WidgetRef ref,
  required ThemeData theme,
  required AppLocalizations l10n,
  required Locale currentLocale,
  required Future<void> Function() onLogout,
  bool includeAppSettingsRoute = false,
  String? userPhoneForSettingsGate,
  /// Yuboruvchi: bildirishnomalar ro‘yxati va yangi xabar indikatori.
  String? senderNotificationsUserId,
  int senderUnreadNotificationCount = 0,
}) {
  final error = theme.colorScheme.error;
  final showAppSettings = includeAppSettingsRoute &&
      isAppSettingsMenuAllowedForPhone(userPhoneForSettingsGate);

  void runAfterClose(VoidCallback fn) {
    closeHomeOverflowMenu(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) fn();
    });
  }

  void pickLang(Locale locale) {
    closeHomeOverflowMenu(context);
    ref.read(localeControllerProvider.notifier).setLocale(locale);
  }

  const divider =
      Divider(height: 1, thickness: 1, indent: 12, endIndent: 12);

  return [
    SubmenuButton(
      menuChildren: [
        MenuItemButton(
          onPressed: () => pickLang(const Locale('uz')),
          child: _homeOverflowLangSubmenuRow(
            theme,
            l10n.languageUzbek,
            currentLocale.languageCode == 'uz',
          ),
        ),
        MenuItemButton(
          onPressed: () => pickLang(const Locale('ru')),
          child: _homeOverflowLangSubmenuRow(
            theme,
            l10n.languageRussian,
            currentLocale.languageCode == 'ru',
          ),
        ),
        MenuItemButton(
          onPressed: () => pickLang(const Locale('en')),
          child: _homeOverflowLangSubmenuRow(
            theme,
            l10n.languageEnglish,
            currentLocale.languageCode == 'en',
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: kHomeOverflowMenuIconSlotWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: homeOverflowMenuLeadingIcon(theme, Icons.language_rounded),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.language,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              size: kHomeOverflowMenuIconSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ),
    divider,
    if (showAppSettings) ...[
      MenuItemButton(
        onPressed: () => runAfterClose(() => context.push(AppRoutes.settings)),
        child: homeOverflowMenuActionRow(theme, Icons.tune_rounded, l10n.settings),
      ),
      divider,
    ],
    MenuItemButton(
      onPressed: () => runAfterClose(() => showAppThemeBottomSheet(context)),
      child: homeOverflowMenuActionRow(theme, Icons.settings_outlined, l10n.createJobMenuChangeTheme),
    ),
    MenuItemButton(
      onPressed: () => runAfterClose(() => showSenderHomeContactBottomSheet(context)),
      child: homeOverflowMenuActionRow(theme, Icons.support_agent_rounded, l10n.createJobMenuContactUs),
    ),
    MenuItemButton(
      onPressed: () => runAfterClose(() {
        final uid = senderNotificationsUserId;
        if (uid != null) {
          showSenderNotificationsSheet(
            context,
            ref,
            uid,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.senderNotificationsEmpty)),
          );
        }
      }),
      child: homeOverflowMenuActionRow(
        theme,
        Icons.notifications_outlined,
        l10n.senderNotificationsTooltip,
        trailing: senderUnreadNotificationCount > 0
            ? const PulsingNotificationDot(size: 9)
            : null,
      ),
    ),
    divider,
    MenuItemButton(
      onPressed: () => runAfterClose(() {
        onLogout();
      }),
      child: homeOverflowMenuActionRow(
        theme,
        Icons.logout_rounded,
        l10n.logout,
        textColor: error,
        fontWeight: FontWeight.w700,
      ),
    ),
  ];
}
