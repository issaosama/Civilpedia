import 'business_membership.dart';
import 'business_membership_capabilities.dart';
import 'business_role.dart';

/// A6.1 — Pure, stateless resolver that derives a user's capabilities for a
/// Directory Entity from their own membership list.
///
/// This keeps authorization reasoning in one place: given the user's own
/// memberships (from [BusinessMembershipGateway.listOwnMemberships]) and a
/// target entity, it answers the capability questions the product needs.
///
/// Deterministic semantics:
/// * No membership row for the entity → capability-less (fail closed), even if
///   it is the user's only/sole data.
/// * A MEMBER that happens to be the only membership is NEVER treated as an
///   OWNER.
/// * An unknown role is never elevated.
/// * Legacy local metadata (e.g. `futureOwnerUserId`) is NOT consulted — only
///   the membership role is authoritative.
abstract final class BusinessMembershipCapabilityResolver {
  /// The effective role for [userId] within [entityId] from their own
  /// membership list, or null when the user has no membership for that entity.
  static BusinessMembership? membershipForEntity(
    List<BusinessMembership> memberships, {
    required String userId,
    required String entityId,
  }) {
    for (final membership in memberships) {
      if (membership.userId == userId && membership.entityId == entityId) {
        return membership;
      }
    }
    return null;
  }

  /// Capabilities for [userId] within [entityId], derived ONLY from their own
  /// memberships. Absence of a membership fails closed to no capability.
  static BusinessMembershipCapabilities capabilitiesForEntity(
    List<BusinessMembership> memberships, {
    required String userId,
    required String entityId,
  }) {
    final membership =
        membershipForEntity(memberships, userId: userId, entityId: entityId);
    if (membership == null) {
      return BusinessMembershipCapabilities.forRole(BusinessRole.unknown);
    }
    return BusinessMembershipCapabilities.forRole(membership.role);
  }
}
