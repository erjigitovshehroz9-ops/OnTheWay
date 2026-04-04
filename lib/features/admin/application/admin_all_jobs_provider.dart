import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../models/job_entity.dart';

final adminAllJobsProvider = FutureProvider<List<JobEntity>>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return db.listAllJobsAdmin();
});
