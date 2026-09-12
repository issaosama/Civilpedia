import '../domain/user_profile.dart';

/// A5.6/A5.7 — Immutable representation of a single `public.profiles` row
/// stored in Supabase, keyed 1:1 by the canonical `auth.users.id` ([userId]).
///
/// Only the columns that A5.6/A5.7 is allowed to read/derive are surfaced
/// here. It deliberately exposes no token, email, or provider-raw metadata.
class CloudProfile {
  const CloudProfile({
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.roleCode,
    this.preferredRegionId,
    this.regionPreferenceId,
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

  /// LEGACY `profiles.preferred_region_id` (uuid FK to `regions`, physical
  /// geography). Preserved for compatibility; A5.7 never writes it and never
  /// compares it to a preference.
  final String? preferredRegionId;

  /// `profiles.region_preference_id` (uuid FK to `region_preferences`, the
  /// frozen six Zone Region Preference). Never written by A5.7 bootstrap.
  final String? regionPreferenceId;

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

/// Thrown when a raw `public.profiles` row cannot be parsed as a valid,
/// session-owned cloud profile (V1-R08 strict parsing, finding 4).
class CloudProfileParseException implements Exception {
  const CloudProfileParseException(this.reason);
  final String reason;

  @override
  String toString() => 'CloudProfileParseException($reason)';
}

/// The exact set of `profiles.role_code` values the DB CHECK constraint
/// allows. These are the only values the save foundation may write.
const Set<String> canonicalRoleCodes = {
  'site_engineer',
  'consultant_engineer',
  'structural_engineer',
  'contractor',
  'engineering_student',
  'technician_supervisor',
  'supplier_shop_owner',
  'engineering_office',
  'construction_company',
  'building_office',
  'general_user',
};

/// True when [code] is one of the canonical `profiles.role_code` values.
bool isCanonicalRoleCode(String code) => canonicalRoleCodes.contains(code);

/// True when [value] is a valid UUID v4-ish string (8-4-4-4-12 hex with
/// dashes). Case-insensitive for hex digits.
bool isValidUuid(String value) {
  final trimmed = value.trim();
  if (trimmed.length != 36) return false;
  if (trimmed[8] != '-' ||
      trimmed[13] != '-' ||
      trimmed[18] != '-' ||
      trimmed[23] != '-') {
    return false;
  }
  final body = trimmed.replaceAll('-', '');
  if (body.length != 32) return false;
  for (final rune in body.codeUnits) {
    final isDigit = rune >= 0x30 && rune <= 0x39;
    final isLowerHex = rune >= 0x61 && rune <= 0x66;
    final isUpperHex = rune >= 0x41 && rune <= 0x46;
    if (!(isDigit || isLowerHex || isUpperHex)) return false;
  }
  return true;
}

/// Strict parser for a raw `public.profiles` row returned by PostgREST.
///
/// Enforces (V1-R08 finding 4):
/// * `user_id` is present, non-empty, matches [expectedUserId], and is a
///   valid UUID.
/// * `role_code` when present is one of the canonical values.
/// * UUID-typed columns when present are valid UUIDs.
/// * Other text columns are accepted as-is (presentation-only).
///
/// Throws [CloudProfileParseException] on any violation so the caller can
/// surface a typed `malformedResponse` cause without fabricating data.
CloudProfile parseCloudProfileRow(
  Map<String, dynamic> row, {
  required String expectedUserId,
}) {
  final rawUserId = row['user_id'];
  if (rawUserId is! String || rawUserId.trim().isEmpty) {
    throw const CloudProfileParseException(
      'profile row has no canonical user_id',
    );
  }
  final userId = rawUserId.trim();
  if (userId != expectedUserId) {
    throw CloudProfileParseException(
      'profile row user_id ($userId) does not match '
      'authenticated user ($expectedUserId)',
    );
  }
  if (!isValidUuid(userId)) {
    throw const CloudProfileParseException(
      'profile row user_id is not a valid UUID',
    );
  }

  final roleCode = _nullableText(row, 'role_code');
  if (roleCode != null && !isCanonicalRoleCode(roleCode)) {
    throw CloudProfileParseException(
      'non-canonical role_code "$roleCode"',
    );
  }

  _optionalUuid(row, 'region_preference_id');
  _optionalUuid(row, 'preferred_region_id');

  return CloudProfile(
    userId: userId,
    displayName: _nullableText(row, 'display_name'),
    photoUrl: _nullableText(row, 'photo_url'),
    roleCode: roleCode,
    preferredRegionId: _nullableText(row, 'preferred_region_id'),
    regionPreferenceId: _nullableText(row, 'region_preference_id'),
    phone: _nullableText(row, 'phone'),
  );
}

String? _nullableText(Map<String, dynamic> row, String column) {
  final raw = row[column];
  if (raw == null) return null;
  if (raw is! String) {
    throw CloudProfileParseException('$column is not a text value');
  }
  return raw;
}

void _optionalUuid(Map<String, dynamic> row, String column) {
  final raw = row[column];
  if (raw == null) return;
  if (raw is! String) {
    throw CloudProfileParseException('$column is not a string');
  }
  if (!isValidUuid(raw.trim())) {
    throw CloudProfileParseException('$column is not a valid UUID');
  }
}
