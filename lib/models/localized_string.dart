/// Pure Dart (no Flutter imports) so geo/resolver code can run in VM tools (e.g. `dart run tool/...`).
class LocalizedString {
  const LocalizedString({
    required this.uz,
    required this.ru,
    required this.en,
  });

  final String uz;
  final String ru;
  final String en;

  String resolveLang(String languageCode) {
    switch (languageCode) {
      case 'ru':
        return ru;
      case 'en':
        return en;
      case 'uz':
      default:
        return uz;
    }
  }

  LocalizedString copyWith({
    String? uz,
    String? ru,
    String? en,
  }) {
    return LocalizedString(
      uz: uz ?? this.uz,
      ru: ru ?? this.ru,
      en: en ?? this.en,
    );
  }

  Map<String, dynamic> toJson() => {
        'uz': uz,
        'ru': ru,
        'en': en,
      };

  factory LocalizedString.fromJson(Map<String, dynamic> json) {
    return LocalizedString(
      uz: json['uz'] as String? ?? '',
      ru: json['ru'] as String? ?? '',
      en: json['en'] as String? ?? '',
    );
  }
}
