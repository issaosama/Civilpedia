import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/logger_service.dart';
import '../../core/storage/app_storage_keys.dart';

class PreferencesHelper {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isDarkMode => _prefs.getBool(AppStorageKeys.isDarkMode) ?? false;

  static Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(AppStorageKeys.isDarkMode, value);
    LoggerService.info('Dark mode set to: $value');
  }

  static bool get isOnboardingSeen =>
      _prefs.getBool(AppStorageKeys.onboardingSeen) ?? false;

  static Future<void> setOnboardingSeen() async {
    await _prefs.setBool(AppStorageKeys.onboardingSeen, true);
  }
}
