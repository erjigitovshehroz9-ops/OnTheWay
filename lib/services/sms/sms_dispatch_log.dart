import 'package:flutter/foundation.dart';

/// Haqiqiy SMS uchun backend (Eskiz, Twilio, …) ulanmaguncha — jurnal / debug.
abstract final class SmsDispatchLog {
  static void send({
    required String toPhone,
    required String body,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    debugPrint('[SMS sim] to=$toPhone | $trimmed');
  }
}
