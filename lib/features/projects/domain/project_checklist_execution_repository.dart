import 'entities/project_checklist_execution.dart';

/// W4.8 — canonical narrow [ProjectChecklistExecutionRepository], owned by the
/// Projects domain.
///
/// This is the single narrow interface across which the Tools checklist layer
/// records checklist executions for a project. Projects owns execution
/// identity, lifecycle timestamps, snapshot construction, serialization, and
/// the `checklist_executions_project_<id>` storage key. The Tools layer passes
/// only normalized item-state payloads plus the template identity/version
/// values it owns.
///
/// Inputs are deliberately seed-free: callers hand in flat `itemId → status`
/// and `itemId → notes` maps (exactly what the legacy `checklist_project_<id>`
/// sheet persists), so Projects never imports Tools presentation, seed data, or
/// localized checklist UI.
abstract class ProjectChecklistExecutionRepository {
  /// Loads the execution records for [projectId] (historical then active order
  /// preserved). Read is side-effect free.
  Future<List<ProjectChecklistExecution>> loadExecutions(String projectId);

  /// Legacy adoption (W4.8 migration), idempotent.
  ///
  /// When [projectId] already has persisted legacy item state
  /// ([statusesByItemId] non-empty) AND no execution record exists yet, creates
  /// exactly ONE legacy-normalized ACTIVE execution:
  ///   * [ProjectChecklistExecution.templateVersion] = `null`
  ///     (pre-versioning legacy state MUST NOT be assigned `'1'`)
  ///   * [ProjectChecklistExecution.startedAt] = `null`
  ///     (historical timestamps are never fabricated)
  ///   * snapshot = only the truthful legacy values supplied.
  ///
  /// Repeated adoption is a safe no-op (no duplicate migration executions).
  Future<void> adoptLegacyState({
    required String projectId,
    required String templateId,
    required Map<String, String> statusesByItemId,
    required Map<String, String?> notesByItemId,
  });

  /// Snapshots the current project checklist state into the execution record.
  ///
  /// If an ACTIVE execution exists (`completedAt == null`) it is updated in
  /// place — preserving its [ProjectChecklistExecution.executionId],
  /// [startedAt], and [templateVersion] (a legacy record keeps `null`). If no
  /// active execution exists, a NEW native execution is created with the
  /// supplied [templateVersion] and `startedAt = now`. Completed executions
  /// are never modified.
  Future<void> recordSnapshot({
    required String projectId,
    required String templateId,
    required String templateVersion,
    required Map<String, String> statusesByItemId,
    required Map<String, String?> notesByItemId,
  });

  /// Finalizes the ACTIVE execution for [projectId] by setting
  /// [ProjectChecklistExecution.completedAt] = [completedAt], making it
  /// immutable. A no-op when there is no active execution. Never creates a
  /// record.
  Future<void> finalizeActive({
    required String projectId,
    required DateTime completedAt,
  });
}
