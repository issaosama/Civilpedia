import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';
import 'cloud_profile.dart';
import 'personal_profile_remote_gateway.dart';
import 'profile_bootstrap_outcome.dart';

/// A5.6/A5.7 — Coordinates safe cloud ownership/bootstrap for the user's
/// PERSONAL profile after a REAL authenticated Supabase session.
///
/// Contracts enforced here (all fail-closed):
/// * Canonical identity is ALWAYS `profiles.user_id == auth.users.id`.
/// * A local profile already bound to a different user is never rebound and
///   never triggers any remote mutation.
/// * A missing cloud profile is created ONLY from known-safe, mapped values;
///   missing/unmappable values are omitted, never invented.
/// * An existing cloud profile is never blind-upserted over with local values.
///   Equal/compatible → local association. Meaningful differences → both sides
///   preserved and a `profileConflict` outcome returned (no conflict UI yet).
///
/// A5.7 REGION PREFERENCE ≠ BAGHDAD DIRECTORY AREA (architect correction):
/// * Region Preference is the SIX frozen user/market zones (Baghdad-Karkh,
///   Baghdad-Rusafa, North, Central, South, All Iraq) in `region_preferences`
///   (migration 00013).
/// * The local `baghdadArea` field is a PHYSICAL, Directory-only locality
///   (legacy/local representation) — it is NOT a Region Preference and is never
///   mapped to one. There is currently NO local preference model at all, so
///   this bootstrap NEVER writes, fills, or invents any cloud region
///   preference, and NEVER conflicts on region fields.
/// * Cloud region values (legacy `preferred_region_id` and the new
///   `region_preference_id`) are PRESERVED untouched — the bootstrap performs
///   no region UPDATE and omits region columns from CREATE. This is documented
///   migration debt: persisting a real preference requires a corrected local
///   onboarding preference model (UI/onboarding is out of A5.7 scope).
/// * Association is therefore never blocked by legacy local/geographic region
///   values; authentication is never blocked, and no region value is invented.
///
/// * Every failure leaves local data untouched and the local binding unmarked;
///   the next authenticated session retries safely. The DB `user_id` primary
///   key is the final duplicate defense (insert-race is caught, re-read, and
///   re-evaluated as an existing-cloud case).
///
/// Ordering contract: A5.5 record ownership runs first on the same
/// authenticated seam; A5.6/A5.7 profile bootstrap is fire-and-forget after it
/// and never blocks or is blocked by it.
class PersonalProfileBootstrapCoordinator {
  PersonalProfileBootstrapCoordinator({
    required UserProfileRepository localRepository,
    required PersonalProfileRemoteGateway remoteGateway,
  }) : _localRepository = localRepository,
       _remoteGateway = remoteGateway;

  final UserProfileRepository _localRepository;
  final PersonalProfileRemoteGateway _remoteGateway;

  Future<ProfileBootstrapOutcome>? _inFlight;

  /// Runs the bootstrap for the authenticated [userId]. Concurrent calls
  /// coalesce onto the same run; a running bootstrap is never re-entered.
  Future<ProfileBootstrapOutcome> bootstrap({
    required String userId,
    String? authDisplayName,
    String? authPhotoUrl,
  }) {
    if (userId.trim().isEmpty) {
      return Future.value(ProfileBootstrapOutcome.skippedGuest);
    }
    final pending = _inFlight;
    if (pending != null) return pending;
    final run = _bootstrap(
      userId: userId,
      authDisplayName: authDisplayName,
      authPhotoUrl: authPhotoUrl,
    ).whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<ProfileBootstrapOutcome> _bootstrap({
    required String userId,
    String? authDisplayName,
    String? authPhotoUrl,
  }) async {
    // 1. Read local profile safely.
    final LocalUserProfile? local;
    try {
      local = await _localRepository.loadProfile();
    } catch (_) {
      // Cannot read local state → cannot prove safety → treat as retryable.
      return ProfileBootstrapOutcome.failure;
    }
    if (local == null) {
      // Nothing to associate yet (guest-first: profile setup may be skipped).
      return ProfileBootstrapOutcome.noLocalProfile;
    }

    // 2. Validate local account binding (fail closed).
    final boundUserId = local.futureCloudUserId;
    if (boundUserId != null && boundUserId.isNotEmpty && boundUserId != userId) {
      // Never silently change User A's binding to User B, never mutate remote.
      return ProfileBootstrapOutcome.differentUserBlocked;
    }

    // 3. Read the cloud profile.
    CloudProfile? cloud;
    try {
      cloud = await _remoteGateway.fetchByUserId(userId);
    } catch (_) {
      // Offline/read failure → local untouched, binding not falsely persisted.
      return ProfileBootstrapOutcome.failure;
    }

    if (cloud == null) {
      // CASE A — create using only known-safe mapped values.
      final toCreate = _buildCloudProfile(
        local: local,
        userId: userId,
        authDisplayName: authDisplayName,
        authPhotoUrl: authPhotoUrl,
      );
      try {
        await _remoteGateway.createProfile(toCreate);
      } on CloudProfileAlreadyExistsException {
        // Insert-race: another client created the row. Re-read and evaluate
        // as CASE B instead of failing or double-inserting.
        try {
          cloud = await _remoteGateway.fetchByUserId(userId);
        } catch (_) {
          return ProfileBootstrapOutcome.failure;
        }
        if (cloud == null) {
          return ProfileBootstrapOutcome.failure;
        }
        return _associateOrConflict(local: local, cloud: cloud, userId: userId);
      } catch (_) {
        // Remote insert failure → local untouched, binding not persisted.
        return ProfileBootstrapOutcome.failure;
      }

      // Remote creation confirmed → now (and only now) persist local binding.
      final bound = await _persistLocalBinding(local, userId);
      return bound ? ProfileBootstrapOutcome.associated
                   : ProfileBootstrapOutcome.failure;
    }

    // CASE B — existing cloud profile.
    return _associateOrConflict(local: local, cloud: cloud, userId: userId);
  }

  Future<ProfileBootstrapOutcome> _associateOrConflict({
    required LocalUserProfile local,
    required CloudProfile cloud,
    required String userId,
  }) async {
    final conflict = _detectConflict(local, cloud);
    if (conflict) {
      // Preserve BOTH sides. The device local profile stays unchanged; the
      // remote profile stays unchanged; no winner is silently chosen.
      return ProfileBootstrapOutcome.profileConflict;
    }

    // Compatible/equal → associate local profile with the canonical user id.
    final bound = await _persistLocalBinding(local, userId);
    return bound ? ProfileBootstrapOutcome.associated
                 : ProfileBootstrapOutcome.failure;
  }

  /// Field-by-field comparison of the values A5.6 can map meaningfully.
  /// A field only conflicts when BOTH sides hold meaningful, different values;
  /// a genuinely-missing side never destroys information (no silent fills).
  ///
  /// A5.7 — region fields are EXCLUDED from conflict and from writes entirely:
  /// the local `baghdadArea` is physical/Directory-only (not a preference) and
  /// there is no local preference model to compare — legacy/geographic values
  /// never block association and are preserved untouched (no invention, no
  /// silent overwrite).
  bool _detectConflict(LocalUserProfile local, CloudProfile cloud) {
    final localRole = civilUserTypeToRoleCode(local.userType);
    final cloudRole = _meaningful(cloud.roleCode);
    if (cloudRole != null && cloudRole != localRole) return true;

    final localName = _meaningful(local.name);
    final cloudName = _meaningful(cloud.displayName);
    if (localName != null && cloudName != null && cloudName != localName) {
      return true;
    }

    return false;
  }

  /// Builds the initial cloud profile from known-safe local/auth values only.
  ///
  /// Notable audit decisions:
  /// * All region columns are deliberately OMITTED — `preferred_region_id` is
  ///   a legacy geographic reference and no local Region Preference exists in
  ///   A5.7, so persisting either column cannot be proven intentional; a
  ///   UUID/code is never invented. Cloud region preference data stays unset.
  /// * `phone` is deliberately OMITTED: it is not collected by any current
  ///   intentional flow, so persisting it cannot be proven intentionally
  ///   collected.
  CloudProfile _buildCloudProfile({
    required LocalUserProfile local,
    required String userId,
    String? authDisplayName,
    String? authPhotoUrl,
  }) {
    return CloudProfile(
      userId: userId,
      displayName: _meaningful(local.name) ?? _meaningful(authDisplayName),
      photoUrl: _meaningful(authPhotoUrl),
      roleCode: civilUserTypeToRoleCode(local.userType),
    );
  }

  Future<bool> _persistLocalBinding(
    LocalUserProfile local,
    String userId,
  ) async {
    if (local.futureCloudUserId == userId) return true; // Already bound.
    final updated = local.copyWith(
      futureCloudUserId: userId,
      updatedAt: DateTime.now(),
    );
    try {
      await _localRepository.saveProfile(updated);
      return true;
    } catch (_) {
      // Local write failed → binding must NOT be falsely marked complete.
      return false;
    }
  }

  static String? _meaningful(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}