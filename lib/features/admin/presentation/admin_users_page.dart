import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_primary_scaffold.dart';
import 'admin_panel_light_theme.dart';
import 'widgets/admin_users_manage_content.dart';

/// To‘liq marshrut: `/admin/users` — panel bilan bir xil kontent, alohida AppBar.
class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Theme(
      data: buildAdminPanelLightTheme(),
      child: AppPrimaryScaffold(
        title: l10n.adminUsers,
        showLanguageSwitcher: true,
        body: const AdminUsersManageContent(),
      ),
    );
  }
}
