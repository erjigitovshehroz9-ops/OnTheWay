import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/panel_bottom_nav_chrome.dart';

enum CourierBottomNavTab {
  orders,
  roleSwitch,
  wallet,
  profile,
}

/// Pastki navigatsiya: gradient fon, yuqori nozik chiziq; aktiv tab — faqat oq rang + qalin shrift.
class CourierBottomNav extends StatelessWidget {
  const CourierBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onRoleSwitch,
  });

  final CourierBottomNavTab selected;
  final ValueChanged<CourierBottomNavTab> onSelected;
  final VoidCallback onRoleSwitch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        minimum: EdgeInsets.zero,
        child: DecoratedBox(
          decoration: PanelBottomNavChrome.barDecorationOf(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
            child: SizedBox(
              height: PanelBottomNavChrome.rowHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: PanelBottomNavItem(
                      label: l10n.courierNavOrders,
                      icon: Icons.receipt_long_rounded,
                      selected: selected == CourierBottomNavTab.orders,
                      onTap: () => onSelected(CourierBottomNavTab.orders),
                    ),
                  ),
                  Expanded(
                    child: PanelBottomNavItem(
                      label: l10n.senderBottomNavSwitchRole,
                      icon: Icons.swap_horiz_rounded,
                      selected: false,
                      twoLineLabel: true,
                      onTap: onRoleSwitch,
                    ),
                  ),
                  Expanded(
                    child: PanelBottomNavItem(
                      label: l10n.bottomNavWallet,
                      icon: Icons.account_balance_wallet_outlined,
                      selected: selected == CourierBottomNavTab.wallet,
                      onTap: () => onSelected(CourierBottomNavTab.wallet),
                    ),
                  ),
                  Expanded(
                    child: PanelBottomNavItem(
                      label: l10n.profileSection,
                      icon: Icons.person_outline_rounded,
                      selected: selected == CourierBottomNavTab.profile,
                      onTap: () => onSelected(CourierBottomNavTab.profile),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
