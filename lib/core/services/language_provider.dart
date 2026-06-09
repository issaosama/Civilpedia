import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  static const String _key = 'app_language';

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'ar';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'ar') {
      await setLocale('en');
    } else {
      await setLocale('ar');
    }
  }
}
