import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/core/network/remote_operation_policy.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/business/data/business_remote_read_classifier.dart';
import 'package:civilpedia/features/business/data/supabase_business_application_gateway.dart';
import 'package:civilpedia/features/business/data/supabase_business_claim_target_gateway.dart';
import 'package:civilpedia/features/business/data/supabase_business_membership_gateway.dart';
import 'package:civilpedia/features/business/data/supabase_business_profile_management_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_policy.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:civilpedia/features/business/domain/business_claim_target.dart';
import 'package:civilpedia/features/business/domain/business_claim_target_gateway.dart';
import 'package:civilpedia/features/business/domain/business_contact_type.dart';
import 'package:civilpedia/features/business/domain/business_membership.dart';
import 'package:civilpedia/features/business/domain/business_membership_gateway.dart';
import 'package:civilpedia/features/business/domain/business_profile_management_gateway.dart';
import 'package:civilpedia/features/business/domain/business_remote_read.dart';
import 'package:civilpedia/features/business/domain/business_role.dart';
import 'package:civilpedia/features/business/domain/managed_business_profile.dart';
import 'package:civilpedia/features/business/domain/managed_business_profile_draft.dart';
import 'package:civilpedia/features/business/domain/managed_business_summary.dart';
import 'package:civilpedia/features/business/domain/managed_selectable_options.dart';
import 'package:civilpedia/features/business/presentation/providers/business_application_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/business_claim_target_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/business_profile_editor_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/managed_businesses_provider.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes/fake_auth_gateway.dart';
import 'helpers/canonical_directory_test_helpers.dart';

const _userA = 'user-a';
const _userB = 'user-b';
const _entityA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const _entityB = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

const _sessionA = AuthSession(
  userId: _userA,
  email: 'a@example.com',
  displayName: 'A',
);
const _sessionB = AuthSession(
  userId: _userB,
  email: 'b@example.com',
  displayName: 'B',
);

Future<AuthProvider> _authenticatedAuth({
  AuthSession session = _sessionA,
  FakeAuthGateway? gateway,
}) async {
  final auth = AuthProvider(
    gateway: gateway ?? FakeAuthGateway(restoredSession: session),
    onPostAuth: (_) async => PostAuthOutcome.success,
  );
  await auth.restoreSession();
  return auth;
}

ManagedBusinessSummary _summary(String entityId, String name) {
  return ManagedBusinessSummary(
    entityId: entityId,
    name: name,
    entityType: 'company',
    membershipRole: BusinessRole.owner,
    claimStatus: 'claimed',
    verificationStatus: 'verified',
  );
}

BusinessApplication _application(
  String id, {
  String userId = _userA,
  BusinessApplicationStatus status = BusinessApplicationStatus.draft,
}) {
  return BusinessApplication(
    id: id,
    applicantUserId: userId,
    type: BusinessApplicationType.newApplication,
    status: status,
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
  );
}

ManagedBusinessProfile _profile(
  String id, {
  String name = 'Business',
  DateTime? updatedAt,
}) {
  return ManagedBusinessProfile(
    id: id,
    entityType: 'company',
    name: name,
    lifecycleStatus: 'active',
    verificationStatus: VerificationStatus.verified,
    claimStatus: 'claimed',
    createdAt: DateTime.utc(2024),
    updatedAt: updatedAt ?? DateTime.utc(2024, 1, 2),
    contacts: const [
      ManagedBusinessContact(
        id: 'contact',
        type: BusinessContactType.phone,
        value: '12345',
        isPrimary: true,
      ),
    ],
    categories: const [],
  );
}

class _MembershipGateway implements BusinessMembershipGateway {
  bool available = true;
  int calls = 0;
  final List<Future<ManagedBusinessListResult> Function()> reads = [];

  @override
  bool get isAvailable => available;

  @override
  Future<ManagedBusinessListResult> listMyBusinesses() {
    final read = reads[calls++];
    return read();
  }

  @override
  Future<List<BusinessMembership>> listOwnMemberships(String userId) async =>
      const [];

  @override
  Future<BusinessMembershipListResult> listMembersForEntity(
    String entityId,
  ) async => const BusinessMembershipListUnavailable();
}

class _ApplicationGateway implements BusinessApplicationGateway {
  @override
  bool get isAvailable => true;

  int listCalls = 0;
  int detailCalls = 0;
  final List<Future<List<BusinessApplication>> Function(String)> listReads = [];
  final List<Future<BusinessApplication?> Function(String, String)>
  detailReads = [];
  BusinessApplicationCreateResult? createResult;
  BusinessApplicationSubmitResult? submitResult;

  @override
  Future<List<BusinessApplication>> listOwnApplications(String userId) {
    final read = listReads[listCalls++];
    return read(userId);
  }

  @override
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  ) {
    final read = detailReads[detailCalls++];
    return read(userId, applicationId);
  }

  @override
  Future<BusinessApplicationCreateResult> createNewDraft({
    required String currentUserId,
    Map<String, dynamic>? metadata,
  }) async => createResult!;

  @override
  Future<BusinessApplicationCreateResult> createClaimDraft({
    required String currentUserId,
    required String targetEntityId,
  }) async => createResult!;

  @override
  Future<BusinessApplicationSubmitResult> submitApplication(
    BusinessApplication application,
  ) async => submitResult!;

  @override
  Future<BusinessApplicationSubmitResult> resubmitApplication(
    BusinessApplication application,
  ) async => submitResult!;
}

class _ClaimGateway implements BusinessClaimTargetGateway {
  @override
  bool get isAvailable => true;

  int calls = 0;
  final List<Future<List<BusinessClaimTarget>> Function()> reads = [];

  @override
  Future<List<BusinessClaimTarget>> listUnclaimedTargets() {
    final read = reads[calls++];
    return read();
  }
}

class _ProfileGateway implements BusinessProfileManagementGateway {
  @override
  bool get isAvailable => true;

  int profileCalls = 0;
  int categoryCalls = 0;
  int regionCalls = 0;
  final Map<String, List<Future<ManagedProfileReadResult> Function()>>
  profileReads = {};
  Future<List<ManagedSelectableCategory>> Function()? categoryRead;
  Future<List<ManagedSelectableRegion>> Function()? regionRead;
  ManagedProfileUpdateResult updateResult = const ManagedProfileUpdateDenied(
    BusinessProfileManagementCause.unexpected,
  );

  @override
  Future<ManagedProfileReadResult> readManagedProfile(String entityId) {
    profileCalls++;
    final queue = profileReads[entityId]!;
    return queue.removeAt(0)();
  }

  @override
  Future<List<ManagedSelectableCategory>> loadActiveCategories() {
    categoryCalls++;
    return categoryRead?.call() ?? Future.value(const []);
  }

  @override
  Future<List<ManagedSelectableRegion>> loadActiveRegions() {
    regionCalls++;
    return regionRead?.call() ?? Future.value(const []);
  }

  @override
  Future<ManagedProfileUpdateResult> updateManagedProfile({
    required String entityId,
    required DateTime expectedUpdatedAt,
    required ManagedBusinessProfileDraft draft,
  }) async => updateResult;
}

Future<SupabaseService> _initializedService() async {
  final service = SupabaseService(
    config: const BackendConfig(
      appEnvRaw: 'development',
      supabaseUrl: 'http://localhost:54321',
      supabaseAnonKey: 'anon',
    ),
  );
  await service.init(
    initialize: ({required url, required publishableKey}) async {},
  );
  return service;
}

http.Response _json(
  Object? body, {
  int status = 200,
  http.BaseRequest? request,
}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
    request: request,
  );
}

Map<String, dynamic> _applicationRow(
  String id, {
  String userId = _userA,
  String createdAt = '2024-01-01T00:00:00Z',
  String updatedAt = '2024-01-02T00:00:00Z',
}) {
  return <String, dynamic>{
    'id': id,
    'applicant_user_id': userId,
    'application_type': 'NEW',
    'status': 'DRAFT',
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

Map<String, dynamic> _profileProjection(String entityId, {String name = 'B'}) {
  return <String, dynamic>{
    'entity': <String, dynamic>{
      'id': entityId,
      'entity_type': 'company',
      'name': name,
      'lifecycle_status': 'active',
      'claim_status': 'claimed',
      'verification_status': 'verified',
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-02T00:00:00Z',
    },
    'contacts': <Map<String, dynamic>>[],
    'primary_location': null,
    'categories': <Map<String, dynamic>>[],
  };
}

String _base64UrlJson(Map<String, dynamic> value) =>
    base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

String _testAccessToken(String userId) {
  return '${_base64UrlJson({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${_base64UrlJson({'sub': userId, 'session_id': 'p2-d-test-session', 'exp': 1893456000, 'aud': 'authenticated', 'role': 'authenticated', 'iat': 1609459200})}.signature';
}

Future<SupabaseClient> _authenticatedSupabaseClient(
  http.Client httpClient,
) async {
  final client = SupabaseClient(
    'http://localhost:54321',
    'anon',
    httpClient: httpClient,
  );
  final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': _testAccessToken(_userA),
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at': now + 3600,
      'refresh_token': 'p2-d-refresh-token',
      'user': {
        'id': _userA,
        'email': 'a@example.com',
        'user_metadata': <String, dynamic>{},
        'app_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2024-01-01T00:00:00Z',
        'role': 'authenticated',
      },
    }),
  );
  return client;
}

void main() {
  group('P2-D1 taxonomy', () {
    test('maps transport, timeout, malformed, and unknown narrowly', () {
      expect(
        classifyBusinessRemoteReadFailure(const SocketException('closed')),
        BusinessRemoteReadFailureKind.network,
      );
      expect(
        classifyBusinessRemoteReadFailure(TimeoutException('bounded')),
        BusinessRemoteReadFailureKind.timeout,
      );
      expect(
        classifyBusinessRemoteReadFailure(const FormatException('shape')),
        BusinessRemoteReadFailureKind.malformedResponse,
      );
      expect(
        classifyBusinessRemoteReadFailure(StateError('unknown')),
        BusinessRemoteReadFailureKind.unexpected,
      );
    });

    test('maps only frozen PostgREST availability codes', () {
      for (final code in const [
        '08006',
        '53000',
        'PGRST000',
        'PGRST001',
        'PGRST002',
        'PGRST003',
      ]) {
        expect(
          classifyBusinessRemoteReadFailure(
            PostgrestException(message: 'hidden', code: code),
          ),
          BusinessRemoteReadFailureKind.serviceUnavailable,
          reason: code,
        );
      }
    });

    test('permission and auth codes require proven source semantics', () {
      expect(
        classifyBusinessRemoteReadFailure(
          const PostgrestException(message: 'hidden', code: '42501'),
        ),
        BusinessRemoteReadFailureKind.permissionDenied,
      );
      expect(
        classifyBusinessRemoteReadFailure(
          const PostgrestException(message: 'hidden', code: 'P0PER'),
          p0PerIsPermissionDenied: true,
        ),
        BusinessRemoteReadFailureKind.permissionDenied,
      );
      expect(
        classifyBusinessRemoteReadFailure(
          const PostgrestException(message: 'hidden', code: 'P0AUT'),
          p0AutIsAuthRestricted: true,
        ),
        BusinessRemoteReadFailureKind.authRestricted,
      );
      for (final code in const ['PGRST301', 'PGRST302', 'PGRST303']) {
        expect(
          classifyBusinessRemoteReadFailure(
            PostgrestException(message: 'hidden', code: code),
          ),
          BusinessRemoteReadFailureKind.authRestricted,
        );
      }
      expect(
        classifyBusinessRemoteReadFailure(
          const PostgrestException(message: 'hidden', code: 'P0PER'),
        ),
        BusinessRemoteReadFailureKind.unexpected,
      );
    });

    test('literal 503 and generic PostgREST 401 stay unexpected', () {
      for (final code in const ['503', '401']) {
        expect(
          classifyBusinessRemoteReadFailure(
            PostgrestException(message: 'hidden', code: code),
          ),
          BusinessRemoteReadFailureKind.unexpected,
        );
      }
      expect(
        classifyBusinessRemoteReadFailure(
          const AuthException('hidden', statusCode: '401'),
        ),
        BusinessRemoteReadFailureKind.authRestricted,
      );
    });
  });

  group('P2-D1 gateway strictness and deadline', () {
    test('managed list malformed row fails complete response', () async {
      final service = await _initializedService();
      final client = SupabaseClient(
        'http://localhost:54321',
        'anon',
        httpClient: MockClient(
          (request) async => _json([
            {
              'entity_id': _entityA,
              'name': 'Good',
              'entity_type': 'company',
              'membership_role': 'OWNER',
              'claim_status': 'claimed',
              'verification_status': 'verified',
            },
            {'entity_id': _entityB},
          ], request: request),
        ),
      );
      final gateway = SupabaseBusinessMembershipGateway(
        service: service,
        client: client,
      );
      final result = await gateway.listMyBusinesses();
      expect(result, isA<ManagedBusinessListDenied>());
      expect(
        (result as ManagedBusinessListDenied).cause,
        BusinessRemoteReadFailureKind.malformedResponse,
      );
    });

    test('application malformed row fails complete response', () async {
      final service = await _initializedService();
      final client = SupabaseClient(
        'http://localhost:54321',
        'anon',
        httpClient: MockClient(
          (request) async => _json([
            _applicationRow('good'),
            {'id': 'malformed'},
          ], request: request),
        ),
      );
      final gateway = SupabaseBusinessApplicationGateway(
        service: service,
        client: client,
      );
      await expectLater(
        gateway.listOwnApplications(_userA),
        throwsA(
          isA<BusinessRemoteReadException>().having(
            (error) => error.kind,
            'kind',
            BusinessRemoteReadFailureKind.malformedResponse,
          ),
        ),
      );
    });

    test(
      'application authoritative timestamps are strictly required',
      () async {
        final service = await _initializedService();

        Future<List<BusinessApplication>> readRow(Map<String, dynamic> row) {
          final client = SupabaseClient(
            'http://localhost:54321',
            'anon',
            httpClient: MockClient(
              (request) async => _json([row], request: request),
            ),
          );
          return SupabaseBusinessApplicationGateway(
            service: service,
            client: client,
          ).listOwnApplications(_userA);
        }

        final valid = await readRow(_applicationRow('valid'));
        expect(valid.single.id, 'valid');
        expect(valid.single.createdAt, DateTime.utc(2024, 1, 1));
        expect(valid.single.updatedAt, DateTime.utc(2024, 1, 2));

        final cases =
            <({String label, void Function(Map<String, dynamic>) alter})>[
              (
                label: 'missing created_at',
                alter: (row) => row.remove('created_at'),
              ),
              (
                label: 'missing updated_at',
                alter: (row) => row.remove('updated_at'),
              ),
              (
                label: 'null created_at',
                alter: (row) => row['created_at'] = null,
              ),
              (
                label: 'null updated_at',
                alter: (row) => row['updated_at'] = null,
              ),
              (
                label: 'wrong-type created_at',
                alter: (row) => row['created_at'] = 7,
              ),
              (
                label: 'wrong-type updated_at',
                alter: (row) => row['updated_at'] = 7,
              ),
              (
                label: 'invalid created_at',
                alter: (row) => row['created_at'] = 'not-a-timestamp',
              ),
              (
                label: 'invalid updated_at',
                alter: (row) => row['updated_at'] = 'not-a-timestamp',
              ),
            ];
        for (final testCase in cases) {
          final row = _applicationRow('invalid');
          testCase.alter(row);
          await expectLater(
            readRow(row),
            throwsA(
              isA<BusinessRemoteReadException>().having(
                (error) => error.kind,
                testCase.label,
                BusinessRemoteReadFailureKind.malformedResponse,
              ),
            ),
            reason: testCase.label,
          );
        }
      },
    );

    test('managed profile rejects a projection for another entity', () async {
      final service = await _initializedService();
      final client = SupabaseClient(
        'http://localhost:54321',
        'anon',
        httpClient: MockClient(
          (request) async =>
              _json(_profileProjection(_entityB), request: request),
        ),
      );
      final result = await SupabaseBusinessProfileManagementGateway(
        service: service,
        client: client,
      ).readManagedProfile(_entityA);
      expect(result, isA<ManagedProfileReadFailed>());
      expect(
        (result as ManagedProfileReadFailed).cause,
        BusinessRemoteReadFailureKind.malformedResponse,
      );
    });

    test('application detail rejects an owned row with another id', () async {
      final service = await _initializedService();
      final client = SupabaseClient(
        'http://localhost:54321',
        'anon',
        httpClient: MockClient(
          (request) async =>
              _json(_applicationRow('application-b'), request: request),
        ),
      );
      final gateway = SupabaseBusinessApplicationGateway(
        service: service,
        client: client,
      );
      await expectLater(
        gateway.getOwnApplication(_userA, 'application-a'),
        throwsA(
          isA<BusinessRemoteReadException>().having(
            (error) => error.kind,
            'kind',
            BusinessRemoteReadFailureKind.malformedResponse,
          ),
        ),
      );
    });

    test(
      'production claim gateway fails the complete malformed response',
      () async {
        final service = await _initializedService();
        final client = await _authenticatedSupabaseClient(
          MockClient(
            (request) async => _json([
              {
                'id': _entityA,
                'name': 'Good',
                'entity_type': 'company',
                'claim_status': 'unclaimed',
                'verification_status': 'verified',
              },
              {'id': _entityB},
            ], request: request),
          ),
        );
        final gateway = SupabaseBusinessClaimTargetGateway(
          service: service,
          client: client,
        );
        await expectLater(
          gateway.listUnclaimedTargets(),
          throwsA(
            isA<BusinessRemoteReadException>().having(
              (error) => error.kind,
              'kind',
              BusinessRemoteReadFailureKind.malformedResponse,
            ),
          ),
        );
      },
    );

    test(
      'read deadline is canonical and timeout is typed without 15s wait',
      () async {
        expect(RemoteOperationPolicy.read, const Duration(seconds: 15));
        final service = await _initializedService();
        final never = Completer<http.Response>();
        final client = SupabaseClient(
          'http://localhost:54321',
          'anon',
          httpClient: MockClient((_) => never.future),
        );
        final gateway = SupabaseBusinessApplicationGateway(
          service: service,
          client: client,
          readTimeout: const Duration(milliseconds: 5),
        );
        await expectLater(
          gateway.listOwnApplications(_userA),
          throwsA(
            isA<BusinessRemoteReadException>().having(
              (error) => error.kind,
              'kind',
              BusinessRemoteReadFailureKind.timeout,
            ),
          ),
        );
      },
    );

    test(
      'claim provider rejects contradictory row instead of skipping it',
      () async {
        final auth = await _authenticatedAuth();
        final gateway = _ClaimGateway()
          ..reads.add(
            () async => const [
              BusinessClaimTarget(
                id: _entityA,
                name: 'Contradiction',
                entityType: 'company',
                claimStatus: 'claimed',
              ),
            ],
          );
        final provider = BusinessClaimTargetProvider(
          gateway: gateway,
          auth: auth,
        );
        await provider.reload();
        expect(provider.targets, isEmpty);
        expect(
          provider.readFailure,
          BusinessRemoteReadFailureKind.malformedResponse,
        );
      },
    );
  });

  group('P2-D1 managed-list lifecycle', () {
    test(
      'managed and claim list empties are authoritative, not notFound',
      () async {
        final auth = await _authenticatedAuth();
        final membershipGateway = _MembershipGateway()
          ..reads.add(() async => const ManagedBusinessListAvailable([]));
        final managed = ManagedBusinessesProvider(
          membershipGateway: membershipGateway,
          auth: auth,
        );
        await managed.load();
        expect(managed.readPhase, BusinessRemoteReadPhase.authoritativeEmpty);
        expect(managed.readFailure, isNull);

        final claimGateway = _ClaimGateway()..reads.add(() async => const []);
        final claims = BusinessClaimTargetProvider(
          gateway: claimGateway,
          auth: auth,
        );
        await claims.reload();
        expect(claims.readPhase, BusinessRemoteReadPhase.authoritativeEmpty);
        expect(claims.readFailure, isNull);
      },
    );

    test('same key coalesces and known-good survives typed failure', () async {
      final auth = await _authenticatedAuth();
      final first = Completer<ManagedBusinessListResult>();
      final failure = Completer<ManagedBusinessListResult>();
      final replacement = Completer<ManagedBusinessListResult>();
      final gateway = _MembershipGateway()
        ..reads.add(() => first.future)
        ..reads.add(() => failure.future)
        ..reads.add(() => replacement.future);
      final provider = ManagedBusinessesProvider(
        membershipGateway: gateway,
        auth: auth,
      );

      final read1 = provider.load();
      final joined = provider.load();
      expect(gateway.calls, 1);
      first.complete(ManagedBusinessListAvailable([_summary(_entityA, 'A')]));
      await Future.wait([read1, joined]);

      final refresh = provider.load();
      expect(provider.readPhase, BusinessRemoteReadPhase.refreshing);
      expect(provider.items.single.summary.name, 'A');
      failure.complete(
        const ManagedBusinessListDenied(BusinessRemoteReadFailureKind.network),
      );
      await refresh;
      expect(provider.items.single.summary.name, 'A');
      expect(provider.readFailure, BusinessRemoteReadFailureKind.network);
      expect(provider.state, ManagedBusinessesState.data);

      final successfulRefresh = provider.load();
      replacement.complete(
        ManagedBusinessListAvailable([_summary(_entityB, 'Replacement')]),
      );
      await successfulRefresh;
      expect(provider.items.single.summary.name, 'Replacement');
      expect(provider.readFailure, isNull);
    });

    test(
      'claim targets preserve exact-key data and clear it for another user',
      () async {
        final authGateway = FakeAuthGateway(
          restoredSession: _sessionA,
          signInResult: _sessionB,
        );
        final auth = await _authenticatedAuth(gateway: authGateway);
        final failure = Completer<List<BusinessClaimTarget>>();
        final replacement = Completer<List<BusinessClaimTarget>>();
        final userB = Completer<List<BusinessClaimTarget>>();
        final gateway = _ClaimGateway()
          ..reads.add(
            () async => const [
              BusinessClaimTarget(
                id: _entityA,
                name: 'A',
                entityType: 'company',
                claimStatus: 'unclaimed',
              ),
            ],
          )
          ..reads.add(() => failure.future)
          ..reads.add(() => replacement.future)
          ..reads.add(() => userB.future);
        final provider = BusinessClaimTargetProvider(
          gateway: gateway,
          auth: auth,
        );

        await provider.reload();
        final failedRefresh = provider.reload();
        expect(provider.readPhase, BusinessRemoteReadPhase.refreshing);
        expect(provider.targets.single.name, 'A');
        failure.completeError(
          const BusinessRemoteReadException(
            BusinessRemoteReadFailureKind.network,
          ),
        );
        await failedRefresh;
        expect(provider.targets.single.name, 'A');
        expect(provider.readFailure, BusinessRemoteReadFailureKind.network);

        final successfulRefresh = provider.reload();
        expect(provider.targets.single.name, 'A');
        replacement.complete(const [
          BusinessClaimTarget(
            id: _entityA,
            name: 'Replacement',
            entityType: 'company',
            claimStatus: 'unclaimed',
          ),
        ]);
        await successfulRefresh;
        expect(provider.targets.single.name, 'Replacement');
        expect(provider.readFailure, isNull);

        await auth.signInWithGoogle();
        final userBRead = provider.reload();
        expect(provider.targets, isEmpty);
        expect(provider.readPhase, BusinessRemoteReadPhase.loading);
        userB.complete(const [
          BusinessClaimTarget(
            id: _entityB,
            name: 'B',
            entityType: 'company',
            claimStatus: 'unclaimed',
          ),
        ]);
        await userBRead;
        expect(provider.targets.single.id, _entityB);
      },
    );

    test(
      'user B starts independently and late A cannot clear B handle/data',
      () async {
        final authGateway = FakeAuthGateway(
          restoredSession: _sessionA,
          signInResult: _sessionB,
        );
        final auth = await _authenticatedAuth(gateway: authGateway);
        final a = Completer<ManagedBusinessListResult>();
        final b = Completer<ManagedBusinessListResult>();
        final gateway = _MembershipGateway()
          ..reads.add(() => a.future)
          ..reads.add(() => b.future);
        final provider = ManagedBusinessesProvider(
          membershipGateway: gateway,
          auth: auth,
        );

        final readA = provider.load();
        await auth.signInWithGoogle();
        final readB = provider.load();
        expect(gateway.calls, 2);
        a.complete(ManagedBusinessListAvailable([_summary(_entityA, 'A')]));
        await readA;
        expect(provider.activeReadCount, 1);
        expect(provider.items, isEmpty);
        b.complete(ManagedBusinessListAvailable([_summary(_entityB, 'B')]));
        await readB;
        expect(provider.items.single.summary.name, 'B');
        expect(provider.activeReadCount, 0);
      },
    );

    test(
      'same user new auth generation supersedes the old generation',
      () async {
        final authGateway = FakeAuthGateway(
          restoredSession: _sessionA,
          signInResult: _sessionA,
        );
        final auth = await _authenticatedAuth(gateway: authGateway);
        final oldGeneration = auth.generation;
        final old = Completer<ManagedBusinessListResult>();
        final current = Completer<ManagedBusinessListResult>();
        final gateway = _MembershipGateway()
          ..reads.add(() => old.future)
          ..reads.add(() => current.future);
        final provider = ManagedBusinessesProvider(
          membershipGateway: gateway,
          auth: auth,
        );

        final oldRead = provider.load();
        await auth.signOut();
        await auth.signInWithGoogle();
        expect(auth.session?.userId, _userA);
        expect(auth.generation, greaterThan(oldGeneration));

        final currentRead = provider.load();
        expect(gateway.calls, 2);
        current.complete(
          ManagedBusinessListAvailable([_summary(_entityB, 'Current')]),
        );
        await currentRead;
        expect(provider.items.single.summary.name, 'Current');
        expect(provider.activeReadCount, 1);

        old.complete(
          const ManagedBusinessListDenied(
            BusinessRemoteReadFailureKind.network,
          ),
        );
        await oldRead;
        expect(provider.items.single.summary.name, 'Current');
        expect(provider.readFailure, isNull);
        expect(provider.readPhase, BusinessRemoteReadPhase.loaded);
        expect(provider.activeReadCount, 0);
      },
    );

    test('sign-out suppresses late publication', () async {
      final auth = await _authenticatedAuth();
      final pending = Completer<ManagedBusinessListResult>();
      final gateway = _MembershipGateway()..reads.add(() => pending.future);
      final provider = ManagedBusinessesProvider(
        membershipGateway: gateway,
        auth: auth,
      );
      final read = provider.load();
      await auth.signOut();
      pending.complete(ManagedBusinessListAvailable([_summary(_entityA, 'A')]));
      await read;
      expect(provider.items, isEmpty);
    });

    test('disposal suppresses late publication and notification', () async {
      final auth = await _authenticatedAuth();
      final pending = Completer<ManagedBusinessListResult>();
      final gateway = _MembershipGateway()..reads.add(() => pending.future);
      final provider = ManagedBusinessesProvider(
        membershipGateway: gateway,
        auth: auth,
      );
      var notifications = 0;
      provider.addListener(() => notifications++);
      final read = provider.load();
      final notificationsAtDispose = notifications;
      provider.dispose();
      pending.complete(ManagedBusinessListAvailable([_summary(_entityA, 'A')]));
      await read;
      expect(provider.items, isEmpty);
      expect(notifications, notificationsAtDispose);
    });
  });

  group('P2-D1 exact-key coalescing', () {
    test(
      'managed profile exact key joins one profile and auxiliary read',
      () async {
        final auth = await _authenticatedAuth();
        final profileResult = Completer<ManagedProfileReadResult>();
        final categories = Completer<List<ManagedSelectableCategory>>();
        final regions = Completer<List<ManagedSelectableRegion>>();
        final gateway = _ProfileGateway()
          ..profileReads[_entityA] = [() => profileResult.future];
        gateway.categoryRead = () => categories.future;
        gateway.regionRead = () => regions.future;
        final provider = BusinessProfileEditorProvider(
          gateway: gateway,
          directoryRepository: FakeCloudDirectoryRepository(const []),
          auth: auth,
        );

        final first = provider.load(_entityA);
        final joined = provider.load(_entityA);
        expect(gateway.profileCalls, 1);
        expect(gateway.categoryCalls, 1);
        expect(gateway.regionCalls, 1);

        profileResult.complete(ManagedProfileReadSuccess(_profile(_entityA)));
        categories.complete(const []);
        regions.complete(const []);
        await Future.wait([first, joined]);
        expect(provider.profile?.id, _entityA);
      },
    );

    test('application list and detail exact keys coalesce per lane', () async {
      final auth = await _authenticatedAuth();
      final list = Completer<List<BusinessApplication>>();
      final detail = Completer<BusinessApplication?>();
      final gateway = _ApplicationGateway()
        ..listReads.add((_) => list.future)
        ..detailReads.add((_, __) => detail.future);
      final provider = BusinessApplicationProvider(
        gateway: gateway,
        auth: auth,
      );

      final listFirst = provider.loadApplications();
      final listJoined = provider.loadApplications();
      final detailFirst = provider.loadApplication('application-a');
      final detailJoined = provider.loadApplication('application-a');
      expect(gateway.listCalls, 1);
      expect(gateway.detailCalls, 1);

      list.complete([_application('application-a')]);
      detail.complete(_application('application-a'));
      await Future.wait([listFirst, listJoined, detailFirst, detailJoined]);
      expect(provider.applications.single.id, 'application-a');
      expect(provider.current?.id, 'application-a');
    });

    test('claim target exact key joins one underlying read', () async {
      final auth = await _authenticatedAuth();
      final pending = Completer<List<BusinessClaimTarget>>();
      final gateway = _ClaimGateway()..reads.add(() => pending.future);
      final provider = BusinessClaimTargetProvider(
        gateway: gateway,
        auth: auth,
      );

      final first = provider.reload();
      final joined = provider.reload();
      expect(gateway.calls, 1);
      pending.complete(const [
        BusinessClaimTarget(
          id: _entityA,
          name: 'A',
          entityType: 'company',
          claimStatus: 'unclaimed',
        ),
      ]);
      await Future.wait([first, joined]);
      expect(provider.targets.single.id, _entityA);
    });
  });

  group('P2-D1 provider disposal', () {
    test(
      'profile provider drops a late profile completion after dispose',
      () async {
        final auth = await _authenticatedAuth();
        final pending = Completer<ManagedProfileReadResult>();
        final categories = Completer<List<ManagedSelectableCategory>>();
        final regions = Completer<List<ManagedSelectableRegion>>();
        final gateway = _ProfileGateway()
          ..profileReads[_entityA] = [() => pending.future];
        gateway.categoryRead = () => categories.future;
        gateway.regionRead = () => regions.future;
        final provider = BusinessProfileEditorProvider(
          gateway: gateway,
          directoryRepository: FakeCloudDirectoryRepository(const []),
          auth: auth,
        );
        var notifications = 0;
        provider.addListener(() => notifications++);

        final read = provider.load(_entityA);
        await Future<void>.delayed(Duration.zero);
        final notificationsAtDispose = notifications;
        final phaseAtDispose = provider.profileReadPhase;
        final auxiliaryPhaseAtDispose = provider.auxiliaryReadPhase;
        provider.dispose();
        pending.complete(ManagedProfileReadSuccess(_profile(_entityA)));
        categories.complete(const [
          ManagedSelectableCategory(id: 'late-category', code: 'late'),
        ]);
        regions.complete(const [
          ManagedSelectableRegion(id: 'late-region', code: 'late'),
        ]);
        await read;

        expect(provider.profile, isNull);
        expect(provider.profileReadFailure, isNull);
        expect(provider.profileReadPhase, phaseAtDispose);
        expect(provider.selectableCategories, isEmpty);
        expect(provider.selectableRegions, isEmpty);
        expect(provider.auxiliaryReadFailure, isNull);
        expect(provider.auxiliaryReadPhase, auxiliaryPhaseAtDispose);
        expect(notifications, notificationsAtDispose);
      },
    );

    test(
      'application provider drops late list and detail completions',
      () async {
        final auth = await _authenticatedAuth();
        final list = Completer<List<BusinessApplication>>();
        final detail = Completer<BusinessApplication?>();
        final gateway = _ApplicationGateway()
          ..listReads.add((_) => list.future)
          ..detailReads.add((_, __) => detail.future);
        final provider = BusinessApplicationProvider(
          gateway: gateway,
          auth: auth,
        );
        var notifications = 0;
        provider.addListener(() => notifications++);

        final listRead = provider.loadApplications();
        final detailRead = provider.loadApplication('application-a');
        final notificationsAtDispose = notifications;
        final listPhaseAtDispose = provider.listReadPhase;
        final detailPhaseAtDispose = provider.detailReadPhase;
        provider.dispose();
        list.complete([_application('application-a')]);
        detail.complete(_application('application-a'));
        await Future.wait([listRead, detailRead]);

        expect(provider.applications, isEmpty);
        expect(provider.current, isNull);
        expect(provider.listReadFailure, isNull);
        expect(provider.detailReadFailure, isNull);
        expect(provider.listReadPhase, listPhaseAtDispose);
        expect(provider.detailReadPhase, detailPhaseAtDispose);
        expect(notifications, notificationsAtDispose);
      },
    );

    test('claim provider drops a late completion after dispose', () async {
      final auth = await _authenticatedAuth();
      final pending = Completer<List<BusinessClaimTarget>>();
      final gateway = _ClaimGateway()..reads.add(() => pending.future);
      final provider = BusinessClaimTargetProvider(
        gateway: gateway,
        auth: auth,
      );
      var notifications = 0;
      provider.addListener(() => notifications++);

      final read = provider.reload();
      final notificationsAtDispose = notifications;
      final phaseAtDispose = provider.readPhase;
      provider.dispose();
      pending.complete(const [
        BusinessClaimTarget(
          id: _entityA,
          name: 'A',
          entityType: 'company',
          claimStatus: 'unclaimed',
        ),
      ]);
      await read;

      expect(provider.targets, isEmpty);
      expect(provider.readFailure, isNull);
      expect(provider.readPhase, phaseAtDispose);
      expect(notifications, notificationsAtDispose);
    });
  });

  group('P2-D1 applications lanes and revision', () {
    test(
      'list empty and detail null remain distinct authoritative outcomes',
      () async {
        final auth = await _authenticatedAuth();
        final gateway = _ApplicationGateway()
          ..listReads.add((_) async => const [])
          ..detailReads.add((_, __) async => null);
        final provider = BusinessApplicationProvider(
          gateway: gateway,
          auth: auth,
        );
        await provider.loadApplications();
        expect(
          provider.listReadPhase,
          BusinessRemoteReadPhase.authoritativeEmpty,
        );
        await provider.loadApplication('missing');
        expect(
          provider.detailReadPhase,
          BusinessRemoteReadPhase.authoritativeNotFound,
        );
      },
    );

    test(
      'list and detail preserve exact-key data across failure and replace',
      () async {
        final auth = await _authenticatedAuth();
        final listFailure = Completer<List<BusinessApplication>>();
        final listReplacement = Completer<List<BusinessApplication>>();
        final detailFailure = Completer<BusinessApplication?>();
        final detailReplacement = Completer<BusinessApplication?>();
        final gateway = _ApplicationGateway()
          ..listReads.add((_) async => [_application('list-old')])
          ..listReads.add((_) => listFailure.future)
          ..listReads.add((_) => listReplacement.future)
          ..detailReads.add((_, __) async => _application('detail'))
          ..detailReads.add((_, __) => detailFailure.future)
          ..detailReads.add((_, __) => detailReplacement.future);
        final provider = BusinessApplicationProvider(
          gateway: gateway,
          auth: auth,
        );

        await provider.loadApplications();
        final listRefresh = provider.loadApplications();
        expect(provider.listReadPhase, BusinessRemoteReadPhase.refreshing);
        expect(provider.applications.single.id, 'list-old');
        listFailure.completeError(
          const BusinessRemoteReadException(
            BusinessRemoteReadFailureKind.malformedResponse,
          ),
        );
        await listRefresh;
        expect(provider.applications.single.id, 'list-old');
        expect(
          provider.listReadFailure,
          BusinessRemoteReadFailureKind.malformedResponse,
        );
        final listSuccess = provider.loadApplications();
        expect(provider.applications.single.id, 'list-old');
        listReplacement.complete([_application('list-new')]);
        await listSuccess;
        expect(provider.applications.single.id, 'list-new');
        expect(provider.listReadFailure, isNull);

        await provider.loadApplication('detail');
        final detailRefresh = provider.loadApplication('detail');
        expect(provider.detailReadPhase, BusinessRemoteReadPhase.refreshing);
        expect(provider.current?.status, BusinessApplicationStatus.draft);
        detailFailure.complete(_application('detail-other'));
        await detailRefresh;
        expect(provider.current?.id, 'detail');
        expect(provider.current?.status, BusinessApplicationStatus.draft);
        expect(
          provider.detailReadFailure,
          BusinessRemoteReadFailureKind.malformedResponse,
        );
        final detailSuccess = provider.loadApplication('detail');
        expect(provider.current?.id, 'detail');
        detailReplacement.complete(
          _application('detail', status: BusinessApplicationStatus.submitted),
        );
        await detailSuccess;
        expect(provider.current?.status, BusinessApplicationStatus.submitted);
        expect(provider.detailReadFailure, isNull);
      },
    );

    test('list and detail lanes publish independently', () async {
      final auth = await _authenticatedAuth();
      final list = Completer<List<BusinessApplication>>();
      final gateway = _ApplicationGateway()
        ..listReads.add((_) => list.future)
        ..detailReads.add((_, id) async => _application(id));
      final provider = BusinessApplicationProvider(
        gateway: gateway,
        auth: auth,
      );
      final listRead = provider.loadApplications();
      await provider.loadApplication('detail');
      expect(provider.detailState, BusinessApplicationState.data);
      list.complete([_application('list')]);
      await listRead;
      expect(provider.listState, BusinessApplicationState.data);
      expect(provider.detailState, BusinessApplicationState.data);
      expect(provider.current?.id, 'detail');
    });

    test('application switch suppresses old detail result', () async {
      final auth = await _authenticatedAuth();
      final old = Completer<BusinessApplication?>();
      final gateway = _ApplicationGateway()
        ..detailReads.add((_, __) => old.future)
        ..detailReads.add((_, id) async => _application(id));
      final provider = BusinessApplicationProvider(
        gateway: gateway,
        auth: auth,
      );
      final oldRead = provider.loadApplication('old');
      await provider.loadApplication('new');
      old.complete(_application('old'));
      await oldRead;
      expect(provider.current?.id, 'new');
    });

    test(
      'accepted create starts a new revision read and blocks old empty result',
      () async {
        final auth = await _authenticatedAuth();
        final old = Completer<List<BusinessApplication>>();
        final currentRevision = Completer<List<BusinessApplication>>();
        final created = _application('created');
        final gateway = _ApplicationGateway()
          ..listReads.add((_) => old.future)
          ..listReads.add((_) => currentRevision.future)
          ..createResult = BusinessApplicationCreated(created);
        final provider = BusinessApplicationProvider(
          gateway: gateway,
          auth: auth,
        );
        final oldRead = provider.loadApplications();
        await provider.createNewDraft(metadata: const {'name': 'Created'});
        expect(provider.applicationRevision, 1);
        final newRead = provider.loadApplications();
        expect(gateway.listCalls, 2);
        expect(provider.activeListReadCount, 2);
        old.complete(const []);
        await oldRead;
        expect(provider.activeListReadCount, 1);
        expect(provider.applications.map((app) => app.id), ['created']);
        currentRevision.complete([created]);
        await newRead;
        expect(provider.activeListReadCount, 0);
        expect(provider.applications.map((app) => app.id), ['created']);
      },
    );

    test(
      'accepted submit revision blocks old detail success and failure',
      () async {
        final auth = await _authenticatedAuth();
        final draft = _application('app');
        final old = Completer<BusinessApplication?>();
        final gateway = _ApplicationGateway()
          ..detailReads.add((_, __) async => draft)
          ..detailReads.add((_, __) => old.future)
          ..submitResult = BusinessApplicationSubmitted(
            _application('app', status: BusinessApplicationStatus.submitted),
          );
        final provider = BusinessApplicationProvider(
          gateway: gateway,
          auth: auth,
        );
        await provider.loadApplication('app');
        final oldRead = provider.loadApplication('app');
        await provider.submit(draft);
        old.complete(draft);
        await oldRead;
        expect(provider.current?.status, BusinessApplicationStatus.submitted);
        expect(provider.detailReadFailure, isNull);
      },
    );

    test('accepted resubmit blocks an old detail failure', () async {
      final auth = await _authenticatedAuth();
      final correction = _application(
        'app',
        status: BusinessApplicationStatus.needsCorrection,
      );
      final old = Completer<BusinessApplication?>();
      final gateway = _ApplicationGateway()
        ..detailReads.add((_, __) async => correction)
        ..detailReads.add((_, __) => old.future)
        ..submitResult = BusinessApplicationSubmitted(
          _application('app', status: BusinessApplicationStatus.submitted),
        );
      final provider = BusinessApplicationProvider(
        gateway: gateway,
        auth: auth,
      );
      await provider.loadApplication('app');
      final oldRead = provider.loadApplication('app');
      await provider.resubmit(correction);
      old.completeError(
        const BusinessRemoteReadException(
          BusinessRemoteReadFailureKind.network,
        ),
      );
      await oldRead;
      expect(provider.current?.status, BusinessApplicationStatus.submitted);
      expect(provider.detailReadFailure, isNull);
    });
  });

  group('P2-D1 managed profile and auxiliary lane', () {
    test(
      'entity switch starts independently and suppresses old entity',
      () async {
        final auth = await _authenticatedAuth();
        final old = Completer<ManagedProfileReadResult>();
        final gateway = _ProfileGateway()
          ..profileReads[_entityA] = [() => old.future]
          ..profileReads[_entityB] = [
            () async =>
                ManagedProfileReadSuccess(_profile(_entityB, name: 'B')),
          ];
        final provider = BusinessProfileEditorProvider(
          gateway: gateway,
          directoryRepository: FakeCloudDirectoryRepository(const []),
          auth: auth,
        );
        final readA = provider.load(_entityA);
        await provider.load(_entityB);
        old.complete(ManagedProfileReadSuccess(_profile(_entityA, name: 'A')));
        await readA;
        expect(provider.entityId, _entityB);
        expect(provider.profile?.name, 'B');
      },
    );

    test('P0NOT outcome is authoritative absence, not failure', () async {
      final auth = await _authenticatedAuth();
      final gateway = _ProfileGateway()
        ..profileReads[_entityA] = [
          () async => const ManagedProfileReadNotFound(),
        ];
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository(const []),
        auth: auth,
      );
      await provider.load(_entityA);
      expect(
        provider.profileReadPhase,
        BusinessRemoteReadPhase.authoritativeNotFound,
      );
      expect(provider.profileReadFailure, isNull);
      expect(provider.profile, isNull);
    });

    test(
      'profile preserves exact-key data on malformed refresh and replaces',
      () async {
        final auth = await _authenticatedAuth();
        final malformed = Completer<ManagedProfileReadResult>();
        final replacement = Completer<ManagedProfileReadResult>();
        final gateway = _ProfileGateway()
          ..profileReads[_entityA] = [
            () async =>
                ManagedProfileReadSuccess(_profile(_entityA, name: 'A')),
            () => malformed.future,
            () => replacement.future,
          ];
        final provider = BusinessProfileEditorProvider(
          gateway: gateway,
          directoryRepository: FakeCloudDirectoryRepository(const []),
          auth: auth,
        );

        await provider.load(_entityA);
        final failedRefresh = provider.load(_entityA);
        expect(provider.profileReadPhase, BusinessRemoteReadPhase.refreshing);
        expect(provider.profile?.name, 'A');
        expect(provider.draft?.name, 'A');
        malformed.complete(
          ManagedProfileReadSuccess(_profile(_entityB, name: 'Wrong entity')),
        );
        await failedRefresh;
        expect(provider.profile?.name, 'A');
        expect(provider.draft?.name, 'A');
        expect(
          provider.profileReadFailure,
          BusinessRemoteReadFailureKind.malformedResponse,
        );

        final successfulRefresh = provider.load(_entityA);
        expect(provider.profile?.name, 'A');
        replacement.complete(
          ManagedProfileReadSuccess(_profile(_entityA, name: 'Replacement')),
        );
        await successfulRefresh;
        expect(provider.profile?.name, 'Replacement');
        expect(provider.draft?.name, 'Replacement');
        expect(provider.profileReadFailure, isNull);
      },
    );

    test('auxiliary failure preserves successful profile and draft', () async {
      final auth = await _authenticatedAuth();
      final gateway = _ProfileGateway()
        ..profileReads[_entityA] = [
          () async => ManagedProfileReadSuccess(_profile(_entityA)),
        ]
        ..categoryRead = () async => throw const BusinessRemoteReadException(
          BusinessRemoteReadFailureKind.network,
        );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository(const []),
        auth: auth,
      );
      await provider.load(_entityA);
      expect(provider.profile, isNotNull);
      expect(provider.draft, isNotNull);
      expect(provider.state, BusinessProfileEditorState.data);
      expect(provider.auxiliaryReadPhase, BusinessRemoteReadPhase.failed);
      expect(
        provider.auxiliaryReadFailure,
        BusinessRemoteReadFailureKind.network,
      );
      expect(provider.profileReadFailure, isNull);
    });

    test(
      'late auxiliary request cannot overwrite newer entity state',
      () async {
        final auth = await _authenticatedAuth();
        final oldCategories = Completer<List<ManagedSelectableCategory>>();
        final oldRegions = Completer<List<ManagedSelectableRegion>>();
        final newCategories = Completer<List<ManagedSelectableCategory>>();
        final newRegions = Completer<List<ManagedSelectableRegion>>();
        final gateway = _ProfileGateway()
          ..profileReads[_entityA] = [
            () async =>
                ManagedProfileReadSuccess(_profile(_entityA, name: 'A')),
          ]
          ..profileReads[_entityB] = [
            () async =>
                ManagedProfileReadSuccess(_profile(_entityB, name: 'B')),
          ];
        gateway.categoryRead = () => gateway.categoryCalls == 1
            ? oldCategories.future
            : newCategories.future;
        gateway.regionRead = () =>
            gateway.regionCalls == 1 ? oldRegions.future : newRegions.future;
        final provider = BusinessProfileEditorProvider(
          gateway: gateway,
          directoryRepository: FakeCloudDirectoryRepository(const []),
          auth: auth,
        );

        final oldRead = provider.load(_entityA);
        final newRead = provider.load(_entityB);
        newCategories.complete(const [
          ManagedSelectableCategory(id: 'category-new', code: 'new'),
        ]);
        newRegions.complete(const [
          ManagedSelectableRegion(id: 'region-new', code: 'new'),
        ]);
        await newRead;
        expect(provider.profile?.id, _entityB);
        expect(provider.draft?.name, 'B');
        expect(provider.selectableCategories.single.code, 'new');
        expect(provider.selectableRegions.single.code, 'new');
        expect(provider.auxiliaryReadPhase, BusinessRemoteReadPhase.loaded);
        expect(provider.auxiliaryReadFailure, isNull);

        oldCategories.complete(const [
          ManagedSelectableCategory(id: 'category-old', code: 'old'),
        ]);
        oldRegions.complete(const [
          ManagedSelectableRegion(id: 'region-old', code: 'old'),
        ]);
        await oldRead;
        expect(provider.profile?.id, _entityB);
        expect(provider.draft?.name, 'B');
        expect(provider.selectableCategories.single.code, 'new');
        expect(provider.selectableRegions.single.code, 'new');
        expect(provider.auxiliaryReadPhase, BusinessRemoteReadPhase.loaded);
        expect(provider.auxiliaryReadFailure, isNull);
      },
    );

    test('accepted save starts a new profile revision independently', () async {
      final auth = await _authenticatedAuth();
      final old = Completer<ManagedProfileReadResult>();
      final currentRevision = Completer<ManagedProfileReadResult>();
      final saved = _profile(
        _entityA,
        name: 'Saved',
        updatedAt: DateTime.utc(2024, 2),
      );
      final refreshed = _profile(
        _entityA,
        name: 'Refreshed',
        updatedAt: DateTime.utc(2024, 3),
      );
      final gateway = _ProfileGateway()
        ..profileReads[_entityA] = [
          () async => ManagedProfileReadSuccess(_profile(_entityA)),
          () => old.future,
          () => currentRevision.future,
        ]
        ..updateResult = ManagedProfileUpdateSuccess(saved);
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository(const []),
        auth: auth,
      );

      await provider.load(_entityA);
      final oldRead = provider.load(_entityA);
      expect(await provider.save(), isTrue);
      expect(provider.profileRevision, 1);
      final newRead = provider.load(_entityA);
      expect(gateway.profileCalls, 3);
      expect(provider.activeProfileReadCount, 2);

      old.complete(const ManagedProfileReadNotFound());
      await oldRead;
      expect(provider.activeProfileReadCount, 1);
      expect(provider.profile?.name, 'Saved');

      currentRevision.complete(ManagedProfileReadSuccess(refreshed));
      await newRead;
      expect(provider.activeProfileReadCount, 0);
      expect(provider.profile?.name, 'Refreshed');
    });

    test(
      'accepted save blocks old success, failure, and notFound publication',
      () async {
        for (final staleResult in <ManagedProfileReadResult>[
          ManagedProfileReadSuccess(_profile(_entityA, name: 'Stale')),
          const ManagedProfileReadFailed(BusinessRemoteReadFailureKind.network),
          const ManagedProfileReadNotFound(),
        ]) {
          final auth = await _authenticatedAuth();
          final old = Completer<ManagedProfileReadResult>();
          final saved = _profile(
            _entityA,
            name: 'Saved',
            updatedAt: DateTime.utc(2024, 2),
          );
          final gateway = _ProfileGateway()
            ..profileReads[_entityA] = [
              () async => ManagedProfileReadSuccess(_profile(_entityA)),
              () => old.future,
            ]
            ..updateResult = ManagedProfileUpdateSuccess(saved);
          final provider = BusinessProfileEditorProvider(
            gateway: gateway,
            directoryRepository: FakeCloudDirectoryRepository(const []),
            auth: auth,
          );
          await provider.load(_entityA);
          final oldRead = provider.load(_entityA);
          expect(await provider.save(), isTrue);
          old.complete(staleResult);
          await oldRead;
          expect(provider.profile?.name, 'Saved');
          expect(provider.profileReadFailure, isNull);
          expect(provider.state, BusinessProfileEditorState.saveSuccess);
        }
      },
    );
  });

  test('authority boundary contains no Directory or legacy fallback', () {
    final paths = [
      'lib/features/business/presentation/providers/managed_businesses_provider.dart',
      'lib/features/business/presentation/providers/business_application_provider.dart',
      'lib/features/business/presentation/providers/business_claim_target_provider.dart',
      'lib/features/business/data/supabase_business_membership_gateway.dart',
      'lib/features/business/data/supabase_business_application_gateway.dart',
      'lib/features/business/data/supabase_business_claim_target_gateway.dart',
    ];
    final source = paths.map((path) => File(path).readAsStringSync()).join();
    expect(source, isNot(contains('LocalServiceBusinessRepository')));
    expect(source, isNot(contains('sb_profiles')));
    expect(source, isNot(contains('legacyDirectoryRepo')));
    expect(RegExp(r'''['"]service_role['"]''').hasMatch(source), isFalse);
    expect(
      File(
        'lib/features/business/data/supabase_business_claim_target_gateway.dart',
      ).readAsStringSync(),
      isNot(contains('.insert(')),
    );
  });
}
