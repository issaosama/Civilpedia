import 'dart:math';

import '../domain/entities/project_checklist_execution.dart';
import '../domain/project_checklist_execution_repository.dart';
import 'project_persistence_gateway.dart';

/// W4.8 — canonical Projects-owned local [ProjectChecklistExecutionRepository].
///
/// Persists [ProjectChecklistExecution] rows through the Projects
/// [ProjectPersistenceGateway] under `checklist_executions_project_<projectId>`.
/// Projects owns execution identity (`checklist_execution_<micros>_<rand>`),
/// lifecycle timestamps, snapshot construction, serialization, and immutability
/// of completed executions. Tools supplies only normalized item-state payloads
/// plus template identity/version values (never seed data).
class LocalProjectChecklistExecutionRepository
    implements ProjectChecklistExecutionRepository {
  final ProjectPersistenceGateway _gateway;

  LocalProjectChecklistExecutionRepository([ProjectPersistenceGateway? gateway])
      : _gateway = gateway ?? ProjectPersistenceGateway();

  @override
  Future<List<ProjectChecklistExecution>> loadExecutions(
      String projectId) {
    return _gateway.readProjectChecklistExecutions(projectId);
  }

  @override
  Future<void> adoptLegacyState({
    required String projectId,
    required String templateId,
    required Map<String, String> statusesByItemId,
    required Map<String, String?> notesByItemId,
  }) async {
    if (statusesByItemId.isEmpty) return;
    final existing = await _gateway.readProjectChecklistExecutions(projectId);
    if (existing.isNotEmpty) return;
    existing.add(
      ProjectChecklistExecution(
        executionId: _generateId(),
        projectId: projectId,
        templateId: templateId,
        templateVersion: null,
        executedItemSnapshot: _buildSnapshot(
          statusesByItemId,
          notesByItemId,
        ),
        startedAt: null,
        completedAt: null,
        result: null,
        notes: null,
      ),
    );
    await _gateway.writeProjectChecklistExecutions(projectId, existing);
  }

  @override
  Future<void> recordSnapshot({
    required String projectId,
    required String templateId,
    required String templateVersion,
    required Map<String, String> statusesByItemId,
    required Map<String, String?> notesByItemId,
  }) async {
    final existing = await _gateway.readProjectChecklistExecutions(projectId);
    final activeIndex = _lastActiveIndex(existing);
    if (activeIndex == null) {
      existing.add(
        ProjectChecklistExecution(
          executionId: _generateId(),
          projectId: projectId,
          templateId: templateId,
          templateVersion: templateVersion,
          executedItemSnapshot: _buildSnapshot(
            statusesByItemId,
            notesByItemId,
          ),
          startedAt: DateTime.now(),
          completedAt: null,
          result: null,
          notes: null,
        ),
      );
    } else {
      final active = existing[activeIndex];
      existing[activeIndex] = ProjectChecklistExecution(
        executionId: active.executionId,
        projectId: active.projectId,
        templateId: active.templateId,
        templateVersion: active.templateVersion,
        executedItemSnapshot:
            _buildSnapshot(statusesByItemId, notesByItemId),
        startedAt: active.startedAt,
        completedAt: null,
        result: active.result,
        notes: active.notes,
      );
    }
    await _gateway.writeProjectChecklistExecutions(projectId, existing);
  }

  @override
  Future<void> finalizeActive({
    required String projectId,
    required DateTime completedAt,
  }) async {
    final existing = await _gateway.readProjectChecklistExecutions(projectId);
    final activeIndex = _lastActiveIndex(existing);
    if (activeIndex == null) return;
    final active = existing[activeIndex];
    existing[activeIndex] = ProjectChecklistExecution(
      executionId: active.executionId,
      projectId: active.projectId,
      templateId: active.templateId,
      templateVersion: active.templateVersion,
      executedItemSnapshot: _deepCopySnapshot(active.executedItemSnapshot),
      startedAt: active.startedAt,
      completedAt: completedAt,
      result: active.result,
      notes: active.notes,
    );
    await _gateway.writeProjectChecklistExecutions(projectId, existing);
  }

  int? _lastActiveIndex(List<ProjectChecklistExecution> list) {
    for (var i = list.length - 1; i >= 0; i--) {
      if (list[i].completedAt == null) return i;
    }
    return null;
  }

  List<Map<String, Object?>> _buildSnapshot(
    Map<String, String> statuses,
    Map<String, String?> notes,
  ) {
    return statuses.entries.map((entry) {
      final itemNotes = notes[entry.key];
      return <String, Object?>{
        'itemId': entry.key,
        'status': entry.value,
        if (itemNotes != null) 'notes': itemNotes,
      };
    }).toList();
  }

  List<Map<String, Object?>> _deepCopySnapshot(
    List<Map<String, Object?>> snapshot,
  ) {
    return snapshot
        .map((m) => Map<String, Object?>.from(m))
        .toList();
  }

  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(9999);
    return 'checklist_execution_${timestamp}_$suffix';
  }
}
