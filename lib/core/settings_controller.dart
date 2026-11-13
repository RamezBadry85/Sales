import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists lightweight user preferences (language and theme mode).
class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs, this._locale, this._themeMode);

  static const String _localeKey = 'settings.locale';
  static const String _themeKey = 'settings.themeMode';

  final SharedPreferences _prefs;
  Locale _locale;
  ThemeMode _themeMode;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLocale = prefs.getString(_localeKey);
    final storedTheme = prefs.getString(_themeKey);

    final locale = storedLocale == 'en'
        ? const Locale('en')
        : const Locale('ar');
    final themeMode = switch (storedTheme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    return SettingsController._(prefs, locale, themeMode);
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = Locale(locale.languageCode);
    notifyListeners();
    await _prefs.setString(_localeKey, _locale.languageCode);
  }

  Future<void> toggleLanguage() => setLocale(
        _locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar'),
      );

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_themeKey, mode.name);
  }
}
