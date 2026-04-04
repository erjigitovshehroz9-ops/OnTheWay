import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/debug/provider_error_screen.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/job_entity.dart';
import '../../../../models/job_status.dart';
import '../../application/admin_all_jobs_provider.dart';
import '../../application/admin_operational_snapshot_provider.dart';
import 'admin_panel_jobs_list.dart';
import 'admin_surface_card.dart';

enum _OrderFilter {
  all,
  pending,
  auction,
  inDelivery,
  completed,
}

class AdminPanelOrdersTab extends ConsumerStatefulWidget {
  const AdminPanelOrdersTab({super.key});

  @override
  ConsumerState<AdminPanelOrdersTab> createState() =>
      _AdminPanelOrdersTabState();
}

class _AdminPanelOrdersTabState extends ConsumerState<AdminPanelOrdersTab> {
  _OrderFilter _filter = _OrderFilter.all;
  bool _complaintOnly = false;
  bool _auctionBidsOnly = false;
  bool _recentOnly = false;
  String? _regionCode;

  bool _matches(JobEntity j, _OrderFilter f) {
    switch (f) {
      case _OrderFilter.all:
        return true;
      case _OrderFilter.pending:
        return j.status == JobStatus.posted;
      case _OrderFilter.auction:
        return j.status == JobStatus.auctionLive;
      case _OrderFilter.inDelivery:
        return j.status == JobStatus.assigned ||
            j.status == JobStatus.pickedUp ||
            j.status == JobStatus.delivered;
      case _OrderFilter.completed:
        return j.status == JobStatus.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final jobsAsync = ref.watch(adminAllJobsProvider);
    final complaintIdsAsync = ref.watch(adminOrderComplaintIdsProvider);

    return jobsAsync.when(
      data: (jobs) {
        final complaintIds = complaintIdsAsync.valueOrNull ?? {};
        final regions = jobs
            .map((j) => j.regionCode.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        var filtered =
            jobs.where((j) => _matches(j, _filter)).toList(growable: true);
        if (_complaintOnly) {
          filtered = filtered.where((j) => complaintIds.contains(j.id)).toList();
        }
        if (_auctionBidsOnly) {
          filtered = filtered
              .where(
                (j) =>
                    j.auctionBidCount > 0 ||
                    j.status == JobStatus.auctionLive,
              )
              .toList();
        }
        if (_regionCode != null && _regionCode!.trim().isNotEmpty) {
          filtered = filtered
              .where((j) => j.regionCode.trim() == _regionCode!.trim())
              .toList();
        }
        if (_recentOnly) {
          final cut = DateTime.now().subtract(const Duration(days: 30));
          filtered =
              filtered.where((j) => j.createdAt.isAfter(cut)).toList();
        }

        if (kDebugMode) {
          debugPrint('[admin] orders count=${jobs.length}');
          debugPrint(
            '[admin] filters region=${_regionCode ?? '-'} status=$_filter '
            'complaintOnly=$_complaintOnly auctionBids=$_auctionBidsOnly '
            'recent30=$_recentOnly → rows=${filtered.length}',
          );
        }

        return AdminJobsScrollableList(
          jobs: filtered,
          sectionTitle: l10n.adminOrdersSectionTitle,
          locale: locale,
          complaintOrderIds: complaintIds,
          filterBar: AdminSurfaceCard(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    ...regions.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _regionCode = v),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(l10n.adminOrderFilterAll, _OrderFilter.all),
                      _chip(l10n.adminOrderFilterPending, _OrderFilter.pending),
                      _chip(l10n.adminOrderFilterAuction, _OrderFilter.auction),
                      _chip(
                        l10n.adminOrderFilterInDelivery,
                        _OrderFilter.inDelivery,
                      ),
                      _chip(
                        l10n.adminOrderFilterCompleted,
                        _OrderFilter.completed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _boolChip(
                        l10n.adminOrderFilterComplaint,
                        _complaintOnly,
                        (v) => setState(() => _complaintOnly = v),
                      ),
                      _boolChip(
                        l10n.adminOrderFilterAuctionBids,
                        _auctionBidsOnly,
                        (v) => setState(() => _auctionBidsOnly = v),
                      ),
                      _boolChip(
                        l10n.adminOrderFilterRecent30,
                        _recentOnly,
                        (v) => setState(() => _recentOnly = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => ProviderErrorScreen(
        error: e,
        stackTrace: st,
        onRetry: () {
          ref.invalidate(adminAllJobsProvider);
          ref.invalidate(appDatabaseProvider);
        },
      ),
    );
  }

  Widget _chip(String label, _OrderFilter value) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        label: Text(label),
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: scheme.primary.withValues(alpha: 0.2),
        side: BorderSide(
          color: (selected ? scheme.primary : scheme.outlineVariant)
              .withValues(alpha: selected ? 0.6 : 0.35),
        ),
      ),
    );
  }

  Widget _boolChip(
    String label,
    bool selected,
    ValueChanged<bool> onChanged,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        label: Text(label),
        onSelected: onChanged,
        selectedColor: scheme.secondary.withValues(alpha: 0.2),
        side: BorderSide(
          color: (selected ? scheme.secondary : scheme.outlineVariant)
              .withValues(alpha: selected ? 0.6 : 0.35),
        ),
      ),
    );
  }
}
