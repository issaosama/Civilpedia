import '../domain/user_profile.dart';

/// A5.6 — Immutable representation of a single `public.profiles` row stored in
/// Supabase, keyed 1:1 by the canonical `auth.users.id` ([userId]).
///
/// Only the columns that A5.6 is allowed to read/derive are surfaced here.
/// It deliberately exposes no token, email, or provider-raw metadata.
class CloudProfile {
  const CloudProfile({
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.roleCode,
    this.preferredRegionId,
    this.phone,
  });

  /// Canonical Supabase `auth.users.id`.
  final String userId;

  /// `profiles.display_name`.
  final String? displayName;

  /// `profiles.photo_url`.
  final String? photoUrl;

  /// `profiles.role_code` (snake_case, CHECK-constrained).
  final String? roleCode;

  /// `profiles.preferred_region_id` (uuid FK to regions).
  final String? preferredRegionId;

  /// `profiles.phone`.
  final String? phone;
}

/// Maps a single local [CivilUserType] into its stable `profiles.role_code`
/// snake_case value (mirrors the DB CHECK constraint).
String civilUserTypeToRoleCode(CivilUserType type) {
  switch (type) {
    case CivilUserType.siteEngineer:
      return 'site_engineer';
    case CivilUserType.consultantEngineer:
      return 'consultant_engineer';
    case CivilUserType.structuralEngineer:
      return 'structural_engineer';
    case CivilUserType.contractor:
      return 'contractor';
    case CivilUserType.engineeringStudent:
      return 'engineering_student';
    case CivilUserType.technicianSupervisor:
      return 'technician_supervisor';
    case CivilUserType.supplierShopOwner:
      return 'supplier_shop_owner';
    case CivilUserType.engineeringOffice:
      return 'engineering_office';
    case CivilUserType.constructionCompany:
      return 'construction_company';
    case CivilUserType.buildingOffice:
      return 'building_office';
    case CivilUserType.generalUser:
      return 'general_user';
  }
}

/// Inverse of [civilUserTypeToRoleCode]; unknown codes fall back to
/// [CivilUserType.generalUser] (mirrors the DB default and local deserializer).
CivilUserType roleCodeToCivilUserType(String code) {
  switch (code) {
    case 'site_engineer':
      return CivilUserType.siteEngineer;
    case 'consultant_engineer':
      return CivilUserType.consultantEngineer;
    case 'structural_engineer':
      return CivilUserType.structuralEngineer;
    case 'contractor':
      return CivilUserType.contractor;
    case 'engineering_student':
      return CivilUserType.engineeringStudent;
    case 'technician_supervisor':
      return CivilUserType.technicianSupervisor;
    case 'supplier_shop_owner':
      return CivilUserType.supplierShopOwner;
    case 'engineering_office':
      return CivilUserType.engineeringOffice;
    case 'construction_company':
      return CivilUserType.constructionCompany;
    case 'building_office':
      return CivilUserType.buildingOffice;
    default:
      return CivilUserType.generalUser;
  }
}
