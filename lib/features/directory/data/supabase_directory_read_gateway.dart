import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../../../core/network/remote_operation_policy.dart';
import '../domain/canonical_directory_entity.dart';
import '../domain/cloud_directory_repository.dart';

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
      region_id, address, regions(id, code, name_ar, name_en), is_primary
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
/// fail-closed parsing, `isAvailable` gating). All remote reads are bounded by
/// [RemoteOperationPolicy.read] (15 seconds) and return typed outcomes; raw
/// exceptions are never surfaced past this boundary.
class SupabaseDirectoryReadGateway {
  SupabaseDirectoryReadGateway({
    required this.service,
    SupabaseClient? client,
    DirectoryReadQueryChannel? queryChannel,
    this.readTimeout = RemoteOperationPolicy.read,
  })  : _injectedClient = client,
        _queryChannel = queryChannel;

  final SupabaseService service;
  final SupabaseClient? _injectedClient;

  /// Test seam: when injected, query execution is intercepted (runtime
  /// semantics unchanged); when null the production
  /// [SupabaseDirectoryReadQueryChannel] runs the exact same statements.
  final DirectoryReadQueryChannel? _queryChannel;

  /// Application-owned read deadline. Production uses
  /// [RemoteOperationPolicy.read]; tests may inject a shorter duration.
  final Duration readTimeout;

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
  /// The complete snapshot is validated strictly: a single malformed entity
  /// row, relationship row, or required nested child structure causes the
  /// whole result to fail as [DirectoryReadFailureKind.malformedResponse].
  /// Authoritative empty is returned as [DirectoryListEmpty].
  Future<DirectoryListOutcome> loadAll() async {
    if (!isAvailable) {
      return const DirectoryListFailure(
        DirectoryReadFailureKind.serviceUnavailable,
      );
    }

    try {
      final rows = await runWithRemoteDeadline(
        _queries.queryAllActive(),
        timeout: readTimeout,
      );

      final entities = <CanonicalDirectoryEntity>[];
      for (final row in rows) {
        final parsed = _parseRow(row);
        if (parsed == null) {
          return const DirectoryListFailure(
            DirectoryReadFailureKind.malformedResponse,
          );
        }
        entities.add(parsed);
      }

      final refreshedAt = DateTime.now().toUtc();
      if (entities.isEmpty) {
        return DirectoryListEmpty(refreshedAt);
      }
      return DirectoryListSuccess(entities, refreshedAt);
    } catch (e) {
      return DirectoryListFailure(_classifyError(e));
    }
  }

  /// Loads a single active entity by canonical UUID.
  ///
  /// Returns [DirectoryEntityInvalidId] without a backend call when [id] is
  /// not a valid canonical UUID. Malformed responses are distinct from
  /// authoritative absence.
  Future<DirectoryEntityOutcome> loadById(String id) async {
    // Canonical ID validation is local and MUST run before any availability
    // or network logic so an invalid ID never depends on backend state.
    if (id.isEmpty || !CanonicalDirectoryEntity.isValidUuid(id)) {
      return const DirectoryEntityInvalidId();
    }

    if (!isAvailable) {
      return const DirectoryEntityFailure(
        DirectoryReadFailureKind.serviceUnavailable,
      );
    }

    try {
      final rows = await runWithRemoteDeadline(
        _queries.queryActiveById(id),
        timeout: readTimeout,
      );

      if (rows.isEmpty) return const DirectoryEntityNotFound();

      final parsed = _parseRow(rows.first);
      if (parsed == null) {
        return const DirectoryEntityFailure(
          DirectoryReadFailureKind.malformedResponse,
        );
      }
      return DirectoryEntitySuccess(parsed);
    } catch (e) {
      return DirectoryEntityFailure(_classifyError(e));
    }
  }

  /// Fail-closed row parser with child relationship extraction.
  ///
  /// Returns null when the entity or any required nested child is malformed.
  /// A null return is converted to [DirectoryReadFailureKind.malformedResponse]
  /// by the public load methods so the failure is never silently dropped.
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
    if (raw == null) {
      throw const FormatException('directory_entity_categories missing');
    }
    if (raw is! List) throw const FormatException('categories not a list');
    final result = <CanonicalDirectoryCategory>[];
    for (final item in raw) {
      if (item is! Map) throw const FormatException('category item not a map');
      final cat = item['directory_categories'];
      if (cat is! Map) {
        throw const FormatException('directory_categories missing');
      }
      final parsed = CanonicalDirectoryCategory.tryFromRow(
        Map<String, dynamic>.from(cat),
      );
      if (parsed == null) {
        throw const FormatException('directory_categories malformed');
      }
      result.add(parsed);
    }
    return result;
  }

  static List<CanonicalDirectoryLocation> _parseLocations(
    Map<String, dynamic> row,
  ) {
    final raw = row['entity_locations'];
    if (raw == null) throw const FormatException('entity_locations missing');
    if (raw is! List) throw const FormatException('locations not a list');
    final result = <CanonicalDirectoryLocation>[];
    for (final item in raw) {
      if (item is! Map) throw const FormatException('location item not a map');
      final region = item['regions'];
      if (region != null && region is! Map) {
        throw const FormatException('regions malformed');
      }
      final regionCodeRaw = region is Map ? region['code'] : null;
      if (regionCodeRaw != null && regionCodeRaw is! String) {
        throw const FormatException('region code malformed');
      }
      final regionNameArRaw = region is Map ? region['name_ar'] : null;
      if (regionNameArRaw != null && regionNameArRaw is! String) {
        throw const FormatException('region name_ar malformed');
      }
      final regionNameEnRaw = region is Map ? region['name_en'] : null;
      if (regionNameEnRaw != null && regionNameEnRaw is! String) {
        throw const FormatException('region name_en malformed');
      }
      final addressRaw = item['address'];
      if (addressRaw != null && addressRaw is! String) {
        throw const FormatException('location address malformed');
      }
      final isPrimaryRaw = item['is_primary'];
      if (isPrimaryRaw is! bool) {
        throw const FormatException('is_primary malformed');
      }
      final regionCode = regionCodeRaw as String?;
      final regionNameAr = regionNameArRaw as String?;
      final regionNameEn = regionNameEnRaw as String?;
      final address = addressRaw as String?;
      final isPrimary = isPrimaryRaw;
      if ((regionCode == null || regionCode.isEmpty) &&
          (address == null || address.isEmpty)) {
        throw const FormatException('location missing region and address');
      }
      result.add(
        CanonicalDirectoryLocation(
          regionCode: regionCode ?? '',
          regionName: _displayName(regionNameEn, regionNameAr),
          regionNameAr: regionNameAr,
          regionNameEn: regionNameEn,
          address: address,
          isPrimary: isPrimary,
        ),
      );
    }
    // V1-R06 compatibility: public presentation consumes the first location,
    // so put the database-authoritative primary row first deterministically.
    return [
      ...result.where((location) => location.isPrimary),
      ...result.where((location) => !location.isPrimary),
    ];
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
    if (raw == null) throw const FormatException('entity_contacts missing');
    if (raw is! List) throw const FormatException('contacts not a list');
    final result = <CanonicalDirectoryContact>[];
    for (final item in raw) {
      if (item is! Map) throw const FormatException('contact item not a map');
      final parsed = CanonicalDirectoryContact.tryFromRow(
        Map<String, dynamic>.from(item),
      );
      if (parsed == null) throw const FormatException('contact malformed');
      result.add(parsed);
    }
    return result;
  }

  static List<CanonicalDirectoryMedia> _parseMedia(
    Map<String, dynamic> row,
  ) {
    final raw = row['entity_media'];
    if (raw == null) throw const FormatException('entity_media missing');
    if (raw is! List) throw const FormatException('media not a list');
    final result = <CanonicalDirectoryMedia>[];
    for (final item in raw) {
      if (item is! Map) throw const FormatException('media item not a map');
      final url = item['url'];
      if (url is! String || url.isEmpty) {
        throw const FormatException('media url missing');
      }
      final mediaTypeRaw = item['media_type'];
      if (mediaTypeRaw != null && mediaTypeRaw is! String) {
        throw const FormatException('media type malformed');
      }
      result.add(CanonicalDirectoryMedia(
        url: url,
        mediaType: mediaTypeRaw as String?,
      ));
    }
    return result;
  }

  static DirectoryReadFailureKind _classifyError(Object error) {
    if (error is InfrastructureFailureException) {
      // The data layer never asserts device transport state; an offline kind
      // from the infrastructure helper can only mean a transport request
      // failure, so it is mapped to network.
      final kind = error.failure.kind;
      return switch (kind) {
        InfrastructureFailureKind.offline => DirectoryReadFailureKind.network,
        InfrastructureFailureKind.network => DirectoryReadFailureKind.network,
        InfrastructureFailureKind.timeout => DirectoryReadFailureKind.timeout,
        InfrastructureFailureKind.serviceUnavailable =>
          DirectoryReadFailureKind.serviceUnavailable,
        InfrastructureFailureKind.malformedResponse =>
          DirectoryReadFailureKind.malformedResponse,
        InfrastructureFailureKind.unknown => DirectoryReadFailureKind.unexpected,
      };
    }
    if (error is TimeoutException) {
      return DirectoryReadFailureKind.timeout;
    }
    if (error is FormatException) {
      return DirectoryReadFailureKind.malformedResponse;
    }
    if (error is SocketException ||
        error is HandshakeException ||
        error is HttpException ||
        error is http.ClientException) {
      return DirectoryReadFailureKind.network;
    }
    if (error is PostgrestException) {
      // serviceUnavailable is reserved for clearly recognized temporary
      // backend/service availability failures. PostgrestException.code is the
      // Postgres/PostgREST error code, NOT the HTTP status code, so HTTP 503
      // must not be used as the classifier.
      //
      // Recognized temporary conditions:
      //   * PostgreSQL connection exception class ('08xxx')
      //   * PostgreSQL insufficient-resources class ('53xxx')
      //   * PostgREST database-connection/service availability family
      //     (PGRST000..PGRST003)
      //
      // Permission, auth, schema, semantic, query, and unknown PostgREST
      // failures remain unexpected. No backend error text is surfaced.
      final code = error.code ?? '';
      if (_isPostgrestTemporaryServiceFailure(code)) {
        return DirectoryReadFailureKind.serviceUnavailable;
      }
      return DirectoryReadFailureKind.unexpected;
    }
    return DirectoryReadFailureKind.unexpected;
  }

  static bool _isPostgrestTemporaryServiceFailure(String code) {
    if (code.startsWith('08') || code.startsWith('53')) return true;
    const postgrestAvailabilityCodes = {
      'PGRST000',
      'PGRST001',
      'PGRST002',
      'PGRST003',
    };
    return postgrestAvailabilityCodes.contains(code);
  }
}
