import 'dart:io';

import 'package:flutter/material.dart';

Widget buildFilePreview(String path, double height) {
  return Image.file(
    File(path),
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
  );
}
