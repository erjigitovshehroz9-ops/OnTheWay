import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../models/job_entity.dart';

final senderJobsProvider =
    FutureProvider.family<List<JobEntity>, String>((ref, senderId) async {
  final repo = await ref.watch(jobRepositoryProvider.future);
  final list = await repo.senderJobs(senderId);
  if (kDebugMode) {
    debugPrint('[order-list] sender count=${list.length} senderId=$senderId');
  }
  return list;
});
