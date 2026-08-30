import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/topic_list_card.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_resolver.dart';
import 'package:civilpedia/features/saved/presentation/saved_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

const _boxName = 'w3_2_saved_screen_test_box';

final Uint8List _kPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _PngHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _PngHttpClient();
}

class _PngHttpClient implements HttpClient {
  @override
  String? userAgent;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  int? maxConnectionsPerHost;
  Future<bool> Function(Uri url, String scheme, String? realm)? authenticate;
  String Function(Uri url)? findProxy;
  bool Function(X509Certificate cert, String host, int port)?
  badCertificateCallback;
  Function(String line)? keyLog;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _PngRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _PngRequest(url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async =>
      _PngRequest(Uri(scheme: 'https', host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      get(host, port, path);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      get(host, port, path);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      get(host, port, path);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      get(host, port, path);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      get(host, port, path);

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => get(host, port, path);

  @override
  Future<void> close({bool force = false}) async {}

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected HttpClient member: ${invocation.memberName}');
}

class _PngRequest implements HttpClientRequest {
  @override
  final Uri uri;

  _PngRequest(this.uri);

  final _headers = _PngHeaders();

  @override
  int contentLength = 0;

  @override
  bool bufferOutput = true;

  @override
  bool persistentConnection = true;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  Duration? timeout;

  @override
  Future<HttpClientResponse> get done => close();

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<HttpClientResponse> close() async => _PngResponse(_kPngBytes);

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> add(List<int> data) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected HttpClientRequest member: ${invocation.memberName}');
}

class _PngResponse implements HttpClientResponse {
  final Uint8List _bytes;
  _PngResponse(this._bytes);

  final _headers = _PngHeaders();

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _bytes.length;

  @override
  HttpHeaders get headers => _headers;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  bool get isBroadcast => false;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.fromIterable([_bytes]).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected HttpClientResponse member: ${invocation.memberName}');
}

class _PngHeaders implements HttpHeaders {
  final Map<String, List<String>> _map = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _map.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _map[name.toLowerCase()] = [value.toString()];
  }

  @override
  List<String>? operator [](String name) => _map[name.toLowerCase()];

  @override
  String? value(String name) {
    final values = _map[name.toLowerCase()];
    return values == null || values.isEmpty ? null : values.join(', ');
  }

  @override
  void remove(String name, Object value) {
    final list = _map[name.toLowerCase()];
    if (list != null) list.remove(value.toString());
  }

  @override
  void removeAll(String name) => _map.remove(name.toLowerCase());

  @override
  void clear() => _map.clear();

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _map.forEach(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected HttpHeaders member: ${invocation.memberName}');
}

EngineeringTopic _topic(String id, String title) => EngineeringTopic(
  id: id,
  titleAr: title,
  categoryId: 'cat1',
  summary: 'ملخص $title',
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
  tags: const ['concrete'],
  keyTopics: const ['خرسانة'],
);

class _ListBackedEncyclopediaFavoritesStore
    implements EncyclopediaFavoritesStore {
  final List<String> _ids;
  _ListBackedEncyclopediaFavoritesStore(this._ids);

  @override
  Future<List<String>> read() async => List.of(_ids);

  @override
  Future<void> add(String topicId) async {
    if (!_ids.contains(topicId)) _ids.insert(0, topicId);
  }

  @override
  Future<void> remove(String topicId) async {
    _ids.remove(topicId);
  }
}

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  final List<EngineeringTopic> topics;
  _FakeEncyclopediaRepository(this.topics);

  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  @override
  Future<List<EngineeringTopic>> getAllTopics() async => topics;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      topics.where((t) => t.categoryId == categoryId).toList();

  @override
  Future<Map<String, CategoryInfo>> getCategories() async =>
      const <String, CategoryInfo>{};

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civilpedia_w3_2_test');
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      return tempDir.path;
    });
    HttpOverrides.global = _PngHttpOverrides();
    await HiveHelper.init(path: tempDir.path, boxName: _boxName);
  });

  setUp(() async {
    await Hive.box(_boxName).clear();
  });

  tearDownAll(() async {
    HttpOverrides.global = null;
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<void> pumpFrames(WidgetTester tester, {int pumps = 12}) async {
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpSaved(
    WidgetTester tester, {
    required List<EngineeringTopic> topics,
    List<String> efIds = const [],
    List<String> favIds = const [],
    EncyclopediaFavoritesProvider? favoritesProvider,
    SavedReferenceResolver? favoritesResolver,
    GoRouter? router,
  }) async {
    final favorites =
        favoritesProvider ??
        EncyclopediaFavoritesProvider(
          store: _ListBackedEncyclopediaFavoritesStore(efIds),
        );
    await favorites.load();
    final resolver =
        favoritesResolver ??
        SavedReferenceResolver(
          encyclopediaTopicIds: () async => List.of(efIds),
          legacyArticleIds: () async => List.of(favIds),
        );
    final app = MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value:
              EncyclopediaProvider(
                repository: _FakeEncyclopediaRepository(topics),
              ),
        ),
        ChangeNotifierProvider.value(value: favorites),
      ],
      child:
          router != null
              ? MaterialApp.router(routerConfig: router)
              : MaterialApp(home: SavedScreen(favoritesResolver: resolver)),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 100));
    });
    await pumpFrames(tester);
  }

  group('W3.2 Favorites identity comes from the canonical resolver', () {
    testWidgets(
      'renders topic + legacy article favorites resolved through the resolver',
      (tester) async {
        await pumpSaved(
          tester,
          topics: [_topic('t1', 'الموضوع الأول')],
          efIds: const ['t1'],
          favIds: const ['2'],
        );

        expect(find.text('الموضوع الأول'), findsOneWidget);
        expect(find.text('أساسيات تصميم الأساسات'), findsOneWidget);
        expect(find.byType(TopicListCard), findsOneWidget);
      },
    );

    testWidgets(
      'builds the favorite list without reading raw stores directly',
      (tester) async {
        final resolver = SavedReferenceResolver(
          encyclopediaTopicIds: () async => const ['t1'],
          legacyArticleIds: () async => const ['2'],
        );
        final favoritesProvider = EncyclopediaFavoritesProvider(
          store: _ListBackedEncyclopediaFavoritesStore(<String>[]),
        );
        await favoritesProvider.load();

        await pumpSaved(
          tester,
          topics: [_topic('t1', 'الموضوع الأول')],
          favoritesProvider: favoritesProvider,
          favoritesResolver: resolver,
        );

        expect(HiveHelper.getFavorites(), isEmpty);
        expect(HiveHelper.getEncyclopediaFavorites(), isEmpty);
        expect(favoritesProvider.savedIds, isEmpty);
        expect(find.text('الموضوع الأول'), findsOneWidget);
        expect(find.text('أساسيات تصميم الأساسات'), findsOneWidget);
      },
    );

    testWidgets(
      'same raw id in topic and article namespaces renders distinct entities',
      (tester) async {
        await pumpSaved(
          tester,
          topics: [_topic('1', 'موضوع مشترك')],
          efIds: const ['1'],
          favIds: const ['1'],
        );

        expect(find.text('موضوع مشترك'), findsOneWidget);
        expect(find.text('أنواع الخرسانة المسلحة'), findsOneWidget);
      },
    );
  });

  group('W3.2 ordering and hydration', () {
    testWidgets(
        'renders topics in stored most-recent-first order and legacy articles '
        'in ArticleRepository catalog order', (tester) async {
      _useTallViewport(tester);
      await pumpSaved(
        tester,
        topics: [
          _topic('t1', 'الموضوع الأول'),
          _topic('t2', 'الموضوع الثاني'),
          _topic('t3', 'الموضوع الثالث'),
        ],
        efIds: const ['t3', 't1', 't2'],
        favIds: const ['5', '1'],
      );

      double dy(String text) => tester.getTopLeft(find.text(text)).dy;

      expect(
        dy('الموضوع الثالث') < dy('الموضوع الأول'),
        isTrue,
        reason: 'topics render most-recent-first exactly as stored (pre-W3.2 '
            'topic behavior preserved)',
      );
      expect(dy('الموضوع الأول') < dy('الموضوع الثاني'), isTrue);
      expect(
        dy('الموضوع الثاني') < dy(Ar.engineeringEncyclopedia),
        isFalse,
        reason: 'topics stay under their section header',
      );
      expect(
        dy(Ar.savedArticlesSection) > dy('الموضوع الثاني'),
        isTrue,
        reason: 'articles section follows topics section',
      );
      expect(
        dy('أنواع الخرسانة المسلحة') < dy('طبقات الرصف للطرق'),
        isTrue,
        reason: 'legacy articles display in ArticleRepository catalog order '
            'even though stored append order is [5, 1]; stored order does NOT '
            'redefine visible ordering',
      );
    });

    testWidgets('topic hydration keeps the stored most-recent-first order',
        (tester) async {
      _useTallViewport(tester);
      await pumpSaved(
        tester,
        topics: [
          _topic('t2', 'الموضوع الثاني'),
          _topic('t1', 'الموضوع الأول'),
        ],
        efIds: const ['t2', 't1'],
      );

      expect(
        tester.getTopLeft(find.text('الموضوع الثاني')).dy <
            tester.getTopLeft(find.text('الموضوع الأول')).dy,
        isTrue,
      );
    });
  });

  group('W3.2 stale references', () {
    testWidgets('unresolvable reference is skipped without crashing or writing',
        (tester) async {
      await pumpSaved(
        tester,
        topics: [_topic('t1', 'الموضوع الأول')],
        efIds: const ['missing', 't1'],
        favIds: const ['999'],
      );

      expect(find.text('الموضوع الأول'), findsOneWidget);
      expect(find.text('missing'), findsNothing);
      expect(find.text('999'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(HiveHelper.getEncyclopediaFavorites(), isEmpty);
      expect(HiveHelper.getFavorites(), isEmpty);
      expect(
        find.text(Ar.noFavorites),
        findsNothing,
        reason: 'valid favorites still render alongside stale ones',
      );
    });
  });

  group('W3.2 behavior preservation', () {
    testWidgets('empty Favorites state shows the same empty UI', (tester) async {
      await pumpSaved(
        tester,
        topics: [_topic('t1', 'الموضوع الأول')],
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text(Ar.noFavorites), findsOneWidget);
    });

    testWidgets('topic tap opens Topic Detail and article tap opens Article '
        'Detail', (tester) async {
      _useTallViewport(tester);
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async => const ['t1'],
        legacyArticleIds: () async => const ['1'],
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => SavedScreen(favoritesResolver: resolver),
          ),
          GoRoute(
            path: '/encyclopedia/topic/:id',
            builder: (_, __) => Scaffold(
              appBar: AppBar(),
              body: const Text('topic-detail'),
            ),
          ),
          GoRoute(
            path: '/article/:id',
            builder: (_, __) => Scaffold(
              appBar: AppBar(),
              body: const Text('article-detail'),
            ),
          ),
        ],
      );

      await pumpSaved(
        tester,
        topics: [_topic('t1', 'الموضوع الأول')],
        favoritesResolver: resolver,
        router: router,
      );

      await tester.tap(find.byType(TopicListCard));
      await pumpFrames(tester);
      expect(find.text('topic-detail'), findsOneWidget);

      await tester.pageBack();
      await pumpFrames(tester);
      expect(find.text('الموضوع الأول'), findsOneWidget);

      await tester.tap(find.text('أنواع الخرسانة المسلحة'));
      await pumpFrames(tester);
      expect(find.text('article-detail'), findsOneWidget);
    });

    testWidgets('Downloads tab renders downloads and stays unaffected',
        (tester) async {
      await tester.runAsync(() async {
        await Hive.box(
          _boxName,
        ).put(AppStorageKeys.downloads, const <String>['2']);
      });
      await pumpSaved(
        tester,
        topics: [_topic('t1', 'الموضوع الأول')],
        efIds: const ['t1'],
      );

      expect(find.text('الموضوع الأول'), findsOneWidget);

      await tester.tap(find.text(Ar.downloads));
      await pumpFrames(tester);

      expect(find.text('أساسيات تصميم الأساسات'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(HiveHelper.getDownloads(), ['2']);
      expect(HiveHelper.getFavorites(), isEmpty);
      expect(HiveHelper.getEncyclopediaFavorites(), isEmpty);
    });
  });

  group('W3.2 refresh through existing write paths', () {
    testWidgets(
      'legacy article favorite added via HiveHelper is visible after tab '
      'revisit', (tester) async {
      _useTallViewport(tester);
      await tester.runAsync(() async {
        final box = Hive.box(_boxName);
        await box.put(AppStorageKeys.favorites, const <String>['2']);
        await box.put(AppStorageKeys.encyclopediaFavorites, const <String>[]);
      });
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async => HiveHelper.getEncyclopediaFavorites(),
        legacyArticleIds: () async => HiveHelper.getFavorites(),
      );
      final favoritesProvider = EncyclopediaFavoritesProvider();
      await favoritesProvider.load();

      await pumpSaved(
        tester,
        topics: [_topic('t1', 'الموضوع الأول')],
        favoritesProvider: favoritesProvider,
        favoritesResolver: resolver,
      );

      expect(find.text('أساسيات تصميم الأساسات'), findsOneWidget);
      expect(find.text('أنواع حديد التسليح'), findsNothing);

      await tester.runAsync(() => HiveHelper.toggleFavorite('3'));

      await tester.tap(find.text(Ar.downloads));
      await pumpFrames(tester);
      await tester.tap(find.text(Ar.favorites));
      await pumpFrames(tester);

      expect(find.text('أنواع حديد التسليح'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('أساسيات تصميم الأساسات')).dy <
            tester.getTopLeft(find.text('أنواع حديد التسليح')).dy,
        isTrue,
        reason: 'legacy articles keep ArticleRepository catalog order after '
            'refresh through the existing write path',
      );
    });

    testWidgets(
      'topic favorite saved through the provider is picked up automatically',
      (tester) async {
final sharedIds = <String>['t1'];
      final favoritesProvider = EncyclopediaFavoritesProvider(
        store: _ListBackedEncyclopediaFavoritesStore(sharedIds),
      );
      await favoritesProvider.load();

      await pumpSaved(
        tester,
        topics: [
          _topic('t1', 'الموضوع الأول'),
          _topic('t2', 'الموضوع الثاني'),
        ],
        favoritesProvider: favoritesProvider,
        efIds: sharedIds,
      );

        expect(find.text('الموضوع الثاني'), findsNothing);

        await favoritesProvider.save('t2');
        await pumpFrames(tester);

        expect(find.text('الموضوع الثاني'), findsOneWidget);
      },
    );
  });
}
