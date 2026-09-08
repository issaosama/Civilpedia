import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';
import 'cloud_profile.dart';
import 'personal_profile_remote_gateway.dart';
import 'profile_bootstrap_outcome.dart';
import 'region_preference.dart';
import 'region_preference_gateway.dart';

/// A5.6/A5.7/A5.8 — Coordinates safe cloud ownership/bootstrap for the user's
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
///   mapped to one.
/// * Cloud region values: the legacy `preferred_region_id` is PRESERVED
///   untouched — this bootstrap never reads, writes, or compares it.
///
/// A5.8 REGION PREFERENCE WIRING (first-launch model):
/// * The local profile now carries a stable `regionPreferenceCode` (one of the
///   frozen `IQ_PREF_*` codes) selected during first-launch setup.
/// * Local code → canonical `region_preferences.id` is resolved EXCLUSIVELY via
///   [RegionPreferenceGateway]; a UUID is never invented or hardcoded.
/// * FAIL-CLOSED LOOKUP: when the local preference is meaningful
///   (`regionPreferenceCode` present and known) and its canonical id cannot be
///   resolved (lookup/network failure), the bootstrap returns a RETRYABLE
///   `failure` outcome. No cloud row is created, no local binding persisted,
///   no association performed, and no cloud data is updated — the existing
///   cloud profile, if any, may already carry a DIFFERENT preference, so
///   association cannot be proven safe until the canonical id is resolved.
///   Authentication itself stays successful; the next authenticated session
///   retries the whole bootstrap.
/// * CREATE: when resolution succeeds, the new cloud row receives
///   `region_preference_id`; the local binding is persisted only after the
///   remote create is confirmed.
/// * EXISTING cloud profile:
///     - same resolved preference → compatible → associate.
///     - cloud `region_preference_id` NULL + local preference → conditional
///       single-column safe fill (never touches other cloud columns), then
///       bind after a safe result.
///     - cloud preference present AND differs → `profileConflict`. Never
///       overwritten silently.
///     - local preference NULL + cloud preference present → associate and
///       preserve the cloud preference (no push, no unset, no lookup needed).
///
/// * Every failure leaves local data untouched and the local binding unmarked;
///   the next authenticated session retries safely. The DB `user_id` primary
///   key is the final duplicate defense (insert-race is caught, re-read, and
///   re-evaluated as an existing-cloud case).
///
/// Ordering contract: A5.5 record ownership runs first on the same
/// authenticated seam; A5.6/A5.7/A5.8 profile bootstrap is fire-and-forget
/// after it and never blocks or is blocked by it.
class PersonalProfileBootstrapCoordinator {
  PersonalProfileBootstrapCoordinator({
    required UserProfileRepository localRepository,
    required PersonalProfileRemoteGateway remoteGateway,
    required RegionPreferenceGateway regionPreferenceGateway,
  }) : _localRepository = localRepository,
       _remoteGateway = remoteGateway,
       _regionPreferenceGateway = regionPreferenceGateway;

  final UserProfileRepository _localRepository;
  final PersonalProfileRemoteGateway _remoteGateway;
  final RegionPreferenceGateway _regionPreferenceGateway;

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
      // CASE A — create using only known-safe mapped values. A5.8: resolve a
      // stable local preference code to its canonical id when possible. On
      // lookup/network failure the field is safely omitted — authentication
      // stays successful, local data is untouched, and a later session retries.
      // A5.8 FAIL-CLOSED CASE A: the local preference is meaningful and its
      // canonical id must be proven BEFORE any remote write. On lookup/network
      // failure return a retryable failure: NO cloud row is created, NO local
      // binding is persisted, and no data is mutated. Authentication itself
      // stays successful; the next authenticated session retries.
      String? regionPreferenceId;
      if (_hasPreference(local)) {
        try {
          regionPreferenceId = await _regionPreferenceGateway
              .resolvePreferenceIdByCode(local.regionPreferenceCode!);
        } catch (_) {
          return ProfileBootstrapOutcome.failure;
        }
      }
      final toCreate = _buildCloudProfile(
        local: local,
        userId: userId,
        authDisplayName: authDisplayName,
        authPhotoUrl: authPhotoUrl,
        regionPreferenceId: regionPreferenceId,
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
    // A5.8 FAIL-CLOSED Region Preference association: when the local
    // preference is meaningful, its canonical id MUST be resolved before any
    // compare/fill/associate can be proven safe (an existing cloud profile may
    // already carry a different preference). On lookup/network failure return
    // a retryable failure — NO association, NO local binding, NO cloud
    // mutation; retried on a later authenticated session.
    String? localPreferenceId;
    if (_hasPreference(local)) {
      try {
        localPreferenceId = await _regionPreferenceGateway
            .resolvePreferenceIdByCode(local.regionPreferenceCode!);
      } catch (_) {
        return ProfileBootstrapOutcome.failure;
      }
    }
    if (localPreferenceId != null) {
      final cloudPreferenceId = cloud.regionPreferenceId;
      if (cloudPreferenceId == null) {
        // cloud NULL + local preference → conditional single-column safe fill.
        // A failure here never fails the association: the fill is retried on
        // a later session without any local or other cloud mutation.
        try {
          await _remoteGateway.updateRegionPreferenceId(
            userId: userId,
            regionPreferenceId: localPreferenceId,
          );
        } catch (_) {
          // non-fatal; see above.
        }
      } else if (cloudPreferenceId != localPreferenceId) {
        // Different cloud/local preference → preserve BOTH sides and never
        // overwrite silently; local binding is not persisted.
        return ProfileBootstrapOutcome.profileConflict;
      }
    }

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
  /// A5.7/A5.8 — `baghdadArea` (physical Directory locality) is NEVER
  /// compared here. Region Preference comparison happens separately in
  /// `_associateOrConflict` before this role/name check.
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
  /// * `preferred_region_id` is ALWAYS omitted — it is a legacy geographic
  ///   reference, never written by this bootstrap.
  /// * `region_preference_id` is written ONLY from the [regionPreferenceId]
  ///   provided by the caller, which is itself the result of resolving a
  ///   stable local `RegionPreferenceCode` through [RegionPreferenceGateway]
  ///   (A5.8). A UUID is never invented; on resolution failure the caller
  ///   passes null and the column is safely omitted.
  /// * `phone` is deliberately OMITTED: it is not collected by any current
  ///   intentional flow, so persisting it cannot be proven intentionally
  ///   collected.
  CloudProfile _buildCloudProfile({
    required LocalUserProfile local,
    required String userId,
    String? authDisplayName,
    String? authPhotoUrl,
    String? regionPreferenceId,
  }) {
    return CloudProfile(
      userId: userId,
      displayName: _meaningful(local.name) ?? _meaningful(authDisplayName),
      photoUrl: _meaningful(authPhotoUrl),
      roleCode: civilUserTypeToRoleCode(local.userType),
      regionPreferenceId: regionPreferenceId,
    );
  }

  /// True when the local profile carries a known, non-empty stable preference
  /// code from the frozen six-zone contract.
  bool _hasPreference(LocalUserProfile local) {
    final code = local.regionPreferenceCode;
    return code != null &&
        code.trim().isNotEmpty &&
        RegionPreferenceCode.isKnown(code);
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