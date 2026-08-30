import '../../../projects/data/project_persistence_gateway.dart';
import '../../domain/checklist/entities/project.dart';

/// Legacy Tools compatibility facade (W4.1).
///
/// Keeps the legacy Tools data-source identity and its public API
/// ([readProjects], [writeProjects], [clearProjects], no-arg constructibility)
/// so existing Tools consumers keep their original wiring, while ALL
/// persistence access is delegated to the Projects-domain
/// [ProjectPersistenceGateway].
///
/// The legacy implementation previously owned the `projects_list` key and the
/// Project JSON (de)serialization. Both now belong exclusively to
/// [ProjectPersistenceGateway], so there is exactly one persistence and one
/// serialization contract in the codebase:
///
/// ```text
/// LocalProjectRepository → ProjectLocalDataSource → ProjectPersistenceGateway
/// ```
class ProjectLocalDataSource {
  final ProjectPersistenceGateway _gateway;

  ProjectLocalDataSource([ProjectPersistenceGateway? gateway])
    : _gateway = gateway ?? ProjectPersistenceGateway();

  Future<List<Project>> readProjects() => _gateway.readProjects();

  Future<void> writeProjects(List<Project> projects) =>
      _gateway.writeProjects(projects);

  Future<void> clearProjects() => _gateway.clearProjects();
}
