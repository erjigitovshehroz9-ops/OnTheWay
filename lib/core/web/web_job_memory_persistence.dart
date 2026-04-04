import '../geo/work_area_keys.dart';
import '../utils/auction_math.dart';
import '../../models/bid_entity.dart';
import '../../models/job_entity.dart';
import '../../models/job_status.dart';
import '../../models/job_transport_type.dart';
import 'job_local_persistence.dart';

List<JobEntity> _dedupeJobsByIdPreserveOrder(List<JobEntity> jobs) {
  final seen = <String>{};
  final out = <JobEntity>[];
  for (final j in jobs) {
    if (seen.add(j.id)) out.add(j);
  }
  return out;
}

/// In-memory job store for Flutter web (temporary; no SQLite).
class WebJobMemoryPersistence implements JobLocalPersistence {
  WebJobMemoryPersistence();

  final Map<String, JobEntity> _jobs = {};
  final Map<String, List<BidEntity>> _bidsByJob = {};
  final Set<String> _auctionStepIds = {};
  final Map<String, List<Map<String, Object?>>> _auctionStepsByJob = {};

  @override
  Future<JobEntity?> getJobById(String id) async => _jobs[id];

  @override
  Future<void> insertJob(JobEntity job) async {
    _jobs[job.id] = job;
  }

  @override
  Future<void> updateJob(JobEntity job) async {
    _jobs[job.id] = job;
  }

  @override
  Future<void> deleteJobById(String id) async {
    if (id.isEmpty) return;
    _jobs.remove(id);
    _bidsByJob.remove(id);
    _auctionStepsByJob.removeWhere((k, _) => k == id);
  }

  @override
  Future<List<String>> processExpiredAuctions() async {
    final assignedIds = <String>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final e in _jobs.entries.toList()) {
      final job = e.value;
      if (job.status != JobStatus.auctionLive) continue;
      if (job.auctionEndsAt == null) continue;
      if (job.auctionEndsAt!.millisecondsSinceEpoch >= now) continue;
      if (job.syncedFromSupabase) continue;

      final winner = job.leadingCourierId;
      if (winner == null) {
        await updateJob(
          job.copyWith(
            status: JobStatus.posted,
            auctionEndsAt: null,
            leadingCourierId: null,
            auctionStep: 0,
            currentPriceCents: null,
          ),
        );
        continue;
      }
      final finalPrice = job.currentPriceCents ??
          AuctionMath.committedPriceCents(
            job.startPriceCents,
            job.auctionStep,
            job.floorPriceCents,
          );
      await updateJob(
        job.copyWith(
          status: JobStatus.assigned,
          winnerCourierId: winner,
          finalPriceCents: finalPrice,
          auctionEndsAt: null,
          currentPriceCents: null,
          winnerSelectedAt: job.winnerSelectedAt ?? DateTime.now(),
        ),
      );
      assignedIds.add(job.id);
    }
    return assignedIds;
  }

  @override
  Future<void> insertAuctionStepIfAbsent({
    required String id,
    required String jobId,
    required String courierId,
    required int stepIndex,
    required int priceCents,
    int? createdAtMs,
  }) async {
    if (_auctionStepIds.contains(id)) return;
    _auctionStepIds.add(id);
    final row = <String, Object?>{
      'id': id,
      'job_id': jobId,
      'courier_id': courierId,
      'step_index': stepIndex,
      'price_cents': priceCents,
      'created_at': createdAtMs ?? DateTime.now().millisecondsSinceEpoch,
    };
    (_auctionStepsByJob[jobId] ??= []).add(row);
  }

  @override
  Future<void> insertBid(BidEntity bid) async {
    (_bidsByJob[bid.jobId] ??= []).add(bid);
  }

  @override
  Future<List<BidEntity>> listBidsForJob(String jobId) async {
    final rows = List<BidEntity>.from(_bidsByJob[jobId] ?? const []);
    rows.sort((a, b) {
      final c = b.amountCents.compareTo(a.amountCents);
      if (c != 0) return c;
      return a.createdAt.compareTo(b.createdAt);
    });
    return rows;
  }

  @override
  Future<List<Map<String, Object?>>> listAuctionSteps(String jobId) async {
    final list = List<Map<String, Object?>>.from(
      _auctionStepsByJob[jobId] ?? const [],
    );
    list.sort(
      (a, b) => (a['created_at'] as int).compareTo(b['created_at'] as int),
    );
    return list;
  }

  @override
  Future<List<JobEntity>> listJobsForSender(String senderId) async {
    final list = _jobs.values
        .where((j) => j.senderId == senderId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _dedupeJobsByIdPreserveOrder(list);
  }

  @override
  Future<List<JobEntity>> listJobsForCourierFeed({
    required String? regionCode,
    required String? districtCode,
    required String courierWorkingRegionKey,
    required String courierWorkingDistrictKey,
    required bool courierWholeRegionDistrict,
    List<String>? courierTransportKeys,
    String? winnerCourierId,
    bool requireRemoteBackedJobs = false,
  }) async {
    var jobs = _jobs.values
        .where(
          (j) =>
              j.status == JobStatus.posted || j.status == JobStatus.auctionLive,
        )
        .toList();
    if (requireRemoteBackedJobs) {
      jobs = jobs.where((j) => j.syncedFromSupabase).toList();
    }
    if (regionCode != null && regionCode.isNotEmpty) {
      jobs = jobs
          .where(
            (j) =>
                (j.regionCode == regionCode) || j.regionCode.trim().isEmpty,
          )
          .toList();
    }
    jobs = jobs
        .where(
          (j) => WorkAreaKeys.courierJobMatchesWorkArea(
            job: j,
            courierWorkingRegionKey: courierWorkingRegionKey,
            courierWorkingDistrictKey: courierWorkingDistrictKey,
            courierRegionCode: regionCode,
            courierDistrictCode: districtCode,
            wholeRegionDistrict: courierWholeRegionDistrict,
          ),
        )
        .toList();

    if (courierTransportKeys != null && courierTransportKeys.isNotEmpty) {
      jobs = jobs
          .where(
            (j) => JobTransportType.courierSeesJob(
              courierNormalizedKeys: courierTransportKeys,
              jobTransportStored: j.transportType,
            ),
          )
          .toList();
    }

    if (winnerCourierId != null && winnerCourierId.isNotEmpty) {
      var wonJobs = _jobs.values
          .where(
            (j) =>
                j.winnerCourierId == winnerCourierId &&
                (j.status == JobStatus.assigned ||
                    j.status == JobStatus.pickedUp ||
                    j.status == JobStatus.delivered ||
                    j.status == JobStatus.completed),
          )
          .toList();
      if (requireRemoteBackedJobs) {
        wonJobs = wonJobs.where((j) => j.syncedFromSupabase).toList();
      }
      if (courierTransportKeys != null && courierTransportKeys.isNotEmpty) {
        wonJobs = wonJobs
            .where(
              (j) => JobTransportType.courierSeesJob(
                courierNormalizedKeys: courierTransportKeys,
                jobTransportStored: j.transportType,
              ),
            )
            .toList();
      }
      final byId = <String, JobEntity>{for (final j in jobs) j.id: j};
      for (final j in wonJobs) {
        byId[j.id] = j;
      }
      jobs = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return _dedupeJobsByIdPreserveOrder(jobs);
  }
}
