import 'dart:async';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/network/remote_operation_policy.dart';
import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:civilpedia/core/widgets/remote_data_notice.dart';
import 'package:civilpedia/core/widgets/transport_status_banner.dart';
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
import 'package:civilpedia/features/profile/presentation/profile_screen.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/features/profile/presentation/screens/authenticated_profile_edit_screen.dart';
import 'package:civilpedia/features/profile/presentation/widgets/authenticated_profile_read_notice.dart';
import 'package:civilpedia/features/user_area/presentation/user_area_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_auth_gateway.dart';

const _karkhId = '10000000-0000-4000-8000-000000000101';

Object _networkFailure() => const InfrastructureFailureException(
  InfrastructureFailure(InfrastructureFailureKind.network),
);

// ── Fakes (mirror the V1-R08 harnesses) ──────────────────────────────────────

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
  Completer<void>? _gate = Completer<void>();
  int fetchCalls = 0;
  int saveCalls = 0;
  int createCalls = 0;

  void release() {
    if (gated && _gate != null) {
      gated = false;
      _gate!.complete();
      _gate = null;
    }
  }

  /// Re-arms the gate so a SECOND read can be parked (refresh tests).
  void reGate() {
    gated = true;
    _gate = Completer<void>();
  }

  @override
  Future<CloudProfile?> fetchByUserId(String userId) async {
    fetchCalls++;
    if (gated) await _gate!.future;
    if (fetchError != null) throw fetchError!;
    if (fetchNull) return null;
    return cloud;
  }

  @override
  Future<void> createProfile(CloudProfile profile) async {
    createCalls++;
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

class _FakeTransportSource implements TransportSource {
  _FakeTransportSource(Future<bool> Function() check) : _check = check {
    changes = StreamController<bool>.broadcast(sync: true);
  }

  final Future<bool> Function() _check;
  late final StreamController<bool> changes;

  @override
  Future<bool> checkAvailability() => _check();

  @override
  Stream<bool> get availabilityChanges => changes.stream;

  Future<void> close() => changes.close();
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

// ── Construction helpers ─────────────────────────────────────────────────────

UserProfileProvider _provider(AuthProvider auth, _CloudGateway gateway) {
  return UserProfileProvider(
    repository: _FakeRepo(),
    cloudProfileGateway: gateway,
    regionPreferenceGateway: _PrefGateway(),
    auth: auth,
  );
}

CloudProfile _cloud({String roleCode = 'site_engineer', String? regionId}) {
  return CloudProfile(
    userId: fakeSession.userId,
    roleCode: roleCode,
    regionPreferenceId: regionId,
  );
}

Widget _localizedApp({required Widget home, required Locale locale}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required AuthProvider auth,
  required UserProfileProvider profileProvider,
  ConnectivityProvider? connectivity,
  Locale locale = const Locale('ar'),
  bool settle = true,
}) async {
  final connectivityProvider =
      connectivity ??
      ConnectivityProvider(source: _FakeTransportSource(() async => true));
  addTearDown(connectivityProvider.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              LanguageProvider(isArabic: locale.languageCode == 'ar'),
        ),
        ChangeNotifierProvider<ConnectivityProvider>.value(
          value: connectivityProvider,
        ),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: profileProvider),
      ],
      child: _localizedApp(
        locale: locale,
        home: const Scaffold(body: ProfileScreen()),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required AuthProvider auth,
  required UserProfileProvider profileProvider,
  ConnectivityProvider? connectivity,
  Locale locale = const Locale('ar'),
  bool settle = true,
}) async {
  final connectivityProvider =
      connectivity ??
      ConnectivityProvider(source: _FakeTransportSource(() async => true));
  addTearDown(connectivityProvider.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              LanguageProvider(isArabic: locale.languageCode == 'ar'),
        ),
        ChangeNotifierProvider<ConnectivityProvider>.value(
          value: connectivityProvider,
        ),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: profileProvider),
      ],
      child: _localizedApp(
        locale: locale,
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

Future<void> _openHub(
  WidgetTester tester, {
  required AuthProvider auth,
  required UserProfileProvider profileProvider,
  ConnectivityProvider? connectivity,
  Locale locale = const Locale('ar'),
  bool settle = true,
}) async {
  final connectivityProvider =
      connectivity ??
      ConnectivityProvider(source: _FakeTransportSource(() async => true));
  addTearDown(connectivityProvider.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              LanguageProvider(isArabic: locale.languageCode == 'ar'),
        ),
        ChangeNotifierProvider<ConnectivityProvider>.value(
          value: connectivityProvider,
        ),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(
          create: (context) => StaffAccessProvider(
            gateway: _FakeStaffAccessGateway(),
            auth: context.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider.value(value: profileProvider),
      ],
      child: _localizedApp(
        locale: locale,
        home: const UserAreaScreen(),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// Failure/exact-cause catalog covering the full frozen taxonomy (except the
/// presentation-only promotion from network→offline, covered separately).
final List<(ProfileReadFailureKind, Object Function(), String, String)>
_causeCases = [
  (
    ProfileReadFailureKind.network,
    _networkFailure,
    Ar.noticeNetwork,
    En.noticeNetwork,
  ),
  (
    ProfileReadFailureKind.timeout,
    () => const InfrastructureFailureException(
      InfrastructureFailure(InfrastructureFailureKind.timeout),
    ),
    Ar.noticeTimeout,
    En.noticeTimeout,
  ),
  (
    ProfileReadFailureKind.serviceUnavailable,
    () => const InfrastructureFailureException(
      InfrastructureFailure(InfrastructureFailureKind.serviceUnavailable),
    ),
    Ar.noticeServiceUnavailable,
    En.noticeServiceUnavailable,
  ),
  (
    ProfileReadFailureKind.malformedResponse,
    () => const CloudProfileParseException('raw'),
    Ar.noticeMalformed,
    En.noticeMalformed,
  ),
  (
    ProfileReadFailureKind.permissionDenied,
    CloudProfilePermissionDeniedException.new,
    Ar.noticePermissionDenied,
    En.noticePermissionDenied,
  ),
  (
    ProfileReadFailureKind.authRestricted,
    CloudProfileAuthException.new,
    Ar.noticeAuthRestricted,
    En.noticeAuthRestricted,
  ),
  (
    ProfileReadFailureKind.unexpected,
    CloudProfileUnexpectedException.new,
    Ar.noticeUnexpected,
    En.noticeUnexpected,
  ),
];

void main() {
  // ════════════════════════════════════════════════════════════════════
  // AuthenticatedProfileReadNotice adapter
  // ════════════════════════════════════════════════════════════════════
  group('AuthenticatedProfileReadNotice adapter', () {
    test('maps every read failure kind through the frozen taxonomy', () {
      expect(
        profileReadFailureToRemoteDataCause(
          ProfileReadFailureKind.network,
          connectivityIsUnavailable: false,
        ),
        RemoteDataCause.network,
      );
      expect(
        profileReadFailureToRemoteDataCause(
          ProfileReadFailureKind.network,
          connectivityIsUnavailable: true,
        ),
        RemoteDataCause.offline,
      );
      expect(
        profileReadFailureToRemoteDataCause(
          ProfileReadFailureKind.timeout,
          connectivityIsUnavailable: true,
        ),
        RemoteDataCause.timeout,
      );
      expect(
        profileReadFailureToRemoteDataCause(
          ProfileReadFailureKind.serviceUnavailable,
          connectivityIsUnavailable: false,
        ),
        RemoteDataCause.serviceUnavailable,
      );
      expect(
        profileReadFailureToRemoteDataCause(
          ProfileReadFailureKind.malformedResponse,
          connectivityIsUnavailable: true,
        ),
        RemoteDataCause.malformed,
      );
      expect(
        profileReadFailureToRemoteDataCause(
          ProfileReadFailureKind.permissionDenied,
          connectivityIsUnavailable: true,
        ),
        RemoteDataCause.permissionDenied,
      );
      expect(
        profileReadFailureToRemoteDataCause(
          ProfileReadFailureKind.authRestricted,
          connectivityIsUnavailable: true,
        ),
        RemoteDataCause.authRestricted,
      );
      expect(
        profileReadFailureToRemoteDataCause(
          ProfileReadFailureKind.unexpected,
          connectivityIsUnavailable: true,
        ),
        RemoteDataCause.unexpected,
      );
    });

    testWidgets('renders the shared RemoteDataNotice with the resolved cause',
        (tester) async {
      await tester.pumpWidget(
        _localizedApp(
          locale: const Locale('ar'),
          home: const Scaffold(
            body: AuthenticatedProfileReadNotice(
              failure: ProfileReadFailureKind.serviceUnavailable,
              mode: RemoteDataNoticeMode.compact,
            ),
          ),
        ),
      );

      expect(find.byType(RemoteDataNotice), findsOneWidget);
      expect(find.text(Ar.noticeServiceUnavailable), findsOneWidget);
      expect(
        find.text(Ar.noticeRetryAccessibility),
        findsNothing,
        reason: 'no retry control unless a read retry is provided',
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // ProfileScreen — P2-C2
  // ════════════════════════════════════════════════════════════════════
  group('ProfileScreen P2-C2', () {
    for (final case_ in _causeCases) {
      testWidgets(
          'no-cloud ${case_.$1.name} shows the exact typed cause, the '
          'canonical label and ONE notice (Arabic, RTL, no raw error)',
          (tester) async {
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: fakeSession),
        );
        final gateway = _CloudGateway()..fetchError = case_.$2();
        final profileProvider = _provider(auth, gateway);
        await auth.restoreSession();
        await profileProvider.ensureCloudProfileLoaded();

        await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

        expect(profileProvider.cloudReadFailure, case_.$1);
        expect(find.text(Ar.profileCloudLoadFailed), findsOneWidget);
        expect(find.text(case_.$3), findsOneWidget);
        expect(find.byType(RemoteDataNotice), findsOneWidget);
        expect(
          find.byType(TransportStatusBanner),
          findsNothing,
          reason: 'feature screens never add a second transport banner',
        );
        expect(find.text(Ar.retry), findsOneWidget);
        expect(
          find.text(Ar.profileNotSet),
          findsNothing,
          reason: 'a failing cloud read never resurrects a local surrogate',
        );
        expect(find.textContaining('Exception'), findsNothing);
        expect(
          Directionality.of(tester.element(find.byType(RemoteDataNotice))),
          TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'no-cloud failure renders the English typed cause and LTR direction',
        (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway()..fetchError = _networkFailure();
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpProfile(
        tester,
        auth: auth,
        profileProvider: profileProvider,
        locale: const Locale('en'),
      );

      expect(find.text(En.profileCloudLoadFailed), findsOneWidget);
      expect(find.text(En.noticeNetwork), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(RemoteDataNotice))),
        TextDirection.ltr,
      );
    });

    testWidgets(
        'a known-good card stays visible during a refresh, with a '
        'lightweight indicator and no notice', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(
        cloud: _cloud(roleCode: 'site_engineer', regionId: _karkhId),
      );
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpProfile(
        tester,
        auth: auth,
        profileProvider: profileProvider,
        settle: false,
      );
      await tester.pump();

      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsNothing);

      gateway.reGate();
      final refresh = profileProvider.ensureCloudProfileLoaded();
      await tester.pump();

      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.refreshing);
      expect(
        find.text(Ar.siteEngineer),
        findsOneWidget,
        reason: 'the authoritative summary never leaves the card',
      );
      expect(find.text(Ar.profileCloudLoading), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsNothing);

      gateway.release();
      await refresh;
      await tester.pumpAndSettle();

      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.loaded);
      expect(find.text(Ar.profileCloudLoading), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'an existing-profile read failure keeps the card + ONE compact typed '
        'notice and recovers via Retry', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(
        cloud: _cloud(roleCode: 'site_engineer', regionId: _karkhId),
      );
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      gateway.fetchError = _networkFailure();
      await profileProvider.ensureCloudProfileLoaded();
      await tester.pumpAndSettle();

      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.failed);
      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.text(Ar.profileCloudLoadFailed), findsNothing);

      gateway.fetchError = null;
      await tester.ensureVisible(find.text(Ar.retry));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.loaded);
      expect(find.byType(RemoteDataNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a settled no-row state keeps the failing-closed "not set" label '
        'and a manual read retry recovers', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud())..fetchNull = true;
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpProfile(tester, auth: auth, profileProvider: profileProvider);

      expect(
        profileProvider.cloudReadPhase,
        AuthenticatedProfileReadPhase.authoritativeNotFound,
      );
      expect(find.text(Ar.profileNotSet), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.text(Ar.profileNotAvailable), findsNothing);
      expect(find.byType(RemoteDataNotice), findsNothing);

      gateway.fetchNull = false;
      gateway.fetchError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.loaded);
      expect(find.text(Ar.siteEngineer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a transport failure shows offline ONLY after the canonical '
        'ConnectivityProvider confirms unavailability (no banner)', (tester) async {
      final source = _FakeTransportSource(() async => true);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway()..fetchError = _networkFailure();
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpProfile(
        tester,
        auth: auth,
        profileProvider: profileProvider,
        connectivity: connectivity,
      );

      expect(
        find.text(Ar.noticeNetwork),
        findsOneWidget,
        reason: 'while transport is available the cause stays network',
      );

      source.changes.add(false);
      await tester.pumpAndSettle();

      expect(connectivity.isUnavailable, isTrue);
      expect(find.text(Ar.noticeOffline), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsNothing);
      expect(find.byType(RemoteDataNotice), findsOneWidget);
      expect(find.byType(TransportStatusBanner), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a connectivity reconnect does NOT auto re-read; the failure remains '
        'and resolves only through manual retry', (tester) async {
      final source = _FakeTransportSource(() async => true);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway()..fetchError = _networkFailure();
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpProfile(
        tester,
        auth: auth,
        profileProvider: profileProvider,
        connectivity: connectivity,
      );

      expect(gateway.fetchCalls, 1);

      source.changes.add(false);
      await tester.pumpAndSettle();
      expect(connectivity.isUnavailable, isTrue);
      expect(find.text(Ar.noticeOffline), findsOneWidget);

      source.changes.add(true);
      await tester.pumpAndSettle();

      expect(connectivity.isUnavailable, isFalse);
      expect(connectivity.reconnectGeneration, 1);
      expect(
        gateway.fetchCalls,
        1,
        reason: 'reconnecting transport must never start an automatic read',
      );
      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.failed);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'W3.4 compat: an authenticated session on a non-cloud-wired provider '
        'keeps the local profile card', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final profileProvider = UserProfileProvider(
        repository: _FakeRepo(
          LocalUserProfile(
            anonymousInstallId: 'p2-c2-compat',
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
      expect(find.byType(RemoteDataNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // AuthenticatedProfileEditScreen — P2-C2
  // ════════════════════════════════════════════════════════════════════
  group('AuthenticatedProfileEditScreen P2-C2', () {
    testWidgets(
        'no-cloud failure shows the typed no-data cause; manual retry '
        're-reads and restores the form', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway()..fetchError = _networkFailure();
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      expect(find.text(Ar.profileCloudLoadFailed), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(
        find.text(Ar.profileRole),
        findsNothing,
        reason: 'a form is never rendered for a row that failed to load',
      );
      expect(find.textContaining('Exception'), findsNothing);

      gateway.fetchError = null;
      gateway.cloud = _cloud();
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(profileProvider.isCloudBound, isTrue);
      expect(find.text(Ar.profileRole), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'an in-flight refresh keeps the loaded form on screen (never a '
        'static failure screen over valid content)', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud());
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      gateway.reGate();
      final refresh = profileProvider.ensureCloudProfileLoaded();
      await tester.pump();

      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.refreshing);
      expect(find.text(Ar.profileRole), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsNothing);

      gateway.release();
      await refresh;
      await tester.pumpAndSettle();
      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.loaded);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'an existing-profile failure preserves the form + ONE compact typed '
        'notice; Retry is a read (never a mutation) and Save stays intact',
        (tester) async {
      _useTallViewport(tester);
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud());
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      gateway.fetchError = _networkFailure();
      await profileProvider.ensureCloudProfileLoaded();
      await tester.pumpAndSettle();

      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.failed);
      expect(find.text(Ar.profileRole), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(gateway.saveCalls, 0);

      gateway.fetchError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.loaded);
      expect(find.byType(RemoteDataNotice), findsNothing);
      expect(
        gateway.saveCalls,
        0,
        reason: 'read retry never reaches the mutation gateway',
      );

      await tester.tap(find.widgetWithText(ListTile, Ar.profileRole));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.consultantEngineer));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, Ar.profileSaveChanges));
      await tester.pumpAndSettle();

      expect(gateway.saveCalls, 1);
      expect(find.text(Ar.profileUpdated), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('editor renders the compact notice in RTL for Arabic locale',
        (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud());
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();
      gateway.fetchError = _networkFailure();
      await profileProvider.ensureCloudProfileLoaded();

      await _pumpEditor(tester, auth: auth, profileProvider: profileProvider);

      expect(
        Directionality.of(tester.element(find.byType(RemoteDataNotice))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // User Area header — P2-C2
  // ════════════════════════════════════════════════════════════════════
  group('UserArea header P2-C2', () {
    testWidgets(
        'no-cloud failure shows the typed compact cause + Retry; recovery '
        'restores the cloud summary (never a guest fallback)', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(cloud: _cloud(regionId: _karkhId))
        ..fetchError = _networkFailure();
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.failed);
      expect(find.text(Ar.profileCloudLoadFailed), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(
        find.text(Ar.visitor),
        findsNothing,
        reason: 'an authenticated failure never degrades to a guest prompt',
      );
      expect(find.byType(TransportStatusBanner), findsNothing);

      gateway.fetchError = null;
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(profileProvider.isCloudBound, isTrue);
      expect(
        find.text('${Ar.siteEngineer} · ${Ar.regionBaghdadKarkh}'),
        findsOneWidget,
      );
      expect(find.byType(RemoteDataNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a known-good summary stays visible through a refresh and an '
        'existing-profile failure adds exactly ONE compact typed notice',
        (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway(
        cloud: _cloud(roleCode: 'site_engineer', regionId: _karkhId),
      );
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _openHub(tester, auth: auth, profileProvider: profileProvider);

      const summary = '${Ar.siteEngineer} · ${Ar.regionBaghdadKarkh}';
      expect(find.text(summary), findsOneWidget);

      gateway.reGate();
      final refresh = profileProvider.ensureCloudProfileLoaded();
      await tester.pump();
      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.refreshing);
      expect(find.text(summary), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsNothing);
      gateway.release();
      await refresh;
      await tester.pumpAndSettle();

      gateway.fetchError = _networkFailure();
      await profileProvider.ensureCloudProfileLoaded();
      await tester.pumpAndSettle();

      expect(profileProvider.cloudReadPhase, AuthenticatedProfileReadPhase.failed);
      expect(find.text(summary), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a confirmed-offline transport turns the header failure into the '
        'offline typed cause (single notice, no second banner)', (tester) async {
      final source = _FakeTransportSource(() async => true);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
      );
      final gateway = _CloudGateway()..fetchError = _networkFailure();
      final profileProvider = _provider(auth, gateway);
      await auth.restoreSession();
      await profileProvider.ensureCloudProfileLoaded();

      await _openHub(
        tester,
        auth: auth,
        profileProvider: profileProvider,
        connectivity: connectivity,
      );

      expect(find.text(Ar.noticeNetwork), findsOneWidget);

      source.changes.add(false);
      await tester.pumpAndSettle();

      expect(connectivity.isUnavailable, isTrue);
      expect(find.text(Ar.noticeOffline), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsNothing);
      expect(find.byType(RemoteDataNotice), findsOneWidget);
      expect(find.byType(TransportStatusBanner), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}