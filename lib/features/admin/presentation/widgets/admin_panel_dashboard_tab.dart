import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/debug/provider_error_screen.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/admin_operational_snapshot_provider.dart';
import '../../application/admin_stats_provider.dart';
import 'admin_dashboard_control_center.dart';
import 'admin_order_mix_chart.dart';
import 'admin_panel_charts.dart';
import 'admin_section_title.dart';

class AdminPanelDashboardTab extends ConsumerWidget {
  const AdminPanelDashboardTab({super.key, required this.onSwitchTab});

  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(adminStatsProvider);

    return stats.when(
      data: (s) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            AdminSectionTitle(title: l10n.adminSectionOverview),
            const SizedBox(height: 8),
            const AdminDashboardControlCenter(),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 520;
                final cancelCard = _WideAlertCard(
                  title: l10n.statCancelled,
                  value: s.cancelledJobs.toString(),
                  icon: Icons.cancel_outlined,
                  accent: const Color(0xFFE11D48),
                );
                final complaintCard = _WideAlertCard(
                  title: l10n.statComplaints,
                  value: s.complaints.toString(),
                  icon: Icons.report_gmailerrorred_outlined,
                  accent: const Color(0xFFEA580C),
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cancelCard),
                      const SizedBox(width: 10),
                      Expanded(child: complaintCard),
                    ],
                  );
                }
                return Column(
                  children: [
                    cancelCard,
                    const SizedBox(height: 10),
                    complaintCard,
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            AdminSectionTitle(title: l10n.adminAnalyticsSectionTitle),
            const SizedBox(height: 6),
            Text(
              l10n.adminDesignSampleChartNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
            const SizedBox(height: 12),
            _PremiumChartCard(
              child: AdminDeliveryLineChart(stats: s, l10n: l10n),
            ),
            const SizedBox(height: 12),
            _PremiumChartCard(
              child: AdminUsersCourierBarChart(stats: s, l10n: l10n),
            ),
            const SizedBox(height: 12),
            _PremiumChartCard(
              child: AdminOrderMixDonutChart(stats: s, l10n: l10n),
            ),
            const SizedBox(height: 8),
            AdminSectionTitle(title: l10n.adminChartOrderStatus),
            const SizedBox(height: 8),
            AdminOrderMixChart(
              l10n: l10n,
              totalJobs: s.jobs,
              completed: s.completedJobs,
              inProgress: s.inProgressJobs,
              cancelled: s.cancelledJobs,
            ),
            const SizedBox(height: 18),
            AdminSectionTitle(title: l10n.adminRegionPerformanceTitle),
            const SizedBox(height: 6),
            Text(
              l10n.adminRegionPerformanceHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
            const SizedBox(height: 10),
            const _RegionHeatPreview(),
            const SizedBox(height: 20),
            AdminSectionTitle(title: l10n.adminQuickActionsTitle),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: [
                _QuickGridTile(
                  icon: Icons.person_add_alt_1_outlined,
                  label: l10n.adminGridAddAdmin,
                  color: const Color(0xFF1976D2),
                  onTap: () => onSwitchTab(2),
                ),
                _QuickGridTile(
                  icon: Icons.admin_panel_settings_outlined,
                  label: l10n.adminGridManageRoles,
                  color: const Color(0xFF7C3AED),
                  onTap: () => onSwitchTab(2),
                ),
                _QuickGridTile(
                  icon: Icons.assessment_outlined,
                  label: l10n.adminGridViewReports,
                  color: const Color(0xFF0D9488),
                  onTap: () => context.push(AppRoutes.adminStats),
                ),
                _QuickGridTile(
                  icon: Icons.block_rounded,
                  label: l10n.adminGridBlockUser,
                  color: const Color(0xFFDC2626),
                  onTap: () => onSwitchTab(2),
                ),
                _QuickGridTile(
                  icon: Icons.verified_user_outlined,
                  label: l10n.adminGridApproveCourier,
                  color: const Color(0xFF16A34A),
                  onTap: () => onSwitchTab(2),
                ),
                _QuickGridTile(
                  icon: Icons.gavel_rounded,
                  label: l10n.adminGridMonitorAuctions,
                  color: const Color(0xFFF59E0B),
                  onTap: () => onSwitchTab(1),
                ),
                _QuickGridTile(
                  icon: Icons.settings_outlined,
                  label: l10n.adminGridSystemSettings,
                  color: const Color(0xFF64748B),
                  onTap: () => context.push(AppRoutes.settings),
                ),
                _QuickGridTile(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.adminBottomNavOrders,
                  color: const Color(0xFF2563EB),
                  onTap: () => onSwitchTab(1),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ProviderErrorScreen(
        error: error,
        stackTrace: stack,
        onRetry: () {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(adminOperationalSnapshotProvider);
          ref.invalidate(appDatabaseProvider);
        },
      ),
    );
  }
}

class _PremiumChartCard extends StatelessWidget {
  const _PremiumChartCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WideAlertCard extends StatelessWidget {
  const _WideAlertCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
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

class _QuickGridTile extends StatelessWidget {
  const _QuickGridTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionHeatPreview extends StatelessWidget {
  const _RegionHeatPreview();

  @override
  Widget build(BuildContext context) {
    const cols = 8;
    const rows = 5;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                                const Color(0xFFEF4444),
                                const Color(0xFF22C55E),
                                ((r * cols + c) % 10) / 10,
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
