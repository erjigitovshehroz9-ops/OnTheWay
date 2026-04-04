import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/support_request_entity.dart';

class SupportRequestRepository {
  SupportRequestRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;
  final _uuid = const Uuid();

  Future<void> submit({
    required String userId,
    required String userName,
    required String userPhone,
    required String roleStorage,
    required SupportRequestType requestType,
    required String message,
  }) async {
    await _db.insertSupportRequest(
      SupportRequestEntity(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        roleStorage: roleStorage,
        requestType: requestType,
        message: message,
        createdAt: DateTime.now(),
        status: SupportRequestStatus.fresh,
      ),
    );
  }

  Future<List<SupportRequestEntity>> listAll() => _db.listSupportRequests();

  Future<SupportRequestEntity?> getById(String id) => _db.getSupportRequestById(id);

  Future<void> updateStatus(String id, SupportRequestStatus status) async {
    await _db.updateSupportRequestStatus(id, status);
  }
}
