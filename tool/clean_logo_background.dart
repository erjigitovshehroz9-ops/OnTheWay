// Bir martalik: assets/images/logo.png dagi kulrang tarmoq va soyani oq fon bilan almashtiradi.
// ishga tushirish: dart run tool/clean_logo_background.dart

import 'dart:io';

import 'package:image/image.dart';

void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : 'assets/images/logo.png';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Fayl topilmadi: $path');
    exit(1);
  }

  final bytes = file.readAsBytesSync();
  final image = decodeImage(bytes);
  if (image == null) {
    stderr.writeln('Rasm dekodlanmadi: $path (${bytes.length} bayt)');
    exit(1);
  }

  final white = ColorRgb8(255, 255, 255);

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final r = p.r.toInt().clamp(0, 255);
      final g = p.g.toInt().clamp(0, 255);
      final b = p.b.toInt().clamp(0, 255);
      final mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
      final chroma = mx - mn;
      final luma = 0.299 * r + 0.587 * g + 0.114 * b;

      // Yorug‘ oq/kulrang fon, tarmoq chiziqlari, soya — past xroma.
      // To‘q ko‘k va sariq/oranj logo elementlari saqlanadi.
      final isBackground = (luma > 200 && chroma < 48) ||
          (luma > 155 && chroma < 34) ||
          (luma > 105 && luma < 195 && chroma < 32);

      if (isBackground) {
        image.setPixel(x, y, white);
      }
    }
  }

  file.writeAsBytesSync(encodePng(image));
  stdout.writeln('Yozildi: $path');
}
