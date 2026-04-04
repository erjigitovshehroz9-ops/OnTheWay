abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String phone = '/auth/phone';
  static const String sms = '/auth/sms';
  static const String offer = '/auth/offer';
  static const String role = '/auth/role';
  static const String sender = '/sender';
  static const String courier = '/courier';
  static const String admin = '/admin';
  static const String settings = '/settings';
  static const String createJob = '/sender/create-job';
  static const String mapPicker = '/map-picker';
  static const String adminStats = '/admin/statistics';
  static const String adminUsers = '/admin/users';
  static const String adminMap = '/admin/map';
  static const String adminContactRequests = '/admin/contact-requests';

  static String jobDetail(String id) => '/job/$id';
  static String jobAuction(String id) => '/job/$id/auction';
}
