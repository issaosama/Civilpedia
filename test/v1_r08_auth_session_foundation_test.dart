import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/features/auth/domain/entities/auth_error.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_policy.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:civilpedia/features/business/domain/business_claim_target.dart';
import 'package:civilpedia/features/business/domain/business_claim_target_gateway.dart';
import 'package:civilpedia/features/business/presentation/providers/business_application_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/business_claim_target_provider.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';

import 'fakes/fake_auth_gateway.dart';

const _sessionA = AuthSession(
  userId: 'uuid-0000-0000',
  email: 'a@civilpedia.com',
  displayName: 'Engineer A',
);

const _sessionB = AuthSession(
  userId: 'uuid-0000-BBBB',
  email: 'b@civilpedia.com',
  displayName: 'Engineer B',
);

/// Festival of event-loop turns so stream events and fire-and-forget
/// reconciliations in [AuthProvider] finish processing deterministically.
Future<void> _settle({int ticks = 5}) async {
  for (var i = 0; i < ticks; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// A gateway whose sign-in blocks on a [Completer] until the test releases it.
class _BlockingGateway implements AuthGateway {
  _BlockingGateway(this.result);

  final Completer<AuthSession?> result;
  int signInCalls = 0;

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
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession?> signInWithGoogle() {
    signInCalls++;
    return result.future;
  }

  @override
  Future<void> signOut() async {}

  @override
  void dispose() {}
}

// --------------------------------------------------------------------------
// F6 harness — production-faithful account-bound providers + post-auth wiring.
// --------------------------------------------------------------------------

class _MemoryRepo implements UserProfileRepository {
  @override
  Future<LocalUserProfile?> loadProfile() async => null;

  @override
  Future<void> saveProfile(LocalUserProfile profile) async {}

  @override
  Future<void> clearProfile() async {}
}

/// Cloud gateway that owns exactly ONE authenticated profile (user A). B has
/// no row — and B must NEVER reach a load, because a conflicted second session
/// is blocked before bootstrap and its data must never be installed.
class _CloudOnlyA implements PersonalProfileRemoteGateway {
  @override
  Future<CloudProfile?> fetchByUserId(String userId) async =>
      userId == 'uuid-0000-0000'
      ? CloudProfile(userId: userId, roleCode: 'site_engineer')
      : null;

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
  }) async {}
}

/// Business-applications gateway that returns identifiable A-branded rows for
/// ANY caller (they carry the caller's own user id, so only A's are canonical).
class _BusinessApps implements BusinessApplicationGateway {
  @override
  bool get isAvailable => true;

  @override
  Future<List<BusinessApplication>> listOwnApplications(String userId) async =>
      [
        BusinessApplication(
          id: 'app-A1',
          applicantUserId: userId,
          type: BusinessApplicationType.newApplication,
          status: BusinessApplicationStatus.draft,
        ),
      ];

  @override
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  ) async => null;

  @override
  Future<BusinessApplicationCreateResult> createNewDraft({
    required String currentUserId,
    Map<String, dynamic>? metadata,
  }) async => const BusinessApplicationCreateDenied(
    BusinessApplicationRejectionCause.guestUser,
  );

  @override
  Future<BusinessApplicationCreateResult> createClaimDraft({
    required String currentUserId,
    required String targetEntityId,
  }) async => const BusinessApplicationCreateDenied(
    BusinessApplicationRejectionCause.guestUser,
  );

  @override
  Future<BusinessApplicationSubmitResult> submitApplication(
    BusinessApplication application,
  ) async => const BusinessApplicationSubmitDenied(
    BusinessApplicationSubmitCause.unauthenticated,
  );

  @override
  Future<BusinessApplicationSubmitResult> resubmitApplication(
    BusinessApplication application,
  ) async => const BusinessApplicationSubmitDenied(
    BusinessApplicationSubmitCause.unauthenticated,
  );
}

/// Claim-target gateway returning identifiable A-branded candidates.
class _ClaimTargets implements BusinessClaimTargetGateway {
  @override
  bool get isAvailable => true;

  @override
  Future<List<BusinessClaimTarget>> listUnclaimedTargets() async => const [
    BusinessClaimTarget(
      id: 'target-A1',
      name: 'A Target',
      entityType: 'company',
      claimStatus: 'unclaimed',
    ),
  ];
}

/// Production-faithful account-bound providers sharing ONE [AuthProvider],
/// with a reset seam that invokes the real providers' resets exactly like
/// production's `resetAccountBoundState()`, and a pipeline that mirrors
/// production ordering: claim-refusal for a second account short-circuits
/// BEFORE any bootstrap runs.
class _SecondAccountHarness {
  _SecondAccountHarness({Object? signOutError}) {
    gateway = FakeAuthGateway(
      restoredSession: _sessionA,
      signOutError: signOutError,
    );
    auth = AuthProvider(
      gateway: gateway,
      onAccountBoundReset: resetAccountBoundState,
      onPostAuth: pipeline,
    );
    profile = UserProfileProvider(
      repository: _MemoryRepo(),
      cloudProfileGateway: _CloudOnlyA(),
      auth: auth,
    );
    business = BusinessApplicationProvider(
      gateway: _BusinessApps(),
      auth: auth,
    );
    claims = BusinessClaimTargetProvider(gateway: _ClaimTargets(), auth: auth);
  }

  late final FakeAuthGateway gateway;
  late final AuthProvider auth;
  late final UserProfileProvider profile;
  late final BusinessApplicationProvider business;
  late final BusinessClaimTargetProvider claims;

  final List<String> bootstrapUsers = [];
  int resetCount = 0;

  /// Mirrors production ordering: the ownership claim is evaluated FIRST; a
  /// refusal for account B short-circuits to [PostAuthOutcome.ownershipConflict]
  /// BEFORE bootstrap for B can ever run.
  Future<PostAuthOutcome> pipeline(AuthSession session) async {
    if (session.userId != _sessionA.userId) {
      return PostAuthOutcome.ownershipConflict;
    }
    bootstrapUsers.add(session.userId);
    return PostAuthOutcome.success;
  }

  /// Mirrors production `resetAccountBoundState()` (main.dart): every wired
  /// account-bound provider is reset through this seam.
  void resetAccountBoundState() {
    resetCount++;
    profile.resetForIdentityChange();
    business.resetForIdentityChange();
    claims.resetForIdentityChange();
  }

  void dispose() {
    profile.dispose();
    business.dispose();
    claims.dispose();
    auth.dispose();
  }
}

void main() {
  // ------------------------------------------------------------------
  // §24 Auth & Session — Lifecycle states
  // ------------------------------------------------------------------
  group('V1-R08 auth lifecycle', () {
    test('starts in guest state', () {
      final provider = AuthProvider(gateway: FakeAuthGateway());
      expect(provider.status, AuthStatus.guest);
      expect(provider.isLoggedIn, isFalse);
      expect(provider.generation, 0);
      expect(provider.postAuthState, PostAuthLifecycleState.idle);
      provider.dispose();
    });

    test('restoreSession with persisted session → authenticated', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
      );
      await provider.restoreSession();
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.session, _sessionA);
      provider.dispose();
    });

    test('restoreSession with no session → stays guest', () async {
      final provider = AuthProvider(gateway: FakeAuthGateway());
      await provider.restoreSession();
      expect(provider.status, AuthStatus.guest);
      expect(provider.session, isNull);
      provider.dispose();
    });

    test('signInWithGoogle failure → error state', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(signInError: Exception('network')),
      );
      await provider.signInWithGoogle();
      expect(provider.status, AuthStatus.error);
      expect(provider.error, AuthError.signInFailed);
      provider.dispose();
    });

    test('AuthGatewayException surfaces the typed error', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(
          signInError: const AuthGatewayException(AuthError.unavailable),
        ),
      );
      await provider.signInWithGoogle();
      expect(provider.status, AuthStatus.error);
      expect(provider.error, AuthError.unavailable);
      provider.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §5 Canonical session generation
  // ------------------------------------------------------------------
  group('session generation', () {
    test(
      'initial restore from guest does advance generation (guest→auth is a real identity change)',
      () async {
        final provider = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        expect(provider.generation, 0);
        await provider.restoreSession();
        expect(provider.generation, greaterThan(0));
        provider.dispose();
      },
    );

    test(
      'sign-out + re-restore invalidates prior-generation captures',
      () async {
        final provider = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );
        await provider.restoreSession();
        final genDuringAuth = provider.generation;
        expect(
          provider.isCurrentSession(
            userId: _sessionA.userId,
            generation: genDuringAuth,
          ),
          isTrue,
        );

        await provider.signOut();
        final genAfterSignOut = provider.generation;
        expect(genAfterSignOut, greaterThan(genDuringAuth));
        expect(
          provider.isCurrentSession(
            userId: _sessionA.userId,
            generation: genDuringAuth,
          ),
          isFalse,
        );

        // Re-authenticating the SAME identity from guest is itself a new
        // identity transition (guest → authenticated), so the epoch advances
        // again (finding 6/19).
        await provider.restoreSession();
        expect(provider.generation, greaterThan(genAfterSignOut));
        expect(
          provider.isCurrentSession(
            userId: _sessionA.userId,
            generation: genDuringAuth,
          ),
          isFalse,
        );
        provider.dispose();
      },
    );

    test('advances on explicit sign-out', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
      );
      await provider.restoreSession();
      final genBeforeSignOut = provider.generation;
      await provider.signOut();
      expect(provider.generation, greaterThan(genBeforeSignOut));
      provider.dispose();
    });

    test('advances on external session loss', () async {
      final gateway = FakeAuthGateway(restoredSession: _sessionA);
      final provider = AuthProvider(gateway: gateway);
      await provider.restoreSession();
      final gen = provider.generation;

      gateway.emit(const AuthEvent(type: AuthEventType.sessionLost));
      await _settle();
      expect(provider.generation, greaterThan(gen));
      expect(provider.status, AuthStatus.guest);
      provider.dispose();
    });

    test('same-user re-authentication does NOT advance generation', () async {
      final gateway = FakeAuthGateway(restoredSession: _sessionA);
      final provider = AuthProvider(gateway: gateway);
      await provider.restoreSession();
      final gen = provider.generation;

      gateway.emit(
        AuthEvent(type: AuthEventType.sessionRestored, session: _sessionA),
      );
      await _settle();
      expect(provider.generation, gen);
      provider.dispose();
    });

    test(
      'different-user sign-in advances generation and replaces session',
      () async {
        final gateway = FakeAuthGateway(restoredSession: _sessionA);
        final provider = AuthProvider(gateway: gateway);
        await provider.restoreSession();
        final genA = provider.generation;

        gateway.emit(
          AuthEvent(type: AuthEventType.signedIn, session: _sessionB),
        );
        await _settle();
        expect(provider.generation, greaterThan(genA));
        expect(provider.session, _sessionB);
        provider.dispose();
      },
    );
  });

  // ------------------------------------------------------------------
  // §5 isCurrentSession gating
  // ------------------------------------------------------------------
  group('isCurrentSession', () {
    test('true for matching userId + generation while logged in', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
      );
      await provider.restoreSession();
      expect(
        provider.isCurrentSession(
          userId: _sessionA.userId,
          generation: provider.generation,
        ),
        isTrue,
      );
      provider.dispose();
    });

    test('false for a stale generation', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
      );
      await provider.restoreSession();
      expect(
        provider.isCurrentSession(userId: _sessionA.userId, generation: 999),
        isFalse,
      );
      provider.dispose();
    });

    test('false for a different userId', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
      );
      await provider.restoreSession();
      expect(
        provider.isCurrentSession(
          userId: 'wrong-id',
          generation: provider.generation,
        ),
        isFalse,
      );
      provider.dispose();
    });

    test('false in guest state', () {
      final provider = AuthProvider(gateway: FakeAuthGateway());
      expect(
        provider.isCurrentSession(userId: _sessionA.userId, generation: 0),
        isFalse,
      );
      provider.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §6 Sign-in concurrency guard
  // ------------------------------------------------------------------
  group('sign-in concurrency', () {
    test(
      'concurrent signInWithGoogle calls reuse the pending future',
      () async {
        final completer = Completer<AuthSession?>();
        final gateway = _BlockingGateway(completer);
        final provider = AuthProvider(gateway: gateway);

        final future1 = provider.signInWithGoogle();
        final future2 = provider.signInWithGoogle();

        expect(gateway.signInCalls, 1); // only one underlying sign-in started

        completer.complete(_sessionA);
        await Future.wait([future1, future2]);
        expect(provider.status, AuthStatus.authenticated);
        expect(gateway.signInCalls, 1);
        provider.dispose();
      },
    );

    test('sign-in while resolving reuses the pending operation', () async {
      final completer = Completer<AuthSession?>();
      final gateway = _BlockingGateway(completer);
      final provider = AuthProvider(gateway: gateway);

      final f1 = provider.signInWithGoogle();
      final f2 = provider.signInWithGoogle();
      final f3 = provider.signInWithGoogle();

      expect(gateway.signInCalls, 1);
      completer.complete(_sessionA);
      await Future.wait([f1, f2, f3]);
      expect(gateway.signInCalls, 1);
      provider.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §7 Sign-out contract (fail-closed)
  // ------------------------------------------------------------------
  group('sign-out', () {
    test('successful sign-out → guest', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
      );
      await provider.restoreSession();
      expect(provider.isLoggedIn, isTrue);

      await provider.signOut();
      expect(provider.status, AuthStatus.guest);
      expect(provider.session, isNull);
      provider.dispose();
    });

    test('failed remote sign-out never fakes guest (fail-closed)', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(
          restoredSession: _sessionA,
          signOutError: Exception('network'),
        ),
      );
      await provider.restoreSession();
      expect(provider.isLoggedIn, isTrue);

      await provider.signOut();
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.error, AuthError.signOutFailed);
      expect(provider.session, isNotNull);
      provider.dispose();
    });

    test('signOut as guest is a no-op', () async {
      final provider = AuthProvider(gateway: FakeAuthGateway());
      await provider.signOut();
      expect(provider.status, AuthStatus.guest);
      provider.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §4 Auth event stream — session reconciliation
  // ------------------------------------------------------------------
  group('authEvents stream reconciliation', () {
    test('external signedOut event → guest', () async {
      final gateway = FakeAuthGateway(restoredSession: _sessionA);
      final provider = AuthProvider(gateway: gateway);
      await provider.restoreSession();
      expect(provider.isLoggedIn, isTrue);

      gateway.emit(const AuthEvent(type: AuthEventType.signedOut));
      await _settle();
      expect(provider.status, AuthStatus.guest);
      expect(provider.session, isNull);
      provider.dispose();
    });

    test(
      'tokenRefreshed event updates session without advancing generation',
      () async {
        final gateway = FakeAuthGateway(restoredSession: _sessionA);
        final provider = AuthProvider(gateway: gateway);
        await provider.restoreSession();
        final gen = provider.generation;

        const refreshedSession = AuthSession(
          userId: 'uuid-0000-0000',
          email: 'a@civilpedia.com',
          displayName: 'Engineer A',
          photoUrl: 'https://new-photo.url',
        );
        gateway.emit(
          AuthEvent(
            type: AuthEventType.tokenRefreshed,
            session: refreshedSession,
          ),
        );
        await _settle();
        expect(provider.generation, gen);
        expect(provider.session?.photoUrl, 'https://new-photo.url');
        provider.dispose();
      },
    );

    test(
      'sessionLost event transitions to guest and advances generation',
      () async {
        final gateway = FakeAuthGateway(restoredSession: _sessionA);
        final provider = AuthProvider(gateway: gateway);
        await provider.restoreSession();
        final gen = provider.generation;

        gateway.emit(const AuthEvent(type: AuthEventType.sessionLost));
        await _settle();
        expect(provider.status, AuthStatus.guest);
        expect(provider.generation, greaterThan(gen));
        provider.dispose();
      },
    );

    test('sessionReplaced event notifies the account-bound reset', () async {
      var resetCount = 0;
      final gateway = FakeAuthGateway(restoredSession: _sessionA);
      final provider = AuthProvider(
        gateway: gateway,
        onAccountBoundReset: () => resetCount++,
      );
      await provider.restoreSession();

      gateway.emit(
        AuthEvent(type: AuthEventType.sessionReplaced, session: _sessionB),
      );
      await _settle();
      expect(resetCount, greaterThanOrEqualTo(1));
      expect(provider.session, _sessionB);
      provider.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §10 Post-auth pipeline outcomes
  // ------------------------------------------------------------------
  group('post-auth pipeline outcomes', () {
    test('success → authenticated + success state', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
        onPostAuth: (_) async => PostAuthOutcome.success,
      );

      await provider.restoreSession();
      await _settle();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.postAuthState, PostAuthLifecycleState.success);
      provider.dispose();
    });

    test('retryableFailure keeps authenticated state', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
        onPostAuth: (_) async => PostAuthOutcome.retryableFailure,
      );

      await provider.restoreSession();
      await _settle();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.postAuthState, PostAuthLifecycleState.retryableFailure);
      provider.dispose();
    });

    test('ownershipConflict blocks auth and resets account state', () async {
      var resetCount = 0;
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
        onAccountBoundReset: () => resetCount++,
      );

      await provider.restoreSession();
      await _settle();

      expect(provider.status, AuthStatus.ownershipConflict);
      expect(provider.postAuthState, PostAuthLifecycleState.ownershipConflict);
      expect(resetCount, greaterThanOrEqualTo(1));
      provider.dispose();
    });

    test('corruptOwnershipRegistry blocks auth too', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
        onPostAuth: (_) async => PostAuthOutcome.corruptOwnershipRegistry,
      );

      await provider.restoreSession();
      await _settle();

      expect(provider.status, AuthStatus.ownershipConflict);
      expect(
        provider.postAuthState,
        PostAuthLifecycleState.corruptOwnershipRegistry,
      );
      provider.dispose();
    });

    // ----------------------------------------------------------------
    // Final pass (finding 6): a rejected second-account session must be
    // neutralized (remote sign-out) and the provider must stay fail-closed
    // in ownershipConflict even when that cleanup itself fails.
    // ----------------------------------------------------------------
    test('second-account conflict neutralizes the temporary session via '
        'gateway sign-out (F6)', () async {
      final gateway = FakeAuthGateway(restoredSession: fakeSessionOther);
      final provider = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );

      await provider.restoreSession();
      await _settle();

      expect(provider.status, AuthStatus.ownershipConflict);
      expect(provider.isLoggedIn, isFalse);
      // The rejected second-account session is never promoted: auth stays
      // blocked (fail-closed), no guest, no authenticated route.
      expect(provider.isOwnershipBlocked, isTrue);
      // Cleanup actually attempted (call-count assertion).
      expect(gateway.signOutCalls, greaterThanOrEqualTo(1));
      provider.dispose();
    });

    test('cleanup sign-out failure keeps the provider fail-closed in '
        'ownershipConflict (F6)', () async {
      final gateway = FakeAuthGateway(
        restoredSession: fakeSessionOther,
        signOutError: Exception('network-down'),
      );
      final provider = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );

      await provider.restoreSession();
      await _settle();

      // Fail-closed: not authenticated, not guest; the blocked state persists
      // until the authoritative session resolves.
      expect(provider.status, AuthStatus.ownershipConflict);
      expect(provider.isLoggedIn, isFalse);
      expect(provider.isOwnershipBlocked, isTrue);
      expect(provider.error, AuthError.ownershipConflict);
      provider.dispose();
    });

    test(
      'callback exception maps to retryableFailure, auth survives',
      () async {
        final provider = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
          onPostAuth: (_) async => throw Exception('boom'),
        );

        await provider.restoreSession();
        await _settle();

        expect(provider.status, AuthStatus.authenticated);
        expect(provider.postAuthState, PostAuthLifecycleState.retryableFailure);
        provider.dispose();
      },
    );

    test(
      'no onPostAuth registered → pipeline reports success (no work)',
      () async {
        final provider = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
        );

        await provider.restoreSession();
        await _settle();
        expect(provider.postAuthState, PostAuthLifecycleState.success);
        provider.dispose();
      },
    );
  });

  // ------------------------------------------------------------------
  // §10 Pipeline single-flight + stale-result suppression
  // ------------------------------------------------------------------
  group('pipeline single-flight', () {
    test('concurrent reconciliations share one pipeline run', () async {
      var pipelineCalls = 0;
      final completer = Completer<PostAuthOutcome>();
      final gateway = FakeAuthGateway();
      final provider = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async {
          pipelineCalls++;
          return completer.future;
        },
      );

      gateway.emit(AuthEvent(type: AuthEventType.signedIn, session: _sessionB));
      gateway.emit(AuthEvent(type: AuthEventType.signedIn, session: _sessionB));
      await _settle();
      expect(pipelineCalls, 1); // single-flight held

      completer.complete(PostAuthOutcome.success);
      await _settle();
      expect(provider.status, AuthStatus.authenticated);
      provider.dispose();
    });

    test(
      'a divergent account gets its OWN run; a stale A result is dropped',
      () async {
        final seen = <String>[];
        final releaseA = Completer<void>();
        final releaseB = Completer<void>();
        final gateway = FakeAuthGateway();
        final provider = AuthProvider(
          gateway: gateway,
          onPostAuth: (session) async {
            seen.add(session.userId);
            if (session.userId == _sessionA.userId) {
              await releaseA.future;
              return PostAuthOutcome.success;
            }
            await releaseB.future;
            return PostAuthOutcome.success;
          },
        );

        gateway.emit(
          AuthEvent(type: AuthEventType.signedIn, session: _sessionA),
        );
        await _settle();
        final genA = provider.generation;
        expect(seen, contains(_sessionA.userId));

        // A divergent account signs in while A's pipeline is still in flight:
        // it must NOT reuse A's pending future (finding 7).
        gateway.emit(
          AuthEvent(type: AuthEventType.signedIn, session: _sessionB),
        );
        await _settle();
        final genB = provider.generation;
        expect(genB, greaterThan(genA));
        expect(seen, contains(_sessionB.userId));

        releaseB.complete();
        await _settle();
        expect(provider.status, AuthStatus.authenticated);
        expect(provider.session, _sessionB);
        expect(provider.postAuthState, PostAuthLifecycleState.success);

        // A's abandoned run completes late at a stale generation: it must never
        // overwrite B's session or lifecycle state.
        releaseA.complete();
        await _settle();
        expect(provider.session, _sessionB);
        expect(provider.postAuthState, PostAuthLifecycleState.success);
        expect(
          provider.isCurrentSession(userId: _sessionA.userId, generation: genA),
          isFalse,
        );
        expect(
          provider.isCurrentSession(userId: _sessionB.userId, generation: genB),
          isTrue,
        );
        provider.dispose();
      },
    );

    test(
      're-authenticating the SAME user from guest re-runs the pipeline',
      () async {
        var pipelineCalls = 0;
        final gateway = FakeAuthGateway(restoredSession: _sessionA);
        final provider = AuthProvider(
          gateway: gateway,
          onPostAuth: (_) async {
            pipelineCalls++;
            return PostAuthOutcome.success;
          },
        );

        await provider.restoreSession();
        await _settle();
        expect(pipelineCalls, 1);

        await provider.signOut();
        await _settle();
        expect(provider.status, AuthStatus.guest);

        // Guest → authenticated is a NEW epoch, so the pipeline re-runs for the
        // same identity instead of reusing the settled (user, generation) pair.
        await provider.restoreSession();
        await _settle();
        expect(pipelineCalls, 2);
        expect(provider.status, AuthStatus.authenticated);
        provider.dispose();
      },
    );
  });

  // ------------------------------------------------------------------
  // §10 Post-auth retry (finding 9)
  // ------------------------------------------------------------------
  group('post-auth retry', () {
    test(
      'retries only a current authenticated session with retryableFailure',
      () async {
        var runCount = 0;
        final provider = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: _sessionA),
          onPostAuth: (_) async {
            runCount++;
            return PostAuthOutcome.retryableFailure;
          },
        );

        await provider.restoreSession();
        await _settle();
        expect(runCount, 1);
        expect(provider.postAuthState, PostAuthLifecycleState.retryableFailure);

        await provider.retryPostAuth();
        await _settle();
        expect(runCount, 2);
        expect(provider.postAuthState, PostAuthLifecycleState.retryableFailure);
        provider.dispose();
      },
    );

    test('retry is a no-op when the pipeline already succeeded', () async {
      var runCount = 0;
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
        onPostAuth: (_) async {
          runCount++;
          return PostAuthOutcome.success;
        },
      );

      await provider.restoreSession();
      await _settle();
      expect(provider.postAuthState, PostAuthLifecycleState.success);

      await provider.retryPostAuth();
      await _settle();
      expect(runCount, 1);
      provider.dispose();
    });

    test('retry while signed out is a no-op', () async {
      var runCount = 0;
      final provider = AuthProvider(
        gateway: FakeAuthGateway(),
        onPostAuth: (_) async {
          runCount++;
          return PostAuthOutcome.success;
        },
      );

      await provider.retryPostAuth();
      await _settle();
      expect(runCount, 0);
      provider.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §8 Account-bound reset callback
  // ------------------------------------------------------------------
  group('account-bound reset', () {
    test('fires on explicit sign-out', () async {
      var resetCount = 0;
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
        onAccountBoundReset: () => resetCount++,
      );

      await provider.restoreSession();
      expect(resetCount, 0);
      await provider.signOut();
      expect(resetCount, greaterThanOrEqualTo(1));
      provider.dispose();
    });

    test('fires on external session loss', () async {
      var resetCount = 0;
      final gateway = FakeAuthGateway(restoredSession: _sessionA);
      final provider = AuthProvider(
        gateway: gateway,
        onAccountBoundReset: () => resetCount++,
      );

      await provider.restoreSession();
      expect(resetCount, 0);

      gateway.emit(const AuthEvent(type: AuthEventType.sessionLost));
      await _settle();
      expect(resetCount, greaterThanOrEqualTo(1));
      provider.dispose();
    });

    test('does NOT fire on plain token refresh', () async {
      var resetCount = 0;
      final gateway = FakeAuthGateway(restoredSession: _sessionA);
      final provider = AuthProvider(
        gateway: gateway,
        onAccountBoundReset: () => resetCount++,
      );

      await provider.restoreSession();
      gateway.emit(
        const AuthEvent(type: AuthEventType.tokenRefreshed, session: _sessionA),
      );
      await _settle();
      expect(resetCount, 0);
      provider.dispose();
    });
  });

  // ------------------------------------------------------------------
  // F6 — Second-account conflict: bootstrap suppression + account-bound
  // clearance (behavioral, production-free).
  // ------------------------------------------------------------------
  group('second-account conflict (F6)', () {
    test(
      'B: bootstrap suppressed, A data cleared, cleanup signOut succeeds',
      () async {
        final h = _SecondAccountHarness();

        // Stage A: authenticate and install identifiable A data.
        await h.auth.restoreSession();
        await _settle();
        await h.profile.ensureCloudProfileLoaded();
        await h.business.loadApplications();
        await h.claims.reload();

        expect(h.auth.status, AuthStatus.authenticated);
        expect(h.auth.isLoggedIn, isTrue);
        expect(h.profile.authenticatedProfile?.userId, _sessionA.userId);
        expect(h.profile.isCloudBound, isTrue);
        expect(h.business.applications, isNotEmpty);
        expect(h.claims.targets, isNotEmpty);

        // Stage B: a SECOND account signs in on the same device.
        h.gateway.emit(
          const AuthEvent(type: AuthEventType.signedIn, session: _sessionB),
        );
        await _settle(ticks: 8);

        // B bootstrap was suppressed BEFORE it could run.
        expect(
          h.bootstrapUsers.where((id) => id == _sessionB.userId),
          isEmpty,
          reason: 'the rejected second account must NEVER run bootstrap',
        );

        // The temporary B session cleanup sign-out was invoked.
        expect(h.gateway.signOutCalls, greaterThanOrEqualTo(1));

        // The account-bound reset seam fired and cleared A's real data.
        expect(h.resetCount, greaterThanOrEqualTo(1));
        expect(h.profile.authenticatedProfile, isNull);
        expect(h.profile.isCloudBound, isFalse);
        expect(
          h.business.applications,
          isEmpty,
          reason: "A's business-application state must not survive",
        );
        expect(
          h.claims.targets,
          isEmpty,
          reason: "A's claim-candidate state must not survive",
        );

        // The device is held in the blocking ownership-conflict state, NOT a
        // usable authenticated B state, so no B-differentiated UI can render.
        expect(h.auth.status, AuthStatus.ownershipConflict);
        expect(h.auth.isOwnershipBlocked, isTrue);
        expect(h.auth.isLoggedIn, isFalse);
        expect(h.auth.postAuthState, PostAuthLifecycleState.ownershipConflict);

        // No B private state was installed anywhere.
        expect(h.business.applications, isEmpty);
        expect(h.business.current, isNull);
        expect(h.claims.targets, isEmpty);
        expect(h.profile.authenticatedProfile, isNull);

        h.dispose();
      },
    );

    test('B: cleanup signOut FAILURE still clears A and stays open-ended '
        'blocked without any auto bootstrap', () async {
      final h = _SecondAccountHarness(signOutError: Exception('network down'));

      // Stage A: authenticate and install identifiable A data.
      await h.auth.restoreSession();
      await _settle();
      await h.profile.ensureCloudProfileLoaded();
      await h.business.loadApplications();
      await h.claims.reload();

      expect(h.auth.status, AuthStatus.authenticated);

      // Stage B: second account arrival while the cleanup cannot complete.
      h.gateway.emit(
        const AuthEvent(type: AuthEventType.signedIn, session: _sessionB),
      );
      await _settle(ticks: 8);

      // Even with the sign-out failing, B's bootstrap never ran.
      expect(
        h.bootstrapUsers.where((id) => id == _sessionB.userId),
        isEmpty,
        reason: 'a failed temp-session cleanup must NOT re-enable bootstrap',
      );

      // The account-bound reset still wiped A's real data (fail-closed).
      expect(h.resetCount, greaterThanOrEqualTo(1));
      expect(h.profile.authenticatedProfile, isNull);
      expect(h.profile.isCloudBound, isFalse);
      expect(h.business.applications, isEmpty);
      expect(h.claims.targets, isEmpty);

      // B never installed a private state (no usable B surface exists).
      expect(h.business.applications, isEmpty);
      expect(h.profile.authenticatedProfile, isNull);
      expect(h.auth.isLoggedIn, isFalse);

      // The device rests in the open-ended, block-everything conflict state.
      expect(h.auth.status, AuthStatus.ownershipConflict);
      expect(h.auth.isOwnershipBlocked, isTrue);
      expect(h.auth.error, AuthError.ownershipConflict);
      expect(h.auth.postAuthState, PostAuthLifecycleState.ownershipConflict);

      // Manual retry cannot bootstrap B either (only the owner may proceed).
      h.auth.retryPostAuth();
      await _settle(ticks: 8);
      expect(h.bootstrapUsers.where((id) => id == _sessionB.userId), isEmpty);
      expect(h.auth.status, AuthStatus.ownershipConflict);

      h.dispose();
    });
  });

  // ------------------------------------------------------------------
  // clearError
  // ------------------------------------------------------------------
  group('clearError', () {
    test('clears error and returns to guest', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(signInError: Exception('boom')),
      );
      await provider.signInWithGoogle();
      expect(provider.error, isNotNull);
      provider.clearError();
      expect(provider.error, isNull);
      expect(provider.status, AuthStatus.guest);
      provider.dispose();
    });

    test('cannot clear a blocking ownership conflict', () async {
      final provider = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: _sessionA),
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );
      await provider.restoreSession();
      await _settle();
      expect(provider.status, AuthStatus.ownershipConflict);

      provider.clearError();
      expect(provider.status, AuthStatus.ownershipConflict);
      expect(provider.error, AuthError.ownershipConflict);
      provider.dispose();
    });
  });
}
