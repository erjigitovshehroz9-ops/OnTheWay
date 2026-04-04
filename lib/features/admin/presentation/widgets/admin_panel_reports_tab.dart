import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/admin_stats_provider.dart';
import 'admin_panel_charts.dart';
import 'admin_section_title.dart';
import 'admin_surface_card.dart';

class AdminPanelReportsTab extends ConsumerWidget {
  const AdminPanelReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(adminStatsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        AdminSectionTitle(title: l10n.adminReportsSectionTitle),
        const SizedBox(height: 12),
        stats.when(
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSurfaceCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.report_gmailerrorred_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 36,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.statComplaints,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.complaints}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFEA580C),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ReportTypeTile(
                icon: Icons.people_outline_rounded,
                title: l10n.adminReportSenderCourierComplaints,
                accent: const Color(0xFF1976D2),
                onTap: () => context.push(AppRoutes.adminContactRequests),
              ),
              const SizedBox(height: 8),
              _ReportTypeTile(
                icon: Icons.flag_outlined,
                title: l10n.adminReportFlaggedOrders,
                accent: const Color(0xFFF59E0B),
                onTap: () => context.push(AppRoutes.adminContactRequests),
              ),
              const SizedBox(height: 8),
              _ReportTypeTile(
                icon: Icons.priority_high_rounded,
                title: l10n.adminReportUrgentHighlights,
                accent: const Color(0xFFE11D48),
                highlight: true,
                onTap: () => context.push(AppRoutes.adminContactRequests),
              ),
            ],
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.adminQuickActionsTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ReportAction(
              label: l10n.adminActionQuickResolve,
              color: const Color(0xFF22C55E),
              onTap: () => context.push(AppRoutes.adminContactRequests),
            ),
            _ReportAction(
              label: l10n.adminActionReject,
              color: const Color(0xFFDC2626),
              onTap: () => context.push(AppRoutes.adminContactRequests),
            ),
            _ReportAction(
              label: l10n.adminActionInvestigate,
              color: const Color(0xFF3B82F6),
              onTap: () => context.push(AppRoutes.adminContactRequests),
            ),
          ],
        ),
        const SizedBox(height: 20),
        stats.when(
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AdminDistrictBarChart(stats: s, l10n: l10n),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.adminOrderHotspotsTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    leading: const Icon(Icons.map_outlined, color: Color(0xFF1976D2)),
                    title: Text(
                      'Toshkent · ${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(l10n.adminRegionPerformanceHint),
                    onTap: () => context.push(AppRoutes.adminMap),
                  ),
                ),
              ),
              Text(
                l10n.adminCourierAvailabilityTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const _CourierHeatGrid(),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ReportTypeTile extends StatelessWidget {
  const _ReportTypeTile({
    required this.icon,
    required this.title,
    required this.accent,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: highlight
                ? const Color(0xFFFEE2E2)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourierHeatGrid extends StatelessWidget {
  const _CourierHeatGrid();

  @override
  Widget build(BuildContext context) {
    const cols = 6;
    const rows = 4;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          for (var r = 0; r < rows; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (var c = 0; c < cols; c++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Color.lerp(
                                const Color(0xFF22C55E),
                                const Color(0xFFEF4444),
                                ((r * cols + c) % 8) / 8,
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

class _ReportAction extends StatelessWidget {
  const _ReportAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}
