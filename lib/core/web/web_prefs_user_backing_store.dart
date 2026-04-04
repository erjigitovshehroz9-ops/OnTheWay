import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_user.dart';
import '../../models/app_user_json.dart';
import 'user_backing_store.dart';

/// Temporary web storage for [AppUser] rows (replaces SQLite `users` table).
class WebPrefsUserBackingStore implements UserBackingStore {
  WebPrefsUserBackingStore(this._prefs);

  final SharedPreferences _prefs;

  static const _usersKey = 'web_users_json_v1';

  Map<String, dynamic> _readMap() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) {
        return d.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return {};
  }

  Future<void> _writeMap(Map<String, dynamic> m) async {
    await _prefs.setString(_usersKey, jsonEncode(m));
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    final m = _readMap();
    final row = m[id];
    if (row is! Map) return null;
    return appUserFromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<AppUser?> getUserByPhone(String phone) async {
    final target = phone.trim();
    for (final e in _readMap().values) {
      if (e is! Map) continue;
      final u = appUserFromJson(Map<String, dynamic>.from(e));
      if (u.phone.trim() == target) return u;
    }
    return null;
  }

  @override
  Future<List<AppUser>> listAllUsers() async {
    final out = <AppUser>[];
    for (final e in _readMap().values) {
      if (e is! Map) continue;
      out.add(appUserFromJson(Map<String, dynamic>.from(e)));
    }
    return out;
  }

  @override
  Future<void> upsertUser(AppUser user) async {
    final m = _readMap();
    m[user.id] = appUserToJson(user);
    await _writeMap(m);
  }
}
