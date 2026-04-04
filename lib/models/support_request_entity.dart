/// Foydalanuvchi murojaati (shikoyat / maqtov / ariza / taklif).
class SupportRequestEntity {
  const SupportRequestEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.roleStorage,
    required this.requestType,
    required this.message,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String roleStorage;
  final SupportRequestType requestType;
  final String message;
  final DateTime createdAt;
  final SupportRequestStatus status;
}

enum SupportRequestType {
  complaint,
  praise,
  application,
  suggestion;

  String toStorage() => name;

  static SupportRequestType fromStorage(String raw) {
    for (final v in SupportRequestType.values) {
      if (v.name == raw) return v;
    }
    return SupportRequestType.application;
  }
}

enum SupportRequestStatus {
  fresh,
  read,
  resolved;

  String toStorage() => switch (this) {
        SupportRequestStatus.fresh => 'new',
        SupportRequestStatus.read => 'read',
        SupportRequestStatus.resolved => 'resolved',
      };

  static SupportRequestStatus fromStorage(String raw) {
    switch (raw) {
      case 'read':
        return SupportRequestStatus.read;
      case 'resolved':
        return SupportRequestStatus.resolved;
      default:
        return SupportRequestStatus.fresh;
    }
  }
}
