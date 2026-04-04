import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/sender_in_app_notification.dart';

/// Yuboruvchi bildirishnomalari — `SharedPreferences`da JSON ro‘yxat.
///
/// Kalit `userId` ga bog‘langan; [AuthRepository.logout] faqat sessiyani olib tashlaydi,
/// ushbu kalitlarni o‘chirmaydi — qayta kirganda ro‘yxat va o‘qilmagan indikator saqlanadi.
class SenderNotificationsStorage {
  SenderNotificationsStorage._();

  static String _key(String userId) => 'sender_in_app_notifications_v1_$userId';

  static Future<List<SenderInAppNotification>> load(String userId) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              SenderInAppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(
    String userId,
    List<SenderInAppNotification> items,
  ) async {
    final sp = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(items.map((e) => e.toJson()).toList(growable: false));
    await sp.setString(_key(userId), encoded);
  }
}
