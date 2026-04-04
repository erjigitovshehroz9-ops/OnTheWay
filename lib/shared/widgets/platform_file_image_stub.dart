import 'package:flutter/material.dart';

/// Web: no `dart:io`; only network URLs show as images.
Widget platformFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  final t = path.trim();
  if (t.startsWith('http://') || t.startsWith('https://')) {
    return Image.network(
      t,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
    );
  }
  return Icon(
    Icons.person_rounded,
    size: width != null ? width * 0.55 : 56,
  );
}
