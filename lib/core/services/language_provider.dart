import 'package:flutter/material.dart';

/// App locale provider.
///
/// V1-R08 correction (finding 2) — the provider now actually holds the active
/// language so every `tr(ar, en)` call site can render English when selected.
/// Arabic remains the default; no persistence channel was added (the previous
/// stub never persisted either).
class LanguageProvider extends ChangeNotifier {
  LanguageProvider({bool isArabic = true}) : _isArabic = isArabic;

  bool _isArabic;

  bool get isArabic => _isArabic;

  Locale get locale => Locale(_isArabic ? 'ar' : 'en');

  Future<void> setLocale(String languageCode) async {
    final next = languageCode == 'ar';
    if (next == _isArabic) return;
    _isArabic = next;
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    await setLocale(_isArabic ? 'en' : 'ar');
  }
}