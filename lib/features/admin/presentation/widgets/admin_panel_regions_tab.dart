import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/app_user.dart';
import '../../../../models/job_entity.dart';
import '../../../../models/job_status.dart';
import '../../../../models/user_role.dart';
import '../../application/admin_all_jobs_provider.dart';
import '../../application/admin_operational_snapshot_provider.dart';
import '../../application/admin_users_list_provider.dart';
import 'admin_section_title.dart';
import 'admin_surface_card.dart';

/// Viloyat bo‘yicha xulosalar + user/ro‘yxatdan kelgan sonlar.
class AdminPanelRegionsTab extends ConsumerWidget {
  const AdminPanelRegionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snap = ref.watch(adminOperationalSnapshotProvider);
    final users = ref.watch(adminUsersListProvider);
    final jobs = ref.watch(adminAllJobsProvider);

    if (snap.isLoading || users.isLoading || jobs.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snap.hasError) {
      return Center(child: Text('${snap.error}'));
    }
    if (users.hasError) {
      return Center(child: Text('${users.error}'));
    }
    if (jobs.hasError) {
      return Center(child: Text('${jobs.error}'));
    }

    final s = snap.requireValue;
    final uList = users.requireValue;
    final jList = jobs.requireValue;

    final regionCodes = <String>{};
    for (final e in s.usersByRegion) {
      if (e.code.trim().isNotEmpty) regionCodes.add(e.code.trim());
    }
    for (final e in s.jobsByRegion) {
      if (e.code.trim().isNotEmpty) regionCodes.add(e.code.trim());
    }
    final sortedRegions = regionCodes.toList()..sort();

    if (kDebugMode) {
      debugPrint(
        '[admin] region analytics regions=${sortedRegions.length} '
        'orders=${jList.length} users=${uList.length}',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        AdminSectionTitle(title: l10n.adminRegionsSectionTitle),
        const SizedBox(height: 10),
        AdminSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adminControlUsersByRegion,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              ...s.usersByRegion.take(8).map(
                    (e) => _row(context, e.code, e.count),
                  ),
              const Divider(height: 22),
              Text(
                l10n.adminControlJobsByRegion,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              ...s.jobsByRegion.take(8).map(
                    (e) => _row(context, e.code, e.count),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.adminRegionsSelectRegion,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        ...sortedRegions.map(
          (code) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RegionExpansion(
              code: code,
              users: uList,
              jobs: jList,
              l10n: l10n,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _row(BuildContext context, String code, int n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              code.isEmpty ? '—' : code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$n',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _RegionExpansion extends StatelessWidget {
  const _RegionExpansion({
    required this.code,
    required this.users,
    required this.jobs,
    required this.l10n,
  });

  final String code;
  final List<AppUser> users;
  final List<JobEntity> jobs;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final senders = users
        .where(
          (u) =>
              u.role == UserRole.sender &&
              (u.regionCode ?? '').trim() == code,
        )
        .length;
    final couriers = users
        .where(
          (u) =>
              u.role == UserRole.courier &&
              (u.regionCode ?? '').trim() == code,
        )
        .length;
    final complaints = users
        .where((u) => (u.regionCode ?? '').trim() == code)
        .fold<int>(0, (a, u) => a + u.complaintCount);

    var orderCount = 0;
    var completed = 0;
    for (final j in jobs) {
      if (j.regionCode.trim() != code) continue;
      orderCount++;
      if (j.status == JobStatus.completed) completed++;
    }

    return AdminSurfaceCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            code,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: [
            _metric(l10n.adminRegionsOrders, orderCount),
            _metric(l10n.adminRegionsCompleted, completed),
            _metric(l10n.adminRegionsSenders, senders),
            _metric(l10n.adminRegionsCouriers, couriers),
            _metric(l10n.adminRegionsComplaints, complaints),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
