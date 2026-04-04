import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/debug/provider_error_screen.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/job_entity.dart';
import '../../../../models/job_status.dart';
import '../../application/admin_all_jobs_provider.dart';
import 'admin_panel_jobs_list.dart';

class AdminPanelAuctionsTab extends ConsumerWidget {
  const AdminPanelAuctionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final jobsAsync = ref.watch(adminAllJobsProvider);

    return jobsAsync.when(
      data: (List<JobEntity> jobs) {
        final list = jobs
            .where(
              (j) =>
                  j.status == JobStatus.posted ||
                  j.status == JobStatus.auctionLive,
            )
            .toList(growable: false);
        return AdminJobsScrollableList(
          jobs: list,
          sectionTitle: l10n.adminAuctionsSectionTitle,
          locale: locale,
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
}
