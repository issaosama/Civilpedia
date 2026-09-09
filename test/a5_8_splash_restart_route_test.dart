import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/data/local/preferences_helper.dart';
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
import 'package:civilpedia/features/splash/presentation/splash_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_router.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'helpers/png_http_overrides.dart';

class _FakeConnectivityProvider extends ConnectivityProvider {
  _FakeConnectivityProvider() : super();
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
          String topicId, String sectionId) async =>
      const [];

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

Widget _app(WidgetTester tester, UserProfileProvider profileProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider.value(value: profileProvider),
      ChangeNotifierProvider(
        create: (_) =>
            EncyclopediaProvider(repository: _FakeEncyclopediaRepository()),
      ),
      ChangeNotifierProvider<ConnectivityProvider>(
        create: (_) => _FakeConnectivityProvider(),
      ),
    ],
    child: MaterialApp.router(routerConfig: appRouter),
  );
}

/// Boots from the real [SplashScreen] origin (fresh router take) and pumps just
/// past [AppConstants.splashDuration] so `_navigate` completes. Home's ad
/// carousel keeps a live timer, so only bounded pumps are used after the
/// routing decision.
Future<void> _bootFromSplash(
  WidgetTester tester,
  UserProfileProvider profileProvider,
) async {
  appRouter.go(AppRoutes.splash);
  await tester.pumpWidget(_app(tester, profileProvider));
  await tester.pump(const Duration(seconds: 2));
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
  setUpAll(() {
    HttpOverrides.global = PngHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
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
      final provider =
          UserProfileProvider(repository: _FakeUserProfileRepository(profile));

      await _bootFromSplash(tester, provider);

      expect(_currentPath(), AppRoutes.home);
      expect(find.byType(ProfileSetupScreen), findsNothing,
          reason: 'completed users must never be re-asked Role → Region');
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
      final provider =
          UserProfileProvider(repository: _FakeUserProfileRepository(profile));

      await _bootFromSplash(tester, provider);

      expect(_currentPath(), AppRoutes.home);
    });

    testWidgets('a fresh install (no profile) still funnels through '
        'profile-setup after onboarding', (tester) async {
      _useTallViewport(tester);
      SharedPreferences.setMockInitialValues({'onboardingSeen': true});
      await PreferencesHelper.init();

      final provider =
          UserProfileProvider(repository: _FakeUserProfileRepository(null));

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
  });
}