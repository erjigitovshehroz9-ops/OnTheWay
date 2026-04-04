import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/job_entity.dart';
import '../../../../models/job_status.dart';
import '../../../../shared/utils/job_status_l10n.dart';
import 'admin_job_route_mini_map.dart';
import 'admin_section_title.dart';

Color adminJobStatusColor(JobStatus s) {
  return switch (s) {
    JobStatus.posted => const Color(0xFFF59E0B),
    JobStatus.auctionLive => const Color(0xFF4F46E5),
    JobStatus.assigned => const Color(0xFF1D4ED8),
    JobStatus.pickedUp => const Color(0xFFF59E0B),
    JobStatus.delivered => const Color(0xFF22C55E),
    JobStatus.completed => const Color(0xFF16A34A),
    JobStatus.cancelled => const Color(0xFFE11D48),
  };
}

String _shortJobId(JobEntity j) {
  final c = j.id.replaceAll('-', '');
  if (c.length >= 6) return c.substring(0, 6).toUpperCase();
  return j.id.length > 6 ? j.id.substring(0, 6).toUpperCase() : j.id.toUpperCase();
}

bool _jobHasLiveTracking(JobEntity j) {
  return (j.status == JobStatus.pickedUp || j.status == JobStatus.delivered) &&
      j.courierLat != null &&
      j.courierLng != null;
}

class AdminJobsScrollableList extends StatelessWidget {
  const AdminJobsScrollableList({
    super.key,
    required this.jobs,
    required this.sectionTitle,
    required this.locale,
    this.filterBar,
    this.complaintOrderIds,
  });

  final List<JobEntity> jobs;
  final String sectionTitle;
  final Locale locale;
  final Widget? filterBar;
  final Set<String>? complaintOrderIds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final df = DateFormat.yMMMd(locale.toString());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        AdminSectionTitle(title: sectionTitle),
        if (filterBar != null) ...[
          const SizedBox(height: 10),
          filterBar!,
        ],
        const SizedBox(height: 12),
        if (jobs.isEmpty)
          Text(
            l10n.adminNoJobsInList,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          )
        else
          ...jobs.map(
            (j) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.push(AppRoutes.jobDetail(j.id)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.adminJobOrderNumber(_shortJobId(j)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: adminJobStatusColor(j.status)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                jobStatusLabel(j.status, l10n),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: adminJobStatusColor(j.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          j.title.resolveLang(locale.languageCode),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (j.description.resolveLang(locale.languageCode).trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            j.description.resolveLang(locale.languageCode),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF64748B),
                                ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          df.format(j.createdAt),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF94A3B8),
                              ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (complaintOrderIds?.contains(j.id) == true)
                              Icon(
                                Icons.report_gmailerrorred_outlined,
                                size: 18,
                                color: Colors.orange.shade800,
                              ),
                            if (_jobHasLiveTracking(j))
                              Icon(
                                Icons.location_searching_rounded,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                            if (j.imagePath.trim().isNotEmpty)
                              Icon(
                                Icons.image_outlined,
                                size: 18,
                                color: const Color(0xFF64748B),
                              ),
                            Text(
                              [
                                if (j.regionCode.trim().isNotEmpty)
                                  j.regionCode.trim(),
                                if (j.districtCode.trim().isNotEmpty)
                                  j.districtCode.trim(),
                              ].join(' · '),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              '↑${(j.startPriceCents / 100).toStringAsFixed(0)}'
                              '${j.finalPriceCents != null ? ' → ${(j.finalPriceCents! / 100).toStringAsFixed(0)}' : ''}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _RouteRow(
                          job: j,
                          pickup: j.pickupAddress.resolveLang(locale.languageCode),
                          dropoff: j.dropoffAddress.resolveLang(locale.languageCode),
                          l10n: l10n,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.job,
    required this.pickup,
    required this.dropoff,
    required this.l10n,
  });

  final JobEntity job;
  final String pickup;
  final String dropoff;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.trip_origin, size: 18, color: Color(0xFF22C55E)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminPickupInfo,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    pickup.isEmpty ? '—' : pickup,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Container(
                width: 2,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF22C55E), Color(0xFF1976D2)],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.flag_outlined, size: 18, color: Color(0xFF1976D2)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.adminDropoffInfo,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    dropoff.isEmpty ? '—' : dropoff,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AdminJobRouteMiniMap.hasAnyCoordinate(job)
            ? AdminJobRouteMiniMap(job: job)
            : const AdminJobRouteFallbackStrip(),
      ],
    );
  }
}
