import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/bootstrap/sqlite_platform.dart';
import 'core/config/supabase_config.dart';
import 'core/debug/bootstrap_error_app.dart';
import 'core/debug/global_error_handling.dart';
import 'services/push/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandling();

  Object? bootstrapError;
  StackTrace? bootstrapStack;

  try {
    if (!kIsWeb) {
      await configureSqliteForPlatform();
    }

    await Supabase.initialize(
      url: kSupabaseUrl,
      anonKey: kSupabaseAnonKey,
      authOptions: kSupabaseFlutterAuthOptions(),
    );
    logSupabase('Supabase.initialize completed');
    // Stale GoTrue JWT in SharedPreferences forces Bearer=<bad token> instead of the anon
    // key and breaks PostgREST/RPC/Realtime (often seen on Android after backup or tests).
    await clearStaleSupabaseAuthSession();
    unawaited(probeSupabaseRestOrders());

    try {
      await PushNotificationService.initialize();
    } catch (e, st) {
      debugPrint('[push] init non-fatal: $e');
      debugPrintStack(stackTrace: st);
    }
  } catch (error, stack) {
    bootstrapError = error;
    bootstrapStack = stack;
    debugPrint('Bootstrap error: $error');
    debugPrintStack(stackTrace: stack);
  }

  if (bootstrapError != null) {
    runApp(
      BootstrapErrorApp(
        error: bootstrapError,
        stackTrace: bootstrapStack,
      ),
    );
    return;
  }

  try {
    runApp(
      const ProviderScope(
        child: CourierApp(),
      ),
    );
  } catch (error, stack) {
    debugPrint('runApp error: $error');
    debugPrintStack(stackTrace: stack);
    runApp(
      BootstrapErrorApp(
        error: error,
        stackTrace: stack,
      ),
    );
  }
}