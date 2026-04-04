import '../core/utils/phone_validator.dart';
import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    this.role,
    required this.phoneVerified,
    required this.offerAccepted,
    required this.createdAt,
    this.firstName = '',
    this.lastName = '',
    this.telegram = '',
    this.rating = 5.0,
    this.completedJobs = 0,
    this.complaintCount = 0,
    this.praiseCount = 0,
    this.blocked = false,
    this.regionCode,
    this.districtCode,
    this.workingRegionKey = '',
    this.workingDistrictKey = '',
    this.isSystemAdmin = false,
    this.courierLat,
    this.courierLng,
    this.courierLocationUpdatedAt,
    this.courierTransportTypes = const [],
  });

  final String id;
  final String phone;
  final UserRole? role;
  final bool phoneVerified;
  final bool offerAccepted;
  final DateTime createdAt;

  final String firstName;
  final String lastName;
  final String telegram;
  final double rating;
  final int completedJobs;
  final int complaintCount;
  final int praiseCount;
  final bool blocked;
  final String? regionCode;
  final String? districtCode;
  /// `normalizeLocationKey` + kanonik tuman (profil tanlovi bo‘yicha).
  final String workingRegionKey;
  final String workingDistrictKey;
  final bool isSystemAdmin;
  final double? courierLat;
  final double? courierLng;
  final DateTime? courierLocationUpdatedAt;
  /// Kuryer uchun tanlangan transport kodlari (kanonik kalitlar, masalan `mototsikl`).
  final List<String> courierTransportTypes;

  /// Admin panel: faqat ushbu raqam (normalizatsiyadan keyin `998988082846`).
  static const String _adminPanelMsisdn998 = '998988082846';

  bool get canAccessAdminPanel {
    final n = PhoneValidator.normalizeTo998Msisdn(phone);
    return n == _adminPanelMsisdn998;
  }

  String get displayName {
    final t = '$firstName $lastName'.trim();
    if (t.isEmpty) return phone;
    return t;
  }

  AppUser copyWith({
    String? id,
    String? phone,
    UserRole? role,
    bool? phoneVerified,
    bool? offerAccepted,
    DateTime? createdAt,
    String? firstName,
    String? lastName,
    String? telegram,
    double? rating,
    int? completedJobs,
    int? complaintCount,
    int? praiseCount,
    bool? blocked,
    String? regionCode,
    String? districtCode,
    String? workingRegionKey,
    String? workingDistrictKey,
    bool? isSystemAdmin,
    double? courierLat,
    double? courierLng,
    DateTime? courierLocationUpdatedAt,
    List<String>? courierTransportTypes,
  }) {
    return AppUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      offerAccepted: offerAccepted ?? this.offerAccepted,
      createdAt: createdAt ?? this.createdAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      telegram: telegram ?? this.telegram,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      complaintCount: complaintCount ?? this.complaintCount,
      praiseCount: praiseCount ?? this.praiseCount,
      blocked: blocked ?? this.blocked,
      regionCode: regionCode ?? this.regionCode,
      districtCode: districtCode ?? this.districtCode,
      workingRegionKey: workingRegionKey ?? this.workingRegionKey,
      workingDistrictKey: workingDistrictKey ?? this.workingDistrictKey,
      isSystemAdmin: isSystemAdmin ?? this.isSystemAdmin,
      courierLat: courierLat ?? this.courierLat,
      courierLng: courierLng ?? this.courierLng,
      courierLocationUpdatedAt:
          courierLocationUpdatedAt ?? this.courierLocationUpdatedAt,
      courierTransportTypes:
          courierTransportTypes ?? this.courierTransportTypes,
    );
  }
}
