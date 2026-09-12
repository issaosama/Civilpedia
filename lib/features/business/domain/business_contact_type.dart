/// V1-R06 — Canonical Directory business contact type (value object).
///
/// Mirrors the exact inline text codes enforced by the frozen server mutation
/// contract (migration 00020): `phone`, `whatsapp`, `email`, `website`,
/// `other`. These are the ONLY five types a business profile may carry.
///
/// An unknown/unsupported code deliberately resolves to [unknown] which has NO
/// storage spelling and carries no writable meaning (fail closed). This keeps
/// type handling centralized and prevents raw string comparisons from leaking
/// into the management UI.
enum BusinessContactType {
  phone,
  whatsapp,
  email,
  website,
  other,
  unknown;

  /// The exact server/storage spelling for this type.
  ///
  /// Only the five frozen codes are valid storage values; [unknown] has no
  /// storage spelling.
  String get code {
    switch (this) {
      case BusinessContactType.phone:
        return 'phone';
      case BusinessContactType.whatsapp:
        return 'whatsapp';
      case BusinessContactType.email:
        return 'email';
      case BusinessContactType.website:
        return 'website';
      case BusinessContactType.other:
        return 'other';
      case BusinessContactType.unknown:
        return 'unknown';
    }
  }

  /// Whether this is one of the five frozen storage types (not [unknown]).
  bool get isKnown => this != BusinessContactType.unknown;

  /// Parses a raw storage code into a [BusinessContactType].
  ///
  /// Case-insensitive to tolerate lower-cased server storage, matching the
  /// server's `lower(trim(...))` normalization. Anything else resolves to
  /// [unknown] (fail closed, no writable meaning).
  static BusinessContactType fromCode(String? code) {
    switch (code?.trim().toLowerCase()) {
      case 'phone':
        return BusinessContactType.phone;
      case 'whatsapp':
        return BusinessContactType.whatsapp;
      case 'email':
        return BusinessContactType.email;
      case 'website':
        return BusinessContactType.website;
      case 'other':
        return BusinessContactType.other;
      default:
        return BusinessContactType.unknown;
    }
  }
}