import 'business_membership_capabilities.dart';
import 'business_role.dart';

/// V1-R03 — Minimum server-authoritative projection for a business associated
/// with the authenticated actor through `public.business_memberships`.
///
/// This is intentionally smaller than a Directory profile. It carries only the
/// canonical entity identity/state and the actor's membership role. Management
/// capability continues to come from [BusinessMembershipCapabilities].
class ManagedBusinessSummary {
  const ManagedBusinessSummary({
    required this.entityId,
    required this.name,
    required this.entityType,
    required this.membershipRole,
    required this.claimStatus,
    required this.verificationStatus,
  });

  final String entityId;
  final String name;
  final String entityType;
  final BusinessRole membershipRole;
  final String claimStatus;
  final String verificationStatus;

  /// Existing centralized role semantics; unknown roles fail closed.
  BusinessMembershipCapabilities get capabilities =>
      BusinessMembershipCapabilities.forRole(membershipRole);

  static ManagedBusinessSummary? tryFromRow(Map<String, dynamic> row) {
    final entityId = row['entity_id'];
    final name = row['name'];
    final entityType = row['entity_type'];
    final membershipRole = row['membership_role'];
    final claimStatus = row['claim_status'];
    final verificationStatus = row['verification_status'];
    if (entityId is! String ||
        name is! String ||
        entityType is! String ||
        membershipRole is! String ||
        claimStatus is! String ||
        verificationStatus is! String) {
      return null;
    }
    return ManagedBusinessSummary(
      entityId: entityId,
      name: name,
      entityType: entityType,
      membershipRole: BusinessRole.fromCode(membershipRole),
      claimStatus: claimStatus,
      verificationStatus: verificationStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ManagedBusinessSummary &&
        other.entityId == entityId &&
        other.name == name &&
        other.entityType == entityType &&
        other.membershipRole == membershipRole &&
        other.claimStatus == claimStatus &&
        other.verificationStatus == verificationStatus;
  }

  @override
  int get hashCode => Object.hash(
    entityId,
    name,
    entityType,
    membershipRole,
    claimStatus,
    verificationStatus,
  );
}
