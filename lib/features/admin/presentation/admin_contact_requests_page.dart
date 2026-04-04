import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/debug/provider_error_screen.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/support_request_entity.dart';
import '../../../shared/utils/support_request_l10n.dart';
import '../../../shared/widgets/app_primary_scaffold.dart';

class AdminContactRequestsPage extends ConsumerWidget {
  const AdminContactRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final list = ref.watch(adminSupportRequestsProvider);

    return Theme(
      data: AppTheme.dark(),
      child: AppPrimaryScaffold(
        title: l10n.adminContactRequests,
        showLanguageSwitcher: true,
        body: list.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Text(
                  l10n.noJobsFound,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = items[i];
                final preview = r.message.length > 80
                    ? '${r.message.substring(0, 80)}…'
                    : r.message;
                final dateStr =
                    DateFormat('d MMM yyyy, HH:mm', locale.languageCode)
                        .format(r.createdAt.toLocal());
                return Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openDetail(context, ref, r),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              _StatusChip(l10n: l10n, status: r.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${supportRequestTypeLabel(l10n, r.requestType)} · $dateStr',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => ProviderErrorScreen(
                error: e,
                stackTrace: st,
                onRetry: () => ref.invalidate(adminSupportRequestsProvider),
              ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, SupportRequestEntity r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _AdminRequestDetailSheet(request: r),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.l10n, required this.status});

  final AppLocalizations l10n;
  final SupportRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      SupportRequestStatus.fresh => (scheme.errorContainer, scheme.onErrorContainer),
      SupportRequestStatus.read => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      SupportRequestStatus.resolved => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        supportRequestStatusLabel(l10n, status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _AdminRequestDetailSheet extends ConsumerStatefulWidget {
  const _AdminRequestDetailSheet({required this.request});

  final SupportRequestEntity request;

  @override
  ConsumerState<_AdminRequestDetailSheet> createState() =>
      _AdminRequestDetailSheetState();
}

class _AdminRequestDetailSheetState extends ConsumerState<_AdminRequestDetailSheet> {
  bool _busy = false;

  Future<void> _setStatus(SupportRequestStatus s) async {
    setState(() => _busy = true);
    try {
      final repo = await ref.read(supportRequestRepositoryProvider.future);
      await repo.updateStatus(widget.request.id, s);
      ref.invalidate(adminSupportRequestsProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.request;
    final locale = Localizations.localeOf(context);
    final dateStr = DateFormat('d MMMM yyyy, HH:mm', locale.languageCode)
        .format(r.createdAt.toLocal());

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.adminContactRequestDetail,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            Text('${l10n.recipientNameLabel}: ${r.userName}'),
            Text('${l10n.recipientPhoneLabel}: ${r.userPhone}'),
            Text('Role: ${r.roleStorage}'),
            Text('$dateStr · ${supportRequestTypeLabel(l10n, r.requestType)}'),
            const SizedBox(height: 12),
            Text(
              l10n.supportRequestFullMessage,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SelectableText(r.message),
            const SizedBox(height: 20),
            if (r.status == SupportRequestStatus.fresh)
              FilledButton(
                onPressed: _busy ? null : () => _setStatus(SupportRequestStatus.read),
                child: Text(l10n.supportRequestMarkRead),
              ),
            if (r.status != SupportRequestStatus.resolved) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _busy ? null : () => _setStatus(SupportRequestStatus.resolved),
                child: Text(l10n.supportRequestMarkResolved),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
