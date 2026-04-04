import '../database/app_database.dart';
import '../../models/app_user.dart';
import 'user_backing_store.dart';

class SqliteUserBackingStore implements UserBackingStore {
  SqliteUserBackingStore(this._db);

  final AppDatabase _db;

  @override
  Future<AppUser?> getUserById(String id) => _db.getUserById(id);

  @override
  Future<AppUser?> getUserByPhone(String phone) => _db.getUserByPhone(phone);

  @override
  Future<List<AppUser>> listAllUsers() => _db.listAllUsers();

  @override
  Future<void> upsertUser(AppUser user) => _db.upsertUser(user);
}
