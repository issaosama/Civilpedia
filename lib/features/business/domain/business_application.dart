import 'business_application_status.dart';
import 'business_application_type.dart';

/// A6.2 — A single business application row from
/// `public.business_applications` (canonical identity: `business_applications.id`).
///
/// Canonical identity contract:
/// * [applicantUserId] is always the Supabase `auth.users.id` — never a Google
///   provider id and never derived from email.
/// * [type] is [BusinessApplicationType.newApplication] or
///   [BusinessApplicationType.claim].
/// * [status] is one of the nine lifecycle statuses ([BusinessApplicationStatus]).
///
/// An application is NOT a Directory Entity, NOT a membership, and NOT a
/// verification state. Approved/activated alone never grants ownership.
///
/// Immutable value object. Staff/operational fields (reviewer id, timestamps,
/// reasons) are surfaced READ-ONLY for applicant transparency and must never
/// be writable from the client.
class BusinessApplication {
  BusinessApplication({
    required this.id,
    required this.type,
    required this.status,
    this.applicantUserId,
    this.targetEntityId,
    this.metadata,
    this.reviewedByUserId,
    this.reviewedAt,
    this.returnReason,
    this.rejectionReason,
    this.approvedAt,
    this.activatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Canonical application id (`business_applications.id`).
  final String id;

  /// Canonical applicant id (`auth.users.id`). Nullable to mirror the DB
  /// `ON DELETE SET NULL` when an auth user is deleted; a null applicant shell
  /// grants no capability.
  final String? applicantUserId;

  /// NEW (create entity) or CLAIM (claim existing entity).
  final BusinessApplicationType type;

  /// Target Directory Entity id (`directory_entities.id`) for CLAIM
  /// applications, else null. The DB enforces CLAIM ⇒ target present.
  final String? targetEntityId;

  /// Applicant-provided payload (jsonb `metadata`) for NEW applications before
  /// an entity row exists. Never staff-owned fields.
  final Map<String, dynamic>? metadata;

  /// The current lifecycle status.
  final BusinessApplicationStatus status;

  // --- Read-only staff/operational fields surfaced for transparency ---
  final String? reviewedByUserId;
  final DateTime? reviewedAt;
  final String? returnReason;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? activatedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether this application references another applicant's identity than
  /// [userId] (or the row has no applicant).
  bool belongsTo(String userId) =>
      applicantUserId == userId && userId.isNotEmpty;

  /// Parses a raw PostgREST row for `business_applications` into a
  /// [BusinessApplication], fail-closed: returns null when the row is missing a
  /// required column (`id`, `application_type`, `status`).
  static BusinessApplication? tryFromRow(Map<String, dynamic> row) {
    final id = row['id'];
    if (id is! String) return null;
    final type = BusinessApplicationType.fromCode(row['application_type'] as String?);
    final status = BusinessApplicationStatus.fromCode(row['status'] as String?);
    if (!type.isKnown || !status.isKnown) return null;
    return BusinessApplication(
      id: id,
      applicantUserId: row['applicant_user_id'] as String?,
      type: type,
      targetEntityId: row['target_entity_id'] as String?,
      metadata: row['metadata'] is Map<String, dynamic>
          ? (row['metadata'] as Map<String, dynamic>)
          : null,
      status: status,
      reviewedByUserId: row['reviewed_by_user_id'] as String?,
      reviewedAt: DateTime.tryParse(row['reviewed_at'] as String? ?? ''),
      returnReason: row['return_reason'] as String?,
      rejectionReason: row['rejection_reason'] as String?,
      approvedAt: DateTime.tryParse(row['approved_at'] as String? ?? ''),
      activatedAt: DateTime.tryParse(row['activated_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! BusinessApplication) return false;
    return other.id == id &&
        other.applicantUserId == applicantUserId &&
        other.type == type &&
        other.targetEntityId == targetEntityId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, applicantUserId, type, targetEntityId, status);

  @override
  String toString() =>
      'BusinessApplication(id=$id, type=${type.name}, status=${status.name}, '
      'applicant=$applicantUserId, target=$targetEntityId)';
}