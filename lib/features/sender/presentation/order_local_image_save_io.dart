import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

String _extFromName(String? suggestedName) {
  final n = (suggestedName ?? '').toLowerCase();
  if (n.endsWith('.png')) return 'png';
  if (n.endsWith('.webp')) return 'webp';
  if (n.endsWith('.gif')) return 'gif';
  return 'jpg';
}

/// Writes [bytes] into app documents and returns the absolute path.
Future<String> savePickedImageBytes(
  Uint8List bytes, {
  String? suggestedName,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final ext = _extFromName(suggestedName);
  final name = 'parcel_${const Uuid().v4()}.$ext';
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
