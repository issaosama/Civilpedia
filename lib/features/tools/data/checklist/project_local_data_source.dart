import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProjectLocalDataSource {
  static const String _key = 'projects_list';

  Future<List<Map<String, dynamic>>> readProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final decoded = jsonDecode(json);
    if (decoded is! List) return [];
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> writeProjects(List<Map<String, dynamic>> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(projects);
    await prefs.setString(_key, json);
  }

  Future<void> clearProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
