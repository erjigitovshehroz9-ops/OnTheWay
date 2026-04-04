import 'user_role.dart';
import 'app_user.dart';

Map<String, dynamic> appUserToJson(AppUser u) {
  return {
    'id': u.id,
    'phone': u.phone,
    'role': u.role?.storageValue,
    'phoneVerified': u.phoneVerified,
    'offerAccepted': u.offerAccepted,
    'createdAt': u.createdAt.toIso8601String(),
    'firstName': u.firstName,
    'lastName': u.lastName,
    'telegram': u.telegram,
    'rating': u.rating,
    'completedJobs': u.completedJobs,
    'complaintCount': u.complaintCount,
    'praiseCount': u.praiseCount,
    'blocked': u.blocked,
    'regionCode': u.regionCode,
    'districtCode': u.districtCode,
    'workingRegionKey': u.workingRegionKey,
    'workingDistrictKey': u.workingDistrictKey,
    'isSystemAdmin': u.isSystemAdmin,
    'courierLat': u.courierLat,
    'courierLng': u.courierLng,
    'courierLocationUpdatedAt': u.courierLocationUpdatedAt?.toIso8601String(),
    'courierTransportTypes': u.courierTransportTypes,
  };
}

AppUser appUserFromJson(Map<String, dynamic> m) {
  final roleRaw = m['role'] as String?;
  return AppUser(
    id: m['id'] as String,
    phone: m['phone'] as String,
    role: UserRole.tryParse(roleRaw),
    phoneVerified: m['phoneVerified'] as bool? ?? false,
    offerAccepted: m['offerAccepted'] as bool? ?? false,
    createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ??
        DateTime.now(),
    firstName: m['firstName'] as String? ?? '',
    lastName: m['lastName'] as String? ?? '',
    telegram: m['telegram'] as String? ?? '',
    rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
    completedJobs: (m['completedJobs'] as num?)?.toInt() ?? 0,
    complaintCount: (m['complaintCount'] as num?)?.toInt() ?? 0,
    praiseCount: (m['praiseCount'] as num?)?.toInt() ?? 0,
    blocked: m['blocked'] as bool? ?? false,
    regionCode: m['regionCode'] as String?,
    districtCode: m['districtCode'] as String?,
    workingRegionKey: m['workingRegionKey'] as String? ?? '',
    workingDistrictKey: m['workingDistrictKey'] as String? ?? '',
    isSystemAdmin: m['isSystemAdmin'] as bool? ?? false,
    courierLat: (m['courierLat'] as num?)?.toDouble(),
    courierLng: (m['courierLng'] as num?)?.toDouble(),
    courierLocationUpdatedAt: m['courierLocationUpdatedAt'] != null
        ? DateTime.tryParse(m['courierLocationUpdatedAt'] as String)
        : null,
    courierTransportTypes: (m['courierTransportTypes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
  );
}
