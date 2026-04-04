import '../../models/localized_string.dart';

abstract class TranslationService {
  Future<LocalizedString> localizeUserText({
    required String text,
    required String sourceLanguageCode,
  });

  Future<String> translateToRu(String text, {String? sourceLanguageCode});

  Future<String> translateToEn(String text, {String? sourceLanguageCode});
}
