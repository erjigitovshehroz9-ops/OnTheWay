import '../../data/regions_seed.dart';
import '../../models/app_user.dart';
import '../constants/courier_district_filter.dart';

/// [CourierDistrictFilter.allDistrictsValue] — tuman filtri yo‘q (butun viloyat/shahar).
/// Profil tumani boshqa viloyatga tegishli bo‘lsa, uni filtrga qo‘yish noto‘g‘ri juft beradi.
String? effectiveCourierDistrictForFeed({
  required String? selectedDistrict,
  required String? regionCode,
  required String? profileDistrict,
}) {
  if (selectedDistrict == CourierDistrictFilter.allDistrictsValue) {
    return null;
  }
  if (selectedDistrict != null && selectedDistrict.isNotEmpty) {
    return selectedDistrict;
  }
  final pd = profileDistrict;
  if (pd == null || pd.isEmpty) return null;
  final r = regionCode;
  if (r == null || r.isEmpty) return pd;
  final belongs =
      RegionsSeed.districts.any((d) => d.code == pd && d.regionCode == r);
  return belongs ? pd : null;
}

/// UI tanlovi + profil → tasmasi SQL/Dart filtrlari (bitta manba).
({String? regionCode, String? districtCode, bool wholeRegion}) resolveCourierFeedSelection({
  required AppUser? user,
  required String? selRegionCode,
  required String? selDistrictCode,
}) {
  final effectiveR = selRegionCode ?? user?.regionCode;
  final effectiveD = effectiveCourierDistrictForFeed(
    selectedDistrict: selDistrictCode,
    regionCode: effectiveR,
    profileDistrict: user?.districtCode,
  );
  return (
    regionCode: effectiveR,
    districtCode: effectiveD,
    wholeRegion: effectiveD == null,
  );
}
