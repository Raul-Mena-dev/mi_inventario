import 'package:flutter/material.dart';

import 'settings_service.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences._();

  static final AppPreferences instance = AppPreferences._();

  String languageCode = 'es';
  String themeKey = 'classic';

  Locale get locale => Locale(languageCode);

  Future<void> load() async {
    languageCode = await SettingsService.getLanguageCode();
    themeKey = await SettingsService.getThemeKey();
  }

  Future<void> setLanguage(String code) async {
    languageCode = code;
    await SettingsService.saveLanguageCode(code);
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    themeKey = theme;
    await SettingsService.saveThemeKey(theme);
    notifyListeners();
  }
}
