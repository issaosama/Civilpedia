import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool get isArabic => true;
  Locale get locale => const Locale('ar');

  Future<void> setLocale(String languageCode) async {}
  Future<void> toggleLanguage() async {}
}
