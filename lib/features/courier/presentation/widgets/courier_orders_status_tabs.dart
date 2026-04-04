import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// Kuryer buyurtmalar: Ro'yxat (auksionlar) / Jarayonda / Bajarilgan.
/// Tanlangan tab — pastki Ro'yxat/Xarita pill bilan bir xil yorqin ko'rinish.
class CourierOrdersStatusTabs extends StatelessWidget {
  const CourierOrdersStatusTabs({
    super.key,
    required this.l10n,
    required this.selectedIndex,
    required this.counts,
    required this.onSelect,
  }) : assert(counts.length == 3);

  final AppLocalizations l10n;
  final int selectedIndex;
  final List<int> counts;
  final ValueChanged<int> onSelect;

  static const _mint = Color(0xFF22D3EE);
  static const _pillFg = Color(0xFF0C4A6E);

  Color _accent(int i) {
    switch (i) {
      case 0:
        return _mint;
      case 1:
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF4ADE80);
    }
  }

  Color _labelOnAccent(int i) {
    if (i == 2) return const Color(0xFF022C22);
    return _pillFg;
  }

  List<String> _labels(AppLocalizations l) => [
        l.courierOrdersTabAuction,
        l.courierOrdersTabInProgress,
        l.courierOrdersTabCompleted,
      ];

  @override
  Widget build(BuildContext context) {
    final labels = _labels(l10n);
    return Row(
      children: List.generate(3, (i) {
        final selected = selectedIndex == i;
        final accent = _accent(i);
        final fg = selected ? _labelOnAccent(i) : Colors.white.withValues(alpha: 0.82);
        final badgeFg =
            selected ? _labelOnAccent(i) : Colors.white.withValues(alpha: 0.72);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(12),
                splashColor: accent.withValues(alpha: 0.2),
                highlightColor: accent.withValues(alpha: 0.08),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? accent
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? accent.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.22),
                      width: selected ? 1.2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.55),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: Offset.zero,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: fg,
                          letterSpacing: -0.2,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.45)
                                : Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          '${counts[i]}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: badgeFg,
                            height: 1,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
