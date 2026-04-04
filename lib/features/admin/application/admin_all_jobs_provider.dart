import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../models/job_entity.dart';

final adminAllJobsProvider = FutureProvider<List<JobEntity>>((ref) async {
  if (kIsWeb) return [];
  final db = await ref.watch(appDatabaseProvider.future);
  if (db == null) return [];
  return db.listAllJobsAdmin();
});
