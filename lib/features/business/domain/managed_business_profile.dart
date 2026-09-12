import '../../profile/domain/service_business_profile.dart';
import 'business_contact_type.dart';
import 'directory_entity_types.dart';

/// Canonical UUID format matching Postgres `uuid` / `gen_random_uuid()`.
final RegExp _managedProfileUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

const Set<String> _managedLifecycleStatuses = {
  'draft',
  'active',
  'inactive',
  'suspended',
};

const Set<String> _managedClaimStatuses = {'unclaimed', 'pending', 'claimed'};

/// V1-R06 — Authoritative management projection returned by the frozen server
/// RPC `get_managed_business_profile` / `update_managed_business_profile`
/// (migration 00020).
///
/// This is the writable MANAGE authority — a deliberately bounded projection
/// separate from the public [CanonicalDirectoryEntity] read model. Its
/// [updatedAt] is the optimistic-concurrency version that every save must
/// submit as `p_expected_updated_at`.
///
/// Parsing is fail-closed by design: any malformed sensitive state makes the
/// WHOLE projection unparseable so malformed data can never become silently
/// writable authority (a replace-all contact/category payload built from
/// partially parsed children would otherwise destroy unknown rows).
class ManagedBusinessProfile {
  const ManagedBusinessProfile({
    required this.id,
    required this.entityType,
    required this.name,
    required this.lifecycleStatus,
    required this.verificationStatus,
    required this.claimStatus,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.contacts = const [],
    this.primaryLocation,
    this.categories = const [],
  });

  /// Canonical `directory_entities.id` (UUID). The ONLY business identity.
  final String id;

  /// Canonical entity_type (one of [DirectoryEntityType.all]). Immutable in
  /// V1-R06.
  final String entityType;

  /// Display name (required, 1–160 characters after trim).
  final String name;

  /// Optional bounded description (max 2000 characters).
  final String? description;

  /// Lifecycle status ('draft', 'active', 'inactive', 'suspended').
  final String lifecycleStatus;

  /// Canonical verification state (never a client parameter).
  final VerificationStatus verificationStatus;

  /// Canonical claim state ('unclaimed', 'pending', 'claimed').
  final String claimStatus;

  /// Replacement-set contacts (max 10, frozen types, at most one primary per
  /// type).
  final List<ManagedBusinessContact> contacts;

  /// The single managed primary location, or null when the business has none.
  final ManagedBusinessLocation? primaryLocation;

  /// Replacement-set category assignments (max 10 unique, at most one primary).
  final List<ManagedBusinessCategory> categories;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether the current lifecycle is visible through the PUBLIC Directory RLS
  /// (`directory_entities_select_active` admits only active rows). Management
  /// access remains unaffected for draft/inactive/suspended entities.
  bool get isPubliclyVisible => lifecycleStatus == 'active';

  /// Validates canonical UUID format used for [id] and foreign row ids.
  static bool isValidUuid(String value) => _managedProfileUuid.hasMatch(value);

  /// Fail-closed parser for the frozen READ RPC projection.
  ///
  /// Returns null when any required sensitive state is missing/malformed so the
  /// presentation layer never invents a writable authority.
  static ManagedBusinessProfile? tryFromJson(Map<String, dynamic> json) {
    final entity = json['entity'];
    if (entity is! Map<String, dynamic>) return null;

    final id = entity['id'];
    final name = entity['name'];
    final entityType = entity['entity_type'];
    if (id is! String || !_managedProfileUuid.hasMatch(id)) return null;
    if (name is! String || name.isEmpty) return null;
    if (entityType is! String || !DirectoryEntityType.isKnown(entityType)) {
      return null;
    }

    final lifecycleStatus = entity['lifecycle_status'] as String?;
    if (lifecycleStatus == null ||
        !_managedLifecycleStatuses.contains(lifecycleStatus)) {
      return null;
    }

    final claimStatus = entity['claim_status'] as String?;
    if (claimStatus == null || !_managedClaimStatuses.contains(claimStatus)) {
      return null;
    }

    final verificationRaw = entity['verification_status'];
    if (verificationRaw is! String) return null;
    VerificationStatus? verificationStatus;
    for (final candidate in VerificationStatus.values) {
      if (candidate.name == verificationRaw) {
        verificationStatus = candidate;
        break;
      }
    }
    if (verificationStatus == null) return null;

    final createdAt = DateTime.tryParse(entity['created_at'] as String? ?? '');
    final updatedAt = DateTime.tryParse(entity['updated_at'] as String? ?? '');
    if (createdAt == null || updatedAt == null) return null;

    // V1-R06 review correction: these replace-all child projection keys MUST
    // be present in the server response. A missing key means the RPC returned
    // a malformed/shape-mismatched projection and must NOT become writable
    // authority (fail closed rather than invent empty data that could delete
    // valid server rows on save).
    if (!json.containsKey('contacts')) return null;
    final contactsRaw = json['contacts'];
    if (contactsRaw == null || contactsRaw is! List) return null;
    final contacts = <ManagedBusinessContact>[];
    for (final raw in contactsRaw) {
      if (raw is! Map) return null;
      final parsed =
          ManagedBusinessContact.tryFromJson(Map<String, dynamic>.from(raw));
      if (parsed == null) return null;
      contacts.add(parsed);
    }

    if (!json.containsKey('primary_location')) return null;
    final locationRaw = json['primary_location'];
    ManagedBusinessLocation? primaryLocation;
    if (locationRaw is Map) {
      primaryLocation = ManagedBusinessLocation.tryFromJson(
        Map<String, dynamic>.from(locationRaw),
      );
      if (primaryLocation == null) return null;
    } else if (locationRaw != null) {
      return null;
    }

    if (!json.containsKey('categories')) return null;
    final categoriesRaw = json['categories'];
    if (categoriesRaw == null || categoriesRaw is! List) return null;
    final categories = <ManagedBusinessCategory>[];
    for (final raw in categoriesRaw) {
      if (raw is! Map) return null;
      final parsed =
          ManagedBusinessCategory.tryFromJson(Map<String, dynamic>.from(raw));
      if (parsed == null) return null;
      categories.add(parsed);
    }

    return ManagedBusinessProfile(
      id: id,
      name: name,
      entityType: entityType,
      description: entity['description'] as String?,
      lifecycleStatus: lifecycleStatus,
      verificationStatus: verificationStatus,
      claimStatus: claimStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      contacts: contacts,
      primaryLocation: primaryLocation,
      categories: categories,
    );
  }
}

/// V1-R06 — A single managed contact row (`public.entity_contacts`).
class ManagedBusinessContact {
  const ManagedBusinessContact({
    required this.id,
    required this.type,
    required this.value,
    required this.isPrimary,
  });

  /// Server row id. Empty for client-created draft rows that have not been
  /// persisted yet.
  final String id;

  final BusinessContactType type;

  /// Trimmed display value.
  final String value;

  final bool isPrimary;

  static ManagedBusinessContact? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = BusinessContactType.fromCode(json['contact_type'] as String?);
    final value = json['value'];
    if (id is! String || id.isEmpty) return null;
    if (!type.isKnown) return null;
    if (value is! String || value.isEmpty) return null;
    return ManagedBusinessContact(
      id: id,
      type: type,
      value: value,
      isPrimary: json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'contact_type': type.code,
        'value': value,
        'is_primary': isPrimary,
      };

  @override
  bool operator ==(Object other) {
    return other is ManagedBusinessContact &&
        other.type == type &&
        other.value == value &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode => Object.hash(type, value, isPrimary);
}

/// V1-R06 — The managed PRIMARY location projection
/// (`public.entity_locations` + `public.regions`).
class ManagedBusinessLocation {
  const ManagedBusinessLocation({
    required this.id,
    this.regionId,
    this.regionCode,
    this.regionNameAr,
    this.regionNameEn,
    this.address,
    this.latitude,
    this.longitude,
    this.isPrimary = true,
  });

  /// Server row id. Empty for client-created draft rows.
  final String id;

  /// Canonical active physical region id, or null (no region).
  final String? regionId;

  /// Stable canonical region code (identity kept stable; display-only name is
  /// below).
  final String? regionCode;
  final String? regionNameAr;
  final String? regionNameEn;

  /// Optional bounded address (max 500 characters).
  final String? address;

  /// Nullable paired coordinates (both present or both null).
  final double? latitude;
  final double? longitude;

  final bool isPrimary;

  /// Whether a bounded location payload actually carries content. An empty
  /// location (no region, no address, no coordinates) equals "no primary
  /// location" and is submitted as JSON null to CLEAR the primary row.
  bool get isEmpty =>
      (regionId == null || regionId!.isEmpty) &&
      (address == null || address!.trim().isEmpty) &&
      latitude == null &&
      longitude == null;

  static ManagedBusinessLocation? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    final regionId = json['region_id'] as String?;
    if (regionId != null && !_managedProfileUuid.hasMatch(regionId)) {
      return null;
    }
    if (json['region_code'] != null && json['region_code'] is! String) {
      return null;
    }
    if (json['region_name_ar'] != null &&
        json['region_name_ar'] is! String) {
      return null;
    }
    if (json['region_name_en'] != null &&
        json['region_name_en'] is! String) {
      return null;
    }
    if (json['address'] != null && json['address'] is! String) {
      return null;
    }
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    if (latitude != null && latitude is! num) return null;
    if (longitude != null && longitude is! num) return null;
    return ManagedBusinessLocation(
      id: id,
      regionId: regionId,
      regionCode: json['region_code'] as String?,
      regionNameAr: json['region_name_ar'] as String?,
      regionNameEn: json['region_name_en'] as String?,
      address: json['address'] as String?,
      latitude: latitude == null ? null : (latitude as num).toDouble(),
      longitude: longitude == null ? null : (longitude as num).toDouble(),
      isPrimary: json['is_primary'] != false,
    );
  }
}

/// V1-R06 — A managed category assignment (`public.directory_entity_categories`
/// joined with `public.directory_categories`).
class ManagedBusinessCategory {
  const ManagedBusinessCategory({
    required this.categoryId,
    required this.code,
    this.nameAr,
    this.nameEn,
    required this.isPrimary,
  });

  final String categoryId;
  final String code;
  final String? nameAr;
  final String? nameEn;
  final bool isPrimary;

  static ManagedBusinessCategory? tryFromJson(Map<String, dynamic> json) {
    final categoryId = json['category_id'];
    final code = json['code'];
    if (categoryId is! String || !_managedProfileUuid.hasMatch(categoryId)) {
      return null;
    }
    if (code is! String || code.isEmpty) return null;
    if (json['name_ar'] != null && json['name_ar'] is! String) return null;
    if (json['name_en'] != null && json['name_en'] is! String) return null;
    return ManagedBusinessCategory(
      categoryId: categoryId,
      code: code,
      nameAr: json['name_ar'] as String?,
      nameEn: json['name_en'] as String?,
      isPrimary: json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toAssignmentJson() => {
        'category_id': categoryId,
        'is_primary': isPrimary,
      };

  @override
  bool operator ==(Object other) {
    return other is ManagedBusinessCategory &&
        other.categoryId == categoryId &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode => Object.hash(categoryId, isPrimary);
}