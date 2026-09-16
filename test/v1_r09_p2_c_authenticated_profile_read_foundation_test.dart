import 'dart:async';
import 'dart:io';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/core/network/remote_operation_policy.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/region_preference_gateway.dart';
import 'package:civilpedia/features/profile/data/timed_profile_gateways.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes/fake_auth_gateway.dart';

const _userA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _userB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

const _sessionA = AuthSession(
  userId: _userA,
  email: 'a@civilpedia.test',
  displayName: 'Engineer A',
);
const _sessionB = AuthSession(
  userId: _userB,
  email: 'b@civilpedia.test',
  displayName: 'Engineer B',
);

CloudProfile _cloud(String userId, String role) => CloudProfile(
  userId: userId,
  displayName: userId == _userA ? 'Engineer A' : 'Engineer B',
  roleCode: role,
);

Future<void> _drain([int ticks = 8]) async {
  for (var i = 0; i < ticks; i++) {
    await Future<void>.delayed(Duration.zero);
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

class _PreferenceGateway implements RegionPreferenceGateway {
  @override
  Future<String?> resolveCodeById(String id) async => null;

  @override
  Future<String?> resolvePreferenceIdByCode(String code) async => null;
}

class _PendingRead {
  _PendingRead(this.userId);

  final String userId;
  final Completer<CloudProfile?> completer = Completer<CloudProfile?>();
}

class _ControlledProfileGateway implements PersonalProfileRemoteGateway {
  final List<_PendingRead> reads = [];
  int createCalls = 0;
  int saveCalls = 0;
  int updateCalls = 0;
  Completer<void>? saveGate;

  @override
  Future<CloudProfile?> fetchByUserId(String userId) {
    final read = _PendingRead(userId);
    reads.add(read);
    return read.completer.future;
  }

  void succeed(int index, CloudProfile? profile) {
    reads[index].completer.complete(profile);
  }

  void fail(int index, Object error) {
    reads[index].completer.completeError(error);
  }

  @override
  Future<void> createProfile(CloudProfile profile) async {
    createCalls++;
  }

  @override
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  }) async {
    updateCalls++;
  }

  @override
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) async {
    saveCalls++;
    await saveGate?.future;
  }
}

class _Harness {
  _Harness._({
    required this.authGateway,
    required this.auth,
    required this.cloud,
    required this.profile,
  });

  final FakeAuthGateway authGateway;
  final AuthProvider auth;
  final _ControlledProfileGateway cloud;
  final UserProfileProvider profile;

  static Future<_Harness> create({LocalUserProfile? localProfile}) async {
    final authGateway = FakeAuthGateway(restoredSession: _sessionA);
    final auth = AuthProvider(gateway: authGateway);
    await auth.restoreSession();
    await _drain();
    final cloud = _ControlledProfileGateway();
    final profile = UserProfileProvider(
      repository: _MemoryProfileRepository(profile: localProfile),
      cloudProfileGateway: cloud,
      regionPreferenceGateway: _PreferenceGateway(),
      auth: auth,
    );
    return _Harness._(
      authGateway: authGateway,
      auth: auth,
      cloud: cloud,
      profile: profile,
    );
  }

  void dispose() {
    profile.dispose();
    auth.dispose();
    authGateway.close();
  }
}

void main() {
  group('P2-C1 read taxonomy', () {
    test('transport/client failures map to network, never offline', () {
      expect(
        classifyProfileReadFailure(const SocketException('offline-looking')),
        ProfileReadFailureKind.network,
      );
      expect(
        classifyProfileReadFailure(ClientException('connection failed')),
        ProfileReadFailureKind.network,
      );
      expect(
        ProfileReadFailureKind.values.map((value) => value.name),
        isNot(contains('offline')),
      );
    });

    test('deadline survives the timed gateway as timeout', () async {
      final raw = _ControlledProfileGateway();
      final timed = TimedPersonalProfileRemoteGateway(
        delegate: raw,
        readTimeout: const Duration(milliseconds: 1),
      );

      Object? caught;
      try {
        await timed.fetchByUserId(_userA);
      } catch (error) {
        caught = error;
      }

      expect(caught, isNotNull);
      expect(
        classifyProfileReadFailure(caught!),
        ProfileReadFailureKind.timeout,
      );
      expect(RemoteOperationPolicy.read, const Duration(seconds: 15));
    });

    test('temporary SQL/PostgREST availability families are exact', () {
      for (final code in [
        '08006',
        '53300',
        'PGRST000',
        'PGRST001',
        'PGRST002',
        'PGRST003',
      ]) {
        expect(
          classifyProfileReadFailure(
            PostgrestException(message: 'raw-$code', code: code),
          ),
          ProfileReadFailureKind.serviceUnavailable,
          reason: code,
        );
      }
    });

    test('permission, auth, malformed and unexpected stay distinct', () {
      expect(
        classifyProfileReadFailure(
          const PostgrestException(message: 'raw', code: '42501'),
        ),
        ProfileReadFailureKind.permissionDenied,
      );
      expect(
        classifyProfileReadFailure(const CloudProfileAuthException()),
        ProfileReadFailureKind.authRestricted,
      );
      expect(
        classifyProfileReadFailure(
          const CloudProfileParseException('raw parser detail'),
        ),
        ProfileReadFailureKind.malformedResponse,
      );
      expect(
        classifyProfileReadFailure(
          const PostgrestException(message: 'raw', code: 'XX999'),
        ),
        ProfileReadFailureKind.unexpected,
      );
    });

    test('literal PostgREST 503 is not interpreted as HTTP 503', () {
      final raw = const PostgrestException(
        message: 'sensitive backend detail',
        code: '503',
      );
      expect(
        classifyProfileReadFailure(raw),
        ProfileReadFailureKind.unexpected,
      );
      expect(
        () => throwProfileReadFailure(raw),
        throwsA(isA<CloudProfileUnexpectedException>()),
      );
    });

    test('production read boundary throws only sanitized typed values', () {
      expect(
        () => throwProfileReadFailure(ClientException('secret network text')),
        throwsA(
          isA<InfrastructureFailureException>().having(
            (error) => error.failure.kind,
            'kind',
            InfrastructureFailureKind.network,
          ),
        ),
      );
      expect(
        () => throwProfileReadFailure(
          const PostgrestException(
            message: 'secret database text',
            details: 'secret details',
            hint: 'secret hint',
            code: 'PGRST001',
          ),
        ),
        throwsA(
          isA<InfrastructureFailureException>().having(
            (error) => error.failure.kind,
            'kind',
            InfrastructureFailureKind.serviceUnavailable,
          ),
        ),
      );
      expect(
        () => throwProfileReadFailure(
          const CloudProfileParseException('secret parser detail'),
        ),
        throwsA(
          isA<CloudProfileParseException>().having(
            (error) => error.reason,
            'sanitized reason',
            'Invalid profile response',
          ),
        ),
      );
    });
  });

  group('P2-C1 provider read state', () {
    test('same exact key coalesces onto one read', () async {
      final h = await _Harness.create();
      final first = h.profile.ensureCloudProfileLoaded();
      final second = h.profile.ensureCloudProfileLoaded();
      await _drain();

      expect(h.cloud.reads, hasLength(1));
      expect(h.profile.cloudReadPhase, AuthenticatedProfileReadPhase.loading);

      h.cloud.succeed(0, _cloud(_userA, 'site_engineer'));
      await Future.wait([first, second]);
      expect(h.profile.cloudReadPhase, AuthenticatedProfileReadPhase.loaded);
      h.dispose();
    });

    test(
      'known-good profile remains during refresh and typed failure',
      () async {
        final h = await _Harness.create();
        final initial = h.profile.ensureCloudProfileLoaded();
        await _drain();
        final original = _cloud(_userA, 'site_engineer');
        h.cloud.succeed(0, original);
        await initial;

        final refresh = h.profile.ensureCloudProfileLoaded();
        await _drain();
        expect(
          h.profile.cloudReadPhase,
          AuthenticatedProfileReadPhase.refreshing,
        );
        expect(h.profile.authenticatedProfile, same(original));

        h.cloud.fail(
          1,
          const InfrastructureFailureException(
            InfrastructureFailure(InfrastructureFailureKind.network),
          ),
        );
        await refresh;
        expect(h.profile.cloudReadPhase, AuthenticatedProfileReadPhase.failed);
        expect(h.profile.cloudReadFailure, ProfileReadFailureKind.network);
        expect(h.profile.authenticatedProfile, same(original));
        expect(h.auth.isLoggedIn, isTrue);

        final recovery = h.profile.ensureCloudProfileLoaded();
        await _drain();
        final updated = _cloud(_userA, 'consultant_engineer');
        h.cloud.succeed(2, updated);
        await recovery;
        expect(h.profile.authenticatedProfile, same(updated));
        expect(h.profile.cloudReadFailure, isNull);
        expect(h.profile.cloudReadPhase, AuthenticatedProfileReadPhase.loaded);
        h.dispose();
      },
    );

    test(
      'permission/auth read failures preserve profile and auth authority',
      () async {
        final h = await _Harness.create();
        final initial = h.profile.ensureCloudProfileLoaded();
        await _drain();
        final original = _cloud(_userA, 'site_engineer');
        h.cloud.succeed(0, original);
        await initial;

        final permission = h.profile.ensureCloudProfileLoaded();
        await _drain();
        h.cloud.fail(1, const CloudProfilePermissionDeniedException());
        await permission;
        expect(
          h.profile.cloudReadFailure,
          ProfileReadFailureKind.permissionDenied,
        );
        expect(h.profile.authenticatedProfile, same(original));
        expect(h.auth.isLoggedIn, isTrue);

        final authRestricted = h.profile.ensureCloudProfileLoaded();
        await _drain();
        h.cloud.fail(2, const CloudProfileAuthException());
        await authRestricted;
        expect(
          h.profile.cloudReadFailure,
          ProfileReadFailureKind.authRestricted,
        );
        expect(h.profile.authenticatedProfile, same(original));
        expect(h.auth.isLoggedIn, isTrue);
        h.dispose();
      },
    );

    test(
      'all remaining typed read failures preserve known-good profile',
      () async {
        final h = await _Harness.create();
        final initial = h.profile.ensureCloudProfileLoaded();
        await _drain();
        final original = _cloud(_userA, 'site_engineer');
        h.cloud.succeed(0, original);
        await initial;

        final cases = <(Object, ProfileReadFailureKind)>[
          (
            const InfrastructureFailureException(
              InfrastructureFailure(InfrastructureFailureKind.timeout),
            ),
            ProfileReadFailureKind.timeout,
          ),
          (
            const InfrastructureFailureException(
              InfrastructureFailure(
                InfrastructureFailureKind.serviceUnavailable,
              ),
            ),
            ProfileReadFailureKind.serviceUnavailable,
          ),
          (
            const CloudProfileParseException('raw parser detail'),
            ProfileReadFailureKind.malformedResponse,
          ),
          (
            const CloudProfileUnexpectedException(),
            ProfileReadFailureKind.unexpected,
          ),
        ];

        for (var i = 0; i < cases.length; i++) {
          final read = h.profile.ensureCloudProfileLoaded();
          await _drain();
          h.cloud.fail(i + 1, cases[i].$1);
          await read;
          expect(h.profile.cloudReadFailure, cases[i].$2);
          expect(h.profile.authenticatedProfile, same(original));
          expect(h.auth.isLoggedIn, isTrue);
        }
        h.dispose();
      },
    );

    test('authoritative notFound is distinct and never provisions', () async {
      final h = await _Harness.create();
      final initial = h.profile.ensureCloudProfileLoaded();
      await _drain();
      h.cloud.succeed(0, _cloud(_userA, 'site_engineer'));
      await initial;

      final missing = h.profile.ensureCloudProfileLoaded();
      await _drain();
      h.cloud.succeed(1, null);
      await missing;

      expect(
        h.profile.cloudReadPhase,
        AuthenticatedProfileReadPhase.authoritativeNotFound,
      );
      expect(h.profile.cloudReadFailure, isNull);
      expect(h.profile.authenticatedProfile, isNull);
      expect(h.profile.profile, isNull);
      expect(h.cloud.createCalls, 0);
      expect(h.cloud.saveCalls, 0);
      expect(h.auth.isLoggedIn, isTrue);
      h.dispose();
    });

    test(
      'authenticated read failure never exposes guest local profile',
      () async {
        final local = LocalUserProfile(
          anonymousInstallId: 'install-a',
          userType: CivilUserType.siteEngineer,
          baghdadArea: BaghdadArea.unknown,
          name: 'Guest profile',
        );
        final h = await _Harness.create(localProfile: local);
        await h.profile.loadProfile();
        final read = h.profile.ensureCloudProfileLoaded();
        await _drain();
        h.cloud.fail(0, ClientException('raw network detail'));
        await read;

        expect(h.profile.cloudReadFailure, ProfileReadFailureKind.network);
        expect(h.profile.authenticatedProfile, isNull);
        expect(h.profile.profile, isNull);
        expect(h.auth.isLoggedIn, isTrue);
        h.dispose();
      },
    );
  });

  group('P2-C1 keyed lifecycle and session races', () {
    test('same-user token refresh does not start a replacement read', () async {
      final h = await _Harness.create();
      final initial = h.profile.ensureCloudProfileLoaded();
      await _drain();
      final current = _cloud(_userA, 'site_engineer');
      h.cloud.succeed(0, current);
      await initial;

      h.authGateway.emit(
        const AuthEvent(type: AuthEventType.tokenRefreshed, session: _sessionA),
      );
      await _drain();

      expect(h.cloud.reads, hasLength(1));
      expect(h.profile.authenticatedProfile, same(current));
      h.dispose();
    });

    test(
      'User A active read does not block B and late A cannot publish',
      () async {
        final h = await _Harness.create();
        final aRead = h.profile.ensureCloudProfileLoaded();
        await _drain();
        expect(h.cloud.reads.single.userId, _userA);

        h.authGateway.emit(
          const AuthEvent(
            type: AuthEventType.sessionReplaced,
            session: _sessionB,
          ),
        );
        await _drain(16);

        expect(h.cloud.reads, hasLength(2));
        expect(h.cloud.reads[1].userId, _userB);

        final b = _cloud(_userB, 'consultant_engineer');
        h.cloud.succeed(1, b);
        await _drain();
        expect(h.profile.authenticatedProfile, same(b));

        h.cloud.succeed(0, _cloud(_userA, 'site_engineer'));
        await aRead;
        expect(h.profile.authenticatedProfile, same(b));
        expect(h.profile.authenticatedProfile?.userId, _userB);
        h.dispose();
      },
    );

    test(
      'same user with a newer auth generation starts independently',
      () async {
        final h = await _Harness.create();
        final oldRead = h.profile.ensureCloudProfileLoaded();
        await _drain();

        h.authGateway.emit(const AuthEvent(type: AuthEventType.signedOut));
        await _drain();
        h.authGateway.emit(
          const AuthEvent(type: AuthEventType.signedIn, session: _sessionA),
        );
        await _drain(16);

        expect(h.cloud.reads, hasLength(2));
        expect(h.cloud.reads[0].userId, _userA);
        expect(h.cloud.reads[1].userId, _userA);

        final current = _cloud(_userA, 'consultant_engineer');
        h.cloud.succeed(1, current);
        await _drain();
        h.cloud.succeed(0, _cloud(_userA, 'site_engineer'));
        await oldRead;
        expect(h.profile.authenticatedProfile, same(current));
        h.dispose();
      },
    );

    test('sign-out invalidates active read publication', () async {
      final h = await _Harness.create();
      final read = h.profile.ensureCloudProfileLoaded();
      await _drain();
      h.authGateway.emit(const AuthEvent(type: AuthEventType.signedOut));
      await _drain();
      h.cloud.succeed(0, _cloud(_userA, 'site_engineer'));
      await read;

      expect(h.profile.authenticatedProfile, isNull);
      expect(h.profile.cloudReadPhase, AuthenticatedProfileReadPhase.idle);
      expect(h.auth.isLoggedIn, isFalse);
      h.dispose();
    });

    test('dispose invalidates late completion and notification', () async {
      final h = await _Harness.create();
      var notifications = 0;
      h.profile.addListener(() => notifications++);
      final read = h.profile.ensureCloudProfileLoaded();
      await _drain();
      final beforeDispose = notifications;
      h.profile.dispose();

      h.cloud.succeed(0, _cloud(_userA, 'site_engineer'));
      await read;
      expect(notifications, beforeDispose);
      expect(h.profile.authenticatedProfile, isNull);

      h.auth.dispose();
      h.authGateway.close();
    });
  });

  group('P2-C1 profile revision and mutation compatibility', () {
    test(
      'accepted edit advances revision and stale success cannot overwrite',
      () async {
        final h = await _Harness.create();
        final staleRead = h.profile.ensureCloudProfileLoaded();
        await _drain();

        final save = h.profile.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
        );
        await _drain();
        expect(h.cloud.saveCalls, 1);
        expect(h.cloud.reads, hasLength(2));

        final edited = _cloud(_userA, 'consultant_engineer');
        h.cloud.succeed(1, edited);
        final saveResult = await save;
        expect(saveResult.succeeded, isTrue);
        expect(h.profile.authenticatedProfile, same(edited));

        final postEditRead = h.profile.ensureCloudProfileLoaded();
        await _drain();
        expect(
          h.cloud.reads,
          hasLength(3),
          reason: 'revision N+1 must not join N',
        );
        expect(
          h.profile.cloudReadPhase,
          AuthenticatedProfileReadPhase.refreshing,
        );

        h.cloud.succeed(0, _cloud(_userA, 'site_engineer'));
        await staleRead;
        expect(h.profile.authenticatedProfile, same(edited));
        expect(
          h.profile.cloudReadPhase,
          AuthenticatedProfileReadPhase.refreshing,
        );

        final newest = _cloud(_userA, 'project_manager');
        h.cloud.succeed(2, newest);
        await postEditRead;
        expect(h.profile.authenticatedProfile, same(newest));
        h.dispose();
      },
    );

    test('stale notFound at revision N cannot clear edit at N+1', () async {
      final h = await _Harness.create();
      final staleRead = h.profile.ensureCloudProfileLoaded();
      await _drain();
      final save = h.profile.saveRoleAndRegionPreference(
        roleCode: 'consultant_engineer',
      );
      await _drain();
      final edited = _cloud(_userA, 'consultant_engineer');
      h.cloud.succeed(1, edited);
      expect((await save).succeeded, isTrue);

      h.cloud.succeed(0, null);
      await staleRead;
      expect(h.profile.authenticatedProfile, same(edited));
      expect(h.profile.cloudReadPhase, AuthenticatedProfileReadPhase.loaded);
      h.dispose();
    });

    test(
      'stale failure at revision N cannot replace loaded N+1 state',
      () async {
        final h = await _Harness.create();
        final staleRead = h.profile.ensureCloudProfileLoaded();
        await _drain();
        final save = h.profile.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
        );
        await _drain();
        final edited = _cloud(_userA, 'consultant_engineer');
        h.cloud.succeed(1, edited);
        expect((await save).succeeded, isTrue);

        h.cloud.fail(0, ClientException('old read failed'));
        await staleRead;
        expect(h.profile.authenticatedProfile, same(edited));
        expect(h.profile.cloudReadFailure, isNull);
        expect(h.profile.cloudReadPhase, AuthenticatedProfileReadPhase.loaded);
        h.dispose();
      },
    );

    test('duplicate saves retain existing single-flight call counts', () async {
      final h = await _Harness.create();
      h.cloud.saveGate = Completer<void>();
      final first = h.profile.saveRoleAndRegionPreference(
        roleCode: 'consultant_engineer',
      );
      final second = h.profile.saveRoleAndRegionPreference(
        roleCode: 'consultant_engineer',
      );
      await _drain();
      expect(h.cloud.saveCalls, 1);
      h.cloud.saveGate!.complete();
      await _drain();
      expect(h.cloud.reads, hasLength(1));
      final edited = _cloud(_userA, 'consultant_engineer');
      h.cloud.succeed(0, edited);

      final results = await Future.wait([first, second]);
      expect(results.every((result) => result.succeeded), isTrue);
      expect(h.cloud.saveCalls, 1);
      expect(h.cloud.createCalls, 0);
      h.dispose();
    });
  });
}
