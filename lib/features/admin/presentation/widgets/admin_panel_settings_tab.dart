import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/language_switcher_button.dart';
import 'admin_section_title.dart';
import 'admin_surface_card.dart';

class AdminPanelSettingsTab extends ConsumerWidget {
  const AdminPanelSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        AdminSectionTitle(title: l10n.adminSettingsSectionShortcuts),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.bar_chart_rounded,
          title: l10n.adminOpenStatistics,
          subtitle: l10n.adminNavStatsSubtitle,
          color: const Color(0xFF1976D2),
          onTap: () => context.push(AppRoutes.adminStats),
        ),
        _SettingsTile(
          icon: Icons.map_outlined,
          title: l10n.adminOpenMap,
          subtitle: l10n.adminNavMapSubtitle,
          color: const Color(0xFFF59E0B),
          onTap: () => context.push(AppRoutes.adminMap),
        ),
        _SettingsTile(
          icon: Icons.support_agent_rounded,
          title: l10n.adminOpenContactRequests,
          subtitle: l10n.adminContactRequestsSubtitle,
          color: const Color(0xFF8B5CF6),
          onTap: () => context.push(AppRoutes.adminContactRequests),
        ),
        _SettingsTile(
          icon: Icons.tune_rounded,
          title: l10n.adminOpenFullSettings,
          subtitle: l10n.settings,
          color: const Color(0xFF64748B),
          onTap: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(height: 20),
        AdminSectionTitle(title: l10n.adminLanguageTileTitle),
        const SizedBox(height: 10),
        AdminSurfaceCard(
          child: Row(
            children: [
              const Icon(Icons.language_rounded, color: Color(0xFF1976D2)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const LanguageSwitcherButton(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AdminSurfaceCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            title: Text(
              l10n.logout,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFFDC2626),
              ),
            ),
            onTap: () async {
              final repo = await ref.read(authRepositoryProvider.future);
              await repo.logout();
              await ref.read(authSessionProvider.notifier).refresh();
            },
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AdminSurfaceCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
