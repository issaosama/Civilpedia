import 'dart:async';

import 'package:nested/nested.dart';

import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:civilpedia/core/widgets/remote_data_notice.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_policy.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:civilpedia/features/business/domain/business_claim_target.dart';
import 'package:civilpedia/features/business/domain/business_claim_target_gateway.dart';
import 'package:civilpedia/features/business/domain/business_contact_type.dart';
import 'package:civilpedia/features/business/domain/business_membership_gateway.dart';
import 'package:civilpedia/features/business/domain/business_profile_management_gateway.dart';
import 'package:civilpedia/features/business/domain/business_remote_read.dart';
import 'package:civilpedia/features/business/domain/business_role.dart';
import 'package:civilpedia/features/business/domain/managed_business_profile.dart';
import 'package:civilpedia/features/business/domain/managed_business_summary.dart';
import 'package:civilpedia/features/business/domain/managed_selectable_options.dart';
import 'package:civilpedia/features/business/presentation/providers/business_application_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/business_claim_target_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/business_profile_editor_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/managed_businesses_provider.dart';
import 'package:civilpedia/features/business/presentation/screens/application_claim_form_screen.dart';
import 'package:civilpedia/features/business/presentation/screens/application_detail_screen.dart';
import 'package:civilpedia/features/business/presentation/screens/business_profile_edit_screen.dart';
import 'package:civilpedia/features/business/presentation/screens/managed_businesses_screen.dart';
import 'package:civilpedia/features/business/presentation/screens/my_applications_screen.dart';
import 'package:civilpedia/features/business/presentation/widgets/business_application_status_chip.dart';
import 'package:civilpedia/features/business/presentation/widgets/business_remote_read_notice.dart';
import 'package:civilpedia/features/business/presentation/widgets/business_sign_in_required_view.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_auth_gateway.dart';
import 'fakes/fake_business_membership_gateway.dart';
import 'fakes/fake_business_profile_management_gateway.dart';
import 'helpers/canonical_directory_test_helpers.dart';

// ---------------------------------------------------------------------------
// V1-R09 P2-D2 — Business remote-read UX window (62 obligations)
//
// A.1-A.14  managed-business list lanes
// B.15-B.20 managed profile editor lanes
// C.21-C.25 auxiliary (taxonomy) lanes
// D.26-D.31 my-applications list lanes
// E.32-E.37 application detail lanes
// F.38-F.43 claim selector lanes
// G.44-G.47 connectivity-derived offline promotion
// H.48-H.49 notice ownership / one-notice-per-lane
// I.50      raw backend text never reaches the UI
// J.51-J.59 AR/EN localization (J.56-J.59 correction coverage: empty-state
//           and claim verification labels in both locales + RTL/LTR)
// K.56-K.58 mutation compatibility (read retry never mutates)
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _entityId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const _regionId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
const _categoryId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
const _userId = 'user-0000-0000-0000-000000000001';

const _testSession = AuthSession(
  userId: _userId,
  email: 'test@civilpedia.com',
  displayName: 'tester',
);

const _ar = Locale('ar');
const _en = Locale('en');

Future<AuthProvider> _authenticatedAuth() async {
  final auth = AuthProvider(
    gateway: FakeAuthGateway(restoredSession: _testSession),
    onPostAuth: (_) async => PostAuthOutcome.success,
  );
  await auth.restoreSession();
  return auth;
}

Future<AuthProvider> _guestAuth() async {
  final auth = AuthProvider(
    gateway: FakeAuthGateway(restoredSession: null),
    onPostAuth: (_) async => PostAuthOutcome.success,
  );
  await auth.restoreSession();
  return auth;
}

ManagedBusinessSummary _summary({
  String id = _entityId,
  String name = 'Test Co',
  BusinessRole role = BusinessRole.owner,
}) {
  return ManagedBusinessSummary(
    entityId: id,
    name: name,
    entityType: 'company',
    membershipRole: role,
    claimStatus: 'claimed',
    verificationStatus: 'verified',
  );
}

ManagedBusinessProfile _sampleProfile({DateTime? updatedAt}) {
  return ManagedBusinessProfile(
    id: _entityId,
    entityType: 'company',
    name: 'Test Co',
    lifecycleStatus: 'active',
    verificationStatus: VerificationStatus.verified,
    claimStatus: 'claimed',
    createdAt: DateTime.utc(2024, 1, 1),
    updatedAt: updatedAt ?? DateTime.utc(2024, 1, 2),
    description: 'A sample business',
    contacts: const [
      ManagedBusinessContact(
        id: 'c1',
        type: BusinessContactType.phone,
        value: '+9647700000000',
        isPrimary: true,
      ),
    ],
    primaryLocation: ManagedBusinessLocation(
      id: 'l1',
      regionId: _regionId,
      regionCode: 'baghdad',
      regionNameAr: 'بغداد',
      regionNameEn: 'Baghdad',
      address: 'Al-Jadriya',
      latitude: 33.3152,
      longitude: 44.3661,
    ),
    categories: const [
      ManagedBusinessCategory(
        categoryId: _categoryId,
        code: 'structural',
        nameAr: 'إنشائي',
        isPrimary: true,
      ),
    ],
  );
}

BusinessApplication _app({
  String id = 'app-1',
  String? applicantUserId,
  BusinessApplicationType type = BusinessApplicationType.newApplication,
  BusinessApplicationStatus status = BusinessApplicationStatus.draft,
  String? targetEntityId,
  Map<String, dynamic>? metadata,
  DateTime? approvedAt,
  DateTime? activatedAt,
}) => BusinessApplication(
  id: id,
  applicantUserId: applicantUserId ?? _userId,
  type: type,
  status: status,
  targetEntityId: targetEntityId,
  metadata: metadata,
  approvedAt: approvedAt,
  activatedAt: activatedAt,
);

BusinessClaimTarget _target({
  String id = 't1',
  String name = 'Alpha',
  String entityType = 'company',
  String? verificationStatus,
}) => BusinessClaimTarget(
  id: id,
  name: name,
  entityType: entityType,
  claimStatus: 'unclaimed',
  verificationStatus: verificationStatus,
);

// ---------------------------------------------------------------------------
// Fakes (typed-read aware)
// ---------------------------------------------------------------------------

class _FakeAppGateway implements BusinessApplicationGateway {
  _FakeAppGateway({
    this.listOwnResult = const [],
    this.getOwnResult,
    this.onCreateClaimDraft,
  });

  @override
  final bool isAvailable = true;

  final List<String> listOwnCalls = [];
  final List<String> getOwnCalls = [];
  final List<String> createClaimDraftCalls = [];
  int submitCalls = 0;
  int resubmitCalls = 0;

  /// When set, the corresponding read throws a typed [BusinessRemoteReadException]
  /// on every invocation until the test clears it.
  BusinessRemoteReadFailureKind? listFailureKind;
  BusinessRemoteReadFailureKind? getFailureKind;

  List<BusinessApplication> listOwnResult;
  BusinessApplication? getOwnResult;

  Future<List<BusinessApplication>> Function()? onListOwnApplications;
  Future<BusinessApplication?> Function()? onGetOwnApplication;
  Future<BusinessApplicationSubmitResult> Function(BusinessApplication)?
  onSubmitApplication;
  Future<BusinessApplicationSubmitResult> Function(BusinessApplication)?
  onResubmitApplication;
  Future<BusinessApplicationCreateResult> Function(String targetId)?
  onCreateClaimDraft;

  @override
  Future<List<BusinessApplication>> listOwnApplications(String userId) async {
    listOwnCalls.add(userId);
    final hook = onListOwnApplications;
    if (hook != null) return hook();
    final kind = listFailureKind;
    if (kind != null) throw BusinessRemoteReadException(kind);
    return listOwnResult;
  }

  @override
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  ) async {
    getOwnCalls.add(applicationId);
    final hook = onGetOwnApplication;
    if (hook != null) return hook();
    final kind = getFailureKind;
    if (kind != null) throw BusinessRemoteReadException(kind);
    return getOwnResult;
  }

  @override
  Future<BusinessApplicationCreateResult> createNewDraft({
    required String currentUserId,
    Map<String, dynamic>? metadata,
  }) async {
    return BusinessApplicationCreated(
      _app(
        id: 'app-new-1',
        applicantUserId: currentUserId,
        metadata: metadata,
      ),
    );
  }

  @override
  Future<BusinessApplicationCreateResult> createClaimDraft({
    required String currentUserId,
    required String targetEntityId,
  }) async {
    createClaimDraftCalls.add(targetEntityId);
    final hook = onCreateClaimDraft;
    if (hook != null) return hook(targetEntityId);
    return BusinessApplicationCreated(
      BusinessApplication(
        id: 'app-claim-1',
        applicantUserId: currentUserId,
        type: BusinessApplicationType.claim,
        status: BusinessApplicationStatus.draft,
        targetEntityId: targetEntityId,
      ),
    );
  }

  @override
  Future<BusinessApplicationSubmitResult> submitApplication(
    BusinessApplication application,
  ) async {
    submitCalls++;
    final hook = onSubmitApplication;
    if (hook != null) return hook(application);
    return BusinessApplicationSubmitted(
      _app(
        id: application.id,
        applicantUserId: application.applicantUserId,
        type: application.type,
        status: BusinessApplicationStatus.submitted,
        targetEntityId: application.targetEntityId,
        metadata: application.metadata,
      ),
    );
  }

  @override
  Future<BusinessApplicationSubmitResult> resubmitApplication(
    BusinessApplication application,
  ) async {
    resubmitCalls++;
    final hook = onResubmitApplication;
    if (hook != null) return hook(application);
    return BusinessApplicationSubmitted(
      _app(
        id: application.id,
        applicantUserId: application.applicantUserId,
        type: application.type,
        status: BusinessApplicationStatus.submitted,
        targetEntityId: application.targetEntityId,
        metadata: application.metadata,
      ),
    );
  }
}

class _FakeClaimTargetGateway implements BusinessClaimTargetGateway {
  _FakeClaimTargetGateway({
    this.targetsResult = const [],
    this.failureKind,
  });

  @override
  final bool isAvailable = true;

  int listCalls = 0;
  List<BusinessClaimTarget> targetsResult;
  BusinessRemoteReadFailureKind? failureKind;
  Future<List<BusinessClaimTarget>> Function()? onListTargets;

  @override
  Future<List<BusinessClaimTarget>> listUnclaimedTargets() async {
    listCalls++;
    final hook = onListTargets;
    if (hook != null) return hook();
    final kind = failureKind;
    if (kind != null) throw BusinessRemoteReadException(kind);
    return targetsResult;
  }
}

/// Profile gateway that can also script a typed auxiliary (taxonomy) failure.
class _ScriptableProfileGateway extends FakeBusinessProfileManagementGateway {
  _ScriptableProfileGateway({
    super.readResult,
    super.updateResult,
    List<ManagedSelectableCategory> categories = const [],
    List<ManagedSelectableRegion> regions = const [],
    BusinessRemoteReadFailureKind? auxiliaryFailureKind,
  })  : _categories = categories,
        _regions = regions,
        auxiliaryFailureKind = auxiliaryFailureKind;

  List<ManagedSelectableCategory> _categories;
  List<ManagedSelectableRegion> _regions;

  /// Thrown from the next auxiliary read, then cleared. Set
  /// [recurringAuxiliaryFailure] to keep throwing.
  BusinessRemoteReadFailureKind? auxiliaryFailureKind;
  bool recurringAuxiliaryFailure = false;

  int categoryCalls = 0;
  int regionCalls = 0;

  @override
  Future<List<ManagedSelectableCategory>> loadActiveCategories() async {
    categoryCalls++;
    final kind = auxiliaryFailureKind;
    if (kind != null) {
      if (!recurringAuxiliaryFailure) auxiliaryFailureKind = null;
      throw BusinessRemoteReadException(kind);
    }
    return _categories;
  }

  @override
  Future<List<ManagedSelectableRegion>> loadActiveRegions() async {
    regionCalls++;
    final kind = auxiliaryFailureKind;
    if (kind != null) {
      if (!recurringAuxiliaryFailure) auxiliaryFailureKind = null;
      throw BusinessRemoteReadException(kind);
    }
    return _regions;
  }
}

class _FakeTransportSource implements TransportSource {
  _FakeTransportSource([this.available = true]) {
    changes = StreamController<bool>.broadcast(sync: true);
  }

  bool available;
  late final StreamController<bool> changes;

  @override
  Future<bool> checkAvailability() async => available;

  @override
  Stream<bool> get availabilityChanges => changes.stream;

  Future<void> close() => changes.close();
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

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

Locale _localeFor(bool isArabic) => isArabic ? _ar : _en;

({ConnectivityProvider provider, _FakeTransportSource source})
    _connectivitySource({required bool available}) {
  final source = _FakeTransportSource(available);
  final provider = ConnectivityProvider(source: source);
  addTearDown(provider.dispose);
  addTearDown(source.close);
  return (provider: provider, source: source);
}

List<SingleChildWidget> _baseProviders({
  required bool isArabic,
  ConnectivityProvider? connectivity,
}) {
  return [
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(isArabic: isArabic),
    ),
    if (connectivity != null)
      ChangeNotifierProvider<ConnectivityProvider>.value(value: connectivity),
  ];
}

Future<void> _setTallViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _pumpManaged(
  WidgetTester tester, {
  required ManagedBusinessesProvider provider,
  bool isArabic = true,
  ConnectivityProvider? connectivity,
}) async {
  await _setTallViewport(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ..._baseProviders(isArabic: isArabic, connectivity: connectivity),
        ChangeNotifierProvider.value(value: provider),
      ],
      child: _localizedApp(
        locale: _localeFor(isArabic),
        home: const ManagedBusinessesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpEditor(
  WidgetTester tester, {
  required BusinessProfileEditorProvider provider,
  bool isArabic = true,
  ConnectivityProvider? connectivity,
}) async {
  await _setTallViewport(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ..._baseProviders(isArabic: isArabic, connectivity: connectivity),
        ChangeNotifierProvider.value(value: provider),
      ],
      child: _localizedApp(
        locale: _localeFor(isArabic),
        home: BusinessProfileEditScreen(entityId: _entityId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpAppList(
  WidgetTester tester, {
  required BusinessApplicationProvider provider,
  bool isArabic = true,
  ConnectivityProvider? connectivity,
}) async {
  await _setTallViewport(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ..._baseProviders(isArabic: isArabic, connectivity: connectivity),
        ChangeNotifierProvider.value(value: provider),
      ],
      child: _localizedApp(
        locale: _localeFor(isArabic),
        home: const MyApplicationsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpAppDetail(
  WidgetTester tester, {
  required BusinessApplicationProvider provider,
  bool isArabic = true,
  ConnectivityProvider? connectivity,
}) async {
  await _setTallViewport(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ..._baseProviders(isArabic: isArabic, connectivity: connectivity),
        ChangeNotifierProvider.value(value: provider),
      ],
      child: _localizedApp(
        locale: _localeFor(isArabic),
        home: ApplicationDetailScreen(applicationId: 'a1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpClaim(
  WidgetTester tester, {
  required BusinessApplicationProvider appProvider,
  required BusinessClaimTargetProvider claimProvider,
  bool isArabic = true,
  ConnectivityProvider? connectivity,
}) async {
  await _setTallViewport(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ..._baseProviders(isArabic: isArabic, connectivity: connectivity),
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: claimProvider),
      ],
      child: _localizedApp(
        locale: _localeFor(isArabic),
        home: const ApplicationClaimFormScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<BusinessApplicationProvider> _appProvider(
  _FakeAppGateway gateway, {
  bool guest = false,
}) async {
  return BusinessApplicationProvider(
    gateway: gateway,
    auth: guest ? await _guestAuth() : await _authenticatedAuth(),
  );
}

Future<BusinessClaimTargetProvider> _claimProvider(
  _FakeClaimTargetGateway gateway, {
  bool guest = false,
}) async {
  return BusinessClaimTargetProvider(
    gateway: gateway,
    auth: guest ? await _guestAuth() : await _authenticatedAuth(),
  );
}

Future<ManagedBusinessesProvider> _managedProvider(
  FakeBusinessMembershipGateway gateway, {
  bool guest = false,
}) async {
  return ManagedBusinessesProvider(
    membershipGateway: gateway,
    auth: guest ? await _guestAuth() : await _authenticatedAuth(),
  );
}

Future<BusinessProfileEditorProvider> _editorProvider(
  _ScriptableProfileGateway gateway,
) async {
  return BusinessProfileEditorProvider(
    gateway: gateway,
    directoryRepository: FakeCloudDirectoryRepository(const []),
    auth: await _authenticatedAuth(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // PART 1 (A) — Managed-business list lanes (A.1-A.14)
  // =========================================================================
  group('P2-D2 A managed list lanes', () {
    testWidgets('A.1 successful empty list renders the product empty state', (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway();
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.text(Ar.businessManageEmpty), findsOneWidget);
      expect(find.text('Test Co'), findsNothing);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
    });

    testWidgets('A.2 one managed business renders name and data', (WidgetTester tester) async {
      final gateway =
          FakeBusinessMembershipGateway(listResult: ManagedBusinessListAvailable([
            _summary(),
          ]));
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.text('Test Co'), findsOneWidget);
      expect(find.textContaining(Ar.businessClaimStatus), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
    });

    testWidgets('A.3 read-only member renders not-editable instead of navigation chevron',
        (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway(
        listResult: ManagedBusinessListAvailable([
          _summary(role: BusinessRole.member),
        ]),
      );
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.text(Ar.businessManageNotEditable), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsNothing);
    });

    testWidgets('A.4 data is preserved with a compact notice on failed refresh',
        (WidgetTester tester) async {
      final gateway =
          FakeBusinessMembershipGateway(listResult: ManagedBusinessListAvailable([
            _summary(),
          ]));
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.text('Test Co'), findsOneWidget);

      gateway.listResult =
          const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.network);
      await provider.load();
      await tester.pumpAndSettle();

      expect(find.text('Test Co'), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
    });

    testWidgets('A.5 tapping the compact retry clears the notice and re-reads',
        (WidgetTester tester) async {
      final gateway =
          FakeBusinessMembershipGateway(listResult: ManagedBusinessListAvailable([
            _summary(),
          ]));
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);

      gateway.listResult =
          const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.network);
      await provider.load();
      await tester.pumpAndSettle();
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);

      gateway.listResult = ManagedBusinessListAvailable([_summary()]);
      await tester.tap(find.widgetWithText(TextButton, Ar.retry));
      await tester.pumpAndSettle();

      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
      expect(find.text('Test Co'), findsOneWidget);
      expect(gateway.listMyBusinessesCalls, 3);
    });

    testWidgets('A.6 empty state plus failed refresh shows compact notice and empty state',
        (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway();
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.text(Ar.businessManageEmpty), findsOneWidget);

      gateway.listResult =
          const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.timeout);
      await provider.load();
      await tester.pumpAndSettle();

      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeTimeout), findsOneWidget);
      expect(find.text(Ar.businessManageEmpty), findsOneWidget);
    });

    testWidgets('A.7 first-load network failure renders the no-data notice', (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway(
        listResult:
            const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.network),
      );
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.text(Ar.businessManageEmpty), findsNothing);
    });

    testWidgets('A.8 timeout failure renders the time-out notice', (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway(
        listResult:
            const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.timeout),
      );
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.text(Ar.noticeTimeout), findsOneWidget);
    });

    testWidgets('A.9 no-data retry recovers without navigating away', (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway(
        listResult:
            const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.network),
      );
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);

      gateway.listResult = ManagedBusinessListAvailable([_summary()]);
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(find.text('Test Co'), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
      expect(gateway.listMyBusinessesCalls, 2);
    });

    testWidgets('A.10 refresh shows a thin progress row and preserves cards', (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway(
        listResult: ManagedBusinessListAvailable([
          _summary(name: 'First Co'),
        ]),
      );
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.text('First Co'), findsOneWidget);

      final gate = Completer<ManagedBusinessListResult>();
      gateway.onListMyBusinesses = () => gate.future;
      final loadFuture = provider.load();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('First Co'), findsOneWidget);

      gate.complete(
        ManagedBusinessListAvailable([_summary(name: 'Second Co')]),
      );
      await loadFuture;
      await tester.pumpAndSettle();

      expect(find.text('Second Co'), findsOneWidget);
      expect(find.text('First Co'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('A.11 service unavailable renders the service notice', (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway(
        listResult:
            const ManagedBusinessListUnavailable(),
      );
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.text(Ar.noticeServiceUnavailable), findsOneWidget);
    });

    testWidgets('A.12 permission denied renders the permission notice', (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway(
        listResult: const ManagedBusinessListDenied(
          BusinessRemoteReadFailureKind.permissionDenied,
        ),
      );
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      expect(find.text(Ar.noticePermissionDenied), findsOneWidget);
    });

    testWidgets('A.13 guest sees sign-in required, never a list or a notice', (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway(
        listResult: ManagedBusinessListAvailable([_summary()]),
      );
      final provider = await _managedProvider(gateway, guest: true);
      await _pumpManaged(tester, provider: provider);
      expect(find.text(Ar.businessManageSignInRequired), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, Ar.businessSignInButton),
          findsOneWidget);
      expect(find.text(Ar.businessManageEmpty), findsNothing);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
    });

    testWidgets('A.14 a manual refresh issues exactly one additional read', (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway();
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider);
      final afterInitialLoad = gateway.listMyBusinessesCalls;
      expect(afterInitialLoad, 1);

      await provider.load();
      await tester.pumpAndSettle();
      expect(gateway.listMyBusinessesCalls, afterInitialLoad + 1);
    });
  });

  // =========================================================================
  // PART 2 (B) — Managed profile editor lanes (B.15-B.20)
  // =========================================================================
  group('P2-D2 B managed profile editor lanes', () {
    testWidgets('B.15 successful profile read renders the editable fields', (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);
      expect(
        find.byKey(const Key('businessProfileNameField')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('businessProfileAddressField')),
        findsOneWidget,
      );
      expect(find.text('Test Co'), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
    });

    testWidgets('B.16 first-load network failure renders a no-data notice', (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult:
            ManagedProfileReadFailed(BusinessRemoteReadFailureKind.network),
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.byKey(const Key('businessProfileNameField')), findsNothing);
    });

    testWidgets('B.17 authoritative absence is a neutral, retry-free controlled state',
        (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadNotFound(),
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);
      expect(find.text(Ar.businessProfileCauseNotFound), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
      expect(find.text(Ar.retry), findsNothing);
      expect(find.byKey(const Key('businessProfileNameField')), findsNothing);
    });

    testWidgets('B.18 profile is preserved with a compact notice on failed refresh',
        (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);
      expect(find.byKey(const Key('businessProfileNameField')), findsOneWidget);

      gateway.readResult =
          ManagedProfileReadFailed(BusinessRemoteReadFailureKind.network);
      await provider.load(_entityId);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('businessProfileNameField')), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.text(Ar.businessProfileCauseNetwork), findsNothing);
    });

    testWidgets('B.19 refresh shows the thin progress row then clears it', (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);

      final gate = Completer<ManagedProfileReadResult>();
      gateway.onReadManagedProfile = (_) => gate.future;
      final loadFuture = provider.load(_entityId);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('businessProfileNameField')), findsOneWidget);

      gate.complete(
        ManagedProfileReadSuccess(
          _sampleProfile(updatedAt: DateTime.utc(2024, 1, 3)),
        ),
      );
      await loadFuture;
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
    });

    testWidgets('B.20 a read retry never triggers a save mutation', (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);

      gateway.readResult =
          ManagedProfileReadFailed(BusinessRemoteReadFailureKind.network);
      await provider.load(_entityId);
      await tester.pumpAndSettle();
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(gateway.updateCalls, 0);

      gateway.readResult = ManagedProfileReadSuccess(
        _sampleProfile(updatedAt: DateTime.utc(2024, 1, 4)),
      );
      await tester.tap(find.widgetWithText(TextButton, Ar.retry));
      await tester.pumpAndSettle();

      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
      expect(gateway.updateCalls, 0);
      expect(gateway.readCalls, 3);
    });
  });

  // =========================================================================
  // PART 3 (C) — Auxiliary (taxonomy) lanes (C.21-C.25)
  // =========================================================================
  group('P2-D2 C auxiliary taxonomy lanes', () {
    testWidgets('C.21 auxiliary failure keeps the editable profile with one notice',
        (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        auxiliaryFailureKind: BusinessRemoteReadFailureKind.network,
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);

      expect(find.byKey(const Key('businessProfileNameField')), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.text(Ar.businessProfileCauseNetwork), findsNothing);
      expect(find.text(Ar.businessProfileCauseUnexpected), findsNothing);
    });

    testWidgets('C.22 retrying only the auxiliary read clears the notice', (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        auxiliaryFailureKind: BusinessRemoteReadFailureKind.network,
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(gateway.categoryCalls, 1);

      await tester.tap(find.widgetWithText(TextButton, Ar.retry));
      await tester.pumpAndSettle();

      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
      expect(gateway.categoryCalls, 2);
      expect(gateway.readCalls, 2);
    });

    testWidgets('C.23 selectable catalogs are preserved during an auxiliary failure',
        (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        categories: const [
          ManagedSelectableCategory(
            id: _categoryId,
            code: 'structural',
            nameAr: 'إنشائي',
          ),
        ],
        regions: [
          ManagedSelectableRegion(
            id: _regionId,
            code: 'baghdad',
            nameAr: 'بغداد',
          ),
        ],
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);

      expect(
        find.byType(DropdownButtonFormField<String?>),
        findsNWidgets(2),
      );
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);

      gateway.recurringAuxiliaryFailure = true;
      gateway.auxiliaryFailureKind = BusinessRemoteReadFailureKind.timeout;
      await provider.load(_entityId);
      await tester.pumpAndSettle();

      expect(
        find.byType(DropdownButtonFormField<String?>),
        findsNWidgets(2),
      );
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeTimeout), findsOneWidget);
    });

    testWidgets('C.24 malformed auxiliary response maps to the malformed notice',
        (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        auxiliaryFailureKind: BusinessRemoteReadFailureKind.malformedResponse,
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);
      expect(find.text(Ar.noticeMalformed), findsOneWidget);
    });

    testWidgets('C.25 auxiliary service-unavailable maps to the service notice',
        (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        auxiliaryFailureKind:
            BusinessRemoteReadFailureKind.serviceUnavailable,
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);
      expect(find.text(Ar.noticeServiceUnavailable), findsOneWidget);
    });
  });

  // =========================================================================
  // PART 4 (D) — My-applications list lanes (D.26-D.31)
  // =========================================================================
  group('P2-D2 D my-applications list lanes', () {
    testWidgets('D.26 successful empty list renders the product empty state', (WidgetTester tester) async {
      final provider = await _appProvider(_FakeAppGateway());
      await _pumpAppList(tester, provider: provider);
      expect(find.text(Ar.businessNoApplications), findsOneWidget);
      expect(find.text(Ar.businessNewApplication), findsOneWidget);
      expect(find.text(Ar.businessTypeClaim), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
    });

    testWidgets('D.27 one application renders its metadata name', (WidgetTester tester) async {
      final provider = await _appProvider(
        _FakeAppGateway(
          listOwnResult: [
            _app(metadata: const {'name': 'Test Office'}),
          ],
        ),
      );
      await _pumpAppList(tester, provider: provider);
      expect(find.text('Test Office'), findsOneWidget);
    });

    testWidgets('D.28 first-load network failure renders a no-data notice', (WidgetTester tester) async {
      final gateway = _FakeAppGateway()..listFailureKind =
          BusinessRemoteReadFailureKind.network;
      final provider = await _appProvider(gateway);
      await _pumpAppList(tester, provider: provider);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.text('Test Office'), findsNothing);
    });

    testWidgets('D.29 list is preserved with a compact notice on failed refresh',
        (WidgetTester tester) async {
      final gateway = _FakeAppGateway(
        listOwnResult: [
          _app(metadata: const {'name': 'Test Office'}),
        ],
      );
      final provider = await _appProvider(gateway);
      await _pumpAppList(tester, provider: provider);
      expect(find.text('Test Office'), findsOneWidget);

      gateway.listFailureKind = BusinessRemoteReadFailureKind.network;
      await provider.loadApplications();
      await tester.pumpAndSettle();

      expect(find.text('Test Office'), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
    });

    testWidgets('D.30 empty list plus failed refresh keeps compact notice and empty state',
        (WidgetTester tester) async {
      final gateway = _FakeAppGateway();
      final provider = await _appProvider(gateway);
      await _pumpAppList(tester, provider: provider);
      expect(find.text(Ar.businessNoApplications), findsOneWidget);

      gateway.listFailureKind = BusinessRemoteReadFailureKind.network;
      await provider.loadApplications();
      await tester.pumpAndSettle();

      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.businessNoApplications), findsOneWidget);
    });

    testWidgets('D.31 refresh shows a thin progress row and preserves the cards',
        (WidgetTester tester) async {
      final gateway = _FakeAppGateway(
        listOwnResult: [
          _app(metadata: const {'name': 'First Office'}),
        ],
      );
      final provider = await _appProvider(gateway);
      await _pumpAppList(tester, provider: provider);
      expect(find.text('First Office'), findsOneWidget);

      final gate = Completer<List<BusinessApplication>>();
      gateway.onListOwnApplications = () => gate.future;
      final loadFuture = provider.loadApplications();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('First Office'), findsOneWidget);

      gate.complete([
        _app(metadata: const {'name': 'Second Office'}),
      ]);
      await loadFuture;
      await tester.pumpAndSettle();

      expect(find.text('Second Office'), findsOneWidget);
      expect(find.text('First Office'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  // =========================================================================
  // PART 5 (E) — Application detail lanes (E.32-E.37)
  // =========================================================================
  group('P2-D2 E application detail lanes', () {
    testWidgets('E.32 data renders the status chip and approved content', (WidgetTester tester) async {
      final gateway = _FakeAppGateway(
        getOwnResult: _app(
          id: 'a1',
          status: BusinessApplicationStatus.approved,
          approvedAt: DateTime.utc(2024, 2, 1),
        ),
      );
      final provider = await _appProvider(gateway);
      await _pumpAppDetail(tester, provider: provider);
      expect(
        find.byType(BusinessApplicationStatusChip),
        findsOneWidget,
      );
      expect(find.text(Ar.businessApprovedNote), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
    });

    testWidgets('E.33 authoritative absence is a neutral retry-free controlled state',
        (WidgetTester tester) async {
      final gateway = _FakeAppGateway(getOwnResult: null);
      final provider = await _appProvider(gateway);
      await _pumpAppDetail(tester, provider: provider);
      expect(find.text(Ar.businessCauseApplicationNotFound), findsOneWidget);
      expect(find.text(Ar.retry), findsNothing);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
      expect(find.byType(BusinessApplicationStatusChip), findsNothing);
      expect(gateway.getOwnCalls, ['a1']);
      expect(gateway.submitCalls, 0);
    });

    testWidgets('E.34 first-load network failure renders a no-data notice', (WidgetTester tester) async {
      final gateway = _FakeAppGateway()..getFailureKind =
          BusinessRemoteReadFailureKind.network;
      final provider = await _appProvider(gateway);
      await _pumpAppDetail(tester, provider: provider);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.byType(BusinessApplicationStatusChip), findsNothing);
    });

    testWidgets('E.35 data is preserved with a compact notice on failed refresh',
        (WidgetTester tester) async {
      final gateway = _FakeAppGateway(
        getOwnResult: _app(id: 'a1', metadata: const {'name': 'Test Office'}),
      );
      final provider = await _appProvider(gateway);
      await _pumpAppDetail(tester, provider: provider);
      expect(find.text('Test Office'), findsOneWidget);

      gateway.getFailureKind = BusinessRemoteReadFailureKind.network;
      await provider.loadApplication('a1');
      await tester.pumpAndSettle();

      expect(find.text('Test Office'), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
    });

    testWidgets('E.36 malformed id mismatch fails typ and never leaks the raw id',
        (WidgetTester tester) async {
      final gateway = _FakeAppGateway(getOwnResult: _app(id: 'other-id'));
      final provider = await _appProvider(gateway);
      await _pumpAppDetail(tester, provider: provider);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeMalformed), findsOneWidget);
      expect(find.byType(BusinessApplicationStatusChip), findsNothing);
      expect(provider.current, isNull);
      expect(find.textContaining('other-id'), findsNothing);
    });

    testWidgets('E.37 submit flows through confirm dialog and submitApplication only',
        (WidgetTester tester) async {
      final gateway = _FakeAppGateway(
        getOwnResult: _app(id: 'a1', status: BusinessApplicationStatus.draft),
      );
      final provider = await _appProvider(gateway);
      await _pumpAppDetail(tester, provider: provider);

      await tester.tap(find.widgetWithText(ElevatedButton, Ar.businessSubmit));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ElevatedButton, Ar.businessSubmitConfirm),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.businessSubmitConfirm),
      );
      await tester.pumpAndSettle();

      expect(gateway.submitCalls, 1);
      expect(gateway.resubmitCalls, 0);
      expect(find.text(Ar.businessResubmit), findsNothing);
    });
  });

  // =========================================================================
  // PART 6 (F) — Claim selector lanes (F.38-F.43)
  // =========================================================================
  group('P2-D2 F claim selector lanes', () {
    testWidgets('F.38 empty targets render the product empty state and refresh action',
        (WidgetTester tester) async {
      final claimGateway = _FakeClaimTargetGateway();
      final provider = await _appProvider(_FakeAppGateway());
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
      );
      expect(find.text(Ar.businessClaimTargetsEmpty), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text(Ar.businessRefresh),
          matching: find.byWidgetPredicate((w) => w is OutlinedButton),
        ),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
    });

    testWidgets('F.39 targets render canonical labels but never raw tokens', (WidgetTester tester) async {
      final claimGateway = _FakeClaimTargetGateway(
        targetsResult: [
          _target(name: 'Alpha', entityType: 'company'),
        ],
      );
      final provider = await _appProvider(_FakeAppGateway());
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
      );
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text(Ar.businessEntityTypeCompany), findsOneWidget);
      expect(find.text('company'), findsNothing);
      expect(find.text('t1'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('F.40 first-load network failure renders a no-data notice', (WidgetTester tester) async {
      final claimGateway = _FakeClaimTargetGateway(
        failureKind: BusinessRemoteReadFailureKind.network,
      );
      final provider = await _appProvider(_FakeAppGateway());
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
      );
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(claimGateway.listCalls, 1);
    });

    testWidgets('F.41 targets are preserved with a compact notice on failed reload',
        (WidgetTester tester) async {
      final claimGateway = _FakeClaimTargetGateway(
        targetsResult: [_target(name: 'Alpha')],
      );
      final provider = await _appProvider(_FakeAppGateway());
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
      );
      expect(find.text('Alpha'), findsOneWidget);

      claimGateway.failureKind = BusinessRemoteReadFailureKind.network;
      await claimProvider.reload();
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
    });

    testWidgets('F.42 confirming the claim files exactly one claim draft', (WidgetTester tester) async {
      final claimGateway = _FakeClaimTargetGateway(
        targetsResult: [_target(id: 't1', name: 'Alpha')],
      );
      final appGateway = _FakeAppGateway();
      final provider = await _appProvider(appGateway);
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
      );
      expect(find.text('Alpha'), findsOneWidget);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ElevatedButton, Ar.businessClaimTarget),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.businessClaimTarget),
      );
      await tester.pumpAndSettle();

      expect(appGateway.createClaimDraftCalls, ['t1']);
    });

    testWidgets('F.43 guests see the sign-in required view and trigger zero reads',
        (WidgetTester tester) async {
      final claimGateway = _FakeClaimTargetGateway(
        targetsResult: [_target(name: 'Alpha')],
      );
      final provider = await _appProvider(_FakeAppGateway(), guest: true);
      final claimProvider = await _claimProvider(claimGateway, guest: true);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
      );
      expect(find.byType(BusinessSignInRequiredView), findsOneWidget);
      expect(find.text(Ar.businessSignInRequired), findsOneWidget);
      expect(claimGateway.listCalls, 0);
    });
  });

  // =========================================================================
  // PART 7 (G) — Connectivity-derived offline promotion (G.44-G.47)
  // =========================================================================
  group('P2-D2 G connectivity offline promotion', () {
    test('G.44 mapping is pure: only network promotes, only when confirmed',
        () {
      final cases = <(BusinessRemoteReadFailureKind, bool, RemoteDataCause)>[
        (BusinessRemoteReadFailureKind.network, true, RemoteDataCause.offline),
        (BusinessRemoteReadFailureKind.network, false, RemoteDataCause.network),
        (BusinessRemoteReadFailureKind.timeout, true, RemoteDataCause.timeout),
        (BusinessRemoteReadFailureKind.timeout, false, RemoteDataCause.timeout),
        (
          BusinessRemoteReadFailureKind.serviceUnavailable,
          true,
          RemoteDataCause.serviceUnavailable,
        ),
        (
          BusinessRemoteReadFailureKind.serviceUnavailable,
          false,
          RemoteDataCause.serviceUnavailable,
        ),
        (
          BusinessRemoteReadFailureKind.malformedResponse,
          true,
          RemoteDataCause.malformed,
        ),
        (
          BusinessRemoteReadFailureKind.malformedResponse,
          false,
          RemoteDataCause.malformed,
        ),
        (
          BusinessRemoteReadFailureKind.permissionDenied,
          true,
          RemoteDataCause.permissionDenied,
        ),
        (
          BusinessRemoteReadFailureKind.permissionDenied,
          false,
          RemoteDataCause.permissionDenied,
        ),
        (
          BusinessRemoteReadFailureKind.authRestricted,
          true,
          RemoteDataCause.authRestricted,
        ),
        (
          BusinessRemoteReadFailureKind.authRestricted,
          false,
          RemoteDataCause.authRestricted,
        ),
        (BusinessRemoteReadFailureKind.unexpected, true, RemoteDataCause.unexpected),
        (BusinessRemoteReadFailureKind.unexpected, false, RemoteDataCause.unexpected),
      ];
      for (final (kind, unavailable, expected) in cases) {
        expect(
          businessReadFailureToRemoteDataCause(
            kind,
            connectivityIsUnavailable: unavailable,
          ),
          expected,
          reason: '$kind ${unavailable ? 'offline-flagged' : 'online'}',
        );
      }
    });

    testWidgets('G.45 offline notice renders when connectivity is confirmed unavailable',
        (WidgetTester tester) async {
      final connectivity = _connectivitySource(available: false);
      final gateway = FakeBusinessMembershipGateway(
        listResult:
            const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.network),
      );
      final provider = await _managedProvider(gateway);
      await _pumpManaged(
        tester,
        provider: provider,
        connectivity: connectivity.provider,
      );
      expect(find.text(Ar.noticeOffline), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsNothing);
    });

    testWidgets('G.46 reconnect alone issues zero new business reads', (WidgetTester tester) async {
      final connectivitySource = _connectivitySource(available: false);
      final gateway = FakeBusinessMembershipGateway(
        listResult:
            const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.network),
      );
      final provider = await _managedProvider(gateway);
      await _pumpManaged(
        tester,
        provider: provider,
        connectivity: connectivitySource.provider,
      );
      expect(find.text(Ar.noticeOffline), findsOneWidget);
      expect(gateway.listMyBusinessesCalls, 1);

      connectivitySource.source.available = true;
      connectivitySource.source.changes.add(true);
      await tester.pumpAndSettle();

      // Rebuild re-renders as network (online), but no automatic read fired.
      expect(gateway.listMyBusinessesCalls, 1);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
    });

    testWidgets('G.47 the claim selector also stays read-quiet across a reconnect',
        (WidgetTester tester) async {
      final connectivitySource = _connectivitySource(available: false);
      final claimGateway = _FakeClaimTargetGateway(
        failureKind: BusinessRemoteReadFailureKind.network,
      );
      final provider = await _appProvider(_FakeAppGateway());
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
        connectivity: connectivitySource.provider,
      );
      expect(find.text(Ar.noticeOffline), findsOneWidget);
      expect(claimGateway.listCalls, 1);

      connectivitySource.source.available = true;
      connectivitySource.source.changes.add(true);
      await tester.pumpAndSettle();

      expect(claimGateway.listCalls, 1);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
    });
  });

  // =========================================================================
  // PART 8 (H) — Notice ownership (H.48-H.49)
  // =========================================================================
  group('P2-D2 H notice ownership', () {
    testWidgets('H.48 exactly one typed notice per failed lane', (WidgetTester tester) async {
      // Managed list data + failed refresh.
      final membership = FakeBusinessMembershipGateway(
        listResult: ManagedBusinessListAvailable([
          _summary(name: 'Lane Co'),
        ]),
      );
      final provider = await _managedProvider(membership);
      await _pumpManaged(tester, provider: provider);
      membership.listResult =
          const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.network);
      await provider.load();
      await tester.pumpAndSettle();
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text('Lane Co'), findsOneWidget);

      // Application list data + failed refresh.
      final appGateway = _FakeAppGateway(
        listOwnResult: [
          _app(metadata: const {'name': 'Lane App'}),
        ],
      );
      final appProvider = await _appProvider(appGateway);
      await _pumpAppList(tester, provider: appProvider);
      appGateway.listFailureKind = BusinessRemoteReadFailureKind.timeout;
      await appProvider.loadApplications();
      await tester.pumpAndSettle();
      expect(find.text(Ar.noticeTimeout), findsOneWidget);
      expect(find.text('Lane App'), findsOneWidget);
    });

    testWidgets('H.49 legacy duplicate text is suppressed while a typed notice shows',
        (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        auxiliaryFailureKind: BusinessRemoteReadFailureKind.network,
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);
      expect(find.byType(BusinessRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.businessProfileCauseNetwork), findsNothing);
      expect(find.text(Ar.businessProfileCauseUnexpected), findsNothing);
    });
  });

  // =========================================================================
  // PART 9 (I) — Raw backend text never reaches the UI (I.50)
  // =========================================================================
  group('P2-D2 I raw error hygiene', () {
    testWidgets('I.50 no SQLSTATE or server code text is ever rendered', (WidgetTester tester) async {
      // Managed list network failure.
      final membership = FakeBusinessMembershipGateway(
        listResult:
            const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.network),
      );
      final mProvider = await _managedProvider(membership);
      await _pumpManaged(tester, provider: mProvider);
      expect(find.textContaining('SQLSTATE'), findsNothing);
      expect(find.textContaining('P0AUT'), findsNothing);

      // Detail malformed response.
      final gateway = _FakeAppGateway(getOwnResult: _app(id: 'x'));
      final dProvider = await _appProvider(gateway);
      await _pumpAppDetail(tester, provider: dProvider);
      expect(find.textContaining('SQLSTATE'), findsNothing);
      expect(find.textContaining('P0NAC'), findsNothing);

      // Claim selector network failure.
      final claimGateway = _FakeClaimTargetGateway(
        failureKind: BusinessRemoteReadFailureKind.network,
      );
      final cProvider = await _appProvider(_FakeAppGateway());
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: cProvider,
        claimProvider: claimProvider,
      );
      expect(find.textContaining('SQLSTATE'), findsNothing);
      expect(find.textContaining('P0CLM'), findsNothing);
    });
  });

  // =========================================================================
  // PART 10 (J) — AR/EN localization (J.51-J.55)
  // =========================================================================
  group('P2-D2 J localization', () {
    testWidgets('J.51 managed list titles localize to AR and EN', (WidgetTester tester) async {
      final gateway = FakeBusinessMembershipGateway();
      final provider = await _managedProvider(gateway);
      await _pumpManaged(tester, provider: provider, isArabic: true);
      expect(find.text(Ar.businessManageTitle), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      final enProvider = await _managedProvider(FakeBusinessMembershipGateway());
      await _pumpManaged(tester, provider: enProvider, isArabic: false);
      expect(find.text(En.businessManageTitle), findsOneWidget);
    });

    testWidgets('J.52 managed empty state localizes to AR and EN', (WidgetTester tester) async {
      final provider = await _managedProvider(FakeBusinessMembershipGateway());
      await _pumpManaged(tester, provider: provider, isArabic: true);
      expect(find.text(Ar.businessManageEmpty), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      final enProvider = await _managedProvider(FakeBusinessMembershipGateway());
      await _pumpManaged(tester, provider: enProvider, isArabic: false);
      expect(find.text(En.businessManageEmpty), findsOneWidget);
    });

    testWidgets('J.53 editor titles localize to AR and EN', (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider, isArabic: true);
      expect(find.text(Ar.businessProfileEditTitle), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      final enGateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final enProvider = await _editorProvider(enGateway);
      await _pumpEditor(tester, provider: enProvider, isArabic: false);
      expect(find.text(En.businessProfileEditTitle), findsOneWidget);
    });

    testWidgets('J.54 application list card labels localize to EN', (WidgetTester tester) async {
      final gateway = _FakeAppGateway(
        listOwnResult: [
          _app(metadata: const {'name': 'Test Office', 'entity_type': 'company'}),
        ],
      );
      final provider = await _appProvider(gateway);
      await _pumpAppList(tester, provider: provider, isArabic: false);
      expect(find.text(En.businessApplicationsTitle), findsOneWidget);
      expect(find.text('Test Office'), findsOneWidget);
      expect(find.text(En.businessEntityTypeCompany), findsOneWidget);
      expect(find.text(Ar.businessEntityTypeCompany), findsNothing);
    });

    testWidgets('J.55 claim selector and notices localize to EN', (WidgetTester tester) async {
      final claimGateway = _FakeClaimTargetGateway(
        failureKind: BusinessRemoteReadFailureKind.network,
      );
      final provider = await _appProvider(_FakeAppGateway());
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
        isArabic: false,
      );
      expect(find.text(En.businessClaimApplicationTitle), findsOneWidget);
      expect(find.text(En.noticeNetwork), findsOneWidget);
      expect(find.text(En.retry), findsOneWidget);

      // Also verify the localized product empty state.
      await tester.pumpWidget(const SizedBox());
      final emptyClaim = _FakeClaimTargetGateway();
      final emptyProvider = await _appProvider(_FakeAppGateway());
      final emptyClaimProvider = await _claimProvider(emptyClaim);
      await _pumpClaim(
        tester,
        appProvider: emptyProvider,
        claimProvider: emptyClaimProvider,
        isArabic: false,
      );
      expect(find.text(En.businessClaimTargetsEmpty), findsOneWidget);
      expect(find.text(Ar.businessClaimTargetsEmpty), findsNothing);
    });

    testWidgets('J.56 application-list empty state localizes to EN with LTR',
        (WidgetTester tester) async {
      final provider = await _appProvider(_FakeAppGateway());
      await _pumpAppList(tester, provider: provider, isArabic: false);
      expect(find.text(En.businessNoApplications), findsOneWidget);
      expect(find.text(Ar.businessNoApplications), findsNothing);
      expect(find.text(En.businessNewApplication), findsOneWidget);
      expect(find.text(En.businessTypeClaim), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
      expect(
        Directionality.of(
          tester.element(find.text(En.businessNoApplications)),
        ),
        TextDirection.ltr,
      );
    });

    testWidgets('J.57 application-list empty state stays Arabic with RTL',
        (WidgetTester tester) async {
      final provider = await _appProvider(_FakeAppGateway());
      await _pumpAppList(tester, provider: provider, isArabic: true);
      expect(find.text(Ar.businessNoApplications), findsOneWidget);
      expect(find.text(Ar.businessNewApplication), findsOneWidget);
      expect(find.text(Ar.businessTypeClaim), findsOneWidget);
      expect(find.byType(BusinessRemoteReadNotice), findsNothing);
      expect(
        Directionality.of(
          tester.element(find.text(Ar.businessNoApplications)),
        ),
        TextDirection.rtl,
      );
    });

    testWidgets('J.58 claim verification labels localize to EN on the rendered screen',
        (WidgetTester tester) async {
      final claimGateway = _FakeClaimTargetGateway(
        targetsResult: [
          _target(
              id: 'r1', name: 'Row One', verificationStatus: 'unverified'),
          _target(id: 'r2', name: 'Row Two', verificationStatus: 'pending'),
          _target(
              id: 'r3', name: 'Row Three', verificationStatus: 'verified'),
          _target(
              id: 'r4', name: 'Row Four', verificationStatus: 'rejected'),
          _target(
              id: 'r5', name: 'Row Five', verificationStatus: 'suspended'),
          _target(id: 'r6', name: 'Row Six', verificationStatus: 'bogus'),
        ],
      );
      final provider = await _appProvider(_FakeAppGateway());
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
        isArabic: false,
      );
      String enLine(String label) => '${En.businessVerificationStatus}: $label';
      String arLine(String label) => '${Ar.businessVerificationStatus}: $label';

      expect(find.text(enLine(En.verificationUnverified)), findsOneWidget);
      expect(find.text(enLine(En.verificationPending)), findsOneWidget);
      expect(find.text(enLine(En.verificationVerified)), findsOneWidget);
      expect(find.text(enLine(En.verificationRejected)), findsOneWidget);
      expect(find.text(enLine(En.verificationSuspended)), findsOneWidget);
      expect(find.text(enLine(En.directoryNotSpecified)), findsOneWidget);

      expect(find.text(arLine(Ar.verificationUnverified)), findsNothing);
      expect(find.text(arLine(Ar.verificationPending)), findsNothing);
      expect(find.text(arLine(Ar.verificationVerified)), findsNothing);
      expect(find.text(arLine(Ar.verificationRejected)), findsNothing);
      expect(find.text(arLine(Ar.verificationSuspended)), findsNothing);
      expect(find.text(arLine(Ar.directoryNotSpecified)), findsNothing);

      expect(
        Directionality.of(
          tester.element(find.text(enLine(En.verificationVerified))),
        ),
        TextDirection.ltr,
      );
    });

    testWidgets('J.59 claim verification labels stay Arabic with RTL',
        (WidgetTester tester) async {
      final claimGateway = _FakeClaimTargetGateway(
        targetsResult: [
          _target(
              id: 'r1', name: 'Row One', verificationStatus: 'unverified'),
          _target(id: 'r2', name: 'Row Two', verificationStatus: 'pending'),
          _target(
              id: 'r3', name: 'Row Three', verificationStatus: 'verified'),
          _target(
              id: 'r4', name: 'Row Four', verificationStatus: 'rejected'),
          _target(
              id: 'r5', name: 'Row Five', verificationStatus: 'suspended'),
          _target(id: 'r6', name: 'Row Six', verificationStatus: 'bogus'),
        ],
      );
      final provider = await _appProvider(_FakeAppGateway());
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
        isArabic: true,
      );
      String enLine(String label) => '${En.businessVerificationStatus}: $label';
      String arLine(String label) => '${Ar.businessVerificationStatus}: $label';

      expect(find.text(arLine(Ar.verificationUnverified)), findsOneWidget);
      expect(find.text(arLine(Ar.verificationPending)), findsOneWidget);
      expect(find.text(arLine(Ar.verificationVerified)), findsOneWidget);
      expect(find.text(arLine(Ar.verificationRejected)), findsOneWidget);
      expect(find.text(arLine(Ar.verificationSuspended)), findsOneWidget);
      expect(find.text(arLine(Ar.directoryNotSpecified)), findsOneWidget);

      expect(find.text(enLine(En.verificationUnverified)), findsNothing);
      expect(find.text(enLine(En.verificationPending)), findsNothing);
      expect(find.text(enLine(En.verificationVerified)), findsNothing);
      expect(find.text(enLine(En.verificationRejected)), findsNothing);
      expect(find.text(enLine(En.verificationSuspended)), findsNothing);
      expect(find.text(enLine(En.directoryNotSpecified)), findsNothing);

      expect(
        Directionality.of(
          tester.element(find.text(arLine(Ar.verificationVerified))),
        ),
        TextDirection.rtl,
      );
    });
  });

  // =========================================================================
  // PART 11 (K) — Mutation compatibility (K.56-K.58)
  // =========================================================================
  group('P2-D2 K mutation compatibility', () {
    testWidgets('K.56 submit/resubmit gateway call counts are unchanged', (WidgetTester tester) async {
      final gateway = _FakeAppGateway();
      final provider = await _appProvider(gateway);

      final submitted =
          await provider.submit(_app(status: BusinessApplicationStatus.draft));
      expect(gateway.submitCalls, 1);
      expect(submitted, isA<BusinessApplicationSubmitted>());

      // Resubmit is only valid for NEEDS_CORRECTION: a DRAFT must not invoke it.
      final rejected = await provider.resubmit(
        _app(status: BusinessApplicationStatus.draft),
      );
      expect(gateway.resubmitCalls, 0);
      expect(rejected, isNull);

      // The resubmit lane still works for the valid source status.
      final resubmitted = await provider.resubmit(
        _app(status: BusinessApplicationStatus.needsCorrection),
      );
      expect(gateway.resubmitCalls, 1);
      expect(resubmitted, isA<BusinessApplicationSubmitted>());
    });

    testWidgets('K.57 a denied claim saves nothing and shows exactly one message',
        (WidgetTester tester) async {
      final claimGateway = _FakeClaimTargetGateway(
        targetsResult: [_target(id: 't1', name: 'Alpha')],
      );
      final appGateway = _FakeAppGateway(
        onCreateClaimDraft: (_) async =>
            const BusinessApplicationCreateDenied(
              BusinessApplicationRejectionCause.duplicateClaim,
            ),
      );
      final provider = await _appProvider(appGateway);
      final claimProvider = await _claimProvider(claimGateway);
      await _pumpClaim(
        tester,
        appProvider: provider,
        claimProvider: claimProvider,
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.businessClaimTarget),
      );
      await tester.pumpAndSettle();

      expect(appGateway.createClaimDraftCalls, ['t1']);
      expect(find.text(Ar.businessCauseDuplicateClaim), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('K.58 one editor save path and never a mutation from read retries',
        (WidgetTester tester) async {
      final gateway = _ScriptableProfileGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        updateResult: ManagedProfileUpdateSuccess(
          _sampleProfile(updatedAt: DateTime.utc(2024, 1, 5)),
        ),
      );
      final provider = await _editorProvider(gateway);
      await _pumpEditor(tester, provider: provider);
      expect(gateway.updateCalls, 0);

      // Make a dirty edit so the SaveBar is enabled.
      await tester.enterText(
        find.byKey(const Key('businessProfileNameField')),
        'Renamed Co',
      );
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ElevatedButton, Ar.businessProfileSave),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.businessProfileSave),
      );
      await tester.pumpAndSettle();
      // Confirm the save dialog (its confirm action is a TextButton).
      await tester.tap(
        find.widgetWithText(TextButton, Ar.businessProfileSave),
      );
      await tester.pumpAndSettle();

      expect(gateway.updateCalls, 1);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(Ar.businessProfileSaved), findsOneWidget);
    });
  });
}