import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../domain/canonical_directory_entity.dart';
import '../domain/cloud_directory_repository.dart';
import 'directory_cloud_cache.dart';
import 'supabase_directory_read_gateway.dart';

/// V1-R05 / V1-R09-P2-B1 — Production cloud-backed [CloudDirectoryRepository].
///
/// Cache-first UX semantics:
/// 1. loadCache() → render fast when a valid snapshot exists;
/// 2. refresh() → complete cloud read; on success atomically replace cache;
/// 3. cloud failure → last valid cache remains (never destroyed);
/// 4. authoritative empty refresh replaces the old snapshot;
/// 5. malformed cache fails safely and a cloud refresh is attempted;
/// 6. successful remote data is retained in memory even if cache persistence
///    fails (reported via [DirectoryRefreshResult.cachePersisted]).
///
/// Equivalent complete refreshes are coalesced through a single repository-owned
/// active Future.
///
/// Exposes NO mutation surface and never reads/writes legacy `sb_profiles`.
class SupabaseCloudDirectoryRepository implements CloudDirectoryRepository {
  SupabaseCloudDirectoryRepository({
    required SupabaseService service,
    SupabaseClient? client,
    SupabaseDirectoryReadGateway? gateway,
  }) : _gateway = gateway ??
            SupabaseDirectoryReadGateway(
              service: service,
              client: client,
            );

  final SupabaseDirectoryReadGateway _gateway;

  /// Single repository-owned active Future for equivalent complete refreshes.
  Future<DirectoryRefreshResult>? _activeRefresh;

  @override
  bool get isAvailable => _gateway.isAvailable;

  @override
  Future<DirectoryCachedData?> readCache() async {
    final snapshot = await DirectoryCloudCache.read();
    if (snapshot == null) return null;
    return DirectoryCachedData(
      entities: snapshot.entities,
      refreshedAt: snapshot.refreshedAt,
    );
  }

  @override
  Future<DirectoryRefreshResult> refresh() async {
    final active = _activeRefresh;
    if (active != null) return active;

    final future = _performRefresh();
    _activeRefresh = future;
    future.whenComplete(() {
      if (_activeRefresh == future) {
        _activeRefresh = null;
      }
    });
    return future;
  }

  Future<DirectoryRefreshResult> _performRefresh() async {
    final outcome = await _gateway.loadAll();
    switch (outcome) {
      case DirectoryListSuccess(:final entities, :final refreshedAt):
        return _persistAuthoritative(entities, refreshedAt);
      case DirectoryListEmpty(:final refreshedAt):
        return _persistAuthoritative(const [], refreshedAt);
      case DirectoryListFailure(:final kind):
        return DirectoryRefreshResult(status: _statusForKind(kind));
    }
  }

  Future<DirectoryRefreshResult> _persistAuthoritative(
    List<CanonicalDirectoryEntity> entities,
    DateTime refreshedAt,
  ) async {
    bool cachePersisted;
    try {
      cachePersisted = await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: refreshedAt,
          entities: entities,
        ),
      );
    } catch (_) {
      cachePersisted = false;
    }

    final status = entities.isEmpty
        ? DirectoryRefreshStatus.authoritativeEmpty
        : DirectoryRefreshStatus.success;

    return DirectoryRefreshResult(
      status: status,
      entities: entities,
      refreshedAt: refreshedAt,
      cachePersisted: cachePersisted,
    );
  }

  static DirectoryRefreshStatus _statusForKind(DirectoryReadFailureKind kind) {
    return switch (kind) {
      DirectoryReadFailureKind.network => DirectoryRefreshStatus.network,
      DirectoryReadFailureKind.timeout => DirectoryRefreshStatus.timeout,
      DirectoryReadFailureKind.serviceUnavailable =>
        DirectoryRefreshStatus.serviceUnavailable,
      DirectoryReadFailureKind.malformedResponse =>
        DirectoryRefreshStatus.malformedResponse,
      DirectoryReadFailureKind.unexpected => DirectoryRefreshStatus.unexpected,
      DirectoryReadFailureKind.offline => DirectoryRefreshStatus.network,
    };
  }

  @override
  Future<CanonicalDirectoryEntity?> loadByCanonicalId(String id) async {
    // P2-B1 compatibility: preserve the pre-B1 cache-first behavior for
    // unchanged detail/Saved callers until P2-B2 migrates them to
    // readCache() + refresh(). Invalid IDs are rejected locally first.
    if (id.isEmpty || !CanonicalDirectoryEntity.isValidUuid(id)) {
      return null;
    }

    final cached = await readCache();
    final fromCache = cached?.byId(id);
    if (fromCache != null) return fromCache;

    final outcome = await _gateway.loadById(id);
    return switch (outcome) {
      DirectoryEntitySuccess(:final entity) => entity,
      DirectoryEntityNotFound() => null,
      DirectoryEntityInvalidId() => null,
      DirectoryEntityFailure() => null,
    };
  }

  @override
  Future<DirectoryLoadResult> load() async {
    final cached = await DirectoryCloudCache.read();
    final cachedData = cached == null
        ? null
        : DirectoryCachedData(
            entities: cached.entities,
            refreshedAt: cached.refreshedAt,
          );

    final refreshResult = await refresh();

    if (refreshResult.succeeded) {
      if (refreshResult.entities.isEmpty) {
        return DirectoryLoadResult(
          state: DirectoryLoadState.empty,
          entities: const [],
          refreshedAt: refreshResult.refreshedAt,
        );
      }
      return DirectoryLoadResult(
        state: DirectoryLoadState.fresh,
        entities: refreshResult.entities,
        refreshedAt: refreshResult.refreshedAt,
      );
    }

    // Refresh failed/unavailable → fall back to last valid cache.
    if (cachedData != null) {
      return DirectoryLoadResult(
        state: DirectoryLoadState.stale,
        entities: cachedData.entities,
        refreshedAt: cachedData.refreshedAt,
      );
    }

    return const DirectoryLoadResult(state: DirectoryLoadState.error);
  }
}
