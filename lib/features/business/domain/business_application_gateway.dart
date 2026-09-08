import 'business_application.dart';
import 'business_application_policy.dart';

/// A6.2 — Outcome of a business-application creation attempt.
sealed class BusinessApplicationCreateResult {
  const BusinessApplicationCreateResult();
}

/// The application was created (INSERT succeeded under RLS).
class BusinessApplicationCreated extends BusinessApplicationCreateResult {
  const BusinessApplicationCreated(this.application);

  final BusinessApplication application;
}

/// Creation was denied. [cause] explains why; no row was inserted and no side
/// effects occurred.
class BusinessApplicationCreateDenied extends BusinessApplicationCreateResult {
  const BusinessApplicationCreateDenied(this.cause);

  final BusinessApplicationRejectionCause cause;
}

/// A6.2 — Outcome of an applicant submit/resubmit request.
sealed class BusinessApplicationSubmitResult {
  const BusinessApplicationSubmitResult();
}

/// Submission is not available from the client yet: resubmission requires the
/// explicit, server-authorized mutation contract (UPDATE is intentionally
/// revoked for `authenticated` by migration 00011). Grants no capability and
/// performs no transition.
class BusinessApplicationSubmitUnavailable extends BusinessApplicationSubmitResult {
  const BusinessApplicationSubmitUnavailable();
}

/// A6.2 — Read-only + safe-DRAFT-INSERT boundary to `public.business_applications`.
///
/// Canonical identity: [BusinessApplication.id]. The applicant is always the
/// authenticated Supabase `auth.users.id` — never a Google provider id or
/// email.
///
/// RLS contract (00010 + 00011): `authenticated` may INSERT own and SELECT
/// own; UPDATE is REVOKED (00011); no DELETE. A6.2 preserves this exactly:
///   * safe operations implemented:
///       - list own applications
///       - fetch own application
///       - create NEW draft / CLAIM draft (pure INSERT of DRAFT rows; RLS
///         `WITH CHECK applicant_user_id = auth.uid()` is the backstop)
///   * privileged operations declared but UNAVAILABLE:
///       - submit / resubmit (and every reviewer/staff transition) — future
///         server-authorized mutation contract, NO client UPDATE path.
///
/// An application is never a membership and never mutates
/// `directory_entities.claim_status` / verification. No ownership side effects.
abstract class BusinessApplicationGateway {
  /// Whether the backend is initialized for application reads (production:
  /// Supabase initialized). False keeps the app safely guest.
  bool get isAvailable;

  /// Returns every application belonging to [userId] (the canonical
  /// authenticated user id). A read/network failure THROWS so the caller can
  /// fail safe without inventing a status. Unauthenticated/offline degrades to
  /// an empty list.
  Future<List<BusinessApplication>> listOwnApplications(String userId);

  /// Fetches [applicationId] if and only if it belongs to [userId]. Returns
  /// null when absent/unowned. Read/network failures THROW.
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  );

  /// Creates a NEW DRAFT application row (safe initial INSERT, status DRAFT,
  /// type NEW, applicant = [currentUserId]).
  ///
  /// Returns [BusinessApplicationCreateDenied] for policy guards (guest) and
  /// for RLS applicant-mismatch. [metadata] may carry candidate
  /// profile/contact/geography for the future entity; it is never staff-owned
  /// data and never creates an entity/membership.
  Future<BusinessApplicationCreateResult> createNewDraft({
    required String currentUserId,
    Map<String, dynamic>? metadata,
  });

  /// Creates a CLAIM DRAFT application row for [targetEntityId].
  ///
  /// Domain guards (fail closed): guest, missing target, current user already
  /// OWNER of the target, or an existing live CLAIM for the same target.
  /// Authoritative existence comes from the DB foreign key (mapped to
  /// [BusinessApplicationRejectionCause.targetNotFound]). Submitting a claim
  /// NEVER grants a membership and NEVER changes the entity's claim/verification
  /// state.
  Future<BusinessApplicationCreateResult> createClaimDraft({
    required String currentUserId,
    required String targetEntityId,
  });

  /// Applicant submission. Declared for contract completeness but ALWAYS
  /// [BusinessApplicationSubmitUnavailable]: the client cannot transition an
  /// application under the current RLS (UPDATE revoked).
  BusinessApplicationSubmitResult submitApplication(
    BusinessApplication application,
  );

  /// Applicant resubmission after correction. ALWAYS unavailable from the
  /// client (future server-authorized mutation contract).
  BusinessApplicationSubmitResult resubmitApplication(
    BusinessApplication application,
  );
}