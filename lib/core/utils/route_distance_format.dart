/// Masofa chiqarish: `5 km`, `10.4 km`, `1.2 km`
String formatRouteDistanceKm(double km) {
  if (km.isNaN || km < 0) return '0 km';
  final rounded = km.round();
  if ((km - rounded).abs() < 0.05) {
    return '$rounded km';
  }
  return '${km.toStringAsFixed(1)} km';
}
