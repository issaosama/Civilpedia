import 'business_application_status.dart';
import 'business_application_type.dart';

/// V1-R07 — Minimal summary of a business application returned by the staff
/// queue RPC. Contains only bounded operational data; no applicant PII.
class StaffApplicationSummary {
  const StaffApplicationSummary({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedByUserId,
    this.newBusiness,
    this.claimTarget,
  });

  final String id;
  final BusinessApplicationType type;
  final BusinessApplicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reviewedByUserId;
  final StaffNewBusinessSummary? newBusiness;
  final StaffClaimTargetSummary? claimTarget;

  static StaffApplicationSummary? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) return null;
    final type = BusinessApplicationType.fromCode(
      json['application_type'] as String?,
    );
    final status = BusinessApplicationStatus.fromCode(
      json['status'] as String?,
    );
    if (!type.isKnown || !status.isKnown) return null;

    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    final updatedAt = DateTime.tryParse(json['updated_at'] as String? ?? '');
    if (createdAt == null || updatedAt == null) return null;

    StaffNewBusinessSummary? newBusiness;
    final rawNew = json['new_business'];
    if (rawNew is Map<String, dynamic>) {
      newBusiness = StaffNewBusinessSummary.tryFromJson(rawNew);
      if (newBusiness == null && type == BusinessApplicationType.newApplication) {
        return null;
      }
    }

    StaffClaimTargetSummary? claimTarget;
    final rawClaim = json['claim_target'];
    if (rawClaim is Map<String, dynamic>) {
      claimTarget = StaffClaimTargetSummary.tryFromJson(rawClaim);
      if (claimTarget == null && type == BusinessApplicationType.claim) {
        return null;
      }
    }

    return StaffApplicationSummary(
      id: id,
      type: type,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      reviewedByUserId: json['reviewed_by_user_id'] as String?,
      newBusiness: newBusiness,
      claimTarget: claimTarget,
    );
  }
}

/// V1-R07 — Minimal NEW business summary in a staff queue item.
class StaffNewBusinessSummary {
  const StaffNewBusinessSummary({
    required this.name,
    this.entityType,
  });

  final String name;
  final String? entityType;

  static StaffNewBusinessSummary? tryFromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String) return null;
    return StaffNewBusinessSummary(
      name: name,
      entityType: json['entity_type'] as String?,
    );
  }
}

/// V1-R07 — Minimal CLAIM target summary in a staff queue item.
class StaffClaimTargetSummary {
  const StaffClaimTargetSummary({
    required this.id,
    required this.name,
    this.entityType,
  });

  final String id;
  final String name;
  final String? entityType;

  static StaffClaimTargetSummary? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) return null;
    return StaffClaimTargetSummary(
      id: id,
      name: name,
      entityType: json['entity_type'] as String?,
    );
  }
}

/// V1-R07 — Keyset cursor for staff queue pagination. The server orders by
/// `(created_at ASC, id ASC)`, so the cursor is the pair of the last item's
/// created_at and id.
class StaffApplicationCursor {
  const StaffApplicationCursor({
    required this.createdAt,
    required this.id,
  });

  final DateTime createdAt;
  final String id;

  static StaffApplicationCursor? tryFromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    final id = json['id'];
    if (createdAt == null || id is! String) return null;
    return StaffApplicationCursor(createdAt: createdAt, id: id);
  }
}

/// V1-R07 — One page of staff queue results.
class StaffApplicationPage {
  const StaffApplicationPage({
    required this.items,
    this.nextCursor,
  });

  final List<StaffApplicationSummary> items;
  final StaffApplicationCursor? nextCursor;

  bool get hasMore => nextCursor != null;

  /// Strict fail-closed projection (finding 4):
  /// - explicit JSON `null` (or absent) `next_cursor` is a valid final page;
  /// - a non-null `next_cursor` MUST be a complete, valid cursor — a malformed
  ///   or incomplete cursor object fails the whole page;
  /// - every item must parse; a malformed item fails the whole page.
  static StaffApplicationPage? tryFromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List<dynamic>) return null;
    final items = <StaffApplicationSummary>[];
    for (final raw in rawItems) {
      if (raw is! Map<String, dynamic>) return null;
      final parsed = StaffApplicationSummary.tryFromJson(raw);
      if (parsed == null) return null;
      items.add(parsed);
    }

    StaffApplicationCursor? nextCursor;
    final rawCursor = json['next_cursor'];
    if (rawCursor != null) {
      if (rawCursor is! Map<String, dynamic>) return null;
      final parsed = StaffApplicationCursor.tryFromJson(rawCursor);
      if (parsed == null) return null;
      nextCursor = parsed;
    }

    return StaffApplicationPage(items: items, nextCursor: nextCursor);
  }
}
