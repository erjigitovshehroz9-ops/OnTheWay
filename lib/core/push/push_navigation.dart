import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_routes.dart';
import 'push_notification_type.dart';

/// FCM `data` dan marshrut (GoRouter).
class PushNavigation {
  PushNavigation._();

  static void applyFromData(
    GoRouter router,
    Map<String, dynamic> data,
  ) {
    final route = (data['route'] ?? '').toString().trim();
    final orderId = (data['order_id'] ?? '').toString().trim();
    final type = PushNotificationType.fromRaw(data['type']?.toString());

    if (kDebugMode) {
      debugPrint(
        '[push] tap navigate route=$route order=$orderId type=${type.storageValue}',
      );
    }

    if (orderId.isEmpty && route != 'admin_feedback') {
      return;
    }

    switch (route) {
      case 'auction':
        router.go(AppRoutes.jobAuction(orderId));
        return;
      case 'feedback':
        router.go('${AppRoutes.jobDetail(orderId)}?openFeedback=1');
        return;
      case 'admin_feedback':
        router.go('${AppRoutes.admin}?tab=feedback');
        return;
      case 'job':
      default:
        if (type == PushNotificationType.auctionOutbid ||
            type == PushNotificationType.auctionLost ||
            type == PushNotificationType.auctionWon) {
          router.go(AppRoutes.jobAuction(orderId));
          return;
        }
        router.go(AppRoutes.jobDetail(orderId));
    }
  }
}
