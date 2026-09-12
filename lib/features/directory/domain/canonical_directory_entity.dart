import '../../business/domain/directory_entity_types.dart';
import '../../profile/domain/service_business_profile.dart';

/// Canonical UUID format matching Postgres `uuid` / `gen_random_uuid()`.
final RegExp _canonicalUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

const Set<String> _knownLifecycleStatuses = {
  'draft',
  'active',
  'inactive',
  'suspended',
};

const Set<String> _knownClaimStatuses = {'unclaimed', 'pending', 'claimed'};

/// Returns [preferred] when non-empty, else [fallback] when non-empty.
String? _firstNonEmpty(String? preferred, String? fallback) {
  if (preferred != null && preferred.isNotEmpty) return preferred;
  if (fallback != null && fallback.isNotEmpty) return fallback;
  return null;
}

/// V1-R05 — Canonical Directory entity backed by `public.directory_entities`.
///
/// This is the SINGLE production Directory entity model after V1-R05 cutover.
/// Its [id] is the canonical `directory_entities.id` (UUID). No local profile
/// id, business name, phone, or heuristic match may serve as canonical identity.
///
/// Cloud is authoritative. Cache is a stale offline snapshot. Legacy
/// `ServiceBusinessProfile` is no longer production Directory authority.
class CanonicalDirectoryEntity {
  const CanonicalDirectoryEntity({
    required this.id,
    required this.name,
    required this.entityType,
    this.description,
    this.lifecycleStatus = 'active',
    this.verificationStatus = VerificationStatus.unverified,
    this.claimStatus = 'unclaimed',
    this.categories = const [],
    this.locations = const [],
    this.contacts = const [],
    this.media = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Canonical `directory_entities.id` (UUID). The ONLY production identity.
  final String id;

  /// Display name.
  final String name;

  /// Canonical entity_type (one of [DirectoryEntityType.all]).
  final String entityType;

  /// Optional bounded description.
  final String? description;

  /// Lifecycle status ('active', 'inactive', 'suspended', 'draft').
  final String lifecycleStatus;

  /// Canonical cloud verification state.
  final VerificationStatus verificationStatus;

  /// Canonical cloud claim state (e.g. 'unclaimed', 'claimed').
  final String claimStatus;

  /// Assigned active categories from `directory_entity_categories`.
  final List<CanonicalDirectoryCategory> categories;

  /// Canonical locations from `entity_locations` + `regions`.
  final List<CanonicalDirectoryLocation> locations;

  /// Public contacts from `entity_contacts`.
  final List<CanonicalDirectoryContact> contacts;

  /// Optional public media from `entity_media`.
  final List<CanonicalDirectoryMedia> media;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Validates that [id] matches the canonical UUID format used by Postgres.
  static bool isValidUuid(String id) => _canonicalUuid.hasMatch(id);

  /// Fail-closed row parser for the main entity + joined children.
  ///
  /// Returns null when required canonical columns are missing/malformed so
  /// the presentation layer never invents an entity.
  static CanonicalDirectoryEntity? tryFromRow(
    Map<String, dynamic> row, {
    List<CanonicalDirectoryCategory> categories = const [],
    List<CanonicalDirectoryLocation> locations = const [],
    List<CanonicalDirectoryContact> contacts = const [],
    List<CanonicalDirectoryMedia> media = const [],
  }) {
    final id = row['id'];
    final name = row['name'];
    final entityType = row['entity_type'];
    if (id is! String || !_canonicalUuid.hasMatch(id)) return null;
    if (name is! String || name.isEmpty) return null;
    if (entityType is! String || !DirectoryEntityType.isKnown(entityType)) {
      return null;
    }

    final description = row['description'] as String?;

    final lifecycleStatus = row['lifecycle_status'] as String?;
    if (lifecycleStatus == null || !_knownLifecycleStatuses.contains(lifecycleStatus)) {
      return null;
    }

    final claimStatus = row['claim_status'] as String?;
    if (claimStatus == null || !_knownClaimStatuses.contains(claimStatus)) {
      return null;
    }

    final verificationRaw = row['verification_status'];
    if (verificationRaw is! String) return null;
    VerificationStatus? verificationStatus;
    for (final candidate in VerificationStatus.values) {
      if (candidate.name == verificationRaw) {
        verificationStatus = candidate;
        break;
      }
    }
    if (verificationStatus == null) return null;

    DateTime? createdAt;
    if (row['created_at'] is String) {
      createdAt = DateTime.tryParse(row['created_at']);
    }
    DateTime? updatedAt;
    if (row['updated_at'] is String) {
      updatedAt = DateTime.tryParse(row['updated_at']);
    }

    return CanonicalDirectoryEntity(
      id: id,
      name: name,
      entityType: entityType,
      description: description,
      lifecycleStatus: lifecycleStatus,
      verificationStatus: verificationStatus,
      claimStatus: claimStatus,
      categories: categories,
      locations: locations,
      contacts: contacts,
      media: media,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Serializes to a JSON-safe map for cache persistence.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'entity_type': entityType,
    'description': description,
    'lifecycle_status': lifecycleStatus,
    'verification_status': verificationStatus.name,
    'claim_status': claimStatus,
    'categories': categories.map((c) => c.toJson()).toList(),
    'locations': locations.map((l) => l.toJson()).toList(),
    'contacts': contacts.map((c) => c.toJson()).toList(),
    'media': media.map((m) => m.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  /// Fail-closed deserialization from a cache map.
  static CanonicalDirectoryEntity? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final entityType = json['entity_type'];
    if (id is! String || !_canonicalUuid.hasMatch(id)) return null;
    if (name is! String || name.isEmpty) return null;
    if (entityType is! String || !DirectoryEntityType.isKnown(entityType)) {
      return null;
    }

    final lifecycleStatus = json['lifecycle_status'] as String?;
    if (lifecycleStatus == null || !_knownLifecycleStatuses.contains(lifecycleStatus)) {
      return null;
    }

    final claimStatus = json['claim_status'] as String?;
    if (claimStatus == null || !_knownClaimStatuses.contains(claimStatus)) {
      return null;
    }

    final verificationRaw = json['verification_status'];
    if (verificationRaw is! String) return null;
    VerificationStatus? verificationStatus;
    for (final candidate in VerificationStatus.values) {
      if (candidate.name == verificationRaw) {
        verificationStatus = candidate;
        break;
      }
    }
    if (verificationStatus == null) return null;

    final categoriesRaw = json['categories'];
    final locationsRaw = json['locations'];
    final contactsRaw = json['contacts'];
    final mediaRaw = json['media'];

    return CanonicalDirectoryEntity(
      id: id,
      name: name,
      entityType: entityType,
      description: json['description'] as String?,
      lifecycleStatus: lifecycleStatus,
      verificationStatus: verificationStatus,
      claimStatus: claimStatus,
      categories: categoriesRaw is List
          ? categoriesRaw
              .whereType<Map>()
              .map((m) => CanonicalDirectoryCategory.fromJson(
                    Map<String, dynamic>.from(m),
                  ))
              .where((c) => c.id.isNotEmpty)
              .toList()
          : const [],
      locations: locationsRaw is List
          ? locationsRaw
              .whereType<Map>()
              .map((m) => CanonicalDirectoryLocation.fromJson(
                    Map<String, dynamic>.from(m),
                  ))
              .where((l) =>
                  l.regionCode.isNotEmpty || (l.address?.isNotEmpty ?? false))
              .toList()
          : const [],
      contacts: contactsRaw is List
          ? contactsRaw
              .whereType<Map>()
              .map((m) => CanonicalDirectoryContact.fromJson(
                    Map<String, dynamic>.from(m),
                  ))
              .toList()
          : const [],
      media: mediaRaw is List
          ? mediaRaw
              .whereType<Map>()
              .map((m) => CanonicalDirectoryMedia.fromJson(
                    Map<String, dynamic>.from(m),
                  ))
              .toList()
          : const [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanonicalDirectoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Canonical category from `directory_categories` via
/// `directory_entity_categories`.
class CanonicalDirectoryCategory {
  const CanonicalDirectoryCategory({
    required this.id,
    required this.name,
    this.code,
    this.nameAr,
    this.nameEn,
  });

  final String id;

  /// Display name (English-first, Arabic fallback).
  final String name;
  final String? code;

  /// Bilingual labels from `directory_categories` (`name_ar`, `name_en`).
  final String? nameAr;
  final String? nameEn;

  static CanonicalDirectoryCategory? tryFromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final nameAr = row['name_ar'] as String?;
    final nameEn = row['name_en'] as String?;
    if (id is! String || id.isEmpty) return null;
    final displayName = _firstNonEmpty(nameEn, nameAr);
    if (displayName == null || displayName.isEmpty) return null;
    return CanonicalDirectoryCategory(
      id: id,
      name: displayName,
      code: row['code'] as String?,
      nameAr: nameAr,
      nameEn: nameEn,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (nameAr != null) 'name_ar': nameAr,
    if (nameEn != null) 'name_en': nameEn,
    if (code != null) 'code': code,
  };

  factory CanonicalDirectoryCategory.fromJson(Map<String, dynamic> json) {
    final nameAr = json['name_ar'] as String?;
    final nameEn = json['name_en'] as String?;
    final storedName = json['name'] as String?;
    final displayName = (storedName != null && storedName.isNotEmpty)
        ? storedName
        : (_firstNonEmpty(nameEn, nameAr) ?? '');
    return CanonicalDirectoryCategory(
      id: json['id'] as String? ?? '',
      name: displayName,
      code: json['code'] as String?,
      nameAr: nameAr,
      nameEn: nameEn,
    );
  }
}

/// Canonical location from `entity_locations` + `regions`.
class CanonicalDirectoryLocation {
  const CanonicalDirectoryLocation({
    required this.regionCode,
    this.regionName,
    this.regionNameAr,
    this.regionNameEn,
    this.address,
    this.isPrimary = false,
  });

  final String regionCode;

  /// Display name (English-first, Arabic fallback).
  final String? regionName;

  /// Bilingual region labels from `regions` (`name_ar`, `name_en`).
  final String? regionNameAr;
  final String? regionNameEn;
  final String? address;
  final bool isPrimary;

  Map<String, dynamic> toJson() => {
    'region_code': regionCode,
    if (regionName != null) 'region_name': regionName,
    if (regionNameAr != null) 'region_name_ar': regionNameAr,
    if (regionNameEn != null) 'region_name_en': regionNameEn,
    if (address != null) 'address': address,
    'is_primary': isPrimary,
  };

  factory CanonicalDirectoryLocation.fromJson(Map<String, dynamic> json) {
    final nameAr = json['region_name_ar'] as String?;
    final nameEn = json['region_name_en'] as String?;
    final storedName = json['region_name'] as String?;
    final displayName = (storedName != null && storedName.isNotEmpty)
        ? storedName
        : _firstNonEmpty(nameEn, nameAr);
    return CanonicalDirectoryLocation(
      regionCode: json['region_code'] as String? ?? '',
      regionName: displayName,
      regionNameAr: nameAr,
      regionNameEn: nameEn,
      address: json['address'] as String?,
      isPrimary: json['is_primary'] == true,
    );
  }
}

/// Canonical public contact from `entity_contacts`.
class CanonicalDirectoryContact {
  const CanonicalDirectoryContact({
    required this.contactType,
    required this.value,
  });

  final String contactType;
  final String value;

  static CanonicalDirectoryContact? tryFromRow(Map<String, dynamic> row) {
    final contactType = row['contact_type'];
    final value = row['value'];
    if (contactType is! String || value is! String) return null;
    if (contactType.isEmpty || value.isEmpty) return null;
    return CanonicalDirectoryContact(
      contactType: contactType,
      value: value,
    );
  }

  Map<String, dynamic> toJson() => {
    'contact_type': contactType,
    'value': value,
  };

  factory CanonicalDirectoryContact.fromJson(Map<String, dynamic> json) {
    return CanonicalDirectoryContact(
      contactType: json['contact_type'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}

/// Canonical public media from `entity_media`.
class CanonicalDirectoryMedia {
  const CanonicalDirectoryMedia({
    required this.url,
    this.mediaType,
  });

  final String url;
  final String? mediaType;

  Map<String, dynamic> toJson() => {
    'url': url,
    if (mediaType != null) 'media_type': mediaType,
  };

  factory CanonicalDirectoryMedia.fromJson(Map<String, dynamic> json) {
    return CanonicalDirectoryMedia(
      url: json['url'] as String? ?? '',
      mediaType: json['media_type'] as String?,
    );
  }
}
