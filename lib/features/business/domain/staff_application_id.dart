/// V1-R07 — Canonical staff application id validation.
///
/// Staff application ids are Postgres `uuid` values. Deep links must fail safe
/// BEFORE any RPC: a malformed non-UUID segment is routed to the not-found
/// state instead of reaching the detail RPC (finding 14).
abstract final class StaffApplicationId {
  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// True when [value] is a well-formed UUID for the staff detail route.
  static bool isValidUuid(String value) => _uuid.hasMatch(value);
}