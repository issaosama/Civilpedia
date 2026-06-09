import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/logger_service.dart';

class PreferencesHelper {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isDarkMode => _prefs.getBool(AppConstants.themeKey) ?? false;

  static Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(AppConstants.themeKey, value);
    LoggerService.info('Dark mode set to: $value');
  }

  static bool get isOnboardingSeen =>
      _prefs.getBool(AppConstants.onboardingKey) ?? false;

  static Future<void> setOnboardingSeen() async {
    await _prefs.setBool(AppConstants.onboardingKey, true);
  }
}
