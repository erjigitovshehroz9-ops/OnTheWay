import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/push/push_navigation.dart';
import '../../repositories/push_device_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint(
      '[push] background message id=${message.messageId} data=${message.data}',
    );
  }
}

/// FCM + mahalliy bildirishnomalar + marshrutlash.
abstract final class PushNotificationService {
  PushNotificationService._();

  static final _local = FlutterLocalNotificationsPlugin();
  static GoRouter? _router;
  static String? _deviceId;
  static String? _lastToken;
  static String? _activeUserId;
  static bool _firebaseOk = false;
  static const _androidChannelId = 'kuryer_push_high';
  static const _androidChannelName = 'Kuryer push';

  static void attachRouter(GoRouter router) {
    _router = router;
  }

  static Future<bool> initialize() async {
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint('[push] skip Firebase on web (configure separately)');
      }
      return false;
    }
    if (!(Platform.isAndroid || Platform.isIOS)) {
      if (kDebugMode) {
        debugPrint('[push] skip Firebase on desktop');
      }
      return false;
    }

    try {
      await Firebase.initializeApp();
      _firebaseOk = true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[push] Firebase.initializeApp failed: $e');
        debugPrintStack(stackTrace: st);
      }
      return false;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      final a = settings.authorizationStatus;
      debugPrint(
        '[push] permission granted=${a == AuthorizationStatus.authorized || a == AuthorizationStatus.provisional}',
      );
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      _lastToken = t;
      if (kDebugMode) {
        debugPrint('[push] token refresh len=${t.length}');
      }
      final u = _activeUserId;
      if (u != null && u.isNotEmpty) {
        await registerForUser(u);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
      final d = m.data;
      final title = m.notification?.title ?? (d['title'] ?? 'Kuryer').toString();
      final body = m.notification?.body ?? (d['body'] ?? '').toString();
      if (kDebugMode) {
        debugPrint(
          '[push] foreground type=${d['type']} order=${d['order_id']} title=$title',
        );
      }
      await _showLocalBanner(title, body, d);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) {
      _handleDataTap(m.data);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDataTap(initial.data);
      });
    }

    return true;
  }

  static Future<void> _initLocalNotifications() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        final p = details.payload;
        if (p == null || p.isEmpty) return;
        final parts = p.split('\u001e');
        final map = <String, String>{};
        for (final part in parts) {
          final i = part.indexOf('=');
          if (i > 0) {
            map[part.substring(0, i)] = part.substring(i + 1);
          }
        }
        _handleDataTap(map);
      },
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        importance: Importance.high,
      ),
    );
  }

  static Future<void> _showLocalBanner(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final payload = data.entries.map((e) => '${e.key}=${e.value}').join('\u001e');
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _local.show(
      id: data['order_id']?.hashCode ?? title.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  static void _handleDataTap(Map<String, dynamic> data) {
    final r = _router;
    if (r == null) {
      if (kDebugMode) {
        debugPrint('[push] tap ignored: router not attached');
      }
      return;
    }
    PushNavigation.applyFromData(r, data);
  }

  static Future<String> resolveDeviceId(SharedPreferences prefs) async {
    final existing = prefs.getString(StorageKeys.pushDeviceInstallationId)?.trim();
    if (existing != null && existing.isNotEmpty) {
      _deviceId = existing;
      return existing;
    }
    String id;
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      id = info.id;
    } else if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      id = info.identifierForVendor ?? const Uuid().v4();
    } else {
      id = const Uuid().v4();
    }
    await prefs.setString(StorageKeys.pushDeviceInstallationId, id);
    _deviceId = id;
    return id;
  }

  static String platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Joriy sessiya uchun tokenni serverga yozish.
  static Future<void> registerForUser(String userId) async {
    if (!_firebaseOk || userId.isEmpty) return;
    _activeUserId = userId;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('[push] no FCM token yet');
        }
        return;
      }
      _lastToken = token;
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await resolveDeviceId(prefs);
      final repo = PushDeviceRepository();
      if (kDebugMode) {
        debugPrint(
          '[push] send type=register user=$userId order=- platform=${platformLabel()}',
        );
      }
      await repo.registerToken(
        userId: userId,
        token: token,
        platform: platformLabel(),
        deviceId: deviceId,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[push] send fail error=$e');
        debugPrintStack(stackTrace: st);
      }
    }
  }

  static Future<void> onLogout(String userId) async {
    if (userId.isEmpty) return;
    _activeUserId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = _deviceId ?? await resolveDeviceId(prefs);
      final repo = PushDeviceRepository();
      await repo.deactivateForDevice(userId: userId, deviceId: deviceId);
      if (_lastToken != null && _lastToken!.isNotEmpty) {
        await repo.deactivateTokenValue(_lastToken!);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[push] logout deactivate fail: $e');
      }
    }
  }
}
