/// Faqat UI ko‘rinishi uchun: ismni har bir so‘zning bosh harfini katta qiladi.
/// Backend yoki DB qiymatini o‘zgartirmaydi.
String formatDisplayName(String rawName) {
  final collapsed = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (collapsed.isEmpty) return '';
  return collapsed
      .split(' ')
      .map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}
