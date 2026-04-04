import 'package:flutter/foundation.dart';

import '../core/web/user_backing_store.dart';
import '../core/utils/phone_validator.dart';
import '../models/app_user.dart';
import '../models/order_feedback_type.dart';
import '../models/user_role.dart';

class UserRepository {
  UserRepository(this._store);

  final UserBackingStore _store;

  Future<List<AppUser>> listAllUsers() => _store.listAllUsers();

  Future<AppUser?> getUser(String id) => _store.getUserById(id);

  /// [msisdn998] — `998` + 9 raqam (masalan `998901234567`), [PhoneValidator.normalizeTo998Msisdn] natijasi.
  Future<String?> findUserIdByNormalizedPhone(String msisdn998) async {
    final all = await listAllUsers();
    for (final u in all) {
      final n = PhoneValidator.normalizeTo998Msisdn(u.phone);
      if (n == msisdn998) return u.id;
    }
    return null;
  }

  Future<void> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? telegram,
  }) async {
    final u = await _store.getUserById(userId);
    if (u == null) return;
    await _store.upsertUser(
      u.copyWith(
        firstName: firstName ?? u.firstName,
        lastName: lastName ?? u.lastName,
        telegram: telegram ?? u.telegram,
      ),
    );
  }

  Future<void> setCourierServiceArea({
    required String userId,
    required String regionCode,
    required String districtCode,
  }) async {
    final u = await _store.getUserById(userId);
    if (u == null) return;
    await _store.upsertUser(
      u.copyWith(regionCode: regionCode, districtCode: districtCode),
    );
  }

  /// Public app: only [UserRole.sender] or [UserRole.courier].
  Future<void> switchAppRole({
    required String userId,
    required UserRole newRole,
    required bool callerIsSystemAdmin,
  }) async {
    if (newRole == UserRole.admin && !callerIsSystemAdmin) {
      throw StateError('admin_role_forbidden');
    }
    final u = await _store.getUserById(userId);
    if (u == null) throw StateError('user_not_found');
    await _store.upsertUser(u.copyWith(role: newRole));
    debugPrint('[user] role switched $userId -> ${newRole.storageValue}');
  }

  Future<void> adminSetRole({
    required String targetUserId,
    required UserRole role,
    required bool setSystemAdmin,
  }) async {
    final u = await _store.getUserById(targetUserId);
    if (u == null) throw StateError('user_not_found');
    await _store.upsertUser(
      u.copyWith(
        role: role,
        isSystemAdmin: setSystemAdmin,
      ),
    );
  }

  Future<void> setBlocked(String userId, bool blocked) async {
    final u = await _store.getUserById(userId);
    if (u == null) throw StateError('user_not_found');
    await _store.upsertUser(u.copyWith(blocked: blocked));
  }

  Future<void> applyFeedbackDelta({
    required String userId,
    required int complaintDelta,
    required int praiseDelta,
  }) async {
    final u = await _store.getUserById(userId);
    if (u == null) return;
    await _store.upsertUser(
      u.copyWith(
        complaintCount: u.complaintCount + complaintDelta,
        praiseCount: u.praiseCount + praiseDelta,
        rating: _nextRating(u.rating, praiseDelta, complaintDelta),
      ),
    );
  }

  double _nextRating(double current, int praise, int complaint) {
    var r = current + praise * 0.05 - complaint * 0.15;
    if (r > 5) r = 5;
    if (r < 1) r = 1;
    return r;
  }

  /// `order_feedback` yuborilganda mahalliy profil bahosi (taxminiy EMA + tur bo‘yicha tuzatish).
  Future<void> applyOrderFeedbackImpact({
    required String toUserId,
    required int rating,
    required OrderFeedbackType feedbackType,
  }) async {
    final u = await _store.getUserById(toUserId);
    if (u == null) return;
    var r = u.rating * 0.82 + rating * 0.18;
    if (feedbackType == OrderFeedbackType.complaint) {
      r -= 0.22;
    } else if (feedbackType == OrderFeedbackType.praise) {
      r += 0.06;
    }
    r = r.clamp(1.0, 5.0);
    await _store.upsertUser(
      u.copyWith(
        rating: r,
        complaintCount: u.complaintCount +
            (feedbackType == OrderFeedbackType.complaint ? 1 : 0),
        praiseCount:
            u.praiseCount + (feedbackType == OrderFeedbackType.praise ? 1 : 0),
      ),
    );
  }

  Future<void> incrementCompletedJobs(String userId) async {
    final u = await _store.getUserById(userId);
    if (u == null) return;
    await _store.upsertUser(
      u.copyWith(completedJobs: u.completedJobs + 1),
    );
  }

  Future<void> updateCourierLivePosition({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    final u = await _store.getUserById(userId);
    if (u == null) return;
    await _store.upsertUser(
      u.copyWith(
        courierLat: lat,
        courierLng: lng,
        courierLocationUpdatedAt: DateTime.now(),
      ),
    );
  }

  /// FK for jobs: remote [senderId] may not exist on this device yet.
  Future<void> ensureRemoteSenderStub(String senderId) async {
    if (senderId.isEmpty) return;
    if (await _store.getUserById(senderId) != null) return;

    for (var i = 0; i < 50; i++) {
      final h = (senderId.hashCode + i * 1009).abs();
      final nine = (h % 1000000000).toString().padLeft(9, '0');
      final phone = '+998$nine';
      if (await _store.getUserByPhone(phone) != null) continue;

      await _store.upsertUser(
        AppUser(
          id: senderId,
          phone: phone,
          role: UserRole.sender,
          phoneVerified: true,
          offerAccepted: true,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
    debugPrint('[user] ensureRemoteSenderStub failed for $senderId (no free synthetic phone)');
  }
}
