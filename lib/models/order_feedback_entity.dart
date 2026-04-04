import 'order_feedback_type.dart';

class OrderFeedbackEntity {
  const OrderFeedbackEntity({
    required this.id,
    required this.orderId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromRole,
    required this.toRole,
    required this.rating,
    required this.feedbackType,
    this.complaintCategory,
    this.praiseCategory,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.complaintStatus,
    this.adminNote,
    this.reviewedBy,
    this.reviewedAt,
  });

  final String id;
  final String orderId;
  final String fromUserId;
  final String toUserId;
  final String fromRole;
  final String toRole;
  final int rating;
  final OrderFeedbackType feedbackType;
  final String? complaintCategory;
  final String? praiseCategory;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `new` / `reviewed` / `resolved` — faqat shikoyatlar uchun.
  final String? complaintStatus;
  final String? adminNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  OrderFeedbackEntity copyWith({
    String? complaintStatus,
    String? adminNote,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? updatedAt,
  }) {
    return OrderFeedbackEntity(
      id: id,
      orderId: orderId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromRole: fromRole,
      toRole: toRole,
      rating: rating,
      feedbackType: feedbackType,
      complaintCategory: complaintCategory,
      praiseCategory: praiseCategory,
      comment: comment,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      complaintStatus: complaintStatus ?? this.complaintStatus,
      adminNote: adminNote ?? this.adminNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  static OrderFeedbackEntity fromSupabaseMap(Map<String, dynamic> map) {
    final idRaw = map['id'];
    final id = idRaw == null ? '' : idRaw.toString();
    return OrderFeedbackEntity(
      id: id,
      orderId: map['order_id']?.toString() ?? '',
      fromUserId: map['from_user_id']?.toString() ?? '',
      toUserId: map['to_user_id']?.toString() ?? '',
      fromRole: map['from_role']?.toString() ?? '',
      toRole: map['to_role']?.toString() ?? '',
      rating: (map['rating'] as num?)?.round().clamp(1, 5) ?? 1,
      feedbackType:
          OrderFeedbackType.fromStorage(map['feedback_type']?.toString() ?? 'rating'),
      complaintCategory: map['complaint_category']?.toString(),
      praiseCategory: map['praise_category']?.toString(),
      comment: map['comment']?.toString(),
      createdAt: _readMs(map['created_at']),
      updatedAt: _readMs(map['updated_at'] ?? map['created_at']),
      complaintStatus: map['complaint_status']?.toString(),
      adminNote: map['admin_note']?.toString(),
      reviewedBy: map['reviewed_by']?.toString(),
      reviewedAt: map['reviewed_at'] != null ? _readMs(map['reviewed_at']) : null,
    );
  }

  static DateTime _readMs(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

/// Kategoriya kalitlari (l10n bilan ko‘rsatiladi).
abstract final class OrderFeedbackCategories {
  static const List<String> complaintKeys = [
    'late',
    'rude',
    'careless_order',
    'address_issue',
    'other',
  ];

  static const List<String> praiseKeys = [
    'fast_delivery',
    'polite',
    'careful',
    'reliable',
    'other',
  ];
}
