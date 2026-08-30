import 'dart:math';

import '../domain/entities/project.dart';
import '../domain/project_name_policy.dart';
import '../domain/project_repository.dart';
import 'project_local_data_source.dart';

/// W4.2 — canonical [LocalProjectRepository], owned by the Projects data layer.
///
/// Re-parented from `lib/features/tools/data/checklist/local_project_repository.dart`.
///
/// The Tools feature exposes this exact class through a compatibility re-export
/// shim, so existing Tools consumers (DI wiring, UI screens, backup, tests)
/// keep their original imports and constructor wiring:
///
/// ```text
/// LocalProjectRepository → ProjectLocalDataSource → ProjectPersistenceGateway
/// ```
///
/// Persistence access is delegated through the canonical Projects-owned
/// [ProjectLocalDataSource], which in turn delegates to the single
/// Projects-domain `ProjectPersistenceGateway`. This preserves the exact legacy
/// CRUD behavior, caching, ID generation, and byte-identical serialization.
class LocalProjectRepository implements ProjectRepository {
  final ProjectLocalDataSource _dataSource;
  List<Project>? _cache;

  LocalProjectRepository(this._dataSource);

  @override
  Future<List<Project>> loadProjects() async {
    if (_cache != null) return _cache!;
    _cache = await _dataSource.readProjects();
    return _cache!;
  }

  @override
  Future<Project> createProject(String name) async {
    final finalName = ProjectNamePolicy.createName(name);
    final now = DateTime.now();
    final project = Project(
      id: _generateId(),
      name: finalName,
      createdAt: now,
      updatedAt: now,
    );
    await _ensureCache();
    _cache!.add(project);
    await _flush();
    return project;
  }

  @override
  Future<void> updateProject(Project project) async {
    await _ensureCache();
    final index = _cache!.indexWhere((p) => p.id == project.id);
    if (index == -1) return;
    _cache![index] = project.copyWith(updatedAt: DateTime.now());
    await _flush();
  }

  @override
  Future<void> archiveProject(String projectId) async {
    await _ensureCache();
    final index = _cache!.indexWhere((p) => p.id == projectId);
    if (index == -1) return;
    _cache![index] = _cache![index].copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );
    await _flush();
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await _ensureCache();
    _cache!.removeWhere((p) => p.id == projectId);
    await _flush();
  }

  @override
  Future<void> replaceAll(List<Project> projects) async {
    _cache = List.of(projects);
    await _flush();
  }

  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(9999);
    return 'project_${timestamp}_$suffix';
  }

  Future<void> _ensureCache() async {
    if (_cache != null) return;
    await loadProjects();
  }

  Future<void> _flush() async {
    await _dataSource.writeProjects(_cache!);
  }
}
