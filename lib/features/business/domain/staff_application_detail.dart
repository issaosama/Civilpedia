import 'business_application_status.dart';
import 'business_application_type.dart';

/// V1-R07 — Bounded staff review detail projection. Contains only the
/// operational data needed for review; applicant PII is limited to display name
/// and phone.
class StaffApplicationDetail {
  const StaffApplicationDetail({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.targetEntityId,
    this.reviewedByUserId,
    this.reviewedAt,
    this.returnReason,
    this.rejectionReason,
    this.approvedAt,
    this.activatedAt,
    required this.applicantDisplayName,
    this.applicantPhone,
    this.newBusiness,
    this.claimTarget,
    this.contacts = const [],
    this.visits = const [],
  });

  final String id;
  final BusinessApplicationType type;
  final BusinessApplicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? targetEntityId;
  final String? reviewedByUserId;
  final DateTime? reviewedAt;
  final String? returnReason;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime? activatedAt;
  final String applicantDisplayName;
  final String? applicantPhone;
  final StaffNewBusinessContext? newBusiness;
  final StaffClaimTargetContext? claimTarget;
  final List<StaffApplicationContact> contacts;
  final List<StaffApplicationVisit> visits;

  static StaffApplicationDetail? tryFromJson(Map<String, dynamic> json) {
    final rawApplication = json['application'];
    if (rawApplication is! Map<String, dynamic>) return null;

    final id = rawApplication['id'];
    if (id is! String) return null;

    final type = BusinessApplicationType.fromCode(
      rawApplication['application_type'] as String?,
    );
    final status = BusinessApplicationStatus.fromCode(
      rawApplication['status'] as String?,
    );
    if (!type.isKnown || !status.isKnown) return null;

    final createdAt = DateTime.tryParse(
      rawApplication['created_at'] as String? ?? '',
    );
    final updatedAt = DateTime.tryParse(
      rawApplication['updated_at'] as String? ?? '',
    );
    if (createdAt == null || updatedAt == null) return null;

    final rawApplicant = json['applicant'];
    if (rawApplicant is! Map<String, dynamic>) return null;
    final applicantDisplayName = rawApplicant['display_name'];
    if (applicantDisplayName is! String) return null;

    StaffNewBusinessContext? newBusiness;
    final rawNew = json['new_business'];
    if (rawNew is Map<String, dynamic>) {
      newBusiness = StaffNewBusinessContext.tryFromJson(rawNew);
      if (newBusiness == null &&
          type == BusinessApplicationType.newApplication) {
        return null;
      }
    }

    StaffClaimTargetContext? claimTarget;
    final rawClaim = json['claim_target'];
    if (rawClaim is Map<String, dynamic>) {
      claimTarget = StaffClaimTargetContext.tryFromJson(rawClaim);
      if (claimTarget == null && type == BusinessApplicationType.claim) {
        return null;
      }
    }

    final contacts = _parseContacts(json['contacts']);
    final visits = _parseVisits(json['visits']);
    if (contacts == null || visits == null) return null;

    return StaffApplicationDetail(
      id: id,
      type: type,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      targetEntityId: rawApplication['target_entity_id'] as String?,
      reviewedByUserId: rawApplication['reviewed_by_user_id'] as String?,
      reviewedAt: DateTime.tryParse(
        rawApplication['reviewed_at'] as String? ?? '',
      ),
      returnReason: rawApplication['return_reason'] as String?,
      rejectionReason: rawApplication['rejection_reason'] as String?,
      approvedAt: DateTime.tryParse(
        rawApplication['approved_at'] as String? ?? '',
      ),
      activatedAt: DateTime.tryParse(
        rawApplication['activated_at'] as String? ?? '',
      ),
      applicantDisplayName: applicantDisplayName,
      applicantPhone: rawApplicant['phone'] as String?,
      newBusiness: newBusiness,
      claimTarget: claimTarget,
      contacts: contacts,
      visits: visits,
    );
  }

  /// Strict fail-closed parsing (finding 5): a present-but-malformed contacts
  /// projection fails the whole detail — every entry must parse and the
  /// collection must be a JSON array. Null/absent is a relaxed default empty.
  static List<StaffApplicationContact>? _parseContacts(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List<dynamic>) return null;
    final result = <StaffApplicationContact>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) return null;
      final parsed = StaffApplicationContact.tryFromJson(item);
      if (parsed == null) return null;
      result.add(parsed);
    }
    return result;
  }

  /// Strict fail-closed parsing (finding 5): a present-but-malformed visits
  /// projection fails the whole detail — every entry must parse and the
  /// collection must be a JSON array. Null/absent is a relaxed default empty.
  static List<StaffApplicationVisit>? _parseVisits(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List<dynamic>) return null;
    final result = <StaffApplicationVisit>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) return null;
      final parsed = StaffApplicationVisit.tryFromJson(item);
      if (parsed == null) return null;
      result.add(parsed);
    }
    return result;
  }
}

class StaffNewBusinessContext {
  const StaffNewBusinessContext({required this.name, this.entityType});

  final String name;
  final String? entityType;

  static StaffNewBusinessContext? tryFromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String) return null;
    return StaffNewBusinessContext(
      name: name,
      entityType: json['entity_type'] as String?,
    );
  }
}

class StaffClaimTargetContext {
  const StaffClaimTargetContext({
    required this.id,
    required this.name,
    this.entityType,
    this.lifecycleStatus,
    this.verificationStatus,
    this.claimStatus,
  });

  final String id;
  final String name;
  final String? entityType;
  final String? lifecycleStatus;
  final String? verificationStatus;
  final String? claimStatus;

  static StaffClaimTargetContext? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) return null;
    return StaffClaimTargetContext(
      id: id,
      name: name,
      entityType: json['entity_type'] as String?,
      lifecycleStatus: json['lifecycle_status'] as String?,
      verificationStatus: json['verification_status'] as String?,
      claimStatus: json['claim_status'] as String?,
    );
  }
}

class StaffApplicationContact {
  const StaffApplicationContact({
    required this.id,
    required this.contactedByUserId,
    required this.contactedAt,
    required this.contactType,
    this.result,
    this.notes,
  });

  final String id;
  final String contactedByUserId;
  final DateTime contactedAt;
  final String contactType;
  final String? result;
  final String? notes;

  static StaffApplicationContact? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final contactedByUserId = json['contacted_by_user_id'];
    final contactType = json['contact_type'];
    final contactedAtValue = json['contacted_at'];
    final contactedAt = contactedAtValue is String
        ? DateTime.tryParse(contactedAtValue)
        : null;
    if (id is! String ||
        contactedByUserId is! String ||
        contactType is! String ||
        contactedAt == null) {
      return null;
    }
    return StaffApplicationContact(
      id: id,
      contactedByUserId: contactedByUserId,
      contactedAt: contactedAt,
      contactType: contactType,
      result: json['result'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class StaffApplicationVisit {
  const StaffApplicationVisit({
    required this.id,
    required this.scheduledAt,
    this.completedAt,
    required this.status,
    this.location,
    this.notes,
    this.visitedByUserId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String status;
  final String? location;
  final String? notes;
  final String? visitedByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static StaffApplicationVisit? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final status = json['status'];
    final scheduledAtValue = json['scheduled_at'];
    final scheduledAt = scheduledAtValue is String
        ? DateTime.tryParse(scheduledAtValue)
        : null;
    if (id is! String || status is! String || scheduledAt == null) return null;
    return StaffApplicationVisit(
      id: id,
      scheduledAt: scheduledAt,
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
      status: status,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      visitedByUserId: json['visited_by_user_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}
