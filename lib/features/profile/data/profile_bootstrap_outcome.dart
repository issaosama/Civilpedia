/// A5.6 — Result of a personal profile cloud-ownership bootstrap run.
///
/// Every outcome is non-destructive by contract:
/// * cloud/local data is preserved,
/// * a binding is only ever persisted after a successful remote read/create,
/// * a different-user local binding never changes silently.
enum ProfileBootstrapOutcome {
  /// No authenticated session was supplied → no cloud operation is performed.
  skippedGuest,

  /// Bootstrap completed: either a missing cloud profile was created, or an
  /// existing cloud profile was compatible with the local values. The local
  /// profile is now bound to the canonical `auth.users.id`.
  associated,

  /// The local profile was already bound to a DIFFERENT authenticated user.
  /// Fail-closed: no rebind, no overwrite, no remote mutation.
  differentUserBlocked,

  /// An existing cloud profile holds meaningful values that differ from the
  /// current device's local values. BOTH sides are preserved unchanged; the
  /// local profile is NOT bound yet. Resolution requires a future explicit
  /// profile-sync/conflict UX.
  profileConflict,

  /// A read, create, or local-write step failed (e.g. offline). Sign-in
  /// remains successful, local data is untouched, the local binding is NOT
  /// falsely marked complete, and a later authenticated session retries safely.
  failure,

  /// F7 — a canonical `public.profiles` row for the authenticated session
  /// could NOT be provisioned for a provisioning-specific reason (constraint /
  /// data rejection on INSERT). Sign-in remains successful; the typed state is
  /// surfaced to the profile/provider boundary so the UI can present a
  /// provisioning-specific recovery path. Distinct from [failure] (transient).
  provisioningFailure,
}