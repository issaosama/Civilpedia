import 'dart:async';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/business/data/supabase_business_claim_target_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_capability_resolver.dart';
import 'package:civilpedia/features/business/domain/business_application_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_metadata.dart';
import 'package:civilpedia/features/business/domain/business_application_policy.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:civilpedia/features/business/domain/business_claim_target.dart';
import 'package:civilpedia/features/business/domain/business_claim_target_gateway.dart';
import 'package:civilpedia/features/business/domain/directory_entity_types.dart';
import 'package:civilpedia/features/business/presentation/providers/business_application_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/business_claim_target_provider.dart';
import 'package:civilpedia/features/business/presentation/screens/application_claim_form_screen.dart';
import 'package:civilpedia/features/business/presentation/screens/application_detail_screen.dart';
import 'package:civilpedia/features/business/presentation/screens/application_new_form_screen.dart';
import 'package:civilpedia/features/business/presentation/screens/my_applications_screen.dart';
import 'package:civilpedia/features/business/presentation/widgets/business_application_status_chip.dart';
import 'package:civilpedia/features/business/presentation/widgets/business_application_status_presentation.dart';
import 'package:civilpedia/features/business/presentation/widgets/business_claim_verification_labels.dart';
import 'package:civilpedia/features/business/presentation/widgets/directory_entity_type_labels.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes/fake_auth_gateway.dart';

// ---------------------------------------------------------------------------
// Fake gateways
// ---------------------------------------------------------------------------

class _FakeAppGateway implements BusinessApplicationGateway {
  _FakeAppGateway({
    this.listOwnResult = const [],
    this.getOwnResult,
    this.onSubmitApplication,
  });

  @override
  final bool isAvailable = true;

  final List<String> listOwnCalls = [];
  final List<String> getOwnCalls = [];
  final List<Map<String, dynamic>?> createNewDraftCalls = [];
  final List<String> createClaimDraftCalls = [];
  int submitCalls = 0;
  int resubmitCalls = 0;

  /// Thrown (once) from [listOwnApplications] when set to simulate a network
  /// failure; cleared for the retry path.
  Object? listOwnError;

  List<BusinessApplication> listOwnResult = const [];
  BusinessApplication? getOwnResult;

  Future<BusinessApplicationCreateResult> Function()? onCreateNewDraft;
  Future<BusinessApplicationCreateResult> Function(String targetId)?
      onCreateClaimDraft;
  Future<BusinessApplicationSubmitResult> Function(BusinessApplication)?
      onSubmitApplication;
  Future<BusinessApplicationSubmitResult> Function(BusinessApplication)?
      onResubmitApplication;

  @override
  Future<List<BusinessApplication>> listOwnApplications(String userId) async {
    listOwnCalls.add(userId);
    final error = listOwnError;
    if (error != null) throw error;
    return listOwnResult;
  }

  @override
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  ) async {
    getOwnCalls.add(applicationId);
    return getOwnResult;
  }

  @override
  Future<BusinessApplicationCreateResult> createNewDraft({
    required String currentUserId,
    Map<String, dynamic>? metadata,
  }) async {
    createNewDraftCalls.add(metadata);
    if (onCreateNewDraft != null) {
      final result = await onCreateNewDraft!();
      return result;
    }
    return BusinessApplicationCreated(
      BusinessApplication(
        id: 'app-new-1',
        applicantUserId: currentUserId,
        type: BusinessApplicationType.newApplication,
        status: BusinessApplicationStatus.draft,
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
    if (onCreateClaimDraft != null) {
      return await onCreateClaimDraft!(targetEntityId);
    }
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
    if (onSubmitApplication != null) {
      return await onSubmitApplication!(application);
    }
    return BusinessApplicationSubmitted(
      BusinessApplication(
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
    if (onResubmitApplication != null) {
      return await onResubmitApplication!(application);
    }
    return BusinessApplicationSubmitted(
      BusinessApplication(
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
  _FakeClaimTargetGateway({this.targetsResult = const []});

  @override
  final bool isAvailable = true;

  List<BusinessClaimTarget> targetsResult;
  int listCalls = 0;

  @override
  Future<List<BusinessClaimTarget>> listUnclaimedTargets() async {
    listCalls++;
    return targetsResult;
  }
}

// ---------------------------------------------------------------------------
// Constants + helpers
// ---------------------------------------------------------------------------

const _userId = 'user-0000-0000-0000-000000000001';

const _testSession = AuthSession(
  userId: _userId,
  email: 'test@civilpedia.com',
  displayName: 'tester',
);

BusinessApplication _app({
  String id = 'app-1',
  String? applicantUserId,
  BusinessApplicationType type = BusinessApplicationType.newApplication,
  BusinessApplicationStatus status = BusinessApplicationStatus.draft,
  String? targetEntityId,
  Map<String, dynamic>? metadata,
}) =>
    BusinessApplication(
      id: id,
      applicantUserId: applicantUserId ?? _userId,
      type: type,
      status: status,
      targetEntityId: targetEntityId,
      metadata: metadata,
    );

/// An authenticated [AuthProvider] backed by the deterministic fake gateway.
AuthProvider _authenticatedAuth() => AuthProvider(
      gateway: FakeAuthGateway(signInResult: _testSession),
    );

/// Creates an authenticated [BusinessApplicationProvider].
Future<BusinessApplicationProvider> _makeProvider(_FakeAppGateway gateway) async {
  final auth = _authenticatedAuth();
  await auth.signInWithGoogle();
  return BusinessApplicationProvider(gateway: gateway, auth: auth);
}

Widget _wrapWithProviders(BusinessApplicationProvider business, Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: business),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: MaterialApp(home: home),
  );
}

Widget _wrapClaimForm(
  BusinessApplicationProvider business,
  BusinessClaimTargetProvider claim,
  Widget home,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: business),
      ChangeNotifierProvider.value(value: claim),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: MaterialApp(home: home),
  );
}

Widget _chipApp() {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: const MaterialApp(
      home: Scaffold(
        body: BusinessApplicationStatusChip(
          status: BusinessApplicationStatus.draft,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // A. Status presentation + chip (canonical, reusable)
  // =========================================================================
  group('A. Status presentation', () {
    test('1. label for every one of the nine canonical statuses is non-empty',
        () {
      for (final status in BusinessApplicationStatus.values) {
        final label = BusinessApplicationStatusPresentation.labelFor(
          status,
          isArabic: true,
        );
        expect(label, isNotEmpty, reason: 'Missing label for ${status.name}');
      }
    });

    test('2. every canonical status has a semantic icon and accent', () {
      for (final status in BusinessApplicationStatus.values) {
        expect(
          BusinessApplicationStatusPresentation.iconFor(status),
          isNotNull,
          reason: 'Missing icon for ${status.name}',
        );
        expect(
          BusinessApplicationStatusPresentation.colorFor(status),
          isNotNull,
          reason: 'Missing color for ${status.name}',
        );
      }
    });

    test('3. unknown status fails safe with neutral label', () {
      final label = BusinessApplicationStatusPresentation.labelFor(
        BusinessApplicationStatus.unknown,
        isArabic: true,
      );
      expect(label, equals(Ar.businessStatusUnknown));
    });

    test('4. nine canonical statuses match the domain enum exactly', () {
      final known = BusinessApplicationStatus.values
          .where((s) => s.isKnown)
          .toList();
      expect(known.length, 9);
      expect(
        known.map((s) => s.code).toSet(),
        equals({
          'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEEDS_CORRECTION',
          'CONTACTED', 'VISIT_SCHEDULED', 'APPROVED', 'REJECTED',
          'ACTIVATED',
        }),
      );
    });

    testWidgets('5. status chip renders icon + Arabic label for DRAFT',
        (tester) async {
      await tester.pumpWidget(_chipApp());
      await tester.pumpAndSettle();
      expect(find.text(Ar.businessStatusDraft), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
    });
  });

  // =========================================================================
  // B. DirectoryEntityType canonical source
  // =========================================================================
  group('B. DirectoryEntityType source', () {
    test('6. exactly nine canonical values', () {
      expect(DirectoryEntityType.all.length, 9);
    });

    test('7. values match the migration 00005 CHECK set exactly', () {
      const expected = <String>{
        'company', 'engineering_office', 'contractor', 'supplier', 'store',
        'technician', 'laboratory', 'equipment_provider', 'service_provider',
      };
      expect(DirectoryEntityType.all.toSet(), equals(expected));
      expect(DirectoryEntityType.all.length, expected.length);
    });

    test('8. isKnown fails closed for unknown values', () {
      expect(DirectoryEntityType.isKnown('company'), isTrue);
      expect(DirectoryEntityType.isKnown('Company'), isFalse);
      expect(DirectoryEntityType.isKnown(''), isFalse);
      expect(DirectoryEntityType.isKnown(null), isFalse);
      expect(DirectoryEntityType.isKnown('shop'), isFalse);
    });
  });

  // =========================================================================
  // C. BusinessClaimTarget model + claim target provider
  // =========================================================================
  group('C. BusinessClaimTarget', () {
    test('9. parses canonical row fields', () {
      final row = <String, dynamic>{
        'id': '30000000-0000-0000-0000-000000000001',
        'name': 'Alpha',
        'entity_type': 'company',
        'claim_status': 'unclaimed',
        'verification_status': 'verified',
      };
      final target = BusinessClaimTarget.tryFromRow(row)!;
      expect(target.id, '30000000-0000-0000-0000-000000000001');
      expect(target.name, 'Alpha');
      expect(target.entityType, 'company');
      expect(target.claimStatus, 'unclaimed');
      expect(target.verificationStatus, 'verified');
      expect(target.isUnclaimed, isTrue);
    });

    test('10. claim_status pending/claimed → not unclaimed', () {
      for (final status in ['pending', 'claimed']) {
        final target = BusinessClaimTarget.tryFromRow({
          'id': 'id', 'name': 'X', 'entity_type': 'company',
          'claim_status': status,
        })!;
        expect(target.isUnclaimed, isFalse, reason: 'Status: $status');
      }
    });

    test('11. unknown claim_status → not claimable (fail safe)', () {
      final target = BusinessClaimTarget.tryFromRow({
        'id': 'id', 'name': 'X', 'entity_type': 'company',
        'claim_status': 'unknown_state',
      })!;
      expect(target.isUnclaimed, isFalse);
    });

    test('12. missing required columns → null (fail closed)', () {
      expect(BusinessClaimTarget.tryFromRow({'id': 'x'}), isNull);
      expect(
        BusinessClaimTarget.tryFromRow({
          'id': 'a', 'name': 'X', 'entity_type': 'company',
        }),
        isNull,
      );
    });

    test('12b. claim target provider keeps only unclaimed targets', () async {
      final gateway = _FakeClaimTargetGateway(
        targetsResult: const [
          BusinessClaimTarget(
            id: '30000000-0000-0000-0000-000000000001',
            name: 'Alpha',
            entityType: 'company',
            claimStatus: 'unclaimed',
          ),
          BusinessClaimTarget(
            id: '30000000-0000-0000-0000-000000000002',
            name: 'Beta',
            entityType: 'store',
            claimStatus: 'claimed',
          ),
        ],
      );
      final provider = BusinessClaimTargetProvider(gateway: gateway);
      await provider.reload();
      expect(provider.state, BusinessClaimTargetState.data);
      expect(provider.targets.length, 1);
      expect(provider.targets.first.id,
          '30000000-0000-0000-0000-000000000001');
    });

    test('12c. claim target provider maps zero targets to empty state', () async {
      final gateway = _FakeClaimTargetGateway(targetsResult: const []);
      final provider = BusinessClaimTargetProvider(gateway: gateway);
      await provider.reload();
      expect(provider.state, BusinessClaimTargetState.empty);
    });
  });

  // =========================================================================
  // D. NEW form validation + boundary
  // =========================================================================
  group('D. NEW form state', () {
    Future<void> pumpForm(
      WidgetTester tester,
      BusinessApplicationProvider provider,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          provider,
          const Scaffold(body: ApplicationNewFormScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('13. blank name is rejected and no draft is created',
        (tester) async {
      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);
      await pumpForm(tester, provider);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(gateway.createNewDraftCalls, isEmpty);
    });

    testWidgets('14. entity_type not selected is rejected and no draft is'
        ' created', (tester) async {
      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);
      await pumpForm(tester, provider);

      await tester.enterText(find.byType(TextFormField), 'Test Office');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(gateway.createNewDraftCalls, isEmpty);
    });

    testWidgets('15. dropdown offers every canonical entity type',
        (tester) async {
      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);
      await pumpForm(tester, provider);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      for (final type in DirectoryEntityType.all) {
        final label = DirectoryEntityTypeLabels.labelFor(type, isArabic: true);
        expect(find.text(label), findsWidgets, reason: type);
      }
    });

    testWidgets('16. valid input produces the exact canonical metadata keys',
        (tester) async {
      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);
      await pumpForm(tester, provider);

      await tester.enterText(find.byType(TextFormField), 'Test Office');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.businessEntityTypeCompany).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(gateway.createNewDraftCalls.length, 1);
      final metadata = gateway.createNewDraftCalls.single!;
      expect(metadata.containsKey(BusinessApplicationMetadata.name), isTrue);
      expect(metadata.containsKey(BusinessApplicationMetadata.entityType), isTrue);
      expect(metadata[BusinessApplicationMetadata.name], 'Test Office');
      expect(
        metadata[BusinessApplicationMetadata.entityType],
        DirectoryEntityType.company,
      );
    });

    test('17. draft creation never auto-submits', () async {
      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);

      final result = await provider.createNewDraft(metadata: {
        BusinessApplicationMetadata.name: 'Test',
        BusinessApplicationMetadata.entityType: 'company',
      });

      expect(result, isA<BusinessApplicationCreated>());
      expect((result as BusinessApplicationCreated).application.status,
          BusinessApplicationStatus.draft);
      expect(gateway.submitCalls, 0);
      expect(gateway.resubmitCalls, 0);
    });
  });

  // =========================================================================
  // E. CLAIM form boundary
  // =========================================================================
  group('E. CLAIM form state', () {
    test('18. createClaimDraft receives the canonical directory target id',
        () async {
      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);

      const targetId = '30000000-0000-0000-0000-000000000001';
      final result = await provider.createClaimDraft(targetEntityId: targetId);

      expect(result, isA<BusinessApplicationCreated>());
      expect(gateway.createClaimDraftCalls, [targetId]);
      expect((result as BusinessApplicationCreated).application.targetEntityId,
          targetId);
    });

    testWidgets('19. real CLAIM screen forwards exactly the selected canonical'
        ' target id through the widget interaction', (tester) async {
      const targetA = BusinessClaimTarget(
        id: '30000000-0000-0000-0000-0000000000a1',
        name: 'Alpha Engineering',
        entityType: 'company',
        claimStatus: 'unclaimed',
      );
      const targetB = BusinessClaimTarget(
        id: '30000000-0000-0000-0000-0000000000b2',
        name: 'Beta Supplies',
        entityType: 'store',
        claimStatus: 'unclaimed',
      );

      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);
      final claimProvider = BusinessClaimTargetProvider(
        gateway: _FakeClaimTargetGateway(
          targetsResult: const [targetA, targetB],
        ),
      );

      await tester.pumpWidget(
        _wrapClaimForm(
          provider,
          claimProvider,
          const ApplicationClaimFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. The real selector renders every claimable target with canonical ids.
      expect(find.text('Alpha Engineering'), findsOneWidget);
      expect(find.text('Beta Supplies'), findsOneWidget);

      // 2. Select ONE target through the widget.
      await tester.tap(find.text('Alpha Engineering'));
      await tester.pumpAndSettle();

      // 3. The claim confirmation dialog surfaces the selected target.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Alpha Engineering'),
        ),
        findsOneWidget,
      );

      // 3. Confirm exactly that target's claim action.
      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.businessClaimTarget),
      );
      await tester.pumpAndSettle();

      // 4-5. Exactly one createClaimDraft call carrying the SELECTED canonical
      // directory id — not the other target, not any local profile id.
      expect(gateway.createClaimDraftCalls, hasLength(1));
      expect(gateway.createClaimDraftCalls.single, targetA.id);
      expect(gateway.createClaimDraftCalls.single, isNot(targetB.id));
      expect(gateway.createClaimDraftCalls.single, isNot(_userId));
    });

    test('20. typed creation denials map to Arabic-first messages', () {
      const cases = <BusinessApplicationRejectionCause, String>{
        BusinessApplicationRejectionCause.guestUser: Ar.businessCauseGuestUser,
        BusinessApplicationRejectionCause.missingTarget:
            Ar.businessCauseMissingTarget,
        BusinessApplicationRejectionCause.invalidMetadata:
            Ar.businessCauseInvalidMetadata,
        BusinessApplicationRejectionCause.targetNotFound:
            Ar.businessCauseTargetNotFound,
        BusinessApplicationRejectionCause.targetNotClaimable:
            Ar.businessCauseTargetNotClaimable,
        BusinessApplicationRejectionCause.alreadyOwner:
            Ar.businessCauseAlreadyOwner,
        BusinessApplicationRejectionCause.duplicateClaim:
            Ar.businessCauseDuplicateClaim,
        BusinessApplicationRejectionCause.applicantMismatch:
            Ar.businessCauseApplicantMismatch,
      };
      cases.forEach((cause, expected) {
        expect(
          BusinessApplicationCauseMessages.messageFor(cause),
          equals(expected),
          reason: cause.name,
        );
      });
    });
  });

  // =========================================================================
  // F. Provider list/detail semantics
  // =========================================================================
  group('F. BusinessApplicationProvider list/detail', () {
    test('21. list maps to signInRequired when no authenticated session',
        () async {
      final gateway = _FakeAppGateway();
      final auth = AuthProvider(); // guest
      final provider = BusinessApplicationProvider(
        gateway: gateway,
        auth: auth,
      );

      await provider.loadApplications();
      expect(provider.state, BusinessApplicationState.signInRequired);
      expect(provider.applications, isEmpty);
    });

    test('22. empty own list maps to empty state', () async {
      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);

      await provider.loadApplications();
      expect(provider.state, BusinessApplicationState.empty);
      expect(gateway.listOwnCalls, [_userId]);
    });

    test('23. non-empty list maps to data state', () async {
      final gateway = _FakeAppGateway(listOwnResult: [_app(id: 'a1')]);
      final provider = await _makeProvider(gateway);

      await provider.loadApplications();
      expect(provider.state, BusinessApplicationState.data);
      expect(provider.applications.length, 1);
    });

    test('24. own application detail is returned with data state', () async {
      final gateway = _FakeAppGateway(getOwnResult: _app(id: 'a1'));
      final provider = await _makeProvider(gateway);

      await provider.loadApplication('a1');
      expect(provider.state, BusinessApplicationState.data);
      expect(provider.current?.id, 'a1');
    });

    test('24b. unowned/absent application maps to empty, not data', () async {
      final gateway = _FakeAppGateway(getOwnResult: null);
      final provider = await _makeProvider(gateway);

      await provider.loadApplication('foreign-id');
      expect(provider.state, BusinessApplicationState.empty);
      expect(provider.current, isNull);
    });

    test('25. refresh reloads authoritatively', () async {
      final gateway = _FakeAppGateway(listOwnResult: [_app(id: 'a1')]);
      final provider = await _makeProvider(gateway);

      await provider.loadApplications();
      expect(provider.applications.length, 1);

      gateway.listOwnResult = [_app(id: 'a1'), _app(id: 'a2')];
      await provider.loadApplications();
      expect(provider.applications.length, 2);
      expect(provider.applications.map((a) => a.id),
          containsAll(['a1', 'a2']));
    });
  });

  // =========================================================================
  // G. Submit / resubmit semantics
  // =========================================================================
  group('G. Submit/resubmit semantics', () {
    test('26. submit calls the gateway only from DRAFT status', () async {
      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);

      final draft = _app(status: BusinessApplicationStatus.draft);
      final result = await provider.submit(draft);
      expect(result, isA<BusinessApplicationSubmitted>());
      expect(gateway.submitCalls, 1);

      final submitted = _app(status: BusinessApplicationStatus.submitted);
      final blocked = await provider.submit(submitted);
      expect(blocked, isNull);
      expect(gateway.submitCalls, 1); // no second call
    });

    test('27. resubmit calls the gateway only from NEEDS_CORRECTION',
        () async {
      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);

      final needsCorrection = _app(
        status: BusinessApplicationStatus.needsCorrection,
      );
      final result = await provider.resubmit(needsCorrection);
      expect(result, isA<BusinessApplicationSubmitted>());
      expect(gateway.resubmitCalls, 1);

      final draft = _app(status: BusinessApplicationStatus.draft);
      final blocked = await provider.resubmit(draft);
      expect(blocked, isNull);
      expect(gateway.resubmitCalls, 1);
    });

    test('28. no double-submit while a submission is in flight', () async {
      final completer = Completer<BusinessApplicationSubmitResult>();
      final gateway = _FakeAppGateway(
        onSubmitApplication: (_) => completer.future,
      );
      final provider = await _makeProvider(gateway);

      final draft = _app(status: BusinessApplicationStatus.draft);
      final future1 = provider.submit(draft);
      final future2 = provider.submit(draft); // in-flight → no new call
      final secondResult = await future2;

      expect(secondResult, isNull);
      expect(gateway.submitCalls, 1);

      completer.complete(BusinessApplicationSubmitted(draft));
      final result = await future1;
      expect(result, isA<BusinessApplicationSubmitted>());
    });

    test('29. after success the held application is replaced by the'
        ' authoritative result', () async {
      final original = _app(status: BusinessApplicationStatus.draft);
      final authoritative = _app(
        id: original.id,
        status: BusinessApplicationStatus.submitted,
      );
      final gateway = _FakeAppGateway(
        onSubmitApplication: (_) async =>
            BusinessApplicationSubmitted(authoritative),
      )..listOwnResult = [original];
      final provider = await _makeProvider(gateway);

      await provider.loadApplications();
      expect(provider.applications.first.status, BusinessApplicationStatus.draft);

      await provider.submit(original);
      expect(
        provider.applications.first.status,
        BusinessApplicationStatus.submitted,
      );
    });

    test('30. typed submit denials map to Arabic messages without raw errors',
        () {
      const cases = <BusinessApplicationSubmitCause, String>{
        BusinessApplicationSubmitCause.unauthenticated:
            Ar.businessCauseUnauthenticated,
        BusinessApplicationSubmitCause.notApplicant:
            Ar.businessCauseNotApplicant,
        BusinessApplicationSubmitCause.applicationNotFound:
            Ar.businessCauseApplicationNotFound,
        BusinessApplicationSubmitCause.invalidTransition:
            Ar.businessCauseInvalidTransition,
        BusinessApplicationSubmitCause.phoneRequired:
            Ar.businessCausePhoneRequired,
        BusinessApplicationSubmitCause.requiredDataMissing:
            Ar.businessCauseRequiredDataMissing,
        BusinessApplicationSubmitCause.targetNotClaimable:
            Ar.businessCauseTargetNotClaimable,
        BusinessApplicationSubmitCause.unexpected: Ar.businessCauseUnexpected,
      };
      cases.forEach((cause, expected) {
        final msg = BusinessApplicationCauseMessages.messageForSubmit(cause);
        expect(msg, equals(expected), reason: cause.name);
        expect(msg.contains('SQLSTATE'), isFalse);
        expect(msg.contains('42'), isFalse);
      });
    });
  });

  // =========================================================================
  // H. Guest / offline / error + full-screen states
  // =========================================================================
  group('H. Guest/offline/error', () {
    testWidgets('31. guest sees sign-in-required UI, never a misleading empty'
        ' state', (tester) async {
      final gateway = _FakeAppGateway();
      final auth = AuthProvider(); // guest
      final provider = BusinessApplicationProvider(
        gateway: gateway,
        auth: auth,
      );

      await tester.pumpWidget(
        _wrapWithProviders(provider, const MyApplicationsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.businessSignInRequired), findsOneWidget);
      expect(find.text(Ar.businessNoApplications), findsNothing);
      expect(provider.state, BusinessApplicationState.signInRequired);
    });

    testWidgets('31b. empty list shows the honest empty state and exposes NEW '
        'and CLAIM creation actions', (tester) async {
      final gateway = _FakeAppGateway();
      final provider = await _makeProvider(gateway);

      await tester.pumpWidget(
        _wrapWithProviders(provider, const MyApplicationsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.businessNoApplications), findsOneWidget);
      expect(provider.state, BusinessApplicationState.empty);
      expect(find.text(Ar.businessNewApplication), findsOneWidget);
      expect(find.text(Ar.businessTypeClaim), findsOneWidget);
    });

    testWidgets('31c. data list renders application card with status chip',
        (tester) async {
      final gateway = _FakeAppGateway(
        listOwnResult: [
          _app(
            id: 'app-1',
            status: BusinessApplicationStatus.submitted,
            metadata: {
              BusinessApplicationMetadata.name: 'Test Office',
              BusinessApplicationMetadata.entityType: 'company',
            },
          ),
        ],
      );
      final provider = await _makeProvider(gateway);

      await tester.pumpWidget(
        _wrapWithProviders(provider, const MyApplicationsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Office'), findsOneWidget);
      expect(find.text(Ar.businessStatusSubmitted), findsOneWidget);
      expect(find.byType(BusinessApplicationStatusChip), findsOneWidget);
    });

    test('32. load failure surfaces an error state and retry recovers',
        () async {
      final gateway = _FakeAppGateway()..listOwnError = Exception('offline');
      final provider = await _makeProvider(gateway);

      await provider.loadApplications();
      expect(provider.state, BusinessApplicationState.error);
      expect(provider.applications, isEmpty);

      // Retry with the backend back: clears the failure.
      gateway.listOwnError = null;
      gateway.listOwnResult = [_app(id: 'a1')];
      await provider.loadApplications();
      expect(provider.state, BusinessApplicationState.data);
      expect(provider.applications.length, 1);
    });
  });

  // =========================================================================
  // Bonus: capability hints for the nine canonical statuses
  // =========================================================================
  group('Capabilities', () {
    test('DRAFT and NEEDS_CORRECTION may edit/submit; resubmit is'
        ' NEEDS_CORRECTION only', () {
      final draftCaps = BusinessApplicationCapabilityResolver.forStatus(
        BusinessApplicationStatus.draft,
      );
      expect(draftCaps.canEdit, isTrue);
      expect(draftCaps.canSubmit, isTrue);
      expect(draftCaps.canResubmit, isFalse);

      final needsCorrection = BusinessApplicationCapabilityResolver.forStatus(
        BusinessApplicationStatus.needsCorrection,
      );
      expect(needsCorrection.canEdit, isTrue);
      expect(needsCorrection.canSubmit, isTrue);
      expect(needsCorrection.canResubmit, isTrue);

      for (final status in BusinessApplicationStatus.values) {
        if (status == BusinessApplicationStatus.draft ||
            status == BusinessApplicationStatus.needsCorrection) {
          continue;
        }
        final caps = BusinessApplicationCapabilityResolver.forStatus(status);
        expect(caps.canSubmit, isFalse, reason: '${status.name}.canSubmit');
        expect(caps.canResubmit, isFalse, reason: '${status.name}.canResubmit');
      }
    });

    test('unknown status fails closed to zero capabilities', () {
      final caps = BusinessApplicationCapabilityResolver.forStatus(
        BusinessApplicationStatus.unknown,
      );
      expect(caps.isUnknown, isTrue);
      expect(caps.canEdit, isFalse);
      expect(caps.canSubmit, isFalse);
      expect(caps.canResubmit, isFalse);
    });
  });

  // =========================================================================
  // I. Guest route guards + claim selector UX (production paths)
  // =========================================================================
  group('I. Guest guards + claim selector', () {
    testWidgets('33. NEW route as guest shows sign-in-required, never a form',
        (tester) async {
      final gateway = _FakeAppGateway();
      final auth = AuthProvider();
      final provider = BusinessApplicationProvider(
        gateway: gateway,
        auth: auth,
      );

      await tester.pumpWidget(
        _wrapWithProviders(provider, const ApplicationNewFormScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.businessSignInRequired), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(gateway.createNewDraftCalls, isEmpty);
    });

    testWidgets('34. CLAIM route as guest shows sign-in-required and never '
        'queries the claim seam', (tester) async {
      final appGateway = _FakeAppGateway();
      final auth = AuthProvider();
      final appProvider = BusinessApplicationProvider(
        gateway: appGateway,
        auth: auth,
      );
      final targetGateway = _FakeClaimTargetGateway();
      final claimProvider =
          BusinessClaimTargetProvider(gateway: targetGateway);

      await tester.pumpWidget(
        _wrapClaimForm(
          appProvider,
          claimProvider,
          const ApplicationClaimFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.businessSignInRequired), findsOneWidget);
      expect(find.text(Ar.businessClaimTargetsEmpty), findsNothing);
      expect(targetGateway.listCalls, 0,
          reason: 'guest must never trigger the unclaimed-target read');
    });

    testWidgets('35. claim selector renders localized entity type and '
        'verification labels, never raw storage values', (tester) async {
      const targetId = '30000000-0000-0000-0000-000000000001';
      final appGateway = _FakeAppGateway();
      final appProvider = await _makeProvider(appGateway);
      final targetGateway = _FakeClaimTargetGateway(
        targetsResult: const [
          BusinessClaimTarget(
            id: targetId,
            name: 'Alpha',
            entityType: 'company',
            claimStatus: 'unclaimed',
            verificationStatus: 'verified',
          ),
        ],
      );
      final claimProvider =
          BusinessClaimTargetProvider(gateway: targetGateway);

      await tester.pumpWidget(
        _wrapClaimForm(
          appProvider,
          claimProvider,
          const ApplicationClaimFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text(Ar.businessEntityTypeCompany), findsOneWidget);
      expect(find.textContaining(Ar.verificationVerified), findsOneWidget);
      expect(find.text('company'), findsNothing,
          reason: 'raw storage entity_type must never leak to the UI');
      expect(find.text('verified'), findsNothing,
          reason: 'raw storage verification_status must never leak');
      expect(find.text(targetId), findsNothing,
          reason: 'canonical UUID must never be rendered for applicants');
    });

    testWidgets('36. claim empty state offers refresh and recovers via a '
        'fresh authoritative read', (tester) async {
      const targetId = '30000000-0000-0000-0000-000000000002';
      final appGateway = _FakeAppGateway();
      final appProvider = await _makeProvider(appGateway);
      final targetGateway = _FakeClaimTargetGateway();
      final claimProvider =
          BusinessClaimTargetProvider(gateway: targetGateway);

      await tester.pumpWidget(
        _wrapClaimForm(
          appProvider,
          claimProvider,
          const ApplicationClaimFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.businessClaimTargetsEmpty), findsOneWidget);
      expect(find.text(Ar.businessRefresh), findsOneWidget);

      targetGateway.targetsResult = const [
        BusinessClaimTarget(
          id: targetId,
          name: 'Beta',
          entityType: 'store',
          claimStatus: 'unclaimed',
        ),
      ];
      await tester.tap(find.text(Ar.businessRefresh));
      await tester.pumpAndSettle();

      expect(find.text('Beta'), findsOneWidget);
      expect(find.text(Ar.businessClaimTargetsEmpty), findsNothing);
      expect(targetGateway.listCalls, greaterThanOrEqualTo(2));
    });

    testWidgets('37. malformed metadata never crashes the list card',
        (tester) async {
      final gateway = _FakeAppGateway(
        listOwnResult: [
          _app(
            id: 'app-bad',
            status: BusinessApplicationStatus.submitted,
            metadata: <String, dynamic>{
              'name': 42,
              'entity_type': <String>['nope'],
              'junk': null,
            },
          ),
        ],
      );
      final provider = await _makeProvider(gateway);

      await tester.pumpWidget(
        _wrapWithProviders(provider, const MyApplicationsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.businessTypeNew), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // J. Application detail production semantics (timestamps, reasons, states)
  // =========================================================================
  group('J. Application detail semantics', () {
    Future<void> pumpDetail(
      WidgetTester tester,
      BusinessApplicationProvider provider,
      String applicationId,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          provider,
          ApplicationDetailScreen(applicationId: applicationId),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('38. detail renders authoritative timestamps',
        (tester) async {
      final gateway = _FakeAppGateway(
        getOwnResult: BusinessApplication(
          id: 'a1',
          applicantUserId: _userId,
          type: BusinessApplicationType.newApplication,
          status: BusinessApplicationStatus.approved,
          metadata: {
            BusinessApplicationMetadata.name: 'Test Office',
            BusinessApplicationMetadata.entityType: 'company',
          },
          reviewedAt: DateTime(2026, 1, 3),
          approvedAt: DateTime(2026, 1, 4),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        ),
      );
      final provider = await _makeProvider(gateway);

      await pumpDetail(tester, provider, 'a1');

      expect(find.text(Ar.businessReviewedAt), findsOneWidget);
      expect(find.text(Ar.businessApprovedAt), findsOneWidget);
      expect(find.text('2026-01-01'), findsOneWidget);
      expect(find.text('2026-01-02'), findsOneWidget);
      expect(find.text('2026-01-03'), findsOneWidget);
      expect(find.text('2026-01-04'), findsOneWidget);
      expect(find.text(Ar.businessApprovedNote), findsOneWidget);
      expect(find.text(Ar.businessActivatedNote), findsNothing);
      expect(find.text(Ar.businessActivatedAt), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('39. REJECTED detail shows the authoritative rejection reason',
        (tester) async {
      final gateway = _FakeAppGateway(
        getOwnResult: BusinessApplication(
          id: 'a1',
          applicantUserId: _userId,
          type: BusinessApplicationType.newApplication,
          status: BusinessApplicationStatus.rejected,
          rejectionReason: 'مستندات غير مكتملة',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      final provider = await _makeProvider(gateway);

      await pumpDetail(tester, provider, 'a1');

      expect(find.text(Ar.businessRejectionReason), findsOneWidget);
      expect(find.text('مستندات غير مكتملة'), findsOneWidget);
      expect(find.text(Ar.businessStatusRejected), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('40. NEEDS_CORRECTION detail shows return reason and resubmit',
        (tester) async {
      final gateway = _FakeAppGateway(
        getOwnResult: BusinessApplication(
          id: 'a1',
          applicantUserId: _userId,
          type: BusinessApplicationType.newApplication,
          status: BusinessApplicationStatus.needsCorrection,
          returnReason: 'نقص في رقم الهاتف',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      final provider = await _makeProvider(gateway);

      await pumpDetail(tester, provider, 'a1');

      expect(find.text(Ar.businessReturnReasonTitle), findsOneWidget);
      expect(find.text('نقص في رقم الهاتف'), findsOneWidget);
      expect(find.text(Ar.businessResubmit), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('41. ACTIVATED detail shows activation semantics',
        (tester) async {
      final gateway = _FakeAppGateway(
        getOwnResult: BusinessApplication(
          id: 'a1',
          applicantUserId: _userId,
          type: BusinessApplicationType.newApplication,
          status: BusinessApplicationStatus.activated,
          activatedAt: DateTime(2026, 1, 5),
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      final provider = await _makeProvider(gateway);

      await pumpDetail(tester, provider, 'a1');

      expect(find.text(Ar.businessActivatedAt), findsOneWidget);
      expect(find.text('2026-01-05'), findsOneWidget);
      expect(find.text(Ar.businessActivatedNote), findsOneWidget);
      expect(find.text(Ar.businessApprovedNote), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('42. CLAIM detail never exposes the raw target UUID',
        (tester) async {
      const targetId = '30000000-0000-0000-0000-000000000009';
      final gateway = _FakeAppGateway(
        getOwnResult: BusinessApplication(
          id: 'a1',
          applicantUserId: _userId,
          type: BusinessApplicationType.claim,
          status: BusinessApplicationStatus.submitted,
          targetEntityId: targetId,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      final provider = await _makeProvider(gateway);

      await pumpDetail(tester, provider, 'a1');

      expect(find.text(targetId), findsNothing);
      expect(find.text(Ar.businessTypeClaim), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('43. malformed metadata never crashes the detail screen',
        (tester) async {
      final gateway = _FakeAppGateway(
        getOwnResult: BusinessApplication(
          id: 'a1',
          applicantUserId: _userId,
          type: BusinessApplicationType.newApplication,
          status: BusinessApplicationStatus.draft,
          metadata: <String, dynamic>{
            'name': const <String>['bad'],
            'entity_type': 7,
          },
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      final provider = await _makeProvider(gateway);

      await pumpDetail(tester, provider, 'a1');

      expect(find.text(Ar.businessTypeNew), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // K. Production-path guards (localized labels + session-gated claim read)
  // =========================================================================
  group('K. Production-path guards', () {
    test('44. claim verification labels localize every canonical storage '
        'value and fail-safe on unknown', () {
      const cases = <String, String>{
        'unverified': Ar.verificationUnverified,
        'pending': Ar.verificationPending,
        'verified': Ar.verificationVerified,
        'rejected': Ar.verificationRejected,
        'suspended': Ar.verificationSuspended,
      };
      cases.forEach((code, expected) {
        expect(
          BusinessClaimVerificationLabels.labelFor(code),
          equals(expected),
          reason: code,
        );
      });
      expect(
        BusinessClaimVerificationLabels.labelFor(null),
        Ar.directoryNotSpecified,
      );
      expect(
        BusinessClaimVerificationLabels.labelFor('bogus'),
        Ar.directoryNotSpecified,
      );
    });

    test('45. claim-target gateway never queries without an authenticated '
        'session', () async {
      final service = SupabaseService(
        config: const BackendConfig(
          appEnvRaw: 'development',
          supabaseUrl: 'https://project.supabase.co',
          supabaseAnonKey: 'anon-key',
        ),
      );
      await service.init(
        initialize: ({required url, required publishableKey}) async {},
      );
      final client = SupabaseClient(
        'https://project.supabase.co',
        'anon-key',
      );
      final gateway = SupabaseBusinessClaimTargetGateway(
        service: service,
        client: client,
      );

      final result = await gateway.listUnclaimedTargets();

      expect(result, isEmpty,
          reason: 'no authenticated session → typed safely-empty result, '
              'never an anonymous directory_entities SELECT');
    });
  });
}