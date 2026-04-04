import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_role.dart';
import '../providers/core_providers.dart';
import 'courier_live_location_tick.dart';
import 'courier_order_tracking_hub.dart';

/// Kuryer rolda ilova bo‘ylab (buyurtma tafsilotidan tashqarida ham) GPS ni
/// serverga yuborish — [CourierOrderTrackingHub] bitta aktiv buyurtma uchun.
class CourierLiveLocationHost extends ConsumerWidget {
  const CourierLiveLocationHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).valueOrNull;
    if (user == null || user.role != UserRole.courier) {
      CourierOrderTrackingHub.stop(reason: 'not_courier');
      ref.read(courierTrackingGpsBlockedProvider.notifier).state = false;
      return child;
    }
    return _CourierLiveLocationJobsScope(child: child);
  }
}

class _CourierLiveLocationJobsScope extends ConsumerWidget {
  const _CourierLiveLocationJobsScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).valueOrNull;
    if (user == null || user.role != UserRole.courier) {
      return child;
    }
    final focusId = ref.watch(courierLiveTrackingFocusJobIdProvider);
    final jobsAsync = ref.watch(courierJobsProvider);
    final jobs = jobsAsync.asData?.value;
    if (jobs == null) {
      return child;
    }

    final effectiveId = pickCourierLiveTrackingJobId(
      courierId: user.id,
      focusJobId: focusId,
      jobs: jobs,
    );

    if (effectiveId == null) {
      CourierOrderTrackingHub.stop(reason: 'no_active_delivery');
      return child;
    }

    CourierOrderTrackingHub.ensureRunning(
      jobId: effectiveId,
      courierId: user.id,
      interval: const Duration(seconds: 8),
      shouldContinue: () => true,
      tick: () => courierLiveLocationTick(
            ref: ref,
            jobId: effectiveId,
            courierId: user.id,
          ),
    );

    return child;
  }
}
