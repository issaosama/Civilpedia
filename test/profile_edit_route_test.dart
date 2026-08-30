import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:civilpedia/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_router.dart';
import 'package:civilpedia/routes/app_routes.dart';
import 'package:civilpedia/routes/not_found_screen.dart';

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
  anonymousInstallId: 'w3.3-test',
  userType: CivilUserType.siteEngineer,
  baghdadArea: BaghdadArea.karkh,
);

Widget _app(WidgetTester tester, UserProfileProvider profileProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider.value(value: profileProvider),
    ],
    child: MaterialApp.router(routerConfig: appRouter),
  );
}

/// Navigates the canonical [appRouter] to [path] before attaching it, so the
/// test never renders the app's splash/onboarding origin.
Future<void> _open(
  WidgetTester tester,
  UserProfileProvider profileProvider,
  String path, {
  Object? extra,
}) async {
  appRouter.go(path, extra: extra);
  await tester.pumpWidget(_app(tester, profileProvider));
  await tester.pumpAndSettle();
}

String _currentPath() =>
    appRouter.routerDelegate.currentConfiguration.uri.path;

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  test(
    'W3.3 AppRoutes is the single route-segment authority for /profile/edit',
    () {
      expect(AppRoutes.profileEditSegment, 'edit');
      expect(
        AppRoutes.profileEdit,
        '/profile/edit',
        reason: 'public destination must remain unchanged',
      );
      expect(AppRoutes.profileEdit, '${AppRoutes.profile}/${AppRoutes.profileEditSegment}');
    },
  );

  testWidgets(
    'W3.3 first entry point pushes ProfileEditScreen through the canonical '
    'route', (tester) async {
      _useTallViewport(tester);
      final repository = _FakeUserProfileRepository(_profile());
      final profileProvider = UserProfileProvider(repository: repository);
      await profileProvider.loadProfile();

      await _open(tester, profileProvider, AppRoutes.profile);

      expect(find.text(Ar.backupAndRestore), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'W3.3 second entry point uses the same canonical route',
    (tester) async {
      _useTallViewport(tester);
      final repository = _FakeUserProfileRepository(_profile());
      final profileProvider = UserProfileProvider(repository: repository);
      await profileProvider.loadProfile();

      await _open(tester, profileProvider, AppRoutes.profile);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileMainWorkArea));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'W3.3 push keeps Profile Edit on the branch navigator (shell chrome '
    'stays visible)', (tester) async {
      _useTallViewport(tester);
      final repository = _FakeUserProfileRepository(_profile());
      final profileProvider = UserProfileProvider(repository: repository);
      await profileProvider.loadProfile();

      await _open(tester, profileProvider, AppRoutes.profile);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(
        find.text(Ar.account),
        findsOneWidget,
        reason: 'bottom navigation must remain visible exactly as it was '
            'before W3.3 (branch-local push, not a root-navigator push)',
      );
    },
  );

  testWidgets('W3.3 Back from Profile Edit returns to Profile', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeUserProfileRepository(_profile());
    final profileProvider = UserProfileProvider(repository: repository);
    await profileProvider.loadProfile();

    await _open(tester, profileProvider, AppRoutes.profile);

    await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileEditScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ProfileEditScreen), findsNothing);
    expect(find.text(Ar.backupAndRestore), findsOneWidget);
    expect(_currentPath(), AppRoutes.profile);
  });

  testWidgets(
    'W3.3 exact profile data reaches ProfileEditScreen via state.extra',
    (tester) async {
      _useTallViewport(tester);
      final repository = _FakeUserProfileRepository(_profile());
      final profileProvider = UserProfileProvider(repository: repository);
      await profileProvider.loadProfile();

      await _open(tester, profileProvider, AppRoutes.profile);
      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();

      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(find.text(BaghdadArea.karkh.arName), findsOneWidget);
    },
  );

  testWidgets(
    'W3.3 existing Profile Edit save/update behavior remains green',
    (tester) async {
      _useTallViewport(tester);
      final repository = _FakeUserProfileRepository(_profile());
      final profileProvider = UserProfileProvider(repository: repository);
      await profileProvider.loadProfile();

      await _open(tester, profileProvider, AppRoutes.profile);
      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();
      expect(find.text(Ar.profileChangeRole), findsOneWidget);

      await tester.tap(find.text(Ar.consultantEngineer));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Ar.profileSaveChanges));
      await tester.pumpAndSettle();

      expect(repository.stored!.userType, CivilUserType.consultantEngineer);
      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(find.text(Ar.profileUpdated), findsOneWidget);
      expect(find.text(Ar.consultantEngineer), findsOneWidget);
    },
  );

  testWidgets(
    'W3.3 destination is registered in AppRouter and dispatchable with a '
    'valid extra', (tester) async {
      final repository = _FakeUserProfileRepository(null);
      final profileProvider = UserProfileProvider(repository: repository);

      await _open(
        tester,
        profileProvider,
        AppRoutes.profileEdit,
        extra: _profile(),
      );

      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'W3.3 direct dispatch without extra and without profile shows the router '
    'error contract instead of crashing', (tester) async {
      final repository = _FakeUserProfileRepository(null);
      final profileProvider = UserProfileProvider(repository: repository);

      await _open(tester, profileProvider, AppRoutes.profileEdit);

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'W3.3 direct dispatch without extra falls back to the authoritative '
    'profile provider', (tester) async {
      final repository = _FakeUserProfileRepository(_profile());
      final profileProvider = UserProfileProvider(repository: repository);
      await profileProvider.loadProfile();

      await _open(tester, profileProvider, AppRoutes.profileEdit);

      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(find.text(Ar.siteEngineer), findsOneWidget);
    },
  );

  testWidgets(
    'W3.3 wrong-type extra is handled safely without an uncontrolled cast',
    (tester) async {
      final repository = _FakeUserProfileRepository(null);
      final profileProvider = UserProfileProvider(repository: repository);

      await _open(
        tester,
        profileProvider,
        AppRoutes.profileEdit,
        extra: 'not-a-profile',
      );

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('W3.3 existing /profile branch still works', (tester) async {
    final repository = _FakeUserProfileRepository(_profile());
    final profileProvider = UserProfileProvider(repository: repository);
    await profileProvider.loadProfile();

    await _open(tester, profileProvider, AppRoutes.profile);

    expect(find.text(Ar.backupAndRestore), findsOneWidget);
    expect(find.text(Ar.siteEngineer), findsOneWidget);
    expect(_currentPath(), AppRoutes.profile);
    expect(tester.takeException(), isNull);
  });

  testWidgets('W3.3 /profile-setup remains unchanged', (tester) async {
    final repository = _FakeUserProfileRepository(null);
    final profileProvider = UserProfileProvider(repository: repository);

    await _open(tester, profileProvider, AppRoutes.profileSetup);

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.text(Ar.profileStep1Of2), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'W3.3 does not introduce a W3.4 /user route', (tester) async {
      final repository = _FakeUserProfileRepository(_profile());
      final profileProvider = UserProfileProvider(repository: repository);
      await profileProvider.loadProfile();

      await _open(tester, profileProvider, '/user');

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}