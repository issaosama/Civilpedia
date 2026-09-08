import 'business_application_status.dart';

/// A6.2 — Centralized, deterministic applicant-facing capability set for a
/// business application lifecycle status (/domain/UX capability hints).
///
/// These are UX/domain hints ONLY. The server remains authoritative for every
/// sensitive transition — no capability here is, by itself, an authorization
/// to mutate anything.
///
/// Expected semantics per frozen contract:
/// * DRAFT              → editable + may submit (via future server mutation).
/// * SUBMITTED          → read-only to applicant, pending.
/// * UNDER_REVIEW       → read-only to applicant, pending.
/// * NEEDS_CORRECTION   → may correct/resubmit through a future explicit
///                        mutation contract; NO direct insecure UPDATE path.
/// * CONTACTED          → read-only, pending.
/// * VISIT_SCHEDULED    → read-only, pending.
/// * APPROVED           → read-only; approval does NOT equal activation and
///                        does NOT grant ownership.
/// * REJECTED           → read-only (final unless future product reopens).
/// * ACTIVATED          → terminal from the applicant perspective.
/// * UNKNOWN            → fail closed: no capability of any kind.
class BusinessApplicationCapabilities {
  const BusinessApplicationCapabilities._({required this.status});

  /// The source status every capability is derived from.
  final BusinessApplicationStatus status;

  /// May edit the application content (DRAFT / NEEDS_CORRECTION). The actual
  /// edit/resubmit write is a future server-authorized mutation, not a client
  /// UPDATE.
  bool get canEdit =>
      status == BusinessApplicationStatus.draft ||
      status == BusinessApplicationStatus.needsCorrection;

  /// May submit the application for review (DRAFT / NEEDS_CORRECTION).
  /// Presentation of the submission action is driven by this flag; the
  /// transition itself is server-authorized.
  bool get canSubmit =>
      status == BusinessApplicationStatus.draft ||
      status == BusinessApplicationStatus.needsCorrection;

  /// May resubmit the corrected application (NEEDS_CORRECTION only).
  bool get canResubmit => status == BusinessApplicationStatus.needsCorrection;

  /// The application is in-flight awaiting review/contact/visit.
  bool get isPending =>
      status == BusinessApplicationStatus.submitted ||
      status == BusinessApplicationStatus.underReview ||
      status == BusinessApplicationStatus.contacted ||
      status == BusinessApplicationStatus.visitScheduled;

  /// The lifecycle is terminal for the applicant (REJECTED / ACTIVATED).
  bool get isFinal => status.isFinal;

  /// The reviewer asked for corrections (NEEDS_CORRECTION only).
  bool get requiresCorrection =>
      status == BusinessApplicationStatus.needsCorrection;

  /// Whether the status is DRAFT.
  bool get isDraft => status == BusinessApplicationStatus.draft;

  /// Whether the status is APPROVED. Approval does NOT equal activation and
  /// does NOT grant ownership.
  bool get isApproved => status == BusinessApplicationStatus.approved;

  /// Whether the status is REJECTED (terminal; grants no ownership).
  bool get isRejected => status == BusinessApplicationStatus.rejected;

  /// Whether the status is ACTIVATED (terminal applicant state; ownership is a
  /// separate, membership-driven concern).
  bool get isActivated => status == BusinessApplicationStatus.activated;

  /// Unknown statuses fail closed to a capability-less set.
  bool get isUnknown => status == BusinessApplicationStatus.unknown;

  /// The canonical fail-closed capability set for [status].
  factory BusinessApplicationCapabilities.forStatus(
    BusinessApplicationStatus status,
  ) {
    return BusinessApplicationCapabilities._(status: status);
  }
}