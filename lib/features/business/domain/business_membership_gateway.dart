import 'business_membership.dart';

/// A6.1 — Read-only boundary to the canonical business ownership model
/// (`public.business_memberships`).
///
/// Canonical ownership is represented ONLY through this table. [userId]
/// arguments are ALWAYS the Supabase `auth.users.id` (from the authenticated
/// session) — never a Google provider id, email, or any local metadata.
///
/// RLS contract (migration 00010): an `authenticated` user may SELECT only
/// their OWN membership rows. A6.1 does NOT broaden this. Consequently this
/// gateway exposes:
///   * own-membership reads (implemented, read-own only);
///   * entity-member/management listing (interface capability that returns
///     [unavailable] until the future server-authorized management phase).
///
/// This boundary declares NO insert/update/delete and MUST NOT be used as a
/// path for client membership mutations. It is strictly read-only.
abstract class BusinessMembershipGateway {
  /// Whether the backend is initialized such that membership reads can run
  /// (production: Supabase initialized). False keeps the app safely guest.
  bool get isAvailable;

  /// Returns every active membership belonging to the authenticated [userId].
  ///
  /// Guest / unavailable / network failure MUST NOT invent roles: callers
  /// degrade to an empty membership set and failed-closed capabilities without
  /// breaking authentication or Directory browsing. A read/network failure
  /// therefore THROWS so the caller can decide how to fail safe.
  Future<List<BusinessMembership>> listOwnMemberships(String userId);

  /// Entity-member listing requires privileged server authorization and is NOT
  /// permitted by the current RLS. Always returns [unavailable] until the
  /// future business-management server mutation phase.
  BusinessMembershipListResult listMembersForEntity(String entityId);
}

/// A6.1 — Outcome of a membership-list operation.
///
/// Reads that are permitted return [available] with their rows; operations that
/// require server authorization this phase does not open return [unavailable]
/// (no data, no fabricated privileges).
sealed class BusinessMembershipListResult {
  const BusinessMembershipListResult();
}

/// A read performed successfully.
class BusinessMembershipListAvailable extends BusinessMembershipListResult {
  const BusinessMembershipListAvailable(this.memberships);

  final List<BusinessMembership> memberships;
}

/// The requested operation is not available yet (server-authorized future
/// work). Carries no data and grants no elevated capability.
class BusinessMembershipListUnavailable extends BusinessMembershipListResult {
  const BusinessMembershipListUnavailable();
}
