/// A6.1 — Canonical Directory business membership role (value object).
///
/// Mirrors the exact inline text codes stored in `public.business_memberships`
/// (migration 00006): `OWNER`, `ADMIN`, `MEMBER` (default). These codes are
/// CHECK-constrained in the database and are NOT FK-references to the staff
/// roles table.
///
/// An unknown/unsupported code deliberately resolves to [unknown] which carries
/// NO elevated capability (fail closed). This keeps role handling centralized
/// and prevents spurious role-string comparisons from leaking into features.
enum BusinessRole {
  owner,
  admin,
  member,
  unknown;

  /// The exact database/storage spelling for this role.
  ///
  /// Only the three CHECK-constrained codes are valid storage values;
  /// [unknown] has no storage spelling.
  String get code {
    switch (this) {
      case BusinessRole.owner:
        return 'OWNER';
      case BusinessRole.admin:
        return 'ADMIN';
      case BusinessRole.member:
        return 'MEMBER';
      case BusinessRole.unknown:
        return 'UNKNOWN';
    }
  }

  /// Whether this role is a recognized stored role (not [unknown]).
  bool get isKnown => this != BusinessRole.unknown;

  /// Parses a raw storage code into a [BusinessRole].
  ///
  /// Case-sensitive to match the exact DB CHECK values. Anything not one of
  /// the three valid codes resolves to [unknown] (fail closed, no elevation).
  static BusinessRole fromCode(String? code) {
    switch (code) {
      case 'OWNER':
        return BusinessRole.owner;
      case 'ADMIN':
        return BusinessRole.admin;
      case 'MEMBER':
        return BusinessRole.member;
      default:
        return BusinessRole.unknown;
    }
  }
}
