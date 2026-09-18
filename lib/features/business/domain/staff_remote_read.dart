/// P2-E1 — Sanitized failure kinds for authenticated Staff remote reads.
///
/// `offline` is deliberately absent. The data boundary can prove only a
/// transport failure; P2-E2 may promote [network] to an offline presentation
/// after consulting the canonical connectivity authority.
enum StaffRemoteReadFailureKind {
  network,
  timeout,
  serviceUnavailable,
  malformedResponse,
  permissionDenied,
  authRestricted,
  unexpected,
}

/// Publication lifecycle for each independent Staff read lane.
///
/// Authoritative absence is not a failure. Queue reads use
/// [authoritativeEmpty], while detail reads may use [authoritativeNotFound].
enum StaffRemoteReadPhase {
  idle,
  loading,
  refreshing,
  loaded,
  authoritativeEmpty,
  authoritativeNotFound,
  failed,
}
