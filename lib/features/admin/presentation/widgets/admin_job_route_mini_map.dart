import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../models/job_entity.dart';
import '../../../../shared/map/map_camera_policy.dart';
import '../../../../shared/map/premium_map_style.dart';
import '../../../../shared/map/premium_map_widgets.dart';

/// Buyurtma kartasida olish / yetkazish nuqtalari va to‘g‘ri chiziq marshrut (OSM).
/// Koordinata bo‘lmasa [AdminJobRouteFallbackStrip] ishlating.
class AdminJobRouteMiniMap extends StatefulWidget {
  const AdminJobRouteMiniMap({
    super.key,
    required this.job,
    this.height = 118,
  });

  final JobEntity job;
  final double height;

  static bool hasAnyCoordinate(JobEntity j) {
    return _coord(j.pickupLat, j.pickupLng) || _coord(j.dropoffLat, j.dropoffLng);
  }

  static bool _coord(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  @override
  State<AdminJobRouteMiniMap> createState() => _AdminJobRouteMiniMapState();
}

class _AdminJobRouteMiniMapState extends State<AdminJobRouteMiniMap> {
  final MapController _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LatLng? get _pickup {
    if (!AdminJobRouteMiniMap._coord(widget.job.pickupLat, widget.job.pickupLng)) {
      return null;
    }
    return LatLng(widget.job.pickupLat!, widget.job.pickupLng!);
  }

  LatLng? get _dropoff {
    if (!AdminJobRouteMiniMap._coord(widget.job.dropoffLat, widget.job.dropoffLng)) {
      return null;
    }
    return LatLng(widget.job.dropoffLat!, widget.job.dropoffLng!);
  }

  void _fit(LatLng? a, LatLng? b) {
    final pts = <LatLng>[];
    if (a != null) pts.add(a);
    if (b != null) pts.add(b);
    if (pts.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      premiumFitBounds(
        _controller,
        points: pts,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        maxZoom: 15,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pickup = _pickup;
    final dropoff = _dropoff;

    if (pickup == null && dropoff == null) {
      return const AdminJobRouteFallbackStrip();
    }

    final mapCam = MapCameraPolicy.forPickupDropoffMap(pickup, dropoff);
    final center = pickup ?? dropoff!;
    final bothPoints = pickup != null && dropoff != null;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: bothPoints ? 11 : 13,
                backgroundColor: PremiumMapStyle.mapBackground,
                cameraConstraint: mapCam.constraint,
                minZoom: mapCam.minZoom,
                maxZoom: mapCam.maxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
                onMapReady: () => _fit(pickup, dropoff),
              ),
              children: [
                PremiumMapStyle.lightTileLayer(),
                if (pickup != null && dropoff != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [pickup, dropoff],
                        strokeWidth: 4,
                        color: PremiumMapStyle.routeBlue,
                        borderStrokeWidth: 1.5,
                        borderColor: PremiumMapStyle.routeBlueBorder
                            .withValues(alpha: 0.9),
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (pickup != null)
                      Marker(
                        point: pickup,
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: PremiumRouteLetterMarker(
                          label: l10n.jobMapMarkerA,
                          diameter: 28,
                          fontSize: 12,
                        ),
                      ),
                    if (dropoff != null)
                      Marker(
                        point: dropoff,
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: PremiumRouteLetterMarker(
                          label: l10n.jobMapMarkerB,
                          diameter: 28,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Positioned(
              left: 6,
              right: 6,
              bottom: 4,
              child: PremiumMapAttribution(),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Koordinatasiz buyurtmalar uchun dizayndagi statik marshrut chizig‘i.
class AdminJobRouteFallbackStrip extends StatelessWidget {
  const AdminJobRouteFallbackStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFE8F4FC),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF22C55E),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CustomPaint(
                painter: _RouteLinePainter(),
                child: const SizedBox(height: 3),
              ),
            ),
          ),
          const Icon(Icons.location_on_rounded, color: Color(0xFF1976D2), size: 22),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _RouteLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF22C55E), Color(0xFF1976D2)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
