import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/app_storage_keys.dart';

class ChecklistLocalDataSource {
  static const _key = AppStorageKeys.checklistData;

  static String _projectKey(String projectId) =>
      AppStorageKeys.projectChecklist(projectId);

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
