import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/di/app_dependencies.dart';
import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_bootstrap_coordinator.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/profile_bootstrap_outcome.dart';
import 'package:civilpedia/features/profile/data/region_preference.dart';
import 'package:civilpedia/features/profile/data/region_preference_gateway.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/profile_operation_result.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';

import 'fakes/fake_auth_gateway.dart';

const _userA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _userB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

const _sessionA = AuthSession(
  userId: _userA,
  email: 'a@civilpedia.com',
  displayName: 'Engineer A',
);

Future<void> _settle({int ticks = 5}) async {
  for (var i = 0; i < ticks; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// In-memory [UserProfileRepository] fake.
class _MemoryProfileRepository implements UserProfileRepository {
  _MemoryProfileRepository({this.profile});

  LocalUserProfile? profile;
  Object? loadError;
  Object? saveError;

  @override
  Future<LocalUserProfile?> loadProfile() async {
    if (loadError != null) throw loadError!;
    return profile;
  }

  @override
  Future<void> saveProfile(LocalUserProfile value) async {
    if (saveError != null) throw saveError!;
    profile = value;
  }

  @override
  Future<void> clearProfile() async {
    profile = null;
  }
}

/// Programmable [PersonalProfileRemoteGateway] fake. Production reads are
/// strict-parsed, so the fake must hand back already-valid [CloudProfile]s.
class _CloudGateway implements PersonalProfileRemoteGateway {
  CloudProfile? cloud;
  Object? fetchError;
  bool fetchNull = false;
  Object? saveError;
  bool savePermissionDenied = false;
  Object? createError;

  int fetchCalls = 0;
  int saveCalls = 0;
  String? lastSavedRole;
  String? lastSavedRegionId;

  @override
  Future<CloudProfile?> fetchByUserId(String userId) async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    if (fetchNull) return null;
    return cloud;
  }

  @override
  Future<void> createProfile(CloudProfile profile) async {
    if (createError != null) throw createError!;
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
    if (savePermissionDenied) throw const CloudProfilePermissionDeniedException();
    if (saveError != null) throw saveError!;
    lastSavedRole = roleCode;
    lastSavedRegionId = regionPreferenceId;
    cloud = CloudProfile(
      userId: userId,
      displayName: cloud?.displayName,
      photoUrl: cloud?.photoUrl,
      roleCode: roleCode,
      preferredRegionId: cloud?.preferredRegionId,
      regionPreferenceId: regionPreferenceId ?? cloud?.regionPreferenceId,
      phone: cloud?.phone,
    );
  }
}

/// Programmable [RegionPreferenceGateway] fake mirroring migration 00013.
class _FakePreferenceGateway implements RegionPreferenceGateway {
  static const String _karkhId = '10000000-0000-4000-8000-000000000101';

  Object? resolveError;

  @override
  Future<String?> resolvePreferenceIdByCode(String code) async {
    if (resolveError != null) throw resolveError!;
    return code == RegionPreferenceCode.baghdadKarkh ? _karkhId : null;
  }

  @override
  Future<String?> resolveCodeById(String id) async {
    if (resolveError != null) throw resolveError!;
    return id == _karkhId ? RegionPreferenceCode.baghdadKarkh : null;
  }
}

/// F3 — cloud gateway whose `saveEditableFields` suspends until [release], so
/// tests can verify concurrent save requests coalesce onto ONE remote mutation.
class _GatedSaveCloudGateway extends _CloudGateway {
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
    if (savePermissionDenied) throw const CloudProfilePermissionDeniedException();
    if (saveError != null) throw saveError!;
    lastSavedRole = roleCode;
    lastSavedRegionId = regionPreferenceId;
    cloud = CloudProfile(
      userId: userId,
      displayName: cloud?.displayName,
      photoUrl: cloud?.photoUrl,
      roleCode: roleCode,
      preferredRegionId: cloud?.preferredRegionId,
      regionPreferenceId: regionPreferenceId ?? cloud?.regionPreferenceId,
      phone: cloud?.phone,
    );
  }
}

LocalUserProfile _localProfile({
  String? cloudBinding,
  String anonymousInstallId = 'install-a',
}) {
  return LocalUserProfile(
    anonymousInstallId: anonymousInstallId,
    userType: CivilUserType.siteEngineer,
    baghdadArea: BaghdadArea.unknown,
    name: 'م. علي',
    futureCloudUserId: cloudBinding,
  );
}

void main() {
  group('V1-R08 cloud profile foundation', () {
    // ------------------------------------------------------------
    // F7 — distinct provisioning-failure cause (REAL production paths)
    // ------------------------------------------------------------
    test('a REAL provisioning failure in the bootstrap CREATE path returns '
        'ProfileBootstrapOutcome.provisioningFailure', () async {
      final gateway = _CloudGateway()
        ..createError = const CloudProfileProvisioningException();
      final coordinator = PersonalProfileBootstrapCoordinator(
        localRepository: _MemoryProfileRepository(),
        remoteGateway: gateway,
        regionPreferenceGateway: _FakePreferenceGateway(),
      );

      // No local profile → guest-first provisioning path. The remote CREATE
      // genuinely fails to provision the canonical row.
      final outcome = await coordinator.bootstrap(userId: _userA);

      expect(outcome, ProfileBootstrapOutcome.provisioningFailure,
          reason: 'a provisioning-specific CREATE rejection must NOT be '
              'collapsed into a generic transient failure');
      // Raw backend exception text is never part of the typed outcome.
      expect(outcome.toString(), isNot(contains('Exception')));
    });

    test('provisioningFailure maps through the production bootstrap→provider '
        'boundary to the typed auth lifecycle state', () async {
      final gateway = _CloudGateway()
        ..createError = const CloudProfileProvisioningException();
      final coordinator = PersonalProfileBootstrapCoordinator(
        localRepository: _MemoryProfileRepository(),
        remoteGateway: gateway,
        regionPreferenceGateway: _FakePreferenceGateway(),
      );

      // Production mapping boundary (the SAME function used by
      // AppDependencies.runPostAuthPipeline).
      final outcome = AppDependencies.mapBootstrapOutcome(
        await coordinator.bootstrap(userId: _userA),
      );
      expect(outcome, PostAuthOutcome.provisioningFailure);

      // The REAL AuthProvider pipeline surfaces the typed lifecycle state and
      // keeps the authoritative session (never guest, no raw message).
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
        onPostAuth: (session) async {
          final result = await coordinator.bootstrap(
            userId: session.userId,
            authDisplayName: session.displayName,
          );
          return AppDependencies.mapBootstrapOutcome(result);
        },
      );
      await auth.restoreSession();
      await _settle();

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.postAuthState, PostAuthLifecycleState.provisioningFailure);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.session?.userId, _userA);
      expect(auth.error, isNull,
          reason: 'no raw backend error may be exposed');

      auth.dispose();
    });

    test('a REAL provider save on a never-provisioned session returns '
        'profile-failed(ProfileOperationCause.provisioningFailure)',
        () async {
      final gateway = _CloudGateway()..fetchNull = true;
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

      // Authenticated but no canonical row (the bootstrap seam failed to
      // provision one): the save re-read finds no row and must NOT pretend
      // success or expose a backend message.
      final result = await profileProvider.saveRoleAndRegionPreference(
        roleCode: 'site_engineer',
      );

      expect(result.succeeded, isFalse);
      expect(result.cause, ProfileOperationCause.provisioningFailure,
          reason: 'the real provider path returns the typed provisioning '
              'cause, not enum construction alone');
      expect(result.profile, isNull);
      expect(result.wasNoOp, isFalse);
      expect(profileProvider.isCloudBound, isFalse);
      expect(profileProvider.authenticatedProfile, isNull);

      profileProvider.dispose();
      auth.dispose();
    });

    test('provisioningFailure is a distinct machine-readable cause', () {
      // A genuine provisioning failure is NOT any of the sibling causes:
      // it is neither a malformed response, nor an RLS denial, nor an
      // identity conflict.
      expect(ProfileOperationCause.provisioningFailure, isNot(
        ProfileOperationCause.malformedResponse,
      ));
      expect(ProfileOperationCause.provisioningFailure, isNot(
        ProfileOperationCause.permissionDenied,
      ));
      expect(ProfileOperationCause.provisioningFailure, isNot(
        ProfileOperationCause.ownershipConflict,
      ));
      expect(ProfileOperationCause.provisioningFailure, isNot(
        ProfileOperationCause.retryableFailure,
      ));
      expect(ProfileOperationCause.provisioningFailure, isNot(
        ProfileOperationCause.unexpected,
      ));
    });

    test('failed(provisioningFailure) surfaces the cause with no fabricated '
        'profile', () {
      const result = ProfileOperationResult.failed(
        ProfileOperationCause.provisioningFailure,
      );
      expect(result.succeeded, isFalse);
      expect(result.cause, ProfileOperationCause.provisioningFailure);
      expect(result.profile, isNull);
      expect(result.wasNoOp, isFalse);
    });

    // ------------------------------------------------------------
    // Strict row parsing (finding 4)
    // ------------------------------------------------------------
    group('parseCloudProfileRow — strict schema contract', () {
      test('accepts a canonical, session-owned row', () {
        final row = <String, dynamic>{
          'user_id': _userA,
          'role_code': 'site_engineer',
          'region_preference_id': null,
          'preferred_region_id': null,
          'display_name': 'م. علي',
        };
        final parsed = parseCloudProfileRow(row, expectedUserId: _userA);
        expect(parsed.userId, _userA);
        expect(parsed.roleCode, 'site_engineer');
        expect(parsed.displayName, 'م. علي');
      });

      test('rejects a missing user_id', () {
        expect(
          () => parseCloudProfileRow({}, expectedUserId: _userA),
          throwsA(isA<CloudProfileParseException>()),
        );
      });

      test('rejects a user_id that is not the authenticated user', () {
        expect(
          () => parseCloudProfileRow(
            {'user_id': _userB},
            expectedUserId: _userA,
          ),
          throwsA(isA<CloudProfileParseException>()),
        );
      });

      test('rejects a non-UUID user_id', () {
        expect(
          () => parseCloudProfileRow(
            {'user_id': 'not-a-uuid'},
            expectedUserId: 'not-a-uuid',
          ),
          throwsA(isA<CloudProfileParseException>()),
        );
      });

      test('rejects a non-canonical role_code', () {
        expect(
          () => parseCloudProfileRow(
            {'user_id': _userA, 'role_code': 'super_admin'},
            expectedUserId: _userA,
          ),
          throwsA(isA<CloudProfileParseException>()),
        );
      });

      test('rejects a non-UUID region_preference_id', () {
        expect(
          () => parseCloudProfileRow(
            {
              'user_id': _userA,
              'region_preference_id': 'not-a-uuid',
            },
            expectedUserId: _userA,
          ),
          throwsA(isA<CloudProfileParseException>()),
        );
      });
    });

    // ------------------------------------------------------------
    // SSOT: authenticated ⇒ cloud authoritative, local never a fallback
    // ------------------------------------------------------------
    group('single-source-of-truth (findings 1/17)', () {
      test('local profile is surfaced only while signed out', () async {
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        final profileProvider = UserProfileProvider(
          repository: _MemoryProfileRepository(
            profile: _localProfile(cloudBinding: _userA),
          ),
          cloudProfileGateway: _CloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'consultant_engineer',
            ),
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );

        // Guest: the on-device profile is the authority.
        await profileProvider.loadProfile();
        expect(profileProvider.profile, isNotNull);
        expect(profileProvider.authenticatedProfile, isNull);
        expect(profileProvider.isCloudBound, isFalse);

        // Authenticated: the cloud row is the ONLY profile; local is hidden.
        await auth.restoreSession();
        await profileProvider.ensureCloudProfileLoaded();
        expect(profileProvider.profile, isNull,
            reason: 'no authenticated LocalUserProfile fallback');
        expect(profileProvider.authenticatedProfile?.userId, _userA);
        expect(profileProvider.authenticatedProfile?.roleCode,
            'consultant_engineer');
        expect(profileProvider.isCloudBound, isTrue);

        profileProvider.dispose();
        auth.dispose();
      });

      test('authenticated with NO cloud row keeps profile null (no fabrication)',
          () async {
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        final gateway = _CloudGateway()..fetchNull = true;
        final profileProvider = UserProfileProvider(
          repository: _MemoryProfileRepository(
            profile: _localProfile(cloudBinding: _userA),
          ),
          cloudProfileGateway: gateway,
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );

        await profileProvider.loadProfile();
        expect(profileProvider.profile, isNotNull);

        await auth.restoreSession();
        await profileProvider.ensureCloudProfileLoaded();
        await _settle();

        expect(profileProvider.profile, isNull);
        expect(profileProvider.authenticatedProfile, isNull);
        expect(profileProvider.cloudLoadFailed, isFalse);
        expect(profileProvider.isCloudBound, isFalse);

        profileProvider.dispose();
        auth.dispose();
      });

      test('sign-out returns local authority and drops cloud state', () async {
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        final profileProvider = UserProfileProvider(
          repository: _MemoryProfileRepository(
            profile: _localProfile(cloudBinding: _userA),
          ),
          cloudProfileGateway: _CloudGateway()
            ..cloud = const CloudProfile(userId: _userA),
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );

        await profileProvider.loadProfile();
        await auth.restoreSession();
        await profileProvider.ensureCloudProfileLoaded();
        expect(profileProvider.isCloudBound, isTrue);

        await auth.signOut();
        await _settle();
        expect(profileProvider.profile, isNotNull);
        expect(profileProvider.authenticatedProfile, isNull);
        expect(profileProvider.isCloudBound, isFalse);

        profileProvider.dispose();
        auth.dispose();
      });

      test('a cloud read failure is tolerated but local is NEVER a fallback',
          () async {
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        final gateway = _CloudGateway()
          ..fetchError = Exception('offline');
        final profileProvider = UserProfileProvider(
          repository: _MemoryProfileRepository(
            profile: _localProfile(cloudBinding: _userA),
          ),
          cloudProfileGateway: gateway,
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );

        await profileProvider.loadProfile();
        await auth.restoreSession();
        await profileProvider.ensureCloudProfileLoaded();

        expect(profileProvider.profile, isNull,
            reason: 'a failing cloud read must never resurrect the local '
                'profile into an authenticated session');
        expect(profileProvider.cloudLoadFailed, isTrue);

        profileProvider.dispose();
        auth.dispose();
      });
    });

    // ------------------------------------------------------------
    // saveRoleAndRegionPreference (findings 3/13/14)
    // ------------------------------------------------------------
    group('saveRoleAndRegionPreference', () {
      AuthProvider authWith(String userId) => AuthProvider(
            gateway: FakeAuthGateway(
              restoredSession:
                  userId == _userA ? _sessionA : _sessionA,
            ),
          );

      test('rejects without an authenticated session (unauthenticated)',
          () async {
        final auth = AuthProvider(gateway: FakeAuthGateway());
        final profileProvider = UserProfileProvider(
          repository: _MemoryProfileRepository(),
          cloudProfileGateway: _CloudGateway(),
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );

        final result =
            await profileProvider.saveRoleAndRegionPreference(
          roleCode: 'site_engineer',
        );

        expect(result.succeeded, isFalse);
        expect(result.cause, ProfileOperationCause.unauthenticated);
        profileProvider.dispose();
        auth.dispose();
      });

      test('rejects a non-canonical role with NO remote mutation', () async {
        final gateway = _CloudGateway()
          ..cloud = const CloudProfile(userId: _userA, roleCode: 'site_engineer');
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
          roleCode: 'super_admin',
        );

        expect(result.succeeded, isFalse);
        expect(result.cause, ProfileOperationCause.invalidData);
        expect(gateway.saveCalls, 0);

        profileProvider.dispose();
        auth.dispose();
      });

      test('rejects an unknown region code with NO remote mutation', () async {
        final gateway = _CloudGateway()
          ..cloud = const CloudProfile(userId: _userA, roleCode: 'site_engineer');
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
          roleCode: 'site_engineer',
          regionPreferenceCode: 'IQ_PREF_NOT_A_ZONE',
        );

        expect(result.succeeded, isFalse);
        expect(result.cause, ProfileOperationCause.invalidData);
        expect(gateway.saveCalls, 0);

        profileProvider.dispose();
        auth.dispose();
      });

      test('writes role + resolved region, then installs the authoritative '
          're-read', () async {
        final gateway = _CloudGateway()
          ..cloud = const CloudProfile(userId: _userA, roleCode: 'site_engineer');
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
          regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
        );

        expect(result.succeeded, isTrue);
        expect(result.wasNoOp, isFalse);
        expect(gateway.saveCalls, 1);
        expect(gateway.lastSavedRole, 'consultant_engineer');
        expect(gateway.lastSavedRegionId,
            '10000000-0000-4000-8000-000000000101');
        expect(profileProvider.authenticatedProfile?.roleCode,
            'consultant_engineer');
        expect(profileProvider.authenticatedProfile?.regionPreferenceId,
            '10000000-0000-4000-8000-000000000101');
        expect(result.profile?.roleCode, 'consultant_engineer');

        profileProvider.dispose();
        auth.dispose();
      });

      test('a duplicate save is a no-op BEFORE any remote mutation', () async {
        final gateway = _CloudGateway()
          ..cloud = const CloudProfile(
            userId: _userA,
            roleCode: 'consultant_engineer',
            regionPreferenceId: '10000000-0000-4000-8000-000000000101',
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
          regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
        );

        expect(result.succeeded, isTrue);
        expect(result.wasNoOp, isTrue);
        expect(gateway.saveCalls, 0, reason: 'unchanged save must not mutate');
        expect(gateway.lastSavedRole, isNull);

        profileProvider.dispose();
        auth.dispose();
      });

      test('a failed write preserves prior cloud state (retryableFailure)',
          () async {
        final gateway = _CloudGateway()
          ..cloud = const CloudProfile(userId: _userA, roleCode: 'site_engineer')
          ..saveError = Exception('network');
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
        expect(profileProvider.authenticatedProfile?.roleCode,
            'site_engineer',
            reason: 'a failed save must never install a fabricated result');
        expect(profileProvider.isCloudBound, isTrue);

        profileProvider.dispose();
        auth.dispose();
      });

      test('concurrent saves coalesce onto ONE remote mutation (F3)',
          () async {
        final gateway = _GatedSaveCloudGateway()
          ..cloud = const CloudProfile(userId: _userA, roleCode: 'site_engineer');
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

        final firstRun = profileProvider.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
          regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
        );
        final secondRun = profileProvider.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
          regionPreferenceCode: RegionPreferenceCode.baghdadKarkh,
        );
        await _settle();

        // Both callers are now parked on the SAME remote save: a burst must
        // fire exactly one `saveEditableFields`.
        expect(gateway.saveCalls, 1,
            reason: 'a concurrent burst must coalesce onto one remote save; '
                'otherwise a double-tap writes twice');

        gateway.release();
        final firstResult = await firstRun;
        final secondResult = await secondRun;

        expect(gateway.saveCalls, 1);
        expect(firstResult.succeeded, isTrue);
        expect(secondResult.succeeded, isTrue);
        expect(identical(firstResult, secondResult), isTrue,
            reason: 'both callers share the exact same authoritative result');
        expect(profileProvider.authenticatedProfile?.roleCode,
            'consultant_engineer');

        profileProvider.dispose();
        auth.dispose();
      });

      test('an RLS denial maps to a typed permissionDenied failure', () async {
        final gateway = _CloudGateway()
          ..cloud = const CloudProfile(userId: _userA, roleCode: 'site_engineer')
          ..savePermissionDenied = true;
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
        expect(result.cause, ProfileOperationCause.permissionDenied);
        expect(profileProvider.authenticatedProfile?.roleCode,
            'site_engineer');

        profileProvider.dispose();
        auth.dispose();
      });

      test('a result landing after sign-out is never published (finding 8/14)',
          () async {
        final gateway = _CloudGateway()
          ..cloud = const CloudProfile(userId: _userA, roleCode: 'site_engineer');
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        final profileProvider = UserProfileProvider(
          repository: _MemoryProfileRepository(
            profile: _localProfile(cloudBinding: _userA),
          ),
          cloudProfileGateway: gateway,
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );
        await profileProvider.loadProfile();
        await auth.restoreSession();
        await profileProvider.ensureCloudProfileLoaded();

        // The session ends while the save is in flight: the write completes
        // against a stale (userId, generation) and must not be published.
        await auth.signOut();
        await _settle();
        final result = await profileProvider.saveRoleAndRegionPreference(
          roleCode: 'consultant_engineer',
        );

        expect(result.succeeded, isFalse);
        expect(result.cause, ProfileOperationCause.unauthenticated);
        expect(profileProvider.profile, isNotNull,
            reason: 'guest/local authority is restored after session loss');
        expect(profileProvider.authenticatedProfile, isNull);

        profileProvider.dispose();
        auth.dispose();
      });
    });

    // ------------------------------------------------------------
    // saveProfile guarded for authenticated sessions
    // ------------------------------------------------------------
    group('saveProfile while authenticated', () {
      test('is a no-op: the cloud row is canonical (finding 1/17)', () async {
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        final repository = _MemoryProfileRepository();
        final profileProvider = UserProfileProvider(
          repository: repository,
          cloudProfileGateway: _CloudGateway()
            ..cloud = const CloudProfile(
              userId: _userA,
              roleCode: 'site_engineer',
            ),
          regionPreferenceGateway: _FakePreferenceGateway(),
          auth: auth,
        );
        await auth.restoreSession();
        await profileProvider.ensureCloudProfileLoaded();

        await profileProvider.saveProfile(
          _localProfile(cloudBinding: _userA),
        );

        expect(repository.profile, isNull,
            reason: 'authenticated save must not write a local surrogate');
        expect(profileProvider.authenticatedProfile, isNotNull);

        profileProvider.dispose();
        auth.dispose();
      });
    });
  });
}