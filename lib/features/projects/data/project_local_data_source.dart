import '../domain/entities/project.dart';
import 'project_persistence_gateway.dart';

/// W4.2 — canonical [ProjectLocalDataSource], owned by the Projects data layer.
///
/// It is the single real implementation of the legacy project data-source
/// surface ([readProjects], [writeProjects], [clearProjects], no-arg
/// constructibility). It delegates ALL persistence to the Projects-domain
/// [ProjectPersistenceGateway], so persistence and serialization have exactly
/// one owner:
///
/// ```text
/// LocalProjectRepository → ProjectLocalDataSource → ProjectPersistenceGateway
/// ```
///
/// The legacy Tools path
/// (`lib/features/tools/data/checklist/project_local_data_source.dart`) is a
/// compatibility re-export of this class, so existing Tools consumers keep
/// their original wiring with no changes and no duplicated logic.
class ProjectLocalDataSource {
  final ProjectPersistenceGateway _gateway;

  ProjectLocalDataSource([ProjectPersistenceGateway? gateway])
    : _gateway = gateway ?? ProjectPersistenceGateway();

  Future<List<Project>> readProjects() => _gateway.readProjects();

  Future<void> writeProjects(List<Project> projects) =>
      _gateway.writeProjects(projects);

  Future<void> clearProjects() => _gateway.clearProjects();
}
