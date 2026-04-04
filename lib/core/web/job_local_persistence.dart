import '../../models/bid_entity.dart';
import '../../models/job_entity.dart';

/// Local job persistence used by [JobRepository] (SQLite on native, memory on web).
abstract class JobLocalPersistence {
  Future<JobEntity?> getJobById(String id);

  Future<void> insertJob(JobEntity job);

  Future<void> updateJob(JobEntity job);

  Future<void> deleteJobById(String id);

  /// Local-only expired auction finalization; web returns [] (server RPC handles it).
  Future<List<String>> processExpiredAuctions();

  Future<void> insertAuctionStepIfAbsent({
    required String id,
    required String jobId,
    required String courierId,
    required int stepIndex,
    required int priceCents,
    int? createdAtMs,
  });

  Future<void> insertBid(BidEntity bid);

  Future<List<BidEntity>> listBidsForJob(String jobId);

  Future<List<Map<String, Object?>>> listAuctionSteps(String jobId);

  Future<List<JobEntity>> listJobsForSender(String senderId);

  Future<List<JobEntity>> listJobsForCourierFeed({
    required String? regionCode,
    required String? districtCode,
    required String courierWorkingRegionKey,
    required String courierWorkingDistrictKey,
    required bool courierWholeRegionDistrict,
    List<String>? courierTransportKeys,
    String? winnerCourierId,
    bool requireRemoteBackedJobs = false,
  });
}
