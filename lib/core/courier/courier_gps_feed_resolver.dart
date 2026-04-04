import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/regions_seed.dart';
import '../../services/geocoding/nominatim_service.dart';
import '../geo/pickup_admin_code_resolver.dart';

/// Profil + seed bilan admin juftligining haqiqiyligi.
bool courierAdminPairValid(String? regionCode, String? districtCode) {
  if (regionCode == null || regionCode.isEmpty) return false;
  if (districtCode == null || districtCode.isEmpty) return false;
  return RegionsSeed.districts
      .any((d) => d.code == districtCode && d.regionCode == regionCode);
}

/// GPS + Nominatim → [PickupAdminCodeResolver] orqali viloyat/tuman kodlari.
/// Ruxsat / tarmoq xatosi → [fallbackRegionCode] / [fallbackDistrictCode].
Future<({String regionCode, String? districtCode})> resolveCourierFeedFromGps({
  required NominatimService nominatim,
  required String? fallbackRegionCode,
  required String? fallbackDistrictCode,
}) async {
  var regionOut = (fallbackRegionCode != null && fallbackRegionCode!.isNotEmpty)
      ? fallbackRegionCode!
      : 'TK';
  final String? districtOut =
      (fallbackDistrictCode != null && fallbackDistrictCode!.isNotEmpty)
          ? fallbackDistrictCode
          : null;

  try {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm != LocationPermission.always &&
        perm != LocationPermission.whileInUse) {
      if (kDebugMode) {
        debugPrint('[courierGps] permission denied → profile fallback');
      }
      return (regionCode: regionOut, districtCode: districtOut);
    }

    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      if (kDebugMode) {
        debugPrint('[courierGps] location service off → profile fallback');
      }
      return (regionCode: regionOut, districtCode: districtOut);
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
    final rev = await nominatim.reverse(
      lat: pos.latitude,
      lon: pos.longitude,
    );
    if (rev == null) {
      if (kDebugMode) debugPrint('[courierGps] reverse null → profile fallback');
      return (regionCode: regionOut, districtCode: districtOut);
    }

    final city = rev.city.trim();
    final dist = rev.district.trim();
    final reg = rev.region.trim();
    final parts = <String>[];
    if (city.isNotEmpty) parts.add(city);
    if (dist.isNotEmpty) parts.add(dist);
    final pickupDistrictLine = parts.join(' · ');

    final resolved = PickupAdminCodeResolver.resolve(
      pickupRegion: reg.isNotEmpty ? reg : null,
      pickupDistrictOrCity:
          pickupDistrictLine.isNotEmpty ? pickupDistrictLine : null,
      pickupAddressExtra: rev.displayAddress.trim().isEmpty
          ? null
          : rev.displayAddress.trim(),
      fallbackRegionCode: regionOut,
      fallbackDistrictCode: districtOut ?? 'TK_C',
    );

    if (kDebugMode) {
      debugPrint(
        '[courierGps] rev city=$city district=$dist region=$reg → '
        'resolved ${resolved.regionCode}/${resolved.districtCode}',
      );
    }

    if (courierAdminPairValid(resolved.regionCode, resolved.districtCode)) {
      return (
        regionCode: resolved.regionCode,
        districtCode: resolved.districtCode,
      );
    }
    if (kDebugMode) {
      debugPrint('[courierGps] resolved pair invalid for seed → profile fallback');
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[courierGps] error: $e\n$st');
    }
  }

  return (regionCode: regionOut, districtCode: districtOut);
}
