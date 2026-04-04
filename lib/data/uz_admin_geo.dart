import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Viloyat markazlari (taxminiy) — tuman markazi ma’lum bo‘lmaganda kamera fokusi.
abstract final class UzAdminGeo {
  static const LatLng _default = LatLng(41.31, 69.28);

  static final Map<String, LatLng> _regionCenters = {
    'TK': const LatLng(41.2995, 69.2401),
    'TO': const LatLng(41.2211, 69.2167),
    'AN': const LatLng(40.7821, 72.3442),
    'BU': const LatLng(39.7681, 64.4556),
    'FA': const LatLng(40.3892, 71.7874),
    'JI': const LatLng(40.1158, 67.8422),
    'QA': const LatLng(38.8606, 65.7892),
    'NA': const LatLng(40.0844, 65.3792),
    'NG': const LatLng(40.9983, 71.6726),
    'SA': const LatLng(39.6542, 66.9597),
    'SU': const LatLng(37.2833, 67.2833),
    'SI': const LatLng(40.4897, 68.7840),
    'XO': const LatLng(41.5534, 60.6314),
    'QR': const LatLng(42.4531, 59.6103),
  };

  static LatLng regionCenter(String regionCode) =>
      _regionCenters[regionCode] ?? _default;

  /// Tanlangan tumanga xarita fokusi: viloyat markazidan tuman kodiga bog‘liq barqaror siljish.
  static LatLng districtFocus(String? districtCode, String regionCode) {
    final base = regionCenter(regionCode);
    if (districtCode == null || districtCode.isEmpty) return base;
    final h = districtCode.hashCode;
    final a = (h % 360) * math.pi / 180;
    final r = 0.018 + (h.abs() % 1000) / 45000;
    return LatLng(
      base.latitude + r * math.cos(a),
      base.longitude + r * math.sin(a) * 1.15,
    );
  }

  /// Koordinatasiz buyurtma: bazaviy nuqta atrofida job id bo‘yicha barqaror tarqatish.
  static LatLng scatterFromAnchor(String jobId, LatLng anchor) {
    final h = jobId.hashCode;
    final a = ((h >> 7) % 360) * math.pi / 180;
    final r = 0.0009 + (h.abs() % 600) / 600000;
    return LatLng(
      anchor.latitude + r * math.cos(a),
      anchor.longitude + r * math.sin(a),
    );
  }
}
