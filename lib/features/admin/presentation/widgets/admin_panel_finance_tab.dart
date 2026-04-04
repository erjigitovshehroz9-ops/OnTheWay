import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import 'admin_panel_charts.dart';
import 'admin_section_title.dart';
import 'admin_surface_card.dart';

class AdminPanelFinanceTab extends StatelessWidget {
  const AdminPanelFinanceTab({super.key});

  static List<FlSpot> _sparkA() => const [
        FlSpot(0, 2),
        FlSpot(1, 2.8),
        FlSpot(2, 2.4),
        FlSpot(3, 3.6),
        FlSpot(4, 3.2),
        FlSpot(5, 4.1),
        FlSpot(6, 3.9),
      ];

  static List<FlSpot> _sparkB() => const [
        FlSpot(0, 1.2),
        FlSpot(1, 1.5),
        FlSpot(2, 1.1),
        FlSpot(3, 1.8),
        FlSpot(4, 1.6),
        FlSpot(5, 2),
        FlSpot(6, 1.9),
      ];

  static List<FlSpot> _sparkC() => const [
        FlSpot(0, 3),
        FlSpot(1, 3.4),
        FlSpot(2, 3.1),
        FlSpot(3, 4),
        FlSpot(4, 3.7),
        FlSpot(5, 4.2),
        FlSpot(6, 4.5),
      ];

  static List<FlSpot> _sparkD() => const [
        FlSpot(0, 0.8),
        FlSpot(1, 1),
        FlSpot(2, 0.9),
        FlSpot(3, 1.2),
        FlSpot(4, 1.1),
        FlSpot(5, 1.4),
        FlSpot(6, 1.3),
      ];

  static List<FlSpot> _sparkE() => const [
        FlSpot(0, 2.2),
        FlSpot(1, 2),
        FlSpot(2, 2.5),
        FlSpot(3, 2.3),
        FlSpot(4, 2.8),
        FlSpot(5, 2.6),
        FlSpot(6, 3),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final rows =
        <({String title, String value, IconData icon, Color accent, List<FlSpot> spots})>[
      (
        title: l10n.adminFinanceTotalRevenue,
        value: '150 000 000 soʻm',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF22C55E),
        spots: _sparkA(),
      ),
      (
        title: l10n.adminFinanceCommissions,
        value: '11 537 000 soʻm',
        icon: Icons.percent_rounded,
        accent: const Color(0xFF3B82F6),
        spots: _sparkB(),
      ),
      (
        title: l10n.adminFinanceSuccessfulPayments,
        value: '13 788 000 soʻm',
        icon: Icons.payments_outlined,
        accent: const Color(0xFF8B5CF6),
        spots: _sparkC(),
      ),
      (
        title: l10n.adminFinanceCourierPayouts,
        value: '300 000 soʻm',
        icon: Icons.account_balance_wallet_outlined,
        accent: const Color(0xFFF59E0B),
        spots: _sparkD(),
      ),
      (
        title: l10n.adminFinancePendingPayouts,
        value: '2 400 000 soʻm',
        icon: Icons.schedule_rounded,
        accent: const Color(0xFFEA580C),
        spots: _sparkE(),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        AdminSectionTitle(title: l10n.adminFinanceSectionTitle),
        const SizedBox(height: 8),
        Text(
          l10n.adminFinanceDemoHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
              ),
        ),
        const SizedBox(height: 14),
        for (final r in rows) ...[
          AdminSurfaceCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: r.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(r.icon, color: r.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.value,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                      ),
                    ],
                  ),
                ),
                AdminMiniSparkline(color: r.accent, spots: r.spots),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
