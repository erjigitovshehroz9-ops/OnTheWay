import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

class AdminOrderMixChart extends StatelessWidget {
  const AdminOrderMixChart({
    super.key,
    required this.l10n,
    required this.totalJobs,
    required this.completed,
    required this.inProgress,
    required this.cancelled,
  });

  final AppLocalizations l10n;
  final int totalJobs;
  final int completed;
  final int inProgress;
  final int cancelled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (totalJobs <= 0) {
      return const SizedBox.shrink();
    }

    final c = completed.clamp(0, totalJobs);
    final p = inProgress.clamp(0, totalJobs);
    final x = cancelled.clamp(0, totalJobs);
    final sum = c + p + x;
    final scale = sum > 0 ? totalJobs / sum : 1.0;
    final fc = (c * scale).round();
    final fp = (p * scale).round();
    final fx = (x * scale).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stacked_bar_chart_rounded,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.adminChartOrderStatus,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  _segment(
                    flex: fc,
                    color: const Color(0xFF22C55E),
                  ),
                  _segment(
                    flex: fp,
                    color: scheme.primary,
                  ),
                  _segment(
                    flex: fx,
                    color: scheme.error,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _LegendDot(
                color: const Color(0xFF22C55E),
                label: l10n.chartLegendCompleted,
                value: completed,
              ),
              _LegendDot(
                color: scheme.primary,
                label: l10n.chartLegendActive,
                value: inProgress,
              ),
              _LegendDot(
                color: scheme.error,
                label: l10n.chartLegendCancelled,
                value: cancelled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment({required int flex, required Color color}) {
    if (flex <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: flex,
      child: ColoredBox(color: color),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
