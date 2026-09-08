import 'business_role.dart';

/// A6.1 — Centralized, deterministic capability semantics for a Directory
/// business membership.
///
/// Authorization decisions for a single membership are expressed here in ONE
/// place so that role-string comparisons never spread across widgets/features.
///
/// Capability contract (frozen for this phase):
/// * OWNER  → canManageEntity = true; ownership transfer = false.
/// * ADMIN  → canManageEntity = true; ownership transfer = false.
/// * MEMBER → canManageEntity = false (unless the frozen product contract
///            explicitly says otherwise — it does not for A6.1).
/// * UNKNOWN → fail closed: no elevated capability of any kind.
///
/// The following are future/server-authorized and are intentionally NOT exposed
/// as guaranteed capabilities here:
/// * member/entity sensitive mutation
/// * owner transfer
/// These remain `false`/absent regardless of role.
class BusinessMembershipCapabilities {
  const BusinessMembershipCapabilities._({
    required this.isOwner,
    required this.canManageEntity,
  });

  /// Whether the membership holds the OWNER role.
  final bool isOwner;

  /// Whether the user may manage this entity (OWNER or ADMIN).
  final bool canManageEntity;

  /// Computes capabilities from a single [role].
  ///
  /// All capability answers are derived solely from the role; [unknown] fails
  /// closed to a capability-less result.
  factory BusinessMembershipCapabilities.forRole(BusinessRole role) {
    switch (role) {
      case BusinessRole.owner:
        return const BusinessMembershipCapabilities._(
          isOwner: true,
          canManageEntity: true,
        );
      case BusinessRole.admin:
        return const BusinessMembershipCapabilities._(
          isOwner: false,
          canManageEntity: true,
        );
      case BusinessRole.member:
        return const BusinessMembershipCapabilities._(
          isOwner: false,
          canManageEntity: false,
        );
      case BusinessRole.unknown:
        return const BusinessMembershipCapabilities._(
          isOwner: false,
          canManageEntity: false,
        );
    }
  }
}
