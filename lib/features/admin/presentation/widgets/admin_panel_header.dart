import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/language_switcher_button.dart';

class AdminPanelHeader extends ConsumerWidget {
  const AdminPanelHeader({
    super.key,
    this.onSearchTap,
    this.onNotificationTap,
  });

  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authSessionProvider).valueOrNull;
    final name = user?.displayName ?? '';
    final initials = _initials(name);

    const headerIconStyle = Color(0xFF475569);
    final softIconBg = Colors.white.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 4, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminHomeTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: const Color(0xFF0F172A),
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.adminPanelSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          const LanguageSwitcherButton(),
          IconButton(
            tooltip: l10n.adminComingSoonNotifications,
            style: IconButton.styleFrom(
              backgroundColor: softIconBg,
              foregroundColor: headerIconStyle,
            ),
            onPressed: onNotificationTap ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.adminComingSoonNotifications)),
                  );
                },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: l10n.adminSearchHint,
            style: IconButton.styleFrom(
              backgroundColor: softIconBg,
              foregroundColor: headerIconStyle,
            ),
            onPressed: onSearchTap,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: l10n.adminHeaderSettings,
            style: IconButton.styleFrom(
              backgroundColor: softIconBg,
              foregroundColor: headerIconStyle,
            ),
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.18),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F766E),
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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

  static String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return 'A';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return t.length >= 2 ? t.substring(0, 2).toUpperCase() : t[0].toUpperCase();
  }
}
