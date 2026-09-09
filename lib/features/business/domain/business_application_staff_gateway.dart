import 'business_application.dart';

/// A6.3 — Outcome of a staff business-application mutation attempt.
sealed class BusinessApplicationStaffResult {
  const BusinessApplicationStaffResult();
}

/// The staff mutation succeeded; [application] is the authoritative updated row.
class BusinessApplicationStaffSucceeded extends BusinessApplicationStaffResult {
  const BusinessApplicationStaffSucceeded(this.application);

  final BusinessApplication application;
}

/// The staff mutation was denied for a typed, server-authoritative reason. No
/// row transition occurred and no side effects happened.
class BusinessApplicationStaffDenied extends BusinessApplicationStaffResult {
  const BusinessApplicationStaffDenied(this.cause);

  final BusinessApplicationStaffCause cause;
}

/// A6.3 — Typed staff denial causes mirroring the staff custom SQLSTATE
/// contract of migration 00016. Values are the mapping layer between raw
/// server errors and the application; raw error text is never surfaced.
enum BusinessApplicationStaffCause {
  /// P0AUT — no authenticated session.
  unauthenticated,

  /// P0PER — the caller holds no active staff_memberships (or the role lacks
  /// the required permission). Identity is always derived server-side from
  /// auth.uid(); the client can never supply it.
  staffPermissionDenied,

  /// P0NOT — the application row does not exist.
  applicationNotFound,

  /// P0TRA — the current status does not allow this operation.
  invalidTransition,

  /// P0COR — a correction requires a non-empty reason.
  correctionReasonRequired,

  /// P0REJ — a rejection requires a non-empty reason.
  rejectionReasonRequired,

  /// P0DAT — required staff record data is missing/invalid (e.g. contact type
  /// or scheduled visit time).
  requiredDataMissing,

  /// Any unclassified server failure. Carries no raw SQL/error text.
  unexpected;

  /// Maps a PostgREST error code to the typed cause; unknown codes fail closed
  /// to [unexpected].
  static BusinessApplicationStaffCause fromServerCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'P0AUT':
        return BusinessApplicationStaffCause.unauthenticated;
      case 'P0PER':
        return BusinessApplicationStaffCause.staffPermissionDenied;
      case 'P0NOT':
        return BusinessApplicationStaffCause.applicationNotFound;
      case 'P0TRA':
        return BusinessApplicationStaffCause.invalidTransition;
      case 'P0COR':
        return BusinessApplicationStaffCause.correctionReasonRequired;
      case 'P0REJ':
        return BusinessApplicationStaffCause.rejectionReasonRequired;
      case 'P0DAT':
        return BusinessApplicationStaffCause.requiredDataMissing;
      default:
        return BusinessApplicationStaffCause.unexpected;
    }
  }
}

/// A6.3 — Server-authorized staff boundary to `public.business_applications`.
///
/// Every operation is a SECURITY DEFINER RPC (migration 00016) that derives
/// the actor exclusively from `auth.uid()` and requires a matching permission
/// through `staff_memberships` → `role_permissions` → `permissions.code`.
/// The methods deliberately accept NO user/role/email: staff identity cannot
/// be injected by the caller.
///
/// No method here performs ownership side effects:
///   * approval is a decision, NOT activation (APPROVED awaits A6.4 atomic
///     entity/membership provisioning);
///   * nothing creates a business_memberships row, never writes
///     directory_entities.claim_status / verification_status.
///
/// Transition matrix (server-enforced, acyclic):
///   beginReview: SUBMITTED → UNDER_REVIEW
///   returnForCorrection: UNDER_REVIEW → NEEDS_CORRECTION (reason required)
///   markContacted: UNDER_REVIEW → CONTACTED (+ application_contacts record)
///   scheduleVisit: UNDER_REVIEW → VISIT_SCHEDULED (+ application_visits record)
///   approve: UNDER_REVIEW / CONTACTED / VISIT_SCHEDULED → APPROVED
///   reject:  UNDER_REVIEW / CONTACTED / VISIT_SCHEDULED → REJECTED (reason required)
/// Status changes each write an audit record in the same transaction.
abstract class BusinessApplicationStaffGateway {
  /// Whether the backend is initialized for staff RPC calls.
  bool get isAvailable;

  /// SUBMITTED → UNDER_REVIEW. Requires `business_applications.review`.
  Future<BusinessApplicationStaffResult> beginReview(String applicationId);

  /// UNDER_REVIEW → NEEDS_CORRECTION. Requires
  /// `business_applications.return_for_correction`.
  Future<BusinessApplicationStaffResult> returnForCorrection(
    String applicationId, {
    required String reason,
  });

  /// UNDER_REVIEW → CONTACTED and inserts an `application_contacts` record.
  /// Requires `business_applications.mark_contacted`. [contactType] is one of
  /// `phone`, `whatsapp`, `email`, `visit`, `other`.
  Future<BusinessApplicationStaffResult> markContacted(
    String applicationId, {
    required String contactType,
    String? result,
    String? notes,
  });

  /// UNDER_REVIEW → VISIT_SCHEDULED and inserts an `application_visits`
  /// record. Requires `business_applications.schedule_visit`.
  Future<BusinessApplicationStaffResult> scheduleVisit(
    String applicationId, {
    required DateTime scheduledAt,
    String? location,
    String? notes,
  });

  /// UNDER_REVIEW / CONTACTED / VISIT_SCHEDULED → APPROVED. Requires
  /// `business_applications.approve`. Approval is NOT activation and creates
  /// no membership/ownership.
  Future<BusinessApplicationStaffResult> approve(String applicationId);

  /// UNDER_REVIEW / CONTACTED / VISIT_SCHEDULED → REJECTED. Requires
  /// `business_applications.reject` and a non-empty reason.
  Future<BusinessApplicationStaffResult> reject(
    String applicationId, {
    required String reason,
  });
}