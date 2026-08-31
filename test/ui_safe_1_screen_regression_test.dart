import 'dart:io';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/navigation/shell_content_insets.dart';
import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/screens/encyclopedia_screen.dart';
import 'package:civilpedia/features/home/presentation/home_main_screen.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/profile_screen.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_resolver.dart';
import 'package:civilpedia/features/saved/presentation/saved_screen.dart';
import 'package:civilpedia/features/tools/presentation/screens/tools_screen.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'helpers/png_http_overrides.dart';

/// Screen-level regression coverage for UI-SAFE-1.
///
/// For shell-hosted tests we inject an unusual obstruction (137) and a smaller
/// device inset (24); effective clearance must be 137 + breathing (153), NOT
/// 24+breathing and NOT 137+24+breathing. This proves each screen consumes the
/// semantic shell contract rather than a magic value or today's 86px layout.
///
/// For root-host tests there is no ShellContentInsets ancestor and a known
/// MediaQuery bottom inset (31); effective clearance must be 31 + breathing.

const double _obstruction = 137;
const double _breathing = 16; // AppSpacing.lg
const double _shellExpected = _obstruction + _breathing; // 153
const double _rootInset = 31;
const double _rootExpected = _rootInset + _breathing; // 47

// --- Shared fixtures -------------------------------------------------------

EngineeringTopic _topic(String id, String title, {String categoryId = 'concrete'}) =>
    EngineeringTopic(
      id: id,
      titleAr: title,
      categoryId: categoryId,
      summary: 'ملخص $title',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      tags: const [],
      keyTopics: const [],
    );

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  final List<EngineeringTopic> topics;
  _FakeEncyclopediaRepository(this.topics);
  @override
  Future<EngineeringTopic?> getTopicById(String id) async =>
      topics.where((t) => t.id == id).firstOrNull;
  @override
  Future<List<EngineeringTopic>> getAllTopics() async => topics;
  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      topics.where((t) => t.categoryId == categoryId).toList();
  @override
  Future<Map<String, CategoryInfo>> getCategories() async => const {};
  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];
  @override
  Future<List<ContentBlock>> getBlocksForSection(String t, String s) async =>
      const [];
  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
}

class _FakeConnectivityProvider extends ConnectivityProvider {
  _FakeConnectivityProvider() : super();
}

class _FakeUserProfileRepository implements UserProfileRepository {
  LocalUserProfile? stored;
  _FakeUserProfileRepository(this.stored);
  @override
  Future<LocalUserProfile?> loadProfile() async => stored;
  @override
  Future<void> saveProfile(LocalUserProfile profile) async {
    stored = profile;
  }

  @override
  Future<void> clearProfile() async {
    stored = null;
  }
}

LocalUserProfile _profile() => LocalUserProfile(
      anonymousInstallId: 'ui-safe-1',
      userType: CivilUserType.siteEngineer,
      baghdadArea: BaghdadArea.karkh,
    );

class _FakeFavoritesStore implements EncyclopediaFavoritesStore {
  final List<String> _ids;
  _FakeFavoritesStore(this._ids);
  @override
  Future<List<String>> read() async => List.of(_ids);
  @override
  Future<void> add(String topicId) async => _ids.add(topicId);
  @override
  Future<void> remove(String topicId) async => _ids.remove(topicId);
}

Widget _app({required Widget home, double deviceInset = 0, double? obstruction}) {
  Widget result = MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: home,
  );
  if (deviceInset > 0) {
    result = MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 1600),
        padding: EdgeInsets.only(bottom: deviceInset),
      ),
      child: result,
    );
  }
  if (obstruction != null) {
    result = ShellContentInsets(bottomObstruction: obstruction, child: result);
  }
  return result;
}

/// Returns every ListView's resolved bottom padding in the tree.
List<double> _listViewBottoms(WidgetTester tester) {
  return tester
      .widgetList<ListView>(find.byType(ListView))
      .map((w) => w.padding?.resolve(TextDirection.ltr).bottom ?? 0)
      .toList();
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpFrames(WidgetTester tester, {int pumps = 12}) async {
  for (var i = 0; i < pumps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const _boxName = 'ui_safe_1_regression_box';

void main() {
  late Directory tempDir;
  late HttpOverrides? previousHttpOverrides;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ui_safe_1_regression');
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      return tempDir.path;
    });
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = PngHttpOverrides();
    await HiveHelper.init(path: tempDir.path, boxName: _boxName);
  });

  setUp(() async {
    await Hive.box(_boxName).clear();
  });

  tearDownAll(() async {
    HttpOverrides.global = previousHttpOverrides;
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('UI-SAFE-1 screen-level regression', () {
    testWidgets('HomeMainScreen uses shell obstruction, not device inset',
        (tester) async {
      _useTallViewport(tester);
      final repo = _FakeEncyclopediaRepository([
        _topic('t1', 'فحص الخرسانة'),
        _topic('t2', 'خلط الخرسانة'),
      ]);
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();

      await tester.pumpWidget(
        _app(
          obstruction: _obstruction,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: provider),
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider<ConnectivityProvider>(
                create: (_) => _FakeConnectivityProvider(),
              ),
            ],
            child: const Scaffold(body: HomeMainScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      // Home contains an auto-rotating ad carousel (never fully settles), so
      // use fixed pumps instead of pumpAndSettle.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Trailing spacer must equal shell obstruction + breathing (153).
      final spacers = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((s) => s.height == _shellExpected)
          .toList();
      expect(spacers, isNotEmpty,
          reason: 'Home trailing spacer must clear shell obstruction (153)');
    });

    testWidgets('Encyclopedia browse list uses shell-safe bottom padding',
        (tester) async {
      _useTallViewport(tester);
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository([
          _topic('t1', 'فحص الخرسانة'),
          _topic('t2', 'خلط الخرسانة'),
          _topic('t3', 'حديد', categoryId: 'steel'),
        ]),
      );
      await provider.loadAllTopics();

      await tester.pumpWidget(
        _app(
          obstruction: _obstruction,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: provider),
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ],
            child: const EncyclopediaScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_listViewBottoms(tester), contains(_shellExpected),
          reason: 'browse ListView must clear shell obstruction (153)');
    });

    testWidgets('Encyclopedia search results list uses shell-safe bottom padding',
        (tester) async {
      _useTallViewport(tester);
      final provider = EncyclopediaProvider(
        repository: _FakeEncyclopediaRepository([
          _topic('t1', 'فحص الخرسانة'),
          _topic('t2', 'خلط الخرسانة'),
        ]),
      );
      await provider.loadAllTopics();
      provider.searchTopics('فحص'); // activates search-results mode

      await tester.pumpWidget(
        _app(
          obstruction: _obstruction,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: provider),
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ],
            child: const EncyclopediaScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.isSearchActive, isTrue);
      expect(_listViewBottoms(tester), contains(_shellExpected),
          reason: 'search-results ListView must clear shell obstruction (153)');
    });

    testWidgets('ToolsScreen final SliverPadding clears shell obstruction',
        (tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(
        _app(
          obstruction: _obstruction,
          home: ChangeNotifierProvider(
            create: (_) => LanguageProvider(),
            child: const ToolsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sliverBottoms = tester
          .widgetList<SliverPadding>(find.byType(SliverPadding))
          .map((w) => w.padding.resolve(TextDirection.ltr).bottom)
          .toList();
      expect(sliverBottoms, contains(_shellExpected),
          reason: 'tools SliverPadding must clear shell obstruction (153)');
    });

    testWidgets('SavedScreen Favorites tab uses shell-safe bottom padding',
        (tester) async {
      _useTallViewport(tester);
      final repo = _FakeEncyclopediaRepository([
        _topic('t1', 'الموضوع الأول'),
      ]);
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();
      final favorites = EncyclopediaFavoritesProvider(
        store: _FakeFavoritesStore(['t1']),
      );
      await favorites.load();
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async => ['t1'],
        legacyArticleIds: () async => [],
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(
          _app(
            obstruction: _obstruction,
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: provider),
                ChangeNotifierProvider.value(value: favorites),
              ],
              child: SavedScreen(favoritesResolver: resolver, initialTabIndex: 0),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      });
      await _pumpFrames(tester);

      expect(find.text('الموضوع الأول'), findsOneWidget);
      expect(_listViewBottoms(tester), contains(_shellExpected),
          reason: 'Favorites tab ListView must clear shell obstruction (153)');
    });

    testWidgets('SavedScreen Downloads tab uses shell-safe bottom padding',
        (tester) async {
      _useTallViewport(tester);
      await tester.runAsync(() async {
        await HiveHelper.restoreDownloads(['1']); // legacy article → real Downloads ListView
      });
      final repo = _FakeEncyclopediaRepository([]);
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();
      final favorites = EncyclopediaFavoritesProvider(
        store: _FakeFavoritesStore([]),
      );
      await favorites.load();
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async => [],
        legacyArticleIds: () async => ['1'],
      );

      await tester.runAsync(() async {
        await tester.pumpWidget(
          _app(
            obstruction: _obstruction,
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: provider),
                ChangeNotifierProvider.value(value: favorites),
              ],
              child: SavedScreen(favoritesResolver: resolver, initialTabIndex: 1),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      });
      await _pumpFrames(tester);

      // The downloaded article is rendered on the Downloads tab with a real
      // ListView that must clear the shell obstruction (bottom = 153).
      expect(find.text('أنواع الخرسانة المسلحة'), findsOneWidget);
      expect(_listViewBottoms(tester), contains(_shellExpected),
          reason: 'Downloads tab ListView must clear shell obstruction (153)');
    });

    testWidgets('SavedScreen outside shell uses device inset fallback (no crash)',
        (tester) async {
      _useTallViewport(tester);
      final repo = _FakeEncyclopediaRepository([
        _topic('t1', 'الموضوع الأول'),
      ]);
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();
      final favorites = EncyclopediaFavoritesProvider(
        store: _FakeFavoritesStore(['t1']),
      );
      await favorites.load();
      final resolver = SavedReferenceResolver(
        encyclopediaTopicIds: () async => ['t1'],
        legacyArticleIds: () async => [],
      );

      await tester.pumpWidget(
        _app(
          deviceInset: _rootInset, // root host: no shell ancestor
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: provider),
              ChangeNotifierProvider.value(value: favorites),
            ],
            child: SavedScreen(favoritesResolver: resolver, initialTabIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Root host: effective bottom = device inset (31) + breathing (16) = 47.
      expect(_listViewBottoms(tester), contains(_rootExpected));
    });

    testWidgets('ProfileScreen inside shell uses dynamic bottom padding (no 100)',
        (tester) async {
      _useTallViewport(tester);
      final profileProvider =
          UserProfileProvider(repository: _FakeUserProfileRepository(_profile()));
      await profileProvider.loadProfile();

      await tester.pumpWidget(
        _app(
          obstruction: _obstruction,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider.value(value: profileProvider),
              ChangeNotifierProvider(
                create: (_) => EncyclopediaFavoritesProvider(
                  store: _FakeFavoritesStore([]),
                ),
              ),
            ],
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_listViewBottoms(tester), contains(_shellExpected),
          reason: 'Profile bottom padding must be 153, not the old magic 100');
      // The old magic 100 must no longer be effective.
      expect(_listViewBottoms(tester), isNot(contains(100.0)));
    });

    testWidgets('ProfileScreen outside shell uses device inset fallback',
        (tester) async {
      _useTallViewport(tester);
      final profileProvider =
          UserProfileProvider(repository: _FakeUserProfileRepository(null));
      await profileProvider.loadProfile();

      await tester.pumpWidget(
        _app(
          deviceInset: _rootInset,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider.value(value: profileProvider),
              ChangeNotifierProvider(
                create: (_) => EncyclopediaFavoritesProvider(
                  store: _FakeFavoritesStore([]),
                ),
              ),
            ],
            child: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_listViewBottoms(tester), contains(_rootExpected));
    });

    testWidgets('ProfileEditScreen inside shell uses shell-safe bottom padding',
        (tester) async {
      _useTallViewport(tester);
      final profileProvider =
          UserProfileProvider(repository: _FakeUserProfileRepository(_profile()));
      await profileProvider.loadProfile();

      await tester.pumpWidget(
        _app(
          obstruction: _obstruction,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
              ChangeNotifierProvider.value(value: profileProvider),
            ],
            child: ProfileEditScreen(profile: _profile()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bottoms = _listViewBottoms(tester);
      expect(bottoms, contains(_shellExpected));
      // Side/top padding must remain unchanged (AppSpacing.lg = 16).
      final lv = tester.widgetList<ListView>(find.byType(ListView)).first;
      final pad = lv.padding!.resolve(TextDirection.ltr);
      expect(pad.left, 16);
      expect(pad.right, 16);
      expect(pad.top, 16);
    });

    testWidgets('ProfileEditScreen outside shell uses device inset fallback',
        (tester) async {
      _useTallViewport(tester);
      final profileProvider =
          UserProfileProvider(repository: _FakeUserProfileRepository(_profile()));
      await profileProvider.loadProfile();

      await tester.pumpWidget(
        _app(
          deviceInset: _rootInset,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => LanguageProvider()),
              ChangeNotifierProvider.value(value: profileProvider),
            ],
            child: ProfileEditScreen(profile: _profile()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_listViewBottoms(tester), contains(_rootExpected));
    });
  });
}
