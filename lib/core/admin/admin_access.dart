import '../../models/app_user.dart';

/// Admin panel va admin marshrutlariga kirish (client guard).
///
/// Remote: Supabase RPC/viewlar uchun alohida `is_system_admin` / allowlist TODO.
abstract final class AdminAccess {
  AdminAccess._();

  /// Telefon allowlist yoki `is_system_admin`.
  static bool allowAdminPanel(AppUser user) {
    return user.canAccessAdminPanel || user.isSystemAdmin;
  }
}
