import 'canonical_directory_entity.dart';

/// V1-R05 — Canonical production Directory repository boundary.
///
/// READ-ONLY regarding public business entities. Responsibilities:
/// * load/list canonical entities (cache-first with cloud refresh);
/// * refresh from cloud;
/// * loadByCanonicalId;
/// * cache fallback.
///
/// Deliberately REMOVED from the production Directory contract:
/// save / delete / clearAll. Business-profile mutations belong V1-R06.
///
/// Search/filter stay a pure local query engine over returned canonical
/// models ([CanonicalDirectoryQueryEngine]).
abstract interface class CloudDirectoryRepository {
  /// Whether a cloud read gateway is available. False keeps behavior
  /// cache-only/empty rather than surfacing a fake authority.
  bool get isAvailable;

  /// Fast cache-first read. Returns the last valid cached data or null.
  Future<DirectoryCachedData?> readCache();

  /// Complete cloud refresh. On SUCCESS the cache is atomically replaced
  /// (an authoritative empty result also replaces the old snapshot). Never
  /// destroys the last valid cache on failure.
  Future<DirectoryRefreshResult> refresh();

  /// Resolves one canonical entity by canonical `directory_entities.id`
  /// from cache then cloud. Null when unknown/not visible/cached-unavailable.
  Future<CanonicalDirectoryEntity?> loadByCanonicalId(String id);

  /// Cache-first + cloud-refresh combined load. Renders the cache fast and
  /// returns the best known state ([DirectoryLoadState]).
  Future<DirectoryLoadResult> load();
}

/// Raw cached directory data exposed to consumers (domain-level value).
class DirectoryCachedData {
  const DirectoryCachedData({
    required this.entities,
    required this.refreshedAt,
  });

  final List<CanonicalDirectoryEntity> entities;
  final DateTime refreshedAt;

  CanonicalDirectoryEntity? byId(String id) {
    for (final entity in entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }
}

/// Outcome of one cloud refresh attempt.
class DirectoryRefreshResult {
  const DirectoryRefreshResult({
    required this.status,
    this.entities = const [],
    this.refreshedAt,
  });

  final DirectoryRefreshStatus status;

  /// Canonical entities — populated only on [DirectoryRefreshStatus.success].
  final List<CanonicalDirectoryEntity> entities;

  /// Capture time of the successful refresh; null on failure.
  final DateTime? refreshedAt;

  bool get succeeded => status == DirectoryRefreshStatus.success;
}

enum DirectoryRefreshStatus { success, failure, unavailable }

/// The presentation-relevant state of a Directory load.
class DirectoryLoadResult {
  const DirectoryLoadResult({
    required this.state,
    this.entities = const [],
    this.refreshedAt,
  });

  final DirectoryLoadState state;

  /// Canonical entities to render (empty in [DirectoryLoadState.error]).
  final List<CanonicalDirectoryEntity> entities;

  /// Time of the underlying snapshot/refresh when available.
  final DateTime? refreshedAt;
}

enum DirectoryLoadState {
  /// Authoritative cloud-refreshed dataset (may legitimately be empty).
  fresh,

  /// Last valid cache rendered because cloud refresh failed/unavailable.
  stale,

  /// Authoritative empty cloud directory.
  empty,

  /// Neither cache nor cloud produced data — production error.
  error,
}