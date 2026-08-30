import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/app_storage_keys.dart';
import '../../../projects/data/project_persistence_gateway.dart';

class ChecklistLocalDataSource {
  static const _key = AppStorageKeys.checklistData;

  final ProjectPersistenceGateway _projectGateway;

  ChecklistLocalDataSource([ProjectPersistenceGateway? projectGateway])
    : _projectGateway = projectGateway ?? ProjectPersistenceGateway();

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

  // Project-scoped methods delegate to the Projects-domain compatibility
  // boundary so `checklist_project_<id>` has a single persistence owner
  // (W4.1). The Tools-facing API below is preserved unchanged. Global
  // `checklist_data` (methods above) remains Tools-owned.
  Future<String?> readProjectChecklistData(String projectId) =>
      _projectGateway.readProjectChecklist(projectId);

  Future<void> writeProjectChecklistData(String projectId, String data) =>
      _projectGateway.writeProjectChecklist(projectId, data);

  Future<void> clearProjectChecklistData(String projectId) =>
      _projectGateway.clearProjectChecklist(projectId);
}
