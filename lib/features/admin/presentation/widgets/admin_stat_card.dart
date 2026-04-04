import 'package:flutter/material.dart';

enum AdminStatSemantic {
  neutral,
  active,
  warning,
  blocked,
  completed,
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.semantic,
    this.usePremiumStyle = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final AdminStatSemantic semantic;
  final bool usePremiumStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accentColor(scheme);
    final indicator = _indicatorColor(scheme);

    final decoration = usePremiumStyle
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          );

    final radius = usePremiumStyle ? 16.0 : 20.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: decoration,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.95),
                            accent.withValues(alpha: 0.55),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: indicator,
                        boxShadow: [
                          BoxShadow(
                            color: indicator.withValues(alpha: 0.55),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor(ColorScheme scheme) {
    switch (semantic) {
      case AdminStatSemantic.neutral:
        return scheme.primary;
      case AdminStatSemantic.active:
        return scheme.primary;
      case AdminStatSemantic.warning:
        return const Color(0xFFF59E0B);
      case AdminStatSemantic.blocked:
        return scheme.error;
      case AdminStatSemantic.completed:
        return const Color(0xFF22C55E);
    }
  }

  Color _indicatorColor(ColorScheme scheme) {
    switch (semantic) {
      case AdminStatSemantic.neutral:
        return scheme.primary;
      case AdminStatSemantic.active:
        return scheme.primary;
      case AdminStatSemantic.warning:
        return const Color(0xFFF59E0B);
      case AdminStatSemantic.blocked:
        return scheme.error;
      case AdminStatSemantic.completed:
        return const Color(0xFF22C55E);
    }
  }
}
