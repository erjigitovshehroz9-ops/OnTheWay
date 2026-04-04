import 'package:flutter/material.dart';

import 'platform_file_image_stub.dart'
    if (dart.library.io) 'platform_file_image_io.dart' as impl;

Widget platformFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  return impl.platformFileImage(path, fit: fit, width: width, height: height);
}
