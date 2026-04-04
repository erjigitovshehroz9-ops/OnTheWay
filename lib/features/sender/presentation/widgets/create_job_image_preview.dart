import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'create_job_image_preview_file_stub.dart'
    if (dart.library.io) 'create_job_image_preview_file_io.dart'
        as preview_file;

/// Mahsulot rasmi: brauzerda [bytes], desktop/mobilda yo‘q bo‘lsa fayl yo‘li.
Widget createJobImagePreview({
  required Uint8List? bytes,
  required String filePath,
  double height = 168,
}) {
  if (bytes != null && bytes.isNotEmpty) {
    return Image.memory(
      bytes,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
  final p = filePath.trim();
  if (!kIsWeb && p.isNotEmpty) {
    return preview_file.buildFilePreview(p, height);
  }
  return const SizedBox.shrink();
}
