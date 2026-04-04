import 'dart:io';

import 'package:flutter/material.dart';

Widget buildLocalJobImage(
  String path,
  BoxFit fit, {
  required Widget error,
}) {
  return Image.file(
    File(path),
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (_, __, ___) => error,
  );
}
