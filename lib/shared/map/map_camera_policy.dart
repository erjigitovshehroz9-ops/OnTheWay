import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/job_entity.dart';
import 'uzbekistan_map_bounds.dart';

/// Xarita kamera cheklovi: buyurtma ichki (O‘Z) yoki xalqaro.
class MapCameraChoice {
  const MapCameraChoice({
    required this.constraint,
    this.minZoom,
    this.maxZoom = 19,
  });

  final CameraConstraint constraint;
  final double? minZoom;
  final double maxZoom;
}

/// Qayerda `UzbekistanMapBounds` ishlatish yoki butun dunyo ko‘rinishi.
abstract final class MapCameraPolicy {
  MapCameraPolicy._();

  static bool _coordOk(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  static bool isInsideUzbekistan(LatLng p) {
    final b = UzbekistanMapBounds.bounds;
    return p.latitude >= b.south &&
        p.latitude <= b.north &&
        p.longitude >= b.west &&
        p.longitude <= b.east;
  }

  /// Olish va yetkazish koordinatalari bor va **ikkalasi ham** O‘zbekiston bbox ichida.
  static bool isDomesticUzbekistanJob(JobEntity job) {
    if (!_coordOk(job.pickupLat, job.pickupLng) ||
        !_coordOk(job.dropoffLat, job.dropoffLng)) {
      return false;
    }
    final pu = LatLng(job.pickupLat!, job.pickupLng!);
    final dr = LatLng(job.dropoffLat!, job.dropoffLng!);
    return isInsideUzbekistan(pu) && isInsideUzbekistan(dr);
  }

  static bool isDomesticUzbekistanPickupDropoff(LatLng? pickup, LatLng? dropoff) {
    if (pickup == null || dropoff == null) return false;
    return isInsideUzbekistan(pickup) && isInsideUzbekistan(dropoff);
  }

  /// Buyurtma yaratish (manzil tanlash) — qidiruv va xarita butun dunyo.
  static const MapCameraChoice creationPicker = MapCameraChoice(
    constraint: CameraConstraint.unconstrained(),
    minZoom: null,
    maxZoom: 19,
  );

  /// Auksiondan keyin kuryer kuzatuvi / marshrut: ichki buyurtma — faqat O‘Z.
  static MapCameraChoice forCourierTrackingJob(JobEntity job) {
    if (isDomesticUzbekistanJob(job)) {
      return MapCameraChoice(
        constraint: UzbekistanMapBounds.cameraConstraint,
        minZoom: UzbekistanMapBounds.minZoom,
        maxZoom: UzbekistanMapBounds.maxZoom,
      );
    }
    return creationPicker;
  }

  /// Olish / yetkazish nuqtalari bilan marshrut xaritasi.
  static MapCameraChoice forPickupDropoffMap(LatLng? pickup, LatLng? dropoff) {
    if (isDomesticUzbekistanPickupDropoff(pickup, dropoff)) {
      return MapCameraChoice(
        constraint: UzbekistanMapBounds.cameraConstraint,
        minZoom: UzbekistanMapBounds.minZoom,
        maxZoom: UzbekistanMapBounds.maxZoom,
      );
    }
    return creationPicker;
  }

  /// Kuryer paneli buyurtmalar xaritasi (asosan ichki bozor).
  static MapCameraChoice get courierJobsOverview => MapCameraChoice(
        constraint: UzbekistanMapBounds.cameraConstraint,
        minZoom: UzbekistanMapBounds.minZoom,
        maxZoom: UzbekistanMapBounds.maxZoom,
      );

  static MapCameraChoice get adminTrackingOverview => courierJobsOverview;
}
