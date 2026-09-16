import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:civilpedia/core/widgets/remote_data_notice.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/features/directory/application/directory_detail_controller.dart';
import 'package:civilpedia/features/directory/application/directory_refresh_controller.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/saved/domain/saved_item_reference.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_resolver.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_store.dart';
import 'package:civilpedia/features/saved/presentation/saved_screen.dart';
import 'package:civilpedia/localization/ar.dart';

import 'helpers/canonical_directory_test_helpers.dart';

// ── Fake transport source (same seam as the P2-A shared UX suite) ──

class _FakeTransportSource implements TransportSource {
  _FakeTransportSource(Future<bool> Function() check) : _check = check {
    changes = StreamController<bool>.broadcast(sync: true);
  }

  final Future<bool> Function() _check;
  late final StreamController<bool> changes;

  @override
  Future<bool> checkAvailability() => _check();

  @override
  Stream<bool> get availabilityChanges => changes.stream;

  Future<void> close() => changes.close();
}

// ── Fully scriptable Directory repository ──

class _ScriptedDirectoryRepository implements CloudDirectoryRepository {
  DirectoryCachedData? cached;
  final List<DirectoryRefreshResult> refreshResults = [];
  Completer<void>? refreshGate;
  Completer<void>? readCacheGate;
  int readCacheCalls = 0;
  int refreshCalls = 0;
  bool unavailable = false;

  @override
  bool get isAvailable => !unavailable;

  @override
  Future<DirectoryCachedData?> readCache() async {
    readCacheCalls++;
    final gate = readCacheGate;
    if (gate != null) {
      await gate.future;
      readCacheGate = null;
    }
    return cached;
  }

  @override
  Future<DirectoryRefreshResult> refresh() async {
    refreshCalls++;
    final gate = refreshGate;
    if (gate != null) {
      await gate.future;
      refreshGate = null;
    }
    if (refreshResults.isEmpty) {
      return const DirectoryRefreshResult(status: DirectoryRefreshStatus.success);
    }
    return refreshResults.removeAt(0);
  }

  @override
  Future<CanonicalDirectoryEntity?> loadByCanonicalId(String id) async {
    final fromCache = cached?.byId(id);
    if (fromCache != null) return fromCache;
    for (final result in refreshResults) {
      for (final entity in result.entities) {
        if (entity.id == id) return entity;
      }
    }
    return null;
  }

  @override
  Future<DirectoryLoadResult> load() async {
    if (unavailable || refreshResults.isEmpty) {
      return const DirectoryLoadResult(state: DirectoryLoadState.error);
    }
    final result = refreshResults.last;
    return DirectoryLoadResult(
      state: DirectoryLoadState.fresh,
      entities: List<CanonicalDirectoryEntity>.from(result.entities),
      refreshedAt: result.refreshedAt,
    );
  }
}

// ── Entity / result factories ──

String _uuid(int n) => '00000000-0000-0000-0000-${n.toString().padLeft(12, '0')}';

CanonicalDirectoryEntity _entity(String id, {String name = '', String entityType = 'supplier'}) {
  return fakeEntity(
    id: id,
    name: name.isEmpty ? 'Entity ${id.substring(0, 4)}' : name,
    entityType: entityType,
  );
}

DirectoryRefreshResult _success(
  List<CanonicalDirectoryEntity> entities, {
  DateTime? refreshedAt,
  bool cachePersisted = true,
}) {
  return DirectoryRefreshResult(
    status: DirectoryRefreshStatus.success,
    entities: List<CanonicalDirectoryEntity>.from(entities),
    refreshedAt: refreshedAt ?? DateTime.utc(2026, 9, 1),
    cachePersisted: cachePersisted,
  );
}

DirectoryRefreshResult _empty() {
  return DirectoryRefreshResult(
    status: DirectoryRefreshStatus.authoritativeEmpty,
    entities: const [],
    refreshedAt: DateTime.utc(2026, 9, 1),
  );
}

DirectoryRefreshResult _failure(DirectoryRefreshStatus status) {
  return DirectoryRefreshResult(status: status);
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  throw StateError('Condition not reached.');
}

Future<ConnectivityProvider> _connectivity(_FakeTransportSource source) async {
  final provider = ConnectivityProvider(
    source: source,
    initialCheckTimeout: const Duration(seconds: 1),
  );
  await provider.initialization;
  return provider;
}

// ── Saved widget harness (mirrors w5_6) ──

class _FakeSavedStore implements SavedReferenceStore {
  final List<SavedItemReference> refs;
  _FakeSavedStore([List<SavedItemReference> seed = const []]) : refs = List.of(seed);

  @override
  Future<List<SavedItemReference>> loadAll() async => List.of(refs);
  @override
  Future<bool> contains(String referenceId) async =>
      refs.any((r) => r.id == referenceId);
  @override
  Future<void> save(SavedItemReference reference) async {
    if (!refs.any((r) => r.id == reference.id)) refs.add(reference);
  }

  @override
  Future<void> remove(String referenceId) async {
    refs.removeWhere((r) => r.id == referenceId);
  }
}

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  final List<EngineeringTopic> topics;
  _FakeEncyclopediaRepository([this.topics = const []]);

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async => topics;
  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
  @override
  Future<List<EngineeringTopic>> getAllTopics() async => topics;
  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async => const [];
  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];
  @override
  Future<Map<String, CategoryInfo>> getCategories() async =>
      const <String, CategoryInfo>{};
}

SavedItemReference _dirRef(String id) => SavedItemReference(
  ownerDomain: SavedReferenceOwners.directory,
  entityType: SavedReferenceEntityTypes.provider,
  entityId: id,
  savedAt: DateTime.utc(2026, 8, 1),
);

Future<SavedReferenceResolver> _buildResolver(SavedReferenceStore store) async {
  return SavedReferenceResolver(
    encyclopediaTopicIds: () async => const [],
    legacyArticleIds: () async => const [],
    structuredReferences: () async => store.loadAll(),
  );
}

Future<void> _pumpSaved(
  WidgetTester tester, {
  required CloudDirectoryRepository directoryRepo,
  required SavedReferenceStore store,
}) async {
  final favorites = EncyclopediaFavoritesProvider();
  await favorites.load();
  final resolver = await _buildResolver(store);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) => EncyclopediaProvider(
            repository: _FakeEncyclopediaRepository(),
          ),
        ),
        ChangeNotifierProvider.value(value: favorites),
      ],
      child: MaterialApp.router(
        routerConfig: canonicalDirectoryDetailRouter(
          home: SavedScreen(
            favoritesResolver: resolver,
            directoryRepository: directoryRepo,
            savedReferenceStore: store,
          ),
          repository: directoryRepo,
          savedReferenceStore: store,
        ),
      ),
    ),
  );
}

void main() {
  group('V1-R09 P2-B2 Directory UX — Detail controller', () {
    test('seed entity paints the stale first frame before authority settles', () async {
      final id = _uuid(1);
      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_success([_entity(id, name: 'Authoritative')]));
      final controller = DirectoryDetailController(
        repository: repo,
        entityId: id,
        seedEntity: _entity(id, name: 'Seed'),
      );
      // The seed block runs synchronously in the constructor: stale + seed.
      expect(controller.state, DirectoryDetailState.stale);
      expect(controller.entity?.name, 'Seed');
      expect(controller.isLoading, isTrue);

      await _waitUntil(() => controller.isLoading == false);
      expect(controller.state, DirectoryDetailState.fresh);
      expect(controller.entity?.name, 'Authoritative');
      controller.dispose();
    });

    test('cache wins over seed (cache-first authority)', () async {
      final id = _uuid(1);
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: [_entity(id, name: 'Cached')],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.refreshResults.add(
        _failure(DirectoryRefreshStatus.network),
      );
      final controller = DirectoryDetailController(
        repository: repo,
        entityId: id,
        seedEntity: _entity(id, name: 'Seed'),
      );
      expect(controller.entity?.name, 'Seed');

      await _waitUntil(() => controller.isLoading == false);
      expect(controller.entity?.name, 'Cached');
      expect(controller.state, DirectoryDetailState.stale);
      expect(controller.cause, RemoteDataCause.network);
      await _waitUntil(() => controller.isLoading == false);
      controller.dispose();
    });

    for (final entry in <(DirectoryRefreshStatus, RemoteDataCause)>[
      (DirectoryRefreshStatus.network, RemoteDataCause.network),
      (DirectoryRefreshStatus.timeout, RemoteDataCause.timeout),
      (DirectoryRefreshStatus.serviceUnavailable, RemoteDataCause.serviceUnavailable),
    ]) {
      test('stale entity retained with ${entry.$1.name} failure', () async {
        final id = _uuid(1);
        final repo = _ScriptedDirectoryRepository();
        repo.cached = DirectoryCachedData(
          entities: [_entity(id, name: 'Cached')],
          refreshedAt: DateTime.utc(2026, 9, 1),
        );
        repo.refreshResults.add(_failure(entry.$1));
        final controller = DirectoryDetailController(
          repository: repo,
          entityId: id,
        );
        await _waitUntil(() => controller.isLoading == false);
        expect(controller.entity?.name, 'Cached');
        expect(controller.state, DirectoryDetailState.stale);
        expect(controller.cause, entry.$2);
        controller.dispose();
      });
    }

    test('malformed response maps to malformed and stays stale', () async {
      final id = _uuid(1);
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: [_entity(id, name: 'Cached')],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.refreshResults.add(
        _failure(DirectoryRefreshStatus.malformedResponse),
      );
      final controller = DirectoryDetailController(repository: repo, entityId: id);
      await _waitUntil(() => controller.isLoading == false);
      expect(controller.state, DirectoryDetailState.stale);
      expect(controller.cause, RemoteDataCause.malformed);

      // Manual retry is allowed for malformed (explicit idempotent reload).
      repo.refreshCalls = 0;
      controller.retry();
      await _waitUntil(() => controller.isLoading == false);
      expect(repo.refreshCalls, 1);
      controller.dispose();
    });

    test('authoritative notFound state for a valid absent UUID', () async {
      final id = _uuid(1);
      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_success([_entity(_uuid(2), name: 'Other')]));
      final controller = DirectoryDetailController(repository: repo, entityId: id);
      await _waitUntil(() => controller.isLoading == false);
      expect(controller.state, DirectoryDetailState.notFound);
      expect(controller.entity, isNull);
      controller.dispose();
    });

    test('authoritative empty maps to notFound for the requested id', () async {
      final id = _uuid(1);
      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_empty());
      final controller = DirectoryDetailController(repository: repo, entityId: id);
      await _waitUntil(() => controller.isLoading == false);
      expect(controller.state, DirectoryDetailState.notFound);
      controller.dispose();
    });

    test('invalid canonical id makes zero cache/refresh requests', () async {
      final repo = _ScriptedDirectoryRepository();
      final controller = DirectoryDetailController(
        repository: repo,
        entityId: 'not-a-uuid',
      );
      // The invalid-id branch runs synchronously in the constructor.
      expect(controller.state, DirectoryDetailState.invalidId);
      expect(controller.isLoading, isFalse);
      expect(repo.readCacheCalls, 0);
      expect(repo.refreshCalls, 0);
      controller.dispose();
    });

    test('authoritative result stays fresh even when cache write fails', () async {
      final id = _uuid(1);
      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(
        _success([_entity(id, name: 'Fresh')], cachePersisted: false),
      );
      final controller = DirectoryDetailController(repository: repo, entityId: id);
      await _waitUntil(() => controller.isLoading == false);
      expect(controller.state, DirectoryDetailState.fresh);
      expect(controller.entity?.name, 'Fresh');
      expect(controller.cause, isNull);
      controller.dispose();
    });

    test('in-flight refresh coalesces overlapping attempts (epoch guard)', () async {
      final id = _uuid(1);
      final gate = Completer<void>();
      final repo = _ScriptedDirectoryRepository();
      repo.refreshGate = gate;
      repo.refreshResults.add(_success([_entity(id, name: 'Alpha')]));
      final controller = DirectoryDetailController(repository: repo, entityId: id);

      await _waitUntil(() => repo.refreshCalls == 1);
      expect(controller.isLoading, isTrue);

      // A retry while loading must not start a second refresh.
      controller.retry();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshCalls, 1);

      gate.complete();
      await _waitUntil(() => controller.isLoading == false);
      expect(repo.refreshCalls, 1);
      expect(controller.state, DirectoryDetailState.fresh);
      controller.dispose();
    });

    test('reconnect eligible: transport recovery triggers exactly one refresh', () async {
      final id = _uuid(1);
      final source = _FakeTransportSource(() async => false);
      final connectivity = await _connectivity(source);
      addTearDown(source.close);
      addTearDown(connectivity.dispose);

      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      repo.refreshResults.add(_success([_entity(id, name: 'Recovered')]));
      final controller = DirectoryDetailController(
        repository: repo,
        entityId: id,
        connectivity: connectivity,
      );
      addTearDown(controller.dispose);

      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 1);
      // Transport is confirmed unavailable -> network becomes offline.
      expect(controller.cause, RemoteDataCause.offline);
      expect(controller.state, DirectoryDetailState.unresolved);

      source.changes.add(true); // unavailable -> available: generation 1
      await _waitUntil(() => repo.refreshCalls == 2);
      await _waitUntil(() => controller.isLoading == false);
      expect(controller.state, DirectoryDetailState.fresh);
      expect(controller.entity?.name, 'Recovered');
      expect(controller.cause, isNull);
    });

    test('same-generation events are ignored; only recovery claims a refresh', () async {
      final id = _uuid(1);
      final source = _FakeTransportSource(() async => true);
      final connectivity = await _connectivity(source);
      addTearDown(source.close);
      addTearDown(connectivity.dispose);

      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      final controller = DirectoryDetailController(
        repository: repo,
        entityId: id,
        connectivity: connectivity,
      );
      addTearDown(controller.dispose);

      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 1);
      expect(controller.cause, RemoteDataCause.network);

      // available -> unavailable keeps the same generation (0): ignored.
      source.changes.add(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshCalls, 1);

      // unavailable -> available bumps to generation 1: exactly one refresh.
      source.changes.add(true);
      await _waitUntil(() => repo.refreshCalls == 2);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshCalls, 2);
      expect(controller.cause, RemoteDataCause.network);
    });

    test('reconnect does not fire when the cause is not transport-like (malformed)', () async {
      final id = _uuid(1);
      final source = _FakeTransportSource(() async => false);
      final connectivity = await _connectivity(source);
      addTearDown(source.close);
      addTearDown(connectivity.dispose);

      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(
        _failure(DirectoryRefreshStatus.malformedResponse),
      );
      final controller = DirectoryDetailController(
        repository: repo,
        entityId: id,
        connectivity: connectivity,
      );
      addTearDown(controller.dispose);

      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 1);
      expect(controller.cause, RemoteDataCause.malformed);

      source.changes.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshCalls, 1);
    });

    test('after dispose the controller stops observing transport', () async {
      final id = _uuid(1);
      final source = _FakeTransportSource(() async => false);
      final connectivity = await _connectivity(source);
      addTearDown(source.close);
      addTearDown(connectivity.dispose);

      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      final controller = DirectoryDetailController(
        repository: repo,
        entityId: id,
        connectivity: connectivity,
      );
      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 1);

      controller.dispose();
      source.changes.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshCalls, 1);
    });
  });

  group('V1-R09 P2-B2 Directory UX — Refresh (search) controller', () {
    test('cache-first: caches publish before refresh completes', () async {
      final gate = Completer<void>();
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: [_entity(_uuid(1), name: 'Cached')],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.refreshGate = gate;
      repo.refreshResults.add(_success([_entity(_uuid(1), name: 'Fresh')]));

      final controller = DirectoryRefreshController(repository: repo);
      addTearDown(controller.dispose);
      unawaited(controller.initialize());
      await _waitUntil(() => repo.readCacheCalls == 1);
      await _waitUntil(() => repo.refreshCalls == 1);
      // Cache is published while the refresh is still gated.
      expect(controller.loadState, DirectoryLoadState.stale);
      expect(controller.entities.single.name, 'Cached');

      gate.complete();
      await _waitUntil(() => controller.isLoading == false);
      expect(controller.loadState, DirectoryLoadState.fresh);
      expect(controller.entities.single.name, 'Fresh');
    });

    test('eligible reconnect refresh fires once on transport recovery', () async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = await _connectivity(source);
      addTearDown(source.close);
      addTearDown(connectivity.dispose);

      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      repo.refreshResults.add(_success([_entity(_uuid(1), name: 'Recovered')]));
      final controller = DirectoryRefreshController(
        repository: repo,
        connectivity: connectivity,
      );
      addTearDown(controller.dispose);
      unawaited(controller.initialize());

      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 1);
      expect(controller.loadState, DirectoryLoadState.error);
      expect(controller.cause, RemoteDataCause.offline);

      source.changes.add(true);
      await _waitUntil(() => repo.refreshCalls == 2);
      await _waitUntil(() => controller.isLoading == false);
      expect(controller.loadState, DirectoryLoadState.fresh);
      expect(controller.cause, isNull);
    });

    test('reconnect does not retry after a successful state (cause cleared)', () async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = await _connectivity(source);
      addTearDown(source.close);
      addTearDown(connectivity.dispose);

      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      repo.refreshResults.add(_success([_entity(_uuid(1), name: 'Ok')]));
      final controller = DirectoryRefreshController(
        repository: repo,
        connectivity: connectivity,
      );
      addTearDown(controller.dispose);
      unawaited(controller.initialize());

      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 1);
      expect(controller.loadState, DirectoryLoadState.error);
      expect(controller.cause, RemoteDataCause.offline);

      // Recovery: transport comes back -> one reconnect refresh succeeds.
      source.changes.add(true);
      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 2);
      expect(controller.loadState, DirectoryLoadState.fresh);

      source.changes.add(false);
      source.changes.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshCalls, 2);
    });
  });

  group('V1-R09 P2-B2 Directory UX — Saved local-first', () {
    late Directory tempDir;
    const boxName = 'v1_r09_p2_b_directory_ux_box';

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('civilpedia_p2b_ux');
      await HiveHelper.init(path: tempDir.path, boxName: boxName);
    });

    setUp(() async {
      await Hive.box(boxName).clear();
    });

    tearDownAll(() async {
      await Hive.close();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    testWidgets('saved refs publish local-first before Directory resolution', (tester) async {
      final id = _uuid(1);
      final store = _FakeSavedStore([_dirRef(id)]);
      final gate = Completer<void>();
      final repo = _ScriptedDirectoryRepository();
      repo.refreshGate = gate;
      repo.refreshResults.add(_success([_entity(id, name: 'Alpha')]));

      await _pumpSaved(tester, directoryRepo: repo, store: store);
      await tester.pump(); // resolve() completes
      await tester.pump(); // readCache (null) -> full list set
      await tester.pump(); // refresh awaits gate -> still pending

      // Local-only frame: unavailable row is already rendered, no remote name.
      expect(find.text(Ar.savedEngineeringDirectory), findsOneWidget);
      expect(find.text(Ar.savedProviderUnavailable), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);

      gate.complete();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text(Ar.savedProviderUnavailable), findsNothing);
    });

    testWidgets('multiple saved refs resolve through a single refresh batch', (tester) async {
      final store = _FakeSavedStore([_dirRef(_uuid(1)), _dirRef(_uuid(2))]);
      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_success([
        _entity(_uuid(1), name: 'Alpha'),
        _entity(_uuid(2), name: 'Beta'),
      ]));

      await _pumpSaved(tester, directoryRepo: repo, store: store);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(repo.refreshCalls, 1);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('failed refresh keeps the saved ref (no delete on failure)', (tester) async {
      final store = _FakeSavedStore([_dirRef(_uuid(1))]);
      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));

      await _pumpSaved(tester, directoryRepo: repo, store: store);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(repo.refreshCalls, 1);
      expect(find.text(Ar.savedProviderUnavailable), findsOneWidget);
      expect(store.refs, hasLength(1));
      expect(store.refs.single.entityId, _uuid(1));
    });

    test('SavedScreen owns no ConnectivityProvider/reconnect listener', () {
      final source = File(
        'lib/features/saved/presentation/saved_screen.dart',
      ).readAsStringSync();
      expect(source.contains('ConnectivityProvider'), isFalse);
      expect(source.contains('connectivity_provider.dart'), isFalse);
      expect(source.contains('reconnect_generation_gate.dart'), isFalse);
      expect(source.contains('TransportSource'), isFalse);
    });
  });

  // ── SEARCH CACHED-EMPTY ──────────────────────────────────────────────────

  group('V1-R09 P2-B2 — Search cached-empty semantics', () {
    test('T1. cached-empty + refresh pending → empty presentation, NOT full-page loading', () async {
      final gate = Completer<void>();
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: const [],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.refreshGate = gate;
      repo.refreshResults.add(_success([]));

      final controller = DirectoryRefreshController(repository: repo);
      addTearDown(controller.dispose);

      unawaited(controller.initialize());
      await _waitUntil(() => repo.refreshCalls == 1);

      expect(controller.hasSnapshot, isTrue);
      expect(controller.loadState, DirectoryLoadState.stale);
      expect(controller.entities, isEmpty);
      expect(controller.isLoading, isTrue);

      gate.complete();
      await _waitUntil(() => controller.isLoading == false);
      expect(controller.loadState, DirectoryLoadState.empty);
      expect(controller.cause, isNull);
    });

    test('T2. cached-empty + network failure → empty retained + network notice', () async {
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: const [],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));

      final controller = DirectoryRefreshController(repository: repo);
      addTearDown(controller.dispose);

      unawaited(controller.initialize());
      await _waitUntil(() => controller.isLoading == false);

      expect(controller.loadState, DirectoryLoadState.stale);
      expect(controller.cause, RemoteDataCause.network);
      expect(controller.entities, isEmpty);
      expect(controller.hasSnapshot, isTrue);
    });

    test('T3. cached-empty + timeout failure → empty retained + timeout notice', () async {
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: const [],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.timeout));

      final controller = DirectoryRefreshController(repository: repo);
      addTearDown(controller.dispose);

      unawaited(controller.initialize());
      await _waitUntil(() => controller.isLoading == false);

      expect(controller.loadState, DirectoryLoadState.stale);
      expect(controller.cause, RemoteDataCause.timeout);
      expect(controller.entities, isEmpty);
    });

    test('T4. cached-empty + serviceUnavailable → empty retained', () async {
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: const [],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.serviceUnavailable));

      final controller = DirectoryRefreshController(repository: repo);
      addTearDown(controller.dispose);

      unawaited(controller.initialize());
      await _waitUntil(() => controller.isLoading == false);

      expect(controller.loadState, DirectoryLoadState.stale);
      expect(controller.cause, RemoteDataCause.serviceUnavailable);
      expect(controller.entities, isEmpty);
    });

    test('T5. remote authoritative empty → fresh empty, no stale provenance', () async {
      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_empty());

      final controller = DirectoryRefreshController(repository: repo);
      addTearDown(controller.dispose);

      unawaited(controller.initialize());
      await _waitUntil(() => controller.isLoading == false);

      expect(controller.loadState, DirectoryLoadState.empty);
      expect(controller.cause, isNull);
      expect(controller.hasSnapshot, isTrue);
      expect(controller.entities, isEmpty);
    });

    test('T6. authoritative empty + cachePersisted false → fresh, no failure notice', () async {
      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(DirectoryRefreshResult(
        status: DirectoryRefreshStatus.authoritativeEmpty,
        entities: const [],
        refreshedAt: DateTime.utc(2026, 9, 1),
        cachePersisted: false,
      ));

      final controller = DirectoryRefreshController(repository: repo);
      addTearDown(controller.dispose);

      unawaited(controller.initialize());
      await _waitUntil(() => controller.isLoading == false);

      expect(controller.loadState, DirectoryLoadState.empty);
      expect(controller.cause, isNull);
    });
  });

  // ── NO-CACHE FAILURE ─────────────────────────────────────────────────────

  group('V1-R09 P2-B2 — No-cache failure semantics', () {
    test('T7. no cache + network failure → typed no-data state', () async {
      final repo = _ScriptedDirectoryRepository();
      repo.cached = null;
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));

      final controller = DirectoryRefreshController(repository: repo);
      addTearDown(controller.dispose);

      unawaited(controller.initialize());
      await _waitUntil(() => controller.isLoading == false);

      expect(controller.loadState, DirectoryLoadState.error);
      expect(controller.cause, RemoteDataCause.network);
      expect(controller.hasSnapshot, isFalse);
    });

    test('T8. no cache + timeout → typed no-data state', () async {
      final repo = _ScriptedDirectoryRepository();
      repo.cached = null;
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.timeout));

      final controller = DirectoryRefreshController(repository: repo);
      addTearDown(controller.dispose);

      unawaited(controller.initialize());
      await _waitUntil(() => controller.isLoading == false);

      expect(controller.loadState, DirectoryLoadState.error);
      expect(controller.cause, RemoteDataCause.timeout);
      expect(controller.hasSnapshot, isFalse);
    });
  });

  // ── SEARCH LIFECYCLE ─────────────────────────────────────────────────────

  group('V1-R09 P2-B2 — Search lifecycle safety', () {
    test('T9. search cache Future completes after dispose → no publication', () async {
      final readCacheGate = Completer<void>();
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: [_entity(_uuid(1))],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.readCacheGate = readCacheGate;
      repo.refreshResults.add(_success([]));

      final controller = DirectoryRefreshController(repository: repo);
      unawaited(controller.initialize());
      await _waitUntil(() => repo.readCacheCalls == 1);

      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.dispose();
      readCacheGate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(notifications, 0);
    });

    test('T10. search refresh Future completes after dispose → no publication', () async {
      final refreshGate = Completer<void>();
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: const [],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.refreshGate = refreshGate;
      repo.refreshResults.add(_success([_entity(_uuid(1))]));

      final controller = DirectoryRefreshController(repository: repo);
      unawaited(controller.initialize());
      await _waitUntil(() => repo.refreshCalls == 1);

      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);
      controller.dispose();
      refreshGate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(notifications, 0);
    });
  });

  // ── SEARCH SUPERSESSION ──────────────────────────────────────────────────

  group('V1-R09 P2-B2 — Search supersession', () {
    test('T13. older search completion after newer operation → ignored', () async {
      final refreshGate = Completer<void>();
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: const [],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.refreshGate = refreshGate;
      repo.refreshResults.add(_success([_entity(_uuid(1), name: 'Stale')]));

      final controller = DirectoryRefreshController(repository: repo);
      unawaited(controller.initialize());
      await _waitUntil(() => repo.refreshCalls == 1);

      final stateBeforeDispose = controller.loadState;
      controller.dispose();

      refreshGate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.loadState, stateBeforeDispose);
      expect(controller.entities, isEmpty);
    });
  });

  // ── DETAIL LIFECYCLE ─────────────────────────────────────────────────────

  group('V1-R09 P2-B2 — Detail lifecycle safety', () {
    test('T11. detail cache Future completes after dispose → no publication', () async {
      final readCacheGate = Completer<void>();
      final id = _uuid(1);
      final repo = _ScriptedDirectoryRepository();
      repo.cached = DirectoryCachedData(
        entities: [_entity(id, name: 'Cached')],
        refreshedAt: DateTime.utc(2026, 9, 1),
      );
      repo.readCacheGate = readCacheGate;
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));

      final controller = DirectoryDetailController(repository: repo, entityId: id);
      await _waitUntil(() => repo.readCacheCalls == 1);

      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.dispose();
      readCacheGate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(notifications, 0);
    });

    test('T12. detail refresh Future completes after dispose → no publication', () async {
      final refreshGate = Completer<void>();
      final id = _uuid(1);
      final repo = _ScriptedDirectoryRepository();
      repo.refreshGate = refreshGate;
      repo.refreshResults.add(_success([_entity(id, name: 'Fresh')]));

      final controller = DirectoryDetailController(repository: repo, entityId: id);
      await _waitUntil(() => repo.refreshCalls == 1);

      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(notifications, 0);
      controller.dispose();
      refreshGate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(notifications, 0);
    });

    test('T14. older detail completion after newer operation → ignored', () async {
      final refreshGate = Completer<void>();
      final id = _uuid(1);
      final repo = _ScriptedDirectoryRepository();
      repo.refreshGate = refreshGate;
      repo.refreshResults.add(_success([_entity(id, name: 'Fresh')]));

      final controller = DirectoryDetailController(repository: repo, entityId: id);
      await _waitUntil(() => repo.refreshCalls == 1);

      final stateBeforeDispose = controller.state;
      controller.dispose();

      refreshGate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.state, stateBeforeDispose);
    });
  });

  // ── RECONNECT ────────────────────────────────────────────────────────────

  group('V1-R09 P2-B2 — Reconnect behavior', () {
    test('T15. initial available/bound generation → no reconnect refresh', () async {
      final source = _FakeTransportSource(() async => true);
      final connectivity = await _connectivity(source);
      addTearDown(source.close);
      addTearDown(connectivity.dispose);

      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_success([_entity(_uuid(1), name: 'Ok')]));

      final controller = DirectoryRefreshController(
        repository: repo,
        connectivity: connectivity,
      );
      addTearDown(controller.dispose);
      unawaited(controller.initialize());
      await _waitUntil(() => controller.isLoading == false);

      final refreshCountAfterInit = repo.refreshCalls;
      expect(refreshCountAfterInit, 1);
      expect(controller.loadState, DirectoryLoadState.fresh);
    });

    test('T16. manual refresh active + reconnect → one underlying repository refresh', () async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = await _connectivity(source);
      addTearDown(source.close);
      addTearDown(connectivity.dispose);

      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      final controller = DirectoryRefreshController(
        repository: repo,
        connectivity: connectivity,
      );
      addTearDown(controller.dispose);
      unawaited(controller.initialize());
      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 1);
      expect(controller.cause, RemoteDataCause.offline);

      // Manual refresh starts and stays in flight.
      final refreshGate = Completer<void>();
      repo.refreshGate = refreshGate;
      repo.refreshResults.add(_success([_entity(_uuid(1), name: 'Manual')]));
      unawaited(controller.refresh(userInitiated: true));
      await _waitUntil(() => repo.refreshCalls == 2);
      expect(controller.isLoading, isTrue);

      // Reconnect event during the in-flight manual refresh: the generation is
      // claimed, but the request coalesces into the active manual refresh.
      source.changes.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshCalls, 2);

      refreshGate.complete();
      await _waitUntil(() => controller.isLoading == false);
      expect(controller.loadState, DirectoryLoadState.fresh);
      expect(controller.entities.single.name, 'Manual');
    });

    test('T17. failed reconnect → no repeat on same generation', () async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = await _connectivity(source);
      addTearDown(source.close);
      addTearDown(connectivity.dispose);

      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      final controller = DirectoryRefreshController(
        repository: repo,
        connectivity: connectivity,
      );
      addTearDown(controller.dispose);
      unawaited(controller.initialize());

      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 1);
      expect(controller.cause, RemoteDataCause.offline);

      // Reconnect (generation 1) fails: mapped as plain network now that
      // transport is available.
      source.changes.add(true);
      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 2);
      expect(controller.loadState, DirectoryLoadState.error);
      expect(controller.cause, RemoteDataCause.network);

      // Falling back to unavailable does NOT advance the generation: ignored.
      source.changes.add(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.refreshCalls, 2);
    });

    test('T18. later newer generation → one new eligible refresh', () async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = await _connectivity(source);
      addTearDown(source.close);
      addTearDown(connectivity.dispose);

      final repo = _ScriptedDirectoryRepository();
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      repo.refreshResults.add(_failure(DirectoryRefreshStatus.network));
      repo.refreshResults.add(_success([_entity(_uuid(1), name: 'Recovered')]));
      final controller = DirectoryRefreshController(
        repository: repo,
        connectivity: connectivity,
      );
      addTearDown(controller.dispose);
      unawaited(controller.initialize());

      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 1);
      expect(controller.cause, RemoteDataCause.offline);

      source.changes.add(true);
      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 2);
      expect(controller.cause, RemoteDataCause.network);

      source.changes.add(false);
      source.changes.add(true);
      await _waitUntil(() => controller.isLoading == false && repo.refreshCalls == 3);
      expect(controller.loadState, DirectoryLoadState.fresh);
      expect(controller.cause, isNull);
    });
  });
}
