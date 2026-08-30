import 'entities/project.dart';

/// W4.2 — canonical [ProjectRepository] contract, owned by the Projects domain.
///
/// Re-parented from `lib/features/tools/domain/checklist/project_repository.dart`.
/// The legacy Tools path exposes this same contract through a compatibility
/// re-export shim so existing implementers and consumers are unaffected.
abstract class ProjectRepository {
  Future<List<Project>> loadProjects();

  Future<Project> createProject(String name);

  Future<void> updateProject(Project project);

  Future<void> archiveProject(String projectId);

  /// Returns an archived project to the active list (isArchived -> false).
  ///
  /// No-op if the project does not exist or is not currently archived.
  Future<void> restoreProject(String projectId);

  Future<void> deleteProject(String projectId);

  /// Replaces the whole project list with the given projects (IDs preserved).
  ///
  /// Used by Backup / Restore to reproduce the persisted project records
  /// exactly, including original [Project.id] values.
  Future<void> replaceAll(List<Project> projects);
}
