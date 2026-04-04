import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Buyurtmada bir yoki bir nechta mos transport turlari (CSV); kuryer o‘zidan kamida bittasi
/// mos bo‘lsa buyurtmani ko‘radi.
enum JobTransportType {
  piyoda('piyoda'),
  velosiped('velosiped_skuter'),
  moto('mototsikl'),
  avto('avtomobil'),
  truck('yuk_avtomobili');

  const JobTransportType(this.storageKey);
  final String storageKey;

  IconData get icon => switch (this) {
        JobTransportType.piyoda => Icons.directions_walk_rounded,
        JobTransportType.velosiped => Icons.electric_scooter_rounded,
        JobTransportType.moto => Icons.two_wheeler_rounded,
        JobTransportType.avto => Icons.directions_car_filled_rounded,
        JobTransportType.truck => Icons.local_shipping_rounded,
      };

  String label(AppLocalizations l10n) => switch (this) {
        JobTransportType.piyoda => l10n.transportLabelPiyoda,
        JobTransportType.velosiped => l10n.transportLabelVelosiped,
        JobTransportType.moto => l10n.transportLabelMoto,
        JobTransportType.avto => l10n.transportLabelAvto,
        JobTransportType.truck => l10n.transportLabelTruck,
      };

  /// Tanlangan kodni kanonik storage kalitiga aylantiradi (`null` — noma’lum).
  static String? normalizeStorageKey(String? raw) {
    if (raw == null) return null;
    var t = raw.trim();
    if (t.isEmpty) return null;
    if (t == 'velosiped/skuter') {
      t = velosiped.storageKey;
    }
    final lower = t.toLowerCase();
    if (lower == 'moto') {
      t = moto.storageKey;
    }
    for (final v in JobTransportType.values) {
      if (v.storageKey == t) return v.storageKey;
    }
    return null;
  }

  static JobTransportType? tryParse(String? raw) {
    final n = normalizeStorageKey(raw);
    if (n == null) return null;
    for (final v in JobTransportType.values) {
      if (v.storageKey == n) return v;
    }
    return null;
  }

  /// DB / `JobEntity.transportType` — vergul bilan ajratilgan kanonik kalitlar.
  static List<String> parseStoredTransportCodes(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Saqlangan qiymatdan barcha kanonik kalitlar ([JobTransportType] tartibida).
  static List<String> normalizedJobTransportKeysFromStored(String? stored) {
    if (stored == null || stored.trim().isEmpty) return const [];
    final normalized = normalizeCourierKeyList(parseStoredTransportCodes(stored));
    if (normalized.isEmpty) return const [];
    final set = normalized.toSet();
    final ordered = <String>[];
    for (final v in JobTransportType.values) {
      if (set.contains(v.storageKey)) ordered.add(v.storageKey);
    }
    for (final c in normalized) {
      if (!ordered.contains(c)) ordered.add(c);
    }
    return ordered;
  }

  /// Birinchi tanilgan tur (eski kod uchun) yoki `null`.
  static String? requiredTransportKeyFromStored(String? stored) {
    if (stored == null) return null;
    for (final seg in parseStoredTransportCodes(stored)) {
      final n = normalizeStorageKey(seg);
      if (n != null) return n;
    }
    return null;
  }

  /// Migratsiya: bitta kanonik kalit (bo‘sh yoki noto‘g‘ri bo‘lsa — avtomobil).
  static String migrateStoredJobTransportToSingleKey(String raw) {
    return requiredTransportKeyFromStored(raw) ?? avto.storageKey;
  }

  /// Bitta kalitni saqlash (ixtiyoriy yordamchi).
  static String encodeSingleRequiredType(String storageKey) {
    return normalizeStorageKey(storageKey) ?? avto.storageKey;
  }

  /// Kuryer profilidagi kalitlar ro‘yxatini normalizatsiya qiladi.
  static List<String> normalizeCourierKeyList(Iterable<String> raw) {
    final out = <String>{};
    for (final r in raw) {
      final n = normalizeStorageKey(r);
      if (n != null) out.add(n);
    }
    return out.toList();
  }

  /// Kuryer buyurtma uchun belgilangan turlardan kamida bittasiga ega bo‘lsa — ko‘radi.
  static bool courierSeesJob({
    required List<String> courierNormalizedKeys,
    required String jobTransportStored,
  }) {
    final jobKeys = normalizedJobTransportKeysFromStored(jobTransportStored);
    if (jobKeys.isEmpty) return false;
    if (courierNormalizedKeys.isEmpty) return false;
    return jobKeys.any(courierNormalizedKeys.contains);
  }

  /// Tanlangan kodlarni barqaror tartibda bir qatorga yozadi (kuryer profili CSV).
  static String encodeTransportTypesToStorage(Iterable<String> codes) {
    final normalized = normalizeCourierKeyList(codes);
    final ordered = <String>[];
    for (final v in JobTransportType.values) {
      if (normalized.contains(v.storageKey)) ordered.add(v.storageKey);
    }
    for (final c in normalized) {
      if (!ordered.contains(c)) ordered.add(c);
    }
    return ordered.join(',');
  }

  static String displayLabel(AppLocalizations l10n, String storageKey) {
    final t = tryParse(storageKey);
    if (t != null) return t.label(l10n);
    if (storageKey.isEmpty) return '—';
    return storageKey;
  }

  static String displayLabelsJoined(AppLocalizations l10n, String storedCsv) {
    final keys = normalizedJobTransportKeysFromStored(storedCsv);
    if (keys.isEmpty) return '—';
    return keys.map((k) => displayLabel(l10n, k)).join(', ');
  }

  /// Kartochka / ro‘yxatda: birinchi tur ikonkasi (bir nechta bo‘lsa ham).
  static IconData iconForStoredSummary(String storedCsv) {
    final keys = normalizedJobTransportKeysFromStored(storedCsv);
    if (keys.isEmpty) return Icons.local_shipping_outlined;
    return tryParse(keys.first)?.icon ?? Icons.local_shipping_rounded;
  }
}
