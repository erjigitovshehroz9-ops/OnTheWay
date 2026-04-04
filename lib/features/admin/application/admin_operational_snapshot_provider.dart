import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../models/admin_operational_snapshot.dart';
import '../../../models/order_feedback_entity.dart';

/// Operatsion dashboard uchun SQLite aggregate.
final adminOperationalSnapshotProvider =
    FutureProvider<AdminOperationalSnapshot>((ref) async {
  if (kIsWeb) {
    return AdminOperationalSnapshot.emptyWeb();
  }
  final db = await ref.watch(appDatabaseProvider.future);
  if (db == null) {
    return AdminOperationalSnapshot.emptyWeb();
  }
  final s = await db.loadAdminOperationalSnapshot();
  if (kDebugMode) {
    debugPrint(
      '[admin] dashboard loaded orders=${s.jobsTotal} users=${s.usersTotal} '
      'feedback=${s.orderFeedbackTotal} complaints=${s.complaintsCombined}',
    );
  }
  return s;
});

/// Buyurtma IDlari — shikoyat (yangi yoki eski jadval) bor.
final adminOrderComplaintIdsProvider = FutureProvider<Set<String>>((ref) async {
  if (kIsWeb) return {};
  final db = await ref.watch(appDatabaseProvider.future);
  if (db == null) return {};
  final ids = await db.adminOrderIdsWithComplaint();
  if (kDebugMode) {
    debugPrint('[admin] complaints order ids=${ids.length}');
  }
  return ids;
});

/// Barcha feedback (filtr state bilan).
final adminFeedbackAllListProvider = FutureProvider
    .family<List<OrderFeedbackEntity>, ({bool lowRating, bool senderToCourier})>(
        (ref, p) async {
  if (kIsWeb) return [];
  final db = await ref.watch(appDatabaseProvider.future);
  if (db == null) return [];
  final list = await db.listAdminOrderFeedback(
    lowRatingOnly: p.lowRating ? true : null,
    complaintFromSenderOnly: p.senderToCourier ? true : null,
  );
  if (kDebugMode) {
    debugPrint(
      '[admin] feedback count=${list.length} lowRating=${p.lowRating} '
      'senderToCourier=${p.senderToCourier}',
    );
  }
  return list;
});

/// Faqat shikoyatlar (moderatsiya ro‘yxati).
final adminComplaintsListProvider =
    FutureProvider<List<OrderFeedbackEntity>>((ref) async {
  if (kIsWeb) return [];
  final db = await ref.watch(appDatabaseProvider.future);
  if (db == null) return [];
  final list =
      await db.listAdminOrderFeedback(feedbackType: 'complaint', limit: 500);
  if (kDebugMode) {
    debugPrint('[admin] complaints count=${list.length}');
  }
  return list;
});

/// Moderatsiya saqlangach barcha filtr kombinatsiyalarini yangilash.
void invalidateAdminFeedbackListFamily(WidgetRef ref) {
  for (final lr in [false, true]) {
    for (final s2c in [false, true]) {
      ref.invalidate(
        adminFeedbackAllListProvider(
          (lowRating: lr, senderToCourier: s2c),
        ),
      );
    }
  }
}
