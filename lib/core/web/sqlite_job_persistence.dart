import '../database/app_database.dart';
import '../../models/bid_entity.dart';
import '../../models/job_entity.dart';
import 'job_local_persistence.dart';

class SqliteJobPersistence implements JobLocalPersistence {
  SqliteJobPersistence(this._db);

  final AppDatabase _db;

  @override
  Future<JobEntity?> getJobById(String id) => _db.getJobById(id);

  @override
  Future<void> insertJob(JobEntity job) => _db.insertJob(job);

  @override
  Future<void> updateJob(JobEntity job) => _db.updateJob(job);

  @override
  Future<void> deleteJobById(String id) => _db.deleteJobById(id);

  @override
  Future<List<String>> processExpiredAuctions() => _db.processExpiredAuctions();

  @override
  Future<void> insertAuctionStepIfAbsent({
    required String id,
    required String jobId,
    required String courierId,
    required int stepIndex,
    required int priceCents,
    int? createdAtMs,
  }) =>
      _db.insertAuctionStepIfAbsent(
        id: id,
        jobId: jobId,
        courierId: courierId,
        stepIndex: stepIndex,
        priceCents: priceCents,
        createdAtMs: createdAtMs,
      );

  @override
  Future<void> insertBid(BidEntity bid) => _db.insertBid(bid);

  @override
  Future<List<BidEntity>> listBidsForJob(String jobId) =>
      _db.listBidsForJob(jobId);

  @override
  Future<List<Map<String, Object?>>> listAuctionSteps(String jobId) =>
      _db.listAuctionSteps(jobId);

  @override
  Future<List<JobEntity>> listJobsForSender(String senderId) =>
      _db.listJobsForSender(senderId);

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
  }) =>
      _db.listJobsForCourierFeed(
        regionCode: regionCode,
        districtCode: districtCode,
        courierWorkingRegionKey: courierWorkingRegionKey,
        courierWorkingDistrictKey: courierWorkingDistrictKey,
        courierWholeRegionDistrict: courierWholeRegionDistrict,
        courierTransportKeys: courierTransportKeys,
        winnerCourierId: winnerCourierId,
        requireRemoteBackedJobs: requireRemoteBackedJobs,
      );
}
