/// Yuboruvchi ilova ichidagi bildirishnoma (push emas).
enum SenderNotificationKind {
  auctionStarted,
  auctionEndedAssigned,
  auctionEndedReopened,
  auctionEndedCancelled,
  /// Kuryer A (olib ketish) nuqtasiga ~1 km qolganda — yuboruvchiga.
  courierNearPickup1Km,
  /// Kuryer B ga ~5 km — yuboruvchi (+ ro‘yxatdan o‘tgan qabul qiluvchi).
  courierNearDropoff5Km,
  /// Kuryer B ga ~2 km — xuddi shu.
  courierNearDropoff2Km,
}

class SenderInAppNotification {
  const SenderInAppNotification({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.jobId,
    this.read = false,
    /// Hodisa paytida joriy tilda tuzilgan matn (eski yozuvlar bo‘sh bo‘lishi mumkin).
    this.displayMessage,
  });

  final String id;
  final SenderNotificationKind kind;
  final String? jobId;
  final DateTime createdAt;
  final bool read;
  final String? displayMessage;

  SenderInAppNotification copyWith({
    String? id,
    SenderNotificationKind? kind,
    String? jobId,
    DateTime? createdAt,
    bool? read,
    String? displayMessage,
  }) {
    return SenderInAppNotification(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      jobId: jobId ?? this.jobId,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      displayMessage: displayMessage ?? this.displayMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'jobId': jobId,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        if (displayMessage != null) 'displayMessage': displayMessage,
      };

  static SenderInAppNotification fromJson(Map<String, dynamic> j) {
    SenderNotificationKind kind;
    try {
      kind = SenderNotificationKind.values.byName(j['kind'] as String);
    } catch (_) {
      kind = SenderNotificationKind.auctionStarted;
    }
    return SenderInAppNotification(
      id: j['id'] as String,
      kind: kind,
      jobId: j['jobId'] as String?,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      read: j['read'] as bool? ?? false,
      displayMessage: j['displayMessage'] as String?,
    );
  }
}
