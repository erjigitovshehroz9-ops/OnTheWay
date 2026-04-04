import 'package:flutter/services.dart';

/// Oʻzbekiston mobil raqami uchun: faqat raqamlar, 9 ta cheklov, `XX XXX XX XX` bo‘shliqlar.
class UzPhoneMaskFormatter extends TextInputFormatter {
  const UzPhoneMaskFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) b.write(' ');
      b.write(digits[i]);
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
