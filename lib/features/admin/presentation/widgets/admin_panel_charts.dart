import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/admin_stats_provider.dart';

/// Yetkazib berish dinamikasi — statistikaga moslangan egri chiziq.
class AdminDeliveryLineChart extends StatelessWidget {
  const AdminDeliveryLineChart({
    super.key,
    required this.stats,
    required this.l10n,
  });

  final AdminStats stats;
  final AppLocalizations l10n;

  List<FlSpot> _spots() {
    final seed = (stats.jobs + stats.activeJobs + stats.users).toDouble();
    final base = math.max(6, seed * 0.08);
    return List.generate(12, (i) {
      final t = i / 11;
      final wave = 0.55 + 0.45 * math.sin(t * math.pi * 1.4);
      final bump = 1 + 0.12 * (i % 3);
      return FlSpot(i.toDouble(), base * wave * bump);
    });
  }

  @override
  Widget build(BuildContext context) {
    final spots = _spots();
    final ys = spots.map((s) => s.y).toList();
    final minY = ys.reduce(math.min) * 0.92;
    final maxY = ys.reduce(math.max) * 1.08;
    const line = Color(0xFF1976D2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adminChartDeliveryGrowth,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: line,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        line.withValues(alpha: 0.35),
                        line.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Guruhlangan ustunlar: foydalanuvchilar vs kuryerlar (namuna profil).
class AdminUsersCourierBarChart extends StatelessWidget {
  const AdminUsersCourierBarChart({
    super.key,
    required this.stats,
    required this.l10n,
  });

  final AdminStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final u = math.max(1, stats.users.toDouble());
    final c = math.max(1, stats.couriers.toDouble());
    final groups = List.generate(6, (i) {
      final f = 0.75 + (i % 3) * 0.1;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (u * f * (0.85 + i * 0.02)) / 6,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            color: const Color(0xFF1976D2),
          ),
          BarChartRodData(
            toY: (c * f * (1.1 + i * 0.03)) / 4,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            color: const Color(0xFF22C55E),
          ),
        ],
        barsSpace: 4,
      );
    });
    final maxY = groups
        .expand((g) => g.barRods)
        .map((r) => r.toY)
        .reduce(math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adminChartUsersVsCourier,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.15,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              barGroups: groups,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _LegendDot(color: const Color(0xFF1976D2), label: l10n.statTotalUsers),
            const SizedBox(width: 14),
            _LegendDot(color: const Color(0xFF22C55E), label: l10n.statCouriers),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Donut: bajarilgan / jarayon / bekor.
class AdminOrderMixDonutChart extends StatelessWidget {
  const AdminOrderMixDonutChart({
    super.key,
    required this.stats,
    required this.l10n,
  });

  final AdminStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final done = stats.completedJobs.toDouble();
    final prog = stats.inProgressJobs.toDouble();
    final canc = stats.cancelledJobs.toDouble();
    final total = done + prog + canc;
    if (total <= 0) {
      return Text(
        l10n.adminNoJobsInList,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
            ),
      );
    }

    final parts = <({double v, Color c, double fs})>[
      (v: done, c: const Color(0xFF22C55E), fs: 12),
      (v: prog, c: const Color(0xFF1976D2), fs: 11),
      (v: canc, c: const Color(0xFFE11D48), fs: 10),
    ];
    final sections = <PieChartSectionData>[];
    for (final p in parts) {
      if (p.v <= 0) continue;
      sections.add(
        PieChartSectionData(
          value: p.v,
          color: p.c,
          radius: 50,
          title: '${(p.v / total * 100).round()}%',
          titleStyle: TextStyle(
            fontSize: p.fs,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adminChartCompletionDonut,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: sections,
            ),
          ),
        ),
      ],
    );
  }
}

/// Vertikal ustunlar — hisobotlar bo‘limi uchun.
class AdminDistrictBarChart extends StatelessWidget {
  const AdminDistrictBarChart({super.key, required this.stats, required this.l10n});

  final AdminStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final base = math.max(4, stats.jobs + stats.complaints).toDouble();
    final groups = List.generate(
      8,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: base * (0.2 + (i % 4) * 0.18),
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
            ),
          ),
        ],
      ),
    );
    final maxY = groups.first.barRods.first.toY * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adminDistrictActivityTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              barGroups: groups,
            ),
          ),
        ),
      ],
    );
  }
}

/// Moliya kartalaridagi ixcham chiziq diagramma.
class AdminMiniSparkline extends StatelessWidget {
  const AdminMiniSparkline({super.key, required this.color, required this.spots});

  final Color color;
  final List<FlSpot> spots;

  @override
  Widget build(BuildContext context) {
    if (spots.length < 2) return const SizedBox(width: 72, height: 40);
    final ys = spots.map((s) => s.y).toList();
    final minY = ys.reduce(math.min) * 0.95;
    final maxY = ys.reduce(math.max) * 1.05;
    if (maxY <= minY) return const SizedBox(width: 72, height: 40);
    return SizedBox(
      width: 88,
      height: 40,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
