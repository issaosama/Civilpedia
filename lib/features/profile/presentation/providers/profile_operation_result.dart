import '../../data/cloud_profile.dart' as profile_data;

/// V1-R08 (finding 13) — typed failure cause for cloud profile operations.
///
/// The provider NEVER exposes raw backend exception text; every failed
/// operation degrades to one of these machine-readable causes so the UI can
/// present a localized, recoverable message.
enum ProfileOperationCause {
  /// No authenticated session; nothing was attempted.
  unauthenticated,

  /// The session/identity changed while the operation was in flight; the
  /// result was intentionally NOT published (generation-gated stale result).
  sessionLost,

  /// The backend denied the mutation/read (RLS). Fail closed — no local change,
  /// no fabrication.
  permissionDenied,

  /// F7 — the authenticated profile could not be provisioned (no
  /// `public.profiles` row for the session and the bootstrap seam failed).
  /// Distinct from [malformedResponse] (schema contract) and
  /// [permissionDenied] (RLS); only a genuine provisioning failure maps here.
  /// Raw backend messages are never surfaced.
  provisioningFailure,

  /// The supplied role/region value is not one of the canonical frozen values.
  invalidData,

  /// The authoritative cloud row violated the strict schema contract and could
  /// not be parsed.
  malformedResponse,

  /// A transient network/backend failure; safe to retry.
  retryableFailure,

  /// The re-read row belongs to a different user than the active session.
  ownershipConflict,

  /// Anything else — details are swallowed, a generic failure is surfaced.
  unexpected,
}

/// V1-R08 (findings 13/14) — observable result of an authenticated cloud
/// profile mutation (save). Successful results carry the authoritative
/// re-read [profile]; failures carry a [cause] and leave prior cloud state
/// untouched.
class ProfileOperationResult {
  const ProfileOperationResult._({
    required this.succeeded,
    required this.cause,
    this.profile,
    this.wasNoOp = false,
  });

  /// A completed operation that installed the authoritative re-read.
  const ProfileOperationResult.ok({
    profile_data.CloudProfile? profile,
    bool wasNoOp = false,
  }) : this._(
          succeeded: true,
          cause: null,
          profile: profile,
          wasNoOp: wasNoOp,
        );

  /// A failed operation. Failures never mutate cloud state and never navigate.
  const ProfileOperationResult.failed(ProfileOperationCause cause)
      : this._(
          succeeded: false,
          cause: cause,
          profile: null,
        );

  final bool succeeded;
  final ProfileOperationCause? cause;
  final profile_data.CloudProfile? profile;

  /// True when the save was a no-op duplicate of the current authoritative
  /// values (nothing was written to the backend, nothing changed locally).
  final bool wasNoOp;
}