import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';

/// Yuboruvchi/kuryer menyusi: metallik ramka + profil rasmi yoki monogram + pastki status nuqta.
class PremiumMonogramAvatar extends StatelessWidget {
  const PremiumMonogramAvatar({
    super.key,
    required this.initial,
    this.profileImagePath,
    this.overlayTopRight,
  });

  final String initial;
  /// Lokal fayl yo‘li (`profile_image_path_*`). Bo‘sh yoki noto‘g‘ri bo‘lsa monogram ko‘rinadi.
  final String? profileImagePath;
  /// Masalan bildirishnoma puls nuqtasi.
  final Widget? overlayTopRight;

  static const double _diameter = 40;
  static const double _ring = 2.8;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final metalHi = isDark ? const Color(0xFFC8CCD6) : const Color(0xFFF9FAFB);
    final metalLo = isDark ? const Color(0xFF525A6A) : const Color(0xFF7C8794);
    final metalEdge = isDark ? const Color(0xFF3D4555) : const Color(0xFF64748B);

    final discInner = isDark ? const Color(0xFFADB8C9) : const Color(0xFFE8EDF3);
    final discOuter = isDark ? const Color(0xFF8B96A8) : const Color(0xFFD0DAE6);

    final glyphColor = isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B);
    final statusBorder = isDark ? const Color(0xFF020617) : const Color(0xFF0B1220);

    final innerSize = _diameter - 2 * _ring;
    final innerBorder = Border.all(
      color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.65),
      width: 0.9,
    );

    final monogram = Text(
      initial,
      style: TextStyle(
        color: glyphColor,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: -0.6,
      ),
    );

    Widget monogramOrPerson() {
      if (initial == '?') {
        return Icon(Icons.person_rounded, size: 20, color: glyphColor);
      }
      return monogram;
    }

    final path = profileImagePath?.trim();
    File? photoFile;
    if (path != null && path.isNotEmpty) {
      final f = File(path);
      if (f.existsSync()) photoFile = f;
    }
    final showPhoto = photoFile != null;

    final Widget innerChild;
    if (showPhoto) {
      innerChild = Container(
        width: innerSize,
        height: innerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: innerBorder,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          photoFile!,
          fit: BoxFit.cover,
          width: innerSize,
          height: innerSize,
          errorBuilder: (_, __, ___) => Center(child: monogramOrPerson()),
        ),
      );
    } else {
      innerChild = Container(
        width: innerSize,
        height: innerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.42),
            radius: 1.05,
            colors: [
              discInner,
              discOuter,
            ],
          ),
          border: innerBorder,
        ),
        alignment: Alignment.center,
        child: monogramOrPerson(),
      );
    }

    final core = Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
            blurRadius: isDark ? 12 : 9,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: metalHi.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(-1, -2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              metalHi,
              metalLo,
              metalEdge,
              metalLo,
            ],
            stops: const [0.0, 0.38, 0.62, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(_ring),
        child: innerChild,
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        core,
        if (overlayTopRight != null)
          Positioned(
            top: -2,
            right: -2,
            child: overlayTopRight!,
          ),
        Positioned(
          right: -0.5,
          bottom: -0.5,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: t.brandSecondary,
              shape: BoxShape.circle,
              border: Border.all(color: statusBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
