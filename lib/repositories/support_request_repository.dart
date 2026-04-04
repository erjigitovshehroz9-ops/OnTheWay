import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/support_request_entity.dart';

class SupportRequestRepository {
  SupportRequestRepository({AppDatabase? database}) : _db = database;

  final AppDatabase? _db;
  /// Shared across all web instances so provider rebuilds do not wipe data.
  static final List<SupportRequestEntity> _webOnly = [];
  final _uuid = const Uuid();

  Future<void> submit({
    required String userId,
    required String userName,
    required String userPhone,
    required String roleStorage,
    required SupportRequestType requestType,
    required String message,
  }) async {
    final entity = SupportRequestEntity(
      id: _uuid.v4(),
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      roleStorage: roleStorage,
      requestType: requestType,
      message: message,
      createdAt: DateTime.now(),
      status: SupportRequestStatus.fresh,
    );
    final db = _db;
    if (db != null) {
      await db.insertSupportRequest(entity);
    } else {
      _webOnly.insert(0, entity);
    }
  }

  Future<List<SupportRequestEntity>> listAll() {
    final db = _db;
    if (db != null) return db.listSupportRequests();
    return Future.value(List<SupportRequestEntity>.from(_webOnly));
  }

  Future<SupportRequestEntity?> getById(String id) {
    final db = _db;
    if (db != null) return db.getSupportRequestById(id);
    try {
      return Future.value(_webOnly.firstWhere((e) => e.id == id));
    } catch (_) {
      return Future.value(null);
    }
  }

  Future<void> updateStatus(String id, SupportRequestStatus status) async {
    final db = _db;
    if (db != null) {
      await db.updateSupportRequestStatus(id, status);
      return;
    }
    final list = _webOnly;
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final prev = list[i];
    list[i] = SupportRequestEntity(
      id: prev.id,
      userId: prev.userId,
      userName: prev.userName,
      userPhone: prev.userPhone,
      roleStorage: prev.roleStorage,
      requestType: prev.requestType,
      message: prev.message,
      createdAt: prev.createdAt,
      status: status,
    );
  }
}
