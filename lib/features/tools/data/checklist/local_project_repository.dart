import 'dart:math';

import '../../domain/checklist/entities/project.dart';
import '../../domain/checklist/project_repository.dart';
import 'project_local_data_source.dart';

class LocalProjectRepository implements ProjectRepository {
  final ProjectLocalDataSource _dataSource;
  List<Project>? _cache;

  LocalProjectRepository(this._dataSource);

  @override
  Future<List<Project>> loadProjects() async {
    if (_cache != null) return _cache!;
    final rawList = await _dataSource.readProjects();
    _cache = rawList.map(_deserialize).where((p) => p != null).cast<Project>().toList();
    return _cache!;
  }

  @override
  Future<Project> createProject(String name) async {
    final trimmedName = name.trim();
    final finalName = trimmedName.isEmpty ? 'Untitled Project' : trimmedName;
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
    final rawList = _cache!.map(_serialize).toList();
    await _dataSource.writeProjects(rawList);
  }

  Map<String, dynamic> _serialize(Project project) => {
        'id': project.id,
        'name': project.name,
        'createdAt': project.createdAt.toIso8601String(),
        'updatedAt': project.updatedAt.toIso8601String(),
        'isArchived': project.isArchived,
      };

  Project? _deserialize(Map<String, dynamic> map) {
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
