import 'business_claim_target.dart';

/// V1-R04 — Read boundary for CLAIM targets on `public.directory_entities`.
///
/// This is the single narrow, additive, read-only seam defined by the V1-R04
/// contract (§6). It is intentionally separate from the Directory repositories:
/// it reads the canonical `directory_entities.claim_status` signal over PostgREST,
/// returning only rows eligible for a CLAIM application. It exposes NO mutation
/// and NO membership/ownership data.
abstract class BusinessClaimTargetGateway {
  /// Whether the backend is initialized for the read (production: Supabase
  /// initialized). False keeps consumers inert/safely empty.
  bool get isAvailable;

  /// Returns the canonical, currently claimable targets — active rows whose
  /// `claim_status = 'unclaimed'` — visible under the existing RLS
  /// (`directory_entities_select_active`, migration 00010).
  ///
  /// Read/network failures THROW so the caller can present a retryable error
  /// rather than an invented empty list. The server trigger (migration 00014)
  /// remains the authoritative claimability backstop.
  Future<List<BusinessClaimTarget>> listUnclaimedTargets();
}