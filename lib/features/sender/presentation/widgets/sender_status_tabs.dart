import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Aktiv / Jarayonda / Tugagan — ixcham, bitta qator premium tab.
class SenderStatusTabs extends StatelessWidget {
  const SenderStatusTabs({
    super.key,
    required this.selectedIndex,
    required this.counts,
    required this.onSelect,
  }) : assert(counts.length == 3);

  final int selectedIndex;
  final List<int> counts;
  final ValueChanged<int> onSelect;

  static const _labels = ['Aktiv', 'Jarayonda', 'Tugagan'];

  Color _accent(int i) {
    switch (i) {
      case 0:
        return AppColors.primaryBlue;
      case 1:
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(3, (i) {
        final selected = selectedIndex == i;
        final accent = _accent(i);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(12),
                splashColor: accent.withValues(alpha: 0.1),
                highlightColor: accent.withValues(alpha: 0.05),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected ? accent.withValues(alpha: 0.11) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? accent.withValues(alpha: 0.42)
                          : const Color(0xFFE8EEF7),
                      width: selected ? 1.15 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: selected
                            ? accent.withValues(alpha: 0.1)
                            : const Color(0x08000000),
                        blurRadius: selected ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: selected ? accent : const Color(0xFF334155),
                          letterSpacing: -0.25,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withValues(alpha: 0.18)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? accent.withValues(alpha: 0.22)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          '${counts[i]}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: selected ? accent : const Color(0xFF475569),
                            height: 1,
                            fontSize: 10.5,
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
