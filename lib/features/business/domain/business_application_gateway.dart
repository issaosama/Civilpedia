import 'business_application.dart';
import 'business_application_policy.dart';

/// A6.2 — Outcome of a business-application creation attempt.
sealed class BusinessApplicationCreateResult {
  const BusinessApplicationCreateResult();
}

/// The application was created by the server-authorized creation RPC.
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

/// A6.3 — Outcome of an applicant submit/resubmit request.
///
/// Both operations are server-authorized RPC mutations (migration 00016):
/// the client NEVER issues a PostgREST UPDATE/DELETE on
/// `business_applications` (UPDATE is still revoked for `authenticated` by
/// 00011). The returned [BusinessApplication] reflects the authoritative
/// server state; the adversary - including a concurrent transition - is
/// resolved by the database, not by this type.
sealed class BusinessApplicationSubmitResult {
  const BusinessApplicationSubmitResult();
}

/// The submission succeeded; [application] is the authoritative updated row.
class BusinessApplicationSubmitted extends BusinessApplicationSubmitResult {
  const BusinessApplicationSubmitted(this.application);

  final BusinessApplication application;
}

/// Submission was denied for a typed, server-authoritative reason. No row
/// transition occurred and no side effects happened.
class BusinessApplicationSubmitDenied extends BusinessApplicationSubmitResult {
  const BusinessApplicationSubmitDenied(this.cause);

  final BusinessApplicationSubmitCause cause;
}

/// A6.3 — Typed applicant submit/resubmit denial causes, mirroring the
/// deterministic custom SQLSTATE contract of migration 00016. Values are the
/// mapping layer between raw server errors and the application; raw error
/// text is never surfaced to UI.
enum BusinessApplicationSubmitCause {
  /// P0AUT — no authenticated session.
  unauthenticated,

  /// P0NAC — the application belongs to a different applicant.
  notApplicant,

  /// P0NOT — the application row does not exist.
  applicationNotFound,

  /// P0TRA — the current status does not allow this operation.
  invalidTransition,

  /// P0PHR — the applicant's authoritative phone (profiles.phone) is missing.
  /// Phone presence is required, not phone verification.
  phoneRequired,

  /// P0DAT — a NEW application carries no candidate metadata.
  requiredDataMissing,

  /// P0CLM — the CLAIM target is no longer claimable (claim_status changed).
  targetNotClaimable,

  /// Any unclassified server failure. Carries no raw SQL/error text.
  unexpected;

  /// Maps a PostgREST error code to the typed cause; unknown codes fail closed
  /// to [unexpected].
  static BusinessApplicationSubmitCause fromServerCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'P0AUT':
        return BusinessApplicationSubmitCause.unauthenticated;
      case 'P0NAC':
        return BusinessApplicationSubmitCause.notApplicant;
      case 'P0NOT':
        return BusinessApplicationSubmitCause.applicationNotFound;
      case 'P0TRA':
        return BusinessApplicationSubmitCause.invalidTransition;
      case 'P0PHR':
        return BusinessApplicationSubmitCause.phoneRequired;
      case 'P0DAT':
        return BusinessApplicationSubmitCause.requiredDataMissing;
      case 'P0CLM':
        return BusinessApplicationSubmitCause.targetNotClaimable;
      default:
        return BusinessApplicationSubmitCause.unexpected;
    }
  }
}

/// A6.3.1 — Read-only + server-authorized creation/lifecycle boundary for
/// `public.business_applications`.
///
/// Canonical identity: [BusinessApplication.id]. The applicant is always the
/// authenticated Supabase `auth.users.id` — never a Google provider id or
/// email.
///
/// Database contract (00010 + 00011 + 00017): `authenticated` may SELECT its
/// own rows; generic INSERT and UPDATE are revoked; no DELETE. Creation is
/// available only through narrow RPCs that derive applicant identity from
/// `auth.uid()` and force DRAFT:
///   * safe operations implemented:
///       - list own applications
///       - fetch own application
///       - create NEW draft / CLAIM draft through migration-00017 RPCs
///       - submit / resubmit through migration-00016 RPCs
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

  /// Creates a NEW DRAFT application through the server RPC. [currentUserId]
  /// is used only for the local guest guard; it is never sent to the RPC.
  /// Server identity comes exclusively from `auth.uid()`.
  ///
  /// Returns [BusinessApplicationCreateDenied] for policy/server guards.
  /// [metadata] may carry candidate
  /// profile/contact/geography for the future entity; it is never staff-owned
  /// data and never creates an entity/membership.
  Future<BusinessApplicationCreateResult> createNewDraft({
    required String currentUserId,
    Map<String, dynamic>? metadata,
  });

  /// Creates a CLAIM DRAFT application through the server RPC for
  /// [targetEntityId]. [currentUserId] is never sent as identity.
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

  /// Applicant submission (A6.3): a server-authorized RPC mutation
  /// (`submit_business_application`, migration 00016) that transitions a
  /// DRAFT application to SUBMITTED. The client passes only the application id;
  /// identity, phone, and target claimability are verified authoritatively
  /// server-side. Returns [BusinessApplicationSubmitted] with the updated row
  /// or a typed [BusinessApplicationSubmitDenied]. Never a client UPDATE.
  Future<BusinessApplicationSubmitResult> submitApplication(
    BusinessApplication application,
  );

  /// Applicant resubmission after staff correction (A6.3): the server-authorized
  /// `resubmit_business_application` RPC transitions a NEEDS_CORRECTION
  /// application back to SUBMITTED. return_reason history is preserved
  /// server-side. Never a client UPDATE.
  Future<BusinessApplicationSubmitResult> resubmitApplication(
    BusinessApplication application,
  );
}
