import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/remote_operation_policy.dart';
import '../../../../core/services/logger_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/cloud_profile.dart';
import '../../data/personal_profile_remote_gateway.dart';
import '../../data/region_preference.dart';
import '../../data/region_preference_gateway.dart';
import '../../domain/user_profile.dart';
import '../../domain/user_profile_repository.dart';
import 'profile_operation_result.dart';

/// P2-C1 transient state for the active authenticated-profile read surface.
enum AuthenticatedProfileReadPhase {
  idle,
  loading,
  refreshing,
  loaded,
  authoritativeNotFound,
  failed,
}

typedef _ProfileReadKey = ({
  String userId,
  int authGeneration,
  int profileRevision,
});

/// V1-R08 — Session-aware owner of the personal profile, with a strict
/// gated-bounded authority split (finding 1 / 17):
///
/// * GUEST state: the on-device [LocalUserProfile] ([profile]) is the only
///   profile surfaced.
/// * AUTHENTICATED state: `public.profiles` is the SINGLE SOURCE OF TRUTH.
///   The provider exposes [authenticatedProfile] (a strictly-parsed
///   [CloudProfile]); [profile] returns null — the local profile is NEVER used
///   as an authenticated fallback and [saveProfile] is a no-op while signed in.
///
/// Every cloud read/write is session- AND generation-gated ([AuthProvider.
/// isCurrentSession]): a result that lands after sign-out/account-switch is
/// never published into a different (or guest) session.
///
/// V1-R08 (finding 3/13/14) — the ONLY authenticated mutation authored here is
/// [saveRoleAndRegionPreference]: values are validated against the frozen
/// canonical sets BEFORE any remote call, a duplicate save is a no-op before
/// any mutation, a failed write preserves prior cloud state, and only a
/// successful authoritative strict re-read installs new state (with stale
/// results suppressed after a session change). Outcomes are typed
/// [ProfileOperationResult]/[ProfileOperationCause].
class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider({
    required UserProfileRepository repository,
    PersonalProfileRemoteGateway? cloudProfileGateway,
    RegionPreferenceGateway? regionPreferenceGateway,
    AuthProvider? auth,
  }) : _repository = repository,
       _cloudProfileGateway = cloudProfileGateway,
       _regionPreferenceGateway = regionPreferenceGateway,
       _auth = auth {
    _auth?.addListener(_handleAuthChanged);
  }

  final UserProfileRepository _repository;
  final PersonalProfileRemoteGateway? _cloudProfileGateway;
  final RegionPreferenceGateway? _regionPreferenceGateway;
  final AuthProvider? _auth;

  LocalUserProfile? _profile;
  bool _isLoaded = false;
  bool _profileLoadFailed = false;

  CloudProfile? _authenticatedProfile;
  AuthenticatedProfileReadPhase _cloudReadPhase =
      AuthenticatedProfileReadPhase.idle;
  ProfileReadFailureKind? _cloudReadFailure;
  String? _authenticatedRegionPreferenceCode;
  String? _lastWatchedUser;
  int _lastWatchedGeneration = 0;
  final Map<_ProfileReadKey, Future<void>> _cloudReadsInFlight = {};
  int _cloudReadRequestEpoch = 0;
  int _profileRevision = 0;
  bool _disposed = false;

  /// F3 — coalesces concurrent [saveRoleAndRegionPreference] invocations so the
  /// backend `saveEditableFields` is invoked at most once per burst. A caller
  /// that arrives while a save is in flight awaits the SAME remote operation
  /// and shares its authoritative result (single remote mutation, no double
  /// writes).
  Future<ProfileOperationResult>? _saveInFlight;

  // Process-local request metadata only; never a profile cache or replay queue.
  ({String userId, int generation, String role, String? region})?
  _uncertainSave;

  /// The on-device local profile. NULL while an authenticated session is
  /// active (the cloud profile is canonical and the local profile is never a
  /// signed-in fallback — finding 1/17).
  LocalUserProfile? get profile =>
      (_auth?.isLoggedIn ?? false) ? null : _profile;

  bool get isLoaded => _isLoaded;
  bool get profileLoadFailed => _profileLoadFailed;

  /// The authoritative, strictly-parsed cloud profile for the ACTIVE
  /// authenticated session, or null while signed out / not yet loaded.
  CloudProfile? get authenticatedProfile => _authenticatedProfile;

  /// The stable six-zone preference **code** (e.g. [RegionPreferenceCode.
  /// baghdadKarkh]) derived from the cloud profile's [CloudProfile.
  /// regionPreferenceId] UUID by reverse resolution via the [RegionPreferenceGateway].
  /// Display-only; null when the cloud profile has no region set or when the
  /// reverse resolution fails (never fabricated).
  String? get authenticatedRegionPreferenceCode =>
      _authenticatedRegionPreferenceCode;

  /// True only while a cloud profile is authoritatively loaded for the active
  /// authenticated session.
  bool get isCloudBound {
    final auth = _auth;
    return auth != null &&
        auth.isLoggedIn &&
        auth.currentUserId != null &&
        _authenticatedProfile != null &&
        _authenticatedProfile!.userId == auth.currentUserId;
  }

  /// Typed lifecycle state consumed by the P2-C2 presentation layer.
  AuthenticatedProfileReadPhase get cloudReadPhase => _cloudReadPhase;

  /// Exact sanitized cause of the latest failed authenticated read.
  ProfileReadFailureKind? get cloudReadFailure => _cloudReadFailure;

  /// Backward-compatible view used by the existing V1-R08 screens until
  /// P2-C2 migrates them to [cloudReadPhase]/[cloudReadFailure].
  bool get cloudLoadFailed =>
      _cloudReadPhase == AuthenticatedProfileReadPhase.failed;

  /// True while a known-good same-user profile stays visible during a read.
  bool get isCloudProfileRefreshing =>
      _cloudReadPhase == AuthenticatedProfileReadPhase.refreshing;

  /// V1-R08 (Part 2) — True while an authenticated cloud profile read is still
  /// in flight and has NOT settled to a row, "no row", or failure. Lets the UI
  /// render a loading state (never "not set" / "not available") between the
  /// moment an identity is established and the moment the canonical read
  /// settles — and shows nothing misleading when no read has settled yet.
  /// False for guests and when the provider has no auth wiring.
  bool get isCloudProfileLoading {
    final auth = _auth;
    if (auth == null || !auth.isLoggedIn) return false;
    return _authenticatedProfile == null &&
        _cloudReadPhase == AuthenticatedProfileReadPhase.loading;
  }

  Future<void> loadProfile() async {
    try {
      _profile = await _repository.loadProfile();
      _profileLoadFailed = false;
    } catch (error) {
      LoggerService.error('Local profile load failed', error);
      _profileLoadFailed = true;
      _profile = null;
    }
    _isLoaded = true;
    _notifyIfAlive();
  }

  Future<void> saveProfile(LocalUserProfile value) async {
    // Authenticated → the cloud row is canonical. Writing a local surrogate
    // could silently shadow cloud state, so it is rejected outright.
    if (_auth?.isLoggedIn ?? false) return;
    await _repository.saveProfile(value);
    if (_disposed) return;
    _profile = value;
    _notifyIfAlive();
  }

  Future<void> clearProfile() async {
    await _repository.clearProfile();
    if (_disposed) return;
    _profile = null;
    _authenticatedProfile = null;
    _authenticatedRegionPreferenceCode = null;
    _cloudReadFailure = null;
    _cloudReadPhase = AuthenticatedProfileReadPhase.idle;
    _profileRevision++;
    _cloudReadRequestEpoch++;
    _notifyIfAlive();
  }

  /// Loads the authoritative cloud profile for the ACTIVE authenticated
  /// session. Concurrent calls coalesce only when their exact logical key
  /// `(userId, authGeneration, profileRevision)` matches.
  Future<void> ensureCloudProfileLoaded() async {
    if (_disposed) return;
    final auth = _auth;
    if (auth == null || !auth.isLoggedIn) return;
    final userId = auth.currentUserId;
    if (userId == null) return;
    final generation = auth.generation;

    // Fail closed if an impossible foreign in-memory profile survived an
    // external harness/state transition. It must never be retained for the
    // current identity or treated as refreshable content.
    if (_authenticatedProfile != null &&
        _authenticatedProfile!.userId != userId) {
      _authenticatedProfile = null;
      _authenticatedRegionPreferenceCode = null;
      _profileRevision++;
    }

    // A provider constructed after an already-restored session may receive
    // its first read before any auth-listener transition. Record that same
    // canonical identity so a later same-generation token refresh does not
    // look like an account replacement.
    _lastWatchedUser = userId;
    _lastWatchedGeneration = generation;

    final key = (
      userId: userId,
      authGeneration: generation,
      profileRevision: _profileRevision,
    );
    final pending = _cloudReadsInFlight[key];
    if (pending != null) {
      await pending;
      return;
    }

    final requestEpoch = ++_cloudReadRequestEpoch;
    _cloudReadFailure = null;
    _cloudReadPhase = _authenticatedProfile?.userId == userId
        ? AuthenticatedProfileReadPhase.refreshing
        : AuthenticatedProfileReadPhase.loading;

    late final Future<void> run;
    run =
        Future<void>.microtask(
          () => _loadCloudProfile(key: key, requestEpoch: requestEpoch),
        ).whenComplete(() {
          if (identical(_cloudReadsInFlight[key], run)) {
            _cloudReadsInFlight.remove(key);
          }
        });
    _cloudReadsInFlight[key] = run;
    _notifyIfAlive();
    await run;
  }

  Future<void> _loadCloudProfile({
    required _ProfileReadKey key,
    required int requestEpoch,
  }) async {
    final auth = _auth;
    final gateway = _cloudProfileGateway;
    if (auth == null || gateway == null) {
      _publishReadFailure(
        key: key,
        requestEpoch: requestEpoch,
        failure: ProfileReadFailureKind.unexpected,
      );
      return;
    }
    try {
      final loaded = await gateway.fetchByUserId(key.userId);
      if (!_canPublishRead(key: key, requestEpoch: requestEpoch)) return;
      if (loaded == null) {
        // Successful absence is authoritative, but provisioning remains
        // exclusively owned by PersonalProfileBootstrapCoordinator.
        final changed =
            _authenticatedProfile != null ||
            _authenticatedRegionPreferenceCode != null;
        _authenticatedProfile = null;
        _authenticatedRegionPreferenceCode = null;
        _cloudReadFailure = null;
        _cloudReadPhase = AuthenticatedProfileReadPhase.authoritativeNotFound;
        if (changed) _profileRevision++;
        _notifyIfAlive();
      } else {
        if (loaded.userId != key.userId) {
          _publishReadFailure(
            key: key,
            requestEpoch: requestEpoch,
            failure: ProfileReadFailureKind.malformedResponse,
          );
          return;
        }
        final regionCode = await _resolveRegionPreferenceCode(
          loaded.regionPreferenceId,
        );
        if (!_canPublishRead(key: key, requestEpoch: requestEpoch)) return;
        // Advance before publication so any older read captured at the prior
        // revision is immediately stale.
        _profileRevision++;
        _authenticatedProfile = loaded;
        _authenticatedRegionPreferenceCode = regionCode;
        _cloudReadFailure = null;
        _cloudReadPhase = AuthenticatedProfileReadPhase.loaded;
        _notifyIfAlive();
      }
    } catch (error) {
      _publishReadFailure(
        key: key,
        requestEpoch: requestEpoch,
        failure: classifyProfileReadFailure(error),
      );
    }
  }

  bool _canPublishRead({
    required _ProfileReadKey key,
    required int requestEpoch,
  }) {
    final auth = _auth;
    return !_disposed &&
        requestEpoch == _cloudReadRequestEpoch &&
        key.profileRevision == _profileRevision &&
        auth != null &&
        auth.isCurrentSession(
          userId: key.userId,
          generation: key.authGeneration,
        );
  }

  void _publishReadFailure({
    required _ProfileReadKey key,
    required int requestEpoch,
    required ProfileReadFailureKind failure,
  }) {
    if (!_canPublishRead(key: key, requestEpoch: requestEpoch)) return;
    // Preserve a known-good same-user profile. Fail closed if a foreign value
    // somehow reached this state; guest/local data is never substituted.
    if (_authenticatedProfile != null &&
        _authenticatedProfile!.userId != key.userId) {
      _authenticatedProfile = null;
      _authenticatedRegionPreferenceCode = null;
      _profileRevision++;
      _cloudReadRequestEpoch++;
      _cloudReadFailure = null;
      _cloudReadPhase = AuthenticatedProfileReadPhase.idle;
      _notifyIfAlive();
      return;
    }
    _cloudReadFailure = failure;
    _cloudReadPhase = AuthenticatedProfileReadPhase.failed;
    _notifyIfAlive();
  }

  /// Reverse-lookup of a cloud profile's `region_preferences.id` UUID → the
  /// stable six-zone code for display. Display-only: a missing id, an unknown
  /// id, or a failed lookup yields null (the UI renders "not set"; the code is
  /// never fabricated).
  Future<String?> _resolveRegionPreferenceCode(
    String? regionPreferenceId,
  ) async {
    final regionGateway = _regionPreferenceGateway;
    if (regionGateway == null ||
        regionPreferenceId == null ||
        regionPreferenceId.isEmpty) {
      return null;
    }
    try {
      return await regionGateway.resolveCodeById(regionPreferenceId);
    } catch (_) {
      return null;
    }
  }

  /// V1-R08 (finding 3/13/14) — Saves the authenticated user's role and,
  /// optionally, their six-zone Region Preference.
  ///
  /// Ordering guarantees:
  /// 1. Rejects any request without a current authenticated session.
  /// 2. Validates both values against the frozen canonical sets BEFORE any
  ///    remote call (invalidData, no mutation).
  /// 3. Resolves the region code → canonical `region_preferences.id` via the
  ///    [RegionPreferenceGateway]; a known code that cannot be resolved is a
  ///    retryable/invalid failure.
  /// 4. Duplicate guard: identical values to the current authoritative profile
  ///    are a success WITHOUT any backend mutation (`wasNoOp`).
  /// 5. The write goes out as a single `saveEditableFields` call; a failure
  ///    preserves prior cloud state and maps to a typed [ProfileOperationCause].
  /// 6. A successful write triggers an authoritative strict re-read; ONLY a
  ///    successful parse under the same (userId, generation) installs new state.
  Future<ProfileOperationResult> saveRoleAndRegionPreference({
    required String roleCode,
    String? regionPreferenceCode,
  }) {
    // F3 single-flight: coalesce concurrent invocations onto one remote save.
    final pending = _saveInFlight;
    if (pending != null) return pending;
    final run = _runSaveRoleAndRegionPreference(
      roleCode: roleCode,
      regionPreferenceCode: regionPreferenceCode,
    );
    _saveInFlight = run;
    return run.whenComplete(() {
      if (identical(_saveInFlight, run)) _saveInFlight = null;
    });
  }

  /// F3 — the actual save pipeline (see [saveRoleAndRegionPreference]).
  Future<ProfileOperationResult> _runSaveRoleAndRegionPreference({
    required String roleCode,
    String? regionPreferenceCode,
  }) async {
    final auth = _auth;
    final gateway = _cloudProfileGateway;
    final regionGateway = _regionPreferenceGateway;
    if (auth == null ||
        !auth.isLoggedIn ||
        gateway == null ||
        regionGateway == null) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.unauthenticated,
      );
    }
    if (!auth.canAccountAuthorityBeGranted) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.authorityBlocked,
      );
    }
    final userId = auth.currentUserId;
    final generation = auth.generation;
    if (userId == null || userId.isEmpty) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.unauthenticated,
      );
    }
    ProfileOperationCause? lostAuthority() {
      if (_disposed) return ProfileOperationCause.sessionLost;
      if (!auth.isCurrentSession(userId: userId, generation: generation))
        return ProfileOperationCause.sessionLost;
      if (!auth.canAccountAuthorityBeGranted)
        return ProfileOperationCause.authorityBlocked;
      return null;
    }

    if (!isCanonicalRoleCode(roleCode)) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.invalidData,
      );
    }
    final trimmedRegion = regionPreferenceCode?.trim();
    String? regionPreferenceId;
    if (trimmedRegion != null && trimmedRegion.isNotEmpty) {
      if (!RegionPreferenceCode.isKnown(trimmedRegion)) {
        return const ProfileOperationResult.failed(
          ProfileOperationCause.invalidData,
        );
      }
      try {
        regionPreferenceId = await regionGateway.resolvePreferenceIdByCode(
          trimmedRegion,
        );
      } catch (error) {
        return ProfileOperationResult.failed(
          lostAuthority() ?? _failureCause(error),
        );
      }
      final lost = lostAuthority();
      if (lost != null) return ProfileOperationResult.failed(lost);
      if (regionPreferenceId == null) {
        return const ProfileOperationResult.failed(
          ProfileOperationCause.invalidData,
        );
      }
    }

    bool matches(CloudProfile profile) =>
        profile.roleCode == roleCode &&
        (regionPreferenceId == null ||
            profile.regionPreferenceId == regionPreferenceId);

    Future<ProfileOperationResult> publish(
      CloudProfile fresh, {
      bool noOp = false,
    }) async {
      if (fresh.userId != userId) {
        return const ProfileOperationResult.failed(
          ProfileOperationCause.ownershipConflict,
        );
      }
      final regionCode = await _resolveRegionPreferenceCode(
        fresh.regionPreferenceId,
      );
      final lost = lostAuthority();
      if (lost != null) return ProfileOperationResult.failed(lost);
      // P2-C1: an accepted authoritative mutation publication advances the
      // canonical in-memory revision before any older read can publish.
      _profileRevision++;
      _authenticatedProfile = fresh;
      _authenticatedRegionPreferenceCode = regionCode;
      _cloudReadFailure = null;
      _cloudReadPhase = AuthenticatedProfileReadPhase.loaded;
      _notifyIfAlive();
      return matches(fresh)
          ? ProfileOperationResult.ok(profile: fresh, wasNoOp: noOp)
          : const ProfileOperationResult.failed(
              ProfileOperationCause.profileConflict,
            );
    }

    final uncertain = _uncertainSave;
    var conditionalRetry = false;
    final hasStaleUncertainty =
        uncertain != null &&
        (uncertain.userId != userId || uncertain.generation != generation);

    if (uncertain != null &&
        uncertain.userId == userId &&
        uncertain.generation == generation) {
      // A timed-out write may already have committed. Inspect current authority
      // before another intentional attempt; never overwrite an observed region.
      CloudProfile? current;
      try {
        current = await gateway.fetchByUserId(userId);
      } catch (error) {
        return ProfileOperationResult.failed(
          lostAuthority() ?? _failureCause(error),
        );
      }
      final lost = lostAuthority();
      if (lost != null) return ProfileOperationResult.failed(lost);
      if (current == null)
        return const ProfileOperationResult.failed(
          ProfileOperationCause.provisioningFailure,
        );
      if (current.userId != userId)
        return const ProfileOperationResult.failed(
          ProfileOperationCause.ownershipConflict,
        );
      if (_isProfileMutationPending(userId)) {
        return const ProfileOperationResult.failed(
          ProfileOperationCause.retryableFailure,
        );
      }
      _uncertainSave = null;
      if (matches(current)) {
        return publish(current, noOp: true);
      }
      if ((regionPreferenceId != null && current.regionPreferenceId != null) ||
          uncertain.role != roleCode ||
          uncertain.region != regionPreferenceId) {
        await publish(current);
        final lost = lostAuthority();
        return ProfileOperationResult.failed(
          lost ?? ProfileOperationCause.profileConflict,
        );
      }
      // Only the same request can be explicitly retried while the authoritative
      // region is absent and the old raw write has settled.
      conditionalRetry = regionPreferenceId != null;
    } else if (hasStaleUncertainty) {
      // A stale local uncertainty (different user or generation) does NOT prove
      // the underlying raw mutation has settled. The gateway's pending-mutation
      // state is authoritative, and an authoritative reread is required before
      // another mutation whenever the previous outcome was uncertain.
      if (_isProfileMutationPending(userId)) {
        return const ProfileOperationResult.failed(
          ProfileOperationCause.retryableFailure,
        );
      }
      CloudProfile? current;
      try {
        current = await gateway.fetchByUserId(userId);
      } catch (error) {
        return ProfileOperationResult.failed(
          lostAuthority() ?? _failureCause(error),
        );
      }
      final lost = lostAuthority();
      if (lost != null) return ProfileOperationResult.failed(lost);
      if (current == null)
        return const ProfileOperationResult.failed(
          ProfileOperationCause.provisioningFailure,
        );
      if (current.userId != userId)
        return const ProfileOperationResult.failed(
          ProfileOperationCause.ownershipConflict,
        );
      _uncertainSave = null;
      if (matches(current)) {
        return publish(current, noOp: true);
      }
      if (regionPreferenceId != null && current.regionPreferenceId != null) {
        await publish(current);
        return const ProfileOperationResult.failed(
          ProfileOperationCause.profileConflict,
        );
      }
      // The raw mutation has settled and the authoritative region is still
      // absent; a fresh mutation may proceed under the current generation.
      conditionalRetry = regionPreferenceId != null;
    } else {
      // No prior uncertainty, but the gateway is still authoritative for
      // whether a raw mutation for this user is in flight.
      if (_isProfileMutationPending(userId)) {
        return const ProfileOperationResult.failed(
          ProfileOperationCause.retryableFailure,
        );
      }
      _uncertainSave = null;
      final current = _authenticatedProfile;
      if (current != null && current.userId == userId && matches(current)) {
        return ProfileOperationResult.ok(profile: current, wasNoOp: true);
      }
    }

    final lost = lostAuthority();
    if (lost != null) return ProfileOperationResult.failed(lost);
    final request = (
      userId: userId,
      generation: generation,
      role: roleCode,
      region: regionPreferenceId,
    );
    _uncertainSave = request;
    try {
      if (conditionalRetry) {
        if (gateway is! ConditionalProfileRetryGateway)
          throw const CloudProfileUnexpectedException();
        await (gateway as ConditionalProfileRetryGateway)
            .saveEditableFieldsIfRegionAbsent(
              userId: userId,
              roleCode: roleCode,
              regionPreferenceId: regionPreferenceId,
            );
      } else {
        await gateway.saveEditableFields(
          userId: userId,
          roleCode: roleCode,
          regionPreferenceId: regionPreferenceId,
        );
      }
    } catch (error) {
      final kind = classifyProfileFailure(error);
      // A definite rejection did not commit this request. Allow corrected
      // input, but do not erase uncertainty from an earlier timed-out request.
      if (uncertain == null &&
          _uncertainSave == request &&
          (kind == ProfileFailureKind.permission ||
              kind == ProfileFailureKind.invalidData ||
              kind == ProfileFailureKind.auth)) {
        _uncertainSave = null;
      }
      return ProfileOperationResult.failed(
        lostAuthority() ?? _failureCause(error),
      );
    }
    final afterWrite = lostAuthority();
    if (afterWrite != null) return ProfileOperationResult.failed(afterWrite);
    CloudProfile? fresh;
    try {
      fresh = await gateway.fetchByUserId(userId);
    } catch (error) {
      return ProfileOperationResult.failed(
        lostAuthority() ?? _failureCause(error),
      );
    }
    final afterRead = lostAuthority();
    if (afterRead != null) return ProfileOperationResult.failed(afterRead);
    if (fresh == null) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.provisioningFailure,
      );
    }
    final result = await publish(fresh);
    if (lostAuthority() == null &&
        _uncertainSave == request &&
        uncertain == null) {
      _uncertainSave = null;
    }
    return result;
  }

  static ProfileOperationCause _failureCause(Object error) =>
      switch (classifyProfileFailure(error)) {
        ProfileFailureKind.infrastructure =>
          ProfileOperationCause.retryableFailure,
        ProfileFailureKind.auth => ProfileOperationCause.authFailure,
        ProfileFailureKind.permission => ProfileOperationCause.permissionDenied,
        ProfileFailureKind.invalidData => ProfileOperationCause.invalidData,
        ProfileFailureKind.malformed => ProfileOperationCause.malformedResponse,
        ProfileFailureKind.unexpected => ProfileOperationCause.unexpected,
      };

  /// The gateway is authoritative for whether a raw mutation for [userId] is
  /// still in flight. A generation mismatch or stale local uncertainty does NOT
  /// prove the raw write has settled.
  bool _isProfileMutationPending(String userId) {
    final gateway = _cloudProfileGateway;
    if (gateway is! ProfileMutationSettlement) return false;
    return (gateway as ProfileMutationSettlement).isProfileMutationPending(
      userId,
    );
  }

  /// Clears authenticated cloud state on a canonical identity change. Called
  /// synchronously via the account-bound reset wiring; the auth listener then
  /// reloads for the new identity.
  void resetForIdentityChange() {
    if (_disposed) return;
    _cloudReadRequestEpoch++;
    _profileRevision++;
    _authenticatedProfile = null;
    _authenticatedRegionPreferenceCode = null;
    _cloudReadFailure = null;
    _cloudReadPhase = AuthenticatedProfileReadPhase.idle;
    _lastWatchedUser = null;
    _lastWatchedGeneration = 0;
    _notifyIfAlive();
  }

  /// Fires for every [AuthProvider] change. On a canonical user/generation
  /// change the authenticated cloud profile is dropped and re-read for the new
  /// identity; sign-out drops it entirely (the local profile remains, guest
  /// authority only).
  void _handleAuthChanged() {
    if (_disposed) return;
    final auth = _auth;
    if (auth == null) return;
    final authenticated = auth.isLoggedIn;
    final userId = authenticated ? auth.currentUserId : null;
    final generation = auth.generation;

    if (!authenticated) {
      _cloudReadRequestEpoch++;
      _profileRevision++;
      _authenticatedProfile = null;
      _authenticatedRegionPreferenceCode = null;
      _cloudReadFailure = null;
      _cloudReadPhase = AuthenticatedProfileReadPhase.idle;
      _lastWatchedUser = null;
      _lastWatchedGeneration = 0;
      _notifyIfAlive();
      return;
    }

    if (userId == null) return;
    if (_lastWatchedUser == userId && _lastWatchedGeneration == generation) {
      return;
    }
    _cloudReadRequestEpoch++;
    _profileRevision++;
    _authenticatedProfile = null;
    _authenticatedRegionPreferenceCode = null;
    _cloudReadFailure = null;
    _cloudReadPhase = AuthenticatedProfileReadPhase.idle;
    _lastWatchedUser = userId;
    _lastWatchedGeneration = generation;
    _notifyIfAlive();
    unawaited(ensureCloudProfileLoaded());
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cloudReadRequestEpoch++;
    _profileRevision++;
    _cloudReadsInFlight.clear();
    _auth?.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
