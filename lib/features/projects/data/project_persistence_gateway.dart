import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/app_storage_keys.dart';
import '../domain/entities/project.dart';
import '../domain/entities/project_calculation_record.dart';

/// W4.1 — Projects-domain persistence compatibility boundary.
///
/// This is the single low-level persistence access point for the two approved
/// Project key families:
///   * [AppStorageKeys.projectsList]
///   * [AppStorageKeys.projectChecklist] (`checklist_project_<id>`)
///
/// The persisted identities and their stored representations are byte-identical
/// to the legacy Tools-owned data sources. It is the only implementation of
/// the project-record ↔ [Project] (de)serialization contract, so the legacy
/// Tools path (which delegates here through the `ProjectLocalDataSource`
/// facade, `LocalProjectRepository`, and `ChecklistLocalDataSource`) and the
/// new Projects-domain path can never drift apart.
///
/// It is deliberately NOT a repository: the canonical `Project` entity and
/// `ProjectRepository` contract now live in the Projects domain (W4.2), and
/// this boundary only performs low-level persistence. Global checklist
/// persistence (`checklist_data`) remains Tools-owned and is never touched
/// here.
class ProjectPersistenceGateway {
  /// Reads the persisted project list. Read is side-effect free: it never
  /// rewrites, reorders, or re-times stored records. Malformed entries are
  /// skipped exactly as the legacy path did.
  Future<List<Project>> readProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppStorageKeys.projectsList);
    if (json == null) return [];
    final decoded = jsonDecode(json);
    if (decoded is! List) return [];
    return decoded
        .cast<Map<String, dynamic>>()
        .map(_fromMap)
        .where((p) => p != null)
        .cast<Project>()
        .toList();
  }

  /// Writes the whole project list to `projects_list` using the exact legacy
  /// representation (field names, ordering, ISO timestamps, archived flag).
  Future<void> writeProjects(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppStorageKeys.projectsList,
      jsonEncode(projects.map(_toMap).toList()),
    );
  }

  /// Removes the whole `projects_list` record. Kept for the legacy
  /// [ProjectLocalDataSource] facade so its public API surface is preserved.
  Future<void> clearProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppStorageKeys.projectsList);
  }

  /// Reads the raw per-project checklist JSON for a project, exactly as stored.
  Future<String?> readProjectChecklist(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppStorageKeys.projectChecklist(projectId));
  }

  /// Writes the per-project checklist JSON verbatim to the exact legacy key,
  /// so Tools-side decoding of `checklist_project_<id>` is unaffected.
  Future<void> writeProjectChecklist(String projectId, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppStorageKeys.projectChecklist(projectId), data);
  }

  Future<void> clearProjectChecklist(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppStorageKeys.projectChecklist(projectId));
  }

  /// Reads the persisted calculation records for [projectId]. Returns an empty
  /// list when the project has no saved records. Read is side-effect free.
  Future<List<ProjectCalculationRecord>> readProjectCalculations(
      String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(AppStorageKeys.projectCalculations(projectId));
    if (json == null) return [];
    final decoded = jsonDecode(json);
    if (decoded is! List) return [];
    return decoded
        .cast<Map<String, dynamic>>()
        .map(_calcFromMap)
        .where((r) => r != null)
        .cast<ProjectCalculationRecord>()
        .toList();
  }

  /// Writes the whole calculation list for [projectId] to
  /// `calculations_project_<projectId>`.
  Future<void> writeProjectCalculations(
      String projectId, List<ProjectCalculationRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppStorageKeys.projectCalculations(projectId),
      jsonEncode(records.map(_calcToMap).toList()),
    );
  }

  Map<String, dynamic> _calcToMap(ProjectCalculationRecord record) => {
        'id': record.id,
        'projectId': record.projectId,
        'calculatorId': record.calculatorId,
        'calculatorVersion': record.calculatorVersion,
        if (record.title != null) 'title': record.title,
        'inputSnapshot': record.inputSnapshot,
        'outputSnapshot': record.outputSnapshot,
        'createdAt': record.createdAt.toIso8601String(),
      };

  ProjectCalculationRecord? _calcFromMap(Map<String, dynamic> map) {
    try {
      return ProjectCalculationRecord(
        id: map['id'] as String,
        projectId: map['projectId'] as String,
        calculatorId: map['calculatorId'] as String,
        calculatorVersion: map['calculatorVersion'] as String,
        title: map['title'] as String?,
        inputSnapshot: (map['inputSnapshot'] as Map).cast<String, Object?>(),
        outputSnapshot: (map['outputSnapshot'] as Map).cast<String, Object?>(),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toMap(Project project) => {
    'id': project.id,
    'name': project.name,
    'createdAt': project.createdAt.toIso8601String(),
    'updatedAt': project.updatedAt.toIso8601String(),
    'isArchived': project.isArchived,
  };

  Project? _fromMap(Map<String, dynamic> map) {
    try {
      return Project(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        isArchived: map['isArchived'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}
