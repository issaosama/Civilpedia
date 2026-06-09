import 'package:flutter/material.dart';
import '../../data/local/preferences_helper.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void loadTheme() {
    _themeMode = PreferencesHelper.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    PreferencesHelper.setDarkMode(isDarkMode);
    notifyListeners();
  }
}
