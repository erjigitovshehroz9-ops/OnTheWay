import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readLocalImageBytes(String path) async {
  final f = File(path);
  if (!await f.exists()) return null;
  return f.readAsBytes();
}
