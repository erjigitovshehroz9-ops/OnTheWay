import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

class AdminPanelBottomBar extends StatelessWidget {
  const AdminPanelBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <({int i, IconData icon, String label})>[
      (i: 0, icon: Icons.dashboard_outlined, label: l10n.adminBottomNavDashboard),
      (i: 1, icon: Icons.receipt_long_outlined, label: l10n.adminBottomNavOrders),
      (i: 2, icon: Icons.people_outline_rounded, label: l10n.adminBottomNavUsers),
      (i: 3, icon: Icons.feedback_outlined, label: l10n.adminBottomNavFeedback),
      (i: 4, icon: Icons.map_outlined, label: l10n.adminBottomNavRegions),
    ];

    return Material(
      elevation: 10,
      shadowColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              for (final e in items)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _NavPill(
                    selected: currentIndex == e.i,
                    icon: e.icon,
                    label: e.label,
                    onTap: () => onTap(e.i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary.withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? primary : const Color(0xFF64748B),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? primary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
