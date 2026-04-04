import 'package:flutter/material.dart';

/// Premium semantic ranglar — vidjetlarda to‘g‘ridan-to‘g‘ri hex o‘rniga
/// `Theme.of(context).extension<AppThemeTokens>()` yoki `context.tokens`.
@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.brandPrimary,
    required this.brandPrimaryHover,
    required this.brandPrimarySoft,
    required this.brandSecondary,
    required this.brandSecondaryHover,
    required this.brandSecondarySoft,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.appBackground,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.cardMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnPrimary,
    required this.textOnDark,
    required this.border,
    required this.borderSoft,
    required this.divider,
    required this.shadow,
    required this.overlaySoftBlue,
    required this.overlaySoftGreen,
    required this.disabledBg,
    required this.disabledText,
    required this.iconPrimary,
    required this.iconMuted,
    required this.buttonPrimaryBg,
    required this.buttonPrimaryText,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryText,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusedBorder,
    required this.chipBackground,
    required this.chipSelectedBackground,
    required this.navBackground,
    required this.navSelected,
    required this.navUnselected,
    required this.sheetBackground,
    required this.dialogBackground,
    required this.auctionAccent,
    required this.courierAccent,
    required this.senderAccent,
    required this.roleSenderHighlight,
    required this.roleCourierHighlight,
    required this.navGradientTop,
    required this.navGradientMid,
    required this.navGradientBottom,
    required this.navTopBorder,
    required this.navLightShadow,
  });

  final Color brandPrimary;
  final Color brandPrimaryHover;
  final Color brandPrimarySoft;
  final Color brandSecondary;
  final Color brandSecondaryHover;
  final Color brandSecondarySoft;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  final Color appBackground;
  final Color surface;
  final Color surfaceAlt;
  final Color card;
  final Color cardMuted;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnPrimary;
  final Color textOnDark;

  final Color border;
  final Color borderSoft;
  final Color divider;

  final Color shadow;
  final Color overlaySoftBlue;
  final Color overlaySoftGreen;

  final Color disabledBg;
  final Color disabledText;

  final Color iconPrimary;
  final Color iconMuted;

  final Color buttonPrimaryBg;
  final Color buttonPrimaryText;
  final Color buttonSecondaryBg;
  final Color buttonSecondaryText;

  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusedBorder;

  final Color chipBackground;
  final Color chipSelectedBackground;

  final Color navBackground;
  final Color navSelected;
  final Color navUnselected;

  final Color sheetBackground;
  final Color dialogBackground;

  final Color auctionAccent;
  final Color courierAccent;
  final Color senderAccent;

  final Color roleSenderHighlight;
  final Color roleCourierHighlight;

  /// Kuryer pastki bar (qorong‘i rejim gradient).
  final Color navGradientTop;
  final Color navGradientMid;
  final Color navGradientBottom;
  final Color navTopBorder;

  /// Yorug‘ rejim pastki bar uchun yumshoq soyya.
  final Color navLightShadow;

  static const light = AppThemeTokens(
    brandPrimary: Color(0xFF2563EB),
    brandPrimaryHover: Color(0xFF1D4ED8),
    brandPrimarySoft: Color(0xFFDBEAFE),
    brandSecondary: Color(0xFF10B981),
    brandSecondaryHover: Color(0xFF059669),
    brandSecondarySoft: Color(0xFFD1FAE5),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF0EA5E9),
    appBackground: Color(0xFFF7FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F5F9),
    card: Color(0xFFFFFFFF),
    cardMuted: Color(0xFFF8FAFC),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textTertiary: Color(0xFF64748B),
    textOnPrimary: Color(0xFFFFFFFF),
    textOnDark: Color(0xFFF8FAFC),
    border: Color(0xFFE2E8F0),
    borderSoft: Color(0xFFEEF2F7),
    divider: Color(0xFFE5E7EB),
    shadow: Color(0x140F172A),
    overlaySoftBlue: Color(0xFFEFF6FF),
    overlaySoftGreen: Color(0xFFECFDF5),
    disabledBg: Color(0xFFE2E8F0),
    disabledText: Color(0xFF94A3B8),
    iconPrimary: Color(0xFF0F172A),
    iconMuted: Color(0xFF64748B),
    buttonPrimaryBg: Color(0xFF2563EB),
    buttonPrimaryText: Color(0xFFFFFFFF),
    buttonSecondaryBg: Color(0xFFF1F5F9),
    buttonSecondaryText: Color(0xFF2563EB),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFE2E8F0),
    inputFocusedBorder: Color(0xFF2563EB),
    chipBackground: Color(0xFFF1F5F9),
    chipSelectedBackground: Color(0xFFDBEAFE),
    navBackground: Color(0xFFFFFFFF),
    navSelected: Color(0xFF2563EB),
    navUnselected: Color(0xFF64748B),
    sheetBackground: Color(0xFFFFFFFF),
    dialogBackground: Color(0xFFFFFFFF),
    auctionAccent: Color(0xFF0D9488),
    courierAccent: Color(0xFF10B981),
    senderAccent: Color(0xFF2563EB),
    roleSenderHighlight: Color(0xFFE0F2FE),
    roleCourierHighlight: Color(0xFFECFDF5),
    navGradientTop: Color(0xFFF8FAFC),
    navGradientMid: Color(0xFFEFF6FF),
    navGradientBottom: Color(0xFFE0E7FF),
    navTopBorder: Color(0xFFE2E8F0),
    navLightShadow: Color(0x120F172A),
  );

  static const dark = AppThemeTokens(
    brandPrimary: Color(0xFF3B82F6),
    brandPrimaryHover: Color(0xFF60A5FA),
    brandPrimarySoft: Color(0xFF1E3A8A),
    brandSecondary: Color(0xFF10B981),
    brandSecondaryHover: Color(0xFF34D399),
    brandSecondarySoft: Color(0xFF064E3B),
    success: Color(0xFF10B981),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    info: Color(0xFF38BDF8),
    appBackground: Color(0xFF0B1220),
    surface: Color(0xFF111827),
    surfaceAlt: Color(0xFF172033),
    card: Color(0xFF1E293B),
    cardMuted: Color(0xFF172033),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textTertiary: Color(0xFF94A3B8),
    textOnPrimary: Color(0xFFFFFFFF),
    textOnDark: Color(0xFFF8FAFC),
    border: Color(0xFF334155),
    borderSoft: Color(0xFF243041),
    divider: Color(0xFF273449),
    shadow: Color(0x4D000000),
    overlaySoftBlue: Color(0x243B82F6),
    overlaySoftGreen: Color(0x2410B981),
    disabledBg: Color(0xFF1F2937),
    disabledText: Color(0xFF64748B),
    iconPrimary: Color(0xFFF8FAFC),
    iconMuted: Color(0xFF94A3B8),
    buttonPrimaryBg: Color(0xFF3B82F6),
    buttonPrimaryText: Color(0xFFFFFFFF),
    buttonSecondaryBg: Color(0xFF1E293B),
    buttonSecondaryText: Color(0xFF93C5FD),
    inputBackground: Color(0xFF1E293B),
    inputBorder: Color(0xFF334155),
    inputFocusedBorder: Color(0xFF60A5FA),
    chipBackground: Color(0xFF172033),
    chipSelectedBackground: Color(0xFF1E3A8A),
    navBackground: Color(0xFF111827),
    navSelected: Color(0xFF60A5FA),
    navUnselected: Color(0xFF94A3B8),
    sheetBackground: Color(0xFF1E293B),
    dialogBackground: Color(0xFF1E293B),
    auctionAccent: Color(0xFF2DD4BF),
    courierAccent: Color(0xFF34D399),
    senderAccent: Color(0xFF60A5FA),
    roleSenderHighlight: Color(0x1A3B82F6),
    roleCourierHighlight: Color(0x1A10B981),
    navGradientTop: Color(0xFF1E293B),
    navGradientMid: Color(0xFF0F172A),
    navGradientBottom: Color(0xFF020617),
    navTopBorder: Color(0x33FFFFFF),
    navLightShadow: Color(0x66000000),
  );

  @override
  AppThemeTokens copyWith({
    Color? brandPrimary,
    Color? brandPrimaryHover,
    Color? brandPrimarySoft,
    Color? brandSecondary,
    Color? brandSecondaryHover,
    Color? brandSecondarySoft,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? appBackground,
    Color? surface,
    Color? surfaceAlt,
    Color? card,
    Color? cardMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnPrimary,
    Color? textOnDark,
    Color? border,
    Color? borderSoft,
    Color? divider,
    Color? shadow,
    Color? overlaySoftBlue,
    Color? overlaySoftGreen,
    Color? disabledBg,
    Color? disabledText,
    Color? iconPrimary,
    Color? iconMuted,
    Color? buttonPrimaryBg,
    Color? buttonPrimaryText,
    Color? buttonSecondaryBg,
    Color? buttonSecondaryText,
    Color? inputBackground,
    Color? inputBorder,
    Color? inputFocusedBorder,
    Color? chipBackground,
    Color? chipSelectedBackground,
    Color? navBackground,
    Color? navSelected,
    Color? navUnselected,
    Color? sheetBackground,
    Color? dialogBackground,
    Color? auctionAccent,
    Color? courierAccent,
    Color? senderAccent,
    Color? roleSenderHighlight,
    Color? roleCourierHighlight,
    Color? navGradientTop,
    Color? navGradientMid,
    Color? navGradientBottom,
    Color? navTopBorder,
    Color? navLightShadow,
  }) {
    return AppThemeTokens(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandPrimaryHover: brandPrimaryHover ?? this.brandPrimaryHover,
      brandPrimarySoft: brandPrimarySoft ?? this.brandPrimarySoft,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      brandSecondaryHover: brandSecondaryHover ?? this.brandSecondaryHover,
      brandSecondarySoft: brandSecondarySoft ?? this.brandSecondarySoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      appBackground: appBackground ?? this.appBackground,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      card: card ?? this.card,
      cardMuted: cardMuted ?? this.cardMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      textOnDark: textOnDark ?? this.textOnDark,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      overlaySoftBlue: overlaySoftBlue ?? this.overlaySoftBlue,
      overlaySoftGreen: overlaySoftGreen ?? this.overlaySoftGreen,
      disabledBg: disabledBg ?? this.disabledBg,
      disabledText: disabledText ?? this.disabledText,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconMuted: iconMuted ?? this.iconMuted,
      buttonPrimaryBg: buttonPrimaryBg ?? this.buttonPrimaryBg,
      buttonPrimaryText: buttonPrimaryText ?? this.buttonPrimaryText,
      buttonSecondaryBg: buttonSecondaryBg ?? this.buttonSecondaryBg,
      buttonSecondaryText: buttonSecondaryText ?? this.buttonSecondaryText,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      inputFocusedBorder: inputFocusedBorder ?? this.inputFocusedBorder,
      chipBackground: chipBackground ?? this.chipBackground,
      chipSelectedBackground: chipSelectedBackground ?? this.chipSelectedBackground,
      navBackground: navBackground ?? this.navBackground,
      navSelected: navSelected ?? this.navSelected,
      navUnselected: navUnselected ?? this.navUnselected,
      sheetBackground: sheetBackground ?? this.sheetBackground,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      auctionAccent: auctionAccent ?? this.auctionAccent,
      courierAccent: courierAccent ?? this.courierAccent,
      senderAccent: senderAccent ?? this.senderAccent,
      roleSenderHighlight: roleSenderHighlight ?? this.roleSenderHighlight,
      roleCourierHighlight: roleCourierHighlight ?? this.roleCourierHighlight,
      navGradientTop: navGradientTop ?? this.navGradientTop,
      navGradientMid: navGradientMid ?? this.navGradientMid,
      navGradientBottom: navGradientBottom ?? this.navGradientBottom,
      navTopBorder: navTopBorder ?? this.navTopBorder,
      navLightShadow: navLightShadow ?? this.navLightShadow,
    );
  }

  @override
  ThemeExtension<AppThemeTokens> lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    Color lc(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppThemeTokens(
      brandPrimary: lc(brandPrimary, other.brandPrimary),
      brandPrimaryHover: lc(brandPrimaryHover, other.brandPrimaryHover),
      brandPrimarySoft: lc(brandPrimarySoft, other.brandPrimarySoft),
      brandSecondary: lc(brandSecondary, other.brandSecondary),
      brandSecondaryHover: lc(brandSecondaryHover, other.brandSecondaryHover),
      brandSecondarySoft: lc(brandSecondarySoft, other.brandSecondarySoft),
      success: lc(success, other.success),
      warning: lc(warning, other.warning),
      error: lc(error, other.error),
      info: lc(info, other.info),
      appBackground: lc(appBackground, other.appBackground),
      surface: lc(surface, other.surface),
      surfaceAlt: lc(surfaceAlt, other.surfaceAlt),
      card: lc(card, other.card),
      cardMuted: lc(cardMuted, other.cardMuted),
      textPrimary: lc(textPrimary, other.textPrimary),
      textSecondary: lc(textSecondary, other.textSecondary),
      textTertiary: lc(textTertiary, other.textTertiary),
      textOnPrimary: lc(textOnPrimary, other.textOnPrimary),
      textOnDark: lc(textOnDark, other.textOnDark),
      border: lc(border, other.border),
      borderSoft: lc(borderSoft, other.borderSoft),
      divider: lc(divider, other.divider),
      shadow: lc(shadow, other.shadow),
      overlaySoftBlue: lc(overlaySoftBlue, other.overlaySoftBlue),
      overlaySoftGreen: lc(overlaySoftGreen, other.overlaySoftGreen),
      disabledBg: lc(disabledBg, other.disabledBg),
      disabledText: lc(disabledText, other.disabledText),
      iconPrimary: lc(iconPrimary, other.iconPrimary),
      iconMuted: lc(iconMuted, other.iconMuted),
      buttonPrimaryBg: lc(buttonPrimaryBg, other.buttonPrimaryBg),
      buttonPrimaryText: lc(buttonPrimaryText, other.buttonPrimaryText),
      buttonSecondaryBg: lc(buttonSecondaryBg, other.buttonSecondaryBg),
      buttonSecondaryText: lc(buttonSecondaryText, other.buttonSecondaryText),
      inputBackground: lc(inputBackground, other.inputBackground),
      inputBorder: lc(inputBorder, other.inputBorder),
      inputFocusedBorder: lc(inputFocusedBorder, other.inputFocusedBorder),
      chipBackground: lc(chipBackground, other.chipBackground),
      chipSelectedBackground: lc(chipSelectedBackground, other.chipSelectedBackground),
      navBackground: lc(navBackground, other.navBackground),
      navSelected: lc(navSelected, other.navSelected),
      navUnselected: lc(navUnselected, other.navUnselected),
      sheetBackground: lc(sheetBackground, other.sheetBackground),
      dialogBackground: lc(dialogBackground, other.dialogBackground),
      auctionAccent: lc(auctionAccent, other.auctionAccent),
      courierAccent: lc(courierAccent, other.courierAccent),
      senderAccent: lc(senderAccent, other.senderAccent),
      roleSenderHighlight: lc(roleSenderHighlight, other.roleSenderHighlight),
      roleCourierHighlight: lc(roleCourierHighlight, other.roleCourierHighlight),
      navGradientTop: lc(navGradientTop, other.navGradientTop),
      navGradientMid: lc(navGradientMid, other.navGradientMid),
      navGradientBottom: lc(navGradientBottom, other.navGradientBottom),
      navTopBorder: lc(navTopBorder, other.navTopBorder),
      navLightShadow: lc(navLightShadow, other.navLightShadow),
    );
  }
}

/// `Theme.of(context).extension<AppThemeTokens>()` uchun qisqa yo‘l.
extension AppThemeTokensX on BuildContext {
  AppThemeTokens get tokens {
    final t = Theme.of(this).extension<AppThemeTokens>();
    if (t != null) return t;
    return Theme.of(this).brightness == Brightness.dark
        ? AppThemeTokens.dark
        : AppThemeTokens.light;
  }
}

extension AppThemeTokensDataX on ThemeData {
  AppThemeTokens get tokens {
    return extension<AppThemeTokens>() ??
        (brightness == Brightness.dark ? AppThemeTokens.dark : AppThemeTokens.light);
  }
}
