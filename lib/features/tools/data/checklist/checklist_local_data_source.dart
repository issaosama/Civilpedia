import 'package:shared_preferences/shared_preferences.dart';

class ChecklistLocalDataSource {
  static const String _key = 'checklist_data';

  static String _projectKey(String projectId) => 'checklist_project_$projectId';

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

  Future<String?> readProjectChecklistData(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_projectKey(projectId));
  }

  Future<void> writeProjectChecklistData(String projectId, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_projectKey(projectId), data);
  }

  Future<void> clearProjectChecklistData(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_projectKey(projectId));
  }
}
