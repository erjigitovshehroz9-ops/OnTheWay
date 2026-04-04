import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../models/job_entity.dart';

/// Polls job row so auction timer / status updates reflect without manual refresh.
final jobPollProvider =
    StreamProvider.autoDispose.family<JobEntity?, String>((ref, jobId) async* {
  final repo = await ref.watch(jobRepositoryProvider.future);
  while (true) {
    yield await repo.getJob(jobId);
    await Future<void>.delayed(const Duration(seconds: 1));
  }
});
