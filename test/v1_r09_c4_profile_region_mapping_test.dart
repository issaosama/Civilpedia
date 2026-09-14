import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/di/app_dependencies.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/core/network/remote_operation_policy.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_bootstrap_coordinator.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/profile_bootstrap_outcome.dart';
import 'package:civilpedia/features/profile/data/region_preference.dart';
import 'package:civilpedia/features/profile/data/region_preference_gateway.dart';
import 'package:civilpedia/features/profile/data/supabase_personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/timed_profile_gateways.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/profile_operation_result.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';

import 'fakes/fake_auth_gateway.dart';

const _userA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _userB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _karkhId = '10000000-0000-4000-8000-000000000101';
const _rusafaId = '10000000-0000-4000-8000-000000000102';

const _sessionA = AuthSession(
  userId: _userA,
  email: 'a@civilpedia.com',
  displayName: 'Engineer A',
);

// ---------------------------------------------------------------------------
// Gateway classification helpers
// ---------------------------------------------------------------------------
class _RecoveryAuthGateway extends FakeAuthGateway
    implements AuthRecoveryGateway {
  _RecoveryAuthGateway() : super(restoredSession: _sessionA);
  @override
  AuthRecoveryStatus recoveryStatus = AuthRecoveryStatus.none;
  @override
  bool get canAccountAuthorityBeGranted =>
      recoveryStatus == AuthRecoveryStatus.none &&
      super.canAccountAuthorityBeGranted;
  @override
  Future<AuthRecoveryResult> retryAuthRecovery() async =>
      AuthRecoveryResult.blocked;
}

class _LookupBarrier extends _FakePreferenceGateway {
  final entered = Completer<void>();
  final resume = Completer<void>();
  @override
  Future<String?> resolvePreferenceIdByCode(String code) async {
    entered.complete();
    await resume.future;
    return super.resolvePreferenceIdByCode(code);
  }
}

void _surgicalCorrectionTests() {
  group('C4 surgical corrections', () {
    for (final status in [
      AuthRecoveryStatus.exchangeTimedOutPending,
      AuthRecoveryStatus.exchangeNeutralizing,
      AuthRecoveryStatus.exchangeBlockedCleanupFailure,
      AuthRecoveryStatus.exchangeBlockedUnattributed,
      AuthRecoveryStatus.localResetRestartRequired,
    ]) {
      test(
        'authenticated then $status blocks save and post-auth retry',
        () async {
          final gateway = _RecoveryAuthGateway();
          var pipelineCalls = 0;
          final auth = AuthProvider(
            gateway: gateway,
            onPostAuth: (_) async {
              pipelineCalls++;
              return PostAuthOutcome.retryableFailure;
            },
          );
          final cloud = _MappingCloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            );
          final preference = _FakePreferenceGateway();
          final profile = UserProfileProvider(
            repository: _MemoryProfileRepository(),
            cloudProfileGateway: cloud,
            regionPreferenceGateway: preference,
            auth: auth,
          );
          await auth.restoreSession();
          await profile.ensureCloudProfileLoaded();
          expect(auth.isLoggedIn, isTrue);
          final session = auth.session;
          final generation = auth.generation;
          gateway.recoveryStatus = status;
          gateway.emit(
            const AuthEvent(type: AuthEventType.authRecoveryChanged),
          );
          await _settle();
          expect(auth.session, same(session));
          expect(auth.isLoggedIn, isTrue);
          expect(auth.isAuthorityBlocked, isTrue);
          final result = await profile.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
            regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
          );
          await auth.retryPostAuth();
          expect(result.cause, ProfileOperationCause.authorityBlocked);
          expect(cloud.saveCalls, 0);
          expect(preference.lookupCalls, 0);
          expect(pipelineCalls, 1);
          expect(auth.generation, generation);
          expect(auth.recoveryStatus, status);
          profile.dispose();
          auth.dispose();
        },
      );
    }

    for (final block in [false, true]) {
      test('lookup barrier restriction=$block prevents mutation', () async {
        final gateway = _RecoveryAuthGateway();
        final auth = AuthProvider(gateway: gateway);
        final cloud = _MappingCloudGateway()
          ..cloud = const CloudProfile(
            userId: _userA,
            roleCode: 'site_engineer',
          );
        final lookup = _LookupBarrier();
        final profile = UserProfileProvider(
          repository: _MemoryProfileRepository(),
          cloudProfileGateway: cloud,
          regionPreferenceGateway: lookup,
          auth: auth,
        );
        await auth.restoreSession();
        await profile.ensureCloudProfileLoaded();
        final run = profile.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
          regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
        );
        await lookup.entered.future;
        if (block) {
          gateway.recoveryStatus =
              AuthRecoveryStatus.exchangeBlockedUnattributed;
          gateway.emit(
            const AuthEvent(type: AuthEventType.authRecoveryChanged),
          );
        } else {
          cloud.cloud = const CloudProfile(
            userId: _userB,
            roleCode: 'general_user',
          );
          gateway.emit(
            const AuthEvent(
              type: AuthEventType.signedIn,
              session: AuthSession(
                userId: _userB,
                email: 'b@example.com',
                displayName: 'B',
              ),
            ),
          );
        }
        await _settle();
        lookup.resume.complete();
        final result = await run;
        expect(
          result.cause,
          block
              ? ProfileOperationCause.authorityBlocked
              : ProfileOperationCause.sessionLost,
        );
        expect(cloud.saveCalls, 0);
        expect(cloud.cloud!.roleCode, block ? 'site_engineer' : 'general_user');
        expect(auth.currentUserId, block ? _userA : _userB);
        profile.dispose();
        auth.dispose();
      });
    }

    final failures =
        <(Object, ProfileBootstrapOutcome, PostAuthLifecycleState)>[
          (
            const CloudProfileAuthException(),
            ProfileBootstrapOutcome.authFailure,
            PostAuthLifecycleState.authFailure,
          ),
          (
            const CloudProfilePermissionDeniedException(),
            ProfileBootstrapOutcome.permissionDenied,
            PostAuthLifecycleState.permissionDenied,
          ),
          (
            const CloudProfileInvalidDataException(),
            ProfileBootstrapOutcome.invalidData,
            PostAuthLifecycleState.invalidData,
          ),
          (
            const CloudProfileParseException('bad row'),
            ProfileBootstrapOutcome.malformedResponse,
            PostAuthLifecycleState.malformedResponse,
          ),
          (
            const CloudProfileUnexpectedException(),
            ProfileBootstrapOutcome.unexpected,
            PostAuthLifecycleState.unexpected,
          ),
          (
            const PostgrestException(message: 'unknown', code: 'XX999'),
            ProfileBootstrapOutcome.unexpected,
            PostAuthLifecycleState.unexpected,
          ),
          (
            Exception('untyped backend'),
            ProfileBootstrapOutcome.unexpected,
            PostAuthLifecycleState.unexpected,
          ),
          (
            const SocketException('offline'),
            ProfileBootstrapOutcome.failure,
            PostAuthLifecycleState.retryableFailure,
          ),
          (
            TimeoutException('deadline'),
            ProfileBootstrapOutcome.failure,
            PostAuthLifecycleState.retryableFailure,
          ),
          (
            const InfrastructureFailureException(
              InfrastructureFailure(
                InfrastructureFailureKind.serviceUnavailable,
              ),
            ),
            ProfileBootstrapOutcome.failure,
            PostAuthLifecycleState.retryableFailure,
          ),
        ];
    for (var i = 0; i < failures.length; i++) {
      for (final reread in [false, true]) {
        test(
          'typed bootstrap propagation $i reread=$reread preserves session',
          () async {
            final (error, expected, lifecycle) = failures[i];
            final remote = _M2FakeRemoteGateway()
              ..cloudProfile = const CloudProfile(
                userId: _userA,
                roleCode: 'site_engineer',
              );
            if (reread) {
              remote.rereadError = error;
            } else {
              remote.updateError = error;
            }
            final repo = _MemoryProfileRepository(
              profile: _localProfile(
                userType: CivilUserType.siteEngineer,
                regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
              ),
            );
            final coordinator = _coordinator(repo, remote);
            final gateway = FakeAuthGateway(restoredSession: _sessionA);
            var pipelineCalls = 0;
            final auth = AuthProvider(
              gateway: gateway,
              onPostAuth: (session) async {
                pipelineCalls++;
                final result = await coordinator.bootstrap(
                  userId: session.userId,
                );
                expect(result, expected);
                return AppDependencies.mapBootstrapOutcome(result);
              },
            );
            await auth.restoreSession();
            expect(auth.postAuthState, lifecycle);
            expect(auth.isLoggedIn, isTrue);
            expect(auth.currentUserId, _userA);
            expect(gateway.signOutCalls, 0);
            expect(repo.profile!.futureCloudUserId, isNull);
            if (lifecycle != PostAuthLifecycleState.retryableFailure) {
              await auth.retryPostAuth();
              expect(pipelineCalls, 1);
            }
            auth.dispose();
          },
        );
      }
    }

    for (final code in ['PGRST301', 'PGRST302', 'PGRST303', '401']) {
      for (final read in [false, true]) {
        test('production HTTP $code read=$read is auth rejection', () async {
          final client = SupabaseClient(
            'http://localhost:54321',
            'anon',
            httpClient: _DelegatingHttpClient(
              (_) async => http.Response(
                jsonEncode({
                  'code': code,
                  'message': 'private backend details',
                }),
                401,
              ),
            ),
          );
          final gateway = SupabasePersonalProfileRemoteGateway(client: client);
          await expectLater(
            read
                ? gateway.fetchByUserId(_userA)
                : gateway.updateRegionPreferenceId(
                    userId: _userA,
                    regionPreferenceId: _karkhId,
                  ),
            throwsA(isA<CloudProfileAuthException>()),
          );
          await client.dispose();
        });
      }
    }
    test(
      'production uncertain retry has own-user and null-only predicates',
      () async {
        late http.BaseRequest captured;
        final client = SupabaseClient(
          'http://localhost:54321',
          'anon',
          httpClient: _DelegatingHttpClient((request) async {
            captured = request;
            return http.Response('', 204);
          }),
        );
        final gateway = TimedPersonalProfileRemoteGateway(
          delegate: SupabasePersonalProfileRemoteGateway(client: client),
        );
        await gateway.saveEditableFieldsIfRegionAbsent(
          userId: _userA,
          roleCode: 'consultant_engineer',
          regionPreferenceId: _karkhId,
        );
        expect(captured.url.queryParameters['user_id'], 'eq.$_userA');
        expect(captured.url.queryParameters['region_preference_id'], 'is.null');
        expect(gateway.isProfileMutationPending(_userA), isFalse);
        await client.dispose();
      },
    );

    test(
      'canonical SDK session exceptions differ from transport and unknown',
      () {
        expect(
          classifyProfileFailure(AuthSessionMissingException()),
          ProfileFailureKind.auth,
        );
        expect(
          classifyProfileFailure(
            const AuthException('unauthorized', statusCode: '401'),
          ),
          ProfileFailureKind.auth,
        );
        expect(
          classifyProfileFailure(
            AuthRetryableFetchException(message: 'network'),
          ),
          ProfileFailureKind.infrastructure,
        );
        for (final code in <String?>[null, 'PGRST300', 'XX999', '22not-sql']) {
          expect(
            classifyProfileFailure(
              PostgrestException(message: 'JWT expired', code: code),
            ),
            ProfileFailureKind.unexpected,
          );
        }
      },
    );

    test(
      'real malformed HTTP row reaches strict parser without publication or logout',
      () async {
        var mutated = false;
        final client = SupabaseClient(
          'http://localhost:54321',
          'anon',
          httpClient: _DelegatingHttpClient((request) async {
            if (request.method == 'PATCH') {
              mutated = true;
              return http.Response('', 204);
            }
            return http.Response(
              jsonEncode([
                {
                  'user_id': _userA,
                  'role_code': mutated ? 42 : 'site_engineer',
                },
              ]),
              200,
            );
          }),
        );
        final gateway = SupabasePersonalProfileRemoteGateway(client: client);
        final authGateway = FakeAuthGateway(restoredSession: _sessionA);
        final auth = AuthProvider(gateway: authGateway);
        final profile = UserProfileProvider(
          repository: _MemoryProfileRepository(),
          cloudProfileGateway: gateway,
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );
        await auth.restoreSession();
        await profile.ensureCloudProfileLoaded();
        final previous = profile.authenticatedProfile;
        final result = await profile.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
        );
        expect(result.cause, ProfileOperationCause.malformedResponse);
        expect(profile.authenticatedProfile, same(previous));
        expect(auth.isLoggedIn, isTrue);
        expect(authGateway.signOutCalls, 0);
        await expectLater(
          gateway.fetchByUserId(_userA),
          throwsA(isA<CloudProfileParseException>()),
        );
        profile.dispose();
        auth.dispose();
        await client.dispose();
      },
    );

    for (final sameRegion in [false, true]) {
      test(
        'uncertain mutation retry matching=$sameRegion rereads without second write',
        () async {
          final cloud = _MappingCloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            )
            ..saveInfrastructure = const InfrastructureFailure(
              InfrastructureFailureKind.timeout,
            );
          final auth = AuthProvider(
            gateway: FakeAuthGateway(restoredSession: _sessionA),
          );
          final profile = UserProfileProvider(
            repository: _MemoryProfileRepository(),
            cloudProfileGateway: cloud,
            regionPreferenceGateway: _FakePreferenceGateway(),
            auth: auth,
          );
          await auth.restoreSession();
          await profile.ensureCloudProfileLoaded();
          final first = await profile.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
            regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
          );
          expect(first.cause, ProfileOperationCause.retryableFailure);
          cloud.saveInfrastructure = null;
          cloud.rereadProfile = CloudProfile(
            userId: _userA,
            roleCode: 'consultant_engineer',
            regionPreferenceId: sameRegion ? _karkhId : _rusafaId,
          );
          final retry = await profile.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
            regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
          );
          expect(retry.succeeded, sameRegion);
          if (!sameRegion)
            expect(retry.cause, ProfileOperationCause.profileConflict);
          expect(cloud.saveCalls, 1);
          expect(
            profile.authenticatedProfile!.regionPreferenceId,
            sameRegion ? _karkhId : _rusafaId,
          );
          profile.dispose();
          auth.dispose();
        },
      );
    }

    for (final lateFailure in [false, true]) {
      test(
        'real deadline retry waits for raw settlement, lateFailure=$lateFailure',
        () async {
          final raw = _GatedMappingCloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            );
          final timed = TimedPersonalProfileRemoteGateway(
            delegate: raw,
            mutationTimeout: const Duration(milliseconds: 5),
          );
          final auth = AuthProvider(
            gateway: FakeAuthGateway(restoredSession: _sessionA),
          );
          final profile = UserProfileProvider(
            repository: _MemoryProfileRepository(),
            cloudProfileGateway: timed,
            regionPreferenceGateway: _FakePreferenceGateway(),
            auth: auth,
          );
          await auth.restoreSession();
          await profile.ensureCloudProfileLoaded();
          Future<ProfileOperationResult> save() =>
              profile.saveRoleAndRegionPreference(
                roleCode: 'consultant_engineer',
                regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
              );
          expect((await save()).cause, ProfileOperationCause.retryableFailure);
          expect(timed.isProfileMutationPending(_userA), isTrue);
          expect((await save()).cause, ProfileOperationCause.retryableFailure);
          expect(raw.saveCalls, 1, reason: 'no competing raw write');
          if (lateFailure)
            raw.saveInfrastructure = const InfrastructureFailure(
              InfrastructureFailureKind.network,
            );
          raw.release();
          await _settle();
          expect(timed.isProfileMutationPending(_userA), isFalse);
          raw.saveInfrastructure = null;
          final settled = await save();
          expect(settled.succeeded, isTrue);
          expect(raw.saveCalls, lateFailure ? 2 : 1);
          expect(profile.authenticatedProfile!.regionPreferenceId, _karkhId);
          expect(auth.isLoggedIn, isTrue);
          profile.dispose();
          auth.dispose();
        },
      );
    }

    test(
      'same-user generation rollover blocks retry while raw mutation pending, then rereads after settlement',
      () async {
        final raw = _GatedMappingCloudGateway()
          ..cloud = const CloudProfile(
            userId: _userA,
            roleCode: 'site_engineer',
          );
        final timed = TimedPersonalProfileRemoteGateway(
          delegate: raw,
          mutationTimeout: const Duration(milliseconds: 5),
        );
        final fakeGateway = FakeAuthGateway(restoredSession: _sessionA);
        final auth = AuthProvider(gateway: fakeGateway);
        final profile = UserProfileProvider(
          repository: _MemoryProfileRepository(),
          cloudProfileGateway: timed,
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );
        await auth.restoreSession();
        await profile.ensureCloudProfileLoaded();

        Future<ProfileOperationResult> save() =>
            profile.saveRoleAndRegionPreference(
              roleCode: 'consultant_engineer',
              regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
            );

        final g1 = auth.generation;
        expect(auth.currentUserId, _userA);

        // g1: start a region save; the raw mutation outlives the deadline.
        final first = await save();
        expect(first.cause, ProfileOperationCause.retryableFailure);
        expect(timed.isProfileMutationPending(_userA), isTrue);
        expect(raw.saveCalls, 1);

        // Same user signs out and back in: generation rolls over.
        await auth.signOut();
        await _settle();
        expect(auth.isLoggedIn, isFalse);

        await auth.restoreSession();
        await profile.ensureCloudProfileLoaded();
        expect(auth.isLoggedIn, isTrue);
        expect(auth.currentUserId, _userA);
        final g2 = auth.generation;
        expect(g2, isNot(g1));
        expect(profile.authenticatedProfile?.roleCode, 'site_engineer');
        expect(profile.authenticatedProfile?.regionPreferenceId, isNull);

        // g2: a new save request while the g1 raw mutation is still pending.
        final second = await save();
        expect(timed.isProfileMutationPending(_userA), isTrue);
        expect(raw.saveCalls, 1, reason: 'no competing write after rollover');
        expect(second.cause, ProfileOperationCause.retryableFailure);
        expect(second.succeeded, isFalse);
        // The g1 operation result must not be adopted into the g2 session.
        expect(profile.authenticatedProfile?.roleCode, 'site_engineer');
        expect(profile.authenticatedProfile?.regionPreferenceId, isNull);

        // Settle the original raw mutation.
        raw.release();
        await _settle();
        expect(timed.isProfileMutationPending(_userA), isFalse);

        // After settlement: authoritative reread finds the region already set;
        // no second backend write, no adoption of the g1 operation result.
        final third = await save();
        expect(third.succeeded, isTrue);
        expect(third.wasNoOp, isTrue);
        expect(raw.saveCalls, 1, reason: 'no duplicate write after settlement');
        expect(profile.authenticatedProfile?.userId, _userA);
        expect(profile.authenticatedProfile?.roleCode, 'consultant_engineer');
        expect(profile.authenticatedProfile?.regionPreferenceId, _karkhId);
        expect(auth.generation, g2);

        profile.dispose();
        auth.dispose();
      },
    );

    test(
      'definite invalid rejection allows corrected input without a retry lock',
      () async {
        final cloud = _MappingCloudGateway()
          ..cloud = const CloudProfile(
            userId: _userA,
            roleCode: 'site_engineer',
          )
          ..saveInvalidData = true;
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        final profile = UserProfileProvider(
          repository: _MemoryProfileRepository(),
          cloudProfileGateway: cloud,
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );
        await auth.restoreSession();
        await profile.ensureCloudProfileLoaded();
        expect(
          (await profile.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
            regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
          )).cause,
          ProfileOperationCause.invalidData,
        );
        cloud.saveInvalidData = false;
        final corrected = await profile.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
          regionPreferenceCode: RegionPreferenceCode.baghdadRusafa,
        );
        expect(corrected.succeeded, isTrue);
        expect(cloud.saveCalls, 2);
        expect(profile.authenticatedProfile!.regionPreferenceId, _rusafaId);
        profile.dispose();
        auth.dispose();
      },
    );

    test(
      'bootstrap gate invalidated during lookup prevents region mutation',
      () async {
        var allowed = true;
        final lookup = _LookupBarrier();
        final remote = _M2FakeRemoteGateway()
          ..cloudProfile = const CloudProfile(
            userId: _userA,
            roleCode: 'site_engineer',
          );
        final repo = _MemoryProfileRepository(
          profile: _localProfile(
            userType: CivilUserType.siteEngineer,
            regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
          ),
        );
        final coordinator = PersonalProfileBootstrapCoordinator(
          localRepository: repo,
          remoteGateway: remote,
          regionPreferenceGateway: lookup,
        );
        final run = coordinator.bootstrap(
          userId: _userA,
          canContinue: () => allowed,
        );
        await lookup.entered.future;
        allowed = false;
        lookup.resume.complete();
        expect(await run, ProfileBootstrapOutcome.authFailure);
        expect(remote.updatePreferenceCalls, 0);
        expect(repo.profile!.futureCloudUserId, isNull);
      },
    );
  });
}

void main() {
  _surgicalCorrectionTests();
  group('V1-R09 C4 M2 — profile-region error mapping', () {
    group('SupabasePersonalProfileRemoteGateway SQLSTATE classification', () {
      test('42501 → permission denied', () {
        final error = PostgrestException(
          message: 'permission denied for table profiles',
          code: '42501',
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isPermissionDenied(error),
          isTrue,
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUpdateInvalidDataRejection(
            error,
          ),
          isFalse,
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUnexpectedBackendFailure(
            error,
          ),
          isFalse,
        );
      });

      test('23502 → invalid/domain data', () {
        final error = PostgrestException(
          message: 'null value in column',
          code: '23502',
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUpdateInvalidDataRejection(
            error,
          ),
          isTrue,
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUnexpectedBackendFailure(
            error,
          ),
          isFalse,
        );
      });

      test('23503 → invalid/domain data', () {
        final error = PostgrestException(
          message: 'foreign key violation',
          code: '23503',
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUpdateInvalidDataRejection(
            error,
          ),
          isTrue,
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUnexpectedBackendFailure(
            error,
          ),
          isFalse,
        );
      });

      test('23514 → invalid/domain data', () {
        final error = PostgrestException(
          message: 'check constraint violation',
          code: '23514',
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUpdateInvalidDataRejection(
            error,
          ),
          isTrue,
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUnexpectedBackendFailure(
            error,
          ),
          isFalse,
        );
      });

      test('23P01 → invalid/domain data', () {
        final error = PostgrestException(
          message: 'exclusion constraint violation',
          code: '23P01',
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUpdateInvalidDataRejection(
            error,
          ),
          isTrue,
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUnexpectedBackendFailure(
            error,
          ),
          isFalse,
        );
      });

      test('SQLSTATE class 22xxx → invalid/domain data', () {
        final error = PostgrestException(
          message: 'invalid text representation',
          code: '22P02',
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUpdateInvalidDataRejection(
            error,
          ),
          isTrue,
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUnexpectedBackendFailure(
            error,
          ),
          isFalse,
        );
      });

      test(
        'UPDATE-time 23505 → invalid/domain data, NOT provisioning success',
        () {
          final error = PostgrestException(
            message: 'duplicate key value violates unique constraint',
            code: '23505',
          );
          expect(
            SupabasePersonalProfileRemoteGateway.isUpdateInvalidDataRejection(
              error,
            ),
            isTrue,
          );
          expect(
            SupabasePersonalProfileRemoteGateway.isUnexpectedBackendFailure(
              error,
            ),
            isFalse,
          );
        },
      );

      test('unknown SQLSTATE → unexpected backend failure', () {
        final error = PostgrestException(
          message: 'something went wrong',
          code: 'XX999',
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isPermissionDenied(error),
          isFalse,
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUpdateInvalidDataRejection(
            error,
          ),
          isFalse,
        );
        expect(
          SupabasePersonalProfileRemoteGateway.isUnexpectedBackendFailure(
            error,
          ),
          isTrue,
        );
      });
    });

    // -----------------------------------------------------------------------
    // Production gateway behavior via controlled HTTP client
    // -----------------------------------------------------------------------
    group('updateRegionPreferenceId production mapping', () {
      http.Response _errorResponse(int statusCode, String sqlState) {
        return http.Response(
          jsonEncode({
            'message': 'backend error',
            'code': sqlState,
            'details': 'details',
            'hint': 'hint',
          }),
          statusCode,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      http.Response _okResponse() => http.Response(
        jsonEncode([
          {'user_id': _userA, 'role_code': 'site_engineer'},
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

      Future<SupabasePersonalProfileRemoteGateway> _gateway(
        Future<http.Response> Function(http.BaseRequest) handler,
      ) async {
        final client = SupabaseClient(
          'http://localhost:54321',
          'anon',
          httpClient: _DelegatingHttpClient(handler),
        );
        return SupabasePersonalProfileRemoteGateway(client: client);
      }

      test('maps 42501 to CloudProfilePermissionDeniedException', () async {
        late http.BaseRequest captured;
        final gateway = await _gateway((request) async {
          captured = request;
          return _errorResponse(403, '42501');
        });

        await expectLater(
          gateway.updateRegionPreferenceId(
            userId: _userA,
            regionPreferenceId: _karkhId,
          ),
          throwsA(isA<CloudProfilePermissionDeniedException>()),
        );

        expect(captured.url.query, contains('region_preference_id=is.null'));
      });

      test('maps UPDATE 23505 to CloudProfileInvalidDataException', () async {
        final gateway = await _gateway(
          (_) async => _errorResponse(409, '23505'),
        );

        await expectLater(
          gateway.updateRegionPreferenceId(
            userId: _userA,
            regionPreferenceId: _karkhId,
          ),
          throwsA(isA<CloudProfileInvalidDataException>()),
        );
      });

      test(
        'maps unknown SQLSTATE to CloudProfileUnexpectedException',
        () async {
          final gateway = await _gateway(
            (_) async => _errorResponse(500, 'XX999'),
          );

          await expectLater(
            gateway.updateRegionPreferenceId(
              userId: _userA,
              regionPreferenceId: _karkhId,
            ),
            throwsA(isA<CloudProfileUnexpectedException>()),
          );
        },
      );

      test('success includes null-only predicate in query', () async {
        late http.BaseRequest captured;
        final gateway = await _gateway((request) async {
          captured = request;
          return _okResponse();
        });

        await gateway.updateRegionPreferenceId(
          userId: _userA,
          regionPreferenceId: _karkhId,
        );

        expect(captured.method, 'PATCH');
        expect(captured.url.query, contains('region_preference_id=is.null'));
        expect(captured.url.query, contains('user_id=eq.$_userA'));
      });
    });

    // -----------------------------------------------------------------------
    // Provider error mapping and reread behavior
    // -----------------------------------------------------------------------
    group('UserProfileProvider saveRoleAndRegionPreference', () {
      test(
        'invalidData exception maps to invalidData, not retryable',
        () async {
          final gateway = _MappingCloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            )
            ..saveInvalidData = true;
          final auth = AuthProvider(
            gateway: FakeAuthGateway(restoredSession: _sessionA),
          );
          final profileProvider = UserProfileProvider(
            repository: _MemoryProfileRepository(),
            cloudProfileGateway: gateway,
            regionPreferenceGateway: _FakePreferenceGateway(),
            auth: auth,
          );
          await auth.restoreSession();
          await profileProvider.ensureCloudProfileLoaded();

          final result = await profileProvider.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
          );

          expect(result.succeeded, isFalse);
          expect(result.cause, ProfileOperationCause.invalidData);
          expect(gateway.saveCalls, 1);

          profileProvider.dispose();
          auth.dispose();
        },
      );

      test(
        'unexpected backend failure maps to unexpected, not retryable',
        () async {
          final gateway = _MappingCloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            )
            ..saveUnexpected = true;
          final auth = AuthProvider(
            gateway: FakeAuthGateway(restoredSession: _sessionA),
          );
          final profileProvider = UserProfileProvider(
            repository: _MemoryProfileRepository(),
            cloudProfileGateway: gateway,
            regionPreferenceGateway: _FakePreferenceGateway(),
            auth: auth,
          );
          await auth.restoreSession();
          await profileProvider.ensureCloudProfileLoaded();

          final result = await profileProvider.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
          );

          expect(result.succeeded, isFalse);
          expect(result.cause, ProfileOperationCause.unexpected);

          profileProvider.dispose();
          auth.dispose();
        },
      );

      test('infrastructure timeout maps to retryableFailure', () async {
        final gateway = _MappingCloudGateway()
          ..cloud = const CloudProfile(
            userId: _userA,
            roleCode: 'site_engineer',
          )
          ..saveInfrastructure = const InfrastructureFailure(
            InfrastructureFailureKind.timeout,
          );
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        final profileProvider = UserProfileProvider(
          repository: _MemoryProfileRepository(),
          cloudProfileGateway: gateway,
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );
        await auth.restoreSession();
        await profileProvider.ensureCloudProfileLoaded();

        final result = await profileProvider.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
        );

        expect(result.succeeded, isFalse);
        expect(result.cause, ProfileOperationCause.retryableFailure);

        profileProvider.dispose();
        auth.dispose();
      });

      test(
        'infrastructure serviceUnavailable maps to retryableFailure',
        () async {
          final gateway = _MappingCloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            )
            ..saveInfrastructure = const InfrastructureFailure(
              InfrastructureFailureKind.serviceUnavailable,
            );
          final auth = AuthProvider(
            gateway: FakeAuthGateway(restoredSession: _sessionA),
          );
          final profileProvider = UserProfileProvider(
            repository: _MemoryProfileRepository(),
            cloudProfileGateway: gateway,
            regionPreferenceGateway: _FakePreferenceGateway(),
            auth: auth,
          );
          await auth.restoreSession();
          await profileProvider.ensureCloudProfileLoaded();

          final result = await profileProvider.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
          );

          expect(result.succeeded, isFalse);
          expect(result.cause, ProfileOperationCause.retryableFailure);

          profileProvider.dispose();
          auth.dispose();
        },
      );

      test(
        'network failure keeps user authenticated and session intact',
        () async {
          final gateway = _MappingCloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            )
            ..saveInfrastructure = const InfrastructureFailure(
              InfrastructureFailureKind.network,
            );
          final auth = AuthProvider(
            gateway: FakeAuthGateway(restoredSession: _sessionA),
          );
          final profileProvider = UserProfileProvider(
            repository: _MemoryProfileRepository(),
            cloudProfileGateway: gateway,
            regionPreferenceGateway: _FakePreferenceGateway(),
            auth: auth,
          );
          await auth.restoreSession();
          await profileProvider.ensureCloudProfileLoaded();

          final result = await profileProvider.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
          );

          expect(result.succeeded, isFalse);
          expect(result.cause, ProfileOperationCause.retryableFailure);
          expect(auth.isLoggedIn, isTrue);
          expect(auth.session?.userId, _userA);
          expect(profileProvider.isCloudBound, isTrue);

          profileProvider.dispose();
          auth.dispose();
        },
      );

      test(
        'local submitted region is not published before authoritative reread',
        () async {
          final gateway = _MappingCloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            );
          final auth = AuthProvider(
            gateway: FakeAuthGateway(restoredSession: _sessionA),
          );
          final profileProvider = UserProfileProvider(
            repository: _MemoryProfileRepository(),
            cloudProfileGateway: gateway,
            regionPreferenceGateway: _FakePreferenceGateway(),
            auth: auth,
          );
          await auth.restoreSession();
          await profileProvider.ensureCloudProfileLoaded();

          // Set the reread to return a DIFFERENT region than submitted.
          gateway.rereadProfile = const CloudProfile(
            userId: _userA,
            roleCode: 'consultant_engineer',
            regionPreferenceId: _rusafaId,
          );

          final result = await profileProvider.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
            regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
          );

          expect(result.succeeded, isFalse);
          expect(result.cause, ProfileOperationCause.profileConflict);
          expect(result.profile, isNull);
          expect(gateway.saveCalls, 1);
          expect(
            profileProvider.authenticatedProfile?.regionPreferenceId,
            _rusafaId,
          );

          profileProvider.dispose();
          auth.dispose();
        },
      );

      test('reread failure does not report false success', () async {
        final gateway = _MappingCloudGateway()
          ..cloud = const CloudProfile(
            userId: _userA,
            roleCode: 'site_engineer',
          )
          ..rereadError = const SocketException('offline');
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        final profileProvider = UserProfileProvider(
          repository: _MemoryProfileRepository(),
          cloudProfileGateway: gateway,
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );
        await auth.restoreSession();
        await profileProvider.ensureCloudProfileLoaded();

        final result = await profileProvider.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
        );

        expect(result.succeeded, isFalse);
        expect(result.cause, ProfileOperationCause.retryableFailure);
        expect(
          result.profile,
          isNull,
          reason: 'no fabricated profile on reread failure',
        );

        profileProvider.dispose();
        auth.dispose();
      });

      test('reread foreign ownership does not report false success', () async {
        final gateway = _MappingCloudGateway()
          ..cloud = const CloudProfile(
            userId: _userA,
            roleCode: 'site_engineer',
          )
          ..rereadProfile = const CloudProfile(
            userId: _userB,
            roleCode: 'consultant_engineer',
          );
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        final profileProvider = UserProfileProvider(
          repository: _MemoryProfileRepository(),
          cloudProfileGateway: gateway,
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );
        await auth.restoreSession();
        await profileProvider.ensureCloudProfileLoaded();

        final result = await profileProvider.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
        );

        expect(result.succeeded, isFalse);
        expect(result.cause, ProfileOperationCause.ownershipConflict);

        profileProvider.dispose();
        auth.dispose();
      });

      test(
        'A→B session-generation change during save rejects result',
        () async {
          final fakeGateway = FakeAuthGateway(restoredSession: _sessionA);
          final auth = AuthProvider(gateway: fakeGateway);
          final gateway = _GatedMappingCloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            );
          final profileProvider = UserProfileProvider(
            repository: _MemoryProfileRepository(),
            cloudProfileGateway: gateway,
            regionPreferenceGateway: _FakePreferenceGateway(),
            auth: auth,
          );
          await auth.restoreSession();
          await profileProvider.ensureCloudProfileLoaded();

          final saveRun = profileProvider.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
          );
          await _settle();

          // Simulate an account switch while the save is parked on the gate.
          fakeGateway.restoredSession = const AuthSession(
            userId: _userB,
            email: 'b@civilpedia.com',
            displayName: 'Engineer B',
          );
          fakeGateway.emit(
            const AuthEvent(
              type: AuthEventType.signedIn,
              session: AuthSession(
                userId: _userB,
                email: 'b@civilpedia.com',
                displayName: 'Engineer B',
              ),
            ),
          );
          await _settle();

          gateway.release();
          final result = await saveRun;

          expect(result.succeeded, isFalse);
          expect(result.cause, ProfileOperationCause.sessionLost);
          expect(
            result.profile,
            isNull,
            reason: 'stale A result is not published',
          );

          profileProvider.dispose();
          auth.dispose();
        },
      );

      test(
        'C3 recovery-blocked auth state denies mutation before backend',
        () async {
          final gateway = _MappingCloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            );
          final fakeGateway = FakeAuthGateway(
            restoredSession: _sessionA,
            blockAccountAuthority: true,
          );
          final auth = AuthProvider(gateway: fakeGateway);
          final profileProvider = UserProfileProvider(
            repository: _MemoryProfileRepository(),
            cloudProfileGateway: gateway,
            regionPreferenceGateway: _FakePreferenceGateway(),
            auth: auth,
          );
          await auth.restoreSession();
          await _settle();

          expect(
            auth.isLoggedIn,
            isFalse,
            reason: 'blocked authority is not authenticated',
          );

          final result = await profileProvider.saveRoleAndRegionPreference(
            roleCode: 'consultant_engineer',
          );

          expect(result.succeeded, isFalse);
          expect(result.cause, ProfileOperationCause.unauthenticated);
          expect(
            gateway.saveCalls,
            0,
            reason: 'backend mutation must not run while blocked',
          );

          profileProvider.dispose();
          auth.dispose();
        },
      );
    });

    // -----------------------------------------------------------------------
    // Bootstrap coordinator M2 fill + authoritative reread
    // -----------------------------------------------------------------------
    group('PersonalProfileBootstrapCoordinator M2 region fill', () {
      test(
        'successful fill performs authoritative reread before binding',
        () async {
          final remote = _M2FakeRemoteGateway()
            ..cloudProfile = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            );
          final repo = _MemoryProfileRepository(
            profile: _localProfile(
              userType: CivilUserType.siteEngineer,
              regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
            ),
          );
          final coordinator = _coordinator(repo, remote);

          final outcome = await coordinator.bootstrap(userId: _userA);

          expect(outcome, ProfileBootstrapOutcome.associated);
          expect(remote.updatePreferenceCalls, 1);
          expect(
            remote.fetchCalls,
            greaterThanOrEqualTo(2),
            reason: 'initial read + authoritative reread',
          );
          expect(repo.profile!.futureCloudUserId, _userA);
          expect(remote.cloudProfile!.regionPreferenceId, _karkhId);
        },
      );

      test('already-populated region is not silently overwritten', () async {
        final remote = _M2FakeRemoteGateway()
          ..cloudProfile = const CloudProfile(
            userId: _userA,
            roleCode: 'site_engineer',
            regionPreferenceId: _rusafaId,
          );
        final repo = _MemoryProfileRepository(
          profile: _localProfile(
            userType: CivilUserType.siteEngineer,
            regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
          ),
        );
        final coordinator = _coordinator(repo, remote);

        final outcome = await coordinator.bootstrap(userId: _userA);

        expect(
          outcome,
          ProfileBootstrapOutcome.profileConflict,
          reason: 'different existing region is a conflict, not an overwrite',
        );
        expect(remote.updatePreferenceCalls, 0);
        expect(remote.cloudProfile!.regionPreferenceId, _rusafaId);
      });

      test(
        'reread shows different region → profileConflict, no binding',
        () async {
          final remote = _M2FakeRemoteGateway()
            ..cloudProfile = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            )
            ..rereadOverride = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
              regionPreferenceId: _rusafaId,
            );
          final repo = _MemoryProfileRepository(
            profile: _localProfile(
              userType: CivilUserType.siteEngineer,
              regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
            ),
          );
          final coordinator = _coordinator(repo, remote);

          final outcome = await coordinator.bootstrap(userId: _userA);

          expect(outcome, ProfileBootstrapOutcome.profileConflict);
          expect(
            repo.profile!.futureCloudUserId,
            isNull,
            reason: 'no binding when reread disagrees',
          );
        },
      );

      test(
        'reread fails after update → failure, no binding, no false success',
        () async {
          final remote = _M2FakeRemoteGateway()
            ..cloudProfile = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            )
            ..rereadError = const SocketException('offline');
          final repo = _MemoryProfileRepository(
            profile: _localProfile(
              userType: CivilUserType.siteEngineer,
              regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
            ),
          );
          final coordinator = _coordinator(repo, remote);

          final outcome = await coordinator.bootstrap(userId: _userA);

          expect(outcome, ProfileBootstrapOutcome.failure);
          expect(remote.updatePreferenceCalls, 1);
          expect(
            repo.profile!.futureCloudUserId,
            isNull,
            reason: 'binding requires a successful reread',
          );
        },
      );

      test('UPDATE 23505 does not bind or report success', () async {
        final remote = _M2FakeRemoteGateway()
          ..cloudProfile = const CloudProfile(
            userId: _userA,
            roleCode: 'site_engineer',
          )
          ..updateError = const CloudProfileInvalidDataException();
        final repo = _MemoryProfileRepository(
          profile: _localProfile(
            userType: CivilUserType.siteEngineer,
            regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
          ),
        );
        final coordinator = _coordinator(repo, remote);

        final outcome = await coordinator.bootstrap(userId: _userA);

        expect(
          outcome,
          ProfileBootstrapOutcome.invalidData,
          reason: 'UPDATE 23505/domain failure must not silently succeed',
        );
        expect(repo.profile!.futureCloudUserId, isNull);
      });

      test('permission denied on update does not bind', () async {
        final remote = _M2FakeRemoteGateway()
          ..cloudProfile = const CloudProfile(
            userId: _userA,
            roleCode: 'site_engineer',
          )
          ..updateError = const CloudProfilePermissionDeniedException();
        final repo = _MemoryProfileRepository(
          profile: _localProfile(
            userType: CivilUserType.siteEngineer,
            regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
          ),
        );
        final coordinator = _coordinator(repo, remote);

        final outcome = await coordinator.bootstrap(userId: _userA);

        expect(outcome, ProfileBootstrapOutcome.permissionDenied);
        expect(repo.profile!.futureCloudUserId, isNull);
      });

      test(
        'region-fill timeout remains retryable failure, auth retained',
        () async {
          final remote = _M2FakeRemoteGateway()
            ..cloudProfile = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            )
            ..updateHang = true;
          final timedRemote = TimedPersonalProfileRemoteGateway(
            delegate: remote,
            mutationTimeout: const Duration(milliseconds: 5),
          );
          final timedPreference = TimedRegionPreferenceGateway(
            delegate: _FakePreferenceGateway(),
            readTimeout: const Duration(seconds: 5),
          );
          final repo = _MemoryProfileRepository(
            profile: _localProfile(
              userType: CivilUserType.siteEngineer,
              regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
            ),
          );
          final coordinator = PersonalProfileBootstrapCoordinator(
            localRepository: repo,
            remoteGateway: timedRemote,
            regionPreferenceGateway: timedPreference,
          );

          final outcome = await coordinator.bootstrap(userId: _userA);

          expect(outcome, ProfileBootstrapOutcome.failure);
          expect(remote.updatePreferenceCalls, 1);
          expect(repo.profile!.futureCloudUserId, isNull);
        },
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Future<void> _settle({int ticks = 5}) async {
  for (var i = 0; i < ticks; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _DelegatingHttpClient extends http.BaseClient {
  _DelegatingHttpClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.fromIterable([utf8.encode(response.body)]),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

class _MemoryProfileRepository implements UserProfileRepository {
  _MemoryProfileRepository({this.profile});

  LocalUserProfile? profile;

  @override
  Future<LocalUserProfile?> loadProfile() async => profile;

  @override
  Future<void> saveProfile(LocalUserProfile value) async {
    profile = value;
  }

  @override
  Future<void> clearProfile() async {
    profile = null;
  }
}

class _FakePreferenceGateway implements RegionPreferenceGateway {
  int lookupCalls = 0;
  @override
  Future<String?> resolvePreferenceIdByCode(String code) async {
    lookupCalls++;
    if (code == RegionPreferenceCode.baghdadKarkh) return _karkhId;
    if (code == RegionPreferenceCode.baghdadRusafa) return _rusafaId;
    return null;
  }

  @override
  Future<String?> resolveCodeById(String id) async {
    if (id == _karkhId) return RegionPreferenceCode.baghdadKarkh;
    if (id == _rusafaId) return RegionPreferenceCode.baghdadRusafa;
    return null;
  }
}

class _MappingCloudGateway
    implements PersonalProfileRemoteGateway, ConditionalProfileRetryGateway {
  CloudProfile? cloud;
  CloudProfile? rereadProfile;
  Object? rereadError;
  int saveCalls = 0;
  bool savePermissionDenied = false;
  bool saveInvalidData = false;
  bool saveUnexpected = false;
  InfrastructureFailure? saveInfrastructure;

  @override
  Future<void> saveEditableFieldsIfRegionAbsent({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) async {
    if (cloud?.regionPreferenceId != null) return;
    await saveEditableFields(
      userId: userId,
      roleCode: roleCode,
      regionPreferenceId: regionPreferenceId,
    );
  }

  @override
  Future<CloudProfile?> fetchByUserId(String userId) async {
    if (rereadError != null) throw rereadError!;
    return rereadProfile ?? cloud;
  }

  @override
  Future<void> createProfile(CloudProfile profile) async {}

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
    if (savePermissionDenied)
      throw const CloudProfilePermissionDeniedException();
    if (saveInvalidData) throw const CloudProfileInvalidDataException();
    if (saveUnexpected) throw const CloudProfileUnexpectedException();
    if (saveInfrastructure != null) {
      throw InfrastructureFailureException(saveInfrastructure!);
    }
    cloud = CloudProfile(
      userId: userId,
      roleCode: roleCode,
      regionPreferenceId: regionPreferenceId ?? cloud?.regionPreferenceId,
    );
  }
}

class _GatedMappingCloudGateway extends _MappingCloudGateway {
  final Completer<void> _gate = Completer<void>();
  bool _released = false;

  void release() {
    if (!_released) {
      _released = true;
      _gate.complete();
    }
  }

  @override
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) async {
    saveCalls++;
    await _gate.future;
    if (savePermissionDenied)
      throw const CloudProfilePermissionDeniedException();
    if (saveInvalidData) throw const CloudProfileInvalidDataException();
    if (saveUnexpected) throw const CloudProfileUnexpectedException();
    if (saveInfrastructure != null) {
      throw InfrastructureFailureException(saveInfrastructure!);
    }
    cloud = CloudProfile(
      userId: userId,
      roleCode: roleCode,
      regionPreferenceId: regionPreferenceId ?? cloud?.regionPreferenceId,
    );
  }
}

class _M2FakeRemoteGateway implements PersonalProfileRemoteGateway {
  CloudProfile? cloudProfile;
  CloudProfile? rereadOverride;
  Object? rereadError;
  Object? updateError;
  bool updateHang = false;
  int fetchCalls = 0;
  int updatePreferenceCalls = 0;
  bool _updateAttempted = false;

  @override
  Future<CloudProfile?> fetchByUserId(String userId) async {
    fetchCalls++;
    if (_updateAttempted && rereadError != null) throw rereadError!;
    return rereadOverride ?? cloudProfile;
  }

  @override
  Future<void> createProfile(CloudProfile profile) async {}

  @override
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  }) async {
    updatePreferenceCalls++;
    _updateAttempted = true;
    if (updateHang) return Completer<void>().future;
    if (updateError != null) throw updateError!;
    if (cloudProfile?.regionPreferenceId != null) {
      throw const CloudProfileInvalidDataException();
    }
    cloudProfile = CloudProfile(
      userId: userId,
      displayName: cloudProfile?.displayName,
      photoUrl: cloudProfile?.photoUrl,
      roleCode: cloudProfile?.roleCode,
      preferredRegionId: cloudProfile?.preferredRegionId,
      regionPreferenceId: regionPreferenceId,
      phone: cloudProfile?.phone,
    );
  }

  @override
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) async {}
}

LocalUserProfile _localProfile({
  required CivilUserType userType,
  String? regionPreferenceCode,
}) {
  return LocalUserProfile(
    anonymousInstallId: 'install-a',
    userType: userType,
    baghdadArea: BaghdadArea.unknown,
    regionPreferenceCode: regionPreferenceCode,
  );
}

PersonalProfileBootstrapCoordinator _coordinator(
  _MemoryProfileRepository repo,
  _M2FakeRemoteGateway gateway,
) {
  return PersonalProfileBootstrapCoordinator(
    localRepository: repo,
    remoteGateway: gateway,
    regionPreferenceGateway: _FakePreferenceGateway(),
  );
}
