import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/app_storage_keys.dart';
import '../domain/canonical_directory_entity.dart';

/// V1-R05 — Dedicated versioned Directory cloud cache.
///
/// A single SharedPreferences snapshot keyed by [AppStorageKeys.directoryCloudCache]
/// — clearly separate from the legacy `sb_profiles` key. The cache is ONLY a
/// stale offline snapshot: cloud is authoritative, and no cache path exposes
/// mutation of public entities or their claim/verification state.
///
/// Cache authority rules (§15):
/// * successful complete cloud refresh → atomically replace snapshot;
/// * network failure → may use last valid snapshot (handled by repository);
/// * malformed cache → fails safely and the repository attempts cloud refresh;
/// * failed/partial refresh never destroys the last valid cache (callers only
///   call [writeSnapshot] after a successful complete refresh);
/// * an authoritative EMPTY cloud refresh replaces the old snapshot (empty is
///   a valid snapshot);
/// * [SharedPreferences.setString] returning `false` or throwing is a
///   persistence failure and is reported to callers.
abstract final class DirectoryCloudCache {
  /// Bumped when the persisted snapshot shape changes.
  static const int cacheVersion = 1;

  static final DirectoryCloudCacheStore _defaultStore =
      _SharedPreferencesCacheStore();

  /// Narrow test seam for deterministic cache-store behavior. Production code
  /// never sets this; [_defaultStore] is used normally.
  static DirectoryCloudCacheStore? _testStore;

  @visibleForTesting
  static void setTestStore(DirectoryCloudCacheStore? store) {
    _testStore = store;
  }

  static DirectoryCloudCacheStore get _store => _testStore ?? _defaultStore;

  static Future<DirectoryCloudCacheSnapshot?> read() async {
    try {
      final raw = await _store.readString(AppStorageKeys.directoryCloudCache);
      if (raw == null || raw.isEmpty) return null;
      return DirectoryCloudCacheSnapshot.tryDecode(raw);
    } catch (_) {
      // Fail safely: malformed cache reads produce no snapshot.
      return null;
    }
  }

  /// Atomically replaces the whole snapshot. [snapshot] must be a complete,
  /// successfully-refreshed snapshot — callers never persist partial data.
  ///
  /// Returns `true` when [SharedPreferences.setString] reports success,
  /// `false` when it reports failure or throws.
  static Future<bool> writeSnapshot(DirectoryCloudCacheSnapshot snapshot) async {
    try {
      return await _store.writeString(
        AppStorageKeys.directoryCloudCache,
        snapshot.encode(),
      );
    } catch (_) {
      return false;
    }
  }
}

/// Internal cache-store seam. Production uses [SharedPreferences]; tests may
/// inject deterministic implementations without creating a second cache.
///
/// Public so external tests can inject narrow fakes; it is not a second cache.
abstract interface class DirectoryCloudCacheStore {
  Future<String?> readString(String key);
  Future<bool> writeString(String key, String value);
}

class _SharedPreferencesCacheStore implements DirectoryCloudCacheStore {
  @override
  Future<String?> readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<bool> writeString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }
}

/// Immutable, versioned, single-snapshot cache payload.
class DirectoryCloudCacheSnapshot {
  const DirectoryCloudCacheSnapshot({
    required this.version,
    required this.refreshedAt,
    required this.entities,
  });

  final int version;

  /// UTC ISO-8601 capture time of the successful cloud refresh.
  final DateTime refreshedAt;

  /// Canonical entities keyed by `directory_entities.id`. Preserves
  /// deterministic (name) order for list rendering.
  final List<CanonicalDirectoryEntity> entities;

  /// Lookup by canonical UUID.
  CanonicalDirectoryEntity? byId(String id) {
    for (final entity in entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }

  String encode() => jsonEncode({
    'schema_version': version,
    'refreshed_at': refreshedAt.toUtc().toIso8601String(),
    'entities': entities.map((e) => e.toJson()).toList(),
  });

  /// Fail-closed decode. Returns null for missing/unknown/malformed shapes.
  ///
  /// Snapshot integrity rule: if ANY entity row fails closed parsing, the
  /// WHOLE snapshot is rejected instead of silently dropping the authoritative
  /// row — a snapshot that can no longer be rendered completely is not a valid
  /// cache, and the repository attempts a fresh cloud refresh instead.
  static DirectoryCloudCacheSnapshot? tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final version = decoded['schema_version'];
      if (version is! int || version != DirectoryCloudCache.cacheVersion) {
        return null;
      }
      final refreshedAtRaw = decoded['refreshed_at'];
      if (refreshedAtRaw is! String) return null;
      final refreshedAt = DateTime.tryParse(refreshedAtRaw);
      if (refreshedAt == null) return null;

      final entitiesRaw = decoded['entities'];
      if (entitiesRaw is! List) return null;

      final entities = <CanonicalDirectoryEntity>[];
      for (final item in entitiesRaw) {
        if (item is! Map) return null;
        final parsed = CanonicalDirectoryEntity.tryFromJson(
          Map<String, dynamic>.from(item),
        );
        if (parsed == null) return null;
        entities.add(parsed);
      }
      return DirectoryCloudCacheSnapshot(
        version: version,
        refreshedAt: refreshedAt,
        entities: entities,
      );
    } catch (_) {
      return null;
    }
  }
}