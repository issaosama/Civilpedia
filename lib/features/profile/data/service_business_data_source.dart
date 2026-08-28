import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/app_storage_keys.dart';

class ServiceBusinessDataSource {
  static const _key = AppStorageKeys.sbProfiles;

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> write(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
