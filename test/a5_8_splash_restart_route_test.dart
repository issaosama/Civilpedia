import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:civilpedia/data/local/preferences_helper.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/profile/data/region_preference.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:civilpedia/features/splash/presentation/civilpedia_splash_animation.dart';
import 'package:civilpedia/features/splash/presentation/splash_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_router.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'fakes/fake_auth_gateway.dart';
import 'helpers/png_http_overrides.dart';

class _FakeTransportSource implements TransportSource {
  @override
  Stream<bool> get availabilityChanges => const Stream<bool>.empty();

  @override
  Future<bool> checkAvailability() async => true;
}

class _FakeConnectivityProvider extends ConnectivityProvider {
  _FakeConnectivityProvider() : super(source: _FakeTransportSource());
}

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

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
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => const [];
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

class _DelayedRestoreAuthGateway extends FakeAuthGateway {
  final Completer<AuthSession?> restoreCompleter = Completer<AuthSession?>();
  int restoreCalls = 0;

  @override
  Future<AuthSession?> restoreSession() {
    restoreCalls++;
    return restoreCompleter.future;
  }
}

Widget _app(
  WidgetTester tester,
  UserProfileProvider profileProvider, {
  AuthProvider? authProvider,
  Future<void>? startupReady,
  StartupDestinationCallback? onDestinationResolved,
}) {
  final auth = authProvider ?? AuthProvider();
  final readiness =
      startupReady ??
      Future.wait<void>([auth.restoreSession(), profileProvider.loadProfile()]);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: profileProvider),
      ChangeNotifierProvider(
        create: (_) =>
            EncyclopediaProvider(repository: _FakeEncyclopediaRepository()),
      ),
      ChangeNotifierProvider<ConnectivityProvider>(
        create: (_) => _FakeConnectivityProvider(),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: appRouter,
      builder: (context, child) => ProductionSplashGate(
        startupReady: readiness,
        currentRoutePath: () =>
            appRouter.routerDelegate.currentConfiguration.uri.path,
        onDestinationResolved: onDestinationResolved ?? appRouter.go,
        child: child ?? const SizedBox.expand(),
      ),
    ),
  );
}

/// Boots from the real production splash gate and observes the route prepared
/// beneath the animation. Full animation/reveal timing is covered by the
/// focused splash suite; this routing regression test keeps pumps bounded so
/// Home's plugin-backed images and live carousel do not outlive the assertion.
Future<void> _bootFromSplash(
  WidgetTester tester,
  UserProfileProvider profileProvider,
) async {
  appRouter.go(AppRoutes.splash);
  await tester.pumpWidget(_app(tester, profileProvider));
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

String _currentPath() =>
    appRouter.routerDelegate.currentConfiguration.matches.last.matchedLocation;

void main() {
  late PathProviderPlatform originalPathProvider;

  setUpAll(() {
    HttpOverrides.global = PngHttpOverrides();
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
    PathProviderPlatform.instance = originalPathProvider;
  });

  group('LocalUserProfile.isProfileSetupComplete', () {
    test('false when no real role was chosen', () {
      final profile = LocalUserProfile(
        anonymousInstallId: 't',
        userType: CivilUserType.generalUser,
        regionPreferenceCode: RegionPreferenceCode.allIraq,
      );
      expect(profile.isProfileSetupComplete, isFalse);
    });

    test('false when the region preference was never selected', () {
      final profile = LocalUserProfile(
        anonymousInstallId: 't',
        userType: CivilUserType.siteEngineer,
      );
      expect(profile.isProfileSetupComplete, isFalse);
    });

    test('false when the region preference is blank', () {
      for (final blank in ['', '   ']) {
        final profile = LocalUserProfile(
          anonymousInstallId: 't',
          userType: CivilUserType.siteEngineer,
          regionPreferenceCode: blank,
        );
        expect(profile.isProfileSetupComplete, isFalse);
      }
    });

    test('true for a completed A5.8 profile whose legacy BaghdadArea is '
        'still unknown (the restart-persistence regression)', () {
      final profile = LocalUserProfile(
        anonymousInstallId: 't',
        userType: CivilUserType.siteEngineer,
        baghdadArea: BaghdadArea.unknown,
        regionPreferenceCode: RegionPreferenceCode.baghdadRusafa,
      );
      expect(profile.isProfileSetupComplete, isTrue);
    });

    test('true for a completed profile with a legacy locality set too', () {
      final profile = LocalUserProfile(
        anonymousInstallId: 't',
        userType: CivilUserType.contractor,
        baghdadArea: BaghdadArea.karkh,
        regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
      );
      expect(profile.isProfileSetupComplete, isTrue);
    });
  });

  group('Splash restart routing (A5.8 first-launch persistence)', () {
    testWidgets(
      'delayed auth restore settles before the startup route is resolved',
      (tester) async {
        _useTallViewport(tester);
        SharedPreferences.setMockInitialValues({'onboardingSeen': true});
        await PreferencesHelper.init();

        final gateway = _DelayedRestoreAuthGateway();
        final auth = AuthProvider(gateway: gateway);
        final profileProvider = UserProfileProvider(
          repository: _FakeUserProfileRepository(
            LocalUserProfile(
              anonymousInstallId: 'authenticated-returning-user',
              userType: CivilUserType.siteEngineer,
              regionPreferenceCode: RegionPreferenceCode.baghdadRusafa,
            ),
          ),
          auth: auth,
        );
        addTearDown(() {
          profileProvider.dispose();
          auth.dispose();
          gateway.close();
        });
        final startupReady = Future.wait<void>([
          auth.restoreSession(),
          profileProvider.loadProfile(),
        ]);
        var navigationCount = 0;

        appRouter.go(AppRoutes.splash);
        await tester.pumpWidget(
          _app(
            tester,
            profileProvider,
            authProvider: auth,
            startupReady: startupReady,
            onDestinationResolved: (route) {
              navigationCount++;
              appRouter.go(route);
            },
          ),
        );
        await tester.pump();

        expect(gateway.restoreCalls, 1);
        expect(_currentPath(), AppRoutes.splash);
        expect(navigationCount, 0);

        gateway.restoreCompleter.complete(fakeSession);
        await tester.pump();
        await tester.pump();

        expect(auth.isLoggedIn, isTrue);
        expect(
          _currentPath(),
          AppRoutes.profileSetup,
          reason:
              'authenticated authority must settle before the local-profile '
              'startup decision is evaluated',
        );
        expect(navigationCount, 1);

        await tester.pump(const Duration(milliseconds: 300));
        expect(_currentPath(), AppRoutes.profileSetup);
        expect(navigationCount, 1);
      },
    );

    testWidgets('a cold-start non-splash route remains authoritative', (
      tester,
    ) async {
      _useTallViewport(tester);
      SharedPreferences.setMockInitialValues({'onboardingSeen': true});
      await PreferencesHelper.init();

      final profileProvider = UserProfileProvider(
        repository: _FakeUserProfileRepository(null),
      );
      final startupReady = profileProvider.loadProfile();
      var navigationCount = 0;

      appRouter.go(AppRoutes.categories);
      await tester.pumpWidget(
        _app(
          tester,
          profileProvider,
          startupReady: startupReady,
          onDestinationResolved: (route) {
            navigationCount++;
            appRouter.go(route);
          },
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(_currentPath(), AppRoutes.categories);
      expect(navigationCount, 0);

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(
        SplashMotionSpec.totalDuration + const Duration(milliseconds: 100),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(_currentPath(), AppRoutes.categories);
      expect(navigationCount, 0);
      expect(
        find.byKey(CivilpediaSplashAnimationKeys.composition),
        findsNothing,
      );
    });

    testWidgets('a route change during bootstrap is not overwritten', (
      tester,
    ) async {
      _useTallViewport(tester);
      SharedPreferences.setMockInitialValues({'onboardingSeen': true});
      await PreferencesHelper.init();

      final profileProvider = UserProfileProvider(
        repository: _FakeUserProfileRepository(null),
      );
      final readiness = Completer<void>();
      var navigationCount = 0;

      appRouter.go(AppRoutes.splash);
      await tester.pumpWidget(
        _app(
          tester,
          profileProvider,
          startupReady: readiness.future,
          onDestinationResolved: (route) {
            navigationCount++;
            appRouter.go(route);
          },
        ),
      );
      await tester.pump();

      appRouter.go(AppRoutes.categories);
      await tester.pump();
      readiness.complete();
      await tester.pump();
      await tester.pump();

      expect(_currentPath(), AppRoutes.categories);
      expect(navigationCount, 0);

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(
        SplashMotionSpec.totalDuration + const Duration(milliseconds: 100),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(_currentPath(), AppRoutes.categories);
      expect(navigationCount, 0);
      expect(
        find.byKey(CivilpediaSplashAnimationKeys.composition),
        findsNothing,
      );
    });

    testWidgets('a completed A5.8 profile lands on Home, NOT profile-setup, '
        'on every restart', (tester) async {
      _useTallViewport(tester);
      SharedPreferences.setMockInitialValues({'onboardingSeen': true});
      await PreferencesHelper.init();

      final profile = LocalUserProfile(
        anonymousInstallId: 'restart-regression',
        userType: CivilUserType.siteEngineer,
        // A5.8 never requests or maps BaghdadArea — it stays unknown on a
        // completed profile, exactly as stored on the QA emulator.
        baghdadArea: BaghdadArea.unknown,
        regionPreferenceCode: RegionPreferenceCode.baghdadRusafa,
      );
      final provider = UserProfileProvider(
        repository: _FakeUserProfileRepository(profile),
      );

      await _bootFromSplash(tester, provider);

      expect(_currentPath(), AppRoutes.home);
      expect(
        find.byType(ProfileSetupScreen),
        findsNothing,
        reason: 'completed users must never be re-asked Role → Region',
      );
    });

    testWidgets('a completed profile with a legacy locality also lands on '
        'Home', (tester) async {
      _useTallViewport(tester);
      SharedPreferences.setMockInitialValues({'onboardingSeen': true});
      await PreferencesHelper.init();

      final profile = LocalUserProfile(
        anonymousInstallId: 'legacy-complete',
        userType: CivilUserType.structuralEngineer,
        baghdadArea: BaghdadArea.karrada,
        regionPreferenceCode: RegionPreferenceCode.central,
      );
      final provider = UserProfileProvider(
        repository: _FakeUserProfileRepository(profile),
      );

      await _bootFromSplash(tester, provider);

      expect(_currentPath(), AppRoutes.home);
    });

    testWidgets('a fresh install (no profile) still funnels through '
        'profile-setup after onboarding', (tester) async {
      _useTallViewport(tester);
      SharedPreferences.setMockInitialValues({'onboardingSeen': true});
      await PreferencesHelper.init();

      final provider = UserProfileProvider(
        repository: _FakeUserProfileRepository(null),
      );

      await _bootFromSplash(tester, provider);

      expect(_currentPath(), AppRoutes.profileSetup);
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.text(Ar.profileStep1Of2), findsOneWidget);
    });

    testWidgets('onboarding is still the very first gate when it was never '
        'seen', (tester) async {
      _useTallViewport(tester);
      SharedPreferences.setMockInitialValues({'onboardingSeen': false});
      await PreferencesHelper.init();

      final provider = UserProfileProvider(
        repository: _FakeUserProfileRepository(
          LocalUserProfile(anonymousInstallId: 'not-seen'),
        ),
      );

      await _bootFromSplash(tester, provider);

      expect(_currentPath(), AppRoutes.onboarding);
    });

    testWidgets('completed splash does not replay after pause and resume', (
      tester,
    ) async {
      _useTallViewport(tester);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await PreferencesHelper.init();

      final provider = UserProfileProvider(
        repository: _FakeUserProfileRepository(null),
      );

      appRouter.go(AppRoutes.splash);
      await tester.pumpWidget(_app(tester, provider));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await tester.pump(
        SplashMotionSpec.totalDuration + const Duration(milliseconds: 100),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(_currentPath(), AppRoutes.onboarding);
      expect(
        find.byKey(CivilpediaSplashAnimationKeys.composition),
        findsNothing,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(_currentPath(), AppRoutes.onboarding);
      expect(
        find.byKey(CivilpediaSplashAnimationKeys.composition),
        findsNothing,
      );
    });
  });
}
