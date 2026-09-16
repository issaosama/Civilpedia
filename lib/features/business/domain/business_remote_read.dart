/// P2-D1 — Sanitized failure kinds for authenticated Business remote reads.
///
/// `offline` is deliberately absent. A gateway can prove only that its
/// request encountered a transport failure; P2-D2 may present that as offline
/// after consulting the canonical connectivity state.
enum BusinessRemoteReadFailureKind {
  network,
  timeout,
  serviceUnavailable,
  malformedResponse,
  permissionDenied,
  authRestricted,
  unexpected,
}

/// Read lifecycle shared by the Business providers.
///
/// Authoritative absence is not a failure. List reads normally use
/// [authoritativeEmpty], while resource reads may use
/// [authoritativeNotFound].
enum BusinessRemoteReadPhase {
  idle,
  loading,
  refreshing,
  loaded,
  authoritativeEmpty,
  authoritativeNotFound,
  failed,
}

/// Typed boundary exception for Business gateways whose existing API returns
/// a value directly. It contains no backend message, code, hint, or stack.
class BusinessRemoteReadException implements Exception {
  const BusinessRemoteReadException(this.kind);

  final BusinessRemoteReadFailureKind kind;
}
