import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme_tokens.dart';

export 'app_theme_tokens.dart';

/// Ilova temasi: [AppThemeTokens] + [ColorScheme] + komponenta temalari.
abstract final class AppTheme {
  static ThemeData light() {
    const tokens = AppThemeTokens.light;
    const scaffoldFill = Color(0xFFF8FAFC);

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: tokens.brandPrimary,
      onPrimary: tokens.textOnPrimary,
      primaryContainer: tokens.brandPrimarySoft,
      onPrimaryContainer: const Color(0xFF1E3A8A),
      secondary: tokens.brandSecondary,
      onSecondary: tokens.textOnPrimary,
      secondaryContainer: tokens.brandSecondarySoft,
      onSecondaryContainer: const Color(0xFF065F46),
      tertiary: tokens.auctionAccent,
      onTertiary: tokens.textOnPrimary,
      tertiaryContainer: const Color(0xFFCCFBF1),
      onTertiaryContainer: const Color(0xFF134E4A),
      error: tokens.error,
      onError: tokens.textOnPrimary,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF991B1B),
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      surfaceContainerHighest: tokens.surfaceAlt,
      onSurfaceVariant: tokens.textTertiary,
      outline: tokens.border,
      outlineVariant: tokens.borderSoft,
      shadow: tokens.shadow,
      scrim: Color(0x99000000),
      inverseSurface: const Color(0xFF0F172A),
      onInverseSurface: tokens.textOnDark,
      inversePrimary: tokens.brandPrimaryHover,
      surfaceTint: tokens.brandPrimary,
    );

    final baseText = ThemeData(brightness: Brightness.light, useMaterial3: true).textTheme;
    final textTheme = GoogleFonts.manropeTextTheme(baseText).apply(
      bodyColor: tokens.textPrimary,
      displayColor: tokens.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldFill,
      shadowColor: tokens.shadow,
      extensions: const [AppThemeTokens.light],
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: tokens.divider, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: tokens.surface,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.shadow,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: tokens.textPrimary,
        ),
        iconTheme: IconThemeData(color: tokens.iconPrimary),
        shape: Border(bottom: BorderSide(color: tokens.borderSoft, width: 1)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.borderSoft, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: tokens.textTertiary, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(color: tokens.textSecondary, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.inputFocusedBorder, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.disabledBg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.buttonPrimaryBg,
          foregroundColor: tokens.buttonPrimaryText,
          disabledBackgroundColor: tokens.disabledBg,
          disabledForegroundColor: tokens.disabledText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.pressed)) {
              return tokens.brandPrimaryHover.withValues(alpha: 0.18);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.brandPrimary,
          side: BorderSide(color: tokens.border),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.brandPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.chipBackground,
        selectedColor: tokens.chipSelectedBackground,
        disabledColor: tokens.disabledBg,
        labelStyle: TextStyle(color: tokens.textSecondary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(color: tokens.textTertiary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: tokens.borderSoft),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.sheetBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: tokens.sheetBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        dragHandleColor: tokens.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.dialogBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: tokens.borderSoft),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.textOnDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.iconMuted,
        textColor: tokens.textPrimary,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: tokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
      ),
      iconTheme: IconThemeData(color: tokens.iconPrimary),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.navBackground,
        selectedItemColor: tokens.navSelected,
        unselectedItemColor: tokens.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    const tokens = AppThemeTokens.dark;
    const scaffoldFill = Color(0xFF0F172A);

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: tokens.brandPrimary,
      onPrimary: tokens.textOnPrimary,
      primaryContainer: tokens.brandPrimarySoft,
      onPrimaryContainer: const Color(0xFFBFDBFE),
      secondary: tokens.brandSecondary,
      onSecondary: tokens.textOnPrimary,
      secondaryContainer: tokens.brandSecondarySoft,
      onSecondaryContainer: const Color(0xFFD1FAE5),
      tertiary: tokens.auctionAccent,
      onTertiary: const Color(0xFF042F2E),
      tertiaryContainer: const Color(0xFF115E59),
      onTertiaryContainer: const Color(0xFFCCFBF1),
      error: tokens.error,
      onError: const Color(0xFF450A0A),
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFEE2E2),
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      surfaceContainerHighest: tokens.surfaceAlt,
      onSurfaceVariant: tokens.textTertiary,
      outline: tokens.border,
      outlineVariant: tokens.borderSoft,
      shadow: tokens.shadow,
      scrim: Color(0xCC000000),
      inverseSurface: const Color(0xFFE2E8F0),
      onInverseSurface: const Color(0xFF0F172A),
      inversePrimary: tokens.brandPrimaryHover,
      surfaceTint: tokens.brandPrimary,
    );

    final baseText = ThemeData(brightness: Brightness.dark, useMaterial3: true).textTheme;
    final textTheme = GoogleFonts.manropeTextTheme(baseText).apply(
      bodyColor: tokens.textPrimary,
      displayColor: tokens.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldFill,
      shadowColor: tokens.shadow,
      extensions: const [AppThemeTokens.dark],
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: tokens.divider, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: tokens.surface,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.shadow,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: tokens.textPrimary,
        ),
        iconTheme: IconThemeData(color: tokens.textPrimary),
        shape: Border(bottom: BorderSide(color: tokens.borderSoft, width: 1)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.borderSoft, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: tokens.textTertiary, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(color: tokens.textSecondary, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.inputFocusedBorder, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.disabledBg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.buttonPrimaryBg,
          foregroundColor: tokens.buttonPrimaryText,
          disabledBackgroundColor: tokens.disabledBg,
          disabledForegroundColor: tokens.disabledText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.pressed)) {
              return tokens.brandPrimaryHover.withValues(alpha: 0.22);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.brandPrimary,
          side: BorderSide(color: tokens.border),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.brandPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.chipBackground,
        selectedColor: tokens.chipSelectedBackground,
        disabledColor: tokens.disabledBg,
        labelStyle: TextStyle(color: tokens.textSecondary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(color: tokens.textTertiary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: tokens.borderSoft),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.sheetBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: tokens.sheetBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        dragHandleColor: tokens.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.dialogBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: tokens.borderSoft),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.card,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.iconMuted,
        textColor: tokens.textPrimary,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: tokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
      ),
      iconTheme: IconThemeData(color: tokens.textPrimary),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.navBackground,
        selectedItemColor: tokens.navSelected,
        unselectedItemColor: tokens.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  /// Kuryer va yuboruvchi bosh panelidagi markaziy sarlavha (Manrope emas — barqaror kompakt shrift).
  static TextStyle panelTopBarTitle(Color color) => GoogleFonts.roboto(
        color: color,
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 1.2,
        height: 1.0,
      );
}
