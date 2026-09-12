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
import 'package:civilpedia/features/business/domain/business_application_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_staff_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:civilpedia/features/business/domain/staff_application_capabilities.dart';
import 'package:civilpedia/features/business/domain/staff_application_detail.dart';
import 'package:civilpedia/features/business/domain/staff_application_summary.dart';
import 'package:civilpedia/features/business/domain/staff_read_result.dart';
import 'package:civilpedia/features/business/presentation/providers/staff_access_provider.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/region_preference.dart';
import 'package:civilpedia/features/profile/data/region_preference_gateway.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/features/user_area/presentation/user_area_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

import 'fakes/fake_auth_gateway.dart';

const _sessionId = 'w3-4-authenticated-user';
final _session = AuthSession(
  userId: _sessionId,
  email: 'w3.4@civilpedia.test',
  displayName: 'W3.4 Tester',
);
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
  }) async {}
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

class _FakeStaffAccessGateway implements BusinessApplicationStaffGateway {
  @override
  bool get isAvailable => true;

  @override
  Future<StaffReadResult<StaffApplicationCapabilities>>
      getCapabilities() async =>
          const StaffReadSuccess(StaffApplicationCapabilities.empty());

  @override
  Future<StaffReadResult<StaffApplicationPage>> listApplications({
    BusinessApplicationStatus? statusFilter,
    BusinessApplicationType? typeFilter,
    int limit = 25,
    StaffApplicationCursor? cursor,
  }) async => const StaffReadSuccess(StaffApplicationPage(items: []));

  @override
  Future<StaffReadResult<StaffApplicationDetail>> getApplicationDetail(
    String applicationId,
  ) async => const StaffReadDenied(
    BusinessApplicationStaffCause.applicationNotFound,
  );

  @override
  Future<BusinessApplicationStaffResult> beginReview(
      String applicationId) async =>
      const BusinessApplicationStaffDenied(
          BusinessApplicationStaffCause.staffPermissionDenied);

  @override
  Future<BusinessApplicationStaffResult> returnForCorrection(
    String applicationId, {
    required String reason,
  }) async => const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.staffPermissionDenied);

  @override
  Future<BusinessApplicationStaffResult> markContacted(
    String applicationId, {
    required String contactType,
    String? result,
    String? notes,
  }) async => const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.staffPermissionDenied);

  @override
  Future<BusinessApplicationStaffResult> scheduleVisit(
    String applicationId, {
    required DateTime scheduledAt,
    String? location,
    String? notes,
  }) async => const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.staffPermissionDenied);

  @override
  Future<BusinessApplicationStaffResult> approve(String applicationId) async =>
      const BusinessApplicationStaffDenied(
          BusinessApplicationStaffCause.staffPermissionDenied);

  @override
  Future<BusinessApplicationStaffResult> reject(
    String applicationId, {
    required String reason,
  }) async => const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.staffPermissionDenied);

  @override
  Future<BusinessApplicationStaffResult> activate(
      String applicationId) async =>
      const BusinessApplicationStaffDenied(
          BusinessApplicationStaffCause.staffPermissionDenied);
}

UserProfileProvider _cloudWired(
  AuthProvider auth,
  _CloudGateway gateway, {
  UserProfileRepository? repository,
}) {
  return UserProfileProvider(
    repository: repository ?? _FakeRepo(),
    cloudProfileGateway: gateway,
    regionPreferenceGateway: _PrefGateway(),
    auth: auth,
  );
}

CloudProfile _cloud({String roleCode = 'site_engineer', String? regionId}) {
  return CloudProfile(
    userId: _sessionId,
    roleCode: roleCode,
    regionPreferenceId: regionId,
  );
}

/// V1-R08 correction (finding 5) — a sign-out whose remote call is parked lets
/// the test observe the single-flight pending header state.
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
/// (stuck header), the RETRY resolves to a clean guest (accepted recovery).
class _RecoveredRestoreGateway extends FakeAuthGateway {
  _RecoveredRestoreGateway({required AuthSession session})
      : super(restoredSession: session);

  int restoreCalls = 0;

  @override
  Future<AuthSession?> restoreSession() async {
    restoreCalls++;
    return restoreCalls == 1 ? restoredSession : null;
  }
}

AuthProvider _guestAuth() => AuthProvider(gateway: FakeAuthGateway());

/// Renders the User Area hub without a router: navigation paths
/// (`/user/profile/edit`, `/auth`, the card pushes) are covered by the
/// route-level suite; here we only exercise header identity/cloud behavior.
Future<void> _openHub(
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
        ChangeNotifierProvider(
          create: (context) => StaffAccessProvider(
            gateway: _FakeStaffAccessGateway(),
            auth: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider.value(value: profileProvider),
      ],
      child: const MaterialApp(home: UserAreaScreen()),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Finder _logoutHeaderButton() => find.ancestor(
      of: find.text(Ar.logout),
      matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
    );

void main() {
  group('V1-R08 UserArea header', () {
    testWidgets('a guest sees the visitor identity, a sign-in prompt + Login '
        'button and the exact 5-tile navigation inventory', (tester) async {
      final auth = _guestAuth();
      final profileProvider = _cloudWired(auth, _CloudGateway());
      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text(Ar.visitor), findsOneWidget);
      expect(find.text(Ar.notRegistered), findsOneWidget);
      expect(find.text(Ar.userAreaSignInPrompt), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) => widget is FilledButton),
        findsOneWidget,
        reason: 'FilledButton.icon builds a private subclass, so the plain '
            'byType finder cannot see it',
      );
      expect(
        find.descendant(
          of: find.byWidgetPredicate((widget) => widget is FilledButton),
          matching: find.text(Ar.login),
        ),
        findsOneWidget,
      );
      expect(find.byType(ListTile), findsNWidgets(5),
          reason: 'hub ledger: exactly the five navigation-card entries');
      expect(find.text(Ar.editProfile), findsNothing);
      expect(find.text(Ar.logout), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an authenticated cloud-bound session shows identity, role · '
        'region, Edit + Sign out and keeps 5 tiles', (tester) async {
      final auth = AuthProvider(gateway: FakeAuthGateway(restoredSession: _session));
      final gateway = _CloudGateway(cloud: _cloud(regionId: _karkhId));
      final profileProvider = _cloudWired(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text('W3.4 Tester'), findsOneWidget);
      expect(find.text('w3.4@civilpedia.test'), findsOneWidget);
      expect(
        find.text('${Ar.siteEngineer} · ${Ar.regionBaghdadKarkh}'),
        findsOneWidget,
      );
      expect(find.text(Ar.editProfile), findsOneWidget);
      expect(find.text(Ar.logout), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(find.text(Ar.visitor), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an authenticated session with no cloud row shows the '
        'not-available line (no fabrication)', (tester) async {
      final auth = AuthProvider(gateway: FakeAuthGateway(restoredSession: _session));
      final gateway = _CloudGateway(); // fetch returns null
      final profileProvider = _cloudWired(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text(Ar.profileNotAvailable), findsOneWidget);
      expect(find.text(Ar.editProfile), findsOneWidget);
      expect(find.text(Ar.logout), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an in-flight cloud read shows the loading line, never '
        '"not-available"', (tester) async {
      final auth = AuthProvider(gateway: FakeAuthGateway(restoredSession: _session));
      final gateway = _CloudGateway(
        cloud: _cloud(regionId: _karkhId),
      )..gated = true;
      final profileProvider = _cloudWired(auth, gateway);
      await auth.restoreSession();
      // The auth listener parked ensureCloudProfileLoaded on the gate.

      await _openHub(tester, auth: auth, profileProvider: profileProvider,
          settle: false);
      await tester.pump();

      expect(profileProvider.isCloudProfileLoading, isTrue);
      expect(find.text(Ar.profileCloudLoading), findsOneWidget);
      expect(find.text(Ar.profileNotAvailable), findsNothing);

      gateway.release();
      await tester.pumpAndSettle();

      expect(
        find.text('${Ar.siteEngineer} · ${Ar.regionBaghdadKarkh}'),
        findsOneWidget,
      );
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a cloud read failure shows the typed error line and Retry '
        'recovers', (tester) async {
      final auth = AuthProvider(gateway: FakeAuthGateway(restoredSession: _session));
      final gateway = _CloudGateway(
        cloud: _cloud(regionId: _karkhId),
      )..fetchError = Exception('offline');
      final profileProvider = _cloudWired(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      expect(profileProvider.cloudLoadFailed, isTrue);
      expect(find.text(Ar.profileCloudLoadFailed), findsOneWidget);

      gateway.fetchError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(profileProvider.isCloudBound, isTrue);
      expect(
        find.text('${Ar.siteEngineer} · ${Ar.regionBaghdadKarkh}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sign-out confirms, Cancel keeps the hub signed-in, Confirm '
        'returns to the guest header', (tester) async {
      final auth = AuthProvider(gateway: FakeAuthGateway(restoredSession: _session));
      final profileProvider = _cloudWired(auth, _CloudGateway(cloud: _cloud()));
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(_logoutHeaderButton());
      await tester.pumpAndSettle();
      expect(find.text(Ar.signOutConfirmMessage), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, Ar.cancel));
      await tester.pumpAndSettle();
      expect(auth.isLoggedIn, isTrue);
      expect(find.text('W3.4 Tester'), findsOneWidget);

      await tester.tap(_logoutHeaderButton());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, Ar.logout));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(find.text(Ar.visitor), findsOneWidget);
      expect(find.text(Ar.login), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed sign-out exposes the recoverable snackbar and Retry '
        'succeeds', (tester) async {
      final gateway = FakeAuthGateway(
        restoredSession: _session,
        signOutError: Exception('boom'),
      );
      final auth = AuthProvider(gateway: gateway);
      final profileProvider = _cloudWired(auth, _CloudGateway(cloud: _cloud()));
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(_logoutHeaderButton());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, Ar.logout));
      await tester.pumpAndSettle();

      expect(auth.error, AuthError.signOutFailed);
      expect(auth.isLoggedIn, isTrue);
      expect(find.text(Ar.signOutFailed), findsOneWidget);

      gateway.signOutError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(find.text(Ar.visitor), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an ownership conflict blocks the header (no identity, no '
        'sign-out) while the nav inventory stays intact', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _session),
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );
      final profileProvider = _cloudWired(auth, _CloudGateway(cloud: _cloud()));
      await auth.restoreSession();

      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      expect(auth.isOwnershipBlocked, isTrue);
      expect(find.text(Ar.authAccountConflictTitle), findsOneWidget);
      expect(find.text('W3.4 Tester'), findsNothing);
      expect(find.text(Ar.logout), findsNothing);
      expect(find.text(Ar.editProfile), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    // ---------------------------------------------------------------
    // V1-R08 Part 2 correction coverage (findings 1/3/5/6/9)
    // ---------------------------------------------------------------
    testWidgets('the cloud authority wins over a conflicting on-device file — '
        'no local leak, no A/B flicker', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _session),
      );
      final gateway = _CloudGateway(cloud: _cloud(regionId: _karkhId));
      // A conflicting local file claims a DIFFERENT role + region than the
      // credited cloud row.
      final repo = _FakeRepo(
        LocalUserProfile(
          anonymousInstallId: 'local-xs',
          userType: CivilUserType.structuralEngineer,
          baghdadArea: BaghdadArea.rusafa,
        ),
      );
      final profileProvider = _cloudWired(
        auth,
        gateway,
        repository: repo,
      );
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      expect(profileProvider.isCloudBound, isTrue);
      expect(profileProvider.profile, isNull,
          reason: 'a cloud-bound session never resurrects a local file');
      expect(
        find.text('${Ar.siteEngineer} · ${Ar.regionBaghdadKarkh}'),
        findsOneWidget,
        reason: 'the header renders the authoritative cloud identity only');
      expect(find.text(Ar.structuralEngineer), findsNothing);
      expect(find.text(Ar.regionBaghdadRusafa), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a LIVE session-loss event immediately reverts the hub header '
        'to the guest prompt and keeps the 5-tile ledger', (tester) async {
      final gateway = FakeAuthGateway(restoredSession: _session);
      final auth = AuthProvider(gateway: gateway);
      final profileProvider = _cloudWired(
        auth,
        _CloudGateway(cloud: _cloud(regionId: _karkhId)),
      );
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text('W3.4 Tester'), findsOneWidget);

      gateway.emit(const AuthEvent(type: AuthEventType.sessionLost));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(find.text(Ar.visitor), findsOneWidget);
      expect(find.text(Ar.userAreaSignInPrompt), findsOneWidget);
      expect(find.text('W3.4 Tester'), findsNothing);
      expect(find.text(Ar.editProfile), findsNothing);
      expect(find.text(Ar.logout), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a header sign-out in flight disables the action (single-'
        'flight) with progress and preserves the identity', (tester) async {
      final gate = Completer<void>();
      final gateway = _GatedSignOutGateway(
        gate: gate,
        restoredSession: _session,
      );
      final auth = AuthProvider(gateway: gateway);
      final profileProvider = _cloudWired(
        auth,
        _CloudGateway(cloud: _cloud(regionId: _karkhId)),
      );
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      await tester.tap(_logoutHeaderButton());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, Ar.logout));
      await tester.pump();

      expect(auth.isSigningOut, isTrue);
      expect(gateway.signOutCalls, 1);
      expect(find.text(Ar.signOutPendingLabel), findsOneWidget,
          reason: 'the header renders the disabled pending affordance');
      expect(find.text('W3.4 Tester'), findsOneWidget,
          reason: 'identity is preserved while the sign-out is pending');
      expect(find.text(Ar.visitor), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(5));
      final pendingButton = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(Ar.signOutPendingLabel),
          matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
        ),
      );
      expect(pendingButton.onPressed, isNull);

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
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an ownership-conflict header offers Retry resolution; a '
        'resolved conflict collapses to the guest header (no dead-end)',
        (tester) async {
      final gateway = _RecoveredRestoreGateway(session: _session);
      final auth = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );
      final profileProvider = _cloudWired(
        auth,
        _CloudGateway(cloud: _cloud(roleCode: 'site_engineer')),
      );
      await auth.restoreSession();
      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      expect(auth.isOwnershipBlocked, isTrue);
      expect(find.text(Ar.authAccountConflictTitle), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.text('W3.4 Tester'), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(5));

      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(auth.isOwnershipBlocked, isFalse);
      expect(auth.error, isNull);
      expect(find.text(Ar.visitor), findsOneWidget,
          reason: 'a resolved conflict collapses to the credited guest header');
      expect(find.text(Ar.retry), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('English locale renders the whole hub in English with no '
        'forced Arabic or raw codes', (tester) async {
      final guestAuth = _guestAuth();
      await _openHub(
        tester,
        auth: guestAuth,
        profileProvider: _cloudWired(guestAuth, _CloudGateway()),
        isArabic: false,
      );

      expect(find.text(En.userArea), findsOneWidget,
          reason: 'the AppBar title follows the active locale');
      expect(find.text(En.visitor), findsOneWidget);
      expect(find.text(En.userAreaSignInPrompt), findsOneWidget);
      expect(
        find.descendant(
          of: find.byWidgetPredicate((widget) => widget is FilledButton),
          matching: find.text(En.login),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(ListTile, En.businessManageMyBusinesses),
          findsOneWidget);
      expect(find.widgetWithText(ListTile, En.businessMyApplications),
          findsOneWidget);
      expect(find.widgetWithText(ListTile, En.profile), findsOneWidget);
      expect(find.widgetWithText(ListTile, En.saved), findsOneWidget);
      expect(find.widgetWithText(ListTile, En.downloads), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(find.text(Ar.visitor), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('English locale renders the authenticated hub header in '
        'English', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _session),
      );
      final profileProvider = _cloudWired(
        auth,
        _CloudGateway(cloud: _cloud(roleCode: 'site_engineer', regionId: _karkhId)),
      );
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      await _openHub(
        tester,
        auth: auth,
        profileProvider: profileProvider,
        isArabic: false,
      );

      expect(
        find.text('${En.siteEngineer} · ${En.regionBaghdadKarkh}'),
        findsOneWidget,
      );
      expect(find.text(En.editProfile), findsOneWidget);
      expect(find.text(En.logout), findsOneWidget);
      expect(find.text(Ar.siteEngineer), findsNothing);
      expect(find.text('site_engineer'), findsNothing);
      expect(find.byType(ListTile), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });
}