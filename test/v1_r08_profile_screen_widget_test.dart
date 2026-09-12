import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_error.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/region_preference.dart';
import 'package:civilpedia/features/profile/data/region_preference_gateway.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/profile_screen.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

import 'fakes/fake_auth_gateway.dart';

const _userId = 'uuid-0000-0000';
const _karkhId = '10000000-0000-4000-8000-000000000101';

class _FakeRepo implements UserProfileRepository {
  _FakeRepo([this.stored]);

  LocalUserProfile? stored;

  @override
  Future<LocalUserProfile?> loadProfile() async => stored;

  @override
  Future<void> saveProfile(LocalUserProfile value) async {
    stored = value;
  }

  @override
  Future<void> clearProfile() async {
    stored = null;
  }
}

class _CloudGateway implements PersonalProfileRemoteGateway {
  _CloudGateway({this.cloud});

  CloudProfile? cloud;
  Object? fetchError;
  bool fetchNull = false;
  bool gated = false;
  final Completer<void> _gate = Completer<void>();

  void release() {
    if (gated) {
      gated = false;
      _gate.complete();
    }
  }

  @override
  Future<CloudProfile?> fetchByUserId(String userId) async {
    if (gated) await _gate.future;
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

/// V1-R08 correction (finding 5) — a sign-out whose remote call is parked lets
/// the test observe the single-flight pending state before completion.
class _GatedSignOutGateway extends FakeAuthGateway {
  _GatedSignOutGateway({required this.gate, AuthSession? restoredSession})
      : super(restoredSession: restoredSession);

  final Completer<void>? gate;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (gate != null) await gate!.future;
  }
}

/// V1-R08 correction (finding 3) — the FIRST resolution reports the conflict
/// (stuck), the RETRY resolves to a clean guest (the other account signature
/// was cleared in the interim), which is the accepted recovery path.
class _RecoveredRestoreGateway extends FakeAuthGateway {
  _RecoveredRestoreGateway() : super(restoredSession: fakeSession);

  int restoreCalls = 0;

  @override
  Future<AuthSession?> restoreSession() async {
    restoreCalls++;
    return restoreCalls == 1 ? fakeSession : null;
  }
}

UserProfileProvider _cloudWired(AuthProvider auth, _CloudGateway gateway) {
  return UserProfileProvider(
    repository: _FakeRepo(),
    cloudProfileGateway: gateway,
    regionPreferenceGateway: _PrefGateway(),
    auth: auth,
  );
}

CloudProfile _cloud({String roleCode = 'site_engineer', String? regionId}) {
  return CloudProfile(
    userId: _userId,
    roleCode: roleCode,
    regionPreferenceId: regionId,
  );
}

/// Renders [ProfileScreen] directly with the given side-effect tree. No router
/// timing: state is fully established through the providers before the pump.
Future<void> _pumpProfile(
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
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Finder _logoutHeaderButton() => find.ancestor(
      of: find.text(Ar.logout),
      matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
    );

void main() {
  group('V1-R08 ProfileScreen', () {
    testWidgets('a guest sees the local profile card, visitor identity and a '
        'Login affordance (no sign-out)', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(), // guest: no restore performed
      );
      final profileProvider = UserProfileProvider(
        repository: _FakeRepo(
          LocalUserProfile(
            anonymousInstallId: 'p1-guest',
            userType: CivilUserType.siteEngineer,
            baghdadArea: BaghdadArea.karkh,
          ),
        ),
        auth: auth,
      );
      await profileProvider.loadProfile();
      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text(Ar.visitor), findsOneWidget);
      expect(find.text(Ar.notRegistered), findsOneWidget);
      expect(find.text(Ar.login), findsOneWidget);
      expect(find.text(Ar.siteEngineer), findsOneWidget,
          reason: 'a guest owns the on-device profile');
      expect(find.text(Ar.logout), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an authenticated cloud profile renders the read-only '
        'role + region with an explicit Edit affordance', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(
        cloud: _cloud(regionId: _karkhId),
      );
      final profileProvider = _cloudWired(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      expect(profileProvider.isCloudBound, isTrue);
      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(find.text(Ar.regionBaghdadKarkh), findsOneWidget);
      expect(find.text(Ar.editProfile), findsOneWidget);
      expect(find.text(Ar.logout), findsOneWidget);
      expect(find.text(Ar.visitor), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a cloud read failure shows the typed error and Recovers on '
        'Retry (local is never a fallback)', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud())
        ..fetchError = Exception('offline');
      final profileProvider = _cloudWired(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      expect(profileProvider.cloudLoadFailed, isTrue);
      expect(profileProvider.profile, isNull,
          reason: 'a failing cloud read never resurrects a local surrogate');
      expect(find.text(Ar.profileCloudLoadFailed), findsOneWidget);

      gateway.fetchError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(profileProvider.isCloudBound, isTrue);
      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an in-flight cloud load shows the explicit loading row, '
        'never "not set"', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud())..gated = true;
      final profileProvider = _cloudWired(auth, gateway);
      await auth.restoreSession();
      // The auth listener fires ensureCloudProfileLoaded which is now parked.

      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider,
          settle: false);
      await tester.pump();

      expect(profileProvider.isCloudProfileLoading, isTrue);
      expect(find.text(Ar.profileCloudLoading), findsOneWidget);
      expect(find.text(Ar.profileNotSet), findsNothing,
          reason: 'a pending read must not be presented as "not set"');

      gateway.release();
      await tester.pumpAndSettle();

      expect(profileProvider.isCloudBound, isTrue);
      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an authenticated session with no cloud row renders "not '
        'set" (fail closed, no fabrication)', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway()..fetchNull = true;
      final profileProvider = _cloudWired(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      expect(profileProvider.isCloudProfileLoading, isFalse);
      expect(profileProvider.cloudLoadFailed, isFalse);
      expect(profileProvider.authenticatedProfile, isNull);
      expect(find.text(Ar.profileNotSet), findsOneWidget);
      expect(find.text(Ar.siteEngineer), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sign-out confirms, Cancel keeps the session, Confirm returns '
        'to the guest identity', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final profileProvider = _cloudWired(auth, _CloudGateway(cloud: _cloud()));
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(_logoutHeaderButton());
      await tester.pumpAndSettle();
      expect(find.text(Ar.signOutConfirmMessage), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, Ar.cancel));
      await tester.pumpAndSettle();
      expect(auth.isLoggedIn, isTrue,
          reason: 'cancelling the confirmation must not sign out');
      expect(_logoutHeaderButton(), findsOneWidget);

      await tester.tap(_logoutHeaderButton());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, Ar.logout));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(find.text(Ar.visitor), findsOneWidget);
      expect(find.text(Ar.login), findsOneWidget);
      expect(find.text(Ar.logout), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed sign-out exposes the recoverable snackbar and Retry '
        'succeeds', (tester) async {
      final gateway = FakeAuthGateway(
        restoredSession: fakeSession,
        signOutError: Exception('boom'),
      );
      final auth = AuthProvider(gateway: gateway);
      final profileProvider = _cloudWired(auth, _CloudGateway(cloud: _cloud()));
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(_logoutHeaderButton());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, Ar.logout));
      await tester.pumpAndSettle();

      expect(auth.error, AuthError.signOutFailed);
      expect(auth.isLoggedIn, isTrue,
          reason: 'a failed remote sign-out never claims guest');
      expect(find.text(Ar.signOutFailed), findsOneWidget);

      gateway.signOutError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(find.text(Ar.visitor), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an ownership conflict blocks the whole profile area '
        '(fail closed)', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );
      final profileProvider = _cloudWired(auth, _CloudGateway(cloud: _cloud()));
      await auth.restoreSession();

      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      expect(auth.isOwnershipBlocked, isTrue);
      expect(find.text(Ar.authAccountConflictTitle), findsOneWidget);
      expect(find.text(Ar.logout), findsNothing);
      expect(find.text(Ar.siteEngineer), findsNothing,
          reason: 'no profile affordances while blockingly bound to another '
              'account');
      expect(tester.takeException(), isNull);
    });

    testWidgets('W3.4 compat: an authenticated session over a NON-cloud-wired '
        'provider keeps the local profile card', (tester) async {
      // The user-area route-test world wires providers without `auth`; for
      // those screens the local card stays authoritative (branch 5).
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final profileProvider = UserProfileProvider(
        repository: _FakeRepo(
          LocalUserProfile(
            anonymousInstallId: 'p9-compat',
            userType: CivilUserType.siteEngineer,
            baghdadArea: BaghdadArea.karkh,
          ),
        ),
      );
      await profileProvider.loadProfile();
      await auth.restoreSession();

      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(find.text(Ar.profileMainWorkArea), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ---------------------------------------------------------------
    // V1-R08 Part 2 correction coverage (findings 1/3/5/9)
    // ---------------------------------------------------------------
    testWidgets('a LIVE session-loss event immediately reverts the profile '
        'area to the guest card', (tester) async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final auth = AuthProvider(gateway: gateway);
      final profileProvider = _cloudWired(
        auth,
        _CloudGateway(cloud: _cloud(roleCode: 'site_engineer', regionId: _karkhId)),
      );
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text(Ar.siteEngineer), findsOneWidget);

      gateway.emit(const AuthEvent(type: AuthEventType.sessionLost));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(find.text(Ar.visitor), findsOneWidget);
      expect(find.text(Ar.login), findsOneWidget);
      expect(find.text(Ar.siteEngineer), findsNothing,
          reason: 'no cloud identity after the session is externally lost');
      expect(find.text(Ar.logout), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a sign-out in flight is single-flight: the action disables '
        'with progress and the guest card lands only on completion',
        (tester) async {
      final gate = Completer<void>();
      final gateway = _GatedSignOutGateway(
        gate: gate,
        restoredSession: fakeSession,
      );
      final auth = AuthProvider(gateway: gateway);
      final profileProvider = _cloudWired(
        auth,
        _CloudGateway(cloud: _cloud(roleCode: 'site_engineer', regionId: _karkhId)),
      );
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(_logoutHeaderButton());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, Ar.logout));
      await tester.pump();

      expect(auth.isSigningOut, isTrue);
      expect(gateway.signOutCalls, 1);
      expect(find.text(Ar.signOutPendingLabel), findsOneWidget,
          reason: 'the disabled pending affordance is observably rendered');
      expect(find.text('م. أحمد'), findsOneWidget,
          reason: 'the identity is preserved while the sign-out is pending');
      expect(find.text(Ar.visitor), findsNothing);
      final pendingButton = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(Ar.signOutPendingLabel),
          matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
        ),
      );
      expect(pendingButton.onPressed, isNull,
          reason: 'a pending sign-out cannot be re-triggered');

      // Duplicate attempt stays inert (single-flight).
      await tester.tap(
        find.ancestor(
          of: find.text(Ar.signOutPendingLabel),
          matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
        ),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(gateway.signOutCalls, 1,
          reason: 'no duplicate sign-out may start while pending');

      gate.complete();
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(find.text(Ar.visitor), findsOneWidget);
      expect(find.text(Ar.login), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an ownership conflict offers Retry resolution; a resolved '
        'conflict collapses to the credited guest path (no dead-end)',
        (tester) async {
      final gateway = _RecoveredRestoreGateway();
      final auth = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );
      final profileProvider = _cloudWired(
        auth,
        _CloudGateway(cloud: _cloud(roleCode: 'site_engineer', regionId: _karkhId)),
      );
      await auth.restoreSession();
      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      expect(auth.isOwnershipBlocked, isTrue);
      expect(find.text(Ar.authAccountConflictTitle), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.text(Ar.logout), findsNothing);

      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      // The retry resolved the account signature to a clean guest.
      expect(auth.isOwnershipBlocked, isFalse);
      expect(auth.error, isNull);
      expect(find.text(Ar.visitor), findsOneWidget,
          reason: 'a resolved conflict falls back to the credited guest path');
      expect(find.text(Ar.login), findsOneWidget,
          reason: 'Login resumes the sign-in flow');
      expect(find.text(Ar.retry), findsNothing);
      expect(find.text(Ar.logout), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('English locale renders the full English profile copy (no '
        'forced Arabic, no raw codes)', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final profileProvider = _cloudWired(
        auth,
        _CloudGateway(cloud: _cloud(roleCode: 'site_engineer', regionId: _karkhId)),
      );
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _pumpProfile(
        tester,
        auth: auth,
        profileProvider: profileProvider,
        isArabic: false,
      );

      expect(find.text(En.profile), findsOneWidget,
          reason: 'the AppBar title follows the active locale');
      expect(find.text(En.siteEngineer), findsOneWidget);
      expect(find.text(En.regionBaghdadKarkh), findsOneWidget);
      expect(find.text(En.editProfile), findsOneWidget);
      expect(find.text(En.logout), findsOneWidget);
      expect(find.text(Ar.siteEngineer), findsNothing);
      expect(find.text('site_engineer'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}