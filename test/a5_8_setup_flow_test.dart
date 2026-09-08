import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
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
              EncyclopediaProvider(repository: _FakeEncyclopediaRepository())),
      ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => _FakeConnectivityProvider()),
    ],
    child: MaterialApp.router(routerConfig: appRouter),
  );
}

/// Navigates the canonical [appRouter] to [path] before attaching it, so the
/// test never renders the app's splash/onboarding origin. Both the fresh
/// first-launch funnel and the onboarding "Skip" button land here
/// (OnboardingScreen._complete → context.go('/profile-setup')).
Future<void> _open(
  WidgetTester tester,
  UserProfileProvider profileProvider,
  String path,
) async {
  appRouter.go(path);
  await tester.pumpWidget(_app(tester, profileProvider));
  await tester.pumpAndSettle();
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

String _currentPath() =>
    appRouter.routerDelegate.currentConfiguration.matches.last.matchedLocation;

Future<void> _completeJourney(
  WidgetTester tester,
  String roleLabel,
  String regionLabel,
) async {
  await tester.tap(find.text(roleLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, Ar.profileContinue));
  await tester.pumpAndSettle();
  await tester.tap(find.text(regionLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, Ar.profileComplete));
  // Home's ad article carousel keeps an auto-scroll timer alive, so a settle
  // would hang the fake clock — bounded pumps only (established Home harness
  // pattern). The save + go('/home') complete within these frames.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() {
    HttpOverrides.global = PngHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('A5.8 fresh first-launch journey is exactly Role → Region '
      'Preference → Home', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeUserProfileRepository(null);
    final profileProvider = UserProfileProvider(repository: repository);

    await _open(tester, profileProvider, AppRoutes.profileSetup);

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.text(Ar.profileStep1Of2), findsOneWidget);

    await _completeJourney(tester, Ar.siteEngineer, Ar.regionAllIraq);

    expect(_currentPath(), AppRoutes.home);
    expect(repository.stored, isNotNull);
    expect(repository.stored!.userType, CivilUserType.siteEngineer);
    expect(repository.stored!.regionPreferenceCode,
        RegionPreferenceCode.allIraq);
  });

  testWidgets('A5.8 skip-onboarding entry (shared /profile-setup seam) still '
      'enforces Role → Region Preference → Home', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeUserProfileRepository(null);
    final profileProvider = UserProfileProvider(repository: repository);

    await _open(tester, profileProvider, AppRoutes.profileSetup);

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.text(Ar.profileStep1Of2), findsOneWidget,
        reason: 'onboarding funnel + Skip both land on /profile-setup');

    await _completeJourney(tester, Ar.contractorName, Ar.regionNorth);

    expect(_currentPath(), AppRoutes.home);
    expect(repository.stored!.userType, CivilUserType.contractor);
    expect(repository.stored!.regionPreferenceCode,
        RegionPreferenceCode.north);
  });

  testWidgets('A5.8 step counter is exactly 1/2 → 2/2', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeUserProfileRepository(null);
    final profileProvider = UserProfileProvider(repository: repository);

    await _open(tester, profileProvider, AppRoutes.profileSetup);

    expect(find.text(Ar.profileStep1Of2), findsOneWidget);
    expect(find.text(Ar.profileStep2Of2), findsNothing);

    await tester.tap(find.text(Ar.siteEngineer));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, Ar.profileContinue));
    await tester.pumpAndSettle();

    expect(find.text(Ar.profileStep2Of2), findsOneWidget);
    expect(find.text(Ar.profileStep1Of2), findsNothing);
  });

  testWidgets('A5.8 back from Region Preference returns to Role selection',
      (tester) async {
    _useTallViewport(tester);
    final repository = _FakeUserProfileRepository(null);
    final profileProvider = UserProfileProvider(repository: repository);

    await _open(tester, profileProvider, AppRoutes.profileSetup);

    await tester.tap(find.text(Ar.siteEngineer));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, Ar.profileContinue));
    await tester.pumpAndSettle();

    expect(find.text(Ar.profileStep2Of2), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text(Ar.profileStep1Of2), findsOneWidget);
    expect(find.text(Ar.siteEngineer), findsOneWidget,
        reason: 'role selection retained when going back');
  });

  testWidgets('A5.8 no BaghdadArea selector appears anywhere in first-launch '
      'setup', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeUserProfileRepository(null);
    final profileProvider = UserProfileProvider(repository: repository);

    await _open(tester, profileProvider, AppRoutes.profileSetup);

    for (final area in BaghdadArea.values) {
      if (area == BaghdadArea.unknown) continue;
      expect(find.text(area.arName), findsNothing,
          reason: '${area.arName} must not appear in first-launch setup');
      expect(find.text(area.enName), findsNothing);
    }

    await tester.tap(find.text(Ar.structuralEngineer));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, Ar.profileContinue));
    await tester.pumpAndSettle();

    for (final area in BaghdadArea.values) {
      if (area == BaghdadArea.unknown) continue;
      expect(find.text(area.arName), findsNothing,
          reason: 'still no BaghdadArea locality on the Region step');
    }
  });

  testWidgets('A5.8 all six frozen Region Preference options render with their '
      'canonical labels', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeUserProfileRepository(null);
    final profileProvider = UserProfileProvider(repository: repository);

    await _open(tester, profileProvider, AppRoutes.profileSetup);
    await tester.tap(find.text(Ar.siteEngineer));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, Ar.profileContinue));
    await tester.pumpAndSettle();

    const labels = [
      Ar.regionBaghdadKarkh,
      Ar.regionBaghdadRusafa,
      Ar.regionNorth,
      Ar.regionCentral,
      Ar.regionSouth,
      Ar.regionAllIraq,
    ];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget,
          reason: 'region option "$label" must be present');
    }
  });

  testWidgets('A5.8 completed setup persists BaghdadArea as untouched legacy '
      'unknown (never requested, never mapped)', (tester) async {
    _useTallViewport(tester);
    final repository = _FakeUserProfileRepository(null);
    final profileProvider = UserProfileProvider(repository: repository);

    await _open(tester, profileProvider, AppRoutes.profileSetup);
    await _completeJourney(tester, Ar.engineeringStudent, Ar.regionSouth);

    expect(_currentPath(), AppRoutes.home);
    expect(repository.stored!.baghdadArea, BaghdadArea.unknown,
        reason: 'legacy locality default preserved; first-launch never asks');
    expect(repository.stored!.regionPreferenceCode,
        RegionPreferenceCode.south);
  });
}