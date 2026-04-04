import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/storage_keys.dart';
import '../core/utils/phone_validator.dart';
import '../core/web/user_backing_store.dart';
import '../models/app_user.dart';
import '../models/job_transport_type.dart';
import '../models/user_role.dart';

class AuthRepository {
  AuthRepository({
    required UserBackingStore userStore,
    required SharedPreferences preferences,
  })  : _users = userStore,
        _prefs = preferences;

  final UserBackingStore _users;
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  String? debugValidatePhone(String rawPhone) {
    return PhoneValidator.validateUzbekPhone(rawPhone);
  }

  Future<AppUser> submitPhone(String rawPhone) async {
    debugPrint('[auth] request login started: raw=$rawPhone');
    final normalized = PhoneValidator.validateUzbekPhone(rawPhone);
    if (normalized == null) {
      debugPrint('[auth] validate failed: invalid_phone');
      throw FormatException('invalid_phone');
    }
    debugPrint('[auth] validate passed: normalized=$normalized');

    final existing = await _users.getUserByPhone(normalized);
    if (existing != null) {
      debugPrint('[auth] existing user found: id=${existing.id}');
      await _prefs.setString(StorageKeys.currentUserId, existing.id);
      debugPrint('[auth] session saved: ${existing.id}');
      debugPrint('[auth] auth repository success');
      return existing;
    }

    final user = AppUser(
      id: _uuid.v4(),
      phone: normalized,
      role: null,
      phoneVerified: false,
      offerAccepted: false,
      createdAt: DateTime.now(),
    );
    debugPrint('[auth] creating new user: id=${user.id}');
    await _users.upsertUser(user);
    debugPrint('[auth] sqlite write success: user upserted');
    await _prefs.setString(StorageKeys.currentUserId, user.id);
    debugPrint('[auth] session saved: ${user.id}');
    debugPrint('[auth] auth repository success');
    return user;
  }

  Future<AppUser> verifySms({
    required String phone,
    required String code,
  }) async {
    final normalized = PhoneValidator.validateUzbekPhone(phone);
    if (normalized == null) {
      throw FormatException('invalid_phone');
    }

    final expected = _expectedCode(normalized);
    if (code.trim() != expected) {
      throw FormatException('invalid_code');
    }

    var user = await _users.getUserByPhone(normalized);
    if (user == null) {
      user = AppUser(
        id: _uuid.v4(),
        phone: normalized,
        role: null,
        phoneVerified: false,
        offerAccepted: false,
        createdAt: DateTime.now(),
      );
      await _users.upsertUser(user);
      await _prefs.setString(StorageKeys.currentUserId, user.id);
    }

    final verified = user.copyWith(phoneVerified: true);
    await _users.upsertUser(verified);
    return verified;
  }

  String _expectedCode(String normalizedPhone) {
    final digits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      return digits.substring(digits.length - 6);
    }
    return digits;
  }

  Future<AppUser> acceptOffer() async {
    final id = _prefs.getString(StorageKeys.currentUserId);
    if (id == null) {
      throw StateError('no_session');
    }
    final user = await _users.getUserById(id);
    if (user == null) {
      throw StateError('no_user');
    }
    if (!user.phoneVerified) {
      throw StateError('phone_not_verified');
    }
    final next = user.copyWith(offerAccepted: true);
    await _users.upsertUser(next);
    return next;
  }

  Future<AppUser> setRole(UserRole role) async {
    final id = _prefs.getString(StorageKeys.currentUserId);
    if (id == null) {
      throw StateError('no_session');
    }
    final user = await _users.getUserById(id);
    if (user == null) {
      throw StateError('no_user');
    }
    if (!user.offerAccepted) {
      throw StateError('offer_not_accepted');
    }
    if (role == UserRole.admin && !user.isSystemAdmin) {
      throw StateError('admin_role_forbidden');
    }
    final next = user.copyWith(role: role);
    await _users.upsertUser(next);
    return next;
  }

  Future<AppUser> completeProfileSetup({
    required String fullName,
    required String phoneNumber,
    required UserRole role,
    required String regionCode,
    required String districtCode,
    required DateTime birthDate,
    String? gender,
    List<String> selectedTransportTypes = const [],
    String? profileImagePath,
  }) async {
    final id = _prefs.getString(StorageKeys.currentUserId);
    if (id == null) {
      throw StateError('no_session');
    }
    final user = await _users.getUserById(id);
    if (user == null) {
      throw StateError('no_user');
    }

    final normalizedName = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final parts = normalizedName.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final normTransport =
        JobTransportType.normalizeCourierKeyList(selectedTransportTypes);
    if (role == UserRole.courier && normTransport.isEmpty) {
      throw ArgumentError('courier_transport_required');
    }

    final next = user.copyWith(
      phone: phoneNumber,
      firstName: firstName,
      lastName: lastName,
      role: role,
      regionCode: regionCode,
      districtCode: districtCode,
      courierTransportTypes:
          role == UserRole.courier ? normTransport : const [],
    );
    await _users.upsertUser(next);
    final saved = await _users.getUserById(id);
    if (saved == null) {
      throw StateError('no_user');
    }

    // Temporary persistence for profile-only fields until dedicated DB columns exist.
    await _prefs.setString(
      'profile_birth_date_$id',
      birthDate.toIso8601String(),
    );
    final g = gender?.trim();
    if (g != null && g.isNotEmpty) {
      await _prefs.setString('profile_gender_$id', g);
    } else {
      await _prefs.remove('profile_gender_$id');
    }
    if (role == UserRole.courier) {
      await _prefs.setStringList(
        'profile_transport_types_$id',
        normTransport,
      );
    } else {
      await _prefs.remove('profile_transport_types_$id');
    }
    if (profileImagePath != null && profileImagePath.trim().isNotEmpty) {
      await _prefs.setString('profile_image_path_$id', profileImagePath.trim());
    } else {
      await _prefs.remove('profile_image_path_$id');
    }

    return saved;
  }

  /// Profil sozlamalaridagi kuryer transport turlari (`completeProfileSetup` bilan bir xil kalit).
  List<String> getProfileTransportTypes(String userId) {
    return _prefs.getStringList('profile_transport_types_$userId') ?? const [];
  }

  /// Sessiya foydalanuvchisi: SQLite + prefs birlashtirilgan kanonik kalitlar.
  List<String> resolvedCourierTransportKeys(AppUser user) {
    final fromUser =
        JobTransportType.normalizeCourierKeyList(user.courierTransportTypes);
    if (fromUser.isNotEmpty) return fromUser;
    return JobTransportType.normalizeCourierKeyList(
      getProfileTransportTypes(user.id),
    );
  }

  /// Auksion / repository: prefs dan DB ga sinxronlash bilan.
  Future<List<String>> effectiveCourierTransportKeys(String userId) async {
    final user = await _users.getUserById(userId);
    if (user == null) {
      return JobTransportType.normalizeCourierKeyList(
        getProfileTransportTypes(userId),
      );
    }
    final synced = await _syncCourierTransportFromPrefs(user);
    return resolvedCourierTransportKeys(synced);
  }

  Future<AppUser> _syncCourierTransportFromPrefs(AppUser user) async {
    if (user.role != UserRole.courier) return user;
    if (user.courierTransportTypes.isNotEmpty) return user;
    final prefs = getProfileTransportTypes(user.id);
    final norm = JobTransportType.normalizeCourierKeyList(prefs);
    if (norm.isEmpty) return user;
    final updated = user.copyWith(courierTransportTypes: norm);
    await _users.upsertUser(updated);
    return updated;
  }

  /// Kuryer transportlarini saqlash (kamida bitta talab qilinadi).
  Future<void> saveProfileTransportTypes(
    String userId,
    List<String> storageKeys,
  ) async {
    final norm = JobTransportType.normalizeCourierKeyList(storageKeys);
    if (norm.isEmpty) {
      throw ArgumentError('transport_types_empty');
    }
    await _prefs.setStringList(
      'profile_transport_types_$userId',
      List<String>.from(norm),
    );
    final user = await _users.getUserById(userId);
    if (user != null) {
      await _users.upsertUser(user.copyWith(courierTransportTypes: norm));
    }
  }

  Future<AppUser?> currentUser() async {
    final id = _prefs.getString(StorageKeys.currentUserId);
    debugPrint('[auth] currentUser read session id=$id');
    if (id == null) return null;
    var user = await _users.getUserById(id);
    debugPrint('[auth] currentUser db result=${user?.id}');
    if (user == null) return null;
    user = await _syncCourierTransportFromPrefs(user);
    return user;
  }

  /// Profil yorlig‘i: ism (SQLite), qo‘shimcha telefon va rasm yo‘li (SharedPreferences).
  ///
  /// [secondaryPhoneRaw] bo‘sh bo‘lsa — saqlangan qo‘shimcha raqam olib tashlanadi.
  /// [profileImagePathUpdate] `null` bo‘lsa rasm yo‘li o‘zgarmaydi; bo‘sh qator — rasm olib tashlanadi.
  Future<AppUser> updateSenderProfileDetails({
    required String fullName,
    required String secondaryPhoneRaw,
    String? profileImagePathUpdate,
  }) async {
    final id = _prefs.getString(StorageKeys.currentUserId);
    if (id == null) throw StateError('no_session');
    final user = await _users.getUserById(id);
    if (user == null) throw StateError('no_user');

    final trimmedSecondary = secondaryPhoneRaw.trim();
    if (trimmedSecondary.isNotEmpty) {
      final normalized = PhoneValidator.validateUzbekPhone(trimmedSecondary);
      if (normalized == null) {
        throw FormatException('invalid_secondary_phone');
      }
      if (normalized == user.phone) {
        throw FormatException('secondary_same_as_primary');
      }
      await _prefs.setString('profile_secondary_phone_$id', normalized);
    } else {
      await _prefs.remove('profile_secondary_phone_$id');
    }

    if (profileImagePathUpdate != null) {
      final p = profileImagePathUpdate.trim();
      if (p.isEmpty) {
        await _prefs.remove('profile_image_path_$id');
      } else {
        await _prefs.setString('profile_image_path_$id', p);
      }
    }

    final normalizedName = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final parts = normalizedName.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final next = user.copyWith(
      firstName: firstName,
      lastName: lastName,
    );
    await _users.upsertUser(next);
    return next;
  }

  /// Sessiyani tozalaydi. Yuboruvchi bildirishnomalari (`sender_in_app_notifications_v1_*`)
  /// va boshqa profil kalitlari saqlanib qoladi — qayta kirganda ko‘rinadi.
  Future<void> logout() async {
    await _prefs.remove(StorageKeys.currentUserId);
  }
}
