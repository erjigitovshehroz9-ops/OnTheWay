import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../models/feedback_kind.dart';
import '../../../models/job_status.dart';

class AdminStats {
  const AdminStats({
    required this.users,
    required this.senders,
    required this.couriers,
    required this.jobs,
    required this.activeJobs,
    required this.liveAuctions,
    required this.completedJobs,
    required this.uncompletedJobs,
    required this.cancelledJobs,
    required this.blockedUsers,
    required this.complaints,
  });

  final int users;
  final int senders;
  final int couriers;
  final int jobs;
  final int activeJobs;
  final int liveAuctions;
  final int completedJobs;
  final int uncompletedJobs;
  final int cancelledJobs;
  final int blockedUsers;
  final int complaints;

  int get inProgressJobs =>
      (jobs - completedJobs - cancelledJobs).clamp(0, jobs);
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  if (kIsWeb) {
    return const AdminStats(
      users: 0,
      senders: 0,
      couriers: 0,
      jobs: 0,
      activeJobs: 0,
      liveAuctions: 0,
      completedJobs: 0,
      uncompletedJobs: 0,
      cancelledJobs: 0,
      blockedUsers: 0,
      complaints: 0,
    );
  }
  final db = await ref.watch(appDatabaseProvider.future);
  if (db == null) {
    return const AdminStats(
      users: 0,
      senders: 0,
      couriers: 0,
      jobs: 0,
      activeJobs: 0,
      liveAuctions: 0,
      completedJobs: 0,
      uncompletedJobs: 0,
      cancelledJobs: 0,
      blockedUsers: 0,
      complaints: 0,
    );
  }
  final users = await db.countUsers();
  final senders = await db.countSenders();
  final couriers = await db.countUsersByRole('courier');
  final jobs = await db.countJobs();
  final activeJobs = await db.countJobsNotTerminal();
  final liveAuctions =
      await db.countJobsByStatus(JobStatus.auctionLive.toStorage());
  final completedJobs =
      await db.countJobsByStatus(JobStatus.completed.toStorage());
  final cancelledJobs =
      await db.countJobsByStatus(JobStatus.cancelled.toStorage());
  final blockedUsers = await db.countBlockedUsers();
  final complaintsLegacy = await db.countFeedback(FeedbackKind.complaint);
  final complaintsNew = await db.countOrderFeedbackByType('complaint');
  final complaints = complaintsLegacy + complaintsNew;

  return AdminStats(
    users: users,
    senders: senders,
    couriers: couriers,
    jobs: jobs,
    activeJobs: activeJobs,
    liveAuctions: liveAuctions,
    completedJobs: completedJobs,
    uncompletedJobs: jobs - completedJobs,
    cancelledJobs: cancelledJobs,
    blockedUsers: blockedUsers,
    complaints: complaints,
  );
});
