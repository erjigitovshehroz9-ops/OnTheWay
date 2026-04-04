import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/app_user.dart';
import '../../../../models/user_role.dart';
import '../../application/admin_stats_provider.dart';
import '../../application/admin_users_list_provider.dart';
import 'admin_section_title.dart';
import 'admin_surface_card.dart';

enum AdminUserFilter {
  all,
  blocked,
  complaints,
  couriers,
  senders,
  admins,
  newUsers,
  lowRating,
}

class AdminUsersManageContent extends ConsumerStatefulWidget {
  const AdminUsersManageContent({super.key});

  @override
  ConsumerState<AdminUsersManageContent> createState() =>
      _AdminUsersManageContentState();
}

class _AdminUsersManageContentState extends ConsumerState<AdminUsersManageContent> {
  late final TextEditingController _search;
  AdminUserFilter _filter = AdminUserFilter.all;
  String? _regionCode;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(authSessionProvider).valueOrNull;
    final listAsync = ref.watch(adminUsersListProvider);

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('$e')),
      data: (users) {
        final q = _search.text.trim().toLowerCase();
        final sorted = [...users]
          ..sort((a, b) => b.complaintCount.compareTo(a.complaintCount));

        final now = DateTime.now();
        final regionCodes = users
            .map((u) => u.regionCode)
            .whereType<String>()
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        final filtered = sorted.where((u) {
          final matchesQuery = q.isEmpty ||
              u.displayName.toLowerCase().contains(q) ||
              u.phone.toLowerCase().contains(q);
          if (!matchesQuery) return false;
          if (_regionCode != null && _regionCode!.trim().isNotEmpty) {
            if ((u.regionCode ?? '').trim() != _regionCode!.trim()) {
              return false;
            }
          }

          switch (_filter) {
            case AdminUserFilter.all:
              return true;
            case AdminUserFilter.blocked:
              return u.blocked;
            case AdminUserFilter.complaints:
              return u.complaintCount > 0;
            case AdminUserFilter.couriers:
              return u.role == UserRole.courier;
            case AdminUserFilter.senders:
              return u.role == UserRole.sender;
            case AdminUserFilter.admins:
              return u.role == UserRole.admin;
            case AdminUserFilter.newUsers:
              return now.difference(u.createdAt).inDays <= 7;
            case AdminUserFilter.lowRating:
              return u.rating < 3.5;
          }
        }).toList();

        if (kDebugMode) {
          debugPrint(
            '[admin] users count=${users.length} user quality rows=${filtered.length} '
            'region=${_regionCode ?? '-'} filter=$_filter',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            AdminSectionTitle(
              title: l10n.adminUserManagementTitle,
              trailing: _CountChip(count: filtered.length),
            ),
            const SizedBox(height: 12),
            AdminSurfaceCard(
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: l10n.mapSearch,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _regionCode,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: l10n.adminUserRegionFilterHint,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.adminUserRegionAll),
                      ),
                      ...regionCodes.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _regionCode = v),
                  ),
                  const SizedBox(height: 12),
                  _FilterRow(
                    selected: _filter,
                    l10n: l10n,
                    onSelect: (f) => setState(() => _filter = f),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...filtered.map(
              (u) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _UserCard(
                  user: u,
                  l10n: l10n,
                  canManageRoles: me?.isSystemAdmin == true,
                  onBlockedChanged: (v) async {
                    final repo = await ref.read(userRepositoryProvider.future);
                    await repo.setBlocked(u.id, v);
                    ref.invalidate(adminUsersListProvider);
                    ref.invalidate(adminStatsProvider);
                  },
                  onRoleChanged: me?.isSystemAdmin == true
                      ? (role) async {
                          final repo =
                              await ref.read(userRepositoryProvider.future);
                          await repo.adminSetRole(
                            targetUserId: u.id,
                            role: role,
                            setSystemAdmin:
                                role == UserRole.admin ? u.isSystemAdmin : false,
                          );
                          ref.invalidate(adminUsersListProvider);
                          ref.invalidate(adminStatsProvider);
                        }
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.primary.withValues(alpha: 0.14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        count.toString(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.l10n,
    required this.onSelect,
  });

  final AdminUserFilter selected;
  final AppLocalizations l10n;
  final ValueChanged<AdminUserFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = <(AdminUserFilter, String)>[
      (AdminUserFilter.all, l10n.adminUserFilterAll),
      (AdminUserFilter.senders, l10n.adminUserFilterSenders),
      (AdminUserFilter.couriers, l10n.adminUserFilterCouriers),
      (AdminUserFilter.blocked, l10n.adminUserFilterBlocked),
      (AdminUserFilter.newUsers, l10n.adminUserFilterNew),
      (AdminUserFilter.complaints, l10n.adminUserFilterComplaints),
      (AdminUserFilter.lowRating, l10n.adminUserFilterLowRating),
      (AdminUserFilter.admins, l10n.adminUserFilterAdmins),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _chip(context, scheme, entries[i].$1, entries[i].$2),
          ],
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    ColorScheme scheme,
    AdminUserFilter value,
    String label,
  ) {
    final isSelected = selected == value;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(label),
      onSelected: (_) => onSelect(value),
      selectedColor: scheme.primary.withValues(alpha: 0.2),
      side: BorderSide(
        color: (isSelected ? scheme.primary : scheme.outlineVariant)
            .withValues(alpha: isSelected ? 0.6 : 0.35),
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.l10n,
    required this.canManageRoles,
    required this.onBlockedChanged,
    required this.onRoleChanged,
  });

  final AppUser user;
  final AppLocalizations l10n;
  final bool canManageRoles;
  final ValueChanged<bool> onBlockedChanged;
  final ValueChanged<UserRole>? onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final role = user.role ?? UserRole.sender;
    final accent = user.blocked
        ? scheme.error
        : user.complaintCount > 0
            ? const Color(0xFFF59E0B)
            : scheme.primary;

    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarBadge(
                name: user.displayName,
                accent: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _RoleChip(role: role, blocked: user.blocked),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.blocked
                          ? scheme.error.withValues(alpha: 0.12)
                          : const Color(0xFF22C55E).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      user.blocked
                          ? l10n.adminStatusBlockedShort
                          : l10n.adminStatusActive,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: user.blocked
                            ? scheme.error
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetricPill(
                icon: Icons.star_rounded,
                label: '★ ${user.rating.toStringAsFixed(1)}',
                color: scheme.primary,
              ),
              _MetricPill(
                icon: Icons.report_gmailerrorred_outlined,
                label: '${l10n.complaint}: ${user.complaintCount}',
                color: const Color(0xFFF59E0B),
              ),
              _MetricPill(
                icon: Icons.thumb_up_alt_outlined,
                label: '${l10n.praise}: ${user.praiseCount}',
                color: const Color(0xFF22C55E),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _UserActionChip(
                label: l10n.adminActionViewList,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(user.phone)),
                  );
                },
              ),
              _UserActionChip(
                label: l10n.adminActionEditRole,
                onTap: () {
                  if (onRoleChanged == null || !canManageRoles) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.adminActionEditRole)),
                    );
                    return;
                  }
                  showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final r in UserRole.values)
                            ListTile(
                              title: Text(r.name),
                              onTap: () {
                                Navigator.pop(ctx);
                                onRoleChanged!(r);
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              _UserActionChip(
                label: l10n.adminActionBan,
                onTap: () {
                  if (!user.blocked) onBlockedChanged(true);
                },
              ),
              _UserActionChip(
                label: l10n.adminActionUnblock,
                onTap: () {
                  if (user.blocked) onBlockedChanged(false);
                },
              ),
              _UserActionChip(
                label: l10n.adminActionVerify,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.adminActionVerify)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.blockUser,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Switch.adaptive(
                value: user.blocked,
                onChanged: onBlockedChanged,
              ),
            ],
          ),
          if (canManageRoles && onRoleChanged != null) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<UserRole>(
              initialValue: role,
              decoration: InputDecoration(
                labelText: l10n.chooseRoleTitle,
                isDense: true,
              ),
              items: UserRole.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                onRoleChanged!(v);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p.isEmpty ? '' : p[0])
            .join()
            .toUpperCase();

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role, required this.blocked});

  final UserRole role;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = blocked
        ? scheme.error
        : role == UserRole.admin
            ? const Color(0xFF22C55E)
            : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        role.name,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
      ),
    );
  }
}

class _UserActionChip extends StatelessWidget {
  const _UserActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        foregroundColor: const Color(0xFF0F172A),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
