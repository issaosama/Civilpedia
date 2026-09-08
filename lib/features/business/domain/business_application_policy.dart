import 'business_membership.dart';
import 'business_membership_capability_resolver.dart';
import 'business_role.dart';
import 'business_application.dart';
import 'business_application_type.dart';

/// A6.2 — Rejection causes for application creation / claim decisions.
enum BusinessApplicationRejectionCause {
  /// No authenticated canonical user context (guest/unauthenticated).
  guestUser,

  /// No target entity id supplied for a CLAIM application.
  missingTarget,

  /// The target entity does not exist (authoritative DB foreign-key signal).
  targetNotFound,

  /// The target entity exists but is not claimable: its canonical
  /// `claim_status` is not `unclaimed` (already claimed / claim in review).
  /// Authoritative trigger guard (migration 00014), not a client read.
  targetNotClaimable,

  /// The current user already holds an OWNER membership for the target
  /// entity; claiming it again is unnecessary/invalid.
  alreadyOwner,

  /// The current user already has a live (non-final) CLAIM application for the
  /// same target; no duplicate claims.
  duplicateClaim,

  /// A row-level security violation confirmed the supplied applicant id is not
  /// the authenticated session user.
  applicantMismatch,
}

/// A6.2 — Outcome of evaluating whether the current user may create an
/// application/claim (pure domain decision).
sealed class BusinessApplicationCreateDecision {
  const BusinessApplicationCreateDecision();
}

/// Creation is permitted by domain policy.
class BusinessApplicationPolicyAllowed extends BusinessApplicationCreateDecision {
  const BusinessApplicationPolicyAllowed();
}

/// Creation is blocked; [cause] explains why. Carries no side effects.
class BusinessApplicationPolicyDenied extends BusinessApplicationCreateDecision {
  const BusinessApplicationPolicyDenied(this.cause);

  final BusinessApplicationRejectionCause cause;
}

/// A6.2 — Pure, stateless claim/creation safety policy.
///
/// Centralizes the applicant-side rules that MUST hold before the client may
/// issue an INSERT for a NEW or CLAIM application. These are UX/domain guards;
/// the server (RLS, CHECK constraints, future staff functions) remains
/// authoritative.
abstract final class BusinessApplicationPolicy {
  /// Evaluates a NEW application creation.
  ///
  /// Safety: the current canonical user id must be present. That id is ALWAYS
  /// the authenticated `auth.users.id` (RLS enforces the inserted
  /// `applicant_user_id` equals `auth.uid()`).
  static BusinessApplicationCreateDecision evaluateNew({
    required String currentUserId,
  }) {
    if (currentUserId.isEmpty) {
      return const BusinessApplicationPolicyDenied(
        BusinessApplicationRejectionCause.guestUser,
      );
    }
    return const BusinessApplicationPolicyAllowed();
  }

  /// Evaluates a CLAIM application creation.
  ///
  /// Guards, in order:
  /// 1. non-guest canonical user;
  /// 2. a target entity id MUST be supplied (DB also enforces CLAIM ⇒ target);
  /// 3. the current user must NOT already be OWNER of the target
  ///    (claiming one's own entity is unnecessary/invalid);
  /// 4. the current user must NOT already hold a live (non-final) CLAIM for
  ///    the same target (no silent duplicate claims).
  ///
  /// [memberships] and [ownApplications] MUST be the current user's own rows
  /// (read through the authorized own-read gateways).
  static BusinessApplicationCreateDecision evaluateClaim({
    required String currentUserId,
    required String targetEntityId,
    required List<BusinessMembership> memberships,
    required List<BusinessApplication> ownApplications,
  }) {
    if (currentUserId.isEmpty) {
      return const BusinessApplicationPolicyDenied(
        BusinessApplicationRejectionCause.guestUser,
      );
    }
    if (targetEntityId.isEmpty) {
      return const BusinessApplicationPolicyDenied(
        BusinessApplicationRejectionCause.missingTarget,
      );
    }

    final ownMembership = BusinessMembershipCapabilityResolver
        .membershipForEntity(
          memberships,
          userId: currentUserId,
          entityId: targetEntityId,
        );
    if (ownMembership != null && ownMembership.role == BusinessRole.owner) {
      return const BusinessApplicationPolicyDenied(
        BusinessApplicationRejectionCause.alreadyOwner,
      );
    }

    final hasLiveClaim = ownApplications.any(
      (a) =>
          a.type == BusinessApplicationType.claim &&
          a.targetEntityId == targetEntityId &&
          a.status.isLive,
    );
    if (hasLiveClaim) {
      return const BusinessApplicationPolicyDenied(
        BusinessApplicationRejectionCause.duplicateClaim,
      );
    }

    return const BusinessApplicationPolicyAllowed();
  }
}