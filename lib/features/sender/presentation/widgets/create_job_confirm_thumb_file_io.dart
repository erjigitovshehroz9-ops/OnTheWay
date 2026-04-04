import 'dart:io';

import 'package:flutter/material.dart';

Widget buildConfirmThumbFile(String path) {
  return Image.file(
    File(path),
    width: 52,
    height: 52,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => const SizedBox(
      width: 52,
      height: 52,
    ),
  );
}
