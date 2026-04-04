import 'package:flutter/foundation.dart';

import '../../data/regions_seed.dart';
import '../../models/job_entity.dart';
import '../../models/job_status.dart';
import '../utils/location_normalizer.dart';

/// Ish hududi uchun yagona kalitlar: xarita matni yoki admin kodlari orqali.
abstract final class WorkAreaKeys {
  WorkAreaKeys._();

  /// Xarita / geokodlash ko‘rsatadigan qatorlar (sender pickup).
  static ({String regionKey, String districtKey}) fromPickupDisplay(
    String? pickupRegion,
    String? pickupDistrictOrCity,
  ) {
    return (
      regionKey: LocationKeyNormalizer.regionKeyFromRaw(pickupRegion),
      districtKey: LocationKeyNormalizer.districtKeyFromRaw(pickupDistrictOrCity),
    );
  }

  /// Profil / ro‘yxatdan tanlangan `RegionsSeed` admin kodlari.
  static ({String regionKey, String districtKey}) fromAdminCodes(
    String? regionCode,
    String? districtCode,
  ) {
    if (regionCode == null ||
        districtCode == null ||
        regionCode.isEmpty ||
        districtCode.isEmpty) {
      return (regionKey: '', districtKey: '');
    }
    try {
      final r = RegionsSeed.regions.firstWhere((e) => e.code == regionCode);
      final d = RegionsSeed.districts.firstWhere((e) => e.code == districtCode);
      return fromPickupDisplay(r.name.uz, d.name.uz);
    } catch (_) {
      return (regionKey: '', districtKey: '');
    }
  }

  /// Region kaliti faqat `region_code` bo‘yicha (tuman kodi yo‘q bo‘lsa ham).
  static String regionKeyFromSeedRegionCode(String? regionCode) {
    if (regionCode == null || regionCode.isEmpty) return '';
    try {
      final r = RegionsSeed.regions.firstWhere((e) => e.code == regionCode);
      return LocationKeyNormalizer.regionKeyFromRaw(r.name.uz);
    } catch (_) {
      return '';
    }
  }

  /// Tuman kaliti faqat `district_code` bo‘yicha.
  static String districtKeyFromSeedDistrictCode(String? districtCode) {
    if (districtCode == null || districtCode.isEmpty) return '';
    try {
      final d = RegionsSeed.districts.firstWhere((e) => e.code == districtCode);
      return LocationKeyNormalizer.districtKeyFromRaw(d.name.uz);
    } catch (_) {
      return '';
    }
  }

  static void _addRegionKey(Set<String> sink, String? rawOrCompact) {
    final v = (rawOrCompact ?? '').trim();
    if (v.isEmpty) return;
    final k = LocationKeyNormalizer.regionKeyFromRaw(v);
    if (k.isNotEmpty) sink.add(k);
  }

  static void _addDistrictKey(Set<String> sink, String? rawOrCompact) {
    final v = (rawOrCompact ?? '').trim();
    if (v.isEmpty) return;
    final k = LocationKeyNormalizer.districtKeyFromRaw(v);
    if (k.isNotEmpty) sink.add(k);
  }

  /// Barcha mumkin bo‘lgan viloyat kalitlari (DB kaliti noto‘g‘ri bo‘lsa ham matn/admin bilan).
  static Set<String> orderRegionKeyCandidates(JobEntity job) {
    final s = <String>{};
    _addRegionKey(s, job.pickupRegionKey);
    _addRegionKey(s, job.pickupRegion);
    _addRegionKey(s, job.pickupRegionOriginal);
    final pair = fromAdminCodes(job.regionCode, job.districtCode);
    if (pair.regionKey.isNotEmpty) s.add(pair.regionKey);
    final only = regionKeyFromSeedRegionCode(job.regionCode);
    if (only.isNotEmpty) s.add(only);
    return s;
  }

  static Set<String> orderDistrictKeyCandidates(JobEntity job) {
    final s = <String>{};
    _addDistrictKey(s, job.pickupDistrictKey);
    _addDistrictKey(s, job.pickupDistrictOrCity);
    _addDistrictKey(s, job.pickupDistrictOriginal);
    final hay = LocationKeyNormalizer.normalizeAddressHaystack(
      '${job.pickupRegion ?? ''} ${job.pickupDistrictOrCity ?? ''} ${job.pickupDistrictOriginal ?? ''}',
    );
    final rCode = job.regionCode.trim();
    if (hay.isNotEmpty && rCode.isNotEmpty) {
      for (final d
          in RegionsSeed.districts.where((e) => e.regionCode == rCode)) {
        final dk = districtKeyFromSeedDistrictCode(d.code);
        if (dk.isEmpty) continue;
        if (LocationKeyNormalizer.haystackContainsDistrictKey(hay, dk)) {
          s.add(dk);
        }
      }
    }
    final pair = fromAdminCodes(job.regionCode, job.districtCode);
    if (pair.districtKey.isNotEmpty) s.add(pair.districtKey);
    final only = districtKeyFromSeedDistrictCode(job.districtCode);
    if (only.isNotEmpty) s.add(only);
    return s;
  }

  /// Tasmasi: admin kod tanlangan bo‘lsa, faqat shu kodlar va seed orqali kalitlar
  /// (profil `working_*` kalitlari aralashmasin — boshqa tuman/viloyat kaliti
  /// tanlovni buzmasin).
  static Set<String> courierRegionKeyCandidates({
    required String workingRegionKey,
    String? regionCode,
    String? districtCode,
  }) {
    final s = <String>{};
    final r = regionCode?.trim();
    final d = districtCode?.trim();
    if (r != null && r.isNotEmpty) {
      final pair = fromAdminCodes(r, d ?? '');
      if (pair.regionKey.isNotEmpty) s.add(pair.regionKey);
      final only = regionKeyFromSeedRegionCode(r);
      if (only.isNotEmpty) s.add(only);
    } else {
      _addRegionKey(s, workingRegionKey);
    }
    return s;
  }

  static Set<String> courierDistrictKeyCandidates({
    required String workingDistrictKey,
    String? regionCode,
    String? districtCode,
  }) {
    final s = <String>{};
    final r = regionCode?.trim();
    final d = districtCode?.trim();
    if (d != null && d.isNotEmpty) {
      if (r != null && r.isNotEmpty) {
        final pair = fromAdminCodes(r, d);
        if (pair.districtKey.isNotEmpty) s.add(pair.districtKey);
      }
      final only = districtKeyFromSeedDistrictCode(d);
      if (only.isNotEmpty) s.add(only);
    } else {
      _addDistrictKey(s, workingDistrictKey);
    }
    return s;
  }

  /// Birlamchi kalitlar (log / eski chaqiriqlar uchun).
  static ({String regionKey, String districtKey}) effectiveOrderKeys(JobEntity job) {
    final r = orderRegionKeyCandidates(job);
    final d = orderDistrictKeyCandidates(job);
    return (
      regionKey: r.isEmpty ? '' : r.first,
      districtKey: d.isEmpty ? '' : d.first,
    );
  }

  static ({String regionKey, String districtKey}) effectiveCourierKeys({
    required String workingRegionKey,
    required String workingDistrictKey,
    String? regionCode,
    String? districtCode,
  }) {
    final r = courierRegionKeyCandidates(
      workingRegionKey: workingRegionKey,
      regionCode: regionCode,
      districtCode: districtCode,
    );
    final d = courierDistrictKeyCandidates(
      workingDistrictKey: workingDistrictKey,
      regionCode: regionCode,
      districtCode: districtCode,
    );
    return (
      regionKey: r.isEmpty ? '' : r.first,
      districtKey: d.isEmpty ? '' : d.first,
    );
  }

  /// Supabase-dan kelgan qatorlarda joylashuv kaliti yo‘q bo‘lsa (faqat legacy minimal maydonlar),
  /// hudud filtri barcha kuryerlarga mos kelmay qolmasligi uchun vaqtincha yengillashtirish.
  static bool _supabaseJobNeedsWorkAreaBypass(JobEntity job) {
    if (!job.syncedFromSupabase) return false;
    if (job.status != JobStatus.posted && job.status != JobStatus.auctionLive) {
      return false;
    }
    return !jobHasWorkAreaAnchors(job);
  }

  /// Viloyat/tuman/admin kalitlari yoki ulardan hisoblangan kandidatlar mavjud bo‘lsa — normal filtr ishlatiladi.
  static bool jobHasWorkAreaAnchors(JobEntity job) {
    if (job.regionCode.trim().isNotEmpty) return true;
    return orderRegionKeyCandidates(job).isNotEmpty ||
        orderDistrictKeyCandidates(job).isNotEmpty;
  }

  /// Kuryer tasmasi: admin kod + kalitlar to‘plami (xato saqlangan kalitlarni matn bilan tuzatadi).
  static bool courierJobMatchesWorkArea({
    required JobEntity job,
    required String courierWorkingRegionKey,
    required String courierWorkingDistrictKey,
    required String? courierRegionCode,
    required String? courierDistrictCode,
    required bool wholeRegionDistrict,
  }) {
    if (_supabaseJobNeedsWorkAreaBypass(job)) {
      return true;
    }

    final courierR = courierRegionCode?.trim();
    final courierD = courierDistrictCode?.trim();

    final oReg = orderRegionKeyCandidates(job);
    final oDist = orderDistrictKeyCandidates(job);
    final cReg = courierRegionKeyCandidates(
      workingRegionKey: courierWorkingRegionKey,
      regionCode: courierR,
      districtCode: courierD,
    );
    final cDist = courierDistrictKeyCandidates(
      workingDistrictKey: courierWorkingDistrictKey,
      regionCode: courierR,
      districtCode: courierD,
    );

    final regionUnconstrained = courierR == null || courierR.isEmpty;
    final regionByCode = courierR != null &&
        courierR.isNotEmpty &&
        job.regionCode.isNotEmpty &&
        job.regionCode == courierR;
    final regionByKeys =
        oReg.isNotEmpty && cReg.isNotEmpty && oReg.intersection(cReg).isNotEmpty;
    final regionMatch = regionUnconstrained || regionByCode || regionByKeys;

    final districtMatchWhole = wholeRegionDistrict;
    final districtByCode = courierD != null &&
        courierD.isNotEmpty &&
        job.districtCode.isNotEmpty &&
        job.districtCode == courierD;
    final districtByKeys =
        oDist.isNotEmpty && cDist.isNotEmpty && oDist.intersection(cDist).isNotEmpty;
    final districtMatch =
        districtMatchWhole || districtByCode || districtByKeys;

    final overall = regionMatch && districtMatch;

    if (kDebugMode) {
      _debugMatchLog(
        job: job,
        rawWorkingR: courierWorkingRegionKey,
        rawWorkingD: courierWorkingDistrictKey,
        courierR: courierR,
        courierD: courierD,
        wholeRegion: wholeRegionDistrict,
        oReg: oReg,
        oDist: oDist,
        cReg: cReg,
        cDist: cDist,
        regionMatch: regionMatch,
        districtMatch: districtMatch,
        overall: overall,
        mappedOrderDistrict: districtKeyFromSeedDistrictCode(job.districtCode),
      );
    }

    return overall;
  }

  static void _debugMatchLog({
    required JobEntity job,
    required String rawWorkingR,
    required String rawWorkingD,
    required String? courierR,
    required String? courierD,
    required bool wholeRegion,
    required Set<String> oReg,
    required Set<String> oDist,
    required Set<String> cReg,
    required Set<String> cDist,
    required bool regionMatch,
    required bool districtMatch,
    required bool overall,
    required String mappedOrderDistrict,
  }) {
    debugPrint(
      '[workAreaMatch] job=${job.id} '
      'geocoder.pickupDistrictOriginal=${job.pickupDistrictOriginal} '
      'geocoder.pickupRegionOriginal=${job.pickupRegionOriginal}',
    );
    debugPrint(
      '[workAreaMatch] job=${job.id} '
      'order.fromRegion(pickupRegion)=${job.pickupRegion} '
      'order.fromDistrict(pickupDistrict)=${job.pickupDistrictOrCity}',
    );
    debugPrint(
      '[workAreaMatch] order.fromRegionKey=${job.pickupRegionKey} '
      'order.fromDistrictKey=${job.pickupDistrictKey} '
      'admin=${job.regionCode}/${job.districtCode} '
      'mappedCanonicalDistrict(from seed)=$mappedOrderDistrict',
    );
    debugPrint(
      '[workAreaMatch] user.region(regionCode)=$courierR user.district(districtCode)=$courierD '
      'user.workingRegionKey=$rawWorkingR user.workingDistrictKey=$rawWorkingD',
    );
    debugPrint(
      '[workAreaMatch] orderRegionCandidates={${oReg.join(',')}} '
      'courierRegionCandidates={${cReg.join(',')}}',
    );
    debugPrint(
      '[workAreaMatch] orderDistrictCandidates={${oDist.join(',')}} '
      'courierDistrictCandidates={${cDist.join(',')}}',
    );
    debugPrint(
      '[workAreaMatch] finalRegionMatch=$regionMatch finalDistrictMatch=$districtMatch '
      'finalOverallMatch=$overall wholeRegion=$wholeRegion',
    );
    final oR0 = oReg.isEmpty ? '' : oReg.first;
    final uR0 = cReg.isEmpty ? '' : cReg.first;
    final oD0 = oDist.isEmpty ? '' : oDist.first;
    final uD0 = cDist.isEmpty ? '' : cDist.first;
    debugPrint(
      'MATCH => orderRegionKey=$oR0 userRegionKey=$uR0 '
      'orderDistrictKey=$oD0 userDistrictKey=$uD0 => $overall',
    );
  }
}
