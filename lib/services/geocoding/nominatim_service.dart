import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/utils/location_normalizer.dart';

class NominatimResult {
  const NominatimResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  final String displayName;
  final double lat;
  final double lon;
}

class ReverseGeocodeResult {
  const ReverseGeocodeResult({
    required this.displayAddress,
    required this.streetOrPlace,
    required this.city,
    required this.district,
    required this.region,
    required this.neighborhood,
    required this.districtGeocoderRaw,
  });

  /// Qisqa manzil satri (ko‘cha · shahar · tuman · viloyat).
  final String displayAddress;

  /// Ko‘cha / joy nomi.
  final String streetOrPlace;

  /// Shahar yoki qishloq.
  final String city;

  /// **Ma’muriy tuman** (refine qilingan, matching uchun).
  final String district;

  /// Viloyat / mintaqa.
  final String region;

  /// Suburb / quarter (mahalla) — matching uchun emas, faqat heuristik.
  final String neighborhood;

  /// Geocoderdan kelgan tuman/mahalla qatorlari (original audit).
  final String districtGeocoderRaw;
}

class NominatimService {
  NominatimService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Distance _geoDistance = Distance();

  static double _distanceKm(LatLng from, LatLng to) =>
      _geoDistance.as(LengthUnit.Kilometer, from, to);

  /// Bitta so‘z kiritilganda Nominatim `q` bilan topilmay qoladigan qisqartmalar.
  static const Map<String, List<String>> _abbreviationSearchVariants = {
    'nmb': ['Milliy bank', "O'zbekiston Respublikasi Markaziy banki"],
    'nbu': ['Milliy bank', 'National bank Uzbekistan'],
    'mbmu': ["Markaziy bank O'zbekiston", 'Milliy bank'],
    'kapital': ['Kapitalbank', 'Kapital Bank'],
    'sqb': ["O'zbekiston sanoat-qurilish banki", 'Sanoat qurilish banki'],
    'click': ['Click Uzbekistan', 'Click'],
    'payme': ['Payme'],
    'humo': ['Humo'],
    'uzcard': ['Uzcard'],
    'oty': ["O'zbekiston temir yo'llari", 'Temir yo\'l vokzal Toshkent'],
    'uty': ["O'zbekiston temir yo'llari"],
    'temiryol': ["O'zbekiston temir yo'llari"],
    'uzairways': ['Uzbekistan Airways'],
    'uzbekistanairways': ['Uzbekistan Airways'],
    'uztelecom': ['Uztelecom', 'Uzbektelecom'],
    'uzbektelecom': ['Uzbektelecom'],
    'mts': ['Milliy teleradio', 'MTRK'],
    'mtrk': ['Milliy teleradio', "O'zbekiston MTRK"],
    'uzpost': ["O'zbekiston pochtasi"],
    'pochta': ["O'zbekiston pochtasi"],
    'soliq': ["Soliq qo'mitasi", 'Davlat soliq'],
    'nds': ['Soliq', "Soliq qo'mitasi"],
    'hokimiyat': ['Hokimiyat', 'Toshkent shahar hokimiyati'],
    'oliy': ['Oliy Majlis'],
  };

  static String _abbrevKey(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r"['ʻ`´]"), '');

  static List<String> _variantsForAbbrevInput(String raw) {
    final t = raw.trim();
    if (t.length < 2 || t.contains(RegExp(r'\s'))) return const [];
    return _abbreviationSearchVariants[_abbrevKey(t)] ?? const [];
  }

  static String _dedupeKey(NominatimResult r) =>
      '${(r.lat * 1e5).round()}_${(r.lon * 1e5).round()}';

  Future<List<NominatimResult>> _fetchSearch(String q, {int limit = 10}) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': q,
        'format': 'json',
        'limit': '$limit',
        'countrycodes': 'uz',
        'accept-language': 'uz, ru, en',
      },
    );
    final res = await _client.get(
      uri,
      headers: {
        'User-Agent': 'CourierAuctionApp/1.0',
        'Accept-Language': 'uz, ru, en',
      },
    );
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(res.body);
    if (decoded is! List<dynamic>) return [];
    return decoded.map((e) {
      final m = e as Map<String, dynamic>;
      return NominatimResult(
        displayName: m['display_name'] as String? ?? '',
        lat: double.tryParse(m['lat']?.toString() ?? '') ?? 0,
        lon: double.tryParse(m['lon']?.toString() ?? '') ?? 0,
      );
    }).where((r) => r.displayName.isNotEmpty).toList();
  }

  /// [near] berilsa, natijalar shu nuqtaga eng yaqindan boshlab tartiblanadi.
  Future<List<NominatimResult>> search(String query, {LatLng? near}) async {
    final q0 = query.trim();
    if (q0.length < 3) return [];

    final seen = <String>{};
    final out = <NominatimResult>[];

    void merge(List<NominatimResult> batch) {
      for (final r in batch) {
        if (r.lat == 0 && r.lon == 0) continue;
        if (seen.add(_dedupeKey(r))) out.add(r);
      }
    }

    final variants = _variantsForAbbrevInput(q0);
    for (final v in variants.take(5)) {
      merge(await _fetchSearch('$v, Uzbekistan', limit: 8));
    }
    merge(await _fetchSearch(q0, limit: 10));

    if (near != null) {
      final ref = near;
      out.sort((a, b) {
        final da = _distanceKm(ref, LatLng(a.lat, a.lon));
        final db = _distanceKm(ref, LatLng(b.lat, b.lon));
        final c = da.compareTo(db);
        if (c != 0) return c;
        return a.displayName.compareTo(b.displayName);
      });
    }

    return out.take(16).toList();
  }

  static bool _isTashkentArea(String city, String region, String displayName) {
    final blob = '${city.toLowerCase()} ${region.toLowerCase()} ${displayName.toLowerCase()}';
    return blob.contains('tashkent') ||
        blob.contains('toshkent') ||
        blob.contains('ташкент');
  }

  static bool _hintsYangiHayot(String? a, String? b, String? c) {
    void check(String? s, void Function(String) onNorm) {
      if (s == null || s.trim().isEmpty) return;
      final n = s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      onNorm(n);
    }

    var hit = false;
    void scan(String n) {
      if (n.contains('yangihayot') ||
          (n.contains('yangi') && n.contains('hayot')) ||
          n.contains('yangi-hayot') ||
          n.contains('new life')) {
        hit = true;
      }
    }

    check(a, scan);
    check(b, scan);
    check(c, scan);
    return hit;
  }

  static bool _hintsSergeli(String? s) {
    if (s == null || s.isEmpty) return false;
    final n = LocationKeyNormalizer.normalizeLocationKey(s);
    return n.contains('sergeli');
  }

  /// OSM maydonlari → ma’muriy tuman (suburb ko‘cha/mahalla bo‘lishi mumkin).
  static String _refineDistrictForTashkent({
    required String city,
    required String region,
    required String displayName,
    required String administrativePrimary,
    required String neighborhood,
    required String suburb,
    required String quarter,
  }) {
    final admin = administrativePrimary.trim();
    final neigh = neighborhood.trim();

    // Yangi Hayot joylari ba’zan Sergeli admin polygonida — matn ustun.
    if (_hintsYangiHayot(neigh, admin, displayName) &&
        (_hintsSergeli(admin) || _hintsSergeli(city))) {
      if (kDebugMode) {
        debugPrint(
          '[geocode] Yangi Hayot heuristik: admin="$admin" suburb="$neigh" → yangihayot',
        );
      }
      return 'Yangi Hayot tumani';
    }

    if (admin.isNotEmpty) return admin;

    // Fallback: mahalla nomi faqat alias jadvaliga tushsa ishlatiladi.
    for (final cand in [neigh, suburb, quarter]) {
      if (cand.trim().isEmpty) continue;
      final k = LocationKeyNormalizer.districtKeyFromRaw(cand);
      if (k.isNotEmpty && !LocationKeyNormalizer.isUnusableDistrictRaw(cand)) {
        return cand.trim();
      }
    }

    return '';
  }

  static String _joinRawDistrictParts(List<String> parts) {
    final cleaned = parts.map((e) => e.trim()).where((e) => e.isNotEmpty);
    return cleaned.join(' | ');
  }

  Future<ReverseGeocodeResult?> reverse({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
        'addressdetails': '1',
      },
    );
    final res = await _client.get(
      uri,
      headers: {'User-Agent': 'CourierAuctionApp/1.0'},
    );
    if (res.statusCode != 200) return null;
    final m = jsonDecode(res.body) as Map<String, dynamic>;
    final displayName = (m['display_name'] as String?)?.trim() ?? '';
    final addr = (m['address'] as Map?)?.cast<String, dynamic>() ?? const {};

    String pick(Map<String, dynamic> a, List<String> keys) {
      for (final k in keys) {
        final v = (a[k] as String?)?.trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return '';
    }

    final streetOrPlace = pick(addr, const [
      'road',
      'pedestrian',
      'footway',
      'amenity',
      'tourism',
      'shop',
    ]);

    final city = pick(addr, const [
      'city',
      'town',
      'township',
      'municipality',
    ]);

    final suburb = pick(addr, const ['suburb']);
    final quarter = pick(addr, const ['quarter']);
    final neighborhood = pick(addr, const [
      'neighbourhood',
      'neighborhood',
      'hamlet',
      'village',
    ]);

    // 1) Kuchli ma’muriy qavatlar (tuman/shahar ichidagi tuman).
    var administrative = pick(addr, const [
      'city_district',
      'district',
      'borough',
      'county',
      'state_district',
    ]);

    if (administrative == city) {
      administrative = pick(addr, const [
        'city_district',
        'district',
        'borough',
      ]);
    }
    if (administrative == city) {
      administrative = '';
    }

    final region = pick(addr, const ['state', 'region', 'province']);

    final districtGeocoderRaw = _joinRawDistrictParts([
      administrative,
      suburb,
      quarter,
      neighborhood,
    ]);

    var district = administrative;
    if (_isTashkentArea(city, region, displayName)) {
      district = _refineDistrictForTashkent(
        city: city,
        region: region,
        displayName: displayName,
        administrativePrimary: administrative,
        neighborhood: neighborhood.isNotEmpty ? neighborhood : suburb,
        suburb: suburb,
        quarter: quarter,
      );
    } else if (district.isEmpty) {
      for (final cand in [suburb, quarter, neighborhood]) {
        if (cand.trim().isEmpty) continue;
        final k = LocationKeyNormalizer.districtKeyFromRaw(cand);
        if (k.isNotEmpty &&
            !LocationKeyNormalizer.isUnusableDistrictRaw(cand)) {
          district = cand.trim();
          break;
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[geocode] raw admin="$administrative" suburb="$suburb" '
        'neighborhood="$neighborhood" => district="$district"',
      );
    }

    String joinComma(List<String> parts) {
      final cleaned = parts.map((e) => e.trim()).where((e) => e.isNotEmpty);
      return cleaned.join(', ');
    }

    final compact = joinComma([streetOrPlace, city, district, region]);
    final bestDisplay = compact.isNotEmpty ? compact : displayName;
    if (bestDisplay.trim().isEmpty) return null;

    return ReverseGeocodeResult(
      displayAddress: bestDisplay,
      streetOrPlace: streetOrPlace,
      city: city,
      district: district,
      region: region,
      neighborhood: neighborhood.isNotEmpty ? neighborhood : suburb,
      districtGeocoderRaw: districtGeocoderRaw,
    );
  }
}
