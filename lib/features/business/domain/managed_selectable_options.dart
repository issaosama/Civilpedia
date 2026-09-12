/// V1-R06 — A selectable ACTIVE canonical Directory category
/// (`public.directory_categories`, read-only taxonomy lookup).
///
/// Only IDENTITY + labels are carried. It is never a write authority: category
/// rows themselves cannot be created/mutated by the client. [id] is the stable
/// canonical category UUID used in assignment payloads.
class ManagedSelectableCategory {
  const ManagedSelectableCategory({
    required this.id,
    required this.code,
    this.isActive = true,
    this.parentCategoryId,
    this.nameAr,
    this.nameEn,
  });

  /// Canonical `directory_categories.id` (UUID).
  final String id;

  /// Optional parent for hierarchy display.
  final String? parentCategoryId;

  /// Stable machine-readable code.
  final String code;

  final String? nameAr;
  final String? nameEn;

  final bool isActive;

  /// Display label: Arabic first (canonical UI language), English fallback.
  String get displayName {
    if (nameAr != null && nameAr!.isNotEmpty) return nameAr!;
    if (nameEn != null && nameEn!.isNotEmpty) return nameEn!;
    return code;
  }

  static ManagedSelectableCategory? tryFromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final code = row['code'];
    if (id is! String || id.isEmpty) return null;
    if (code is! String || code.isEmpty) return null;
    return ManagedSelectableCategory(
      id: id,
      parentCategoryId: row['parent_category_id'] as String?,
      code: code,
      nameAr: row['name_ar'] as String?,
      nameEn: row['name_en'] as String?,
      isActive: row['is_active'] != false,
    );
  }
}

/// V1-R06 — A selectable ACTIVE physical region (`public.regions`,
/// read-only geography lookup).
///
/// Business physical-location authority comes from the regions taxonomy — NEVER
/// from `region_preferences` (the six frozen user-onboarding preference zones).
class ManagedSelectableRegion {
  const ManagedSelectableRegion({
    required this.id,
    required this.code,
    this.isActive = true,
    this.parentId,
    this.regionType,
    this.nameAr,
    this.nameEn,
  });

  /// Canonical `regions.id` (UUID).
  final String id;

  final String? parentId;

  /// Region type ('country', 'governorate', 'city', 'district',
  /// 'neighborhood').
  final String? regionType;

  /// Stable machine-readable code (identity; never display authority alone).
  final String code;

  final String? nameAr;
  final String? nameEn;

  final bool isActive;

  /// Display label: Arabic first (canonical UI language), English fallback.
  String get displayName {
    if (nameAr != null && nameAr!.isNotEmpty) return nameAr!;
    if (nameEn != null && nameEn!.isNotEmpty) return nameEn!;
    return code;
  }

  static ManagedSelectableRegion? tryFromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final code = row['code'];
    if (id is! String || id.isEmpty) return null;
    if (code is! String || code.isEmpty) return null;
    return ManagedSelectableRegion(
      id: id,
      parentId: row['parent_id'] as String?,
      regionType: row['region_type'] as String?,
      code: code,
      nameAr: row['name_ar'] as String?,
      nameEn: row['name_en'] as String?,
      isActive: row['is_active'] != false,
    );
  }
}