import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../services/push/push_notification_service.dart';
import '../providers/core_providers.dart';
import '../routing/app_router.dart';

/// Router biriktirish, sessiya bo‘yicha token sync, logoutda deactivate.
class PushLifecycleHost extends ConsumerStatefulWidget {
  const PushLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushLifecycleHost> createState() => _PushLifecycleHostState();
}

class _PushLifecycleHostState extends ConsumerState<PushLifecycleHost> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    PushNotificationService.attachRouter(router);

    ref.listen<AsyncValue<AppUser?>>(authSessionProvider, (prev, next) {
      final prevId = prev?.valueOrNull?.id;
      final nextId = next.valueOrNull?.id;

      if (prevId != null && nextId == null) {
        PushNotificationService.onLogout(prevId);
      }
    });

    final user = ref.watch(authSessionProvider).valueOrNull;
    final uid = user?.id;
    if (uid != null && uid.isNotEmpty && uid != _lastUserId) {
      _lastUserId = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PushNotificationService.registerForUser(uid);
      });
    } else if (uid == null) {
      _lastUserId = null;
    }

    return widget.child;
  }
}
