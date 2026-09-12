import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/di/staff_operations_scope.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_staff_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:civilpedia/features/business/domain/staff_application_capabilities.dart';
import 'package:civilpedia/features/business/domain/staff_application_detail.dart';
import 'package:civilpedia/features/business/domain/staff_application_summary.dart';
import 'package:civilpedia/features/business/domain/staff_read_result.dart';
import 'package:civilpedia/features/business/presentation/providers/staff_access_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/staff_application_detail_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/staff_application_queue_provider.dart';
import 'package:civilpedia/features/business/presentation/screens/staff_application_queue_screen.dart';
import 'package:civilpedia/features/business/presentation/screens/staff_application_review_screen.dart';
import 'package:civilpedia/features/user_area/presentation/user_area_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:civilpedia/routes/app_routes.dart';

const _staffUserId = 'staff-user-1';

/// Valid-UUID route id (the detail route fails safe on non-UUID segments).
const _appId = '00000000-0000-0000-0000-000000000001';

final _staffCapabilities = StaffApplicationCapabilities.tryFromJson(const {
  'permissions': [
    'business_applications.read',
    'business_applications.review',
    'business_applications.return_for_correction',
    'business_applications.mark_contacted',
    'business_applications.schedule_visit',
    'business_applications.approve',
    'business_applications.reject',
    'business_applications.activate',
  ],
})!;

final _readOnlyCapabilities = StaffApplicationCapabilities.tryFromJson(const {
  'permissions': ['business_applications.read'],
})!;

void main() {
  group('StaffAccessProvider', () {
    test('sign-in required when user is guest', () async {
      final auth = _guestAuth();
      final gateway = _FakeStaffGateway();
      final provider = StaffAccessProvider(gateway: gateway, auth: auth);

      await provider.load();

      expect(provider.state, StaffAccessState.signInRequired);
      expect(provider.isAuthorized, isFalse);
    });

    test(
      'authorized when signed-in and server returns read permission',
      () async {
        final auth = _authenticatedAuth();
        final gateway = _FakeStaffGateway(capabilities: _staffCapabilities);
        final provider = StaffAccessProvider(gateway: gateway, auth: auth);

        await provider.load();

        expect(provider.state, StaffAccessState.authorized);
        expect(provider.isAuthorized, isTrue);
        expect(provider.capabilities?.canRead, isTrue);
        expect(provider.capabilities?.canApprove, isTrue);
      },
    );

    test(
      'no read permission when server returns read-only set without read',
      () async {
        final auth = _authenticatedAuth();
        final gateway = _FakeStaffGateway(
          capabilities: const StaffApplicationCapabilities.empty(),
        );
        final provider = StaffAccessProvider(gateway: gateway, auth: auth);

        await provider.load();

        expect(provider.state, StaffAccessState.noReadPermission);
        expect(provider.isAuthorized, isFalse);
      },
    );

    test('no read permission when server denies', () async {
      final auth = _authenticatedAuth();
      final gateway = _FakeStaffGateway(
        capabilitiesResult: const StaffReadDenied(
          BusinessApplicationStaffCause.staffPermissionDenied,
        ),
      );
      final provider = StaffAccessProvider(gateway: gateway, auth: auth);

      await provider.load();

      expect(provider.state, StaffAccessState.noReadPermission);
      expect(
        provider.lastErrorCause,
        BusinessApplicationStaffCause.staffPermissionDenied,
      );
    });

    test('error when backend unavailable', () async {
      final auth = _authenticatedAuth();
      final gateway = _FakeStaffGateway(available: false);
      final provider = StaffAccessProvider(gateway: gateway, auth: auth);

      await provider.load();

      expect(provider.state, StaffAccessState.error);
      expect(provider.lastErrorCause, BusinessApplicationStaffCause.unexpected);
    });

    test('reset clears state', () async {
      final auth = _authenticatedAuth();
      final gateway = _FakeStaffGateway(capabilities: _staffCapabilities);
      final provider = StaffAccessProvider(gateway: gateway, auth: auth);
      await provider.load();
      provider.reset();
      expect(provider.state, StaffAccessState.initial);
      expect(provider.capabilities, isNull);
    });
  });

  group('StaffApplicationQueueProvider', () {
    test('initial state has empty items and no more pages', () {
      final provider = StaffApplicationQueueProvider(
        gateway: _FakeStaffGateway(),
      );
      expect(provider.state, StaffQueueState.initial);
      expect(provider.items, isEmpty);
      expect(provider.hasMore, isFalse);
    });

    test('loadInitial populates items from page', () async {
      final summary = _sampleSummary('app-1');
      final gateway = _FakeStaffGateway(
        page: StaffApplicationPage(
          items: [summary],
          nextCursor: StaffApplicationCursor(
            createdAt: summary.createdAt,
            id: summary.id,
          ),
        ),
      );
      final provider = StaffApplicationQueueProvider(gateway: gateway);

      await provider.loadInitial();

      expect(provider.state, StaffQueueState.data);
      expect(provider.items.length, 1);
      expect(provider.hasMore, isTrue);
    });

    test('loadInitial empty transitions to empty state', () async {
      final gateway = _FakeStaffGateway(
        page: const StaffApplicationPage(items: []),
      );
      final provider = StaffApplicationQueueProvider(gateway: gateway);

      await provider.loadInitial();

      expect(provider.state, StaffQueueState.empty);
    });

    test('access denied maps P0PER', () async {
      final gateway = _FakeStaffGateway(
        pageResult: const StaffReadDenied(
          BusinessApplicationStaffCause.staffPermissionDenied,
        ),
      );
      final provider = StaffApplicationQueueProvider(gateway: gateway);

      await provider.loadInitial();

      expect(provider.state, StaffQueueState.accessDenied);
    });

    test('sign-in required maps P0AUT', () async {
      final gateway = _FakeStaffGateway(
        pageResult: const StaffReadDenied(
          BusinessApplicationStaffCause.unauthenticated,
        ),
      );
      final provider = StaffApplicationQueueProvider(gateway: gateway);

      await provider.loadInitial();

      expect(provider.state, StaffQueueState.signInRequired);
    });

    test('loadMore appends distinct items', () async {
      final item1 = _sampleSummary('app-1');
      final item2 = _sampleSummary('app-2');
      final gateway = _FakeStaffGateway(
        pages: [
          StaffApplicationPage(
            items: [item1],
            nextCursor: StaffApplicationCursor(
              createdAt: item1.createdAt,
              id: item1.id,
            ),
          ),
          StaffApplicationPage(
            items: [item2],
            nextCursor: StaffApplicationCursor(
              createdAt: item2.createdAt,
              id: item2.id,
            ),
          ),
        ],
      );
      final provider = StaffApplicationQueueProvider(gateway: gateway);

      await provider.loadInitial();
      await provider.loadMore();

      expect(provider.items.length, 2);
      expect(provider.items.map((i) => i.id), ['app-1', 'app-2']);
    });

    test('setFilter reloads with new filter', () async {
      final gateway = _FakeStaffGateway();
      final provider = StaffApplicationQueueProvider(gateway: gateway);

      await provider.setFilter(
        const StaffApplicationQueueFilter(
          status: BusinessApplicationStatus.submitted,
        ),
      );

      expect(provider.state, StaffQueueState.empty);
      expect(provider.filter.status, BusinessApplicationStatus.submitted);
    });
  });

  group('StaffApplicationDetailProvider', () {
    test('load populates detail', () async {
      final detail = _sampleDetail(
        'app-1',
        BusinessApplicationStatus.submitted,
      );
      final gateway = _FakeStaffGateway(detail: detail);
      final provider = StaffApplicationDetailProvider(gateway: gateway);

      await provider.load('app-1');

      expect(provider.state, StaffDetailState.data);
      expect(provider.detail?.id, 'app-1');
    });

    test('not found maps P0NOT', () async {
      final gateway = _FakeStaffGateway(
        detailResult: const StaffReadDenied(
          BusinessApplicationStaffCause.applicationNotFound,
        ),
      );
      final provider = StaffApplicationDetailProvider(gateway: gateway);

      await provider.load('missing');

      expect(provider.state, StaffDetailState.notFound);
    });

    test(
      'beginReview available only for SUBMITTED with review permission',
      () async {
        final detail = _sampleDetail(
          'app-1',
          BusinessApplicationStatus.submitted,
        );
        final gateway = _FakeStaffGateway(detail: detail);
        final provider = StaffApplicationDetailProvider(gateway: gateway);
        await provider.load('app-1');

        expect(
          provider.isActionAvailable(
            StaffAction.beginReview,
            _staffCapabilities,
          ),
          isTrue,
        );
        expect(
          provider.isActionAvailable(
            StaffAction.beginReview,
            _readOnlyCapabilities,
          ),
          isFalse,
        );
        expect(
          provider.isActionAvailable(
            StaffAction.beginReview,
            StaffApplicationCapabilities.tryFromJson(const {
              'permissions': ['business_applications.review'],
            })!,
          ),
          isTrue,
        );
      },
    );

    test('successful mutation re-reads detail and returns data', () async {
      final detail = _sampleDetail(
        'app-1',
        BusinessApplicationStatus.submitted,
      );
      final reviewed = detail.copyWithStatus(
        BusinessApplicationStatus.underReview,
      );
      final gateway = _FakeStaffGateway(
        detail: detail,
        mutationResult: BusinessApplicationStaffSucceeded(
          _businessAppFromDetail(reviewed),
        ),
        postMutationDetail: reviewed,
      );
      final provider = StaffApplicationDetailProvider(gateway: gateway);
      await provider.load('app-1');

      final ok = await provider.beginReview();

      expect(ok, isTrue);
      expect(provider.state, StaffDetailState.data);
      expect(provider.detail?.status, BusinessApplicationStatus.underReview);
    });

    test('mutation denied surfaces cause without changing state', () async {
      final detail = _sampleDetail(
        'app-1',
        BusinessApplicationStatus.submitted,
      );
      final gateway = _FakeStaffGateway(
        detail: detail,
        mutationResult: const BusinessApplicationStaffDenied(
          BusinessApplicationStaffCause.staffPermissionDenied,
        ),
      );
      final provider = StaffApplicationDetailProvider(gateway: gateway);
      await provider.load('app-1');

      final ok = await provider.beginReview();

      expect(ok, isFalse);
      expect(provider.state, StaffDetailState.accessDenied);
      expect(
        provider.lastErrorCause,
        BusinessApplicationStaffCause.staffPermissionDenied,
      );
    });

    test('post-mutation detail failure surfaces refresh warning', () async {
      final detail = _sampleDetail(
        'app-1',
        BusinessApplicationStatus.submitted,
      );
      final gateway = _FakeStaffGateway(
        detail: detail,
        mutationResult: BusinessApplicationStaffSucceeded(
          _businessAppFromDetail(detail),
        ),
        postMutationDetailResult: const StaffReadUnavailable(),
      );
      final provider = StaffApplicationDetailProvider(gateway: gateway);
      await provider.load('app-1');

      final ok = await provider.approve();

      expect(ok, isFalse);
      expect(provider.state, StaffDetailState.refreshAfterMutationError);
      expect(gateway.mutationActions, ['approve']);
      expect(gateway.detailCalls, 2);
    });

    test(
      'refreshDetail performs real reread after failed post-mutation refresh',
      () async {
        final detail = _sampleDetail(
          'app-1',
          BusinessApplicationStatus.approved,
        );
        final gateway = _FakeStaffGateway(
          detail: detail,
          mutationResult: BusinessApplicationStaffSucceeded(
            _businessAppFromDetail(detail),
          ),
          postMutationDetailResult: const StaffReadUnavailable(),
        );
        final provider = StaffApplicationDetailProvider(gateway: gateway);
        await provider.load('app-1');
        await provider.approve();
        expect(provider.state, StaffDetailState.refreshAfterMutationError);
        final mutationCount = gateway.mutationActions.length;

        await provider.refreshDetail();

        expect(provider.state, StaffDetailState.data);
        expect(provider.detail, isNotNull);
        expect(gateway.mutationActions.length, mutationCount);
        expect(gateway.detailCalls, 3);
      },
    );

    test('generic mutation failure preserves authoritative detail', () async {
      final detail = _sampleDetail(
        _appId,
        BusinessApplicationStatus.underReview,
      );
      final gateway = _FakeStaffGateway(
        detail: detail,
        mutationResult: const BusinessApplicationStaffDenied(
          BusinessApplicationStaffCause.unexpected,
        ),
      );
      final provider = StaffApplicationDetailProvider(gateway: gateway);
      await provider.load(_appId);

      final ok = await provider.approve();

      expect(ok, isFalse);
      expect(provider.state, StaffDetailState.mutationError);
      expect(identical(provider.detail, detail), isTrue);
      expect(gateway.mutationActions, ['approve']);
    });
  });

  group('StaffApplicationQueueScreen', () {
    testWidgets('renders queue items when authorized', (tester) async {
      await tester.pumpWidget(
        _testApp(
          staffGateway: _FakeStaffGateway(
            capabilities: _staffCapabilities,
            page: StaffApplicationPage(
              items: [_sampleSummary('app-1', name: 'Test Business')],
            ),
          ),
          child: const StaffApplicationQueueScreen(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(Ar.staffApplicationsTitle), findsOneWidget);
      expect(find.text('Test Business'), findsOneWidget);
    });

    testWidgets('renders access denied when no permission', (tester) async {
      await tester.pumpWidget(
        _testApp(
          staffGateway: _FakeStaffGateway(
            capabilities: const StaffApplicationCapabilities.empty(),
          ),
          child: const StaffApplicationQueueScreen(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(Ar.staffAccessDenied), findsOneWidget);
    });
  });

  group('StaffApplicationReviewScreen', () {
    testWidgets('renders detail and action buttons when authorized', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          staffGateway: _FakeStaffGateway(
            capabilities: _staffCapabilities,
            detail: _sampleDetail(
              _appId,
              BusinessApplicationStatus.underReview,
            ),
          ),
          child: const StaffApplicationReviewScreen(applicationId: _appId),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(Ar.staffApplicant), findsOneWidget);
      expect(find.text(Ar.staffActionReturnForCorrection), findsOneWidget);
      expect(find.text(Ar.staffActionApprove), findsOneWidget);
    });

    testWidgets('hides action buttons for read-only reviewer', (tester) async {
      await tester.pumpWidget(
        _testApp(
          staffGateway: _FakeStaffGateway(
            capabilities: _readOnlyCapabilities,
            detail: _sampleDetail(
              _appId,
              BusinessApplicationStatus.underReview,
            ),
          ),
          child: const StaffApplicationReviewScreen(applicationId: _appId),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(Ar.staffActionReturnForCorrection), findsNothing);
      expect(find.text(Ar.staffActionApprove), findsNothing);
    });
  });

  group('UserAreaScreen staff entry', () {
    testWidgets('shows staff operations when authorized', (tester) async {
      await tester.pumpWidget(
        _testApp(
          staffGateway: _FakeStaffGateway(capabilities: _staffCapabilities),
          child: const UserAreaScreen(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(Ar.staffOperations), findsOneWidget);
    });

    testWidgets('hides staff operations when not authorized', (tester) async {
      await tester.pumpWidget(
        _testApp(
          staffGateway: _FakeStaffGateway(
            capabilities: const StaffApplicationCapabilities.empty(),
          ),
          child: const UserAreaScreen(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(Ar.staffOperations), findsNothing);
    });
  });

  group('strict JSON parsing fails closed (findings 3–5)', () {
    test('capabilities: non-string permission fails the whole projection', () {
      expect(
        StaffApplicationCapabilities.tryFromJson(const {
          'permissions': ['business_applications.read', 42],
        }),
        isNull,
      );
    });

    test('capabilities: missing or non-list permissions fails closed', () {
      expect(StaffApplicationCapabilities.tryFromJson(const {}), isNull);
      expect(
        StaffApplicationCapabilities.tryFromJson(const {'permissions': 'read'}),
        isNull,
      );
    });

    test('capabilities: unknown well-formed codes are ignored', () {
      final caps = StaffApplicationCapabilities.tryFromJson(const {
        'permissions': ['business_applications.read', 'future.permission.xyz'],
      });
      expect(caps, isNotNull);
      expect(caps!.canRead, isTrue);
    });

    test('page: explicit null next_cursor is a valid final page', () {
      final now = DateTime(2024, 1, 1);
      final page = StaffApplicationPage.tryFromJson({
        'items': [
          {
            'id': 'app-1',
            'application_type': 'NEW',
            'status': 'SUBMITTED',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'new_business': {'name': 'B'},
          },
        ],
        'next_cursor': null,
      });
      expect(page, isNotNull);
      expect(page!.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('page: non-map next_cursor fails the whole page', () {
      final now = DateTime(2024, 1, 1);
      final page = StaffApplicationPage.tryFromJson({
        'items': [
          {
            'id': 'app-1',
            'application_type': 'NEW',
            'status': 'SUBMITTED',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'new_business': {'name': 'B'},
          },
        ],
        'next_cursor': 'oops',
      });
      expect(page, isNull);
    });

    test('page: malformed cursor map fails the whole page', () {
      final now = DateTime(2024, 1, 1);
      final page = StaffApplicationPage.tryFromJson({
        'items': [
          {
            'id': 'app-1',
            'application_type': 'NEW',
            'status': 'SUBMITTED',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'new_business': {'name': 'B'},
          },
        ],
        'next_cursor': {'created_at': '2024-01-01'},
      });
      expect(page, isNull);
    });

    test('page: malformed item fails the whole page', () {
      final page = StaffApplicationPage.tryFromJson({
        'items': [
          const {'id': 42},
        ],
        'next_cursor': null,
      });
      expect(page, isNull);
    });

    test('detail: malformed contact entry fails the whole detail', () {
      final now = DateTime(2024, 1, 1);
      final detail = StaffApplicationDetail.tryFromJson({
        'application': {
          'id': 'app-1',
          'application_type': 'NEW',
          'status': 'SUBMITTED',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        'applicant': {'display_name': 'Applicant'},
        'new_business': {'name': 'B'},
        'contacts': [
          const {'id': 'c1', 'contacted_by_user_id': 'u1'},
        ],
      });
      expect(detail, isNull);
    });

    test('detail: contacts not a list fails the whole detail', () {
      final now = DateTime(2024, 1, 1);
      final detail = StaffApplicationDetail.tryFromJson({
        'application': {
          'id': 'app-1',
          'application_type': 'NEW',
          'status': 'SUBMITTED',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        'applicant': {'display_name': 'Applicant'},
        'new_business': {'name': 'B'},
        'contacts': 'none',
      });
      expect(detail, isNull);
    });

    test('detail: malformed visit entry fails the whole detail', () {
      final now = DateTime(2024, 1, 1);
      final detail = StaffApplicationDetail.tryFromJson({
        'application': {
          'id': 'app-1',
          'application_type': 'NEW',
          'status': 'SUBMITTED',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        'applicant': {'display_name': 'Applicant'},
        'new_business': {'name': 'B'},
        'visits': [
          const {'location': 'Baghdad'},
          {
            'id': 'v2',
            'status': 'scheduled',
            'visited_at': now.toIso8601String(),
          },
        ],
      });
      expect(detail, isNull);
    });

    test('detail: absent contacts and visits are relaxed defaults', () {
      final now = DateTime(2024, 1, 1);
      final detail = StaffApplicationDetail.tryFromJson({
        'application': {
          'id': 'app-1',
          'application_type': 'NEW',
          'status': 'SUBMITTED',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        'applicant': {'display_name': 'Applicant'},
        'new_business': {'name': 'B'},
      });
      expect(detail, isNotNull);
      expect(detail!.contacts, isEmpty);
      expect(detail.visits, isEmpty);
    });

    for (final value in <Object?>[null, 'not-a-date']) {
      test('detail: contacted_at=$value fails the whole projection', () {
        final json = _validDetailProjection();
        json['contacts'] = [
          {
            'id': 'c1',
            'contacted_by_user_id': 'u1',
            'contact_type': 'phone',
            if (value != null) 'contacted_at': value,
          },
        ];
        expect(StaffApplicationDetail.tryFromJson(json), isNull);
      });

      test('detail: scheduled_at=$value fails the whole projection', () {
        final json = _validDetailProjection();
        json['visits'] = [
          {
            'id': 'v1',
            'status': 'scheduled',
            if (value != null) 'scheduled_at': value,
          },
        ];
        expect(StaffApplicationDetail.tryFromJson(json), isNull);
      });
    }

    test('detail: valid contact and visit timestamps are preserved', () {
      final json = _validDetailProjection();
      json['contacts'] = [
        const {
          'id': 'c1',
          'contacted_by_user_id': 'u1',
          'contact_type': 'phone',
          'contacted_at': '2024-01-03T10:00:00.000Z',
        },
      ];
      json['visits'] = [
        const {
          'id': 'v1',
          'status': 'scheduled',
          'scheduled_at': '2024-01-04T10:00:00.000Z',
        },
      ];
      final detail = StaffApplicationDetail.tryFromJson(json);
      expect(detail, isNotNull);
      expect(detail!.contacts.single.contactedAt, DateTime.utc(2024, 1, 3, 10));
      expect(detail.visits.single.scheduledAt, DateTime.utc(2024, 1, 4, 10));
    });
  });

  group('StaffAccessProvider auth session lifecycle (finding 10)', () {
    test('sign-out resets and signals permission loss', () async {
      final auth = _SwitchableAuthProvider(
        session: const AuthSession(
          userId: _staffUserId,
          email: 'a@x',
          displayName: 'A',
        ),
      );
      var lost = 0;
      final gateway = _FakeStaffGateway(capabilities: _staffCapabilities);
      final provider = StaffAccessProvider(
        gateway: gateway,
        auth: auth,
        onPermissionLost: () => lost++,
      );
      await provider.load();
      expect(provider.state, StaffAccessState.authorized);

      auth.setSession(null);

      expect(provider.state, StaffAccessState.initial);
      expect(provider.capabilities, isNull);
      expect(lost, 1);
    });

    test('session replacement clears and re-resolves capabilities', () async {
      final auth = _SwitchableAuthProvider(
        session: const AuthSession(
          userId: _staffUserId,
          email: 'a@x',
          displayName: 'A',
        ),
      );
      var lost = 0;
      final gateway = _FakeStaffGateway(capabilities: _staffCapabilities);
      final provider = StaffAccessProvider(
        gateway: gateway,
        auth: auth,
        onPermissionLost: () => lost++,
      );
      await provider.load();
      final callsAfterFirst = gateway.capabilitiesCalls;

      auth.setSession(
        const AuthSession(userId: 'b', email: 'b@x', displayName: 'B'),
      );
      await pumpEventQueue();

      expect(lost, 1);
      expect(gateway.capabilitiesCalls, callsAfterFirst + 1);
      expect(provider.state, StaffAccessState.authorized);
    });
  });

  group('StaffApplicationQueueProvider corrections (findings 1, 6)', () {
    test('load-more failure keeps items and '
        'retryLoadMore reuses the same cursor', () async {
      final item1 = _sampleSummary('app-1');
      final cursor1 = StaffApplicationCursor(
        createdAt: item1.createdAt,
        id: item1.id,
      );
      final item2 = _sampleSummary('app-2');
      final gateway = _FakeStaffGateway(
        pageResults: [
          StaffReadSuccess(
            StaffApplicationPage(items: [item1], nextCursor: cursor1),
          ),
          const StaffReadDenied(BusinessApplicationStaffCause.unexpected),
          StaffReadSuccess(
            StaffApplicationPage(
              items: [item2],
              nextCursor: StaffApplicationCursor(
                createdAt: item2.createdAt,
                id: item2.id,
              ),
            ),
          ),
        ],
      );
      final provider = StaffApplicationQueueProvider(gateway: gateway);

      await provider.loadInitial();
      expect(provider.items.length, 1);

      await provider.loadMore();
      expect(provider.state, StaffQueueState.loadMoreError);
      expect(provider.items.length, 1, reason: 'failure keeps loaded items');

      await provider.retryLoadMore();
      expect(provider.state, StaffQueueState.data);
      expect(provider.items.length, 2);
      expect(gateway.cursorsRequested, [
        null,
        cursor1,
        cursor1,
      ], reason: 'retry re-requests the same next page');
    });

    test('P0PER on append clears privileged data and signals', () async {
      final item1 = _sampleSummary('app-1');
      var lost = 0;
      final gateway = _FakeStaffGateway(
        pageResults: [
          StaffReadSuccess(
            StaffApplicationPage(
              items: [item1],
              nextCursor: StaffApplicationCursor(
                createdAt: item1.createdAt,
                id: item1.id,
              ),
            ),
          ),
          const StaffReadDenied(
            BusinessApplicationStaffCause.staffPermissionDenied,
          ),
        ],
      );
      final provider = StaffApplicationQueueProvider(
        gateway: gateway,
        onPermissionLost: (_) => lost++,
      );
      await provider.loadInitial();
      expect(provider.items.length, 1);

      await provider.loadMore();
      expect(provider.state, StaffQueueState.accessDenied);
      expect(provider.items, isEmpty);
      expect(lost, 1);
    });

    test('newer filter response wins over an older initial response', () async {
      final first = Completer<StaffReadResult<StaffApplicationPage>>();
      final second = Completer<StaffReadResult<StaffApplicationPage>>();
      var calls = 0;
      final gateway = _FakeStaffGateway(
        pageRead: (_, __, ___) => calls++ == 0 ? first.future : second.future,
      );
      final provider = StaffApplicationQueueProvider(gateway: gateway);

      final requestA = provider.loadInitial();
      final requestB = provider.setFilter(
        const StaffApplicationQueueFilter(
          status: BusinessApplicationStatus.approved,
        ),
      );
      second.complete(
        StaffReadSuccess(
          StaffApplicationPage(items: [_sampleSummary('newer')]),
        ),
      );
      await requestB;
      first.complete(
        StaffReadSuccess(
          StaffApplicationPage(items: [_sampleSummary('older')]),
        ),
      );
      await requestA;

      expect(provider.filter.status, BusinessApplicationStatus.approved);
      expect(provider.items.single.id, 'newer');
    });
  });

  group('StaffApplicationDetailProvider corrections (findings 1, 2, 8, 9)', () {
    test('P0PER on load clears detail, denies, and signals', () async {
      var lost = 0;
      final gateway = _FakeStaffGateway(
        detailResult: const StaffReadDenied(
          BusinessApplicationStaffCause.staffPermissionDenied,
        ),
      );
      final provider = StaffApplicationDetailProvider(
        gateway: gateway,
        onPermissionLost: (_) => lost++,
      );

      await provider.load('app-1');

      expect(provider.state, StaffDetailState.accessDenied);
      expect(provider.detail, isNull);
      expect(lost, 1);
    });

    test('concurrent mutation is rejected before any RPC', () async {
      final detail = _sampleDetail(
        'app-1',
        BusinessApplicationStatus.submitted,
      );
      final gateway = _FakeStaffGateway(
        detail: detail,
        mutationResult: BusinessApplicationStaffSucceeded(
          _businessAppFromDetail(detail),
        ),
      );
      final provider = StaffApplicationDetailProvider(gateway: gateway);
      await provider.load('app-1');

      final first = provider.beginReview();
      final second = await provider.approve();

      expect(
        second,
        isFalse,
        reason: 'guarded while first mutation is pending',
      );
      await first;
      expect(gateway.mutationActions, ['beginReview']);
    });

    test('stale detail read results are ignored', () async {
      final first = Completer<StaffReadResult<StaffApplicationDetail>>();
      final second = Completer<StaffReadResult<StaffApplicationDetail>>();
      var reads = 0;
      final gateway = _FakeStaffGateway(
        detailRead: (id) {
          reads++;
          return reads == 1 ? first.future : second.future;
        },
      );
      final provider = StaffApplicationDetailProvider(gateway: gateway);

      final firstLoad = provider.load('app-1');
      await pumpEventQueue();
      final secondLoad = provider.refresh();

      first.complete(
        StaffReadSuccess(
          _sampleDetail('stale', BusinessApplicationStatus.submitted),
        ),
      );
      second.complete(
        StaffReadSuccess(
          _sampleDetail('fresh', BusinessApplicationStatus.underReview),
        ),
      );

      await firstLoad;
      await secondLoad;

      expect(provider.detail?.id, 'fresh');
      expect(provider.detail?.status, BusinessApplicationStatus.underReview);
    });

    test('post-mutation committed callback refreshes the queue', () async {
      final detail = _sampleDetail(
        'app-1',
        BusinessApplicationStatus.submitted,
      );
      final reviewed = detail.copyWithStatus(
        BusinessApplicationStatus.underReview,
      );
      final item = _sampleSummary('app-1');
      final gateway = _FakeStaffGateway(
        detail: detail,
        postMutationDetail: reviewed,
        mutationResult: BusinessApplicationStaffSucceeded(
          _businessAppFromDetail(detail),
        ),
        pages: [
          StaffApplicationPage(items: [item], nextCursor: null),
          const StaffApplicationPage(items: []),
        ],
      );
      final queue = StaffApplicationQueueProvider(gateway: gateway);
      final detailProvider = StaffApplicationDetailProvider(
        gateway: gateway,
        onMutationCommitted: () => queue.refresh(),
      );
      await detailProvider.load('app-1');
      await queue.loadInitial();
      expect(queue.items.length, 1);

      await detailProvider.approve();
      await pumpEventQueue();

      expect(queue.items, isEmpty);
    });
  });

  group('StaffOperationsScope cross-provider wiring', () {
    test('queue P0PER revokes the shared access provider', () async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        pageResult: const StaffReadDenied(
          BusinessApplicationStaffCause.staffPermissionDenied,
        ),
      );
      final scope = StaffOperationsScope(
        gateway: gateway,
        auth: _authenticatedAuth(),
      );
      addTearDown(() => _disposeTestScope(scope));
      await scope.access.load();

      await scope.queue.loadInitial();

      expect(scope.access.state, StaffAccessState.noReadPermission);
      expect(scope.access.capabilities, isNull);
      expect(scope.queue.items, isEmpty);
      expect(scope.detail.detail, isNull);
    });

    test('detail permission loss clears the queue', () async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        page: StaffApplicationPage(items: [_sampleSummary('app-1')]),
        detailResult: const StaffReadDenied(
          BusinessApplicationStaffCause.staffPermissionDenied,
        ),
      );
      final scope = StaffOperationsScope(
        gateway: gateway,
        auth: _authenticatedAuth(),
      );
      addTearDown(() => _disposeTestScope(scope));

      await scope.queue.loadInitial();
      expect(scope.queue.items.length, 1);

      await scope.detail.load(_appId);

      expect(scope.access.state, StaffAccessState.noReadPermission);
      expect(scope.detail.state, StaffDetailState.initial);
      expect(scope.queue.state, StaffQueueState.initial);
      expect(scope.queue.items, isEmpty);
    });

    test('access sign-out clears both privileged providers', () async {
      final detail = _sampleDetail(_appId, BusinessApplicationStatus.submitted);
      final auth = _SwitchableAuthProvider(
        session: const AuthSession(
          userId: _staffUserId,
          email: 'a@x',
          displayName: 'A',
        ),
      );
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        page: StaffApplicationPage(items: [_sampleSummary('app-1')]),
        detail: detail,
      );
      final scope = StaffOperationsScope(gateway: gateway, auth: auth);
      addTearDown(() => _disposeTestScope(scope));

      await scope.access.load();
      await scope.queue.loadInitial();
      await scope.detail.load(_appId);
      expect(scope.queue.items.length, 1);
      expect(scope.detail.state, StaffDetailState.data);

      auth.setSession(null);

      expect(scope.queue.state, StaffQueueState.initial);
      expect(scope.queue.items, isEmpty);
      expect(scope.detail.state, StaffDetailState.initial);
    });

    test('sign-out invalidates a mutation completion before reread', () async {
      final auth = _SwitchableAuthProvider(
        session: const AuthSession(
          userId: _staffUserId,
          email: 'a@x',
          displayName: 'A',
        ),
      );
      final mutation = Completer<BusinessApplicationStaffResult>();
      final detail = _sampleDetail(
        _appId,
        BusinessApplicationStatus.underReview,
      );
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        detail: detail,
        mutationCompleter: mutation,
      );
      final scope = StaffOperationsScope(gateway: gateway, auth: auth);
      addTearDown(() => _disposeTestScope(scope));
      await scope.access.load();
      await scope.detail.load(_appId);

      final pending = scope.detail.approve();
      auth.setSession(null);
      mutation.complete(
        BusinessApplicationStaffSucceeded(_businessAppFromDetail(detail)),
      );
      await pending;

      expect(
        gateway.detailCalls,
        1,
        reason: 'old completion performs no reread',
      );
      expect(
        gateway.cursorsRequested,
        isEmpty,
        reason: 'old completion performs no queue refresh',
      );
      expect(scope.detail.detail, isNull);
      expect(scope.access.capabilities, isNull);
    });

    test('user replacement invalidates old mutation completion', () async {
      final auth = _SwitchableAuthProvider(
        session: const AuthSession(
          userId: _staffUserId,
          email: 'a@x',
          displayName: 'A',
        ),
      );
      final mutation = Completer<BusinessApplicationStaffResult>();
      final detail = _sampleDetail(
        _appId,
        BusinessApplicationStatus.underReview,
      );
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        detail: detail,
        mutationCompleter: mutation,
      );
      final scope = StaffOperationsScope(gateway: gateway, auth: auth);
      addTearDown(() => _disposeTestScope(scope));
      await scope.access.load();
      await scope.detail.load(_appId);

      final pending = scope.detail.approve();
      auth.setSession(
        const AuthSession(userId: 'user-b', email: 'b@x', displayName: 'B'),
      );
      mutation.complete(
        BusinessApplicationStaffSucceeded(_businessAppFromDetail(detail)),
      );
      await pending;
      await pumpEventQueue();

      expect(gateway.detailCalls, 1);
      expect(gateway.cursorsRequested, isEmpty);
      expect(scope.detail.detail, isNull);
      expect(scope.access.state, StaffAccessState.authorized);
    });

    test(
      'post-mutation P0PER revokes access and stops queue refresh',
      () async {
        var reads = 0;
        final detail = _sampleDetail(
          _appId,
          BusinessApplicationStatus.underReview,
        );
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          mutationResult: BusinessApplicationStaffSucceeded(
            _businessAppFromDetail(detail),
          ),
          detailRead: (_) async => reads++ == 0
              ? StaffReadSuccess(detail)
              : const StaffReadDenied(
                  BusinessApplicationStaffCause.staffPermissionDenied,
                ),
        );
        final scope = StaffOperationsScope(
          gateway: gateway,
          auth: _authenticatedAuth(),
        );
        addTearDown(() => _disposeTestScope(scope));
        await scope.access.load();
        await scope.detail.load(_appId);

        await scope.detail.approve();

        expect(gateway.mutationActions, ['approve']);
        expect(gateway.detailCalls, 2);
        expect(gateway.cursorsRequested, isEmpty);
        expect(scope.access.state, StaffAccessState.noReadPermission);
        expect(scope.access.capabilities, isNull);
        expect(scope.detail.detail, isNull);
        expect(scope.queue.items, isEmpty);
      },
    );
  });

  group('StaffApplicationReviewScreen route safety and actions '
      '(findings 13, 14)', () {
    testWidgets('malformed application id fails safe before any RPC', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        detail: _sampleDetail(_appId, BusinessApplicationStatus.underReview),
      );
      await tester.pumpWidget(
        _testApp(
          staffGateway: gateway,
          child: const StaffApplicationReviewScreen(
            applicationId: 'not-a-uuid',
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(Ar.staffCauseNotFound), findsOneWidget);
      expect(gateway.detailCalls, 0);
    });

    testWidgets('action dialogs show action-specific confirm labels', (
      tester,
    ) async {
      final detail = _sampleDetail(
        _appId,
        BusinessApplicationStatus.underReview,
      );
      await tester.pumpWidget(
        _testApp(
          staffGateway: _FakeStaffGateway(
            capabilities: _staffCapabilities,
            detail: detail,
            mutationResult: BusinessApplicationStaffSucceeded(
              _businessAppFromDetail(detail),
            ),
          ),
          child: const StaffApplicationReviewScreen(applicationId: _appId),
        ),
      );
      await tester.pump();
      await tester.pump();

      final approve = find.widgetWithText(
        ElevatedButton,
        Ar.staffActionApprove,
      );
      await tester.ensureVisible(approve);
      await tester.pumpAndSettle();
      await tester.tap(approve);
      await tester.pumpAndSettle();

      expect(find.text(Ar.staffConfirmApprove), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, Ar.staffActionApprove),
        findsOneWidget,
      );

      await tester.tap(find.text(Ar.businessCancel));
      await tester.pumpAndSettle();
      expect(find.text(Ar.staffConfirmApprove), findsNothing);
    });

    testWidgets('activate is only offered for approved applications', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          staffGateway: _FakeStaffGateway(
            capabilities: _staffCapabilities,
            detail: _sampleDetail(_appId, BusinessApplicationStatus.approved),
          ),
          child: const StaffApplicationReviewScreen(applicationId: _appId),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.widgetWithText(ElevatedButton, Ar.staffActionActivate),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, Ar.staffActionApprove),
        findsNothing,
      );
    });

    testWidgets('Begin Review confirms and calls the gateway once', (
      tester,
    ) async {
      final gateway = await _pumpReviewAction(
        tester,
        status: BusinessApplicationStatus.submitted,
      );
      await _tapAction(tester, Ar.staffActionBeginReview);
      expect(find.text(Ar.staffConfirmBeginReview), findsOneWidget);
      await tester.tap(
        find.widgetWithText(TextButton, Ar.staffActionBeginReview),
      );
      await tester.pumpAndSettle();
      expect(gateway.mutationActions, ['beginReview']);
    });

    testWidgets('Return for Correction requires and forwards a reason', (
      tester,
    ) async {
      final gateway = await _pumpReviewAction(
        tester,
        status: BusinessApplicationStatus.underReview,
      );
      await _tapAction(tester, Ar.staffActionReturnForCorrection);
      await tester.tap(
        find.widgetWithText(TextButton, Ar.staffActionReturnForCorrection),
      );
      await tester.pumpAndSettle();
      expect(gateway.mutationActions, isEmpty);

      await _tapAction(tester, Ar.staffActionReturnForCorrection);
      await tester.enterText(find.byType(TextField), 'Correct the address');
      await tester.tap(
        find.widgetWithText(TextButton, Ar.staffActionReturnForCorrection),
      );
      await tester.pumpAndSettle();
      expect(gateway.mutationActions, ['returnForCorrection']);
      expect(gateway.mutationLog.single.reason, 'Correct the address');
    });

    testWidgets('Mark Contacted submits the bounded contact input once', (
      tester,
    ) async {
      final gateway = await _pumpReviewAction(
        tester,
        status: BusinessApplicationStatus.underReview,
      );
      await _tapAction(tester, Ar.staffActionMarkContacted);
      expect(find.text(Ar.staffContactTypeLabel), findsOneWidget);
      await tester.tap(
        find.widgetWithText(TextButton, Ar.staffActionMarkContacted),
      );
      await tester.pumpAndSettle();
      expect(gateway.mutationActions, ['markContacted']);
      expect(gateway.mutationLog.single.contactType, 'phone');
    });

    testWidgets('Schedule Visit rejects incomplete input and submits a time', (
      tester,
    ) async {
      final gateway = await _pumpReviewAction(
        tester,
        status: BusinessApplicationStatus.underReview,
      );
      await _tapAction(tester, Ar.staffActionScheduleVisit);
      final submit = find.widgetWithText(
        TextButton,
        Ar.staffActionScheduleVisit,
      );
      expect(tester.widget<TextButton>(submit).onPressed, isNull);

      await tester.tap(find.text(Ar.staffVisitScheduledAtLabel));
      await tester.pumpAndSettle();
      var localizations = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tester.tap(find.text(localizations.okButtonLabel));
      await tester.pumpAndSettle();
      localizations = MaterialLocalizations.of(
        tester.element(find.byType(TimePickerDialog)),
      );
      await tester.tap(find.text(localizations.okButtonLabel));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, Ar.staffActionScheduleVisit),
      );
      await tester.pumpAndSettle();
      expect(gateway.mutationActions, ['scheduleVisit']);
      expect(gateway.mutationLog.single.scheduledAt, isNotNull);
    });

    testWidgets('Approve dismissal is inert and confirmation calls once', (
      tester,
    ) async {
      final gateway = await _pumpReviewAction(
        tester,
        status: BusinessApplicationStatus.underReview,
      );
      await _tapAction(tester, Ar.staffActionApprove);
      await tester.tap(find.text(Ar.businessCancel));
      await tester.pumpAndSettle();
      expect(gateway.mutationActions, isEmpty);

      await _tapAction(tester, Ar.staffActionApprove);
      await tester.tap(find.widgetWithText(TextButton, Ar.staffActionApprove));
      await tester.pumpAndSettle();
      expect(gateway.mutationActions, ['approve']);
    });

    testWidgets('Reject requires and forwards a reason', (tester) async {
      final gateway = await _pumpReviewAction(
        tester,
        status: BusinessApplicationStatus.underReview,
      );
      await _tapAction(tester, Ar.staffActionReject);
      await tester.tap(find.widgetWithText(TextButton, Ar.staffActionReject));
      await tester.pumpAndSettle();
      expect(gateway.mutationActions, isEmpty);

      await _tapAction(tester, Ar.staffActionReject);
      await tester.enterText(find.byType(TextField), 'Duplicate application');
      await tester.tap(find.widgetWithText(TextButton, Ar.staffActionReject));
      await tester.pumpAndSettle();
      expect(gateway.mutationActions, ['reject']);
      expect(gateway.mutationLog.single.reason, 'Duplicate application');
    });

    testWidgets('Activate uses its label and calls the gateway once', (
      tester,
    ) async {
      final gateway = await _pumpReviewAction(
        tester,
        status: BusinessApplicationStatus.approved,
      );
      await _tapAction(tester, Ar.staffActionActivate);
      expect(find.text(Ar.staffConfirmActivate), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, Ar.staffActionActivate),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, Ar.staffActionActivate));
      await tester.pumpAndSettle();
      expect(gateway.mutationActions, ['activate']);
    });

    testWidgets('Activate requires both APPROVED and activation permission', (
      tester,
    ) async {
      await _pumpReviewAction(
        tester,
        status: BusinessApplicationStatus.approved,
        capabilities: _readOnlyCapabilities,
      );
      expect(find.text(Ar.staffActionActivate), findsNothing);

      await _pumpReviewAction(
        tester,
        status: BusinessApplicationStatus.underReview,
        capabilities: StaffApplicationCapabilities.tryFromJson(const {
          'permissions': [
            'business_applications.read',
            'business_applications.activate',
          ],
        })!,
      );
      expect(find.text(Ar.staffActionActivate), findsNothing);
    });
  });

  group('real staff route callbacks and access boundaries', () {
    testWidgets('authorized User Area tile navigates to the staff queue', (
      tester,
    ) async {
      final harness = _routerHarness(
        initialLocation: AppRoutes.user,
        auth: _authenticatedAuth(),
        gateway: _FakeStaffGateway(
          capabilities: _staffCapabilities,
          page: const StaffApplicationPage(items: []),
        ),
      );
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();
      final staffEntry = find.widgetWithText(ListTile, Ar.staffOperations);
      await tester.ensureVisible(staffEntry);
      await tester.pumpAndSettle();
      await tester.tap(staffEntry);
      await tester.pumpAndSettle();
      expect(
        harness
            .router
            .routerDelegate
            .currentConfiguration
            .matches
            .last
            .matchedLocation,
        AppRoutes.staffApplications,
      );
      expect(find.byType(StaffApplicationQueueScreen), findsOneWidget);
    });

    testWidgets('queue item callback navigates with the canonical UUID', (
      tester,
    ) async {
      final harness = _routerHarness(
        initialLocation: AppRoutes.staffApplications,
        auth: _authenticatedAuth(),
        gateway: _FakeStaffGateway(
          capabilities: _staffCapabilities,
          page: StaffApplicationPage(
            items: [_sampleSummary(_appId, name: 'Route Business')],
          ),
          detail: _sampleDetail(_appId, BusinessApplicationStatus.submitted),
        ),
      );
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();
      final queueItem = find.ancestor(
        of: find.text('Route Business'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(queueItem);
      await tester.pumpAndSettle();
      await tester.tap(queueItem);
      await tester.pumpAndSettle();
      expect(
        harness
            .router
            .routerDelegate
            .currentConfiguration
            .matches
            .last
            .matchedLocation,
        AppRoutes.staffApplicationDetailFor(_appId),
      );
      expect(find.byType(StaffApplicationReviewScreen), findsOneWidget);
    });

    testWidgets('logged-out queue deep link performs no privileged read', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        page: const StaffApplicationPage(items: []),
      );
      final harness = _routerHarness(
        initialLocation: AppRoutes.staffApplications,
        auth: _guestAuth(),
        gateway: gateway,
      );
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();
      expect(find.text(Ar.staffSignInRequired), findsOneWidget);
      expect(gateway.cursorsRequested, isEmpty);
    });

    testWidgets('unauthorized queue deep link renders no queue projection', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: const StaffApplicationCapabilities.empty(),
        page: StaffApplicationPage(
          items: [_sampleSummary(_appId, name: 'Secret Business')],
        ),
      );
      final harness = _routerHarness(
        initialLocation: AppRoutes.staffApplications,
        auth: _authenticatedAuth(),
        gateway: gateway,
      );
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();
      expect(find.text(Ar.staffAccessDenied), findsOneWidget);
      expect(find.text('Secret Business'), findsNothing);
      expect(gateway.cursorsRequested, isEmpty);
    });

    testWidgets('capability resolution blocks queue reads and data flash', (
      tester,
    ) async {
      final capabilities =
          Completer<StaffReadResult<StaffApplicationCapabilities>>();
      final gateway = _FakeStaffGateway(
        capabilitiesRead: () => capabilities.future,
        page: StaffApplicationPage(
          items: [_sampleSummary(_appId, name: 'Secret Business')],
        ),
      );
      final harness = _routerHarness(
        initialLocation: AppRoutes.staffApplications,
        auth: _authenticatedAuth(),
        gateway: gateway,
      );
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app);
      await tester.pump();
      expect(find.text(Ar.staffLoadingAccess), findsOneWidget);
      expect(find.text('Secret Business'), findsNothing);
      expect(gateway.cursorsRequested, isEmpty);
      capabilities.complete(
        const StaffReadSuccess(StaffApplicationCapabilities.empty()),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('User Area staff label follows the English locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          staffGateway: _FakeStaffGateway(capabilities: _staffCapabilities),
          child: const UserAreaScreen(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(En.staffOperations), findsOneWidget);
      expect(find.text(Ar.staffOperations), findsNothing);
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget _testApp({
  required _FakeStaffGateway staffGateway,
  required Widget child,
  Locale locale = const Locale('ar'),
}) {
  final auth = _authenticatedAuth();
  return ChangeNotifierProvider(
    create: (_) => auth,
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => StaffAccessProvider(gateway: staffGateway, auth: auth),
        ),
        ChangeNotifierProvider(
          create: (_) => StaffApplicationQueueProvider(gateway: staffGateway),
        ),
        ChangeNotifierProvider(
          create: (_) => StaffApplicationDetailProvider(gateway: staffGateway),
        ),
      ],
      child: MaterialApp(
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale?.languageCode) {
              return supported;
            }
          }
          return const Locale('ar');
        },
        locale: locale,
        home: child,
      ),
    ),
  );
}

Future<_FakeStaffGateway> _pumpReviewAction(
  WidgetTester tester, {
  required BusinessApplicationStatus status,
  StaffApplicationCapabilities? capabilities,
}) async {
  final detail = _sampleDetail(_appId, status);
  final gateway = _FakeStaffGateway(
    capabilities: capabilities ?? _staffCapabilities,
    detail: detail,
    postMutationDetail: detail,
    mutationResult: BusinessApplicationStaffSucceeded(
      _businessAppFromDetail(detail),
    ),
  );
  await tester.pumpWidget(
    _testApp(
      staffGateway: gateway,
      child: const StaffApplicationReviewScreen(applicationId: _appId),
    ),
  );
  await tester.pump();
  await tester.pump();
  return gateway;
}

Future<void> _tapAction(WidgetTester tester, String label) async {
  final action = find.widgetWithText(ElevatedButton, label);
  await tester.ensureVisible(action);
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}

class _RouterHarness {
  _RouterHarness({
    required this.app,
    required this.router,
    required this.scope,
    required this.auth,
  });

  final Widget app;
  final GoRouter router;
  final StaffOperationsScope scope;
  final AuthProvider auth;

  void dispose() {
    router.dispose();
    _disposeTestScope(scope);
    auth.dispose();
  }
}

_RouterHarness _routerHarness({
  required String initialLocation,
  required AuthProvider auth,
  required _FakeStaffGateway gateway,
}) {
  final scope = StaffOperationsScope(gateway: gateway, auth: auth);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: AppRoutes.user, builder: (_, __) => const UserAreaScreen()),
      GoRoute(
        path: AppRoutes.staffApplications,
        builder: (_, __) => const StaffApplicationQueueScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffApplicationDetailPattern,
        builder: (_, state) => StaffApplicationReviewScreen(
          applicationId: state.pathParameters['applicationId'] ?? '',
        ),
      ),
    ],
  );
  final app = MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<StaffAccessProvider>.value(value: scope.access),
      ChangeNotifierProvider<StaffApplicationQueueProvider>.value(
        value: scope.queue,
      ),
      ChangeNotifierProvider<StaffApplicationDetailProvider>.value(
        value: scope.detail,
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
  return _RouterHarness(app: app, router: router, scope: scope, auth: auth);
}

AuthProvider _authenticatedAuth() {
  return _FakeAuthProvider(
    session: const AuthSession(
      userId: _staffUserId,
      email: 'staff@example.com',
      displayName: 'Staff User',
    ),
  );
}

AuthProvider _guestAuth() => _FakeAuthProvider();

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({this.session});

  final AuthSession? session;

  @override
  bool get isAvailable => true;

  @override
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<AuthSession?> signInWithGoogle() async => session;

  @override
  Future<void> signOut() async {}
}

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider({AuthSession? session})
    : _session = session,
      super(gateway: _FakeAuthGateway(session: session));

  final AuthSession? _session;

  @override
  bool get isLoggedIn => _session != null;

  @override
  AuthStatus get status =>
      _session != null ? AuthStatus.authenticated : AuthStatus.guest;

  @override
  AuthSession? get session => _session;
}

class _SwitchableAuthProvider extends AuthProvider {
  _SwitchableAuthProvider({AuthSession? session})
    : _session = session,
      super(gateway: _FakeAuthGateway(session: session));

  AuthSession? _session;

  @override
  bool get isLoggedIn => _session != null;

  @override
  AuthStatus get status =>
      _session != null ? AuthStatus.authenticated : AuthStatus.guest;

  @override
  AuthSession? get session => _session;

  void setSession(AuthSession? next) {
    _session = next;
    notifyListeners();
  }
}

class _FakeStaffGateway implements BusinessApplicationStaffGateway {
  _FakeStaffGateway({
    this.available = true,
    this.capabilities,
    this.capabilitiesResult,
    this.page,
    this.pages,
    this.pageResult,
    this.pageResults,
    this.detail,
    this.detailResult,
    this.mutationResult,
    this.postMutationDetail,
    this.postMutationDetailResult,
    this.detailRead,
    this.pageRead,
    this.mutationCompleter,
    this.capabilitiesRead,
  });

  final bool available;
  final StaffApplicationCapabilities? capabilities;
  final StaffReadResult<StaffApplicationCapabilities>? capabilitiesResult;
  final StaffApplicationPage? page;
  final List<StaffApplicationPage>? pages;
  final StaffReadResult<StaffApplicationPage>? pageResult;

  /// Consumed sequentially by [listApplications]; overrides [page]/[pages].
  /// Each element is returned exactly once so a retry can observe a distinct
  /// (healthier) next page.
  final List<StaffReadResult<StaffApplicationPage>>? pageResults;
  final StaffApplicationDetail? detail;
  final StaffReadResult<StaffApplicationDetail>? detailResult;
  final BusinessApplicationStaffResult? mutationResult;
  final StaffApplicationDetail? postMutationDetail;
  StaffReadResult<StaffApplicationDetail>? postMutationDetailResult;

  /// Test hook: full control over each detail read (ordering, gating).
  final Future<StaffReadResult<StaffApplicationDetail>> Function(
    String applicationId,
  )?
  detailRead;
  final Future<StaffReadResult<StaffApplicationPage>> Function(
    BusinessApplicationStatus?,
    BusinessApplicationType?,
    StaffApplicationCursor?,
  )?
  pageRead;
  final Completer<BusinessApplicationStaffResult>? mutationCompleter;
  final Future<StaffReadResult<StaffApplicationCapabilities>> Function()?
  capabilitiesRead;

  int _pageIndex = 0;
  int _pageResultsIndex = 0;
  final List<_RecordedMutation> _mutationLog = [];
  final List<StaffApplicationCursor?> cursorsRequested = [];

  int capabilitiesCalls = 0;
  int detailCalls = 0;

  List<String> get mutationActions =>
      _mutationLog.map((m) => m.action).toList();
  List<_RecordedMutation> get mutationLog => List.unmodifiable(_mutationLog);

  @override
  bool get isAvailable => available;

  @override
  Future<StaffReadResult<StaffApplicationCapabilities>>
  getCapabilities() async {
    capabilitiesCalls++;
    if (capabilitiesRead != null) return capabilitiesRead!();
    if (capabilitiesResult != null) return capabilitiesResult!;
    if (capabilities != null) return StaffReadSuccess(capabilities!);
    return const StaffReadDenied(
      BusinessApplicationStaffCause.staffPermissionDenied,
    );
  }

  @override
  Future<StaffReadResult<StaffApplicationPage>> listApplications({
    BusinessApplicationStatus? statusFilter,
    BusinessApplicationType? typeFilter,
    int limit = 25,
    StaffApplicationCursor? cursor,
  }) async {
    cursorsRequested.add(cursor);
    if (pageRead != null) return pageRead!(statusFilter, typeFilter, cursor);
    if (pageResult != null) return pageResult!;
    if (pageResults != null && _pageResultsIndex < pageResults!.length) {
      return pageResults![_pageResultsIndex++];
    }
    final source = pages;
    if (source != null && _pageIndex < source.length) {
      return StaffReadSuccess(source[_pageIndex++]);
    }
    if (page != null) return StaffReadSuccess(page!);
    return const StaffReadSuccess(StaffApplicationPage(items: []));
  }

  @override
  Future<StaffReadResult<StaffApplicationDetail>> getApplicationDetail(
    String applicationId,
  ) async {
    detailCalls++;
    if (detailRead != null) return detailRead!(applicationId);
    if (detailResult != null) return detailResult!;
    if (postMutationDetailResult != null && _mutationLog.isNotEmpty) {
      final result = postMutationDetailResult!;
      // One-shot: only the immediate post-mutation reread observes it, so a
      // later manual "Refresh details" can observe the healthy detail again.
      postMutationDetailResult = null;
      return result;
    }
    if (postMutationDetail != null && _mutationLog.isNotEmpty) {
      return StaffReadSuccess(postMutationDetail!);
    }
    if (detail != null) return StaffReadSuccess(detail!);
    return const StaffReadDenied(
      BusinessApplicationStaffCause.applicationNotFound,
    );
  }

  @override
  Future<BusinessApplicationStaffResult> beginReview(
    String applicationId,
  ) async {
    return _mutation('beginReview', applicationId);
  }

  @override
  Future<BusinessApplicationStaffResult> returnForCorrection(
    String applicationId, {
    required String reason,
  }) async {
    return _mutation('returnForCorrection', applicationId, reason: reason);
  }

  @override
  Future<BusinessApplicationStaffResult> markContacted(
    String applicationId, {
    required String contactType,
    String? result,
    String? notes,
  }) async {
    return _mutation(
      'markContacted',
      applicationId,
      contactType: contactType,
      result: result,
      notes: notes,
    );
  }

  @override
  Future<BusinessApplicationStaffResult> scheduleVisit(
    String applicationId, {
    required DateTime scheduledAt,
    String? location,
    String? notes,
  }) async {
    return _mutation(
      'scheduleVisit',
      applicationId,
      scheduledAt: scheduledAt,
      location: location,
      notes: notes,
    );
  }

  @override
  Future<BusinessApplicationStaffResult> approve(String applicationId) async {
    return _mutation('approve', applicationId);
  }

  @override
  Future<BusinessApplicationStaffResult> reject(
    String applicationId, {
    required String reason,
  }) async {
    return _mutation('reject', applicationId, reason: reason);
  }

  @override
  Future<BusinessApplicationStaffResult> activate(String applicationId) async {
    return _mutation('activate', applicationId);
  }

  Future<BusinessApplicationStaffResult> _mutation(
    String action,
    String applicationId, {
    String? reason,
    String? contactType,
    String? result,
    String? notes,
    DateTime? scheduledAt,
    String? location,
  }) {
    _mutationLog.add(
      _RecordedMutation(
        action,
        applicationId,
        reason: reason,
        contactType: contactType,
        result: result,
        notes: notes,
        scheduledAt: scheduledAt,
        location: location,
      ),
    );
    final pending = mutationCompleter;
    if (pending != null) return pending.future;
    return Future.value(
      mutationResult ?? BusinessApplicationStaffDenied(_invalidTransitionCause),
    );
  }
}

Map<String, dynamic> _validDetailProjection() => {
  'application': {
    'id': _appId,
    'application_type': 'NEW',
    'status': 'SUBMITTED',
    'created_at': '2024-01-01T10:00:00.000Z',
    'updated_at': '2024-01-02T10:00:00.000Z',
  },
  'applicant': {'display_name': 'Applicant'},
  'new_business': {'name': 'Business'},
  'contacts': <dynamic>[],
  'visits': <dynamic>[],
};

void _disposeTestScope(StaffOperationsScope scope) {
  scope.detail.dispose();
  scope.queue.dispose();
  scope.access.dispose();
  scope.dispose();
}

class _RecordedMutation {
  const _RecordedMutation(
    this.action,
    this.applicationId, {
    this.reason,
    this.contactType,
    this.result,
    this.notes,
    this.scheduledAt,
    this.location,
  });

  final String action;
  final String applicationId;
  final String? reason;
  final String? contactType;
  final String? result;
  final String? notes;
  final DateTime? scheduledAt;
  final String? location;
}

const BusinessApplicationStaffCause _invalidTransitionCause =
    BusinessApplicationStaffCause.invalidTransition;

StaffApplicationSummary _sampleSummary(String id, {String? name}) {
  final now = DateTime.now();
  return StaffApplicationSummary(
    id: id,
    type: BusinessApplicationType.newApplication,
    status: BusinessApplicationStatus.submitted,
    createdAt: now,
    updatedAt: now,
    newBusiness: StaffNewBusinessSummary(name: name ?? 'Business $id'),
  );
}

StaffApplicationDetail _sampleDetail(
  String id,
  BusinessApplicationStatus status,
) {
  final now = DateTime.now();
  return StaffApplicationDetail(
    id: id,
    type: BusinessApplicationType.newApplication,
    status: status,
    createdAt: now,
    updatedAt: now,
    applicantDisplayName: 'Applicant $id',
    applicantPhone: '+9647700000000',
    newBusiness: const StaffNewBusinessContext(name: 'Test Business'),
  );
}

BusinessApplication _businessAppFromDetail(StaffApplicationDetail detail) {
  return BusinessApplication(
    id: detail.id,
    applicantUserId: _staffUserId,
    type: detail.type,
    targetEntityId: detail.targetEntityId,
    metadata: null,
    status: detail.status,
    reviewedAt: detail.reviewedAt,
    approvedAt: detail.approvedAt,
    returnReason: detail.returnReason,
    rejectionReason: detail.rejectionReason,
  );
}

extension _DetailStatusCopy on StaffApplicationDetail {
  StaffApplicationDetail copyWithStatus(BusinessApplicationStatus newStatus) {
    return StaffApplicationDetail(
      id: id,
      type: type,
      status: newStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      targetEntityId: targetEntityId,
      reviewedByUserId: reviewedByUserId,
      reviewedAt: reviewedAt ?? DateTime.now(),
      returnReason: returnReason,
      rejectionReason: rejectionReason,
      approvedAt: approvedAt,
      activatedAt: activatedAt,
      applicantDisplayName: applicantDisplayName,
      applicantPhone: applicantPhone,
      newBusiness: newBusiness,
      claimTarget: claimTarget,
      contacts: contacts,
      visits: visits,
    );
  }
}
