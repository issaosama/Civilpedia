import 'entities/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> loadProjects();

  Future<Project> createProject(String name);

  Future<void> updateProject(Project project);

  Future<void> archiveProject(String projectId);

  Future<void> deleteProject(String projectId);

  /// Replaces the whole project list with the given projects (IDs preserved).
  ///
  /// Used by Backup / Restore to reproduce the persisted project records
  /// exactly, including original [Project.id] values.
  Future<void> replaceAll(List<Project> projects);
}
