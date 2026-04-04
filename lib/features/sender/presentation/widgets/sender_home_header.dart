import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/sender_in_app_notifications_provider.dart';
import '../../../../shared/widgets/premium_monogram_avatar.dart';
import 'sender_home_settings_menu.dart';
import 'sender_notifications_sheet.dart'
    show PulsingNotificationDot, showSenderNotificationsSheet;

/// Yuboruvchi: kuryer bosh paneli kabi — markazda rol sarlavhasi, o‘ngda avatar → menyu.
class SenderHomeHeader extends ConsumerWidget {
  const SenderHomeHeader({
    super.key,
    required this.displayNameFormatted,
    required this.userId,
    required this.onLogout,
  });

  final String displayNameFormatted;
  final String userId;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Yorug‘: avvalgi to‘q ko‘k (#1E3A8A); qorong‘i: yuqori kontrast.
    final titleColor = theme.brightness == Brightness.light
        ? const Color(0xFF1E3A8A)
        : const Color(0xFFE2E8F0);
    final l10n = AppLocalizations.of(context);
    final currentLocale =
        ref.watch(localeControllerProvider).valueOrNull ?? const Locale('uz');
    final menuInitial = _senderMenuInitial(displayNameFormatted);
    final notifAsync = ref.watch(senderInAppNotificationsProvider(userId));
    final unreadCount =
        notifAsync.valueOrNull?.where((n) => !n.read).length ?? 0;
    final profilePhotoPath =
        ref.watch(profileImagePathProvider(userId)).valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 12, 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => showSenderNotificationsSheet(context, ref, userId),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: titleColor.withValues(alpha: 0.88),
                      size: 26,
                    ),
                    if (unreadCount > 0)
                      const Positioned(
                        right: 4,
                        top: 4,
                        child: PulsingNotificationDot(size: 10),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              l10n.roleSender.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTheme.panelTopBarTitle(titleColor),
            ),
          ),
          MenuAnchor(
            menuChildren: buildHomeOverflowMenuChildren(
              context: context,
              ref: ref,
              theme: theme,
              l10n: l10n,
              currentLocale: currentLocale,
              onLogout: onLogout,
              senderNotificationsUserId: userId,
              senderUnreadNotificationCount: unreadCount,
            ),
            builder: (context, menuController, _) {
              return Tooltip(
                message: l10n.createJobMenuMore,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      if (menuController.isOpen) {
                        menuController.close();
                      } else {
                        menuController.open();
                      }
                    },
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: PremiumMonogramAvatar(
                          initial: menuInitial,
                          profileImagePath: profilePhotoPath,
                          overlayTopRight: unreadCount > 0
                              ? const PulsingNotificationDot(size: 11)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _senderMenuInitial(String displayNameFormatted) {
  final t = displayNameFormatted.trim();
  if (t.isEmpty) return '?';
  return String.fromCharCode(t.runes.first).toUpperCase();
}
