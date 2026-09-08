import '../../../core/location/baghdad_area.dart';
import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';
import 'cloud_profile.dart';
import 'personal_profile_remote_gateway.dart';
import 'profile_bootstrap_outcome.dart';

/// A5.6 — Coordinates safe cloud ownership/bootstrap for the user's PERSONAL
/// profile after a REAL authenticated Supabase session.
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
/// * Region is fail-closed: equality between the local [BaghdadArea] enum and
///   a cloud `preferred_region_id` UUID cannot be proven in A5.6 (regions are
///   not seeded and no enum → region mapping contract exists). When BOTH sides
///   carry a meaningful region, compatibility is NOT assumed → conflict. A
///   region on only one side never blocks association (the other side is
///   preserved untouched; nothing is written to cloud).
/// * Every failure leaves local data untouched and the local binding unmarked;
///   the next authenticated session retries safely. The DB
///   `user_id` primary key is the final duplicate defense (insert-race is
///   caught, re-read, and re-evaluated as an existing-cloud case).
///
/// Ordering contract: A5.5 record ownership runs first on the same
/// authenticated seam; A5.6 profile bootstrap is fire-and-forget after it and
/// never blocks or is blocked by it.
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
  /// Region exemption: when the region is present on only ONE side, that side
  /// is preserved without a write — CASE 1 (local region, cloud NULL) keeps
  /// the local region local; CASE 2 (cloud region, no local region) keeps the
  /// cloud region. When BOTH sides carry a meaningful region, equality is
  /// UNPROVABLE in A5.6, so this MUST yield a conflict even if every other
  /// field matches.
  bool _detectConflict(LocalUserProfile local, CloudProfile cloud) {
    final localRole = civilUserTypeToRoleCode(local.userType);
    final cloudRole = _meaningful(cloud.roleCode);
    if (cloudRole != null && cloudRole != localRole) return true;

    final localName = _meaningful(local.name);
    final cloudName = _meaningful(cloud.displayName);
    if (localName != null && cloudName != null && cloudName != localName) {
      return true;
    }

    final hasLocalRegion = local.baghdadArea != BaghdadArea.unknown;
    final hasCloudRegion = _meaningful(cloud.preferredRegionId) != null;
    if (hasLocalRegion && hasCloudRegion) return true;

    return false;
  }

  /// Builds the initial cloud profile from known-safe local/auth values only.
  ///
  /// Notable audit decisions:
  /// * `preferred_region_id` is deliberately OMITTED: the local [BaghdadArea]
  ///   enum has no established mapping to `regions.id` UUIDs (regions are not
  ///   seeded) — inventing a UUID or guessing a region code is forbidden.
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