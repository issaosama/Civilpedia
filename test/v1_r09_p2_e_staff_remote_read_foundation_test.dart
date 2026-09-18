import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/core/di/staff_operations_scope.dart';
import 'package:civilpedia/core/network/remote_operation_policy.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/business/data/staff_remote_read_classifier.dart';
import 'package:civilpedia/features/business/data/supabase_business_application_staff_gateway.dart';
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

const _userA = 'staff-a';
const _userB = 'staff-b';
const _appA = '00000000-0000-0000-0000-000000000001';
const _appB = '00000000-0000-0000-0000-000000000002';

final _capabilities = StaffApplicationCapabilities.tryFromJson(const {
  'permissions': [
    'business_applications.read',
    'business_applications.approve',
  ],
})!;

void main() {
  group('P2-E1 remote taxonomy and gateway boundary', () {
    test('taxonomy is the frozen seven kinds and has no offline value', () {
      expect(StaffRemoteReadFailureKind.values.map((value) => value.name), [
        'network',
        'timeout',
        'serviceUnavailable',
        'malformedResponse',
        'permissionDenied',
        'authRestricted',
        'unexpected',
      ]);
    });

    test('transport, timeout, malformed, and unknown map narrowly', () {
      expect(
        classifyStaffRemoteReadFailure(const SocketException('hidden')),
        StaffRemoteReadFailureKind.network,
      );
      expect(
        classifyStaffRemoteReadFailure(TimeoutException('hidden')),
        StaffRemoteReadFailureKind.timeout,
      );
      expect(
        classifyStaffRemoteReadFailure(const FormatException('hidden')),
        StaffRemoteReadFailureKind.malformedResponse,
      );
      expect(
        classifyStaffRemoteReadFailure(StateError('hidden')),
        StaffRemoteReadFailureKind.unexpected,
      );
    });

    test('only frozen availability code families map unavailable', () {
      for (final code in const [
        '08006',
        '53000',
        'PGRST000',
        'PGRST001',
        'PGRST002',
        'PGRST003',
      ]) {
        expect(
          classifyStaffRemoteReadFailure(
            PostgrestException(message: 'hidden', code: code),
          ),
          StaffRemoteReadFailureKind.serviceUnavailable,
          reason: code,
        );
      }
    });

    test('permission/auth mappings are source-aware', () {
      expect(
        classifyStaffRemoteReadFailure(
          const PostgrestException(message: 'hidden', code: '42501'),
        ),
        StaffRemoteReadFailureKind.permissionDenied,
      );
      for (final code in const ['PGRST301', 'PGRST302', 'PGRST303']) {
        expect(
          classifyStaffRemoteReadFailure(
            PostgrestException(message: 'hidden', code: code),
          ),
          StaffRemoteReadFailureKind.authRestricted,
        );
      }
      expect(
        classifyStaffRemoteReadFailure(
          const AuthException('hidden', statusCode: '401'),
        ),
        StaffRemoteReadFailureKind.authRestricted,
      );
      for (final code in const ['401', '503', 'P0AUT', 'P0PER', 'P0DAT']) {
        expect(
          classifyStaffRemoteReadFailure(
            PostgrestException(message: 'hidden', code: code),
          ),
          StaffRemoteReadFailureKind.unexpected,
          reason: code,
        );
      }
    });

    test('verified PostgREST response-shape codes require opt-in', () {
      const error = PostgrestException(message: 'hidden', code: 'PGRST116');
      expect(
        classifyStaffRemoteReadFailure(error),
        StaffRemoteReadFailureKind.unexpected,
      );
      expect(
        classifyStaffRemoteReadFailure(
          error,
          postgrestResponseShapeCodesAreMalformed: true,
        ),
        StaffRemoteReadFailureKind.malformedResponse,
      );
    });

    test(
      'canonical read policy is 15 seconds and injected expiry is typed',
      () async {
        expect(RemoteOperationPolicy.read, const Duration(seconds: 15));
        final never = Completer<http.Response>();
        final gateway = _productionGateway(
          MockClient((_) => never.future),
          readTimeout: const Duration(milliseconds: 1),
        );

        final result = await gateway.getCapabilities();

        expect(
          result,
          isA<StaffRemoteReadFailure<StaffApplicationCapabilities>>(),
        );
        expect(
          (result as StaffRemoteReadFailure<StaffApplicationCapabilities>).kind,
          StaffRemoteReadFailureKind.timeout,
        );
      },
    );

    test(
      'one malformed required queue row fails the complete response',
      () async {
        final gateway = _productionGateway(
          MockClient(
            (request) async => _jsonResponse({
              'items': [
                _summaryJson(_appA),
                {'id': _appB},
              ],
              'next_cursor': null,
            }, request: request),
          ),
        );

        final result = await gateway.listApplications();

        expect(
          (result as StaffRemoteReadFailure<StaffApplicationPage>).kind,
          StaffRemoteReadFailureKind.malformedResponse,
        );
      },
    );

    test(
      'detail canonical-id mismatch is malformed and never success',
      () async {
        final gateway = _productionGateway(
          MockClient(
            (request) async =>
                _jsonResponse(_detailJson(_appB), request: request),
          ),
        );

        final result = await gateway.getApplicationDetail(_appA);

        expect(
          (result as StaffRemoteReadFailure<StaffApplicationDetail>).kind,
          StaffRemoteReadFailureKind.malformedResponse,
        );
      },
    );

    test('P0DAT stays requiredDataMissing and never malformed', () async {
      final gateway = _productionGateway(
        MockClient(
          (request) async => _jsonResponse(
            {'message': 'hidden', 'code': 'P0DAT'},
            statusCode: 400,
            request: request,
          ),
        ),
      );

      final result = await gateway.listApplications();

      expect(result, isA<StaffReadDenied<StaffApplicationPage>>());
      expect(
        (result as StaffReadDenied<StaffApplicationPage>).cause,
        BusinessApplicationStaffCause.requiredDataMissing,
      );
    });

    test(
      'each Staff read RPC maps only migration-proven domain codes',
      () async {
        for (final entry in const {
          'P0AUT': BusinessApplicationStaffCause.unauthenticated,
        }.entries) {
          final result = await _productionGatewayReturningCode(
            entry.key,
          ).getCapabilities();
          _expectDenied(result, entry.value);
        }

        for (final entry in const {
          'P0AUT': BusinessApplicationStaffCause.unauthenticated,
          'P0PER': BusinessApplicationStaffCause.staffPermissionDenied,
          'P0DAT': BusinessApplicationStaffCause.requiredDataMissing,
        }.entries) {
          final result = await _productionGatewayReturningCode(
            entry.key,
          ).listApplications();
          _expectDenied(result, entry.value);
        }

        for (final entry in const {
          'P0AUT': BusinessApplicationStaffCause.unauthenticated,
          'P0PER': BusinessApplicationStaffCause.staffPermissionDenied,
          'P0NOT': BusinessApplicationStaffCause.applicationNotFound,
        }.entries) {
          final result = await _productionGatewayReturningCode(
            entry.key,
          ).getApplicationDetail(_appA);
          _expectDenied(result, entry.value);
        }
      },
    );

    test(
      'unproven Staff-looking codes are unexpected per source RPC',
      () async {
        final capability = await _productionGatewayReturningCode(
          'P0PER',
        ).getCapabilities();
        final queue = await _productionGatewayReturningCode(
          'P0NOT',
        ).listApplications();
        final detail = await _productionGatewayReturningCode(
          'P0DAT',
        ).getApplicationDetail(_appA);

        _expectUnexpectedRemote(capability);
        _expectUnexpectedRemote(queue);
        _expectUnexpectedRemote(detail);
      },
    );
  });

  group('P2-E1 exact keys, epochs, identity, and known-good data', () {
    test('capabilities same key coalesces one underlying RPC', () async {
      final auth = _TestAuthProvider(userId: _userA);
      final pending =
          Completer<StaffReadResult<StaffApplicationCapabilities>>();
      var calls = 0;
      final gateway = _FakeStaffGateway(
        capabilitiesRead: () {
          calls++;
          return pending.future;
        },
      );
      final provider = StaffAccessProvider(gateway: gateway, auth: auth);
      addTearDown(provider.dispose);

      final first = provider.load();
      final second = provider.load();
      expect(calls, 1);
      expect(provider.activeReadCount, 1);

      pending.complete(StaffReadSuccess(_capabilities));
      await Future.wait([first, second]);
      expect(provider.state, StaffAccessState.authorized);
    });

    test(
      'authoritative capability loss clears privileged state and blocks late reads',
      () async {
        final auth = _TestAuthProvider(userId: _userA);
        final queuePending = Completer<StaffReadResult<StaffApplicationPage>>();
        final detailPending =
            Completer<StaffReadResult<StaffApplicationDetail>>();
        var capabilityCalls = 0;
        var queueCalls = 0;
        var detailCalls = 0;
        final gateway = _FakeStaffGateway(
          capabilitiesRead: () async => capabilityCalls++ == 0
              ? StaffReadSuccess(_capabilities)
              : const StaffReadSuccess(StaffApplicationCapabilities.empty()),
          pageRead: (_, __, ___) => queueCalls++ == 0
              ? Future.value(StaffReadSuccess(_page(_summary(_appA))))
              : queuePending.future,
          detailRead: (_) => detailCalls++ == 0
              ? Future.value(
                  StaffReadSuccess(
                    _detail(_appA, BusinessApplicationStatus.submitted),
                  ),
                )
              : detailPending.future,
        );
        final scope = StaffOperationsScope(gateway: gateway, auth: auth);

        await scope.access.load();
        await scope.queue.loadInitial();
        await scope.detail.load(_appA);
        expect(scope.queue.items, isNotEmpty);
        expect(scope.detail.detail, isNotNull);

        final lateQueue = scope.queue.refresh();
        final lateDetail = scope.detail.refresh();
        await scope.access.load();

        expect(scope.access.state, StaffAccessState.noReadPermission);
        expect(scope.queue.items, isEmpty);
        expect(scope.queue.state, StaffQueueState.initial);
        expect(scope.detail.detail, isNull);
        expect(scope.detail.state, StaffDetailState.initial);

        queuePending.complete(StaffReadSuccess(_page(_summary(_appB))));
        detailPending.complete(
          StaffReadSuccess(_detail(_appB, BusinessApplicationStatus.approved)),
        );
        await Future.wait([lateQueue, lateDetail]);
        expect(scope.queue.items, isEmpty);
        expect(scope.detail.detail, isNull);

        _disposeScope(scope);
      },
    );

    test('capability remote failure does not clear privileged state', () async {
      final auth = _TestAuthProvider(userId: _userA);
      var capabilityCalls = 0;
      final gateway = _FakeStaffGateway(
        capabilitiesRead: () async => capabilityCalls++ == 0
            ? StaffReadSuccess(_capabilities)
            : const StaffRemoteReadFailure(StaffRemoteReadFailureKind.network),
        pageRead: (_, __, ___) async =>
            StaffReadSuccess(_page(_summary(_appA))),
        detailRead: (_) async => StaffReadSuccess(
          _detail(_appA, BusinessApplicationStatus.submitted),
        ),
      );
      final scope = StaffOperationsScope(gateway: gateway, auth: auth);
      await scope.access.load();
      await scope.queue.loadInitial();
      await scope.detail.load(_appA);

      await scope.access.load();

      expect(
        scope.access.lastRemoteFailure,
        StaffRemoteReadFailureKind.network,
      );
      expect(scope.queue.items.single.id, _appA);
      expect(scope.detail.detail?.id, _appA);
      _disposeScope(scope);
    });

    test(
      'queue same exact filter coalesces; different filter is independent',
      () async {
        final auth = _TestAuthProvider(userId: _userA);
        final first = Completer<StaffReadResult<StaffApplicationPage>>();
        final second = Completer<StaffReadResult<StaffApplicationPage>>();
        var calls = 0;
        final gateway = _FakeStaffGateway(
          pageRead: (_, __, ___) => calls++ == 0 ? first.future : second.future,
        );
        final provider = StaffApplicationQueueProvider(
          gateway: gateway,
          auth: auth,
        );
        addTearDown(provider.dispose);

        final a1 = provider.loadInitial();
        final a2 = provider.loadInitial();
        expect(calls, 1);
        final b = provider.setFilter(
          const StaffApplicationQueueFilter(
            status: BusinessApplicationStatus.approved,
          ),
        );
        expect(calls, 2);

        first.complete(StaffReadSuccess(_page(_summary(_appA))));
        await Future.wait([a1, a2]);
        expect(provider.activeReadCount, 1, reason: 'old cleanup owns only A');
        expect(provider.items, isEmpty, reason: 'A cannot publish into B');

        second.complete(StaffReadSuccess(_page(_summary(_appB))));
        await b;
        expect(provider.items.single.id, _appB);
      },
    );

    test('queue A -> B -> A retires the superseded A handle', () async {
      final auth = _TestAuthProvider(userId: _userA);
      final oldA = Completer<StaffReadResult<StaffApplicationPage>>();
      final b = Completer<StaffReadResult<StaffApplicationPage>>();
      final freshA = Completer<StaffReadResult<StaffApplicationPage>>();
      final pending = [oldA, b, freshA];
      var calls = 0;
      final provider = StaffApplicationQueueProvider(
        gateway: _FakeStaffGateway(
          pageRead: (_, __, ___) => pending[calls++].future,
        ),
        auth: auth,
      );
      addTearDown(provider.dispose);

      final oldARead = provider.loadInitial();
      final bRead = provider.setFilter(
        const StaffApplicationQueueFilter(
          status: BusinessApplicationStatus.approved,
        ),
      );
      final freshARead = provider.setFilter(
        const StaffApplicationQueueFilter(),
      );
      expect(calls, 3, reason: 'fresh A must not join superseded old A');

      oldA.complete(StaffReadSuccess(_page(_summary(_appA))));
      await oldARead;
      expect(provider.items, isEmpty);
      expect(provider.activeReadCount, 2);

      b.complete(StaffReadSuccess(_page(_summary(_appB))));
      await bRead;
      expect(provider.items, isEmpty);

      freshA.complete(StaffReadSuccess(_page(_summary(_appA))));
      await freshARead;
      expect(provider.items.single.id, _appA);
    });

    test(
      'queue matching refresh and remote failure preserve known-good data',
      () async {
        final auth = _TestAuthProvider(userId: _userA);
        final results = <StaffReadResult<StaffApplicationPage>>[
          StaffReadSuccess(_page(_summary(_appA))),
          const StaffRemoteReadFailure(StaffRemoteReadFailureKind.network),
        ];
        final gateway = _FakeStaffGateway(
          pageRead: (_, __, ___) async => results.removeAt(0),
        );
        final provider = StaffApplicationQueueProvider(
          gateway: gateway,
          auth: auth,
        );
        addTearDown(provider.dispose);

        await provider.loadInitial();
        final refresh = provider.refresh();
        expect(provider.readPhase, StaffRemoteReadPhase.refreshing);
        expect(provider.items.single.id, _appA);
        await refresh;

        expect(provider.items.single.id, _appA);
        expect(provider.state, StaffQueueState.data);
        expect(provider.lastRemoteFailure, StaffRemoteReadFailureKind.network);
        expect(provider.readPhase, StaffRemoteReadPhase.failed);
      },
    );

    test('queue authoritative empty is absence, not failure', () async {
      final provider = StaffApplicationQueueProvider(
        gateway: _FakeStaffGateway(
          pageRead: (_, __, ___) async =>
              const StaffReadSuccess(StaffApplicationPage(items: [])),
        ),
        auth: _TestAuthProvider(userId: _userA),
      );
      addTearDown(provider.dispose);

      await provider.loadInitial();

      expect(provider.state, StaffQueueState.empty);
      expect(provider.readPhase, StaffRemoteReadPhase.authoritativeEmpty);
      expect(provider.lastRemoteFailure, isNull);
    });

    test('queue mutation revision suppresses every older completion', () async {
      final auth = _TestAuthProvider(userId: _userA);
      final stale = Completer<StaffReadResult<StaffApplicationPage>>();
      final fresh = Completer<StaffReadResult<StaffApplicationPage>>();
      var calls = 0;
      final gateway = _FakeStaffGateway(
        pageRead: (_, __, ___) {
          calls++;
          if (calls == 1)
            return Future.value(StaffReadSuccess(_page(_summary(_appA))));
          return calls == 2 ? stale.future : fresh.future;
        },
      );
      final provider = StaffApplicationQueueProvider(
        gateway: gateway,
        auth: auth,
      );
      addTearDown(provider.dispose);
      await provider.loadInitial();

      final oldRefresh = provider.refresh();
      final committedRefresh = provider.onMutationCommitted();
      expect(provider.reviewRevision, 1);
      stale.complete(
        const StaffRemoteReadFailure(StaffRemoteReadFailureKind.network),
      );
      await oldRefresh;
      expect(provider.lastRemoteFailure, isNull);

      fresh.complete(StaffReadSuccess(_page(_summary(_appB))));
      await committedRefresh;
      expect(provider.items.single.id, _appB);
    });

    test('pagination coalesces only the same current cursor key', () async {
      final cursor1 = StaffApplicationCursor(
        createdAt: DateTime.utc(2024, 1, 1),
        id: _appA,
      );
      final cursor2 = StaffApplicationCursor(
        createdAt: DateTime.utc(2024, 1, 2),
        id: _appB,
      );
      final page1 = Completer<StaffReadResult<StaffApplicationPage>>();
      final page2 = Completer<StaffReadResult<StaffApplicationPage>>();
      var calls = 0;
      final provider = StaffApplicationQueueProvider(
        gateway: _FakeStaffGateway(
          pageRead: (_, __, cursor) {
            calls++;
            if (cursor == null) {
              return Future.value(
                StaffReadSuccess(
                  StaffApplicationPage(
                    items: [_summary(_appA)],
                    nextCursor: cursor1,
                  ),
                ),
              );
            }
            return cursor.id == cursor1.id ? page1.future : page2.future;
          },
        ),
        auth: _TestAuthProvider(userId: _userA),
      );
      addTearDown(provider.dispose);
      await provider.loadInitial();

      final first = provider.loadMore();
      final joined = provider.loadMore();
      expect(calls, 2, reason: 'same active cursor must not duplicate');

      page1.complete(
        StaffReadSuccess(
          StaffApplicationPage(items: [_summary(_appB)], nextCursor: cursor2),
        ),
      );
      await Future.wait([first, joined]);

      final differentCursor = provider.loadMore();
      expect(calls, 3, reason: 'new cursor is a different exact key');
      page2.complete(const StaffReadSuccess(StaffApplicationPage(items: [])));
      await differentCursor;
    });

    test(
      'stale pagination cannot publish into a different filter scope',
      () async {
        final cursor = StaffApplicationCursor(
          createdAt: DateTime.utc(2024, 1, 1),
          id: _appA,
        );
        final stalePage = Completer<StaffReadResult<StaffApplicationPage>>();
        final filteredPage = Completer<StaffReadResult<StaffApplicationPage>>();
        var calls = 0;
        final provider = StaffApplicationQueueProvider(
          gateway: _FakeStaffGateway(
            pageRead: (status, _, requestedCursor) {
              calls++;
              if (calls == 1) {
                return Future.value(
                  StaffReadSuccess(
                    StaffApplicationPage(
                      items: [_summary(_appA)],
                      nextCursor: cursor,
                    ),
                  ),
                );
              }
              return status == BusinessApplicationStatus.approved
                  ? filteredPage.future
                  : stalePage.future;
            },
          ),
          auth: _TestAuthProvider(userId: _userA),
        );
        addTearDown(provider.dispose);
        await provider.loadInitial();

        final pagination = provider.loadMore();
        final filtered = provider.setFilter(
          const StaffApplicationQueueFilter(
            status: BusinessApplicationStatus.approved,
          ),
        );
        expect(calls, 3);

        stalePage.complete(StaffReadSuccess(_page(_summary(_appB))));
        await pagination;
        expect(provider.items, isEmpty);

        filteredPage.complete(StaffReadSuccess(_page(_summary(_appA))));
        await filtered;
        expect(provider.items.single.id, _appA);
        expect(provider.filter.status, BusinessApplicationStatus.approved);
      },
    );

    test(
      'detail resource switch suppresses late data and foreign cleanup',
      () async {
        final auth = _TestAuthProvider(userId: _userA);
        final a = Completer<StaffReadResult<StaffApplicationDetail>>();
        final b = Completer<StaffReadResult<StaffApplicationDetail>>();
        final gateway = _FakeStaffGateway(
          detailRead: (id) => id == _appA ? a.future : b.future,
        );
        final provider = StaffApplicationDetailProvider(
          gateway: gateway,
          auth: auth,
        );
        addTearDown(provider.dispose);

        final readA = provider.load(_appA);
        final readB = provider.load(_appB);
        a.complete(
          StaffReadSuccess(_detail(_appA, BusinessApplicationStatus.submitted)),
        );
        await readA;
        expect(provider.activeReadCount, 1);
        expect(provider.detail, isNull);

        b.complete(
          StaffReadSuccess(_detail(_appB, BusinessApplicationStatus.approved)),
        );
        await readB;
        expect(provider.detail?.id, _appB);
      },
    );

    test('detail X -> Y -> X retires the superseded X handle', () async {
      final auth = _TestAuthProvider(userId: _userA);
      final oldX = Completer<StaffReadResult<StaffApplicationDetail>>();
      final y = Completer<StaffReadResult<StaffApplicationDetail>>();
      final freshX = Completer<StaffReadResult<StaffApplicationDetail>>();
      final pending = [oldX, y, freshX];
      var calls = 0;
      final provider = StaffApplicationDetailProvider(
        gateway: _FakeStaffGateway(detailRead: (_) => pending[calls++].future),
        auth: auth,
      );
      addTearDown(provider.dispose);

      final oldXRead = provider.load(_appA);
      final yRead = provider.load(_appB);
      final freshXRead = provider.load(_appA);
      expect(calls, 3, reason: 'fresh X must not join superseded old X');

      oldX.complete(
        StaffReadSuccess(_detail(_appA, BusinessApplicationStatus.submitted)),
      );
      await oldXRead;
      expect(provider.detail, isNull);
      expect(provider.activeReadCount, 2);

      y.complete(
        StaffReadSuccess(_detail(_appB, BusinessApplicationStatus.approved)),
      );
      await yRead;
      expect(provider.detail, isNull);

      freshX.complete(
        StaffReadSuccess(_detail(_appA, BusinessApplicationStatus.underReview)),
      );
      await freshXRead;
      expect(provider.detail?.id, _appA);
      expect(provider.detail?.status, BusinessApplicationStatus.underReview);
    });

    test('detail matching refresh failure preserves known-good data', () async {
      final results = <StaffReadResult<StaffApplicationDetail>>[
        StaffReadSuccess(_detail(_appA, BusinessApplicationStatus.submitted)),
        const StaffRemoteReadFailure(StaffRemoteReadFailureKind.timeout),
      ];
      final provider = StaffApplicationDetailProvider(
        gateway: _FakeStaffGateway(
          detailRead: (_) async => results.removeAt(0),
        ),
        auth: _TestAuthProvider(userId: _userA),
      );
      addTearDown(provider.dispose);
      await provider.load(_appA);

      final refresh = provider.refresh();
      expect(provider.readPhase, StaffRemoteReadPhase.refreshing);
      expect(provider.detail?.id, _appA);
      await refresh;

      expect(provider.detail?.id, _appA);
      expect(provider.state, StaffDetailState.data);
      expect(provider.lastRemoteFailure, StaffRemoteReadFailureKind.timeout);
    });

    test(
      'detail mismatch from a fake boundary is malformed with no publication',
      () async {
        final provider = StaffApplicationDetailProvider(
          gateway: _FakeStaffGateway(
            detailRead: (_) async => StaffReadSuccess(
              _detail(_appB, BusinessApplicationStatus.submitted),
            ),
          ),
          auth: _TestAuthProvider(userId: _userA),
        );
        addTearDown(provider.dispose);

        await provider.load(_appA);

        expect(provider.detail, isNull);
        expect(provider.state, StaffDetailState.error);
        expect(
          provider.lastRemoteFailure,
          StaffRemoteReadFailureKind.malformedResponse,
        );
      },
    );

    test('accepted mutation suppresses pre-mutation detail read', () async {
      final stale = Completer<StaffReadResult<StaffApplicationDetail>>();
      final postMutation = Completer<StaffReadResult<StaffApplicationDetail>>();
      var reads = 0;
      final gateway = _FakeStaffGateway(
        detailRead: (_) {
          reads++;
          if (reads == 1) {
            return Future.value(
              StaffReadSuccess(
                _detail(_appA, BusinessApplicationStatus.submitted),
              ),
            );
          }
          return reads == 2 ? stale.future : postMutation.future;
        },
        mutationResult: BusinessApplicationStaffSucceeded(
          _businessApplication(BusinessApplicationStatus.approved),
        ),
      );
      final provider = StaffApplicationDetailProvider(
        gateway: gateway,
        auth: _TestAuthProvider(userId: _userA),
      );
      addTearDown(provider.dispose);
      await provider.load(_appA);

      final oldRead = provider.refresh();
      final mutation = provider.approve();
      expect(provider.reviewRevision, 1);
      stale.complete(
        const StaffReadDenied(
          BusinessApplicationStaffCause.applicationNotFound,
        ),
      );
      await oldRead;
      expect(provider.state, StaffDetailState.mutating);

      postMutation.complete(
        StaffReadSuccess(_detail(_appA, BusinessApplicationStatus.approved)),
      );
      expect(await mutation, isTrue);
      expect(provider.detail?.status, BusinessApplicationStatus.approved);
    });

    test(
      'accepted mutation remains committed when follow-up detail read fails',
      () async {
        final results = <StaffReadResult<StaffApplicationDetail>>[
          StaffReadSuccess(
            _detail(_appA, BusinessApplicationStatus.underReview),
          ),
          const StaffRemoteReadFailure(StaffRemoteReadFailureKind.timeout),
        ];
        final provider = StaffApplicationDetailProvider(
          gateway: _FakeStaffGateway(
            detailRead: (_) async => results.removeAt(0),
            mutationResult: BusinessApplicationStaffSucceeded(
              _businessApplication(BusinessApplicationStatus.approved),
            ),
          ),
          auth: _TestAuthProvider(userId: _userA),
        );
        addTearDown(provider.dispose);
        await provider.load(_appA);

        expect(await provider.approve(), isFalse);

        expect(provider.mutationSucceeded, isTrue);
        expect(provider.state, StaffDetailState.refreshAfterMutationError);
        expect(provider.detail?.status, BusinessApplicationStatus.underReview);
        expect(provider.lastRemoteFailure, StaffRemoteReadFailureKind.timeout);
      },
    );

    test('failed mutation does not fabricate accepted outcome', () async {
      final provider = StaffApplicationDetailProvider(
        gateway: _FakeStaffGateway(
          detailRead: (_) async => StaffReadSuccess(
            _detail(_appA, BusinessApplicationStatus.underReview),
          ),
          mutationResult: const BusinessApplicationStaffDenied(
            BusinessApplicationStaffCause.invalidTransition,
          ),
        ),
        auth: _TestAuthProvider(userId: _userA),
      );
      addTearDown(provider.dispose);
      await provider.load(_appA);

      expect(await provider.approve(), isFalse);

      expect(provider.mutationSucceeded, isFalse);
      expect(provider.state, StaffDetailState.mutationError);
      expect(provider.detail?.status, BusinessApplicationStatus.underReview);
      expect(
        provider.lastErrorCause,
        BusinessApplicationStaffCause.invalidTransition,
      );
    });

    test(
      'User A and B reads are independent; late A cannot publish into B',
      () async {
        final auth = _TestAuthProvider(userId: _userA);
        final a = Completer<StaffReadResult<StaffApplicationPage>>();
        final b = Completer<StaffReadResult<StaffApplicationPage>>();
        var calls = 0;
        final provider = StaffApplicationQueueProvider(
          gateway: _FakeStaffGateway(
            pageRead: (_, __, ___) => calls++ == 0 ? a.future : b.future,
          ),
          auth: auth,
        );
        addTearDown(provider.dispose);

        final readA = provider.loadInitial();
        auth.setUser(_userB);
        final readB = provider.loadInitial();
        expect(calls, 2);

        b.complete(StaffReadSuccess(_page(_summary(_appB))));
        await readB;
        a.complete(StaffReadSuccess(_page(_summary(_appA))));
        await readA;
        expect(provider.items.single.id, _appB);
      },
    );

    test('same user with a new auth generation starts independently', () async {
      final auth = _TestAuthProvider(userId: _userA);
      final oldGeneration = Completer<StaffReadResult<StaffApplicationPage>>();
      final newGeneration = Completer<StaffReadResult<StaffApplicationPage>>();
      var calls = 0;
      final provider = StaffApplicationQueueProvider(
        gateway: _FakeStaffGateway(
          pageRead: (_, __, ___) =>
              calls++ == 0 ? oldGeneration.future : newGeneration.future,
        ),
        auth: auth,
      );
      addTearDown(provider.dispose);

      final oldRead = provider.loadInitial();
      auth.bumpGeneration();
      final newRead = provider.loadInitial();
      expect(calls, 2);

      newGeneration.complete(StaffReadSuccess(_page(_summary(_appB))));
      await newRead;
      oldGeneration.complete(StaffReadSuccess(_page(_summary(_appA))));
      await oldRead;
      expect(provider.items.single.id, _appB);
    });

    test(
      'sign-out and disposal both suppress late authenticated publication',
      () async {
        final auth = _TestAuthProvider(userId: _userA);
        final pending = Completer<StaffReadResult<StaffApplicationPage>>();
        final gateway = _FakeStaffGateway(
          pageRead: (_, __, ___) => pending.future,
        );
        final scope = StaffOperationsScope(gateway: gateway, auth: auth);
        await scope.access.load();
        final read = scope.queue.loadInitial();

        auth.setUser(null);
        pending.complete(StaffReadSuccess(_page(_summary(_appA))));
        await read;
        expect(scope.queue.items, isEmpty);
        expect(scope.queue.state, StaffQueueState.initial);

        final detailPending =
            Completer<StaffReadResult<StaffApplicationDetail>>();
        auth.setUser(_userA);
        final detail = StaffApplicationDetailProvider(
          gateway: _FakeStaffGateway(detailRead: (_) => detailPending.future),
          auth: auth,
        );
        var notifications = 0;
        detail.addListener(() => notifications++);
        final detailRead = detail.load(_appA);
        final beforeDispose = notifications;
        detail.dispose();
        detailPending.complete(
          StaffReadSuccess(_detail(_appA, BusinessApplicationStatus.submitted)),
        );
        await detailRead;
        expect(notifications, beforeDispose);

        scope.detail.dispose();
        scope.queue.dispose();
        scope.access.dispose();
        scope.dispose();
      },
    );
  });
}

class _InitializedService extends SupabaseService {
  _InitializedService()
    : super(
        config: const BackendConfig(
          appEnvRaw: 'development',
          supabaseUrl: 'http://localhost:54321',
          supabaseAnonKey: 'anon',
        ),
      );

  @override
  bool get isInitialized => true;
}

SupabaseBusinessApplicationStaffGateway _productionGateway(
  http.Client httpClient, {
  Duration readTimeout = RemoteOperationPolicy.read,
}) {
  return SupabaseBusinessApplicationStaffGateway(
    service: _InitializedService(),
    client: SupabaseClient(
      'http://localhost:54321',
      'anon',
      httpClient: httpClient,
    ),
    readTimeout: readTimeout,
  );
}

SupabaseBusinessApplicationStaffGateway _productionGatewayReturningCode(
  String code,
) {
  return _productionGateway(
    MockClient(
      (request) async => _jsonResponse(
        {'message': 'hidden', 'code': code},
        statusCode: 400,
        request: request,
      ),
    ),
  );
}

void _expectDenied<T>(
  StaffReadResult<T> result,
  BusinessApplicationStaffCause cause,
) {
  expect(result, isA<StaffReadDenied<T>>());
  expect((result as StaffReadDenied<T>).cause, cause);
}

void _expectUnexpectedRemote<T>(StaffReadResult<T> result) {
  expect(result, isA<StaffRemoteReadFailure<T>>());
  expect(
    (result as StaffRemoteReadFailure<T>).kind,
    StaffRemoteReadFailureKind.unexpected,
  );
}

http.Response _jsonResponse(
  Object? body, {
  int statusCode = 200,
  http.BaseRequest? request,
}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
    request: request,
  );
}

Map<String, dynamic> _summaryJson(String id) => {
  'id': id,
  'application_type': 'NEW',
  'status': 'SUBMITTED',
  'created_at': '2024-01-01T00:00:00.000Z',
  'updated_at': '2024-01-01T00:00:00.000Z',
  'new_business': {'name': 'Business'},
  'claim_target': null,
};

Map<String, dynamic> _detailJson(String id) => {
  'application': {
    'id': id,
    'application_type': 'NEW',
    'status': 'SUBMITTED',
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-01T00:00:00.000Z',
  },
  'applicant': {'display_name': 'Applicant', 'phone': null},
  'new_business': {'name': 'Business'},
  'claim_target': null,
  'contacts': <Object?>[],
  'visits': <Object?>[],
};

StaffApplicationSummary _summary(String id) {
  return StaffApplicationSummary(
    id: id,
    type: BusinessApplicationType.newApplication,
    status: BusinessApplicationStatus.submitted,
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
}

StaffApplicationPage _page(StaffApplicationSummary summary) {
  return StaffApplicationPage(items: [summary]);
}

StaffApplicationDetail _detail(String id, BusinessApplicationStatus status) {
  return StaffApplicationDetail(
    id: id,
    type: BusinessApplicationType.newApplication,
    status: status,
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
    applicantDisplayName: 'Applicant',
  );
}

BusinessApplication _businessApplication(BusinessApplicationStatus status) {
  return BusinessApplication(
    id: _appA,
    applicantUserId: _userA,
    type: BusinessApplicationType.newApplication,
    status: status,
    metadata: const {'name': 'Business'},
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
}

void _disposeScope(StaffOperationsScope scope) {
  scope.detail.dispose();
  scope.queue.dispose();
  scope.access.dispose();
  scope.dispose();
}

class _TestAuthGateway implements AuthGateway {
  @override
  bool get isAvailable => true;
  @override
  bool get canAccountAuthorityBeGranted => true;
  @override
  bool get isAuthObservationAvailable => true;
  @override
  bool get isLogoutCleanupBlocked => false;
  @override
  Stream<AuthEvent> get authEvents => const Stream.empty();
  @override
  Future<bool> retryAuthCleanup() async => false;
  @override
  Future<AuthSession?> restoreSession() async => null;
  @override
  Future<AuthSession?> signInWithGoogle() async => null;
  @override
  Future<void> signOut() async {}
  @override
  void dispose() {}
}

class _TestAuthProvider extends AuthProvider {
  _TestAuthProvider({String? userId})
    : _session = userId == null
          ? null
          : AuthSession(
              userId: userId,
              email: '$userId@example.com',
              displayName: userId,
            ),
      super(gateway: _TestAuthGateway());

  AuthSession? _session;
  int _testGeneration = 1;

  @override
  AuthSession? get session => _session;
  @override
  bool get isLoggedIn => _session != null;
  @override
  AuthStatus get status =>
      _session == null ? AuthStatus.guest : AuthStatus.authenticated;
  @override
  int get generation => _testGeneration;
  @override
  bool isCurrentSession({required String userId, required int generation}) {
    return generation == _testGeneration && _session?.userId == userId;
  }

  void setUser(String? userId) {
    _testGeneration++;
    _session = userId == null
        ? null
        : AuthSession(
            userId: userId,
            email: '$userId@example.com',
            displayName: userId,
          );
    notifyListeners();
  }

  void bumpGeneration() {
    _testGeneration++;
    notifyListeners();
  }
}

class _FakeStaffGateway implements BusinessApplicationStaffGateway {
  _FakeStaffGateway({
    this.capabilitiesRead,
    this.pageRead,
    this.detailRead,
    this.mutationResult,
  });

  final Future<StaffReadResult<StaffApplicationCapabilities>> Function()?
  capabilitiesRead;
  final Future<StaffReadResult<StaffApplicationPage>> Function(
    BusinessApplicationStatus?,
    BusinessApplicationType?,
    StaffApplicationCursor?,
  )?
  pageRead;
  final Future<StaffReadResult<StaffApplicationDetail>> Function(String)?
  detailRead;
  final BusinessApplicationStaffResult? mutationResult;

  @override
  bool get isAvailable => true;

  @override
  Future<StaffReadResult<StaffApplicationCapabilities>> getCapabilities() {
    return capabilitiesRead?.call() ??
        Future.value(StaffReadSuccess(_capabilities));
  }

  @override
  Future<StaffReadResult<StaffApplicationPage>> listApplications({
    BusinessApplicationStatus? statusFilter,
    BusinessApplicationType? typeFilter,
    int limit = 25,
    StaffApplicationCursor? cursor,
  }) {
    return pageRead?.call(statusFilter, typeFilter, cursor) ??
        Future.value(const StaffReadSuccess(StaffApplicationPage(items: [])));
  }

  @override
  Future<StaffReadResult<StaffApplicationDetail>> getApplicationDetail(
    String applicationId,
  ) {
    return detailRead?.call(applicationId) ??
        Future.value(
          const StaffReadDenied(
            BusinessApplicationStaffCause.applicationNotFound,
          ),
        );
  }

  Future<BusinessApplicationStaffResult> _mutation() {
    return Future.value(
      mutationResult ??
          const BusinessApplicationStaffDenied(
            BusinessApplicationStaffCause.invalidTransition,
          ),
    );
  }

  @override
  Future<BusinessApplicationStaffResult> beginReview(String applicationId) =>
      _mutation();
  @override
  Future<BusinessApplicationStaffResult> returnForCorrection(
    String applicationId, {
    required String reason,
  }) => _mutation();
  @override
  Future<BusinessApplicationStaffResult> markContacted(
    String applicationId, {
    required String contactType,
    String? result,
    String? notes,
  }) => _mutation();
  @override
  Future<BusinessApplicationStaffResult> scheduleVisit(
    String applicationId, {
    required DateTime scheduledAt,
    String? location,
    String? notes,
  }) => _mutation();
  @override
  Future<BusinessApplicationStaffResult> approve(String applicationId) =>
      _mutation();
  @override
  Future<BusinessApplicationStaffResult> reject(
    String applicationId, {
    required String reason,
  }) => _mutation();
  @override
  Future<BusinessApplicationStaffResult> activate(String applicationId) =>
      _mutation();
}
