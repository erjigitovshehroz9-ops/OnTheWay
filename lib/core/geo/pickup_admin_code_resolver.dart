import 'dart:developer' as developer;

import '../../data/regions_seed.dart';
import '../../models/region_record.dart';
import 'location_key_normalizer.dart';

/// Xarita / geokodlashdan kelgan matnlar → `RegionsSeed` admin kodlari.
abstract final class PickupAdminCodeResolver {
  PickupAdminCodeResolver._();

  static void _debugLog(String message) {
    assert(() {
      developer.log(message, name: 'PickupAdminCodeResolver');
      return true;
    }());
  }

  static int _districtScore(DistrictRecord d, String haystack) {
    var best = 0;
    for (final loc in [d.name.uz, d.name.ru, d.name.en]) {
      final raw = LocationKeyNormalizer.normalizeLocationKey(loc);
      final c = LocationKeyNormalizer.canonicalDistrictKey(raw);
      if (c.isEmpty) continue;
      if (haystack == c) {
        if (2000 > best) best = 2000;
        continue;
      }
      if (LocationKeyNormalizer.haystackContainsDistrictKey(haystack, c)) {
        final s = 500 + c.length;
        if (s > best) best = s;
        continue;
      }
      if (c.length >= 4 && haystack.contains(c)) {
        final s = 100 + c.length;
        if (s > best) best = s;
      } else if (c.length >= 6) {
        final pref = c.substring(0, c.length - 1);
        if (haystack.contains(pref)) {
          final s = 80 + pref.length;
          if (s > best) best = s;
        }
      }
    }
    return best;
  }

  static int _regionScore(RegionRecord r, String haystack) {
    var best = 0;
    for (final loc in [r.name.uz, r.name.ru, r.name.en]) {
      final raw = LocationKeyNormalizer.normalizeLocationKey(loc);
      final c = LocationKeyNormalizer.canonicalRegionKey(raw);
      if (c.isEmpty) continue;
      if (haystack == c) {
        if (2000 > best) best = 2000;
        continue;
      }
      if (c.length >= 4 && haystack.contains(c)) {
        final s = 500 + c.length;
        if (s > best) best = s;
      } else if (c.length >= 6) {
        final pref = c.substring(0, c.length - 1);
        if (haystack.contains(pref)) {
          final s = 400 + pref.length;
          if (s > best) best = s;
        }
      }
    }
    return best;
  }

  /// [pickupDistrictOrCity] — odatda `MapPickerResult` dan `city · district` qatori.
  ///
  /// [pickupAddressExtra] — to‘liq manzil satri va geokod qatlamlari (masalan
  /// `MapPickerResult.label`). Ba’zi platformalarda (masalan Windows) OSM
  /// `address.state` / `city` bo‘sh bo‘lsa-da, [pickupAddressExtra] da joy nomi
  /// qolishi mumkin — bu holda viloyat/tuman kodlari Android bilan mos chiqadi.
  static ({String regionCode, String districtCode}) resolve({
    required String? pickupRegion,
    required String? pickupDistrictOrCity,
    String? pickupAddressExtra,
    String? fallbackRegionCode,
    String? fallbackDistrictCode,
  }) {
    final haystack = LocationKeyNormalizer.normalizeAddressHaystack(
      '${pickupRegion ?? ''} ${pickupDistrictOrCity ?? ''} ${pickupAddressExtra ?? ''}',
    );

    _debugLog(
      '[crossPlatformOrder] PickupAdminCodeResolver haystackLen=${haystack.length} '
      'structR=${(pickupRegion ?? "").trim().isNotEmpty} '
      'structD=${(pickupDistrictOrCity ?? "").trim().isNotEmpty} '
      'extraLen=${(pickupAddressExtra ?? "").trim().length}',
    );

    if (haystack.isEmpty) {
      final out = (
        regionCode: fallbackRegionCode ?? 'TK',
        districtCode: fallbackDistrictCode ?? 'TK_C',
      );
      _debugLog(
        '[crossPlatformOrder] PickupAdminCodeResolver empty_haystack → '
        '${out.regionCode}/${out.districtCode} (fallback)',
      );
      return out;
    }

    final sortedDistricts = List<DistrictRecord>.from(RegionsSeed.districts)
      ..sort((a, b) => b.name.uz.length.compareTo(a.name.uz.length));

    DistrictRecord? bestD;
    var bestDScore = 0;
    for (final d in sortedDistricts) {
      final s = _districtScore(d, haystack);
      if (s > bestDScore) {
        bestDScore = s;
        bestD = d;
      }
    }

    if (bestD != null && bestDScore >= 4) {
      final out = (regionCode: bestD.regionCode, districtCode: bestD.code);
      _debugLog(
        '[crossPlatformOrder] PickupAdminCodeResolver by_district score=$bestDScore → '
        '${out.regionCode}/${out.districtCode}',
      );
      return out;
    }

    RegionRecord? bestR;
    var bestRScore = 0;
    for (final r in RegionsSeed.regions) {
      final s = _regionScore(r, haystack);
      if (s > bestRScore) {
        bestRScore = s;
        bestR = r;
      }
    }

    if (bestR != null && bestRScore >= 6) {
      DistrictRecord? d2;
      var d2Score = 0;
      final rCode = bestR.code;
      for (final d in sortedDistricts.where((e) => e.regionCode == rCode)) {
        final s = _districtScore(d, haystack);
        if (s > d2Score) {
          d2Score = s;
          d2 = d;
        }
      }
      if (d2 != null && d2Score >= 4) {
        final out = (regionCode: rCode, districtCode: d2.code);
        _debugLog(
          '[crossPlatformOrder] PickupAdminCodeResolver by_region+district score=$d2Score → '
          '${out.regionCode}/${out.districtCode}',
        );
        return out;
      }
      if (fallbackDistrictCode != null) {
        try {
          final fd = RegionsSeed.districts.firstWhere((e) => e.code == fallbackDistrictCode);
          if (fd.regionCode == rCode) {
            final out = (regionCode: rCode, districtCode: fd.code);
            _debugLog(
              '[crossPlatformOrder] PickupAdminCodeResolver region+profile_district → '
              '${out.regionCode}/${out.districtCode}',
            );
            return out;
          }
        } catch (_) {}
      }
      for (final e in RegionsSeed.districts) {
        if (e.regionCode == rCode) {
          final out = (regionCode: rCode, districtCode: e.code);
          _debugLog(
            '[crossPlatformOrder] PickupAdminCodeResolver region+first_district → '
            '${out.regionCode}/${out.districtCode}',
          );
          return out;
        }
      }
    }

    final out = (
      regionCode: fallbackRegionCode ?? 'TK',
      districtCode: fallbackDistrictCode ?? 'TK_C',
    );
    _debugLog(
      '[crossPlatformOrder] PickupAdminCodeResolver weak_match → '
      '${out.regionCode}/${out.districtCode} (fallback)',
    );
    return out;
  }
}
