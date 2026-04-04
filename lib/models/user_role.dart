enum UserRole {
  sender,
  courier,
  admin;

  String get storageValue => name;

  static UserRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final role in UserRole.values) {
      if (role.name == raw) return role;
    }
    return null;
  }
}
