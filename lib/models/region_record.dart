import 'localized_string.dart';

class RegionRecord {
  const RegionRecord({
    required this.code,
    required this.name,
  });

  final String code;
  final LocalizedString name;
}

class DistrictRecord {
  const DistrictRecord({
    required this.code,
    required this.regionCode,
    required this.name,
  });

  final String code;
  final String regionCode;
  final LocalizedString name;
}
