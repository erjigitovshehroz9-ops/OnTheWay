import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/app_user.dart';
import '../../../../models/order_feedback_entity.dart';
import '../../../../models/order_feedback_type.dart';
import '../../application/admin_operational_snapshot_provider.dart';
import '../../application/admin_users_list_provider.dart';
import 'admin_section_title.dart';
import 'admin_surface_card.dart';

class AdminPanelFeedbackTab extends ConsumerStatefulWidget {
  const AdminPanelFeedbackTab({super.key});

  @override
  ConsumerState<AdminPanelFeedbackTab> createState() =>
      _AdminPanelFeedbackTabState();
}

class _AdminPanelFeedbackTabState extends ConsumerState<AdminPanelFeedbackTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _lowRating = false;
  bool _senderToCourier = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final df = DateFormat.yMMMd(locale.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: AdminSectionTitle(title: l10n.adminFeedbackSectionTitle),
        ),
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: l10n.adminFeedbackTabComplaints),
            Tab(text: l10n.adminFeedbackTabAll),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ComplaintsList(l10n: l10n, df: df),
              _AllFeedbackList(
                l10n: l10n,
                df: df,
                lowRating: _lowRating,
                senderToCourier: _senderToCourier,
                onLowRating: (v) => setState(() => _lowRating = v),
                onSenderToCourier: (v) => setState(() => _senderToCourier = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComplaintsList extends ConsumerWidget {
  const _ComplaintsList({required this.l10n, required this.df});

  final AppLocalizations l10n;
  final DateFormat df;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminComplaintsListProvider);
    final usersAsync = ref.watch(adminUsersListProvider);
    final names = _nameMap(usersAsync.valueOrNull);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              l10n.adminNoJobsInList,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final f = list[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FeedbackTile(
                f: f,
                l10n: l10n,
                df: df,
                fromName: names[f.fromUserId] ?? f.fromUserId,
                toName: names[f.toUserId] ?? f.toUserId,
                trailing: f.feedbackType == OrderFeedbackType.complaint
                    ? TextButton(
                        onPressed: () => _openModeration(context, ref, f),
                        child: Text(l10n.adminComplaintReview),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _AllFeedbackList extends ConsumerWidget {
  const _AllFeedbackList({
    required this.l10n,
    required this.df,
    required this.lowRating,
    required this.senderToCourier,
    required this.onLowRating,
    required this.onSenderToCourier,
  });

  final AppLocalizations l10n;
  final DateFormat df;
  final bool lowRating;
  final bool senderToCourier;
  final ValueChanged<bool> onLowRating;
  final ValueChanged<bool> onSenderToCourier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      adminFeedbackAllListProvider(
        (lowRating: lowRating, senderToCourier: senderToCourier),
      ),
    );
    final usersAsync = ref.watch(adminUsersListProvider);
    final names = _nameMap(usersAsync.valueOrNull);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: AdminSurfaceCard(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(l10n.adminFeedbackLowRating),
                  selected: lowRating,
                  onSelected: onLowRating,
                ),
                FilterChip(
                  label: Text(l10n.adminFeedbackSenderToCourier),
                  selected: senderToCourier,
                  onSelected: onSenderToCourier,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    l10n.adminNoJobsInList,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final f = list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FeedbackTile(
                      f: f,
                      l10n: l10n,
                      df: df,
                      fromName: names[f.fromUserId] ?? f.fromUserId,
                      toName: names[f.toUserId] ?? f.toUserId,
                      trailing: f.feedbackType == OrderFeedbackType.complaint
                          ? TextButton(
                              onPressed: () => _openModeration(context, ref, f),
                              child: Text(l10n.adminComplaintReview),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

Map<String, String> _nameMap(List<AppUser>? users) {
  final m = <String, String>{};
  if (users == null) return m;
  for (final u in users) {
    m[u.id] = u.displayName;
  }
  return m;
}

class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({
    required this.f,
    required this.l10n,
    required this.df,
    required this.fromName,
    required this.toName,
    this.trailing,
  });

  final OrderFeedbackEntity f;
  final AppLocalizations l10n;
  final DateFormat df;
  final String fromName;
  final String toName;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final typeLabel = f.feedbackType == OrderFeedbackType.complaint
        ? 'complaint'
        : f.feedbackType == OrderFeedbackType.praise
            ? 'praise'
            : 'rating';
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      context.push(AppRoutes.jobDetail(f.orderId)),
                  child: Text(
                    f.orderId.length > 10
                        ? '${f.orderId.substring(0, 8)}…'
                        : f.orderId,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          Text(
            '$typeLabel · ${f.rating}★ · ${df.format(f.createdAt)}',
            style: t.bodySmall?.copyWith(color: const Color(0xFF64748B)),
          ),
          if (f.complaintStatus != null && f.complaintStatus!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.adminComplaintStatusLabel}: ${f.complaintStatus}',
              style: t.labelMedium,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${l10n.adminMetaFrom}: $fromName  →  ${l10n.adminMetaTo}: $toName',
            style: t.bodySmall,
          ),
          Text(
            '${f.fromRole} → ${f.toRole}',
            style: t.bodySmall?.copyWith(color: const Color(0xFF64748B)),
          ),
          if (f.complaintCategory != null &&
              f.complaintCategory!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              f.complaintCategory!.trim(),
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          if (f.comment != null && f.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(f.comment!.trim(), style: t.bodyMedium),
          ],
        ],
      ),
    );
  }
}

Future<void> _openModeration(
  BuildContext context,
  WidgetRef ref,
  OrderFeedbackEntity f,
) async {
  final l10n = AppLocalizations.of(context);
  final me = ref.read(authSessionProvider).valueOrNull;
  if (me == null) return;

  final result = await showDialog<(String, String?)?>(
    context: context,
    builder: (ctx) => _ComplaintModerationDialog(
      l10n: l10n,
      initialStatus: f.complaintStatus ?? 'new',
      initialNote: f.adminNote ?? '',
    ),
  );

  if (result == null || !context.mounted) return;

  final db = await ref.read(appDatabaseProvider.future);
  await db.updateOrderFeedbackModeration(
    feedbackId: f.id,
    complaintStatus: result.$1,
    adminNote: result.$2,
    reviewedByUserId: me.id,
  );

  ref.invalidate(adminComplaintsListProvider);
  invalidateAdminFeedbackListFamily(ref);
  ref.invalidate(adminOperationalSnapshotProvider);
}

class _ComplaintModerationDialog extends StatefulWidget {
  const _ComplaintModerationDialog({
    required this.l10n,
    required this.initialStatus,
    required this.initialNote,
  });

  final AppLocalizations l10n;
  final String initialStatus;
  final String initialNote;

  @override
  State<_ComplaintModerationDialog> createState() =>
      _ComplaintModerationDialogState();
}

class _ComplaintModerationDialogState extends State<_ComplaintModerationDialog> {
  late String _status;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    if (_status != 'new' &&
        _status != 'reviewed' &&
        _status != 'resolved') {
      _status = 'new';
    }
    _note = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.adminComplaintReview),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.adminComplaintStatusLabel),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _status,
              items: [
                DropdownMenuItem(
                  value: 'new',
                  child: Text(l10n.adminComplaintStatusNew),
                ),
                DropdownMenuItem(
                  value: 'reviewed',
                  child: Text(l10n.adminComplaintStatusReviewed),
                ),
                DropdownMenuItem(
                  value: 'resolved',
                  child: Text(l10n.adminComplaintStatusResolved),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.adminComplaintNoteLabel,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            final t = _note.text.trim();
            Navigator.pop(
              context,
              (_status, t.isEmpty ? null : t),
            );
          },
          child: Text(l10n.adminComplaintSave),
        ),
      ],
    );
  }
}
