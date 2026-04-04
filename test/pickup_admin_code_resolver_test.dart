import 'package:courier_auction/core/geo/pickup_admin_code_resolver.dart';
import 'package:courier_auction/core/geo/work_area_keys.dart';
import 'package:courier_auction/data/regions_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PickupAdminCodeResolver — Windows vs Android parity', () {
    test(
      'label-only (empty structured OSM) matches structured pickupRegion/pickupDistrict',
      () {
        final tkRegion =
            RegionsSeed.regions.firstWhere((e) => e.code == 'TK');
        final anyTkDistrict = RegionsSeed.districts
            .firstWhere((e) => e.regionCode == 'TK');
        final regionUz = tkRegion.name.uz;
        final districtUz = anyTkDistrict.name.uz;

        const fallbackR = 'SA';
        final fallbackD = RegionsSeed.districts
            .firstWhere((e) => e.regionCode == 'SA')
            .code;

        final structured = PickupAdminCodeResolver.resolve(
          pickupRegion: regionUz,
          pickupDistrictOrCity: districtUz,
          pickupAddressExtra: null,
          fallbackRegionCode: fallbackR,
          fallbackDistrictCode: fallbackD,
        );

        final labelLikeWindows = PickupAdminCodeResolver.resolve(
          pickupRegion: null,
          pickupDistrictOrCity: null,
          pickupAddressExtra: '$districtUz · $regionUz',
          fallbackRegionCode: fallbackR,
          fallbackDistrictCode: fallbackD,
        );

        expect(
          structured.regionCode,
          labelLikeWindows.regionCode,
          reason: 'region_code should match',
        );
        expect(
          structured.districtCode,
          labelLikeWindows.districtCode,
          reason: 'district_code should match',
        );

        final keysStructured = WorkAreaKeys.fromAdminCodes(
          structured.regionCode,
          structured.districtCode,
        );
        final keysLabel = WorkAreaKeys.fromAdminCodes(
          labelLikeWindows.regionCode,
          labelLikeWindows.districtCode,
        );
        expect(keysStructured.regionKey, keysLabel.regionKey);
        expect(keysStructured.districtKey, keysLabel.districtKey);
      },
    );

    test('empty haystack uses fallback codes', () {
      final r = PickupAdminCodeResolver.resolve(
        pickupRegion: null,
        pickupDistrictOrCity: null,
        pickupAddressExtra: null,
        fallbackRegionCode: 'TK',
        fallbackDistrictCode: 'TK_C',
      );
      expect(r.regionCode, 'TK');
      expect(r.districtCode, 'TK_C');
    });
  });
}
