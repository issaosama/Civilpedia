import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/di/app_dependencies.dart';
import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/directory/presentation/directory_landing_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_search_screen.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/profile_screen.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:civilpedia/features/projects/presentation/project_list_screen.dart';
import 'package:civilpedia/features/saved/presentation/saved_screen.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/checklist_screen.dart';
import 'package:civilpedia/features/tools/presentation/screens/tools_screen.dart';
import 'package:civilpedia/features/user_area/presentation/user_area_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:civilpedia/routes/app_router.dart';
import 'package:civilpedia/routes/app_routes.dart';
import 'package:civilpedia/routes/not_found_screen.dart';

import 'helpers/png_http_overrides.dart';

const _boxName = 'w6_3_nav_transition_test_box';

/// Test path-provider stub so [AppDependencies.init] resolves a real documents
/// dir without touching platform channels.
class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = Directory.systemTemp.createTempSync('civilpedia_w6_3');
    return dir.path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final dir = Directory.systemTemp.createTempSync('civilpedia_w6_3_support');
    return dir.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    final dir = Directory.systemTemp.createTempSync('civilpedia_w6_3_tmp');
    return dir.path;
  }
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
      anonymousInstallId: 'w6.3-test',
      userType: CivilUserType.siteEngineer,
      baghdadArea: BaghdadArea.karkh,
    );

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  @override
  Future<List<EngineeringTopic>> getAllTopics() async => const [];

  @override
  Future<EngineeringTopic?> getTopicById(String id) async => null;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      const [];

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => const {};

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async => const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => const [];
}

class _ListBackedEncyclopediaFavoritesStore
    implements EncyclopediaFavoritesStore {
  @override
  Future<List<String>> read() async => const [];

  @override
  Future<void> add(String topicId) async {}

  @override
  Future<void> remove(String topicId) async {}
}

Widget _app(UserProfileProvider profileProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider.value(
        value: EncyclopediaProvider(
          repository: _FakeEncyclopediaRepository(),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => EncyclopediaFavoritesProvider(
          store: _ListBackedEncyclopediaFavoritesStore(),
        ),
      ),
      ChangeNotifierProvider<ConnectivityProvider>(
        create: (_) => ConnectivityProvider(),
      ),
      ChangeNotifierProvider.value(value: profileProvider),
    ],
    child: MaterialApp.router(routerConfig: appRouter),
  );
}

/// Navigates the canonical [appRouter] to [path] before attaching it so the
/// test never renders the app's splash/onboarding origin.
Future<void> _open(
  WidgetTester tester,
  String path, {
  UserProfileProvider? profileProvider,
  Object? extra,
}) async {
  appRouter.go(path, extra: extra);
  await tester.pumpWidget(_app(profileProvider ?? _profileProvider()));
  await tester.pumpAndSettle();
}

/// Same as [_open] but for SavedScreen surfaces, whose production
/// Hive-backed resolver performs real box IO — fake-async pumps hang, so the
/// pump must run inside [tester.runAsync] (W3.2 harness pattern).
Future<void> _openSaved(WidgetTester tester, String path) async {
  final profileProvider = _profileProvider();
  await tester.runAsync(() async {
    appRouter.go(path);
    await tester.pumpWidget(_app(profileProvider));
    await tester.pump(const Duration(milliseconds: 100));
  });
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Smoke-tests every HTTP request with a 1x1 PNG so the Home screen's
/// network-backed ad/article images resolve in fake-async tests.
HttpOverrides get _pngOverrides => PngHttpOverrides();

/// Same as [_open] but for Home, whose ad article carousel keeps an auto-scroll
/// timer alive — a settle would hang the fake clock. Bounded pumps only
/// (established Home harness pattern).
Future<void> _openHome(WidgetTester tester, UserProfileProvider profileProvider) async {
  appRouter.go(AppRoutes.home);
  await tester.pumpWidget(_app(profileProvider));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 100));
}

UserProfileProvider _profileProvider({LocalUserProfile? stored}) {
  return UserProfileProvider(
    repository: _FakeUserProfileRepository(stored ?? _profile()),
  );
}

/// Location of the topmost route match. Unlike `currentConfiguration.uri`
/// (which only reflects `go`-level locations), `matches.last.matchedLocation`
/// also reports pushed pages, so branch pushes can be proven (canonical W3.4
/// harness pattern).
String _currentPath() =>
    appRouter.routerDelegate.currentConfiguration.matches.last.matchedLocation;

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    HttpOverrides.global = _pngOverrides;
    PathProviderPlatform.instance = _FakePathProvider();
    await AppDependencies.init();
    tempDir = await Directory.systemTemp.createTemp('civilpedia_w6_3_hive');
    await HiveHelper.init(path: tempDir.path, boxName: _boxName);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.box(_boxName).clear();
  });

  tearDownAll(() async {
    HttpOverrides.global = null;
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // Best-effort cleanup.
    }
  });

  group('W6.3 — shell model (Bottom Navigation contract)', () {
    test('1. visible shell = exactly 5 destinations in contract order', () {
      expect(kShellDestinations.length, 5);
      expect(kShellDestinations.map((d) => d.route).toList(), [
        '/home',
        '/encyclopedia',
        '/tools',
        '/projects',
        '/directory',
      ]);
    });

    test('2. /saved and /profile are no longer shell destinations', () {
      final routes = kShellDestinations.map((d) => d.route).toList();
      expect(routes, isNot(contains('/saved')));
      expect(routes, isNot(contains('/profile')));
      // Both remain Canonical AppRoutes identities (root compatibility routes).
      expect(AppRoutes.saved, '/saved');
      expect(AppRoutes.profile, '/profile');
    });

    test('3. no sixth destination placeholder exists', () {
      expect(kShellDestinations.length, 5);
      // The router derives its branches solely from kShellDestinations.
      final routerSource =
          File('lib/routes/app_router.dart').readAsStringSync();
      expect(routerSource.contains('StatefulShellRoute.indexedStack'), isTrue);
      expect(
        'kShellDestinations'.allMatches(routerSource).length,
        greaterThanOrEqualTo(1),
      );
    });

    test('4. Projects and Directory carry their canonical tab labels', () {
      final projects = kShellDestinations[3];
      expect(projects.route, AppRoutes.projects);
      expect(projects.label, Ar.checklistMyProjects);
      expect(En.checklistMyProjects, 'My Projects');

      final directory = kShellDestinations[4];
      expect(directory.route, AppRoutes.directory);
      expect(directory.label, Ar.directory);
      // Tab label is the short form, distinct from the verbose landing title.
      expect(Ar.directory, isNot(Ar.directoryLandingTitle));
      expect(En.directory, isNot(En.directoryLandingTitle));
    });

    test('5. routing constants: directorySearch lives under the directory branch',
        () {
      expect(AppRoutes.directorySearchSegment, 'search');
      expect(AppRoutes.directorySearch, '/directory/search');
      expect(
        AppRoutes.directorySearch,
        '${AppRoutes.directory}/${AppRoutes.directorySearchSegment}',
      );
    });

    test('6. no duplicate /projects or /directory registrations in the router',
        () {
      final source = File('lib/routes/app_router.dart').readAsStringSync();
      // Exactly one reference each: 'projects' appears only in the branch
      // builders map; 'directory' only in the branch builders + nested map.
      // Negative lookahead so 'AppRoutes.directorySearch' does not count as a
      // separate 'directory' registration.
      expect(
        RegExp(r'AppRoutes\.projects(?!\w)').allMatches(source).length,
        1,
      );
      expect(
        RegExp(r'AppRoutes\.directory(?!\w)').allMatches(source).length,
        2,
      );
      // No raw /directory literals in the router file.
      expect(source.contains("'/directory'"), isFalse);
      expect(source.contains('"/directory"'), isFalse);
    });

    test('7. /directory/provider/:id remains unregistered (no raw route)', () {
      final source = File('lib/routes/app_router.dart').readAsStringSync();
      expect(source.contains('/directory/provider'), isFalse);
      expect(source.contains('AppRoutes.directoryProvider'), isFalse);
    });
  });

  group('W6.3 — shell branches render the real screens', () {
    testWidgets('8. /projects branch root renders the canonical ProjectListScreen',
        (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.projects);

      expect(find.byType(ProjectListScreen), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);
      expect(_currentPath(), AppRoutes.projects);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. /directory branch root renders the real DirectoryLandingScreen',
        (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.directory);

      expect(find.byType(DirectoryLandingScreen), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);
      expect(_currentPath(), AppRoutes.directory);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. /directory/search renders nested under the shell '
        '(AppShell stays visible)', (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.directorySearch);

      expect(find.byType(DirectorySearchScreen), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);
      expect(_currentPath(), AppRoutes.directorySearch);
      expect(tester.takeException(), isNull);
    });

    testWidgets('11. tapping the Directory tab from another branch lands on the '
        'landing screen inside the shell', (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.tools);

      expect(find.byType(ToolsScreen), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AppShell),
          matching: find.byIcon(Icons.business_center_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DirectoryLandingScreen), findsOneWidget);
      expect(_currentPath(), AppRoutes.directory);
      expect(tester.takeException(), isNull);
    });

    testWidgets('12. branch switching keeps earlier branch content alive '
        '(IndexedStack state preservation)', (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.projects);
      expect(find.byType(ProjectListScreen), findsOneWidget);

      appRouter.go(AppRoutes.directory);
      await tester.pumpAndSettle();
      expect(find.byType(DirectoryLandingScreen), findsOneWidget);

      // Returning to the projects branch must not rebuild from scratch (the
      // indexed-stack shell mechanism keeps branch state alive).
      appRouter.go(AppRoutes.projects);
      await tester.pumpAndSettle();
      expect(find.byType(ProjectListScreen), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('12a. W6.3 shell-hosted Projects FAB opens the create dialog '
        '(WORKS/FAILS regression — Projects FAB defect)', (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.projects);
      expect(find.byType(ProjectListScreen), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      expect(
        tester.widget<FloatingActionButton>(fab).onPressed,
        isNotNull,
        reason: '_createProject must stay wired to onPressed',
      );

      // Hit-Test Contract: the FAB must be raised above the shell obstruction
      // so its visual position is its tappable position (Padding layout, not a
      // visual-only Transform). FAB bottom must clear the nav's obstruction
      // region (nav height 70 + 16 bottom margin = 86).
      final fabBottom = tester.getRect(fab).bottom;
      expect(
        fabBottom,
        lessThanOrEqualTo(tester.view.physicalSize.height),
        reason: 'FAB must stay inside the screen',
      );

      await tester.tap(
        fab,
        warnIfMissed: true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text(Ar.projectCreateTitle),
        findsOneWidget,
        reason:
            'the shell-hosted Projects FAB tap must surface the create '
            'project name dialog (W6.3 FAB hit-test defect regression)',
      );

      // Cancel — no persistent mutation.
      await tester.tap(find.text(Ar.cancel));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('W6.3 — root compatibility routes', () {
    testWidgets('13. /saved renders SavedScreen above the root (no shell)',
        (tester) async {
      _useTallViewport(tester);
      await _openSaved(tester, AppRoutes.saved);

      expect(find.byType(SavedScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      expect(_currentPath(), AppRoutes.saved);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. /profile renders ProfileScreen above the root (no shell)',
        (tester) async {
      _useTallViewport(tester);
      final profileProvider = _profileProvider();
      await profileProvider.loadProfile();
      await _open(tester, AppRoutes.profile, profileProvider: profileProvider);

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      expect(_currentPath(), AppRoutes.profile);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. /profile/edit renders ProfileEditScreen above the root '
        '(no shell)', (tester) async {
      _useTallViewport(tester);
      final profileProvider = _profileProvider();
      await profileProvider.loadProfile();

      await _open(
        tester,
        AppRoutes.profile,
        profileProvider: profileProvider,
      );
      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16. /user, /user/saved, /user/downloads remain routable',
        (tester) async {
      _useTallViewport(tester);
      final profileProvider = _profileProvider();
      await profileProvider.loadProfile();

      await _open(tester, AppRoutes.user, profileProvider: profileProvider);
      expect(find.byType(UserAreaScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);

      await tester.runAsync(() async {
        appRouter.go(AppRoutes.userSaved);
        await tester.pump(const Duration(milliseconds: 100));
      });
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(SavedScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);

      await tester.runAsync(() async {
        appRouter.go(AppRoutes.userDownloads);
        await tester.pump(const Duration(milliseconds: 100));
      });
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(SavedScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('W6.3 — avatar entry', () {
    testWidgets('17. Home header avatar navigates to /user', (tester) async {
      _useTallViewport(tester);
      final profileProvider = _profileProvider();
      await profileProvider.loadProfile();
      await _openHome(tester, profileProvider);

      expect(find.byType(AppShell), findsOneWidget);
      final avatar = find.byType(CircleAvatar);
      expect(avatar, findsOneWidget);

      await tester.tap(avatar);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(UserAreaScreen), findsOneWidget);
      expect(_currentPath(), AppRoutes.user);
      expect(tester.takeException(), isNull);
    });
  });

  group('W6.3 — preserved journeys', () {
    testWidgets('18. legacy Tools → Checklist → My Projects still opens the '
        'canonical ProjectListScreen', (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.tools);

      // Checklist tool card on the Tools grid (hardcoded Arabic label).
      await tester.tap(find.text('قائمة التفتيش'));
      await tester.pumpAndSettle();
      expect(find.byType(ChecklistScreen), findsOneWidget);

      // The production My Projects entry inside the checklist pushes the
      // canonical screen through the legacy import path.
      await tester.tap(
        find.descendant(
          of: find.byType(ChecklistScreen),
          matching: find.text(Ar.checklistMyProjects),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProjectListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. /projects renders the canonical screen reachable through '
        'the legacy import path', (tester) async {
      _useTallViewport(tester);
      await _open(tester, AppRoutes.projects);
      expect(find.byType(ProjectListScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(Ar.checklistMyProjects),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('W6.3 — data untouched', () {
    test('20. Saved route/segment identities are unchanged (no migration)', () {
      expect(AppRoutes.saved, '/saved');
      expect(AppRoutes.userSaved, '/user/saved');
      expect(AppRoutes.userDownloads, '/user/downloads');
      expect(AppRoutes.userProfileEdit, '/user/profile/edit');
    });

    test('21. Directory + Profile canonical identities are unchanged', () {
      expect(AppRoutes.directory, '/directory');
      expect(AppRoutes.directorySearch, '/directory/search');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.profileEdit, '/profile/edit');
      expect(En.directoryLandingTitle, 'Engineering Directory');
      expect(En.directorySearchTitle, 'Search Directory');
    });
  });

  group('W6.3 — guard rails (regression shields)', () {
    test('22. /search is still NOT a shell destination', () {
      final routes = kShellDestinations.map((d) => d.route).toList();
      expect(routes, isNot(contains(AppRoutes.search)));
    });

    test('23. /user is still NOT a shell destination', () {
      final routes = kShellDestinations.map((d) => d.route).toList();
      expect(routes, isNot(contains(AppRoutes.user)));
    });

    test('24. every shell destination resolves a registered route constant', () {
      for (final d in kShellDestinations) {
        expect(d.route.startsWith('/'), isTrue);
        expect(d.route.length, greaterThan(1));
      }
    });

    testWidgets('25. an unknown nested route under /directory is NotFound',
        (tester) async {
      _useTallViewport(tester);
      await _open(tester, '/directory/reviews');
      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}