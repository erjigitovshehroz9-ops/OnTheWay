import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/sender_in_app_notification.dart';
import '../data/sender_notifications_storage.dart';

final senderInAppNotificationsProvider = AsyncNotifierProvider.autoDispose
    .family<SenderInAppNotificationsNotifier, List<SenderInAppNotification>,
        String>(SenderInAppNotificationsNotifier.new);

class SenderInAppNotificationsNotifier extends AutoDisposeFamilyAsyncNotifier<
    List<SenderInAppNotification>, String> {
  @override
  Future<List<SenderInAppNotification>> build(String userId) async {
    return SenderNotificationsStorage.load(userId);
  }

  Future<void> append(SenderInAppNotification n) async {
    final userId = arg;
    final existing = state.valueOrNull ??
        await SenderNotificationsStorage.load(userId);
    final next = [n, ...existing].take(50).toList();
    await SenderNotificationsStorage.save(userId, next);
    state = AsyncData(next);
  }

  Future<void> markRead(String id) async {
    final userId = arg;
    final existing = state.valueOrNull;
    if (existing == null) return;
    final next = existing
        .map((e) => e.id == id ? e.copyWith(read: true) : e)
        .toList(growable: false);
    await SenderNotificationsStorage.save(userId, next);
    state = AsyncData(next);
  }

  /// Bildirishnomalar varag‘i yopilgach — barchasini o‘qilgan (indikator o‘chadi).
  Future<void> markAllRead() async {
    final userId = arg;
    final existing =
        state.valueOrNull ?? await SenderNotificationsStorage.load(userId);
    if (existing.isEmpty) return;
    final next = existing
        .map((e) => e.read ? e : e.copyWith(read: true))
        .toList(growable: false);
    await SenderNotificationsStorage.save(userId, next);
    state = AsyncData(next);
  }
}
