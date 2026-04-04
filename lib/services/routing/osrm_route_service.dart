import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// OSRM (Project OSRM demo server) — haqiqiy yo‘l masofasi va polyline.
/// Muvaffaqiyatsiz bo‘lsa `null` qaytaradi (chaqqan chiziq + haversine ishlatiladi).
class OsrmRouteService {
  OsrmRouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<OsrmDrivingRoute?> drivingRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    final coordPath =
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordPath'
      '?overview=full&geometries=geojson',
    );
    try {
      final res = await _client.get(
        uri,
        headers: {'User-Agent': 'CourierAuctionApp/1.0'},
      );
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final distanceM = (route['distance'] as num?)?.toDouble();
      if (distanceM == null) return null;
      final durationSec = (route['duration'] as num?)?.toDouble();
      final geom = route['geometry'] as Map<String, dynamic>?;
      final coords = geom?['coordinates'] as List<dynamic>?;
      if (coords == null || coords.isEmpty) return null;
      final points = <LatLng>[];
      for (final c in coords) {
        final pair = c as List<dynamic>;
        final lon = (pair[0] as num).toDouble();
        final lat = (pair[1] as num).toDouble();
        points.add(LatLng(lat, lon));
      }
      return OsrmDrivingRoute(
        points: points,
        distanceMeters: distanceM,
        durationSeconds:
            durationSec != null && durationSec > 0 ? durationSec : null,
      );
    } catch (e, st) {
      debugPrint('[osrm] route failed: $e\n$st');
      return null;
    }
  }
}

class OsrmDrivingRoute {
  const OsrmDrivingRoute({
    required this.points,
    required this.distanceMeters,
    this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  /// Yo‘l bo‘yicha taxminiy vaqt (s), OSRM `duration`.
  final double? durationSeconds;
}
