import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bitta aktiv buyurtma uchun kuryer lokatsiya timeri (ikkilangan subscribe yo‘q).
class CourierOrderTrackingHub {
  CourierOrderTrackingHub._();

  static String? _sessionKey;
  static Timer? _timer;

  static String _key(String jobId, String courierId) => '$jobId|$courierId';

  /// [tick] ichida o‘zingiz job holatini tekshiring; [shouldContinue] false bo‘lsa timer to‘xtaydi.
  static void ensureRunning({
    required String jobId,
    required String courierId,
    Duration interval = const Duration(seconds: 8),
    required Future<void> Function() tick,
    required bool Function() shouldContinue,
  }) {
    final k = _key(jobId, courierId);
    if (_sessionKey == k && _timer != null) {
      return;
    }
    stop(reason: 'reconfigure');
    _sessionKey = k;
    if (kDebugMode) {
      debugPrint('[tracking] start order=$jobId courier=$courierId');
    }
    _timer = Timer.periodic(interval, (_) {
      unawaited(_runTick(tick, shouldContinue));
    });
    unawaited(_runTick(tick, shouldContinue));
  }

  static Future<void> _runTick(
    Future<void> Function() tick,
    bool Function() shouldContinue,
  ) async {
    if (!shouldContinue()) {
      stop(reason: 'shouldContinue_false');
      return;
    }
    try {
      await tick();
    } catch (e, st) {
      debugPrint('[tracking] tick error: $e');
      if (kDebugMode) debugPrintStack(stackTrace: st);
    }
  }

  static void stop({required String reason}) {
    if (_timer == null && _sessionKey == null) return;
    final o = _sessionKey;
    _timer?.cancel();
    _timer = null;
    _sessionKey = null;
    if (kDebugMode && o != null) {
      final parts = o.split('|');
      final oid = parts.isNotEmpty ? parts[0] : o;
      final cid = parts.length > 1 ? parts[1] : '';
      debugPrint('[tracking] stop order=$oid courier=$cid reason=$reason');
    }
  }
}
