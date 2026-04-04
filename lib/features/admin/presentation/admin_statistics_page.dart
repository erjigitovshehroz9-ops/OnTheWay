import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/job_status.dart';
import '../../../models/region_record.dart';
import '../../../shared/widgets/app_primary_scaffold.dart';
import 'widgets/admin_order_mix_chart.dart';
import 'widgets/admin_section_title.dart';
import 'widgets/admin_surface_card.dart';

class AdminStatisticsPage extends ConsumerWidget {
  const AdminStatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final regionsAsync = ref.watch(regionsListProvider);

    return Theme(
      data: AppTheme.dark(),
      child: AppPrimaryScaffold(
        title: l10n.adminStatistics,
        showLanguageSwitcher: true,
        body: regionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('$e')),
          data: (regions) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                AdminSectionTitle(title: l10n.adminSectionOrders),
                const SizedBox(height: 12),
                AdminSurfaceCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.adminNavStatsSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminSectionTitle(title: l10n.adminSectionOverview),
                const SizedBox(height: 12),
                ...regions.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RegionCard(region: r, locale: locale, l10n: l10n),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RegionCard extends ConsumerWidget {
  const _RegionCard({
    required this.region,
    required this.locale,
    required this.l10n,
  });

  final RegionRecord region;
  final Locale locale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);

    return dbAsync.when(
      loading: () => const AdminSurfaceCard(
        child: SizedBox(height: 56, child: Center(child: LinearProgressIndicator())),
      ),
      error: (e, st) => AdminSurfaceCard(child: Text('$e')),
      data: (db) {
        return FutureBuilder<_Counts>(
          future: db == null
              ? Future.value(_emptyRegionCounts)
              : _loadCounts(db, region.code),
          builder: (context, snap) {
            final c = snap.data;
            final scheme = Theme.of(context).colorScheme;

            return AdminSurfaceCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  shape: const RoundedRectangleBorder(),
                  collapsedShape: const RoundedRectangleBorder(),
                  title: Text(
                    region.name.resolveLang(locale.languageCode),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                  ),
                  subtitle: c == null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            l10n.loading,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _KpiPill(
                                    label: l10n.statActiveJobs,
                                    value: c.active,
                                    color: scheme.primary,
                                  ),
                                  _KpiPill(
                                    label: l10n.statLiveAuctions,
                                    value: c.live,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                  _KpiPill(
                                    label: l10n.statCompleted,
                                    value: c.completed,
                                    color: const Color(0xFF22C55E),
                                  ),
                                  _KpiPill(
                                    label: l10n.statCancelled,
                                    value: c.cancelled,
                                    color: scheme.error,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AdminOrderMixChart(
                                l10n: l10n,
                                totalJobs: c.totalJobs,
                                completed: c.completed,
                                inProgress: c.active,
                                cancelled: c.cancelled,
                              ),
                            ],
                          ),
                        ),
                  children: [
                    if (c != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_city_rounded,
                              size: 18, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${l10n.regionLabel}: ${region.name.resolveLang(locale.languageCode)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          Text(
                            c.totalJobs.toString(),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    _AdminRegionDistrictsList(
                      regionCode: region.code,
                      db: db,
                      locale: locale,
                      scheme: scheme,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

}

/// Keeps [ref.watch] at the top of [build], not inside [FutureBuilder] / [ExpansionTile].
class _AdminRegionDistrictsList extends ConsumerWidget {
  const _AdminRegionDistrictsList({
    required this.regionCode,
    required this.db,
    required this.locale,
    required this.scheme,
  });

  final String regionCode;
  final AppDatabase? db;
  final Locale locale;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districtsAsync = ref.watch(districtsForRegionProvider(regionCode));
    return districtsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('$e'),
      ),
      data: (districts) {
        return Column(
          children: districts.map((d) {
            return FutureBuilder<int>(
              future: db == null
                  ? Future.value(0)
                  : db!.countJobsInDistrict(d.code),
              builder: (context, dsnap) {
                final n = dsnap.data ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.name.resolveLang(locale.languageCode),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Text(
                          n.toString(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

final _emptyRegionCounts = _Counts(
  totalJobs: 0,
  active: 0,
  live: 0,
  completed: 0,
  cancelled: 0,
  complaints: 0,
);

Future<_Counts> _loadCounts(AppDatabase db, String regionCode) async {
  final jobs = await db.countJobsInRegion(regionCode);
  final live = await db.countJobsInRegionWithStatus(
    regionCode,
    JobStatus.auctionLive.toStorage(),
  );
  final completed = await db.countJobsInRegionWithStatus(
    regionCode,
    JobStatus.completed.toStorage(),
  );
  final cancelled = await db.countJobsInRegionWithStatus(
    regionCode,
    JobStatus.cancelled.toStorage(),
  );
  final posted = await db.countJobsInRegionWithStatus(
    regionCode,
    JobStatus.posted.toStorage(),
  );
  final assigned = await db.countJobsInRegionWithStatus(
    regionCode,
    JobStatus.assigned.toStorage(),
  );
  final picked = await db.countJobsInRegionWithStatus(
    regionCode,
    JobStatus.pickedUp.toStorage(),
  );
  final delivered = await db.countJobsInRegionWithStatus(
    regionCode,
    JobStatus.delivered.toStorage(),
  );
  final active = posted + live + assigned + picked + delivered;
  const complaints = 0;
  return _Counts(
    totalJobs: jobs,
    active: active,
    live: live,
    completed: completed,
    cancelled: cancelled,
    complaints: complaints,
  );
}

class _Counts {
  _Counts({
    required this.totalJobs,
    required this.active,
    required this.live,
    required this.completed,
    required this.cancelled,
    required this.complaints,
  });

  final int totalJobs;
  final int active;
  final int live;
  final int completed;
  final int cancelled;
  final int complaints;
}

class _KpiPill extends StatelessWidget {
  const _KpiPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
