import 'entities/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> loadProjects();

  Future<Project> createProject(String name);

  Future<void> updateProject(Project project);

  Future<void> archiveProject(String projectId);

  Future<void> deleteProject(String projectId);
}
