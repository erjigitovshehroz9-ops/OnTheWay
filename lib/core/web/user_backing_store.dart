import '../../models/app_user.dart';

/// User reads/writes abstracted so web can use SharedPreferences instead of SQLite.
abstract class UserBackingStore {
  Future<AppUser?> getUserById(String id);

  Future<AppUser?> getUserByPhone(String phone);

  Future<List<AppUser>> listAllUsers();

  Future<void> upsertUser(AppUser user);
}
