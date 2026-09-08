import 'business_role.dart';

/// A6.1 — A single membership row tying an authenticated Supabase user to a
/// Directory Entity (`public.business_memberships`).
///
/// Canonical identity contract:
/// * [userId] is always the Supabase `auth.users.id` — never a Google provider
///   id and never derived from email.
/// * [entityId] references `public.directory_entities.id`.
/// * Role is a single [BusinessRole].
///
/// Immutable value object. DO NOT add mutation/save semantics here — membership
/// writes are server-authorized future work and MUST NOT originate from the
/// Flutter client.
class BusinessMembership {
  const BusinessMembership({
    required this.userId,
    required this.entityId,
    required this.role,
  });

  /// Canonical Supabase `auth.users.id` of the member.
  final String userId;

  /// Directory Entity id (`directory_entities.id`) this membership references.
  final String entityId;

  /// The role for this membership within the entity.
  final BusinessRole role;

  /// Parses a raw PostgREST row for `business_memberships` into a
  /// [BusinessMembership]. Returns null when the row lacks the required
  /// columns, so callers can fail closed rather than fabricate a membership.
  static BusinessMembership? tryFromRow(Map<String, dynamic> row) {
    final userId = row['user_id'];
    final entityId = row['entity_id'];
    if (userId is! String || entityId is! String) return null;
    return BusinessMembership(
      userId: userId,
      entityId: entityId,
      role: BusinessRole.fromCode(row['role'] as String?),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! BusinessMembership) return false;
    return other.userId == userId &&
        other.entityId == entityId &&
        other.role == role;
  }

  @override
  int get hashCode => Object.hash(userId, entityId, role);

  @override
  String toString() =>
      'BusinessMembership(userId=$userId, entityId=$entityId, role=${role.name})';
}
