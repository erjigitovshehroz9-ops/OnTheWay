/// Kuryer buyurtmalar filtri: tuman dropdownda «barcha tumanlar» tanlovi.
/// SQL da `district_code` filtri qo‘llanmaydi (faqat viloyat/shahar).
abstract final class CourierDistrictFilter {
  CourierDistrictFilter._();

  static const String allDistrictsValue = '__ALL_DISTRICTS__';
}
