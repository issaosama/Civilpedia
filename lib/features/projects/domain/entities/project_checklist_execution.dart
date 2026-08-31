/// W4.8 — canonical [ProjectChecklistExecution] entity, owned by the Projects
/// domain.
///
/// A project-scoped record of one run of the checklist working sheet for a
/// project. Projects owns the entity, execution identity, lifecycle timestamps,
/// snapshot, and persistence. The Tools checklist layer drives it through a
/// narrow Projects-domain contract; the Tools layer supplies the template
/// identity/version contract values only.
///
/// Fields follow the W4.8 final contract:
///   * [executionId], [projectId], [templateId], optional [templateVersion]
///   * [executedItemSnapshot] — list of truthful `{itemId, status, notes?}`
///     rows, capturing exactly what the legacy `checklist_project_<id>` sheet
///     could provide (itemId + status + per-item notes only).
///   * optional [startedAt] / [completedAt] lifecycle timestamps
///   * optional [result] — always `null` in W4.8 (no overall result contract).
///   * optional [notes] — execution-level notes, always `null` in W4.8.
///
/// No [title], [authorId], [createdBy], [isDeleted], [isArchived],
/// [schemaVersion], or attachments field exists in W4.8.
///
/// Immutability: a completed execution ([completedAt] != null) MUST never be
/// mutated through normal autosave; a later reset/run creates a new record.
class ProjectChecklistExecution {
  final String executionId;
  final String projectId;
  final String templateId;
  final String? templateVersion;
  final List<Map<String, Object?>> executedItemSnapshot;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? result;
  final String? notes;

  const ProjectChecklistExecution({
    required this.executionId,
    required this.projectId,
    required this.templateId,
    required this.templateVersion,
    required this.executedItemSnapshot,
    this.startedAt,
    this.completedAt,
    this.result,
    this.notes,
  });
}
