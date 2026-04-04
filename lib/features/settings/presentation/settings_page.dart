import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/user_role.dart';
import '../../../shared/flow/courier_role_switch_flow.dart';
import '../../../shared/widgets/app_theme_picker_sheet.dart';
import '../../../shared/widgets/role_switch_confirm_dialog.dart';
import '../../sender/application/sender_jobs_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _switchingRole = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final user = ref.watch(authSessionProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: Center(child: Text(l10n.signInRequired)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.profileSection,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(user.displayName),
                  Text(user.phone),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.createJobThemeTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
              title: Text(l10n.createJobMenuChangeTheme),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showAppThemeBottomSheet(context),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.chooseRoleTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: user.role == UserRole.admin
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.admin_panel_settings_outlined),
                          title: Text(l10n.roleAdmin),
                          subtitle: Text(l10n.roleAdminDesc),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.chooseRoleTitle,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Chip(
                              label: Text(
                                (user.role ?? UserRole.sender) == UserRole.sender
                                    ? l10n.roleSender
                                    : l10n.roleCourier,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _RoleChoiceCard(
                          title: l10n.roleSender,
                          subtitle: l10n.roleSenderDesc,
                          icon: Icons.inventory_2_outlined,
                          selected:
                              (user.role ?? UserRole.sender) == UserRole.sender,
                          busy: _switchingRole,
                          onTap: () => _onRoleTap(
                            context: context,
                            l10n: l10n,
                            userId: user.id,
                            currentRole: user.role ?? UserRole.sender,
                            nextRole: UserRole.sender,
                            callerIsSystemAdmin: user.isSystemAdmin,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _RoleChoiceCard(
                          title: l10n.roleCourier,
                          subtitle: l10n.roleCourierDesc,
                          icon: Icons.local_shipping_outlined,
                          selected:
                              (user.role ?? UserRole.sender) == UserRole.courier,
                          busy: _switchingRole,
                          onTap: () => _onRoleTap(
                            context: context,
                            l10n: l10n,
                            userId: user.id,
                            currentRole: user.role ?? UserRole.sender,
                            nextRole: UserRole.courier,
                            callerIsSystemAdmin: user.isSystemAdmin,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (user.role == UserRole.courier) ...[
            const SizedBox(height: 20),
            Text(
              l10n.courierHomeTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _RegionDistrictCard(
              userId: user.id,
              locale: locale,
            ),
          ],
          if (user.canAccessAdminPanel) ...[
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  context.push(AppRoutes.admin);
                });
              },
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: Text(l10n.openAdminPanel),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onRoleTap({
    required BuildContext context,
    required AppLocalizations l10n,
    required String userId,
    required UserRole currentRole,
    required UserRole nextRole,
    required bool callerIsSystemAdmin,
  }) async {
    if (_switchingRole) return;
    if (nextRole == currentRole) return;
    if (nextRole == UserRole.admin) return;

    final router = GoRouter.of(context);
    final ok = await showRoleSwitchConfirmDialog(
      context: context,
      title: 'Rolni almashtirmoqchimisiz?',
      contentLine:
          '${currentRole == UserRole.sender ? l10n.roleSender : l10n.roleCourier}'
          ' → '
          '${nextRole == UserRole.sender ? l10n.roleSender : l10n.roleCourier}',
    );
    if (ok != true) return;
    if (!context.mounted) return;

    setState(() => _switchingRole = true);
    try {
      if (nextRole == UserRole.courier) {
        final switched = await ensureCourierTransportAndSwitchRole(
          ref: ref,
          userId: userId,
          callerIsSystemAdmin: callerIsSystemAdmin,
        );
        if (!context.mounted) return;
        if (!switched) return;
        router.go(AppRoutes.courier);
      } else {
        await _switchRole(
          ref,
          userId,
          nextRole,
          callerIsSystemAdmin,
        );
        if (!context.mounted) return;
        router.go(AppRoutes.sender);
      }
    } finally {
      if (mounted) setState(() => _switchingRole = false);
    }
  }

  static Future<void> _switchRole(
    WidgetRef ref,
    String userId,
    UserRole role,
    bool isSystemAdmin,
  ) async {
    debugPrint('[settings] role switch requested: user=$userId role=${role.storageValue}');
    if (role == UserRole.admin) {
      throw StateError('admin_role_forbidden');
    }
    final users = await ref.read(userRepositoryProvider.future);
    await users.switchAppRole(
      userId: userId,
      newRole: role,
      callerIsSystemAdmin: isSystemAdmin,
    );
    await ref.read(authSessionProvider.notifier).refresh();
    ref.invalidate(courierJobsProvider);
    ref.invalidate(senderJobsProvider(userId));
  }
}

class _RegionDistrictCard extends ConsumerStatefulWidget {
  const _RegionDistrictCard({
    required this.userId,
    required this.locale,
  });

  final String userId;
  final Locale locale;

  @override
  ConsumerState<_RegionDistrictCard> createState() =>
      _RegionDistrictCardState();
}

class _RegionDistrictCardState extends ConsumerState<_RegionDistrictCard> {
  String? _region;
  String? _district;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authSessionProvider).valueOrNull;
    _region = u?.regionCode;
    _district = u?.districtCode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final regionsAsync = ref.watch(regionsListProvider);

    return regionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('$e'),
      data: (regions) {
        final rCode = _region ?? (regions.isNotEmpty ? regions.first.code : '');

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.regionLabel),
                DropdownButtonFormField<String>(
                  value: rCode.isEmpty ? null : rCode,
                  items: regions
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.code,
                          child: Text(r.name.resolveLang(widget.locale.languageCode)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _region = v;
                    _district = null;
                  }),
                ),
                const SizedBox(height: 12),
                if (rCode.isEmpty)
                  const SizedBox.shrink()
                else
                  _SettingsDistrictDropdown(
                    key: ValueKey<String>(rCode),
                    regionCode: rCode,
                    locale: widget.locale,
                    l10n: l10n,
                    selectedDistrict: _district,
                    onDistrictChanged: (v) => setState(() => _district = v),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: (_region == null ||
                          _region!.isEmpty ||
                          _district == null ||
                          _district!.isEmpty)
                      ? null
                      : () async {
                          final users =
                              await ref.read(userRepositoryProvider.future);
                          await users.setCourierServiceArea(
                            userId: widget.userId,
                            regionCode: _region!,
                            districtCode: _district!,
                          );
                          await ref
                              .read(authSessionProvider.notifier)
                              .refresh();
                          ref.invalidate(courierJobsProvider);
                          ref.read(courierRegionCodeProvider.notifier).state =
                              _region;
                          ref.read(courierDistrictCodeProvider.notifier).state =
                              _district;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.save)),
                            );
                          }
                        },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// `ref.watch` faqat [build] yuzasida — `.when` ichida emas (Riverpod / InheritedWidget xatolari).
class _SettingsDistrictDropdown extends ConsumerWidget {
  const _SettingsDistrictDropdown({
    super.key,
    required this.regionCode,
    required this.locale,
    required this.l10n,
    required this.selectedDistrict,
    required this.onDistrictChanged,
  });

  final String regionCode;
  final Locale locale;
  final AppLocalizations l10n;
  final String? selectedDistrict;
  final ValueChanged<String?> onDistrictChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distAsync = ref.watch(districtsForRegionProvider(regionCode));
    return distAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => Text('$e'),
      data: (districts) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.districtLabel),
            DropdownButtonFormField<String>(
              value: selectedDistrict ??
                  (districts.isNotEmpty ? districts.first.code : null),
              items: districts
                  .map(
                    (d) => DropdownMenuItem(
                      value: d.code,
                      child: Text(d.name.resolveLang(locale.languageCode)),
                    ),
                  )
                  .toList(),
              onChanged: onDistrictChanged,
            ),
          ],
        );
      },
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.busy,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = selected ? cs.primary : Theme.of(context).dividerColor;
    final bg = selected ? cs.primaryContainer : cs.surface;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurface;

    return Opacity(
      opacity: busy ? 0.7 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: busy ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: bg,
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: selected ? fg : cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (busy && selected)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (selected)
                Icon(Icons.check_circle_rounded, color: cs.primary)
              else
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
