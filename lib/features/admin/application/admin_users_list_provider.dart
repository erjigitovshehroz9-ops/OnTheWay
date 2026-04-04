import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../models/app_user.dart';

final adminUsersListProvider = FutureProvider<List<AppUser>>((ref) async {
  final r = await ref.watch(userRepositoryProvider.future);
  return r.listAllUsers();
});
