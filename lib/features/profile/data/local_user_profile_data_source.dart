import 'package:shared_preferences/shared_preferences.dart';

class LocalUserProfileDataSource {
  static const _key = 'local_user_profile';

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
