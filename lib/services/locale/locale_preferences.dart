import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';

class LocalePreferences {
  LocalePreferences(this._prefs);

  final SharedPreferences _prefs;

  Future<String?> loadLocaleCode() async {
    return _prefs.getString(StorageKeys.localeCode);
  }

  Future<void> saveLocaleCode(String languageCode) async {
    await _prefs.setString(StorageKeys.localeCode, languageCode);
  }
}
