import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Visual tokens and helpers for light, “premium delivery” maps (flutter_map).
abstract final class PremiumMapStyle {
  static const String userAgentPackageName = 'com.courier.auction.app';

  /// OpenStreetMap “Standard” raster style (osm-carto): warm motorways/trunk
  /// (yellow–orange), strong road hierarchy, full street & place labels —
  /// closer to typical city navigation than minimal “designer” light tiles.
  static const String navigationTileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Land tone aligned with OSM standard tiles (avoids pale gray mismatch).
  static const Color mapBackground = Color(0xFFF2EFE9);

  /// Slightly stronger route readout over yellow/orange major roads.
  static const double routeStrokeWidth = 8;
  static const double routeBorderWidth = 3;

  /// Primary route stroke (Uber/Yandex-style blue).
  static const Color routeBlue = Color(0xFF1E6AF6);
  static const Color routeBlueBorder = Color(0xFFFFFFFF);

  /// Endpoint markers (A / B).
  static const Color endpointBlue = Color(0xFF2563EB);
  static const Color endpointRing = Color(0xFFFFFFFF);

  static TileLayer lightTileLayer() {
    return TileLayer(
      urlTemplate: navigationTileUrlTemplate,
      userAgentPackageName: userAgentPackageName,
    );
  }

  /// Thick blue line with white halo; rounded caps/joins.
  static PolylineLayer<Object> routePolylineLayer(List<LatLng> points) {
    if (points.length < 2) {
      return const PolylineLayer<Object>(polylines: []);
    }
    return PolylineLayer<Object>(
      polylines: [
        Polyline<Object>(
          points: points,
          strokeWidth: routeStrokeWidth,
          color: routeBlue,
          borderStrokeWidth: routeBorderWidth,
          borderColor: routeBlueBorder.withValues(alpha: 0.95),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      ],
    );
  }
}
