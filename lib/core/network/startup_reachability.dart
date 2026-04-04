import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'network_config.dart';

/// Foydalanuvchiga ko'rinadigan xabar bilan tekshiruv xatosi.
class StartupReachabilityFailure implements Exception {
  StartupReachabilityFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Internet va (sozlangan bo'lsa) ilova serveri mavjudligini tekshiradi.
///
/// Web: brauzer tarmog'iga ishonamiz; tashqi `generate_204` / CORS tekshiruvlari yo'q.
/// Supabase yuklanmasa foydalanuvchi keyinroq xato ko'radi.
Future<void> verifyStartupReachability() async {
  if (kIsWeb) {
    return;
  }

  await _pingHttp(
    Uri.parse('https://www.gstatic.com/generate_204'),
    onFailure: () => StartupReachabilityFailure(
      "Internet aloqasi yo'q yoki juda sekin. Wi‑Fi yoki mobil tarmoqni tekshiring.",
    ),
  );

  final server = kAppServerHealthCheckUrl?.trim();
  if (server != null && server.isNotEmpty) {
    await _pingHttp(
      Uri.parse(server),
      onFailure: () => StartupReachabilityFailure(
        "Ilova serveriga ulanib bo'lmadi. Internet aloqasi va server holatini tekshiring.",
      ),
    );
  }
}

Future<void> _pingHttp(
  Uri uri, {
  required StartupReachabilityFailure Function() onFailure,
}) async {
  final client = http.Client();
  try {
    final response = await client
        .get(
          uri,
          headers: const {'User-Agent': 'CourierAuction/1.0'},
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode >= 200 && response.statusCode < 600) {
      return;
    }
    throw onFailure();
  } on StartupReachabilityFailure {
    rethrow;
  } on TimeoutException {
    throw StartupReachabilityFailure(
      "Tarmoq yoki server javob bermadi. Keyinroq qayta urinib ko'ring.",
    );
  } catch (e) {
    final s = e.toString();
    if (s.contains('HandshakeException')) {
      throw StartupReachabilityFailure(
        "Xavfsiz ulanish o'rnatilmadi. Vaqt yoki tarmoq sozlamalarini tekshiring.",
      );
    }
    throw onFailure();
  } finally {
    client.close();
  }
}
