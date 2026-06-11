import 'package:shared_preferences/shared_preferences.dart';

class ChecklistLocalDataSource {
  static const String _key = 'checklist_data';

  Future<String?> readChecklistData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> writeChecklistData(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, data);
  }

  Future<void> clearChecklistData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
