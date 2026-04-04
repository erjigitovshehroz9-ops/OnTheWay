class PhoneValidator {
  /// Taqqoslash uchun: `998` + 9 ta raqam (12 raqam), masalan `998901234567`.
  /// Turli formatdagi kiritishlar [validateUzbekPhone] orqali bir xil ko‘rinishga keltiriladi.
  static String? normalizeTo998Msisdn(String raw) {
    final canonical = validateUzbekPhone(raw);
    if (canonical == null) return null;
    return canonical.replaceAll(RegExp(r'\D'), '');
  }

  static String? validateUzbekPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) {
      return '+998$digits';
    }
    if (digits.startsWith('998') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.startsWith('998') && digits.length == 11) {
      return '+$digits';
    }
    if (raw.startsWith('+998') && digits.length >= 12) {
      return '+998${digits.substring(digits.length - 9)}';
    }
    return null;
  }
}
