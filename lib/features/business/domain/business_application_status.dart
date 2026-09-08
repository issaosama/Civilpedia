/// A6.2 — Canonical business application lifecycle status
/// (`public.business_applications` `status` column, migration 00007).
///
/// All nine CHECK-constrained storage codes are surfaced here. Unknown codes
/// resolve to [unknown] and carry NO applicant capability.
///
/// Applicant-facing read model: Flutter may READ every status, but none of the
/// privileged transitions (review, approval, rejection, contact, visit,
/// activation) may originate from the client. Sensitive transitions are
/// server-authorized future work.
enum BusinessApplicationStatus {
  draft,
  submitted,
  underReview,
  needsCorrection,
  contacted,
  visitScheduled,
  approved,
  rejected,
  activated,
  unknown;

  /// The exact database/storage spelling for this status.
  String get code {
    switch (this) {
      case BusinessApplicationStatus.draft:
        return 'DRAFT';
      case BusinessApplicationStatus.submitted:
        return 'SUBMITTED';
      case BusinessApplicationStatus.underReview:
        return 'UNDER_REVIEW';
      case BusinessApplicationStatus.needsCorrection:
        return 'NEEDS_CORRECTION';
      case BusinessApplicationStatus.contacted:
        return 'CONTACTED';
      case BusinessApplicationStatus.visitScheduled:
        return 'VISIT_SCHEDULED';
      case BusinessApplicationStatus.approved:
        return 'APPROVED';
      case BusinessApplicationStatus.rejected:
        return 'REJECTED';
      case BusinessApplicationStatus.activated:
        return 'ACTIVATED';
      case BusinessApplicationStatus.unknown:
        return 'UNKNOWN';
    }
  }

  /// Whether this is a recognized stored status (not [unknown]).
  bool get isKnown => this != BusinessApplicationStatus.unknown;

  /// Whether the lifecycle has reached a terminal conclusion for the
  /// applicant: [rejected] (unless future product explicitly reopens) or
  /// [activated] (terminal). Anything else is not final (e.g. APPROVED still
  /// awaits activation).
  bool get isFinal =>
      this == BusinessApplicationStatus.rejected ||
      this == BusinessApplicationStatus.activated;

  /// Whether the application is still "live" for the applicant — not final.
  /// Used for duplicate-claim detection and pending-state reasoning.
  bool get isLive => !isFinal;

  /// Parses a raw storage code into a [BusinessApplicationStatus].
  ///
  /// Case-sensitive to match the exact DB CHECK values. Anything unrecognized
  /// → [unknown] (fail closed, no elevated applicant capability).
  static BusinessApplicationStatus fromCode(String? code) {
    switch (code) {
      case 'DRAFT':
        return BusinessApplicationStatus.draft;
      case 'SUBMITTED':
        return BusinessApplicationStatus.submitted;
      case 'UNDER_REVIEW':
        return BusinessApplicationStatus.underReview;
      case 'NEEDS_CORRECTION':
        return BusinessApplicationStatus.needsCorrection;
      case 'CONTACTED':
        return BusinessApplicationStatus.contacted;
      case 'VISIT_SCHEDULED':
        return BusinessApplicationStatus.visitScheduled;
      case 'APPROVED':
        return BusinessApplicationStatus.approved;
      case 'REJECTED':
        return BusinessApplicationStatus.rejected;
      case 'ACTIVATED':
        return BusinessApplicationStatus.activated;
      default:
        return BusinessApplicationStatus.unknown;
    }
  }
}