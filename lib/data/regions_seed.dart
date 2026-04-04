import '../models/region_record.dart';
import 'regions_seed_generated.dart';

/// O‘zbekiston viloyatlari va tumanlari (to‘liq ro‘yxat).
/// Ma’lumot: `tool/build_uz_regions_seed.py` → `regions_seed_generated.dart`.
abstract final class RegionsSeed {
  static final List<RegionRecord> regions =
      RegionsSeedGenerated.parseRegions();
  static final List<DistrictRecord> districts =
      RegionsSeedGenerated.parseDistricts();
}
