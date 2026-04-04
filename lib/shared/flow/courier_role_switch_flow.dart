import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/routing/app_router.dart';
import '../../features/sender/application/sender_jobs_provider.dart';
import '../../models/user_role.dart';
import '../widgets/courier_transport_setup_sheet.dart';

/// Yuboruvchi → kuryer: saqlangan transport bo‘lmasa, avval transport tanlash,
/// keyin rol almashtiriladi. Mavjud transportlar bo‘lsa, darhol rol o‘zgaradi.
Future<bool> ensureCourierTransportAndSwitchRole({
  required WidgetRef ref,
  required String userId,
  required bool callerIsSystemAdmin,
}) async {
  final auth = await ref.read(authRepositoryProvider.future);
  final keys = await auth.effectiveCourierTransportKeys(userId);
  if (keys.isNotEmpty) {
    await _switchToCourier(ref, userId, callerIsSystemAdmin);
    return true;
  }

  final sheetContext = rootNavigatorKey.currentContext;
  if (sheetContext == null || !sheetContext.mounted) return false;
  final saved = await showCourierTransportSetupBottomSheet(
    context: sheetContext,
    userId: userId,
  );
  if (saved != true) return false;

  await _switchToCourier(ref, userId, callerIsSystemAdmin);
  return true;
}

Future<void> _switchToCourier(
  WidgetRef ref,
  String userId,
  bool callerIsSystemAdmin,
) async {
  final users = await ref.read(userRepositoryProvider.future);
  await users.switchAppRole(
    userId: userId,
    newRole: UserRole.courier,
    callerIsSystemAdmin: callerIsSystemAdmin,
  );
  await ref.read(authSessionProvider.notifier).refresh();
  ref.invalidate(courierJobsProvider);
  ref.invalidate(senderJobsProvider(userId));
}
