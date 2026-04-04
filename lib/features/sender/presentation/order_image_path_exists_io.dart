import 'dart:io';

Future<bool> orderImagePathExists(String path) async {
  if (path.trim().isEmpty) return false;
  return File(path).exists();
}
