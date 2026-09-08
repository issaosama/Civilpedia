/// A6.2 — Canonical business application type (`public.business_applications`
/// `application_type` column, migration 00007).
///
/// The two CHECK-constrained storage codes are `NEW` (create a new Directory
/// entity) and `CLAIM` (claim an existing Directory entity). An unrecognized
/// code resolves to [unknown] — never a fabricated valid type.
enum BusinessApplicationType {
  newApplication,
  claim,
  unknown;

  /// The exact database/storage spelling for this type. [unknown] has no valid
  /// storage spelling.
  String get code {
    switch (this) {
      case BusinessApplicationType.newApplication:
        return 'NEW';
      case BusinessApplicationType.claim:
        return 'CLAIM';
      case BusinessApplicationType.unknown:
        return 'UNKNOWN';
    }
  }

  /// Whether this is a recognized stored type (not [unknown]).
  bool get isKnown => this != BusinessApplicationType.unknown;

  /// Parses a raw storage code. Anything outside `NEW`/`CLAIM` → [unknown]
  /// (fail closed).
  static BusinessApplicationType fromCode(String? code) {
    switch (code) {
      case 'NEW':
        return BusinessApplicationType.newApplication;
      case 'CLAIM':
        return BusinessApplicationType.claim;
      default:
        return BusinessApplicationType.unknown;
    }
  }
}