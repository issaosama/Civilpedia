import 'business_membership.dart';
import 'managed_business_summary.dart';

/// A6.1 — Read-only boundary to the canonical business ownership model
/// (`public.business_memberships`).
///
/// Canonical ownership is represented ONLY through this table. [userId]
/// arguments are ALWAYS the Supabase `auth.users.id` (from the authenticated
/// session) — never a Google provider id, email, or any local metadata.
///
/// RLS contract (migration 00010): an `authenticated` user may SELECT only
/// their OWN membership rows. V1-R03 preserves that direct read and adds narrow
/// SECURITY DEFINER RPCs for the authenticated actor's business projection and
/// OWNER/ADMIN-authorized entity roster.
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

  /// Returns the minimal canonical entities associated with the authenticated
  /// actor. The RPC accepts no user identity; `auth.uid()` is authoritative.
  Future<ManagedBusinessListResult> listMyBusinesses();

  /// Returns the canonical roster for [entityId] only when the authenticated
  /// actor is OWNER or ADMIN. The server fails closed with P0PER otherwise.
  Future<BusinessMembershipListResult> listMembersForEntity(String entityId);
}

/// V1-R03 typed failures for server-authorized business management reads.
enum BusinessManagementReadCause {
  unauthenticated,
  permissionDenied,
  unexpected;

  static BusinessManagementReadCause fromServerCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'P0AUT':
        return BusinessManagementReadCause.unauthenticated;
      case 'P0PER':
        return BusinessManagementReadCause.permissionDenied;
      default:
        return BusinessManagementReadCause.unexpected;
    }
  }
}

/// Outcome of a My Businesses read.
sealed class ManagedBusinessListResult {
  const ManagedBusinessListResult();
}

class ManagedBusinessListAvailable extends ManagedBusinessListResult {
  const ManagedBusinessListAvailable(this.businesses);

  final List<ManagedBusinessSummary> businesses;
}

class ManagedBusinessListDenied extends ManagedBusinessListResult {
  const ManagedBusinessListDenied(this.cause);

  final BusinessManagementReadCause cause;
}

class ManagedBusinessListUnavailable extends ManagedBusinessListResult {
  const ManagedBusinessListUnavailable();
}

/// Outcome of an entity membership-roster read.
sealed class BusinessMembershipListResult {
  const BusinessMembershipListResult();
}

/// A read performed successfully.
class BusinessMembershipListAvailable extends BusinessMembershipListResult {
  const BusinessMembershipListAvailable(this.memberships);

  final List<BusinessMembership> memberships;
}

class BusinessMembershipListDenied extends BusinessMembershipListResult {
  const BusinessMembershipListDenied(this.cause);

  final BusinessManagementReadCause cause;
}

/// The backend is unavailable, so no data or capability can be inferred.
class BusinessMembershipListUnavailable extends BusinessMembershipListResult {
  const BusinessMembershipListUnavailable();
}
