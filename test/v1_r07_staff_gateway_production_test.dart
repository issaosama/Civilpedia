import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/features/business/data/supabase_business_application_staff_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_staff_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:civilpedia/features/business/domain/staff_application_capabilities.dart';
import 'package:civilpedia/features/business/domain/staff_application_detail.dart';
import 'package:civilpedia/features/business/domain/staff_application_summary.dart';
import 'package:civilpedia/features/business/domain/staff_read_result.dart';

const _appId = '00000000-0000-0000-0000-000000000001';

http.Response _jsonResponse(Object? body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

class _FakeInitializedService extends SupabaseService {
  _FakeInitializedService()
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

class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient({this.onRequest});

  final List<http.BaseRequest> requests = [];
  final Future<http.Response> Function(http.BaseRequest)? onRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = await onRequest?.call(request) ?? _jsonResponse({});
    return http.StreamedResponse(
      Stream.fromIterable([utf8.encode(response.body)]),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

SupabaseBusinessApplicationStaffGateway _gateway(
  _RecordingHttpClient httpClient,
) {
  return SupabaseBusinessApplicationStaffGateway(
    service: _FakeInitializedService(),
    client: SupabaseClient(
      'http://localhost:54321',
      'anon',
      httpClient: httpClient,
    ),
  );
}

Map<String, dynamic> _capabilitiesJson() => const {
  'permissions': ['business_applications.read', 'business_applications.review'],
};

Map<String, dynamic> _summaryJson() => {
  'id': _appId,
  'application_type': 'NEW',
  'status': 'SUBMITTED',
  'created_at': '2024-01-01T10:00:00.000Z',
  'updated_at': '2024-01-02T10:00:00.000Z',
  'new_business': {'name': 'Test Business'},
};

Map<String, dynamic> _pageJson({Object? nextCursor}) => {
  'items': [_summaryJson()],
  'next_cursor': nextCursor,
};

Map<String, dynamic> _detailJson() => {
  'application': {
    'id': _appId,
    'application_type': 'NEW',
    'status': 'SUBMITTED',
    'created_at': '2024-01-01T10:00:00.000Z',
    'updated_at': '2024-01-02T10:00:00.000Z',
  },
  'applicant': {'display_name': 'Applicant One', 'phone': '+9647700000000'},
  'new_business': {'name': 'Test Business'},
  'contacts': [],
  'visits': [],
};

Map<String, dynamic> _applicationRowJson() => {
  'id': _appId,
  'application_type': 'NEW',
  'status': 'UNDER_REVIEW',
  'created_at': '2024-01-01T10:00:00.000Z',
  'updated_at': '2024-01-02T10:00:00.000Z',
};

void main() {
  group('V1-R07 production staff gateway behavioral coverage', () {
    test(
      'getCapabilities sends the frozen RPC and parses the projection',
      () async {
        late String capturedBody;
        final httpClient = _RecordingHttpClient(
          onRequest: (request) async {
            if (request.url.path.endsWith(
              'get_staff_application_capabilities',
            )) {
              expect(request.method, 'POST');
              capturedBody = request is http.Request ? request.body : '';
              return _jsonResponse(_capabilitiesJson());
            }
            return _jsonResponse({});
          },
        );
        final gateway = _gateway(httpClient);

        final result = await gateway.getCapabilities();

        expect(result, isA<StaffReadSuccess<StaffApplicationCapabilities>>());
        final caps =
            (result as StaffReadSuccess<StaffApplicationCapabilities>).data;
        expect(caps.canRead, isTrue);
        expect(caps.canApprove, isFalse);
        expect(
          capturedBody,
          'null',
          reason: 'capability discovery derives identity from auth.uid()',
        );
        expect(
          httpClient.requests.any(
            (r) => r.url.path.endsWith('get_staff_application_capabilities'),
          ),
          isTrue,
        );
      },
    );

    test('listApplications sends status, type and cursor params and parses '
        'a final page with explicit null next_cursor', () async {
      late Map<String, dynamic> capturedBody;
      final httpClient = _RecordingHttpClient(
        onRequest: (request) async {
          if (request.url.path.endsWith('list_staff_business_applications')) {
            capturedBody = request is http.Request
                ? jsonDecode(request.body) as Map<String, dynamic>
                : <String, dynamic>{};
            return _jsonResponse(_pageJson(nextCursor: null));
          }
          return _jsonResponse({});
        },
      );
      final gateway = _gateway(httpClient);
      final cursor = StaffApplicationCursor(
        createdAt: DateTime.utc(2024, 1, 2),
        id: _appId,
      );

      final result = await gateway.listApplications(
        statusFilter: BusinessApplicationStatus.approved,
        typeFilter: BusinessApplicationType.claim,
        cursor: cursor,
      );

      expect(result, isA<StaffReadSuccess<StaffApplicationPage>>());
      final page = (result as StaffReadSuccess<StaffApplicationPage>).data;
      expect(page.items.length, 1);
      expect(page.hasMore, isFalse);
      expect(capturedBody['p_limit'], 25);
      expect(capturedBody['p_status'], 'APPROVED');
      expect(capturedBody['p_application_type'], 'CLAIM');
      expect(capturedBody['p_cursor_created_at'], '2024-01-02T00:00:00.000Z');
      expect(capturedBody['p_cursor_id'], _appId);
    });

    test('listApplications without filters omits optional params', () async {
      late Map<String, dynamic> capturedBody;
      final httpClient = _RecordingHttpClient(
        onRequest: (request) async {
          if (request.url.path.endsWith('list_staff_business_applications')) {
            capturedBody = request is http.Request
                ? jsonDecode(request.body) as Map<String, dynamic>
                : <String, dynamic>{};
            return _jsonResponse(_pageJson(nextCursor: null));
          }
          return _jsonResponse({});
        },
      );
      final gateway = _gateway(httpClient);

      await gateway.listApplications();

      expect(capturedBody.keys.toSet(), {'p_limit'});
    });

    test('malformed page projection maps to unexpected denial', () async {
      final httpClient = _RecordingHttpClient(
        onRequest: (request) async {
          if (request.url.path.endsWith('list_staff_business_applications')) {
            return _jsonResponse({'items': 'broken'});
          }
          return _jsonResponse({});
        },
      );
      final gateway = _gateway(httpClient);

      final result = await gateway.listApplications();

      expect(result, isA<StaffReadDenied<StaffApplicationPage>>());
      expect(
        (result as StaffReadDenied<StaffApplicationPage>).cause,
        BusinessApplicationStaffCause.unexpected,
      );
    });

    test(
      'getApplicationDetail sends the frozen RPC and parses detail',
      () async {
        late Map<String, dynamic> capturedBody;
        final httpClient = _RecordingHttpClient(
          onRequest: (request) async {
            if (request.url.path.endsWith(
              'get_staff_business_application_detail',
            )) {
              capturedBody = request is http.Request
                  ? jsonDecode(request.body) as Map<String, dynamic>
                  : <String, dynamic>{};
              return _jsonResponse(_detailJson());
            }
            return _jsonResponse({});
          },
        );
        final gateway = _gateway(httpClient);

        final result = await gateway.getApplicationDetail(_appId);

        expect(result, isA<StaffReadSuccess<StaffApplicationDetail>>());
        expect(capturedBody['p_application_id'], _appId);
        expect(
          (result as StaffReadSuccess<StaffApplicationDetail>).data.id,
          _appId,
        );
      },
    );

    test(
      'beginReview sends the frozen RPC and parses the returned row',
      () async {
        late Map<String, dynamic> capturedBody;
        final httpClient = _RecordingHttpClient(
          onRequest: (request) async {
            if (request.url.path.endsWith('staff_begin_application_review')) {
              capturedBody = request is http.Request
                  ? jsonDecode(request.body) as Map<String, dynamic>
                  : <String, dynamic>{};
              return _jsonResponse(_applicationRowJson());
            }
            return _jsonResponse({});
          },
        );
        final gateway = _gateway(httpClient);

        final result = await gateway.beginReview(_appId);

        expect(result, isA<BusinessApplicationStaffSucceeded>());
        expect(capturedBody['p_application_id'], _appId);
        expect(
          (result as BusinessApplicationStaffSucceeded).application.status,
          BusinessApplicationStatus.underReview,
        );
      },
    );

    test('reject sends the reason parameter', () async {
      late Map<String, dynamic> capturedBody;
      final httpClient = _RecordingHttpClient(
        onRequest: (request) async {
          if (request.url.path.endsWith('staff_reject_business_application')) {
            capturedBody = request is http.Request
                ? jsonDecode(request.body) as Map<String, dynamic>
                : <String, dynamic>{};
            return _jsonResponse(_applicationRowJson());
          }
          return _jsonResponse({});
        },
      );
      final gateway = _gateway(httpClient);

      final result = await gateway.reject(_appId, reason: 'Not eligible');

      expect(result, isA<BusinessApplicationStaffSucceeded>());
      expect(capturedBody['p_reason'], 'Not eligible');
    });

    for (final entry in <String, BusinessApplicationStaffCause>{
      'P0AUT': BusinessApplicationStaffCause.unauthenticated,
      'P0PER': BusinessApplicationStaffCause.staffPermissionDenied,
      'P0NOT': BusinessApplicationStaffCause.applicationNotFound,
      'P0TRA': BusinessApplicationStaffCause.invalidTransition,
      'P0COR': BusinessApplicationStaffCause.correctionReasonRequired,
      'P0REJ': BusinessApplicationStaffCause.rejectionReasonRequired,
      'P0DAT': BusinessApplicationStaffCause.requiredDataMissing,
      'P0CLM': BusinessApplicationStaffCause.targetNotClaimable,
      'P0OWN': BusinessApplicationStaffCause.ownershipProvisioningConflict,
    }.entries) {
      test(
        'real gateway maps server ${entry.key} to ${entry.value.name}',
        () async {
          final httpClient = _RecordingHttpClient(
            onRequest: (request) async {
              if (request.url.path.endsWith(
                'get_staff_application_capabilities',
              )) {
                return _jsonResponse({
                  'message': 'typed server rejection',
                  'code': entry.key,
                }, statusCode: 400);
              }
              return _jsonResponse({});
            },
          );
          final gateway = _gateway(httpClient);

          final result = await gateway.getCapabilities();

          expect(result, isA<StaffReadDenied<StaffApplicationCapabilities>>());
          expect(
            (result as StaffReadDenied<StaffApplicationCapabilities>).cause,
            entry.value,
          );
        },
      );
    }

    test('returns unavailable when the service is not initialized', () async {
      final gateway = SupabaseBusinessApplicationStaffGateway(
        service: SupabaseService(
          config: const BackendConfig(
            appEnvRaw: 'development',
            supabaseUrl: 'http://localhost:54321',
            supabaseAnonKey: 'anon',
          ),
        ),
        client: SupabaseClient('http://localhost:54321', 'anon'),
      );

      expect(gateway.isAvailable, isFalse);
      expect(await gateway.getCapabilities(), isA<StaffReadUnavailable>());
      expect(
        await gateway.listApplications(),
        isA<StaffReadUnavailable<StaffApplicationPage>>(),
      );
      expect(
        await gateway.getApplicationDetail(_appId),
        isA<StaffReadUnavailable<StaffApplicationDetail>>(),
      );
      expect(
        await gateway.beginReview(_appId),
        isA<BusinessApplicationStaffDenied>(),
      );
    });
  });
}
