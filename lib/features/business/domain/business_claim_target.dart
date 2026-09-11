/// V1-R04 — Canonical claim target on the conservative `directory_entities`
/// read for the CLAIM application selector.
///
/// Identity contract:
/// * [id] is ALWAYS the canonical `directory_entities.id` (UUID) — the value
///   that MUST be passed to `createClaimDraft(p_target_entity_id)`.
/// * It is NEVER a local Directory projection id (e.g.
///   `ServiceBusinessProfile.id` / `LocalServiceBusinessProfile`). Passing a
///   local profile id to the claim RPC would be a type confusion and is
///   forbidden by the V1-R04 contract (§6).
///
/// Reading the row through the existing RLS policy
/// `directory_entities_select_active` (migration 00010) surfaces only
/// `lifecycle_status = 'active'` rows. The client additionally filters on
/// `claim_status = 'unclaimed'` as a UX guard; the server trigger (migration
/// 00014) remains the authoritative claimability backstop.
class BusinessClaimTarget {
  const BusinessClaimTarget({
    required this.id,
    required this.name,
    required this.entityType,
    required this.claimStatus,
    this.verificationStatus,
  });

  /// Canonical `directory_entities.id`. Passed to the CLAIM creation RPC.
  final String id;

  /// Display name of the entity.
  final String name;

  /// Canonical `directory_entities.entity_type` storage value (migration 00005
  /// CHECK set). Presentation labels are resolved separately.
  final String entityType;

  /// Canonical `directory_entities.claim_status`. Only `unclaimed` is a
  /// claimable target for the selector.
  final String claimStatus;

  /// Optional `verification_status` for supplemental display only.
  final String? verificationStatus;

  /// Whether the target is (still) claimable per its canonical claim_status.
  bool get isUnclaimed => claimStatus == 'unclaimed';

  /// Fail-closed row parser. Returns null when the canonical columns are
  /// missing/malformed so the presentation layer never invents a target.
  static BusinessClaimTarget? tryFromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final name = row['name'];
    final entityType = row['entity_type'];
    final claimStatus = row['claim_status'];
    if (id is! String ||
        name is! String ||
        entityType is! String ||
        claimStatus is! String) {
      return null;
    }
    return BusinessClaimTarget(
      id: id,
      name: name,
      entityType: entityType,
      claimStatus: claimStatus,
      verificationStatus: row['verification_status'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BusinessClaimTarget &&
        other.id == id &&
        other.name == name &&
        other.entityType == entityType &&
        other.claimStatus == claimStatus &&
        other.verificationStatus == verificationStatus;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, entityType, claimStatus, verificationStatus);

  @override
  String toString() =>
      'BusinessClaimTarget(id=$id, name=$name, entityType=$entityType, '
      'claimStatus=$claimStatus)';
}