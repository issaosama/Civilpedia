import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/features/auth/presentation/auth_screen.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
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
import 'package:civilpedia/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:civilpedia/features/saved/presentation/saved_screen.dart';
import 'package:civilpedia/features/user_area/presentation/user_area_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_router.dart';
import 'package:civilpedia/routes/app_routes.dart';
import 'package:civilpedia/routes/not_found_screen.dart';

const _boxName = 'w3_4_user_area_test_box';

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
  anonymousInstallId: 'w3.4-test',
  userType: CivilUserType.siteEngineer,
  baghdadArea: BaghdadArea.karkh,
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

Widget _app(
  UserProfileProvider profileProvider, {
  EncyclopediaFavoritesProvider? favorites,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider.value(value: profileProvider),
      ChangeNotifierProvider.value(
        value: EncyclopediaProvider(
          repository: _FakeEncyclopediaRepository(const []),
        ),
      ),
      if (favorites != null)
        ChangeNotifierProvider.value(value: favorites)
      else
        ChangeNotifierProvider(
          create: (_) => EncyclopediaFavoritesProvider(
            store: _ListBackedEncyclopediaFavoritesStore(const []),
          ),
        ),
    ],
    child: MaterialApp.router(routerConfig: appRouter),
  );
}

UserProfileProvider _profileProvider({LocalUserProfile? stored}) {
  final provider = UserProfileProvider(
    repository: _FakeUserProfileRepository(stored),
  );
  return provider;
}

/// Navigates the canonical [appRouter] to [path] before attaching it so the
/// test never renders the app's splash/onboarding origin.
Future<void> _open(
  WidgetTester tester,
  UserProfileProvider profileProvider,
  String path, {
  Object? extra,
}) async {
  appRouter.go(path, extra: extra);
  await tester.pumpWidget(_app(profileProvider));
  await tester.pumpAndSettle();
}

/// Same as [_open] but for SavedScreen surfaces, whose production
/// Hive-backed resolver performs real box IO — fake-async pumps hang, so the
/// pump must run inside [tester.runAsync] (W3.2 harness pattern).
Future<void> _openSaved(
  WidgetTester tester,
  UserProfileProvider profileProvider,
  String path,
) async {
  final favorites = EncyclopediaFavoritesProvider(
    store: _ListBackedEncyclopediaFavoritesStore(const []),
  );
  await tester.runAsync(() async {
    await favorites.load();
    appRouter.go(path);
    await tester.pumpWidget(_app(profileProvider, favorites: favorites));
    await tester.pump(const Duration(milliseconds: 100));
  });
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Settles a SavedScreen that has just been pushed/landed on the current tree
/// (runAsync flush so the production Hive-backed resolver completes, then
/// bounded pump frames for the tab animation).
Future<void> _settleSaved(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.pump(const Duration(milliseconds: 100));
  });
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Re-navigates the already-pumped tree to a saved/downloads route and settles
/// it like [_settleSaved].
Future<void> _goAndSettleSaved(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    appRouter.go(path);
    await tester.pump(const Duration(milliseconds: 100));
  });
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Location of the topmost route match. Unlike `currentConfiguration.uri`
/// (which only reflects `go`-level locations), `matches.last.matchedLocation`
/// reports pushed pages too, so it can prove a push actually targeted the
/// nested `/user/*/edit` destination.
String _topMatchedLocation() =>
    appRouter.routerDelegate.currentConfiguration.matches.last.matchedLocation;

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civilpedia_w3_4_test');
    const pathProviderChannel = MethodChannel(
      'plugins.flutter.io/path_provider',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return tempDir.path;
        });
    await HiveHelper.init(path: tempDir.path, boxName: _boxName);
  });

  setUp(() async {
    await Hive.box(_boxName).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('W3.4 route authority', () {
    test('segments and composed full paths are canonical', () {
      expect(AppRoutes.user, '/user');
      expect(AppRoutes.userProfileSegment, 'profile');
      expect(AppRoutes.userSavedSegment, 'saved');
      expect(AppRoutes.userDownloadsSegment, 'downloads');
      expect(AppRoutes.userProfile, '/user/profile');
      expect(AppRoutes.userProfileEdit, '/user/profile/edit');
      expect(AppRoutes.userSaved, '/user/saved');
      expect(AppRoutes.userDownloads, '/user/downloads');

      expect(
        AppRoutes.userProfile,
        '${AppRoutes.user}/${AppRoutes.userProfileSegment}',
      );
      expect(
        AppRoutes.userProfileEdit,
        '${AppRoutes.userProfile}/${AppRoutes.profileEditSegment}',
      );
      expect(
        AppRoutes.userSaved,
        '${AppRoutes.user}/${AppRoutes.userSavedSegment}',
      );
      expect(
        AppRoutes.userDownloads,
        '${AppRoutes.user}/${AppRoutes.userDownloadsSegment}',
      );
    });

    test('existing public destination values are unchanged', () {
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.profileEdit, '/profile/edit');
      expect(AppRoutes.saved, '/saved');
      expect(AppRoutes.profileSetup, '/profile-setup');
      expect(AppRoutes.auth, '/auth');
      expect(AppRoutes.userProfileEdit, isNot(AppRoutes.profileEdit));
    });

    test('/user is NOT a Bottom Navigation destination', () {
      final shellRoutes = kShellDestinations.map((d) => d.route).toList();
      expect(
        shellRoutes,
        ['/home', '/encyclopedia', '/tools', '/saved', '/profile'],
        reason:
            'W6.3 owns the navigation transition; W3.4 must not alter or '
            'extend the shell destinations',
      );
      expect(shellRoutes.contains(AppRoutes.user), isFalse);
    });
  });

  group('W3.4 /user hub', () {
    testWidgets('is registered as a root full-screen destination and renders', (
      tester,
    ) async {
      final profileProvider = _profileProvider(stored: _profile());
      await _open(tester, profileProvider, AppRoutes.user);

      expect(find.byType(UserAreaScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.user);
      expect(find.text(Ar.userArea), findsOneWidget);
      expect(
        find.byType(AppShell),
        findsNothing,
        reason:
            '/user must be a root full-screen surface, never a shell '
            'branch (no Bottom Navigation chrome)',
      );
    });

    testWidgets('exposes exactly Profile/Saved/Downloads and no inventory-only '
        'entries', (tester) async {
      final profileProvider = _profileProvider(stored: _profile());
      await _open(tester, profileProvider, AppRoutes.user);

      expect(find.widgetWithText(ListTile, Ar.profile), findsOneWidget);
      expect(find.widgetWithText(ListTile, Ar.saved), findsOneWidget);
      expect(find.widgetWithText(ListTile, Ar.downloads), findsOneWidget);
      expect(
        find.byType(ListTile),
        findsNWidgets(3),
        reason:
            'hub is an aggregation surface for shipped destinations only — '
            'activity/preferences/theme/language/backup/account are inventory '
            'and must NOT be surfaced, and there is no avatar/header wiring',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Profile enters /user/profile', (tester) async {
      final profileProvider = _profileProvider(stored: _profile());
      await _open(tester, profileProvider, AppRoutes.user);

      await tester.tap(find.widgetWithText(ListTile, Ar.profile));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userProfile);
    });

    testWidgets('hub Saved entry opens /user/saved live on the existing '
        'SavedScreen (Favorites tab)', (tester) async {
      final profileProvider = _profileProvider(stored: _profile());
      await _openSaved(tester, profileProvider, AppRoutes.user);

      await tester.tap(find.widgetWithText(ListTile, Ar.saved));
      await _settleSaved(tester);

      expect(find.byType(SavedScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userSaved);
      expect(find.text(Ar.noFavorites), findsOneWidget);
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
    });

    testWidgets('hub Downloads entry opens /user/downloads live on the '
        'existing SavedScreen (Downloads tab)', (tester) async {
      final profileProvider = _profileProvider(stored: _profile());
      await _openSaved(tester, profileProvider, AppRoutes.user);

      await tester.tap(find.widgetWithText(ListTile, Ar.downloads));
      await _settleSaved(tester);

      expect(find.byType(SavedScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userDownloads);
      expect(find.text(Ar.noDownloads), findsOneWidget);
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    });
  });

  group('W3.4 /user/profile', () {
    testWidgets('renders the existing ProfileScreen', (tester) async {
      final profileProvider = _profileProvider(stored: _profile());
      await profileProvider.loadProfile();
      await _open(tester, profileProvider, AppRoutes.userProfile);

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userProfile);
    });

    testWidgets('first edit entry pushes /user/profile/edit', (tester) async {
      _useTallViewport(tester);
      final profileProvider = _profileProvider(stored: _profile());
      await profileProvider.loadProfile();
      await _open(tester, profileProvider, AppRoutes.userProfile);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userProfileEdit);
      expect(tester.takeException(), isNull);
    });

    testWidgets('second edit entry pushes /user/profile/edit', (tester) async {
      _useTallViewport(tester);
      final profileProvider = _profileProvider(stored: _profile());
      await profileProvider.loadProfile();
      await _open(tester, profileProvider, AppRoutes.userProfile);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileMainWorkArea));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userProfileEdit);
      expect(tester.takeException(), isNull);
    });

    testWidgets('profile data reaches ProfileEditScreen via state.extra', (
      tester,
    ) async {
      _useTallViewport(tester);
      final profileProvider = _profileProvider(stored: _profile());
      await profileProvider.loadProfile();
      await _open(tester, profileProvider, AppRoutes.userProfile);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();

      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(find.text(BaghdadArea.karkh.arName), findsOneWidget);
    });

    testWidgets('Back from /user/profile/edit returns to /user/profile', (
      tester,
    ) async {
      _useTallViewport(tester);
      final profileProvider = _profileProvider(stored: _profile());
      await profileProvider.loadProfile();
      await _open(tester, profileProvider, AppRoutes.userProfile);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(find.text(Ar.backupAndRestore), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userProfile);
    });
  });

  group(
    'W3.4 /user/profile/edit fallback contract (reuses W3.3 semantics)',
    () {
      testWidgets('wrong-type extra is handled safely via the router error '
          'contract', (tester) async {
        final profileProvider = _profileProvider(stored: null);
        await _open(
          tester,
          profileProvider,
          AppRoutes.userProfileEdit,
          extra: 'not-a-profile',
        );

        expect(find.byType(NotFoundScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('missing extra with no profile shows NotFound instead of '
          'crashing', (tester) async {
        final profileProvider = _profileProvider(stored: null);
        await _open(tester, profileProvider, AppRoutes.userProfileEdit);

        expect(find.byType(NotFoundScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'missing extra falls back to the authoritative profile provider '
        'when a profile exists',
        (tester) async {
          final profileProvider = _profileProvider(stored: _profile());
          await profileProvider.loadProfile();
          await _open(tester, profileProvider, AppRoutes.userProfileEdit);

          expect(find.byType(ProfileEditScreen), findsOneWidget);
          expect(find.text(Ar.siteEngineer), findsOneWidget);
        },
      );

      testWidgets('valid extra is honored', (tester) async {
        final profileProvider = _profileProvider(
          stored: LocalUserProfile(
            anonymousInstallId: 'w3.4-extra',
            userType: CivilUserType.contractor,
            baghdadArea: BaghdadArea.rusafa,
          ),
        );
        await _open(
          tester,
          profileProvider,
          AppRoutes.userProfileEdit,
          extra: LocalUserProfile(
            anonymousInstallId: 'w3.4-direct',
            userType: CivilUserType.engineeringOffice,
            baghdadArea: BaghdadArea.karkh,
          ),
        );

        expect(find.byType(ProfileEditScreen), findsOneWidget);
        expect(find.text(Ar.engineeringOffice), findsOneWidget);
      });
    },
  );

  group('W3.4 /user/saved and /user/downloads', () {
    testWidgets('/user/saved opens the existing SavedScreen on Favorites', (
      tester,
    ) async {
      final profileProvider = _profileProvider(stored: _profile());
      await _openSaved(tester, profileProvider, AppRoutes.userSaved);

      expect(find.byType(SavedScreen), findsOneWidget);
      expect(find.text(Ar.noFavorites), findsOneWidget);
      expect(find.text(Ar.noDownloads), findsNothing);
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('/user/downloads opens the existing SavedScreen directly on '
        'Downloads', (tester) async {
      final profileProvider = _profileProvider(stored: _profile());
      await _openSaved(tester, profileProvider, AppRoutes.userDownloads);

      expect(find.byType(SavedScreen), findsOneWidget);
      expect(find.text(Ar.noDownloads), findsOneWidget);
      expect(find.text(Ar.noFavorites), findsNothing);
      expect(
        tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
        1,
        reason:
            'the Downloads tab must be genuinely selected on arrival, not '
            'after a post-frame jump',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('no persistence writes and no new keys', (tester) async {
      final profileProvider = _profileProvider(stored: _profile());
      await _openSaved(tester, profileProvider, AppRoutes.userDownloads);
      await _openSaved(tester, profileProvider, AppRoutes.userSaved);

      expect(HiveHelper.getFavorites(), isEmpty);
      expect(HiveHelper.getEncyclopediaFavorites(), isEmpty);
      expect(HiveHelper.getDownloads(), isEmpty);
      expect(Hive.box(_boxName).keys.toList(), isEmpty);
    });
  });

  group('W3.4 legacy preservation', () {
    testWidgets('/profile remains reachable and unchanged', (tester) async {
      final profileProvider = _profileProvider(stored: _profile());
      await profileProvider.loadProfile();
      await _open(tester, profileProvider, AppRoutes.profile);

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text(Ar.backupAndRestore), findsOneWidget);
      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.profile);
    });

    testWidgets('/profile edit still uses /profile/edit and stays green', (
      tester,
    ) async {
      _useTallViewport(tester);
      final profileProvider = _profileProvider(stored: _profile());
      await profileProvider.loadProfile();
      await _open(tester, profileProvider, AppRoutes.profile);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(find.text(Ar.backupAndRestore), findsOneWidget);
    });

    testWidgets('/saved legacy branch remains working', (tester) async {
      final profileProvider = _profileProvider(stored: _profile());
      await _openSaved(tester, profileProvider, AppRoutes.saved);

      expect(find.byType(SavedScreen), findsOneWidget);
      expect(find.text(Ar.saved), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('/profile-setup remains unchanged', (tester) async {
      final profileProvider = _profileProvider(stored: null);
      await _open(tester, profileProvider, AppRoutes.profileSetup);

      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.text(Ar.profileStep1Of2), findsOneWidget);
    });

    testWidgets('/auth remains unchanged', (tester) async {
      final profileProvider = _profileProvider(stored: null);
      await _open(tester, profileProvider, AppRoutes.auth);

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('W3.4 direct dispatch and freeze', () {
    testWidgets('all five W3.4 routes are directly dispatchable on one tree', (
      tester,
    ) async {
      final profileProvider = _profileProvider(stored: _profile());
      await profileProvider.loadProfile();
      final favorites = EncyclopediaFavoritesProvider(
        store: _ListBackedEncyclopediaFavoritesStore(const []),
      );
      await tester.runAsync(() async {
        await favorites.load();
        appRouter.go(AppRoutes.user);
        await tester.pumpWidget(_app(profileProvider, favorites: favorites));
        await tester.pump(const Duration(milliseconds: 100));
      });
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(UserAreaScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.user);

      appRouter.go(AppRoutes.userProfile);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userProfile);

      appRouter.go(AppRoutes.userProfileEdit, extra: _profile());
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userProfileEdit);

      await _goAndSettleSaved(tester, AppRoutes.userSaved);
      expect(find.byType(SavedScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userSaved);

      await _goAndSettleSaved(tester, AppRoutes.userDownloads);
      expect(find.byType(SavedScreen), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.userDownloads);
    });

    testWidgets('bottom navigation destinations remain exactly the legacy '
        'five (W6.3 freeze)', (tester) async {
      final profileProvider = _profileProvider(stored: _profile());
      await profileProvider.loadProfile();
      await _open(tester, profileProvider, AppRoutes.profile);

      for (final label in [
        Ar.home,
        Ar.encyclopedia,
        Ar.tools,
        Ar.saved,
        Ar.account,
      ]) {
        expect(
          find.text(label),
          findsWidgets,
          reason: 'legacy 5-tab Bottom Navigation must stay visible',
        );
      }
      expect(kShellDestinations.length, 5);
    });

    testWidgets('inventory-only /user/account is NOT implemented', (
      tester,
    ) async {
      final profileProvider = _profileProvider(stored: _profile());
      await _open(tester, profileProvider, '/user/account');

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
