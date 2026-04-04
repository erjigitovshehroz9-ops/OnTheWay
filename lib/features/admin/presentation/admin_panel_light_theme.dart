import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

/// Admin panel dizayni: teal-ko‘k urug‘i, och fon va kartalar bilan uyg‘un.
ThemeData buildAdminPanelLightTheme() {
  final softBg = AppThemeTokens.light.overlaySoftBlue;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF13635B),
    brightness: Brightness.light,
    surface: AppThemeTokens.light.surface,
    onSurface: AppThemeTokens.light.textPrimary,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: softBg,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: softBg,
      foregroundColor: AppThemeTokens.light.textPrimary,
    ),
  );
}
