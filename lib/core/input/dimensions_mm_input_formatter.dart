import 'package:flutter/services.dart';

/// Razmer: `1000x500x200`. Probel (va boshqa bo'shliqlar) `x` ga almashtiriladi;
/// segmentlar `x` bilan ajratiladi, har segmentda 1–6 ta raqam.
class DimensionsMmInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _normalize(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _normalize(String raw) {
    // Probel va boshqa whitespace → x (oltita raqam kutilmaydi)
    var t = raw.replaceAll(RegExp(r'\s+'), 'x');
    t = t.replaceAll(RegExp(r'[^0-9x]'), '');
    t = t.replaceAll(RegExp(r'x+'), 'x');
    while (t.startsWith('x')) {
      t = t.substring(1);
    }
    if (t.isEmpty) return '';

    final parts = t.split('x');
    final sb = StringBuffer();
    var digitsUsed = 0;

    for (var i = 0; i < parts.length && i < 3; i++) {
      var d = parts[i].replaceAll(RegExp(r'[^0-9]'), '');
      if (d.length > 6) d = d.substring(0, 6);
      final room = 18 - digitsUsed;
      if (room <= 0) break;
      if (d.length > room) d = d.substring(0, room);
      digitsUsed += d.length;

      if (i > 0) sb.write('x');
      sb.write(d);
    }

    return sb.toString();
  }
}

bool isValidDimensionsMm(String s) {
  return RegExp(r'^\d{1,6}x\d{1,6}x\d{1,6}$').hasMatch(s.trim());
}
