import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/region_preference.dart';
import 'package:civilpedia/features/profile/data/region_preference_gateway.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/features/profile/presentation/screens/authenticated_profile_edit_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

import 'fakes/fake_auth_gateway.dart';

const _userId = 'uuid-0000-0000';
const _karkhId = '10000000-0000-4000-8000-000000000101';

class _FakeRepo implements UserProfileRepository {
  @override
  Future<LocalUserProfile?> loadProfile() async => null;

  @override
  Future<void> saveProfile(LocalUserProfile value) async {}

  @override
  Future<void> clearProfile() async {}
}

class _CloudGateway implements PersonalProfileRemoteGateway {
  _CloudGateway({this.cloud});

  CloudProfile? cloud;
  Object? fetchError;
  bool fetchNull = false;
  bool gated = false;
  Object? saveError;
  int saveCalls = 0;
  String? lastSavedRole;
  Completer<void>? saveGate;
  final Completer<void> _loadGate = Completer<void>();

  void release() {
    if (gated) {
      gated = false;
      _loadGate.complete();
    }
  }

  @override
  Future<CloudProfile?> fetchByUserId(String userId) async {
    if (gated) await _loadGate.future;
    if (fetchError != null) throw fetchError!;
    if (fetchNull) return null;
    return cloud;
  }

  @override
  Future<void> createProfile(CloudProfile profile) async {
    cloud = profile;
  }

  @override
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  }) async {}

  @override
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) async {
    saveCalls++;
    if (saveGate != null) await saveGate!.future;
    if (saveError != null) throw saveError!;
    lastSavedRole = roleCode;
    cloud = CloudProfile(
      userId: userId,
      roleCode: roleCode,
      regionPreferenceId: regionPreferenceId ?? cloud?.regionPreferenceId,
    );
  }
}

class _PrefGateway implements RegionPreferenceGateway {
  @override
  Future<String?> resolvePreferenceIdByCode(String code) async {
    return code == RegionPreferenceCode.baghdadKarkh ? _karkhId : null;
  }

  @override
  Future<String?> resolveCodeById(String id) async {
    return id == _karkhId ? RegionPreferenceCode.baghdadKarkh : null;
  }
}

UserProfileProvider _provider(AuthProvider auth, _CloudGateway gateway) {
  return UserProfileProvider(
    repository: _FakeRepo(),
    cloudProfileGateway: gateway,
    regionPreferenceGateway: _PrefGateway(),
    auth: auth,
  );
}

CloudProfile _cloud({String? roleCode, String? regionId}) {
  return CloudProfile(
    userId: _userId,
    roleCode: roleCode,
    regionPreferenceId: regionId,
  );
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Hosts the editor as a real pushed route (Navigator.insert/PageRoute push
/// over a plain home) so AppBar back, PopScope interception and direct
/// [Navigator.pop] on discard behave EXACTLY like production.
Future<void> _pumpEditor(
  WidgetTester tester, {
  required AuthProvider auth,
  required UserProfileProvider profileProvider,
  bool settle = true,
  bool isArabic = true,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider(isArabic: isArabic)),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: profileProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AuthenticatedProfileEditScreen(),
                  ),
                ),
                child: const Text('open-editor'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open-editor'));
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

void main() {
  group('V1-R08 AuthenticatedProfileEditScreen', () {
    testWidgets('a lost session renders the non-editing session-lost state', (
      tester,
    ) async {
      final auth = AuthProvider(gateway: FakeAuthGateway()); // guest
      await _pumpEditor(
        tester,
        auth: auth,
        profileProvider: _provider(auth, _CloudGateway(cloud: _cloud())),
      );

      expect(find.byType(AuthenticatedProfileEditScreen), findsOneWidget);
      expect(find.text(Ar.authSessionLost), findsOneWidget);
      expect(find.text(Ar.profileRole), findsNothing,
          reason: 'no form without a session');
      expect(tester.takeException(), isNull);
    });

    testWidgets('an in-flight cloud read shows the loading state, then the '
        'form after the row settles', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud(roleCode: 'site_engineer'))
        ..gated = true;
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      // The auth listener parked ensureCloudProfileLoaded on the gate.

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider,
          settle: false);
      await tester.pump(const Duration(milliseconds: 120));

      expect(profileProvider.isCloudProfileLoading, isTrue);
      expect(find.text(Ar.profileCloudLoading), findsOneWidget);
      expect(find.text(Ar.profileRole), findsNothing,
          reason: 'never show a form for a row that has not loaded');

      gateway.release();
      await tester.pumpAndSettle();

      expect(profileProvider.isCloudBound, isTrue);
      expect(find.text(Ar.profileRole), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a cloud read failure shows the typed error and Recovers via '
        'Retry', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud())
        ..fetchError = Exception('offline');
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      expect(profileProvider.cloudLoadFailed, isTrue);
      expect(find.text(Ar.profileCloudLoadFailed), findsOneWidget);

      gateway.fetchError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(profileProvider.isCloudBound, isTrue);
      expect(find.text(Ar.profileRole), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a settled-empty cloud state fails closed (never a form)', (
      tester,
    ) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway()..fetchNull = true;
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      expect(profileProvider.authenticatedProfile, isNull);
      expect(find.text(Ar.profileNotAvailable), findsOneWidget);
      expect(find.text(Ar.goToProfile), findsOneWidget);
      expect(find.text(Ar.profileRole), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the form preselects canonical defaults and disables Save '
        'until dirty', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(
        cloud: _cloud(), // no roleCode → canonical general_user fallback
      );
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text(Ar.generalUser), findsOneWidget,
          reason: 'an empty role falls back to the canonical general_user');
      expect(find.text(Ar.profileNotSet), findsOneWidget,
          reason: 'region "Not set" exists only as the initial state');
      final save = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Ar.profileSaveChanges),
      );
      expect(save.onPressed, isNull, reason: 'Save stays disabled until dirty');
      expect(tester.takeException(), isNull);
    });

    testWidgets('picking a role replays the value, enables Save, and only '
        'canonical roles are offered', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud());
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();

      expect(find.text(Ar.profileChangeRole), findsOneWidget);
      expect(find.text(Ar.consultantEngineer), findsOneWidget,
          reason: 'canonical roles are the only choices');

      await tester.tap(find.widgetWithText(SimpleDialogOption, Ar.consultantEngineer));
      await tester.pumpAndSettle();

      expect(find.text(Ar.consultantEngineer), findsOneWidget);
      expect(find.text(Ar.generalUser), findsNothing);
      final save = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Ar.profileSaveChanges),
      );
      expect(save.onPressed, isNotNull, reason: 'a changed selection enables '
          'Save');
      expect(tester.takeException(), isNull);
    });

    testWidgets('picking a region offers only the six canonical zones and '
        'enables Save', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud());
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(
        find.widgetWithText(ListTile, Ar.profileRegionPreference),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.profileChangeRegionPreference), findsOneWidget);
      expect(find.text(Ar.profileNotSet), findsOneWidget,
          reason: '"Not set" is never a selectable choice, only the initial '
              'value');
      expect(find.byType(SimpleDialogOption), findsNWidgets(6),
          reason: 'RegionPreferenceCode.all is exactly the six canonical '
              'zones');

      await tester.tap(
        find.widgetWithText(SimpleDialogOption, Ar.regionNorth),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.regionNorth), findsOneWidget);
      final save = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Ar.profileSaveChanges),
      );
      expect(save.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Save writes the authoritative values, re-baselines and stays '
        'on screen with a success snackbar', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud());
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SimpleDialogOption, Ar.consultantEngineer),
      );
      await tester.pumpAndSettle();
      final save = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Ar.profileSaveChanges),
      );
      expect(save.onPressed, isNotNull);

      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.profileSaveChanges),
      );
      await tester.pumpAndSettle();

      expect(gateway.saveCalls, 1);
      expect(gateway.lastSavedRole, 'consultant_engineer');
      expect(profileProvider.authenticatedProfile?.roleCode,
          'consultant_engineer');
      expect(find.text(Ar.profileUpdated), findsOneWidget);
      expect(find.byType(AuthenticatedProfileEditScreen), findsOneWidget,
          reason: 'Save stays on-screen by design');
      final afterSave = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Ar.profileSaveChanges),
      );
      expect(afterSave.onPressed, isNull,
          reason: 'the form re-baselines and clears dirty after success');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a retryable save failure preserves the draft, shows the '
        'typed cause and Retry succeeds', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud())
        ..saveError = Exception('network');
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SimpleDialogOption, Ar.consultantEngineer),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.profileSaveChanges),
      );
      await tester.pumpAndSettle();

      expect(gateway.saveCalls, 1);
      expect(find.text(Ar.profileCauseRetryable), findsOneWidget);
      expect(find.text(Ar.consultantEngineer), findsOneWidget,
          reason: 'a failed save preserves the in-editor draft');

      gateway.saveError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(gateway.saveCalls, 2);
      expect(gateway.lastSavedRole, 'consultant_engineer');
      expect(profileProvider.authenticatedProfile?.roleCode,
          'consultant_engineer');
      expect(find.text(Ar.profileUpdated), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Back with unsaved changes is guarded: Stay keeps the editor, '
        'Discard pops it', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud());
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SimpleDialogOption, Ar.consultantEngineer),
      );
      await tester.pumpAndSettle();
      expect(find.text(Ar.consultantEngineer), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(Ar.profileUnsavedTitle), findsOneWidget);

      await tester.tap(find.text(Ar.profileStay));
      await tester.pumpAndSettle();
      expect(find.byType(AuthenticatedProfileEditScreen), findsOneWidget,
          reason: 'Stay keeps the dirty editor on screen');

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(Ar.profileUnsavedTitle), findsOneWidget);
      await tester.tap(find.text(Ar.profileDiscard));
      await tester.pumpAndSettle();

      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);
      expect(find.text('open-editor'), findsOneWidget,
          reason: 'Discard pops the editor and lands back on the host');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a canonical cloud re-read re-syncs the form and clears dirty '
        '(identity-switch guard)', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(
        cloud: _cloud(roleCode: 'site_engineer', regionId: _karkhId),
      );
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(find.text(Ar.regionBaghdadKarkh), findsOneWidget);

      // Make the form dirty, then publish a NEW authoritative row: the form
      // must re-baseline to the SSOT and clear dirty.
      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SimpleDialogOption, Ar.structuralEngineer),
      );
      await tester.pumpAndSettle();
      expect(find.text(Ar.structuralEngineer), findsOneWidget);

      gateway.cloud = _cloud(
        roleCode: 'consultant_engineer',
        regionId: _karkhId,
      );
      await profileProvider.ensureCloudProfileLoaded();
      await tester.pumpAndSettle();

      expect(find.text(Ar.consultantEngineer), findsOneWidget);
      expect(find.text(Ar.structuralEngineer), findsNothing,
          reason: 'the form re-baselines to the authoritative cloud row');
      expect(find.text(Ar.regionBaghdadKarkh), findsOneWidget);
      final save = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Ar.profileSaveChanges),
      );
      expect(save.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    // ---------------------------------------------------------------
    // V1-R08 Part 2 correction coverage (findings 1/4/5/9)
    // ---------------------------------------------------------------
    testWidgets('Back with NO changes leaks the editor immediately (no '
        'spurious guard dialog)', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud());
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(Ar.profileUnsavedTitle), findsNothing,
          reason: 'a clean editor must never be discarded-guarded');
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);
      expect(find.text('open-editor'), findsOneWidget,
          reason: 'Back lands straight on the host');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a save in flight is single-flight: the form locks and a '
        'duplicate save cannot start', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud())
        ..saveGate = Completer<void>();
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SimpleDialogOption, Ar.consultantEngineer),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.profileSaveChanges),
      );
      await tester.pump();

      expect(gateway.saveCalls, 1);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
        reason: 'Save is disabled while a save is in flight',
      );

      // The locked form rejects re-entry into the role picker.
      await tester.tap(
        find.widgetWithText(ListTile, Ar.profileRole),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.text(Ar.profileChangeRole), findsNothing,
          reason: 'no re-entry while a save is pending');

      gateway.saveGate!.complete();
      await tester.pumpAndSettle();

      expect(gateway.saveCalls, 1, reason: 'duplicate saves never start');
      expect(find.text(Ar.profileUpdated), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('after a successful save the form is clean: Back exits '
        'without a discard dialog', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud());
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SimpleDialogOption, Ar.consultantEngineer),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.profileSaveChanges),
      );
      await tester.pumpAndSettle();

      expect(gateway.lastSavedRole, 'consultant_engineer');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text(Ar.profileUnsavedTitle), findsNothing,
          reason: 'a re-baselined clean form pops without a guard');
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);
      expect(find.text('open-editor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a LIVE session-loss event replaces the editor with the '
        'non-editing session-lost state', (tester) async {
      _useTallViewport(tester);
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final auth = AuthProvider(gateway: gateway);
      final profileProvider = _provider(
        auth,
        _CloudGateway(cloud: _cloud(roleCode: 'site_engineer')),
      );
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text(Ar.profileRole), findsOneWidget);

      gateway.emit(const AuthEvent(type: AuthEventType.sessionLost));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(find.text(Ar.authSessionLost), findsOneWidget);
      expect(find.text(Ar.profileRole), findsNothing,
          reason: 'no editing affordances without a session');
      expect(find.text(Ar.profileSaveChanges), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('English locale renders the editor and cloud card in English '
        '(no forced Arabic, no raw codes)', (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final profileProvider = _provider(
        auth,
        _CloudGateway(
          cloud: _cloud(roleCode: 'site_engineer', regionId: _karkhId),
        ),
      );
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _pumpEditor(
        tester,
        auth: auth,
        profileProvider: profileProvider,
        isArabic: false,
      );

      expect(find.text(En.profileEditCloudTitle), findsOneWidget);
      expect(find.text(En.profileRole), findsOneWidget);
      expect(find.text(En.siteEngineer), findsOneWidget);
      expect(find.text(En.regionBaghdadKarkh), findsOneWidget);
      expect(find.text(En.profileSaveChanges), findsOneWidget);
      expect(find.text(Ar.profileSaveChanges), findsNothing);
      expect(find.text('site_engineer'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}