import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/logger_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/cloud_profile.dart';
import '../../data/personal_profile_remote_gateway.dart';
import '../../data/region_preference.dart';
import '../../data/region_preference_gateway.dart';
import '../../domain/user_profile.dart';
import '../../domain/user_profile_repository.dart';
import 'profile_operation_result.dart';

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
  })  : _repository = repository,
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
  bool _cloudLoadFailed = false;
  bool _cloudLoadSettled = false;
  String? _authenticatedRegionPreferenceCode;
  String? _lastWatchedUser;
  int _lastWatchedGeneration = 0;
  Future<void>? _cloudLoadInFlight;

  /// F3 — coalesces concurrent [saveRoleAndRegionPreference] invocations so the
  /// backend `saveEditableFields` is invoked at most once per burst. A caller
  /// that arrives while a save is in flight awaits the SAME remote operation
  /// and shares its authoritative result (single remote mutation, no double
  /// writes).
  Future<ProfileOperationResult>? _saveInFlight;

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
  String? get authenticatedRegionPreferenceCode => _authenticatedRegionPreferenceCode;

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

  /// True when the last authoritative authenticated cloud re-read failed
  /// (offline/backend). The guest/local profile is never used as a fallback.
  bool get cloudLoadFailed => _cloudLoadFailed;

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
        !_cloudLoadFailed &&
        !_cloudLoadSettled;
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
    notifyListeners();
  }

  Future<void> saveProfile(LocalUserProfile value) async {
    // Authenticated → the cloud row is canonical. Writing a local surrogate
    // could silently shadow cloud state, so it is rejected outright.
    if (_auth?.isLoggedIn ?? false) return;
    await _repository.saveProfile(value);
    _profile = value;
    notifyListeners();
  }

  Future<void> clearProfile() async {
    await _repository.clearProfile();
    _profile = null;
    _authenticatedProfile = null;
    _authenticatedRegionPreferenceCode = null;
    _cloudLoadFailed = false;
    _cloudLoadSettled = false;
    notifyListeners();
  }

  /// Loads the authoritative cloud profile for the ACTIVE authenticated
  /// session (idempotent; coalesces concurrent calls). No-op when signed out.
  /// Results are published only while the captured (userId, generation) still
  /// matches the active session.
  Future<void> ensureCloudProfileLoaded() async {
    final auth = _auth;
    if (auth == null || !auth.isLoggedIn) return;
    final userId = auth.currentUserId;
    if (userId == null) return;
    final generation = auth.generation;

    final pending = _cloudLoadInFlight;
    if (pending != null) {
      await pending;
      return;
    }
    final run = _loadCloudProfile(userId: userId, generation: generation);
    _cloudLoadInFlight = run;
    try {
      await run;
    } finally {
      if (identical(_cloudLoadInFlight, run)) _cloudLoadInFlight = null;
    }
  }

  Future<void> _loadCloudProfile({
    required String userId,
    required int generation,
  }) async {
    final auth = _auth;
    final gateway = _cloudProfileGateway;
    if (auth == null || gateway == null) {
      _authenticatedProfile = null;
      _authenticatedRegionPreferenceCode = null;
      _cloudLoadFailed = false;
      _cloudLoadSettled = true;
      notifyListeners();
      return;
    }
    try {
      final loaded = await gateway.fetchByUserId(userId);
      // Stale suppression: the session may have changed while the read was in
      // flight; a result captured under an old identity/generation is dropped.
      if (!auth.isCurrentSession(userId: userId, generation: generation)) return;
      if (loaded == null) {
        // No row yet — provisioning belongs to the post-auth bootstrap seam;
        // the provider keeps showing no authenticated profile (fail closed).
        _authenticatedProfile = null;
        _authenticatedRegionPreferenceCode = null;
        _cloudLoadFailed = false;
        _cloudLoadSettled = true;
      } else {
        final regionCode = await _resolveRegionPreferenceCode(
          loaded.regionPreferenceId,
        );
        // Reverse-lookup was async; still publish only under the captured
        // (userId, generation).
        if (!auth.isCurrentSession(userId: userId, generation: generation)) return;
        _authenticatedProfile = loaded;
        _authenticatedRegionPreferenceCode = regionCode;
        _cloudLoadFailed = false;
        _cloudLoadSettled = true;
      }
    } on CloudProfilePermissionDeniedException {
      if (auth.isCurrentSession(userId: userId, generation: generation)) {
        _authenticatedProfile = null;
        _authenticatedRegionPreferenceCode = null;
        _cloudLoadFailed = true;
        _cloudLoadSettled = true;
      }
    } on CloudProfileParseException {
      // Strict parser rejected the row — never surface malformed data.
      if (auth.isCurrentSession(userId: userId, generation: generation)) {
        _authenticatedProfile = null;
        _authenticatedRegionPreferenceCode = null;
        _cloudLoadFailed = true;
        _cloudLoadSettled = true;
      }
    } catch (_) {
      if (auth.isCurrentSession(userId: userId, generation: generation)) {
        _authenticatedProfile = null;
        _authenticatedRegionPreferenceCode = null;
        _cloudLoadFailed = true;
        _cloudLoadSettled = true;
      }
    }
    notifyListeners();
  }

  /// Reverse-lookup of a cloud profile's `region_preferences.id` UUID → the
  /// stable six-zone code for display. Display-only: a missing id, an unknown
  /// id, or a failed lookup yields null (the UI renders "not set"; the code is
  /// never fabricated).
  Future<String?> _resolveRegionPreferenceCode(String? regionPreferenceId) async {
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
    if (auth == null || !auth.isLoggedIn || gateway == null || regionGateway == null) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.unauthenticated,
      );
    }
    final userId = auth.currentUserId;
    if (userId == null || userId.isEmpty) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.unauthenticated,
      );
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
        regionPreferenceId =
            await regionGateway.resolvePreferenceIdByCode(trimmedRegion);
      } catch (_) {
        // Lookup/network failure: nothing may be written without the canonical
        // id. Map to a retryable failure; prior cloud state is untouched.
        return const ProfileOperationResult.failed(
          ProfileOperationCause.retryableFailure,
        );
      }
      if (regionPreferenceId == null) {
        return const ProfileOperationResult.failed(
          ProfileOperationCause.invalidData,
        );
      }
    }

    final generation = auth.generation;

    // Duplicate-save guard fires BEFORE any remote mutation.
    final current = _authenticatedProfile;
    if (current != null &&
        current.userId == userId &&
        current.roleCode == roleCode &&
        (current.regionPreferenceId ?? '') == (regionPreferenceId ?? '')) {
      return ProfileOperationResult.ok(profile: current, wasNoOp: true);
    }

    try {
      await gateway.saveEditableFields(
        userId: userId,
        roleCode: roleCode,
        regionPreferenceId: regionPreferenceId,
      );
    } on CloudProfilePermissionDeniedException {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.permissionDenied,
      );
    } catch (_) {
      // A failed write preserves the current cloud state; never fabricate
      // success, never navigate.
      return const ProfileOperationResult.failed(
        ProfileOperationCause.retryableFailure,
      );
    }

    // Authoritative re-read — ONLY a successful strict parse under the SAME
    // (userId, generation) may install new state (finding 8 stale suppression).
    if (!auth.isCurrentSession(userId: userId, generation: generation)) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.sessionLost,
      );
    }
    CloudProfile? fresh;
    try {
      fresh = await gateway.fetchByUserId(userId);
    } on CloudProfilePermissionDeniedException {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.permissionDenied,
      );
    } on CloudProfileParseException {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.malformedResponse,
      );
    } catch (_) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.retryableFailure,
      );
    }
    if (!auth.isCurrentSession(userId: userId, generation: generation)) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.sessionLost,
      );
    }
    if (fresh == null) {
      // F7 — the authoritative re-read finds NO canonical row for a session
      // that was supposed to have one: provisioning (create at sign-in) never
      // succeeded. Fail closed with the typed provisioning cause; never
      // fabricate success.
      return const ProfileOperationResult.failed(
        ProfileOperationCause.provisioningFailure,
      );
    }
    if (fresh.userId != userId) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.ownershipConflict,
      );
    }
    final regionCode = await _resolveRegionPreferenceCode(fresh.regionPreferenceId);
    if (!auth.isCurrentSession(userId: userId, generation: generation)) {
      return const ProfileOperationResult.failed(
        ProfileOperationCause.sessionLost,
      );
    }
    _authenticatedProfile = fresh;
    _authenticatedRegionPreferenceCode = regionCode;
    _cloudLoadFailed = false;
    _cloudLoadSettled = true;
    notifyListeners();
    return ProfileOperationResult.ok(profile: fresh);
  }

  /// Clears authenticated cloud state on a canonical identity change. Called
  /// synchronously via the account-bound reset wiring; the auth listener then
  /// reloads for the new identity.
  void resetForIdentityChange() {
    _authenticatedProfile = null;
    _authenticatedRegionPreferenceCode = null;
    _cloudLoadFailed = false;
    _cloudLoadSettled = false;
    _lastWatchedUser = null;
    _lastWatchedGeneration = 0;
    notifyListeners();
  }

  /// Fires for every [AuthProvider] change. On a canonical user/generation
  /// change the authenticated cloud profile is dropped and re-read for the new
  /// identity; sign-out drops it entirely (the local profile remains, guest
  /// authority only).
  void _handleAuthChanged() {
    final auth = _auth;
    if (auth == null) return;
    final authenticated = auth.isLoggedIn;
    final userId = authenticated ? auth.currentUserId : null;
    final generation = auth.generation;

    if (!authenticated) {
      if (_authenticatedProfile != null || _cloudLoadFailed) {
        _authenticatedProfile = null;
        _authenticatedRegionPreferenceCode = null;
        _cloudLoadFailed = false;
        notifyListeners();
      }
      _cloudLoadSettled = false;
      _lastWatchedUser = null;
      _lastWatchedGeneration = 0;
      return;
    }

    if (userId == null) return;
    if (_lastWatchedUser == userId && _lastWatchedGeneration == generation) {
      return;
    }
    _authenticatedProfile = null;
    _authenticatedRegionPreferenceCode = null;
    _cloudLoadFailed = false;
    _cloudLoadSettled = false;
    _lastWatchedUser = userId;
    _lastWatchedGeneration = generation;
    notifyListeners();
    unawaited(ensureCloudProfileLoaded());
  }

  @override
  void dispose() {
    _auth?.removeListener(_handleAuthChanged);
    super.dispose();
  }
}