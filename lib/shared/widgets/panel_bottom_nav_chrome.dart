import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme_tokens.dart';

/// Kuryer pastki navigatsiya: rejimga qarab gradient yoki yorqin premium bar.
abstract final class PanelBottomNavChrome {
  static BoxDecoration barDecorationOf(BuildContext context) {
    final t = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.navGradientTop,
            t.navGradientMid,
            t.navGradientBottom,
          ],
          stops: const [0.0, 0.52, 1.0],
        ),
        border: Border(
          top: BorderSide(color: t.navTopBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: t.navLightShadow,
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      );
    }
    return BoxDecoration(
      color: t.navBackground,
      border: Border(
        top: BorderSide(color: t.navTopBorder, width: 1),
      ),
      boxShadow: [
        BoxShadow(
          color: t.navLightShadow,
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
        BoxShadow(
          color: t.shadow,
          blurRadius: 12,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }

  static const double iconSlot = 28;
  static const double rowHeight = 62;
}

/// Kuryer pastki tab — qorong‘ida oq, yorug‘ida yashil aksent.
class PanelBottomNavItem extends StatelessWidget {
  const PanelBottomNavItem({
    super.key,
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
    final t = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color selectedColor =
        isDark ? t.textOnDark : t.courierAccent;
    final Color unselectedColor = isDark
        ? t.textOnDark.withValues(alpha: 0.58)
        : t.navUnselected;

    return Material(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: PanelBottomNavChrome.iconSlot,
                width: PanelBottomNavChrome.iconSlot,
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? selectedColor : unselectedColor,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: Text(
                  label,
                  maxLines: twoLineLabel ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: selected ? selectedColor : unselectedColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: selected ? 0.1 : 0.06,
                    fontSize: twoLineLabel ? 12 : 13,
                    height: twoLineLabel ? 1.14 : 1.18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
