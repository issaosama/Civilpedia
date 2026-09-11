import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/features/business/domain/directory_entity_types.dart';
import 'package:civilpedia/features/directory/data/directory_cloud_cache.dart';
import 'package:civilpedia/features/directory/data/supabase_cloud_directory_repository.dart';
import 'package:civilpedia/features/directory/data/supabase_directory_read_gateway.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_query_engine.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';
import 'package:civilpedia/features/directory/presentation/canonical_entity_type_presentation.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'helpers/canonical_directory_test_helpers.dart';

const String _kUuid1 = '00000000-0000-0000-0000-000000000001';
const String _kUuid2 = '00000000-0000-0000-0000-000000000002';
const String _kUuid3 = '00000000-0000-0000-0000-000000000003';

/// Canonical row helper with fail-closed-required columns pre-filled.
Map<String, dynamic> _validRow({
  String id = _kUuid1,
  String name = 'Alpha Co',
  String entityType = 'supplier',
  String lifecycleStatus = 'active',
  String claimStatus = 'unclaimed',
  String verificationStatus = 'unverified',
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'entity_type': entityType,
    'lifecycle_status': lifecycleStatus,
    'claim_status': claimStatus,
    'verification_status': verificationStatus,
  };
}

/// Mirrors the exact PostgREST child shape the read gateway projects
/// (`regions(id, code, name_ar, name_en)`, `directory_categories(id, code,
/// name_ar, name_en)`, `entity_media(id, url, media_type)`).
Map<String, dynamic> _rowWithChildren() {
  return <String, dynamic>{
    ..._validRow(),
    'directory_entity_categories': <Map<String, dynamic>>[
      <String, dynamic>{
        'directory_categories': <String, dynamic>{
          'id': 'c1',
          'code': 'C01',
          'name_ar': 'صلب',
          'name_en': 'Steel',
        },
      },
      <String, dynamic>{
        'directory_categories': <String, dynamic>{
          'id': 'c2',
          'code': 'C02',
          'name_ar': 'خرسانة',
          'name_en': null,
        },
      },
    ],
    'entity_locations': <Map<String, dynamic>>[
      <String, dynamic>{
        'region_id': 'r1',
        'address': 'St 1',
        'regions': <String, dynamic>{
          'id': 'r1',
          'code': 'karrada',
          'name_ar': 'كرادة',
          'name_en': 'Karrada',
        },
      },
      <String, dynamic>{
        'region_id': 'r2',
        'address': null,
        'regions': <String, dynamic>{
          'id': 'r2',
          'code': 'mansour',
          'name_ar': 'منصور',
          'name_en': null,
        },
      },
    ],
    'entity_contacts': <Map<String, dynamic>>[
      <String, dynamic>{'id': 'ct1', 'contact_type': 'phone', 'value': '07701234567'},
    ],
    'entity_media': <Map<String, dynamic>>[
      <String, dynamic>{'id': 'm1', 'url': 'https://img.example/x.jpg', 'media_type': 'image'},
    ],
  };
}

/// Controlled test double for [DirectoryReadQueryChannel]: intercepts the
/// production query seam, records the executed call shapes, and returns
/// schema-accurate PostgREST-shaped rows (or throws) on demand.
class _FakeDirectoryReadQueryChannel implements DirectoryReadQueryChannel {
  _FakeDirectoryReadQueryChannel({
    List<Map<String, dynamic>> rows = const [],
    Map<String, List<Map<String, dynamic>>> rowsById = const {},
    Object? throwOnQuery,
  })  : rows = rows,
        rowsById = rowsById,
        throwOnQuery = throwOnQuery;

  List<Map<String, dynamic>> rows;
  Map<String, List<Map<String, dynamic>>> rowsById;
  Object? throwOnQuery;

  int queryAllCalls = 0;
  int queryByIdCalls = 0;
  final List<String> queriedIds = <String>[];

  @override
  Future<List<Map<String, dynamic>>> queryAllActive() async {
    queryAllCalls++;
    final error = throwOnQuery;
    if (error != null) throw error;
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> queryActiveById(String id) async {
    queryByIdCalls++;
    final error = throwOnQuery;
    if (error != null) throw error;
    queriedIds.add(id);
    return List<Map<String, dynamic>>.from(rowsById[id] ?? const []);
  }
}

void main() {
  group('V1-R05 §1 — Canonical entity model', () {
    test('1. tryFromRow succeeds with valid row', () {
      final entity = fakeEntity(
        id: _kUuid1,
        name: 'Alpha Co',
        entityType: 'supplier',
      );
      expect(entity.id, _kUuid1);
      expect(entity.name, 'Alpha Co');
      expect(entity.entityType, 'supplier');
      expect(entity.lifecycleStatus, 'active');
      expect(entity.claimStatus, 'unclaimed');
      expect(entity.verificationStatus, VerificationStatus.unverified);
    });

    test('2. tryFromRow fails on missing id', () {
      final row = _validRow()..remove('id');
      expect(CanonicalDirectoryEntity.tryFromRow(row), isNull);
    });

    test('3. tryFromRow fails on empty id', () {
      final row = _validRow(id: '');
      expect(CanonicalDirectoryEntity.tryFromRow(row), isNull);
    });

    test('3a. tryFromRow fails closed on non-UUID id format', () {
      // The canonical identity is the `directory_entities.id` UUID; a
      // non-UUID row id is never an acceptable canonical identity.
      final row = _validRow(id: 'abc');
      expect(CanonicalDirectoryEntity.tryFromRow(row), isNull);
      expect(CanonicalDirectoryEntity.isValidUuid(_kUuid1), isTrue);
      expect(CanonicalDirectoryEntity.isValidUuid('abc'), isFalse);
    });

    test('4. tryFromRow fails on missing name', () {
      final row = _validRow()..remove('name');
      expect(CanonicalDirectoryEntity.tryFromRow(row), isNull);
    });

    test('5. tryFromRow fails on unknown entity_type', () {
      final row = _validRow(entityType: 'bogus_type');
      expect(CanonicalDirectoryEntity.tryFromRow(row), isNull);
    });

    test('5a. tryFromRow fails closed when lifecycle_status is missing/unknown', () {
      final missing = _validRow()..remove('lifecycle_status');
      expect(CanonicalDirectoryEntity.tryFromRow(missing), isNull);
      final unknown = _validRow(lifecycleStatus: 'archived');
      expect(CanonicalDirectoryEntity.tryFromRow(unknown), isNull);
    });

    test('5b. tryFromRow fails closed when claim_status is missing/unknown', () {
      final missing = _validRow()..remove('claim_status');
      expect(CanonicalDirectoryEntity.tryFromRow(missing), isNull);
      final unknown = _validRow(claimStatus: 'owned');
      expect(CanonicalDirectoryEntity.tryFromRow(unknown), isNull);
    });

    test('5c. tryFromRow fails closed when verification_status is missing', () {
      final missing = _validRow()..remove('verification_status');
      expect(CanonicalDirectoryEntity.tryFromRow(missing), isNull);
    });

    test('5d. canonical statuses round-trip through the row parser', () {
      const lifecycles = ['draft', 'active', 'inactive', 'suspended'];
      const claims = ['unclaimed', 'pending', 'claimed'];
      for (final lifecycle in lifecycles) {
        for (final claim in claims) {
          for (final verification in VerificationStatus.values) {
            final row = _validRow(
              lifecycleStatus: lifecycle,
              claimStatus: claim,
              verificationStatus: verification.name,
            );
            final entity = CanonicalDirectoryEntity.tryFromRow(row);
            expect(entity, isNotNull,
                reason: '$lifecycle/$claim/${verification.name}');
            expect(entity!.lifecycleStatus, lifecycle);
            expect(entity.claimStatus, claim);
            expect(entity.verificationStatus, verification);
          }
        }
      }
    });

    test('6. tryFromRow parses children', () {
      final row = <String, dynamic>{
        ..._validRow(),
        'entity_locations': [
          <String, dynamic>{'regions': {'code': 'karrada', 'name_ar': 'كرادة'}},
        ],
        'entity_contacts': [
          <String, dynamic>{'contact_type': 'phone', 'value': '07701234567'},
        ],
      };
      final entity = CanonicalDirectoryEntity.tryFromRow(
        row,
        categories: [fakeCategory('Steel')],
        locations: [fakeLocation('karrada', regionName: 'كرادة')],
        contacts: [fakePhone('07701234567')],
      );
      expect(entity, isNotNull);
      expect(entity!.categories, hasLength(1));
      expect(entity.categories.first.name, 'Steel');
      expect(entity.locations.first.regionCode, 'karrada');
      expect(entity.contacts.first.value, '07701234567');
    });

    test('7. tryFromRow fails closed on bogus verification_status', () {
      // V1-R05 correction: an unknown verification status is NEVER coerced to
      // unverified. A row that cannot be validated becomes no entity at all.
      final row = _validRow(verificationStatus: 'bogus');
      expect(CanonicalDirectoryEntity.tryFromRow(row), isNull);
    });
  });

  group('V1-R05 §2 — Serialization round-trip', () {
    test('8. toJson/tryFromJson preserves fields', () {
      final original = fakeEntity(
        id: _kUuid1,
        name: 'Test',
        entityType: 'contractor',
        description: 'A description',
        verificationStatus: VerificationStatus.verified,
        categories: [fakeCategory('Concrete', code: 'C01')],
        locations: [fakeLocation('karrada', regionName: 'كرادة', address: 'St 1')],
        contacts: [fakePhone('07701234567'), fakeWhatsApp('07801234567')],
      );
      final json = original.toJson();
      final restored = CanonicalDirectoryEntity.tryFromJson(json);
      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.name, original.name);
      expect(restored.entityType, original.entityType);
      expect(restored.description, original.description);
      expect(restored.verificationStatus, VerificationStatus.verified);
      expect(restored.categories.first.name, 'Concrete');
      expect(restored.categories.first.code, 'C01');
      expect(restored.locations.first.regionCode, 'karrada');
      expect(restored.contacts, hasLength(2));
    });

    test('9. tryFromJson fails on malformed data', () {
      expect(CanonicalDirectoryEntity.tryFromJson({}), isNull);
      expect(
        CanonicalDirectoryEntity.tryFromJson({'id': _kUuid1, 'name': null}),
        isNull,
      );
      expect(
        CanonicalDirectoryEntity.tryFromJson({
          'id': _kUuid1,
          'name': 'X',
          'entity_type': 'nonexistent',
        }),
        isNull,
      );
      expect(
        CanonicalDirectoryEntity.tryFromJson({
          'id': _kUuid1,
          'name': 'X',
          'entity_type': 'supplier',
          'lifecycle_status': 'archived',
          'claim_status': 'unclaimed',
          'verification_status': 'unverified',
        }),
        isNull,
        reason: 'fail-closed lifecycle applies to the cache path too',
      );
    });

    test('10. tryFromJson handles missing children gracefully', () {
      final json = <String, dynamic>{
        'id': _kUuid1,
        'name': 'X',
        'entity_type': 'supplier',
        'lifecycle_status': 'active',
        'claim_status': 'unclaimed',
        'verification_status': 'unverified',
      };
      final entity = CanonicalDirectoryEntity.tryFromJson(json);
      expect(entity, isNotNull);
      expect(entity!.categories, isEmpty);
      expect(entity.locations, isEmpty);
      expect(entity.contacts, isEmpty);
    });

    test('10a. bilingual category round-trip preserves name_ar/name_en', () {
      const category = CanonicalDirectoryCategory(
        id: 'c1',
        name: 'Steel',
        code: 'C01',
        nameAr: 'صلب',
        nameEn: 'Steel',
      );
      final restored = CanonicalDirectoryCategory.fromJson(category.toJson());
      expect(restored.nameAr, 'صلب');
      expect(restored.nameEn, 'Steel');
      expect(restored.code, 'C01');
      expect(restored.name, 'Steel');
    });

    test('10b. category tryFromRow uses name_ar when name_en is absent', () {
      final parsed = CanonicalDirectoryCategory.tryFromRow(<String, dynamic>{
        'id': 'c2',
        'code': 'C02',
        'name_ar': 'خرسانة',
        'name_en': null,
      });
      expect(parsed, isNotNull);
      expect(parsed!.name, 'خرسانة');
      expect(parsed.nameAr, 'خرسانة');
      expect(parsed.nameEn, isNull);
    });

    test('10c. bilingual location round-trip preserves region_name_ar/en', () {
      const location = CanonicalDirectoryLocation(
        regionCode: 'karrada',
        regionName: 'Karrada',
        regionNameAr: 'كرادة',
        regionNameEn: 'Karrada',
        address: 'St 1',
      );
      final restored = CanonicalDirectoryLocation.fromJson(location.toJson());
      expect(restored.regionCode, 'karrada');
      expect(restored.regionNameAr, 'كرادة');
      expect(restored.regionNameEn, 'Karrada');
      expect(restored.regionName, 'Karrada');
      expect(restored.address, 'St 1');
    });

    test('10d. media never carries a caption field', () {
      // entity_media has NO caption column (migration 00006); the canonical
      // model must not invent one for the cache shape.
      final media = CanonicalDirectoryMedia(
        url: 'https://img.example/x.jpg',
        mediaType: 'image',
      );
      expect(media.toJson().containsKey('caption'), isFalse);
      expect(media.toJson()['url'], 'https://img.example/x.jpg');
      final restored = CanonicalDirectoryMedia.fromJson(media.toJson());
      expect(restored.url, media.url);
      expect(restored.mediaType, 'image');
    });
  });

  group('V1-R05 §3 — Entity identity', () {
    test('11. equality by id only', () {
      final a = fakeEntity(id: _kUuid1, name: 'Name A');
      final b = fakeEntity(id: _kUuid1, name: 'Name B');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('12. different id means not equal', () {
      final a = fakeEntity(id: _kUuid1);
      final b = fakeEntity(id: _kUuid2);
      expect(a, isNot(equals(b)));
    });
  });

  group('V1-R05 §4 — DirectoryEntityType.isKnown', () {
    test('13. all known types return true', () {
      for (final type in DirectoryEntityType.all) {
        expect(DirectoryEntityType.isKnown(type), isTrue, reason: type);
      }
    });

    test('14. unknown type returns false', () {
      expect(DirectoryEntityType.isKnown('nonexistent'), isFalse);
      expect(DirectoryEntityType.isKnown(''), isFalse);
    });
  });

  group('V1-R05 §5 — CanonicalEntityTypePresentation', () {
    test('15. all 9 types have Arabic labels', () {
      for (final type in CanonicalEntityTypePresentation.orderedTypes) {
        final label = CanonicalEntityTypePresentation.arLabel(type);
        expect(label, isNotEmpty, reason: type);
      }
    });

    test('16. all 9 types have English labels', () {
      for (final type in CanonicalEntityTypePresentation.orderedTypes) {
        final label = CanonicalEntityTypePresentation.enLabel(type);
        expect(label, isNotEmpty, reason: type);
      }
    });

    test('17. all 9 types have icons', () {
      for (final type in CanonicalEntityTypePresentation.orderedTypes) {
        final icon = CanonicalEntityTypePresentation.iconFor(type);
        expect(icon, isNotNull, reason: type);
      }
    });

    test('18. unknown type returns fallback', () {
      expect(
        CanonicalEntityTypePresentation.arLabel('nonexistent'),
        isNotEmpty,
      );
      expect(CanonicalEntityTypePresentation.iconFor('nonexistent'), isNotNull);
    });

    test('19. orderedTypes has exactly 9 entries', () {
      expect(CanonicalEntityTypePresentation.orderedTypes, hasLength(9));
    });
  });

  group('V1-R05 §6 — DirectoryCloudCache', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('20. empty prefs returns null', () async {
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot, isNull);
    });

    test('21. write then read round-trips', () async {
      final now = DateTime.now().toUtc();
      final entity = fakeEntity(id: _kUuid1, name: 'Test');
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: now,
          entities: [entity],
        ),
      );
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot, isNotNull);
      expect(snapshot!.entities, hasLength(1));
      expect(snapshot.entities.first.id, _kUuid1);
      expect(snapshot.refreshedAt, now);
    });

    test('22. version mismatch returns null', () async {
      final json = jsonEncode({
        'schema_version': 999,
        'refreshed_at': DateTime.now().toUtc().toIso8601String(),
        'entities': [],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: json,
      });
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot, isNull);
    });

    test('23. malformed JSON returns null', () async {
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: 'not-json',
      });
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot, isNull);
    });

    test('24. atomic write replaces previous snapshot', () async {
      final now1 = DateTime.utc(2026, 1, 1);
      final now2 = DateTime.utc(2026, 2, 1);
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: now1,
          entities: [fakeEntity(id: _kUuid1, name: 'Old')],
        ),
      );
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: now2,
          entities: [fakeEntity(id: _kUuid2, name: 'New')],
        ),
      );
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot!.entities, hasLength(1));
      expect(snapshot.entities.first.id, _kUuid2);
    });

    test('24a. authoritative EMPTY snapshot replaces old snapshot', () async {
      final now1 = DateTime.utc(2026, 1, 1);
      final now2 = DateTime.utc(2026, 3, 1);
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: now1,
          entities: [fakeEntity(id: _kUuid1, name: 'Old')],
        ),
      );
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: now2,
          entities: const [],
        ),
      );
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot, isNotNull);
      expect(snapshot!.entities, isEmpty);
    });

    test('24b. whole snapshot rejected when ANY entity is malformed', () async {
      final now = DateTime.now().toUtc();
      final good = fakeEntity(id: _kUuid1, name: 'Good');
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: now,
          entities: [good],
        ),
      );

      // Inject a snapshot with one valid + one malformed entity row; the whole
      // snapshot must be rejected (never silently drop the authoritative row).
      final goodJson = good.toJson();
      final entityWithBadId = Map<String, dynamic>.from(goodJson)
        ..['id'] = 'not-a-uuid';
      final snapshotJson = jsonEncode({
        'schema_version': DirectoryCloudCache.cacheVersion,
        'refreshed_at': now.toIso8601String(),
        'entities': [goodJson, entityWithBadId],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: snapshotJson,
      });
      expect(await DirectoryCloudCache.read(), isNull);
    });

    test('24c. whole snapshot rejected when one entity has bogus verification',
        () async {
      final now = DateTime.now().toUtc();
      final trimmed = Map<String, dynamic>.from(
        fakeEntity(id: _kUuid1, name: 'Good').toJson(),
      )..['verification_status'] = 'bogus';
      final snapshotJson = jsonEncode({
        'schema_version': DirectoryCloudCache.cacheVersion,
        'refreshed_at': now.toIso8601String(),
        'entities': [trimmed],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: snapshotJson,
      });
      expect(await DirectoryCloudCache.read(), isNull);
    });

    test('25. cache byId lookup works', () async {
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.now().toUtc(),
          entities: [
            fakeEntity(id: _kUuid1, name: 'Alpha'),
            fakeEntity(id: _kUuid2, name: 'Beta'),
          ],
        ),
      );
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot!.byId(_kUuid2)!.name, 'Beta');
      expect(snapshot.byId('missing'), isNull);
    });
  });

  group('V1-R05 §7 — FakeCloudDirectoryRepository', () {
    test('26. load returns fresh entities', () async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: _kUuid1, name: 'Alpha'),
      ]);
      final result = await repo.load();
      expect(result.state, DirectoryLoadState.fresh);
      expect(result.entities, hasLength(1));
      expect(result.entities.first.name, 'Alpha');
      expect(repo.loadCalls, 1);
    });

    test('27. load returns empty when no entities', () async {
      final repo = FakeCloudDirectoryRepository(const []);
      final result = await repo.load();
      expect(result.state, DirectoryLoadState.empty);
      expect(result.entities, isEmpty);
    });

    test('28. load returns error when throws', () async {
      final repo = FakeCloudDirectoryRepository(
        const [],
        throwOnLoad: Exception('boom'),
      );
      final result = await repo.load();
      expect(result.state, DirectoryLoadState.error);
    });

    test('29. loadByCanonicalId resolves from entity list', () async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: _kUuid1, name: 'Alpha'),
        fakeEntity(id: _kUuid2, name: 'Beta'),
      ]);
      final entity = await repo.loadByCanonicalId(_kUuid2);
      expect(entity, isNotNull);
      expect(entity!.name, 'Beta');
    });

    test('30. loadByCanonicalId returns null for unknown id', () async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: _kUuid1, name: 'Alpha'),
      ]);
      final entity = await repo.loadByCanonicalId('missing');
      expect(entity, isNull);
    });

    test('31. refresh succeeds and returns entities', () async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: _kUuid1, name: 'Alpha'),
      ]);
      final result = await repo.refresh();
      expect(result.succeeded, isTrue);
      expect(result.entities, hasLength(1));
    });

    test('32. refresh failure returns failure status', () async {
      final repo = FakeCloudDirectoryRepository(
        const [],
        throwOnLoad: Exception('boom'),
      );
      final result = await repo.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.failure);
    });

    test('33. isAvailable reflects gateway state', () {
      final available = FakeCloudDirectoryRepository(const []);
      expect(available.isAvailable, isTrue);

      final unavailable = FakeCloudDirectoryRepository(
        const [],
        unavailable: true,
      );
      expect(unavailable.isAvailable, isFalse);
    });
  });

  group('V1-R05 §8 — CanonicalDirectoryQueryEngine', () {
    final entities = [
      fakeEntity(
        id: _kUuid1,
        name: 'Alpha Steel',
        entityType: 'supplier',
        categories: [fakeCategory('Steel')],
        locations: [fakeLocation('karrada')],
      ),
      fakeEntity(
        id: _kUuid2,
        name: 'Beta Concrete',
        entityType: 'contractor',
        categories: [fakeCategory('Concrete')],
        locations: [fakeLocation('mansour')],
      ),
      fakeEntity(
        id: _kUuid3,
        name: 'Gamma Labs',
        entityType: 'laboratory',
        categories: [fakeCategory('Testing')],
        locations: [fakeLocation('karrada')],
      ),
    ];

    test('34. text search matches name', () {
      final result = CanonicalDirectoryQueryEngine.apply(
        entities,
        const CanonicalDirectoryQuery(text: 'steel'),
      );
      expect(result, hasLength(1));
      expect(result.first.name, 'Alpha Steel');
    });

    test('35. text search matches category name', () {
      final result = CanonicalDirectoryQueryEngine.apply(
        entities,
        const CanonicalDirectoryQuery(text: 'concrete'),
      );
      expect(result, hasLength(1));
      expect(result.first.name, 'Beta Concrete');
    });

    test('36. entityType filter works', () {
      final result = CanonicalDirectoryQueryEngine.apply(
        entities,
        const CanonicalDirectoryQuery(entityType: 'supplier'),
      );
      expect(result, hasLength(1));
      expect(result.first.entityType, 'supplier');
    });

    test('37. regionCode filter works', () {
      final result = CanonicalDirectoryQueryEngine.apply(
        entities,
        const CanonicalDirectoryQuery(regionCode: 'karrada'),
      );
      expect(result, hasLength(2));
    });

    test('38. AND semantics between filters', () {
      final result = CanonicalDirectoryQueryEngine.apply(
        entities,
        const CanonicalDirectoryQuery(
          entityType: 'supplier',
          regionCode: 'karrada',
        ),
      );
      expect(result, hasLength(1));
      expect(result.first.name, 'Alpha Steel');
    });

    test('39. deterministic sort by name then id', () {
      final unsorted = [
        fakeEntity(id: _kUuid2, name: 'Zulu'),
        fakeEntity(id: _kUuid1, name: 'Alpha'),
        fakeEntity(id: _kUuid3, name: 'Alpha'),
      ];
      final result = CanonicalDirectoryQueryEngine.apply(
        unsorted,
        const CanonicalDirectoryQuery(),
      );
      expect(result.map((e) => e.id).toList(), [_kUuid1, _kUuid3, _kUuid2]);
    });

    test('40. empty query matches all', () {
      final result = CanonicalDirectoryQueryEngine.apply(
        entities,
        const CanonicalDirectoryQuery(),
      );
      expect(result, hasLength(3));
    });

    test('41. no matches returns empty', () {
      final result = CanonicalDirectoryQueryEngine.apply(
        entities,
        const CanonicalDirectoryQuery(text: 'zzz_nonexistent'),
      );
      expect(result, isEmpty);
    });

    test('42. input list is not mutated', () {
      final copy = List<CanonicalDirectoryEntity>.from(entities);
      CanonicalDirectoryQueryEngine.apply(
        entities,
        const CanonicalDirectoryQuery(text: 'alpha'),
      );
      expect(entities, orderedEquals(copy));
    });
  });

  group('V1-R05 §9 — Gateway read-projection contract', () {
    final gateway = File(
      'lib/features/directory/data/supabase_directory_read_gateway.dart',
    ).readAsStringSync();

    test('A. categories projected with bilingual name_ar/name_en', () {
      expect(
        gateway,
        contains('directory_categories(id, code, name_ar, name_en)'),
      );
      expect(gateway, isNot(contains("directory_categories(id, code, name)")));
    });

    test('B. regions projected with bilingual name_ar/name_en', () {
      expect(gateway, contains('regions(id, code, name_ar, name_en)'));
      expect(gateway, isNot(contains('regions(id, code, name)')));
    });

    test('C. entity_media projected as (id, url, media_type) with no caption',
        () {
      final projection = SupabaseDirectoryReadQueryChannel.readProjection;
      expect(projection, contains('entity_media(id, url, media_type)'));
      expect(projection.contains('caption'), isFalse,
          reason: 'migration 00006 has no caption column');
    });

    test('D. loadById guards on canonical UUID before querying', () {
      expect(gateway, contains('CanonicalDirectoryEntity.isValidUuid(id)'));
    });

    test('E. region display derives from bilingual fields (English-first)', () {
      expect(gateway, contains('_displayName(regionNameEn, regionNameAr)'));
      expect(gateway, contains('regionNameAr'));
      expect(gateway, contains('regionNameEn'));
    });
  });

  group('V1-R05 §10 — Gateway child mapping (bilingual)', () {
    test('F. gateway-shaped children parse with bilingual labels', () {
      final row = _rowWithChildren();
      final categories = <CanonicalDirectoryCategory>[];
      for (final item in row['directory_entity_categories'] as List) {
        final cat = (item as Map)['directory_categories'] as Map;
        final parsed = CanonicalDirectoryCategory.tryFromRow(
          Map<String, dynamic>.from(cat),
        );
        expect(parsed, isNotNull);
        categories.add(parsed!);
      }
      expect(categories[0].name, 'Steel');
      expect(categories[0].nameAr, 'صلب');
      expect(categories[1].name, 'خرسانة', reason: 'Arabic fallback');
      expect(categories[1].nameEn, isNull);
    });

    test('G. region mapping from gateway shape is bilingual', () {
      final row = _rowWithChildren();
      final locations = <CanonicalDirectoryLocation>[];
      for (final item in row['entity_locations'] as List) {
        final region = (item as Map)['regions'] as Map;
        final nameEn = region['name_en'] as String?;
        final nameAr = region['name_ar'] as String?;
        locations.add(CanonicalDirectoryLocation(
          regionCode: region['code'] as String,
          regionName: (nameEn != null && nameEn.isNotEmpty) ? nameEn : nameAr,
          regionNameAr: nameAr,
          regionNameEn: nameEn,
          address: item['address'] as String?,
        ));
      }
      expect(locations[0].regionName, 'Karrada');
      expect(locations[0].regionNameAr, 'كرادة');
      expect(locations[1].regionName, 'منصور', reason: 'Arabic fallback');
      expect(locations[1].regionNameEn, isNull);
    });

    test('H. media mapping from gateway shape carries no caption', () {
      final row = _rowWithChildren();
      final rawMedia = row['entity_media'] as List;
      final url = (rawMedia.first as Map)['url'] as String;
      final mediaType = (rawMedia.first as Map)['media_type'] as String;
      expect(url, 'https://img.example/x.jpg');
      expect(mediaType, 'image');
      expect((rawMedia.first as Map).containsKey('caption'), isFalse);
    });
  });

  group('V1-R05 §11 — Canonical detail routing resolution', () {
    Widget _resolverApp(String id, CloudDirectoryRepository repo,
        {CanonicalDirectoryEntity? seed}) {
      return ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: DirectoryProviderDetailResolver(
            entityId: id,
            repository: repo,
            seedEntity: seed,
          ),
        ),
      );
    }

    testWidgets('I. resolves detail by canonical id through repository',
        (tester) async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: _kUuid1, name: 'Resolved Name'),
      ]);
      await tester.pumpWidget(_resolverApp(_kUuid1, repo));
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryProviderDetailScreen), findsOneWidget);
      expect(find.text('Resolved Name'), findsWidgets);
      expect(find.text('Entity not found'), findsNothing);
    });

    testWidgets('J. unknown canonical id renders unavailable state',
        (tester) async {
      final repo = FakeCloudDirectoryRepository(const []);
      await tester.pumpWidget(_resolverApp(_kUuid1, repo));
      await tester.pumpAndSettle();
      expect(find.text('Entity not found'), findsOneWidget);
      expect(find.byType(DirectoryProviderDetailScreen), findsNothing);
    });

    testWidgets(
        'K. seed entity is replaced by authoritative repository resolution',
        (tester) async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: _kUuid1, name: 'Authoritative'),
      ]);
      final seed = fakeEntity(id: _kUuid1, name: 'Stale Seed');
      await tester.pumpWidget(_resolverApp(_kUuid1, repo, seed: seed));
      await tester.pumpAndSettle();
      expect(find.text('Authoritative'), findsWidgets);
      expect(find.text('Stale Seed'), findsNothing);
    });

    testWidgets('L. seed with mismatched id is never used as a hint',
        (tester) async {
      final repo = FakeCloudDirectoryRepository([
        fakeEntity(id: _kUuid1, name: 'Authoritative'),
      ]);
      final stale = fakeEntity(id: _kUuid2, name: 'Wrong Id Seed');
      await tester.pumpWidget(_resolverApp(_kUuid1, repo, seed: stale));
      await tester.pumpAndSettle();
      expect(find.text('Authoritative'), findsWidgets);
      expect(find.text('Wrong Id Seed'), findsNothing);
    });
  });

  group('V1-R05 §12 — Legacy recheck', () {
    test('M1. VerificationStatus enum stays exactly the 5 canonical states',
        () {
      expect(VerificationStatus.values.map((v) => v.name),
          ['unverified', 'pending', 'verified', 'rejected', 'suspended']);
    });

    test('M2. legacy sb_profiles key remains Storage-only legacy', () {
      expect(AppStorageKeys.sbProfiles, 'sb_profiles');
    });

    test('M3. canonical detail route is /directory/entity/:id', () {
      expect(AppRoutes.directoryEntityDetailFor(_kUuid1), '/directory/entity/$_kUuid1');
      expect(AppRoutes.directoryEntityDetailFor(_kUuid2), '/directory/entity/$_kUuid2');
    });

    test('M4. only the dedicated cloud-cache key is added for Directory', () {
      final keysSource = File(
        'lib/core/storage/app_storage_keys.dart',
      ).readAsStringSync();
      final directoryKeys = RegExp("'directory_[a-z_]+'")
          .allMatches(keysSource)
          .map((m) => m.group(0))
          .toSet();
      expect(directoryKeys, {'\'directory_cloud_cache\''});
    });
  });

  group('V1-R05 §13 — V1-R04 compatibility', () {
    test('N1. legacy sb_profiles wrapper repository untouched by cloud cache',
        () {
      final wrapper = File(
        'lib/features/directory/data/sb_profiles_directory_repository.dart',
      ).readAsStringSync();
      expect(wrapper, isNot(contains('directory_cloud_cache')));
      expect(
        wrapper,
        isNot(contains(
          "import 'package:shared_preferences/shared_preferences.dart'",
        )),
      );
      expect(wrapper, isNot(contains('getInstance(')));
    });

    test('N2. V1-R05 cloud gateway is read-only surface', () {
      final gateway = File(
        'lib/features/directory/data/supabase_directory_read_gateway.dart',
      ).readAsStringSync();
      expect(gateway.contains('.insert('), isFalse);
      expect(gateway.contains('.update('), isFalse);
      expect(gateway.contains('.delete('), isFalse);
      expect(gateway.contains('.rpc('), isFalse);
    });
  });

  group('V1-R05 §14 — Production gateway behavioral coverage', () {
    Future<SupabaseService> availableService() async {
      final service = SupabaseService(
        config: const BackendConfig(
          appEnvRaw: 'development',
          supabaseUrl: 'https://project.supabase.co',
          supabaseAnonKey: 'test-anon-key',
        ),
      );
      await service.init(
        initialize:
            ({required String url, required String publishableKey}) async {},
      );
      return service;
    }

    test('P1. loadAll executes the all-active query through the channel and '
        'parses a schema-accurate response into the canonical model', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithChildren()],
      );
      final gateway = SupabaseDirectoryReadGateway(
        service: await availableService(),
        queryChannel: channel,
      );

      final entities = await gateway.loadAll();

      expect(channel.queryAllCalls, 1);
      expect(entities, hasLength(1));
      final entity = entities.single;
      // Bilingual category mapped from name_ar/name_en (two categories).
      expect(entity.categories, hasLength(2));
      final steel = entity.categories.firstWhere((c) => c.id == 'c1');
      expect(steel.name, 'Steel');
      expect(steel.nameAr, 'صلب');
      expect(steel.nameEn, 'Steel');
      final concrete = entity.categories.firstWhere((c) => c.id == 'c2');
      expect(concrete.name, 'خرسانة', reason: 'Arabic fallback');
      // Bilingual location mapped from regions (two canonical locations).
      expect(entity.locations, hasLength(2));
      final karrada = entity.locations
          .firstWhere((l) => l.regionCode == 'karrada');
      expect(karrada.regionName, 'Karrada');
      expect(karrada.regionNameAr, 'كرادة');
      expect(karrada.address, 'St 1');
      final mansour = entity.locations
          .firstWhere((l) => l.regionCode == 'mansour');
      expect(mansour.regionName, 'منصور', reason: 'Arabic fallback');
      // Media parses without caption.
      expect(entity.media.single.url, 'https://img.example/x.jpg');
      expect(entity.media.single.mediaType, 'image');
      // Contact parsed.
      expect(entity.contacts.single.value, '07701234567');
    });

    test('P2. loadById executes the by-id query and resolves the canonical id',
        () async {
      final channel = _FakeDirectoryReadQueryChannel(
        rowsById: {
          _kUuid1: [_rowWithChildren()],
        },
      );
      final gateway = SupabaseDirectoryReadGateway(
        service: await availableService(),
        queryChannel: channel,
      );

      final entity = await gateway.loadById(_kUuid1);

      expect(channel.queryByIdCalls, 1);
      expect(channel.queriedIds, [_kUuid1]);
      expect(entity, isNotNull);
      expect(entity!.id, _kUuid1);
      expect(entity.name, 'Alpha Co');
    });

    test('P3. loadById rejects a malformed id WITHOUT executing a query', () async {
      final channel = _FakeDirectoryReadQueryChannel();
      final gateway = SupabaseDirectoryReadGateway(
        service: await availableService(),
        queryChannel: channel,
      );

      final entity = await gateway.loadById('not-a-uuid');

      expect(entity, isNull);
      expect(channel.queryByIdCalls, 0);
    });

    test('P4. production projection requests bilingual category/region and '
        'schema-valid media only', () {
      final projection = SupabaseDirectoryReadQueryChannel.readProjection;
      // Categories/regions query name_ar AND name_en (not a single `name`).
      expect(
        projection,
        contains('directory_categories(id, code, name_ar, name_en)'),
      );
      expect(projection, isNot(contains('directory_categories(id, code, name)')));
      expect(projection, contains('regions(id, code, name_ar, name_en)'));
      expect(projection, isNot(contains('regions(id, code, name)')));
      // Media requests only schema-valid fields — never caption.
      expect(projection, contains('entity_media(id, url, media_type)'));
      expect(projection.contains('caption'), isFalse);
      // Unsupported standalone `name` columns are absent.
      expect(projection.contains('regions.name'), isFalse);
      expect(projection.contains('directory_categories.name'), isFalse);
    });

    test('P5. loadAll failure propagates; loadById failure fails safe', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        throwOnQuery: Exception('network down'),
      );
      final gateway = SupabaseDirectoryReadGateway(
        service: await availableService(),
        queryChannel: channel,
      );

      await expectLater(gateway.loadAll(), throwsA(isA<Exception>()));
      expect(await gateway.loadById(_kUuid1), isNull);
    });
  });

  group('V1-R05 §15 — Production repository behavioral coverage', () {
    late SupabaseDirectoryReadGateway gateway;
    late _FakeDirectoryReadQueryChannel channel;
    late SupabaseCloudDirectoryRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      channel = _FakeDirectoryReadQueryChannel();
      final service = SupabaseService(
        config: const BackendConfig(
          appEnvRaw: 'development',
          supabaseUrl: 'https://project.supabase.co',
          supabaseAnonKey: 'test-anon-key',
        ),
      );
      await service.init(
        initialize:
            ({required String url, required String publishableKey}) async {},
      );
      gateway =
          SupabaseDirectoryReadGateway(service: service, queryChannel: channel);
      repository = SupabaseCloudDirectoryRepository(
        service: service,
        gateway: gateway,
      );
    });

    test('Q1. successful cloud refresh calls the cloud seam, replaces the '
        'cache, and returns authoritative entities', () async {
      channel.rows = [_rowWithChildren()];

      final result = await repository.refresh();

      expect(result.succeeded, isTrue);
      expect(result.status, DirectoryRefreshStatus.success);
      expect(result.entities, hasLength(1));
      expect(result.entities.single.id, _kUuid1);
      expect(channel.queryAllCalls, 1);

      final cached = await DirectoryCloudCache.read();
      expect(cached, isNotNull);
      expect(cached!.entities.single.id, _kUuid1);
    });

    test('Q2. failed cloud refresh preserves the last valid cache', () async {
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [fakeEntity(id: _kUuid1, name: 'Cached Co')],
        ),
      );
      channel.throwOnQuery = Exception('network down');

      final refresh = await repository.refresh();
      expect(refresh.succeeded, isFalse);
      expect(refresh.status, DirectoryRefreshStatus.failure);
      expect(refresh.entities, isEmpty);

      // Cache preserved — not destructively overwritten.
      final cached = await repository.readCache();
      expect(cached, isNotNull);
      expect(cached!.entities.single.name, 'Cached Co');

      // Combined load falls back to the stale cache.
      final load = await repository.load();
      expect(load.state, DirectoryLoadState.stale);
      expect(load.entities.single.name, 'Cached Co');
    });

    test('Q3. successful authoritative EMPTY refresh replaces the old cache',
        () async {
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [fakeEntity(id: _kUuid1, name: 'Old Co')],
        ),
      );
      channel.rows = [];

      final result = await repository.refresh();
      expect(result.succeeded, isTrue);
      expect(result.entities, isEmpty);

      final load = await repository.load();
      expect(load.state, DirectoryLoadState.empty);
      expect(load.entities, isEmpty);

      final cached = await repository.readCache();
      expect(cached, isNotNull);
      expect(cached!.entities, isEmpty, reason: 'old snapshot is replaced');
    });

    test('Q4a. malformed cache fails safely and never invents authority',
        () async {
      final malformed = jsonEncode({
        'schema_version': DirectoryCloudCache.cacheVersion,
        'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entities': [
          <String, dynamic>{
            'id': 'not-a-uuid',
            'name': 'Invented',
          },
        ],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: malformed,
      });

      expect(await repository.readCache(), isNull);
      // Cloud failure on top of malformed cache → production error, no fake.
      channel.throwOnQuery = Exception('network down');
      final load = await repository.load();
      expect(load.state, DirectoryLoadState.error);
      expect(load.entities, isEmpty);
    });

    test('Q4b. malformed cache + available empty cloud resolves to empty, '
        'not to invented entities', () async {
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: 'not-json',
      });
      channel.rows = [];

      final load = await repository.load();

      expect(load.state, DirectoryLoadState.empty);
      expect(load.entities, isEmpty);
    });

    test('Q5. sb_profiles is never surfaced or overwritten by the cloud '
        'repository', () async {
      const legacyBlob = '''
        [{"id":"sb-1","name":"Legacy Contractor","type":"contractor"}]
      ''';
      SharedPreferences.setMockInitialValues({
        'sb_profiles': legacyBlob,
      });
      channel.rows = [_rowWithChildren()];

      final load = await repository.load();

      // Only canonical cloud rows surface — never legacy sb_profiles.
      expect(load.state, DirectoryLoadState.fresh);
      expect(load.entities.single.id, _kUuid1);
      expect(load.entities.map((e) => e.id).contains('sb-1'), isFalse);

      // Legacy blob untouched (non-destructive isolation).
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sb_profiles'), legacyBlob);
    });
  });
}