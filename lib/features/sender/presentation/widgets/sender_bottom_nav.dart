import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme_tokens.dart';

enum SenderBottomNavTab {
  orders,
  roleSwitch,
  wallet,
  profile,
}

/// Yuboruvchi pastki bar — ko‘k brend gradient (yorug‘/qorong‘i rejimga moslashadi).
class SenderBottomNav extends StatelessWidget {
  const SenderBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onRoleSwitch,
  });

  final SenderBottomNavTab selected;
  final ValueChanged<SenderBottomNavTab> onSelected;
  final VoidCallback onRoleSwitch;

  static const _bottomRadius = 24.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? [
            t.brandPrimarySoft.withValues(alpha: 0.85),
            const Color(0xFF1E3A8A),
            t.brandPrimary,
          ]
        : [
            const Color(0xFF0F2744),
            t.brandPrimaryHover,
            t.senderAccent,
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(_bottomRadius),
          bottomRight: Radius.circular(_bottomRadius),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: t.brandPrimary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: t.shadow,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(2, 7, 2, bottomInset > 0 ? bottomInset + 4 : 11),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                label: 'Buyurtmalar',
                icon: Icons.receipt_long_rounded,
                selected: selected == SenderBottomNavTab.orders,
                onTap: () => onSelected(SenderBottomNavTab.orders),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Rol almashtirish',
                icon: Icons.swap_horiz_rounded,
                selected: false,
                twoLineLabel: true,
                onTap: onRoleSwitch,
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Hamyon',
                icon: Icons.account_balance_wallet_outlined,
                selected: selected == SenderBottomNavTab.wallet,
                onTap: () => onSelected(SenderBottomNavTab.wallet),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Profil',
                icon: Icons.person_outline_rounded,
                selected: selected == SenderBottomNavTab.profile,
                onTap: () => onSelected(SenderBottomNavTab.profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.twoLineLabel = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool twoLineLabel;

  @override
  Widget build(BuildContext context) {
    const active = Colors.white;
    final inactive = Colors.white.withValues(alpha: 0.58);
    final labelUnselected = Colors.white.withValues(alpha: 0.72);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Colors.white.withValues(alpha: 0.42) : Colors.transparent,
                      width: selected ? 1.2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected ? active : inactive,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: twoLineLabel ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: selected ? active : labelUnselected,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: selected
                      ? (twoLineLabel ? 13.5 : 16)
                      : (twoLineLabel ? 11.5 : 12.5),
                  height: twoLineLabel ? 1.15 : 1.22,
                  letterSpacing: selected ? 0.08 : 0.02,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
