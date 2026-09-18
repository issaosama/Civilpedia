import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:civilpedia/core/widgets/remote_data_notice.dart';
import 'package:civilpedia/core/widgets/transport_status_banner.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
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
import 'package:civilpedia/features/business/domain/staff_remote_read.dart';
import 'package:civilpedia/features/business/presentation/providers/staff_access_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/staff_application_detail_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/staff_application_queue_provider.dart';
import 'package:civilpedia/features/business/presentation/screens/staff_application_queue_screen.dart';
import 'package:civilpedia/features/business/presentation/screens/staff_application_review_screen.dart';
import 'package:civilpedia/features/business/presentation/widgets/staff_remote_read_notice.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

const _on = Locale('ar');
const _en = Locale('en');

const _staffUserId = 'staff-user-p2e2';
const _appX = '00000000-0000-0000-0000-000000000001';
const _appY = '00000000-0000-0000-0000-000000000002';

final DateTime _now = DateTime.utc(2026, 1, 1);

final _staffCapabilities = StaffApplicationCapabilities.tryFromJson(const {
  'permissions': [
    'business_applications.read',
    'business_applications.review',
    'business_applications.approve',
  ],
})!;

StaffApplicationSummary _summary(String id, {String? name}) {
  return StaffApplicationSummary(
    id: id,
    type: BusinessApplicationType.newApplication,
    status: BusinessApplicationStatus.submitted,
    createdAt: _now,
    updatedAt: _now,
    newBusiness: StaffNewBusinessSummary(name: name ?? 'Biz $id'),
  );
}

StaffApplicationPage _pageOf(
  List<StaffApplicationSummary> items, {
  StaffApplicationCursor? next,
}) {
  return StaffApplicationPage(items: items, nextCursor: next);
}

StaffApplicationDetail _detail(
  String id, {
  String? name,
  BusinessApplicationStatus status = BusinessApplicationStatus.underReview,
}) {
  return StaffApplicationDetail(
    id: id,
    type: BusinessApplicationType.newApplication,
    status: status,
    createdAt: _now,
    updatedAt: _now,
    applicantDisplayName: name ?? 'Applicant $id',
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

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeAuthGateway implements AuthGateway {
  const _FakeAuthGateway({this.session});

  final AuthSession? session;

  @override
  bool get isAvailable => true;

  @override
  bool get canAccountAuthorityBeGranted => true;

  @override
  bool get isAuthObservationAvailable => true;

  @override
  bool get isLogoutCleanupBlocked => false;

  @override
  Future<bool> retryAuthCleanup() async => false;

  @override
  Stream<AuthEvent> get authEvents => const Stream.empty();

  @override
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<AuthSession?> signInWithGoogle() async => session;

  @override
  Future<void> signOut() async {}

  @override
  void dispose() {}
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

  @override
  int get generation => 1;

  @override
  bool isCurrentSession({required String userId, required int generation}) {
    return generation == 1 && _session?.userId == userId;
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

({ConnectivityProvider provider, _FakeTransportSource source})
    _connectivitySource({required bool available}) {
  final source = _FakeTransportSource(available);
  final provider = ConnectivityProvider(source: source);
  addTearDown(provider.dispose);
  addTearDown(source.close);
  return (provider: provider, source: source);
}

class _FakeStaffGateway implements BusinessApplicationStaffGateway {
  _FakeStaffGateway({
    this.available = true,
    this.capabilities,
    this.capabilitiesResults,
    this.pageResults,
    this.detailResults,
    this.pageRead,
    this.detailRead,
    this.mutationResult,
    this.postMutationDetailResult,
    this.detail,
  });

  final bool available;
  final StaffApplicationCapabilities? capabilities;
  final List<StaffReadResult<StaffApplicationCapabilities>>? capabilitiesResults;
  final List<StaffReadResult<StaffApplicationPage>>? pageResults;
  final List<StaffReadResult<StaffApplicationDetail>>? detailResults;
  final Future<StaffReadResult<StaffApplicationPage>> Function(
    StaffApplicationCursor? cursor,
  )?
  pageRead;
  final Future<StaffReadResult<StaffApplicationDetail>> Function(String id)?
  detailRead;
  final BusinessApplicationStaffResult? mutationResult;
  StaffReadResult<StaffApplicationDetail>? postMutationDetailResult;
  final StaffApplicationDetail? detail;

  int listCalls = 0;
  int detailCalls = 0;
  int getCapabilitiesCalls = 0;
  final List<String> mutationActions = [];
  final List<BusinessApplicationStatus?> statusFiltersRequested = [];

  int _pageIndex = 0;
  int _detailIndex = 0;
  int _capIndex = 0;

  bool get _hasMutation => mutationActions.isNotEmpty;

  @override
  bool get isAvailable => available;

  @override
  Future<StaffReadResult<StaffApplicationCapabilities>>
  getCapabilities() async {
    getCapabilitiesCalls++;
    if (capabilitiesResults != null && _capIndex < capabilitiesResults!.length) {
      return capabilitiesResults![_capIndex++];
    }
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
    listCalls++;
    statusFiltersRequested.add(statusFilter);
    if (pageRead != null) return pageRead!(cursor);
    if (pageResults != null && _pageIndex < pageResults!.length) {
      return pageResults![_pageIndex++];
    }
    return const StaffReadSuccess(StaffApplicationPage(items: []));
  }

  @override
  Future<StaffReadResult<StaffApplicationDetail>> getApplicationDetail(
    String applicationId,
  ) async {
    detailCalls++;
    if (postMutationDetailResult != null && _hasMutation) {
      final result = postMutationDetailResult!;
      postMutationDetailResult = null;
      return result;
    }
    if (detailRead != null) return detailRead!(applicationId);
    if (detailResults != null && _detailIndex < detailResults!.length) {
      return detailResults![_detailIndex++];
    }
    if (detail != null) return StaffReadSuccess(detail!);
    return const StaffReadDenied(
      BusinessApplicationStaffCause.applicationNotFound,
    );
  }

  @override
  Future<BusinessApplicationStaffResult> beginReview(String applicationId) {
    return _mutation('beginReview');
  }

  @override
  Future<BusinessApplicationStaffResult> returnForCorrection(
    String applicationId, {
    required String reason,
  }) {
    return _mutation('returnForCorrection');
  }

  @override
  Future<BusinessApplicationStaffResult> markContacted(
    String applicationId, {
    required String contactType,
    String? result,
    String? notes,
  }) {
    return _mutation('markContacted');
  }

  @override
  Future<BusinessApplicationStaffResult> scheduleVisit(
    String applicationId, {
    required DateTime scheduledAt,
    String? location,
    String? notes,
  }) {
    return _mutation('scheduleVisit');
  }

  @override
  Future<BusinessApplicationStaffResult> approve(String applicationId) {
    return _mutation('approve');
  }

  @override
  Future<BusinessApplicationStaffResult> activate(String applicationId) {
    return _mutation('activate');
  }

  @override
  Future<BusinessApplicationStaffResult> reject(
    String applicationId, {
    required String reason,
  }) {
    return _mutation('reject');
  }

  Future<BusinessApplicationStaffResult> _mutation(String action) {
    mutationActions.add(action);
    return Future.value(
      mutationResult ??
          const BusinessApplicationStaffDenied(
            BusinessApplicationStaffCause.invalidTransition,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

Future<void> _setTallViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _staffApp({
  required _FakeStaffGateway gateway,
  required Widget screen,
  Locale locale = _on,
  ConnectivityProvider? connectivity,
}) {
  final auth = _FakeAuthProvider(
    session: const AuthSession(
      userId: _staffUserId,
      email: 'staff@example.com',
      displayName: 'Staff User',
    ),
  );
  return ChangeNotifierProvider(
    create: (_) => auth,
    child: MultiProvider(
      providers: [
        if (connectivity != null)
          ChangeNotifierProvider<ConnectivityProvider>.value(value: connectivity),
        ChangeNotifierProvider(
          create: (_) => StaffAccessProvider(gateway: gateway, auth: auth),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              StaffApplicationQueueProvider(gateway: gateway, auth: auth),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              StaffApplicationDetailProvider(gateway: gateway, auth: auth),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [_on, _en],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: screen,
      ),
    ),
  );
}

Future<void> _pumpQueue(
  WidgetTester tester,
  _FakeStaffGateway gateway, {
  Locale locale = _on,
  ConnectivityProvider? connectivity,
}) async {
  await _setTallViewport(tester);
  await tester.pumpWidget(
    _staffApp(
      gateway: gateway,
      screen: const StaffApplicationQueueScreen(),
      locale: locale,
      connectivity: connectivity,
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpReview(
  WidgetTester tester,
  _FakeStaffGateway gateway, {
  String applicationId = _appX,
  Locale locale = _on,
  ConnectivityProvider? connectivity,
}) async {
  await _setTallViewport(tester);
  await tester.pumpWidget(
    _staffApp(
      gateway: gateway,
      screen: StaffApplicationReviewScreen(applicationId: applicationId),
      locale: locale,
      connectivity: connectivity,
    ),
  );
  await tester.pump();
  await tester.pump();
}

void _expectNoRawServerText() {
  for (final code in const ['42501', 'PGRST', 'SQLSTATE', 'Exception']) {
    expect(find.textContaining(code), findsNothing);
  }
}

void main() {
  group('P2-E2 Staff queue remote-read presentation', () {
    testWidgets('renders known-good rows on a healthy load with no notice', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        pageResults: [StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1')]))],
      );
      await _pumpQueue(tester, gateway);
      await tester.pumpAndSettle();

      expect(find.text('A1'), findsOneWidget);
      expect(find.byType(StaffRemoteReadNotice), findsNothing);
      expect(find.byType(RemoteDataNotice), findsNothing);
      expect(gateway.mutationActions, isEmpty);
    });

    testWidgets('authoritative empty renders the empty-queue copy only', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        pageResults: [
          StaffReadSuccess(_pageOf(const <StaffApplicationSummary>[])),
        ],
      );
      await _pumpQueue(tester, gateway);
      await tester.pumpAndSettle();

      expect(find.text(Ar.staffEmptyQueue), findsOneWidget);
      expect(find.byType(StaffRemoteReadNotice), findsNothing);
      expect(find.byType(RemoteDataNotice), findsNothing);
    });

    testWidgets(
      'failed refresh with known-good rows keeps rows and shows exactly one '
      'compact notice; retry recovers and never mutates',
      (tester) async {
      var calls = 0;
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        pageRead: (cursor) async {
          calls++;
          if (calls == 1) {
            return StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1')]));
          }
          if (calls == 2) {
            return const StaffRemoteReadFailure<StaffApplicationPage>(
              StaffRemoteReadFailureKind.network,
            );
          }
          return StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1')]));
        },
      );
        await _pumpQueue(tester, gateway);
        await tester.pumpAndSettle();
        expect(find.text('A1'), findsOneWidget);
        expect(gateway.listCalls, 1);

        final queue =
            tester.element(find.byType(StaffApplicationQueueScreen)).read<
              StaffApplicationQueueProvider
            >();
        await queue.refresh();
        await tester.pumpAndSettle();

        expect(find.text('A1'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsOneWidget);
        expect(find.byType(RemoteDataNotice), findsOneWidget);
        expect(find.text(Ar.noticeNetwork), findsOneWidget);

        await tester.tap(find.text(Ar.retry));
        await tester.pumpAndSettle();

        expect(find.text('A1'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
        expect(find.byType(RemoteDataNotice), findsNothing);
        expect(gateway.listCalls, 3);
        expect(gateway.mutationActions, isEmpty);
      },
    );

    testWidgets(
      'refreshing with known-good rows shows a slim progress line and keeps '
      'the rows',
      (tester) async {
        final gate = Completer<StaffReadResult<StaffApplicationPage>>();
        var calls = 0;
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          pageRead: (cursor) {
            calls++;
            if (calls == 1) {
              return Future.value(
                StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1')])),
              );
            }
            return gate.future;
          },
        );
        await _pumpQueue(tester, gateway);
        await tester.pumpAndSettle();

        final queue =
            tester.element(find.byType(StaffApplicationQueueScreen)).read<
              StaffApplicationQueueProvider
            >();
        queue.refresh();
        await tester.pump();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('A1'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);

        gate.complete(StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1b')])));
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.text('A1b'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
      },
    );

    testWidgets(
      'initial no-data remote failure shows a full notice and retry reloads '
      'the rows',
      (tester) async {
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          pageResults: [
            const StaffRemoteReadFailure<StaffApplicationPage>(
              StaffRemoteReadFailureKind.timeout,
            ),
            StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1')])),
          ],
        );
        await _pumpQueue(tester, gateway);
        await tester.pumpAndSettle();

        expect(find.byType(StaffRemoteReadNotice), findsOneWidget);
        expect(find.byType(RemoteDataNotice), findsOneWidget);
        expect(find.text(Ar.noticeTimeout), findsOneWidget);
        expect(find.text('A1'), findsNothing);
        _expectNoRawServerText();

        await tester.tap(find.text(Ar.retry));
        await tester.pumpAndSettle();

        expect(find.text('A1'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
        expect(gateway.mutationActions, isEmpty);
      },
    );

    testWidgets(
      'network failure with confirmed unavailable connectivity renders '
      'offline copy only',
      (tester) async {
        final connectivity = _connectivitySource(available: false);
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          pageResults: [
            const StaffRemoteReadFailure<StaffApplicationPage>(
              StaffRemoteReadFailureKind.network,
            ),
          ],
        );
        await _pumpQueue(tester, gateway, connectivity: connectivity.provider);
        await tester.pumpAndSettle();

        expect(find.text(Ar.noticeOffline), findsOneWidget);
        expect(find.text(Ar.noticeNetwork), findsNothing);
        expect(find.byType(TransportStatusBanner), findsNothing);
      },
    );

    testWidgets(
      'network failure with available connectivity stays network (not offline)',
      (tester) async {
        final connectivity = _connectivitySource(available: true);
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          pageResults: [
            const StaffRemoteReadFailure<StaffApplicationPage>(
              StaffRemoteReadFailureKind.network,
            ),
          ],
        );
        await _pumpQueue(tester, gateway, connectivity: connectivity.provider);
        await tester.pumpAndSettle();

        expect(find.text(Ar.noticeNetwork), findsOneWidget);
        expect(find.text(Ar.noticeOffline), findsNothing);
      },
    );

    testWidgets('network failure without connectivity provider stays network', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        pageResults: [
          const StaffRemoteReadFailure<StaffApplicationPage>(
            StaffRemoteReadFailureKind.network,
          ),
        ],
      );
      await _pumpQueue(tester, gateway);
      await tester.pumpAndSettle();

      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.text(Ar.noticeOffline), findsNothing);
    });

    testWidgets(
      'non-network kinds are never promoted to offline even when confirmed '
      'unavailable',
      (tester) async {
        final connectivity = _connectivitySource(available: false);
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          pageResults: [
            const StaffRemoteReadFailure<StaffApplicationPage>(
              StaffRemoteReadFailureKind.timeout,
            ),
          ],
        );
        await _pumpQueue(tester, gateway, connectivity: connectivity.provider);
        await tester.pumpAndSettle();

        expect(find.text(Ar.noticeTimeout), findsOneWidget);
        expect(find.text(Ar.noticeOffline), findsNothing);
        expect(find.text(Ar.noticeNetwork), findsNothing);
      },
    );

    testWidgets('reconnect alone issues zero new queue reads', (tester) async {
      final connectivitySource = _connectivitySource(available: false);
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        pageResults: [
          const StaffRemoteReadFailure<StaffApplicationPage>(
            StaffRemoteReadFailureKind.network,
          ),
          StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1')])),
        ],
      );
      await _pumpQueue(
        tester,
        gateway,
        connectivity: connectivitySource.provider,
      );
      await tester.pumpAndSettle();
      expect(find.text(Ar.noticeOffline), findsOneWidget);
      expect(gateway.listCalls, 1);

      connectivitySource.source.available = true;
      connectivitySource.source.changes.add(true);
      await tester.pumpAndSettle();

      expect(gateway.listCalls, 1);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.text('A1'), findsNothing);
    });

    testWidgets('permission loss clears stale rows and shows access denied', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        pageResults: [
          StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1')])),
          const StaffReadDenied(
            BusinessApplicationStaffCause.staffPermissionDenied,
          ),
        ],
      );
      await _pumpQueue(tester, gateway);
      await tester.pumpAndSettle();
      expect(find.text('A1'), findsOneWidget);

      final queue =
          tester.element(find.byType(StaffApplicationQueueScreen)).read<
            StaffApplicationQueueProvider
          >();
      await queue.refresh();
      await tester.pumpAndSettle();

      expect(find.text(Ar.staffAccessDenied), findsOneWidget);
      expect(find.text('A1'), findsNothing);
      expect(find.byType(StaffRemoteReadNotice), findsNothing);
    });

    testWidgets(
      'filter switch reloads and never masquerades prior-key rows',
      (tester) async {
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          pageResults: [
            StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1')])),
            StaffReadSuccess(_pageOf([_summary(_appY, name: 'A2-approved')])),
          ],
        );
        await _pumpQueue(tester, gateway);
        await tester.pumpAndSettle();
        expect(find.text('A1'), findsOneWidget);
        expect(gateway.statusFiltersRequested.last, isNull);

        await tester.tap(find.text(Ar.staffFilterApproved));
        await tester.pump();

        // Loading with the new key: old rows must not linger.
        expect(find.text('A1'), findsNothing);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);

        await tester.pumpAndSettle();
        expect(gateway.statusFiltersRequested.last,
            BusinessApplicationStatus.approved);
        expect(find.text('A2-approved'), findsOneWidget);
        expect(find.text('A1'), findsNothing);
      },
    );

    testWidgets(
      'load-more remote failure keeps loaded rows and shows a compact notice '
      'in the footer; retry appends the next page',
      (tester) async {
        final gateFail = Completer<StaffReadResult<StaffApplicationPage>>();
        final gateAppend = Completer<StaffReadResult<StaffApplicationPage>>();
        final cursor = StaffApplicationCursor(createdAt: _now, id: _appX);
        var calls = 0;
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          pageRead: (c) {
            calls++;
            if (calls == 1) {
              return Future.value(
                StaffReadSuccess(
                  _pageOf([_summary(_appX, name: 'A1')], next: cursor),
                ),
              );
            }
            if (calls == 2) return gateFail.future;
            return gateAppend.future;
          },
        );
        await _pumpQueue(tester, gateway);
        await tester.pumpAndSettle();
        expect(find.text('A1'), findsOneWidget);
        expect(find.text(Ar.staffLoadMore), findsOneWidget);

        await tester.tap(find.text(Ar.staffLoadMore));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('A1'), findsOneWidget);

        gateFail.complete(
          const StaffRemoteReadFailure<StaffApplicationPage>(
            StaffRemoteReadFailureKind.serviceUnavailable,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('A1'), findsOneWidget);
        expect(find.text(Ar.noticeServiceUnavailable), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsOneWidget);

        await tester.tap(find.text(Ar.retry));
        await tester.pump();

        gateAppend.complete(StaffReadSuccess(_pageOf([_summary(_appY, name: 'A2')])));
        await tester.pumpAndSettle();

        expect(find.text('A1'), findsOneWidget);
        expect(find.text('A2'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
      },
    );

    testWidgets(
      'access-level remote failure shows a full notice and retry recovers '
      'and loads the queue',
      (tester) async {
        final gateway = _FakeStaffGateway(
          capabilitiesResults: [
            const StaffRemoteReadFailure<StaffApplicationCapabilities>(
              StaffRemoteReadFailureKind.network,
            ),
            StaffReadSuccess(_staffCapabilities),
          ],
          pageResults: [
            StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1')])),
          ],
        );
        await _pumpQueue(tester, gateway);
        await tester.pumpAndSettle();

        expect(find.byType(StaffRemoteReadNotice), findsOneWidget);
        expect(find.text(Ar.noticeNetwork), findsOneWidget);
        expect(find.text('A1'), findsNothing);

        await tester.tap(find.text(Ar.retry));
        await tester.pumpAndSettle();

        expect(gateway.getCapabilitiesCalls, 2);
        expect(find.text('A1'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
      },
    );

    testWidgets(
      'access-level StaffReadUnavailable renders the typed Staff domain '
      'message, never a remote notice',
      (tester) async {
        final gateway = _FakeStaffGateway(
          capabilitiesResults: [
            const StaffReadUnavailable<StaffApplicationCapabilities>(),
          ],
          pageResults: [
            StaffReadSuccess(_pageOf([_summary(_appX, name: 'A1')])),
          ],
        );
        await _pumpQueue(tester, gateway);
        await tester.pumpAndSettle();

        expect(find.byType(StaffRemoteReadNotice), findsNothing);
        expect(find.byType(RemoteDataNotice), findsNothing);
        expect(find.text(Ar.staffCauseUnexpected), findsOneWidget);
        _expectNoRawServerText();
      },
    );

    testWidgets('localized offline copy renders under the EN locale', (
      tester,
    ) async {
      final connectivity = _connectivitySource(available: false);
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        pageResults: [
          const StaffRemoteReadFailure<StaffApplicationPage>(
            StaffRemoteReadFailureKind.network,
          ),
        ],
      );
      await _pumpQueue(
        tester,
        gateway,
        locale: _en,
        connectivity: connectivity.provider,
      );
      await tester.pumpAndSettle();

      expect(find.text(En.noticeOffline), findsOneWidget);
      expect(find.text(Ar.noticeOffline), findsNothing);
      expect(find.text(En.retry), findsOneWidget);
    });
  });

  group('P2-E2 Staff detail remote-read presentation', () {
    testWidgets('renders known-good detail on a healthy load with no notice', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        detailResults: [StaffReadSuccess(_detail(_appX, name: 'Applicant X'))],
      );
      await _pumpReview(tester, gateway);
      await tester.pumpAndSettle();

      expect(find.text('Applicant X'), findsOneWidget);
      expect(find.byType(StaffRemoteReadNotice), findsNothing);
      expect(find.byType(RemoteDataNotice), findsNothing);
    });

    testWidgets('remote no-data failure shows a full notice and retry recovers', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        detailResults: [
          const StaffRemoteReadFailure<StaffApplicationDetail>(
            StaffRemoteReadFailureKind.network,
          ),
          StaffReadSuccess(_detail(_appX, name: 'Applicant X')),
        ],
      );
      await _pumpReview(tester, gateway);
      await tester.pumpAndSettle();

      expect(find.byType(StaffRemoteReadNotice), findsOneWidget);
      expect(find.text(Ar.noticeNetwork), findsOneWidget);
      expect(find.text('Applicant X'), findsNothing);
      _expectNoRawServerText();

      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(find.text('Applicant X'), findsOneWidget);
      expect(find.byType(StaffRemoteReadNotice), findsNothing);
      expect(gateway.mutationActions, isEmpty);
    });

    testWidgets(
      'non-authority domain denial with no known-good renders the typed Staff '
      'message with a Staff retry, never a remote notice',
      (tester) async {
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          detailResults: [
            const StaffReadDenied(BusinessApplicationStaffCause.invalidTransition),
          ],
        );
        await _pumpReview(tester, gateway);
        await tester.pumpAndSettle();

        expect(find.text(Ar.staffCauseInvalidTransition), findsOneWidget);
        expect(find.text(Ar.staffRetry), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
        expect(find.byType(RemoteDataNotice), findsNothing);
      },
    );

    testWidgets('authoritative notFound clears and shows the not-found copy', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        detailResults: [
          const StaffReadDenied(BusinessApplicationStaffCause.applicationNotFound),
        ],
      );
      await _pumpReview(tester, gateway);
      await tester.pumpAndSettle();

      expect(find.text(Ar.staffCauseNotFound), findsOneWidget);
      expect(find.byType(StaffRemoteReadNotice), findsNothing);
    });

    testWidgets(
      'failed refresh with known-good detail keeps the detail and shows a '
      'single compact notice; retry recovers',
      (tester) async {
        var calls = 0;
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          detailRead: (id) async {
            calls++;
            if (calls == 1) {
              return StaffReadSuccess(_detail(_appX, name: 'Applicant X'));
            }
            if (calls == 2) {
              return const StaffRemoteReadFailure<StaffApplicationDetail>(
                StaffRemoteReadFailureKind.timeout,
              );
            }
            return StaffReadSuccess(_detail(_appX, name: 'Applicant X'));
          },
        );
        await _pumpReview(tester, gateway);
        await tester.pumpAndSettle();
        expect(find.text('Applicant X'), findsOneWidget);

        final detailProvider =
            tester.element(find.byType(StaffApplicationReviewScreen)).read<
              StaffApplicationDetailProvider
            >();
        await detailProvider.refresh();
        await tester.pumpAndSettle();

        expect(find.text('Applicant X'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsOneWidget);
        expect(find.text(Ar.noticeTimeout), findsOneWidget);

        await tester.tap(find.text(Ar.retry));
        await tester.pumpAndSettle();

        expect(find.text('Applicant X'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
        expect(find.byType(RemoteDataNotice), findsNothing);
        expect(gateway.mutationActions, isEmpty);
      },
    );

    testWidgets(
      'refreshing with known-good detail shows a slim progress line and keeps '
      'the detail',
      (tester) async {
        final gate = Completer<StaffReadResult<StaffApplicationDetail>>();
        var calls = 0;
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          detailRead: (id) {
            calls++;
            if (calls == 1) {
              return Future.value(
                StaffReadSuccess(_detail(_appX, name: 'Applicant X')),
              );
            }
            return gate.future;
          },
        );
        await _pumpReview(tester, gateway);
        await tester.pumpAndSettle();

        final detailProvider =
            tester.element(find.byType(StaffApplicationReviewScreen)).read<
              StaffApplicationDetailProvider
            >();
        detailProvider.refresh();
        await tester.pump();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Applicant X'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);

        gate.complete(StaffReadSuccess(_detail(_appX, name: 'Applicant X2')));
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.text('Applicant X2'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
      },
    );

    testWidgets('permission loss clears the detail and shows access denied', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        detailResults: [
          StaffReadSuccess(_detail(_appX, name: 'Applicant X')),
          const StaffReadDenied(
            BusinessApplicationStaffCause.staffPermissionDenied,
          ),
        ],
      );
      await _pumpReview(tester, gateway);
      await tester.pumpAndSettle();
      expect(find.text('Applicant X'), findsOneWidget);

      final detailProvider =
          tester.element(find.byType(StaffApplicationReviewScreen)).read<
            StaffApplicationDetailProvider
          >();
      await detailProvider.refresh();
      await tester.pumpAndSettle();

      expect(find.text(Ar.staffAccessDenied), findsOneWidget);
      expect(find.text('Applicant X'), findsNothing);
      expect(find.byType(StaffRemoteReadNotice), findsNothing);
    });

    testWidgets(
      'resource switch X→Y must never masquerade the old detail',
      (tester) async {
        final gateY = Completer<StaffReadResult<StaffApplicationDetail>>();
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          detailRead: (id) {
            if (id == _appX) {
              return Future.value(
                StaffReadSuccess(_detail(_appX, name: 'Applicant X')),
              );
            }
            return gateY.future;
          },
        );
        await _pumpReview(tester, gateway);
        await tester.pumpAndSettle();
        expect(find.text('Applicant X'), findsOneWidget);

        final detailProvider =
            tester.element(find.byType(StaffApplicationReviewScreen)).read<
              StaffApplicationDetailProvider
            >();
        detailProvider.load(_appY);
        await tester.pump();

        expect(find.text('Applicant X'), findsNothing);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);

        gateY.complete(StaffReadSuccess(_detail(_appY, name: 'Applicant Y')));
        await tester.pumpAndSettle();

        expect(find.text('Applicant Y'), findsOneWidget);
        expect(find.text('Applicant X'), findsNothing);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
      },
    );

    testWidgets(
      'access-level remote failure shows a full notice and retry recovers '
      'and loads the detail',
      (tester) async {
        final gateway = _FakeStaffGateway(
          capabilitiesResults: [
            const StaffRemoteReadFailure<StaffApplicationCapabilities>(
              StaffRemoteReadFailureKind.network,
            ),
            StaffReadSuccess(_staffCapabilities),
          ],
          detailResults: [StaffReadSuccess(_detail(_appX, name: 'Applicant X'))],
        );
        await _pumpReview(tester, gateway);
        await tester.pumpAndSettle();

        expect(find.byType(StaffRemoteReadNotice), findsOneWidget);
        expect(find.text(Ar.noticeNetwork), findsOneWidget);
        expect(find.text('Applicant X'), findsNothing);

        await tester.tap(find.text(Ar.retry));
        await tester.pumpAndSettle();

        expect(gateway.getCapabilitiesCalls, 2);
        expect(find.text('Applicant X'), findsOneWidget);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
      },
    );

    testWidgets('malformed route id shows the not-found copy and never reads', (
      tester,
    ) async {
      final gateway = _FakeStaffGateway(
        capabilities: _staffCapabilities,
        detailResults: [StaffReadSuccess(_detail(_appX, name: 'Applicant X'))],
      );
      await _setTallViewport(tester);
      await tester.pumpWidget(
        _staffApp(
          gateway: gateway,
          screen: const StaffApplicationReviewScreen(applicationId: 'not-a-uuid'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.staffCauseNotFound), findsOneWidget);
      expect(gateway.detailCalls, 0);
    });

    testWidgets(
      'localized detail notice renders under the EN locale',
      (tester) async {
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          detailResults: [
            const StaffRemoteReadFailure<StaffApplicationDetail>(
              StaffRemoteReadFailureKind.timeout,
            ),
          ],
        );
        await _pumpReview(tester, gateway, locale: _en);
        await tester.pumpAndSettle();

        expect(find.text(En.noticeTimeout), findsOneWidget);
        expect(find.text(Ar.noticeTimeout), findsNothing);
        expect(find.text(En.retry), findsOneWidget);
      },
    );
  });

  group('P2-E2 post-mutation read presentation', () {
    testWidgets(
      'an accepted approve with a failing post-mutation reread keeps the '
      'accepted detail, shows only the refresh warning, and refresh recovers '
      'without a second mutation',
      (tester) async {
        final approved = _detail(
          _appX,
          name: 'Applicant X',
          status: BusinessApplicationStatus.approved,
        );
        final gateway = _FakeStaffGateway(
          capabilities: _staffCapabilities,
          detail: _detail(_appX, name: 'Applicant X'),
          postMutationDetailResult:
              const StaffRemoteReadFailure<StaffApplicationDetail>(
                StaffRemoteReadFailureKind.network,
              ),
          mutationResult: BusinessApplicationStaffSucceeded(
            _businessAppFromDetail(approved),
          ),
        );
        await _pumpReview(tester, gateway);
        await tester.pumpAndSettle();
        expect(find.text('Applicant X'), findsOneWidget);

        // Approve action → confirm dialog → confirm.
        await tester.tap(find.text(Ar.staffActionApprove));
        await tester.pumpAndSettle();
        expect(find.text(Ar.staffConfirmApprove), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, Ar.staffActionApprove));
        await tester.pumpAndSettle();

        expect(gateway.mutationActions, ['approve']);
        expect(find.text(Ar.staffRefreshAfterMutation), findsOneWidget);
        expect(find.text('Applicant X'), findsOneWidget);
        // The accepted detail is preserved: post-mutation failure presents the
        // refresh warning ONLY — never a duplicate remote notice.
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
        expect(find.text(Ar.noticeNetwork), findsNothing);
        expect(find.byType(TransportStatusBanner), findsNothing);

        await tester.tap(find.text(Ar.staffRefreshDetail));
        await tester.pumpAndSettle();

        expect(find.text('Applicant X'), findsOneWidget);
        expect(find.text(Ar.staffRefreshAfterMutation), findsNothing);
        expect(find.byType(StaffRemoteReadNotice), findsNothing);
        expect(gateway.mutationActions, ['approve']);
      },
    );
  });
}