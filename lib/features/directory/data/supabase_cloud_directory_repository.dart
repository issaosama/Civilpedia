import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../domain/canonical_directory_entity.dart';
import '../domain/cloud_directory_repository.dart';
import 'directory_cloud_cache.dart';
import 'supabase_directory_read_gateway.dart';

/// V1-R05 — Production cloud-backed [CloudDirectoryRepository].
///
/// Cache-first UX semantics:
/// 1. loadCache() → render fast when a valid snapshot exists;
/// 2. refresh() → complete cloud read; on success atomically replace cache;
/// 3. cloud failure → last valid cache remains (never destroyed);
/// 4. authoritative empty refresh replaces the old snapshot;
/// 5. malformed cache fails safely and a cloud refresh is attempted.
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
    if (!_gateway.isAvailable) {
      return const DirectoryRefreshResult(
        status: DirectoryRefreshStatus.unavailable,
      );
    }
    try {
      final entities = await _gateway.loadAll();
      final refreshedAt = DateTime.now().toUtc();
      // Atomically replace the whole snapshot, INCLUDING an authoritative
      // empty result.
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: refreshedAt,
          entities: entities,
        ),
      );
      return DirectoryRefreshResult(
        status: DirectoryRefreshStatus.success,
        entities: entities,
        refreshedAt: refreshedAt,
      );
    } catch (_) {
      return const DirectoryRefreshResult(
        status: DirectoryRefreshStatus.failure,
      );
    }
  }

  @override
  Future<CanonicalDirectoryEntity?> loadByCanonicalId(String id) async {
    // Cache first.
    final cached = await readCache();
    final fromCache = cached?.byId(id);
    if (fromCache != null) return fromCache;

    // Then cloud.
    if (!_gateway.isAvailable) return null;
    return _gateway.loadById(id);
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