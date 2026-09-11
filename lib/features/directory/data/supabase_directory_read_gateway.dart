import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../domain/canonical_directory_entity.dart';

/// V1-R05 — PostgREST SELECT projection executed by the production cloud read
/// channel (see [SupabaseDirectoryReadQueryChannel]).
///
/// Schema-accurate vs the audited migrations:
/// * `directory_categories`/`regions` are bilingual — `name_ar`, `name_en`
///   (NOT a single `name` column);
/// * `entity_media` carries only schema-valid columns (`id`, `url`,
///   `media_type`) — there is NO `caption` column (migration 00006).
abstract interface class DirectoryReadQueryChannel {
  /// SELECTs all active public entities (+ relational children) ordered by
  /// name. PostgREST returns rows as JSON maps.
  Future<List<Map<String, dynamic>>> queryAllActive();

  /// SELECTs one active entity by canonical UUID (+ relational children).
  Future<List<Map<String, dynamic>>> queryActiveById(String id);
}

/// Production PostgREST query channel: the ONLY Supabase query executor for
/// the public Directory read seam. It is what [SupabaseDirectoryReadGateway]
/// uses at runtime; tests inject a fake channel to prove the query contract
/// behaviorally without a network.
class SupabaseDirectoryReadQueryChannel implements DirectoryReadQueryChannel {
  SupabaseDirectoryReadQueryChannel(this._client);

  final SupabaseClient _client;

  /// The single source of truth for the SELECT projection string.
  static const String readProjection = '''
    id, name, entity_type, description, lifecycle_status,
    verification_status, claim_status, created_at, updated_at,
    directory_entity_categories(
      directory_categories(id, code, name_ar, name_en)
    ),
    entity_locations(
      region_id, address, regions(id, code, name_ar, name_en)
    ),
    entity_contacts(id, contact_type, value),
    entity_media(id, url, media_type)
  ''';

  @override
  Future<List<Map<String, dynamic>>> queryAllActive() async {
    final rows = await _client
        .from('directory_entities')
        .select(readProjection)
        .order('name');
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> queryActiveById(String id) async {
    final rows = await _client
        .from('directory_entities')
        .select(readProjection)
        .eq('id', id)
        .limit(1);
    return rows;
  }
}

/// V1-R05 — Production read-only Supabase Directory data seam.
///
/// Unlike the V1-R04 CLAIM target gateway (authenticated + unclaimed-only),
/// the PUBLIC Directory gateway supports BOTH anon and authenticated reads
/// under existing public RLS. Authentication is never required for normal
/// Directory reads.
///
/// Seam contract (§9):
/// * PostgREST SELECT on `public.directory_entities` + children;
/// * both anon and authenticated sessions supported;
/// * only active lifecycle_status rows returned by RLS;
/// * NO new table, NO RPC, NO migration, NO mutation surface.
///
/// Follows the established gateway pattern (injected client, lazy resolution,
/// fail-closed parsing, `isAvailable` gating).
class SupabaseDirectoryReadGateway {
  SupabaseDirectoryReadGateway({
    required this.service,
    SupabaseClient? client,
    DirectoryReadQueryChannel? queryChannel,
  })  : _injectedClient = client,
        _queryChannel = queryChannel;

  final SupabaseService service;
  final SupabaseClient? _injectedClient;

  /// Test seam: when injected, query execution is intercepted (runtime
  /// semantics unchanged); when null the production
  /// [SupabaseDirectoryReadQueryChannel] runs the exact same statements.
  final DirectoryReadQueryChannel? _queryChannel;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  DirectoryReadQueryChannel get _queries {
    final injected = _queryChannel;
    if (injected != null) return injected;
    return SupabaseDirectoryReadQueryChannel(_client);
  }

  bool get isAvailable => service.isInitialized;

  /// Loads all active directory entities with their canonical child
  /// relationships.
  ///
  /// On network/query failure this THROWS so callers can distinguish a
  /// failure from an authoritative EMPTY result (empty cloud directory is a
  /// valid snapshot and must be able to replace stale cache; failures must
  /// preserve the last valid cache).
  Future<List<CanonicalDirectoryEntity>> loadAll() async {
    if (!isAvailable) {
      throw StateError('Directory read gateway is not available');
    }

    final rows = await _queries.queryAllActive();

    final entities = <CanonicalDirectoryEntity>[];
    for (final row in rows) {
      final parsed = _parseRow(row);
      if (parsed != null) entities.add(parsed);
    }
    return entities;
  }

  /// Loads a single active entity by canonical UUID.
  /// Returns null when not found, not visible under RLS, or malformed.
  Future<CanonicalDirectoryEntity?> loadById(String id) async {
    if (!isAvailable) return null;
    if (id.isEmpty || !CanonicalDirectoryEntity.isValidUuid(id)) return null;

    try {
      final rows = await _queries.queryActiveById(id);

      if (rows.isEmpty) return null;
      return _parseRow(rows.first);
    } catch (_) {
      return null;
    }
  }

  /// Fail-closed row parser with child relationship extraction.
  static CanonicalDirectoryEntity? _parseRow(Map<String, dynamic> row) {
    final categories = _parseCategories(row);
    final locations = _parseLocations(row);
    final contacts = _parseContacts(row);
    final media = _parseMedia(row);

    return CanonicalDirectoryEntity.tryFromRow(
      row,
      categories: categories,
      locations: locations,
      contacts: contacts,
      media: media,
    );
  }

  static List<CanonicalDirectoryCategory> _parseCategories(
    Map<String, dynamic> row,
  ) {
    final raw = row['directory_entity_categories'];
    if (raw is! List) return const [];
    final result = <CanonicalDirectoryCategory>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final cat = item['directory_categories'];
      if (cat is! Map) continue;
      final parsed = CanonicalDirectoryCategory.tryFromRow(
        Map<String, dynamic>.from(cat),
      );
      if (parsed != null) result.add(parsed);
    }
    return result;
  }

  static List<CanonicalDirectoryLocation> _parseLocations(
    Map<String, dynamic> row,
  ) {
    final raw = row['entity_locations'];
    if (raw is! List) return const [];
    final result = <CanonicalDirectoryLocation>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final region = item['regions'];
      final regionCode = region is Map ? region['code'] as String? : null;
      final regionNameAr = region is Map ? region['name_ar'] as String? : null;
      final regionNameEn = region is Map ? region['name_en'] as String? : null;
      final address = item['address'] as String?;
      if (regionCode != null && regionCode.isNotEmpty) {
        result.add(CanonicalDirectoryLocation(
          regionCode: regionCode,
          regionName: _displayName(regionNameEn, regionNameAr),
          regionNameAr: regionNameAr,
          regionNameEn: regionNameEn,
          address: address,
        ));
      }
    }
    return result;
  }

  static String? _displayName(String? preferred, String? fallback) {
    if (preferred != null && preferred.isNotEmpty) return preferred;
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  static List<CanonicalDirectoryContact> _parseContacts(
    Map<String, dynamic> row,
  ) {
    final raw = row['entity_contacts'];
    if (raw is! List) return const [];
    final result = <CanonicalDirectoryContact>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final parsed = CanonicalDirectoryContact.tryFromRow(
        Map<String, dynamic>.from(item),
      );
      if (parsed != null) result.add(parsed);
    }
    return result;
  }

  static List<CanonicalDirectoryMedia> _parseMedia(
    Map<String, dynamic> row,
  ) {
    final raw = row['entity_media'];
    if (raw is! List) return const [];
    final result = <CanonicalDirectoryMedia>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final url = item['url'];
      if (url is! String || url.isEmpty) continue;
      result.add(CanonicalDirectoryMedia(
        url: url,
        mediaType: item['media_type'] as String?,
      ));
    }
    return result;
  }
}
