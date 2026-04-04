import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/job_entity.dart';
import '../../models/job_status.dart';
import '../courier/courier_order_tracking_hub.dart';
import '../providers/core_providers.dart';

/// Qaysi buyurtma uchun jonli GPS yuborilishini tanlash (fokus + faol yetkazuvlar).
String? pickCourierLiveTrackingJobId({
  required String courierId,
  required String? focusJobId,
  required List<JobEntity> jobs,
}) {
  bool trackable(JobEntity j) {
    if (j.winnerCourierId?.trim() != courierId) return false;
    return j.status == JobStatus.assigned ||
        j.status == JobStatus.pickedUp ||
        j.status == JobStatus.delivered;
  }

  final list = jobs.where(trackable).toList();
  if (list.isEmpty) return null;
  if (focusJobId != null && list.any((j) => j.id == focusJobId)) {
    return focusJobId;
  }
  list.sort((a, b) {
    int p(JobEntity j) => switch (j.status) {
          JobStatus.pickedUp => 3,
          JobStatus.delivered => 2,
          JobStatus.assigned => 1,
          _ => 0,
        };
    final c = p(b).compareTo(p(a));
    if (c != 0) return c;
    final ta = a.courierLocationAt ?? a.createdAt;
    final tb = b.courierLocationAt ?? b.createdAt;
    return tb.compareTo(ta);
  });
  return list.first.id;
}

/// Bitta tick: job tekshiruvi + GPS + server.
Future<void> courierLiveLocationTick({
  required WidgetRef ref,
  required String jobId,
  required String courierId,
}) async {
  final repo = await ref.read(jobRepositoryProvider.future);
  final fresh = await repo.getJob(jobId);
  if (fresh == null || fresh.winnerCourierId != courierId) {
    CourierOrderTrackingHub.stop(reason: 'job_or_winner_changed');
    return;
  }
  if (fresh.status != JobStatus.assigned &&
      fresh.status != JobStatus.pickedUp &&
      fresh.status != JobStatus.delivered) {
    CourierOrderTrackingHub.stop(reason: 'status_${fresh.status.name}');
    return;
  }
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      ref.read(courierTrackingGpsBlockedProvider.notifier).state = true;
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      ref.read(courierTrackingGpsBlockedProvider.notifier).state = true;
      if (kDebugMode) {
        debugPrint('[tracking] permission denied perm=$perm');
      }
      return;
    }
    ref.read(courierTrackingGpsBlockedProvider.notifier).state = false;
    final pos = await Geolocator.getCurrentPosition();
    final h = pos.heading;
    await repo.updateCourierLocation(
      jobId: jobId,
      reportingCourierId: courierId,
      lat: pos.latitude,
      lng: pos.longitude,
      heading: (h.isFinite && h >= 0 && h <= 360) ? h : null,
      speedMps: pos.speed.isFinite && pos.speed >= 0 ? pos.speed : null,
      accuracyM: pos.accuracy.isFinite && pos.accuracy >= 0
          ? pos.accuracy
          : null,
    );
  } catch (e, st) {
    debugPrint('[tracking] tick failed: $e');
    if (kDebugMode) debugPrintStack(stackTrace: st);
  }
}
