import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/job_entity.dart';
import '../../../models/job_status.dart';

/// Yuboruvchi buyurtmalari oxirgi holati — oflayn / qayta kirishda status o‘tishlarini aniqlash.
class SenderJobStatusSnapshotStorage {
  SenderJobStatusSnapshotStorage._();

  static String _key(String userId) => 'sender_job_status_snap_v1_$userId';

  static JobStatus? _parse(String raw) {
    try {
      return JobStatus.values.byName(raw);
    } catch (_) {
      return JobStatus.fromStorage(raw);
    }
  }

  static Future<Map<String, JobStatus>> load(String userId) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key(userId));
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, JobStatus>{};
      for (final e in map.entries) {
        final st = _parse(e.value as String);
        if (st != null) out[e.key] = st;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(String userId, List<JobEntity> jobs) async {
    final sp = await SharedPreferences.getInstance();
    final out = <String, String>{for (final j in jobs) j.id: j.status.name};
    await sp.setString(_key(userId), jsonEncode(out));
  }
}
