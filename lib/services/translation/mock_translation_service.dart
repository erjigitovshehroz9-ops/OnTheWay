import '../../models/localized_string.dart';
import 'translation_service.dart';

class MockTranslationService implements TranslationService {
  @override
  Future<LocalizedString> localizeUserText({
    required String text,
    required String sourceLanguageCode,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const LocalizedString(uz: '', ru: '', en: '');
    }

    switch (sourceLanguageCode) {
      case 'uz':
        return LocalizedString(
          uz: trimmed,
          ru: await translateToRu(trimmed, sourceLanguageCode: 'uz'),
          en: await translateToEn(trimmed, sourceLanguageCode: 'uz'),
        );
      case 'ru':
        final ru = trimmed;
        final uz = await _pseudoBackTranslate(ru, target: 'uz');
        final en = await translateToEn(ru, sourceLanguageCode: 'ru');
        return LocalizedString(uz: uz, ru: ru, en: en);
      case 'en':
        final en = trimmed;
        final uz = await _pseudoBackTranslate(en, target: 'uz');
        final ru = await translateToRu(en, sourceLanguageCode: 'en');
        return LocalizedString(uz: uz, ru: ru, en: en);
      default:
        return LocalizedString(
          uz: trimmed,
          ru: '[ru] $trimmed',
          en: '[en] $trimmed',
        );
    }
  }

  @override
  Future<String> translateToRu(String text, {String? sourceLanguageCode}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (text.isEmpty) return '';
    return '[RU] $text';
  }

  @override
  Future<String> translateToEn(String text, {String? sourceLanguageCode}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (text.isEmpty) return '';
    return '[EN] $text';
  }

  Future<String> _pseudoBackTranslate(String text, {required String target}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (text.isEmpty) return '';
    final prefix = target == 'uz' ? '[UZ]' : '[??]';
    return '$prefix $text';
  }
}
