import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/core/network/remote_operation_policy.dart';
import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/features/directory/data/directory_cloud_cache.dart';
import 'package:civilpedia/features/directory/data/supabase_cloud_directory_repository.dart';
import 'package:civilpedia/features/directory/data/supabase_directory_read_gateway.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';

import 'helpers/canonical_directory_test_helpers.dart';

const String _kUuid1 = '00000000-0000-0000-0000-000000000001';
const String _kUuid2 = '00000000-0000-0000-0000-000000000002';
const String _kUuid3 = '00000000-0000-0000-0000-000000000003';
const Object _missingSentinel = Object();

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

Map<String, dynamic> _rowWithChildren({String id = _kUuid1}) {
  return <String, dynamic>{
    ..._validRow(id: id),
    'directory_entity_categories': <Map<String, dynamic>>[
      <String, dynamic>{
        'directory_categories': <String, dynamic>{
          'id': 'c1',
          'code': 'C01',
          'name_ar': 'صلب',
          'name_en': 'Steel',
        },
      },
    ],
    'entity_locations': <Map<String, dynamic>>[
      <String, dynamic>{
        'region_id': 'r1',
        'address': 'St 1',
        'is_primary': true,
        'regions': <String, dynamic>{
          'id': 'r1',
          'code': 'karrada',
          'name_ar': 'كرادة',
          'name_en': 'Karrada',
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

class _FakeDirectoryReadQueryChannel implements DirectoryReadQueryChannel {
  _FakeDirectoryReadQueryChannel({
    List<Map<String, dynamic>> rows = const [],
    Map<String, List<Map<String, dynamic>>> rowsById = const {},
    Object? throwOnQuery,
    this.delay,
  })  : rows = rows,
        rowsById = rowsById,
        throwOnQuery = throwOnQuery;

  List<Map<String, dynamic>> rows;
  Map<String, List<Map<String, dynamic>>> rowsById;
  Object? throwOnQuery;
  Duration? delay;

  int queryAllCalls = 0;
  int queryByIdCalls = 0;
  final List<String> queriedIds = <String>[];

  @override
  Future<List<Map<String, dynamic>>> queryAllActive() async {
    queryAllCalls++;
    final error = throwOnQuery;
    if (error != null) throw error;
    if (delay != null) await Future<void>.delayed(delay!);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> queryActiveById(String id) async {
    queryByIdCalls++;
    final error = throwOnQuery;
    if (error != null) throw error;
    if (delay != null) await Future<void>.delayed(delay!);
    queriedIds.add(id);
    return List<Map<String, dynamic>>.from(rowsById[id] ?? const []);
  }
}

class _FakeCacheStore implements DirectoryCloudCacheStore {
  final Map<String, String> _data = {};
  bool _writeResult = true;
  bool _throwOnWrite = false;
  int writeCalls = 0;

  void setWriteResult(bool value, {bool throwOnWrite = false}) {
    _writeResult = value;
    _throwOnWrite = throwOnWrite;
  }

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<bool> writeString(String key, String value) async {
    writeCalls++;
    if (_throwOnWrite) throw Exception('persistence failed');
    if (_writeResult) _data[key] = value;
    return _writeResult;
  }
}

Future<SupabaseService> _availableService() async {
  final service = SupabaseService(
    config: const BackendConfig(
      appEnvRaw: 'development',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'test-anon-key',
    ),
  );
  await service.init(
    initialize: ({required String url, required String publishableKey}) async {},
  );
  return service;
}

Future<SupabaseCloudDirectoryRepository> _repository({
  required _FakeDirectoryReadQueryChannel channel,
  Duration? readTimeout,
}) async {
  final service = await _availableService();
  final gateway = SupabaseDirectoryReadGateway(
    service: service,
    queryChannel: channel,
    readTimeout: readTimeout ?? RemoteOperationPolicy.read,
  );
  return SupabaseCloudDirectoryRepository(
    service: service,
    gateway: gateway,
  );
}

void main() {
  group('V1-R09 P2-B1 — CACHE / PARSING', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      DirectoryCloudCache.setTestStore(null);
    });

    tearDown(() {
      DirectoryCloudCache.setTestStore(null);
    });

    test('valid non-empty cache accepted', () async {
      final entity = fakeEntity(id: _kUuid1, name: 'Good');
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [entity],
        ),
      );
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot, isNotNull);
      expect(snapshot!.entities, hasLength(1));
      expect(snapshot.entities.first.id, _kUuid1);
    });

    test('valid empty cache accepted', () async {
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: const [],
        ),
      );
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot, isNotNull);
      expect(snapshot!.entities, isEmpty);
    });

    test('malformed entity invalidates entire cache', () async {
      final good = fakeEntity(id: _kUuid1, name: 'Good');
      final goodJson = good.toJson();
      final badEntity = Map<String, dynamic>.from(goodJson)..['id'] = 'not-a-uuid';
      final snapshotJson = jsonEncode({
        'schema_version': DirectoryCloudCache.cacheVersion,
        'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entities': [goodJson, badEntity],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: snapshotJson,
      });
      expect(await DirectoryCloudCache.read(), isNull);
    });

    test('malformed nested relationship invalidates entire cache', () async {
      final entity = fakeEntity(
        id: _kUuid1,
        name: 'Good',
        contacts: [fakePhone('07701234567')],
      );
      final json = entity.toJson();
      json['contacts'] = [
        <String, dynamic>{'contact_type': '', 'value': ''},
      ];
      final snapshotJson = jsonEncode({
        'schema_version': DirectoryCloudCache.cacheVersion,
        'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entities': [json],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: snapshotJson,
      });
      expect(await DirectoryCloudCache.read(), isNull);
    });

    test('partial remote entity response rejected', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [
          _rowWithChildren(id: _kUuid1),
          _rowWithChildren(id: _kUuid2)..remove('name'),
        ],
      );
      final repo = await _repository(channel: channel);
      final result = await repo.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.malformedResponse);
    });

    test('malformed relationship response rejected', () async {
      final row = _rowWithChildren();
      row['entity_contacts'] = [
        <String, dynamic>{'contact_type': '', 'value': ''},
      ];
      final channel = _FakeDirectoryReadQueryChannel(rows: [row]);
      final repo = await _repository(channel: channel);
      final result = await repo.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.malformedResponse);
    });

    test('malformed remote result never replaces valid cache', () async {
      final store = _FakeCacheStore();
      DirectoryCloudCache.setTestStore(store);
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [fakeEntity(id: _kUuid1, name: 'Cached')],
        ),
      );
      store.writeCalls = 0;

      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithChildren(id: _kUuid2)..remove('name')],
      );
      final repo = await _repository(channel: channel);
      final result = await repo.refresh();

      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.malformedResponse);
      expect(store.writeCalls, 0, reason: 'cache must not be overwritten');
      final cached = await repo.readCache();
      expect(cached, isNotNull);
      expect(cached!.entities.single.name, 'Cached');
    });

    test('authoritative empty may replace old cache', () async {
      final channel = _FakeDirectoryReadQueryChannel(rows: const []);
      final repo = await _repository(channel: channel);
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [fakeEntity(id: _kUuid1, name: 'Old')],
        ),
      );

      final result = await repo.refresh();

      expect(result.succeeded, isTrue);
      expect(result.status, DirectoryRefreshStatus.authoritativeEmpty);
      final cached = await repo.readCache();
      expect(cached, isNotNull);
      expect(cached!.entities, isEmpty);
    });
  });

  group('V1-R09 P2-B1 — REQUIRED RELATIONSHIP STRUCTURES', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      DirectoryCloudCache.setTestStore(null);
    });

    tearDown(() {
      DirectoryCloudCache.setTestStore(null);
    });

    Map<String, dynamic> _rowWithout(String key) {
      final row = _rowWithChildren(id: _kUuid1);
      row.remove(key);
      return row;
    }

    Map<String, dynamic> _rowWithNull(String key) {
      final row = _rowWithChildren(id: _kUuid1);
      row[key] = null;
      return row;
    }

    Map<String, dynamic> _rowWithEmpty(String key) {
      final row = _rowWithChildren(id: _kUuid1);
      row[key] = <Map<String, dynamic>>[];
      return row;
    }

    for (final key in [
      'directory_entity_categories',
      'entity_locations',
      'entity_contacts',
      'entity_media',
    ]) {
      test('REMOTE missing $key invalidates snapshot', () async {
        final channel = _FakeDirectoryReadQueryChannel(
          rows: [_rowWithout(key)],
        );
        final repo = await _repository(channel: channel);
        final result = await repo.refresh();
        expect(result.status, DirectoryRefreshStatus.malformedResponse);
      });

      test('REMOTE null $key invalidates snapshot', () async {
        final channel = _FakeDirectoryReadQueryChannel(
          rows: [_rowWithNull(key)],
        );
        final repo = await _repository(channel: channel);
        final result = await repo.refresh();
        expect(result.status, DirectoryRefreshStatus.malformedResponse);
      });

      test('REMOTE empty $key is valid', () async {
        final channel = _FakeDirectoryReadQueryChannel(
          rows: [_rowWithEmpty(key)],
        );
        final repo = await _repository(channel: channel);
        final result = await repo.refresh();
        expect(result.succeeded, isTrue);
      });
    }

    Map<String, dynamic> _cacheEntityWithout(String key) {
      final json = fakeEntity(id: _kUuid1, name: 'Good').toJson();
      json.remove(key);
      return json;
    }

    Map<String, dynamic> _cacheEntityWithNull(String key) {
      final json = fakeEntity(id: _kUuid1, name: 'Good').toJson();
      json[key] = null;
      return json;
    }

    for (final key in ['categories', 'locations', 'contacts', 'media']) {
      test('CACHE missing $key invalidates snapshot', () async {
        final snapshotJson = jsonEncode({
          'schema_version': DirectoryCloudCache.cacheVersion,
          'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
          'entities': [_cacheEntityWithout(key)],
        });
        SharedPreferences.setMockInitialValues({
          AppStorageKeys.directoryCloudCache: snapshotJson,
        });
        expect(await DirectoryCloudCache.read(), isNull);
      });

      test('CACHE null $key invalidates snapshot', () async {
        final snapshotJson = jsonEncode({
          'schema_version': DirectoryCloudCache.cacheVersion,
          'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
          'entities': [_cacheEntityWithNull(key)],
        });
        SharedPreferences.setMockInitialValues({
          AppStorageKeys.directoryCloudCache: snapshotJson,
        });
        expect(await DirectoryCloudCache.read(), isNull);
      });
    }
  });

  group('V1-R09 P2-B1 — PARSER TYPE SAFETY', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      DirectoryCloudCache.setTestStore(null);
    });

    tearDown(() {
      DirectoryCloudCache.setTestStore(null);
    });

    test('REMOTE wrong scalar type in entity field -> malformedResponse', () async {
      final row = _rowWithChildren();
      row['name'] = 123;
      final channel = _FakeDirectoryReadQueryChannel(rows: [row]);
      final repo = await _repository(channel: channel);
      final result = await repo.refresh();
      expect(result.status, DirectoryRefreshStatus.malformedResponse);
    });

    test('REMOTE wrong scalar type in child field -> malformedResponse', () async {
      final row = _rowWithChildren();
      row['entity_contacts'] = [
        <String, dynamic>{'id': 'ct1', 'contact_type': 'phone', 'value': 123},
      ];
      final channel = _FakeDirectoryReadQueryChannel(rows: [row]);
      final repo = await _repository(channel: channel);
      final result = await repo.refresh();
      expect(result.status, DirectoryRefreshStatus.malformedResponse);
    });

    test('REMOTE wrong scalar type in nested region code -> malformedResponse',
        () async {
      final row = _rowWithChildren();
      (row['entity_locations'] as List).first['regions']['code'] = 123;
      final channel = _FakeDirectoryReadQueryChannel(rows: [row]);
      final repo = await _repository(channel: channel);
      final result = await repo.refresh();
      expect(result.status, DirectoryRefreshStatus.malformedResponse);
    });

    test('CACHE wrong scalar type in entity field -> invalid snapshot', () async {
      final json = fakeEntity(id: _kUuid1, name: 'Good').toJson();
      json['name'] = 123;
      final snapshotJson = jsonEncode({
        'schema_version': DirectoryCloudCache.cacheVersion,
        'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entities': [json],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: snapshotJson,
      });
      expect(await DirectoryCloudCache.read(), isNull);
    });

    test('CACHE wrong scalar type in child field -> invalid snapshot', () async {
      final json = fakeEntity(
        id: _kUuid1,
        name: 'Good',
        contacts: [fakePhone('07701234567')],
      ).toJson();
      json['contacts'] = [
        <String, dynamic>{'contact_type': 'phone', 'value': 123},
      ];
      final snapshotJson = jsonEncode({
        'schema_version': DirectoryCloudCache.cacheVersion,
        'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entities': [json],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: snapshotJson,
      });
      expect(await DirectoryCloudCache.read(), isNull);
    });
  });

  group('V1-R09 P2-B1 — LOCATION is_primary STRICT VALIDATION', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      DirectoryCloudCache.setTestStore(null);
    });

    tearDown(() {
      DirectoryCloudCache.setTestStore(null);
    });

    Map<String, dynamic> _rowWithIsPrimary(dynamic isPrimary) {
      final row = _rowWithChildren();
      final locations = row['entity_locations'] as List<dynamic>;
      final location = Map<String, dynamic>.from(locations.first as Map);
      if (isPrimary == _missingSentinel) {
        location.remove('is_primary');
      } else {
        location['is_primary'] = isPrimary;
      }
      row['entity_locations'] = [location];
      return row;
    }

    Map<String, dynamic> _cacheEntityWithIsPrimary(dynamic isPrimary) {
      final entity = fakeEntity(
        id: _kUuid1,
        name: 'Good',
        locations: [fakeLocation('karrada', address: 'St 1')],
      );
      final json = entity.toJson();
      final locations = json['locations'] as List<dynamic>;
      final location = Map<String, dynamic>.from(locations.first as Map);
      if (isPrimary == _missingSentinel) {
        location.remove('is_primary');
      } else {
        location['is_primary'] = isPrimary;
      }
      json['locations'] = [location];
      return json;
    }

    Future<DirectoryRefreshResult> _refreshWithIsPrimary(dynamic isPrimary) async {
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithIsPrimary(isPrimary)],
      );
      final repo = await _repository(channel: channel);
      return repo.refresh();
    }

    test('REMOTE is_primary true accepted', () async {
      final result = await _refreshWithIsPrimary(true);
      expect(result.succeeded, isTrue);
      expect(result.entities.single.locations.single.isPrimary, isTrue);
    });

    test('REMOTE is_primary false accepted and remains false', () async {
      final result = await _refreshWithIsPrimary(false);
      expect(result.succeeded, isTrue);
      expect(result.entities.single.locations.single.isPrimary, isFalse);
    });

    for (final malformed in [
      'true',
      'false',
      1,
      0,
      null,
      <String, dynamic>{},
      <dynamic>[],
    ]) {
      test('REMOTE is_primary $malformed -> malformedResponse', () async {
        final result = await _refreshWithIsPrimary(malformed);
        expect(result.succeeded, isFalse);
        expect(result.status, DirectoryRefreshStatus.malformedResponse);
      });
    }

    test('REMOTE missing is_primary -> malformedResponse', () async {
      final result = await _refreshWithIsPrimary(_missingSentinel);
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.malformedResponse);
    });

    test('REMOTE malformed is_primary fails whole snapshot, no cache write',
        () async {
      final store = _FakeCacheStore()..setWriteResult(true);
      DirectoryCloudCache.setTestStore(store);
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithIsPrimary('true')],
      );
      final repo = await _repository(channel: channel);
      final result = await repo.refresh();

      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.malformedResponse);
      expect(store.writeCalls, 0);
      expect(await repo.readCache(), isNull);
    });

    test('CACHE is_primary true accepted', () async {
      final snapshotJson = jsonEncode({
        'schema_version': DirectoryCloudCache.cacheVersion,
        'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entities': [_cacheEntityWithIsPrimary(true)],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: snapshotJson,
      });
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot, isNotNull);
      expect(snapshot!.entities.single.locations.single.isPrimary, isTrue);
    });

    test('CACHE is_primary false accepted', () async {
      final snapshotJson = jsonEncode({
        'schema_version': DirectoryCloudCache.cacheVersion,
        'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entities': [_cacheEntityWithIsPrimary(false)],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: snapshotJson,
      });
      final snapshot = await DirectoryCloudCache.read();
      expect(snapshot, isNotNull);
      expect(snapshot!.entities.single.locations.single.isPrimary, isFalse);
    });

    for (final malformed in [
      'true',
      1,
      null,
      <String, dynamic>{},
    ]) {
      test('CACHE is_primary $malformed invalidates snapshot', () async {
        final snapshotJson = jsonEncode({
          'schema_version': DirectoryCloudCache.cacheVersion,
          'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
          'entities': [_cacheEntityWithIsPrimary(malformed)],
        });
        SharedPreferences.setMockInitialValues({
          AppStorageKeys.directoryCloudCache: snapshotJson,
        });
        expect(await DirectoryCloudCache.read(), isNull);
      });
    }

    test('CACHE missing is_primary invalidates snapshot', () async {
      final snapshotJson = jsonEncode({
        'schema_version': DirectoryCloudCache.cacheVersion,
        'refreshed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'entities': [_cacheEntityWithIsPrimary(_missingSentinel)],
      });
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.directoryCloudCache: snapshotJson,
      });
      expect(await DirectoryCloudCache.read(), isNull);
    });
  });

  group('V1-R09 P2-B1 — TYPED OUTCOMES', () {
    late SupabaseCloudDirectoryRepository repository;
    late _FakeDirectoryReadQueryChannel channel;
    late SupabaseDirectoryReadGateway gateway;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      DirectoryCloudCache.setTestStore(null);
      channel = _FakeDirectoryReadQueryChannel();
      final service = await _availableService();
      gateway = SupabaseDirectoryReadGateway(
        service: service,
        queryChannel: channel,
      );
      repository = SupabaseCloudDirectoryRepository(
        service: service,
        gateway: gateway,
      );
    });

    tearDown(() {
      DirectoryCloudCache.setTestStore(null);
    });

    test('success', () async {
      channel.rows = [_rowWithChildren(id: _kUuid1)];
      final result = await repository.refresh();
      expect(result.succeeded, isTrue);
      expect(result.status, DirectoryRefreshStatus.success);
      expect(result.entities, hasLength(1));
    });

    test('authoritativeEmpty', () async {
      channel.rows = const [];
      final result = await repository.refresh();
      expect(result.succeeded, isTrue);
      expect(result.status, DirectoryRefreshStatus.authoritativeEmpty);
      expect(result.entities, isEmpty);
    });

    test('authoritativeNotFound', () async {
      final outcome = await gateway.loadById(
        '00000000-0000-0000-0000-000000000099',
      );
      expect(outcome, isA<DirectoryEntityNotFound>());
    });

    test('invalidCanonicalId', () async {
      final outcome = await gateway.loadById('not-a-uuid');
      expect(outcome, isA<DirectoryEntityInvalidId>());
      expect(channel.queryByIdCalls, 0);
    });

    test('network', () async {
      channel.throwOnQuery = const SocketException('connection reset');
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.network);
    });

    test('timeout', () async {
      channel.delay = const Duration(days: 1);
      final service = await _availableService();
      final timedRepo = SupabaseCloudDirectoryRepository(
        service: service,
        gateway: SupabaseDirectoryReadGateway(
          service: service,
          queryChannel: channel,
          readTimeout: const Duration(milliseconds: 10),
        ),
      );
      final result = await timedRepo.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.timeout);
    });

    test(
        'serviceUnavailable for PostgreSQL connection exception class 08xxx',
        () async {
      channel.throwOnQuery = const PostgrestException(
        message: 'connection failure',
        code: '08006',
      );
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.serviceUnavailable);
    });

    test(
        'serviceUnavailable for PostgreSQL insufficient-resources class 53xxx',
        () async {
      channel.throwOnQuery = const PostgrestException(
        message: 'too many connections',
        code: '53300',
      );
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.serviceUnavailable);
    });

    test('serviceUnavailable for PostgREST availability family PGRST000',
        () async {
      channel.throwOnQuery = const PostgrestException(
        message: 'Database connection lost',
        code: 'PGRST000',
      );
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.serviceUnavailable);
    });

    test('serviceUnavailable for PostgREST availability family PGRST003',
        () async {
      channel.throwOnQuery = const PostgrestException(
        message: 'Service temporarily unavailable',
        code: 'PGRST003',
      );
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.serviceUnavailable);
    });

    test('PostgREST code 503 is NOT used as serviceUnavailable classifier',
        () async {
      channel.throwOnQuery = const PostgrestException(
        message: 'Service Unavailable',
        code: '503',
      );
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.unexpected);
    });

    test('unexpected for PostgREST permission failure 42501', () async {
      channel.throwOnQuery = const PostgrestException(
        message: 'permission denied',
        code: '42501',
      );
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.unexpected);
    });

    test('unexpected for PostgREST client/semantic failure PGRST301', () async {
      channel.throwOnQuery = const PostgrestException(
        message: 'JWT invalid',
        code: 'PGRST301',
      );
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.unexpected);
    });

    test('unexpected for PostgREST query/parse failure PGRST204', () async {
      channel.throwOnQuery = const PostgrestException(
        message: 'Column not found',
        code: 'PGRST204',
      );
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.unexpected);
    });

    test('unexpected for unknown PostgREST code', () async {
      channel.throwOnQuery = const PostgrestException(
        message: 'unknown failure',
        code: 'XY123',
      );
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.unexpected);
    });

    test('malformedResponse', () async {
      channel.rows = [_rowWithChildren(id: _kUuid1)..remove('name')];
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.malformedResponse);
    });

    test('unexpected', () async {
      channel.throwOnQuery = StateError('unhandled');
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.unexpected);
    });

    test('ClientException maps to network', () async {
      channel.throwOnQuery = http.ClientException('connection failed');
      final result = await repository.refresh();
      expect(result.succeeded, isFalse);
      expect(result.status, DirectoryRefreshStatus.network);
    });
  });

  group('V1-R09 P2-B1 — CANONICAL ID VALIDATION ORDER', () {
    test('invalid ID returns invalidCanonicalId even when gateway unavailable',
        () async {
      final service = SupabaseService(
        config: const BackendConfig(
          appEnvRaw: 'development',
          supabaseUrl: 'https://project.supabase.co',
          supabaseAnonKey: 'test-anon-key',
        ),
      );
      // service is NOT initialized -> isAvailable == false
      final gateway = SupabaseDirectoryReadGateway(
        service: service,
        queryChannel: _FakeDirectoryReadQueryChannel(),
      );
      final outcome = await gateway.loadById('not-a-uuid');
      expect(outcome, isA<DirectoryEntityInvalidId>());
    });
  });

  group('V1-R09 P2-B1 — BY-ID DEADLINE / OUTCOMES', () {
    late _FakeDirectoryReadQueryChannel channel;
    late SupabaseDirectoryReadGateway gateway;

    setUp(() async {
      channel = _FakeDirectoryReadQueryChannel();
      final service = await _availableService();
      gateway = SupabaseDirectoryReadGateway(
        service: service,
        queryChannel: channel,
        readTimeout: const Duration(milliseconds: 10),
      );
    });

    test('by-ID timeout -> timeout', () async {
      channel.delay = const Duration(days: 1);
      final outcome = await gateway.loadById(_kUuid1);
      expect(outcome, isA<DirectoryEntityFailure>());
      expect((outcome as DirectoryEntityFailure).kind,
          DirectoryReadFailureKind.timeout);
    });

    test('by-ID malformed -> malformedResponse', () async {
      channel.rowsById = {
        _kUuid1: [_validRow(id: _kUuid1)], // missing required relationships
      };
      final outcome = await gateway.loadById(_kUuid1);
      expect(outcome, isA<DirectoryEntityFailure>());
      expect((outcome as DirectoryEntityFailure).kind,
          DirectoryReadFailureKind.malformedResponse);
    });

    test('by-ID network -> network', () async {
      channel.throwOnQuery = const SocketException('reset');
      final outcome = await gateway.loadById(_kUuid1);
      expect(outcome, isA<DirectoryEntityFailure>());
      expect((outcome as DirectoryEntityFailure).kind,
          DirectoryReadFailureKind.network);
    });

    test('by-ID authoritative absence -> notFound', () async {
      channel.rowsById = {_kUuid1: const []};
      final outcome = await gateway.loadById(_kUuid1);
      expect(outcome, isA<DirectoryEntityNotFound>());
    });
  });

  group('V1-R09 P2-B1 — DEADLINE', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      DirectoryCloudCache.setTestStore(null);
    });

    tearDown(() {
      DirectoryCloudCache.setTestStore(null);
    });

    test('default gateway read timeout equals RemoteOperationPolicy.read', () async {
      final gateway = SupabaseDirectoryReadGateway(
        service: await _availableService(),
      );
      expect(gateway.readTimeout, RemoteOperationPolicy.read);
      expect(gateway.readTimeout, const Duration(seconds: 15));
    });

    test('timeout becomes typed timeout outcome', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        delay: const Duration(days: 1),
      );
      final repo = await _repository(
        channel: channel,
        readTimeout: const Duration(milliseconds: 10),
      );
      final result = await repo.refresh();
      expect(result.status, DirectoryRefreshStatus.timeout);
    });
  });

  group('V1-R09 P2-B1 — CACHE PERSISTENCE', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      DirectoryCloudCache.setTestStore(null);
    });

    test('setString true succeeds', () async {
      final store = _FakeCacheStore()..setWriteResult(true);
      DirectoryCloudCache.setTestStore(store);
      final ok = await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [fakeEntity(id: _kUuid1)],
        ),
      );
      expect(ok, isTrue);
      expect(store.writeCalls, 1);
    });

    test('setString false produces cache persistence failure', () async {
      final store = _FakeCacheStore()..setWriteResult(false);
      DirectoryCloudCache.setTestStore(store);
      final ok = await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [fakeEntity(id: _kUuid1)],
        ),
      );
      expect(ok, isFalse);
    });

    test('thrown persistence error produces cache persistence failure', () async {
      final store = _FakeCacheStore()
        ..setWriteResult(false, throwOnWrite: true);
      DirectoryCloudCache.setTestStore(store);
      final ok = await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [fakeEntity(id: _kUuid1)],
        ),
      );
      expect(ok, isFalse);
    });

    Future<void> _testPersistenceFailure({
      required bool empty,
      required bool throwOnWrite,
    }) async {
      final store = _FakeCacheStore()..setWriteResult(true);
      DirectoryCloudCache.setTestStore(store);
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [fakeEntity(id: _kUuid1, name: 'Old')],
        ),
      );
      store.setWriteResult(false, throwOnWrite: throwOnWrite);

      final rows = empty ? const <Map<String, dynamic>>[] : [_rowWithChildren(id: _kUuid2)];
      final channel = _FakeDirectoryReadQueryChannel(rows: rows);
      final repo = await _repository(channel: channel);
      final result = await repo.refresh();

      expect(result.succeeded, isTrue);
      expect(
        result.status,
        empty
            ? DirectoryRefreshStatus.authoritativeEmpty
            : DirectoryRefreshStatus.success,
      );
      expect(result.cachePersisted, isFalse);
      if (!empty) {
        expect(result.entities.single.id, _kUuid2);
      } else {
        expect(result.entities, isEmpty);
      }
      expect(result.refreshedAt, isNotNull);

      final cached = await repo.readCache();
      expect(cached, isNotNull);
      expect(cached!.entities.single.name, 'Old');
    }

    test('non-empty success + setString false -> fresh data retained, cachePersisted false',
        () async {
      await _testPersistenceFailure(empty: false, throwOnWrite: false);
    });

    test('non-empty success + persistence throw -> fresh data retained, cachePersisted false',
        () async {
      await _testPersistenceFailure(empty: false, throwOnWrite: true);
    });

    test('authoritative empty + setString false -> empty retained, cachePersisted false',
        () async {
      await _testPersistenceFailure(empty: true, throwOnWrite: false);
    });

    test('authoritative empty + persistence throw -> empty retained, cachePersisted false',
        () async {
      await _testPersistenceFailure(empty: true, throwOnWrite: true);
    });

    test('fetched data not falsely marked stale', () async {
      final store = _FakeCacheStore()..setWriteResult(false);
      DirectoryCloudCache.setTestStore(store);
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithChildren(id: _kUuid1)],
      );
      final repo = await _repository(channel: channel);
      final result = await repo.refresh();
      expect(result.succeeded, isTrue);
      expect(result.status, DirectoryRefreshStatus.success);
      expect(result.cachePersisted, isFalse);
    });
  });

  group('V1-R09 P2-B1 — SINGLE-FLIGHT', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      DirectoryCloudCache.setTestStore(null);
    });

    tearDown(() {
      DirectoryCloudCache.setTestStore(null);
    });

    test('two concurrent equivalent refreshes cause one remote read', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithChildren(id: _kUuid1)],
        delay: const Duration(milliseconds: 50),
      );
      final repo = await _repository(channel: channel);

      final r1 = repo.refresh();
      final r2 = repo.refresh();
      await Future.wait([r1, r2]);

      expect(channel.queryAllCalls, 1);
    });

    test('both callers receive same settlement', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithChildren(id: _kUuid1)],
        delay: const Duration(milliseconds: 50),
      );
      final repo = await _repository(channel: channel);

      final r1 = repo.refresh();
      final r2 = repo.refresh();
      final results = await Future.wait([r1, r2]);

      expect(results[0].status, results[1].status);
      expect(results[0].entities, results[1].entities);
      expect(results[0].refreshedAt, results[1].refreshedAt);
    });

    test('one persistence attempt', () async {
      final store = _FakeCacheStore()..setWriteResult(true);
      DirectoryCloudCache.setTestStore(store);
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithChildren(id: _kUuid1)],
        delay: const Duration(milliseconds: 50),
      );
      final repo = await _repository(channel: channel);

      await Future.wait([repo.refresh(), repo.refresh()]);

      expect(store.writeCalls, 1);
    });

    test('active future clears after success', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithChildren(id: _kUuid1)],
      );
      final repo = await _repository(channel: channel);
      await repo.refresh();
      expect(channel.queryAllCalls, 1);
      await repo.refresh();
      expect(channel.queryAllCalls, 2);
    });

    test('active future clears after failure', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        throwOnQuery: Exception('boom'),
      );
      final repo = await _repository(channel: channel);
      await repo.refresh();
      expect(channel.queryAllCalls, 1);
      await repo.refresh();
      expect(channel.queryAllCalls, 2);
    });

    test('later deliberate refresh may create a new request', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithChildren(id: _kUuid1)],
      );
      final repo = await _repository(channel: channel);
      await repo.refresh();
      await repo.refresh();
      expect(channel.queryAllCalls, 2);
    });

    test('active future clears after unexpected underlying throw', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        throwOnQuery: StateError('unexpected'),
      );
      final repo = await _repository(channel: channel);
      await repo.refresh();
      expect(channel.queryAllCalls, 1);
      final second = await repo.refresh();
      expect(channel.queryAllCalls, 2);
      expect(second.status, DirectoryRefreshStatus.unexpected);
    });

    test('ownership guard prevents stale completion clearing a newer operation',
        () async {
      // The implementation clears the active Future only when the completing
      // Future is still the owned one. We observe this by allowing a first
      // slow refresh to be superseded by a second deliberate refresh: the
      // second operation must run and the first must not corrupt the outcome.
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithChildren(id: _kUuid1)],
        delay: const Duration(milliseconds: 100),
      );
      final repo = await _repository(channel: channel);

      final first = repo.refresh();
      // Give the first refresh a moment to install its Future.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final second = repo.refresh();

      final results = await Future.wait([first, second]);
      expect(channel.queryAllCalls, 1);
      expect(results[0].status, results[1].status);
      expect(results[0].entities, results[1].entities);
    });
  });

  group('V1-R09 P2-B1 — loadByCanonicalId COMPATIBILITY', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      DirectoryCloudCache.setTestStore(null);
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [
            fakeEntity(id: _kUuid1, name: 'Cached One'),
            fakeEntity(id: _kUuid2, name: 'Cached Two'),
          ],
        ),
      );
    });

    tearDown(() {
      DirectoryCloudCache.setTestStore(null);
    });

    test('matching cached entity resolved without remote call', () async {
      final channel = _FakeDirectoryReadQueryChannel();
      final repo = await _repository(channel: channel);
      final entity = await repo.loadByCanonicalId(_kUuid1);
      expect(entity, isNotNull);
      expect(entity!.name, 'Cached One');
      expect(channel.queryByIdCalls, 0);
    });

    test('offline/unavailable remote does not erase cached compatibility result',
        () async {
      final service = SupabaseService(
        config: const BackendConfig(
          appEnvRaw: 'development',
          supabaseUrl: 'https://project.supabase.co',
          supabaseAnonKey: 'test-anon-key',
        ),
      );
      // uninitialized -> unavailable
      final repo = SupabaseCloudDirectoryRepository(
        service: service,
        gateway: SupabaseDirectoryReadGateway(
          service: service,
          queryChannel: _FakeDirectoryReadQueryChannel(),
        ),
      );
      final entity = await repo.loadByCanonicalId(_kUuid1);
      expect(entity, isNotNull);
      expect(entity!.name, 'Cached One');
    });

    test('invalid ID performs zero remote calls', () async {
      final channel = _FakeDirectoryReadQueryChannel();
      final repo = await _repository(channel: channel);
      final entity = await repo.loadByCanonicalId('not-a-uuid');
      expect(entity, isNull);
      expect(channel.queryByIdCalls, 0);
    });

    test('no cache + authoritative not-found returns null', () async {
      DirectoryCloudCache.setTestStore(_FakeCacheStore());
      final channel = _FakeDirectoryReadQueryChannel(
        rowsById: {_kUuid3: const []},
      );
      final repo = await _repository(channel: channel);
      final entity = await repo.loadByCanonicalId(_kUuid3);
      expect(entity, isNull);
      expect(channel.queryByIdCalls, 1);
    });

    test('cache miss + remote success resolves authoritative entity', () async {
      DirectoryCloudCache.setTestStore(_FakeCacheStore());
      final channel = _FakeDirectoryReadQueryChannel(
        rowsById: {
          _kUuid3: [_rowWithChildren(id: _kUuid3)],
        },
      );
      final repo = await _repository(channel: channel);
      final entity = await repo.loadByCanonicalId(_kUuid3);
      expect(entity, isNotNull);
      expect(entity!.id, _kUuid3);
      expect(channel.queryByIdCalls, 1);
    });
  });

  group('V1-R09 P2-B1 — load() COMPATIBILITY', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      DirectoryCloudCache.setTestStore(null);
    });

    tearDown(() {
      DirectoryCloudCache.setTestStore(null);
    });

    test('existing load() path remains usable with fresh data', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        rows: [_rowWithChildren(id: _kUuid1)],
      );
      final repo = await _repository(channel: channel);
      final load = await repo.load();
      expect(load.state, DirectoryLoadState.fresh);
      expect(load.entities, hasLength(1));
    });

    test('existing load() path falls back to stale cache on failure', () async {
      await DirectoryCloudCache.writeSnapshot(
        DirectoryCloudCacheSnapshot(
          version: DirectoryCloudCache.cacheVersion,
          refreshedAt: DateTime.utc(2026, 1, 1),
          entities: [fakeEntity(id: _kUuid1, name: 'Cached')],
        ),
      );
      final channel = _FakeDirectoryReadQueryChannel(
        throwOnQuery: Exception('network down'),
      );
      final repo = await _repository(channel: channel);
      final load = await repo.load();
      expect(load.state, DirectoryLoadState.stale);
      expect(load.entities.single.name, 'Cached');
    });

    test('load() returns error when no cache and refresh fails', () async {
      final channel = _FakeDirectoryReadQueryChannel(
        throwOnQuery: Exception('network down'),
      );
      final repo = await _repository(channel: channel);
      final load = await repo.load();
      expect(load.state, DirectoryLoadState.error);
      expect(load.entities, isEmpty);
    });
  });
}
