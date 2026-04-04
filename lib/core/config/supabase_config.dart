import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Production Supabase project (same for all platforms; not dart-define split).
const String kSupabaseUrl = 'https://qerxtdefaydbeihosaud.supabase.co';
const String kSupabaseAnonKey =
    'sb_publishable_hWIEHxdf1VwfiTs0ui8szw_R3DQUDqT';

/// Options for this app: identity is local (SQLite); we only use the anon key for
/// PostgREST / RPC / Realtime. Deep-link session detection and token refresh are unnecessary.
FlutterAuthClientOptions kSupabaseFlutterAuthOptions() =>
    const FlutterAuthClientOptions(
      autoRefreshToken: false,
      detectSessionInUri: false,
    );

void logSupabase(String message, {Object? error, StackTrace? stackTrace}) {
  developer.log(
    message,
    name: 'SupabaseBootstrap',
    error: error,
    stackTrace: stackTrace,
  );
}

/// Clears any persisted GoTrue session so REST/Realtime use the anon key.
/// Call after [Supabase.initialize]. Safe when the app does not use Supabase Auth for login.
Future<void> clearStaleSupabaseAuthSession() async {
  try {
    await Supabase.instance.client.auth.signOut();
    logSupabase('GoTrue session cleared (anon-only app path)');
  } catch (e, st) {
    logSupabase(
      'signOut cleanup failed (non-fatal): $e',
      error: e,
      stackTrace: st,
    );
  }
}

/// Optional sanity check; does not throw. Logs success/failure for release logcat.
Future<void> probeSupabaseRestOrders() async {
  try {
    await Supabase.instance.client.from('orders').select('id').limit(1);
    logSupabase('REST probe OK (orders select limit 1)');
  } catch (e, st) {
    logSupabase(
      'REST probe FAILED: $e',
      error: e,
      stackTrace: st,
    );
  }
}
