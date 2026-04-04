import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';

/// Qolgan [AppColors] importlari bilan mos kelishi uchun.
/// **Yangi UI** uchun `context.tokens` ([AppThemeTokens]) yoki [ColorScheme] ishlating.
abstract final class AppColors {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color auctionDeepBlue = Color(0xFF0D47A1);
  static const Color primaryCyan = Color(0xFF06B6D4);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111827);
  static const Color lightBackground = Color(0xFFF8FAFC);

  /// Joriy temaga mos yashil (kuryer / success).
  static Color accentGreenFor(BuildContext context) =>
      context.tokens.brandSecondary;

  /// Joriy temaga mos ko‘k.
  static Color primaryBlueFor(BuildContext context) =>
      context.tokens.brandPrimary;
}
