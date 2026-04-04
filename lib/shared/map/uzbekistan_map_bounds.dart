import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Ichki (O‘Z) buyurtmalar uchun kamera cheklovi — faqat O‘zbekiston hududi.
///
/// [CameraConstraint.contain] kengaytirilgan bbox ichida ko‘rinishni talab qiladi;
/// juda kichik [minZoom]da cheklov `null` qaytarishi mumkin — shuning uchun
/// [minZoom] belgilangan.
abstract final class UzbekistanMapBounds {
  /// Taxminiy chegara (janubi-g‘arb … shimoli-sharq) + chekka bufer.
  static final LatLngBounds bounds = LatLngBounds(
    const LatLng(36.72, 55.92),
    const LatLng(45.72, 73.28),
  );

  static final CameraConstraint cameraConstraint =
      CameraConstraint.contain(bounds: bounds);

  /// Pastki zoom — `contain` bilan mos kelishi uchun (planshet/katta ekran).
  static const double minZoom = 5.5;

  static const double maxZoom = 19;
}
