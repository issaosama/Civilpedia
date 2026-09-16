import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_profile.dart';
import 'personal_profile_remote_gateway.dart';

/// A5.6/A5.7 — Production [PersonalProfileRemoteGateway] backed by the shared
/// Supabase client's PostgREST `profiles` table.
///
/// Rows are gated by existing RLS: an `authenticated` user may SELECT/INSERT/
/// UPDATE only their own row (`user_id = auth.uid()`). This gateway never uses
/// service_role and never reads rows it is not authorized to see.
///
/// Region contract (A5.7 correction): the CREATE payload NEVER contains a
/// region column — `preferred_region_id` (legacy geographic) and
/// `region_preference_id` (six-zone preference) are surfaced on READ for
/// preservation/clarity but are never written by this gateway. No invented
/// region value can therefore reach the DB through the personal-profile seam.
///
/// The unique `user_id` primary key is the final duplicate-defense used by the
/// caller to resolve insert races deterministically.
///
/// V1-R08 (finding 4): READ is strict — every returned row is validated by
/// [parseCloudProfileRow] against the expected authenticated user. A row that
/// fails the schema contract throws [CloudProfileParseException] and is never
/// surfaced to callers, so malformed backend data always fails closed.
class SupabasePersonalProfileRemoteGateway
    implements PersonalProfileRemoteGateway, ConditionalProfileRetryGateway {
  SupabasePersonalProfileRemoteGateway({SupabaseClient? client})
    : _injectedClient = client;

  // Injected for tests; production resolves lazily so merely constructing the
  // gateway never touches the global Supabase singleton (e.g. in unconfigured
  // environments where Supabase is not initialized).
  final SupabaseClient? _injectedClient;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  static const String _table = 'profiles';

  @override
  Future<CloudProfile?> fetchByUserId(String userId) async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (rows == null) return null;
      return parseCloudProfileRow(rows, expectedUserId: userId);
    } catch (error) {
      // P2-C1: preserve the narrow READ taxonomy before the broader shared
      // mutation/bootstrap classifier can erase the exact infrastructure
      // cause. The thrown values are sanitized and contain no backend text.
      throwProfileReadFailure(error);
    }
  }

  @override
  Future<void> createProfile(CloudProfile profile) async {
    // Region columns are deliberately constrained: `preferred_region_id` is a
    // legacy geographic reference that is NEVER written here; the A5.8
    // six-zone `region_preference_id` is written only when the local profile
    // carries a stable preference code resolved through RegionPreferenceGateway
    // (a UUID is never invented, and legacy BaghdadArea is never mapped).
    final payload = <String, dynamic>{
      'user_id': profile.userId,
      if (profile.displayName != null) 'display_name': profile.displayName,
      if (profile.photoUrl != null) 'photo_url': profile.photoUrl,
      if (profile.roleCode != null) 'role_code': profile.roleCode,
      if (profile.regionPreferenceId != null)
        'region_preference_id': profile.regionPreferenceId,
      if (profile.phone != null) 'phone': profile.phone,
    };
    try {
      await _client.from(_table).insert(payload);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique violation on the user_id primary key — a concurrent/duplicate
        // insert race. Surface it as an explicit signal so the coordinator can
        // re-read and evaluate as an existing-cloud case.
        throw const CloudProfileAlreadyExistsException();
      }
      if (isPermissionDenied(e)) {
        // RLS denial is NEVER a provisioning failure (F7).
        throw const CloudProfilePermissionDeniedException();
      }
      if (_isProvisioningRejection(e)) {
        // F7 — the row could not be provisioned for a provisioning-specific
        // reason (constraint/data violation). Typed; the raw backend message
        // is never surfaced.
        throw const CloudProfileProvisioningException();
      }
      throwProfileFailure(e);
    }
  }

  @override
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  }) async {
    // Only the six-zone preference column is touched. RLS guarantees the
    // authenticated user can UPDATE only their own row. The additional
    // null-only predicate guarantees we never overwrite an existing cloud
    // preference (C4 M2).
    try {
      await _client
          .from(_table)
          .update({'region_preference_id': regionPreferenceId})
          .eq('user_id', userId)
          .isFilter('region_preference_id', null);
    } on PostgrestException catch (e) {
      if (isPermissionDenied(e)) {
        throw const CloudProfilePermissionDeniedException();
      }
      if (isUpdateInvalidDataRejection(e)) {
        // C4 M2: UPDATE-time 23505 and similar constraint/data violations are
        // domain failures, never silent provisioning success.
        throw const CloudProfileInvalidDataException();
      }
      throwProfileFailure(e);
    }
  }

  @override
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) => _saveEditableFields(
    userId: userId,
    roleCode: roleCode,
    regionPreferenceId: regionPreferenceId,
    onlyIfAbsent: false,
  );

  @override
  Future<void> saveEditableFieldsIfRegionAbsent({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) => _saveEditableFields(
    userId: userId,
    roleCode: roleCode,
    regionPreferenceId: regionPreferenceId,
    onlyIfAbsent: true,
  );

  Future<void> _saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
    required bool onlyIfAbsent,
  }) async {
    // V1-R08 — the ONLY cloud mutation the authenticated optimize foundation
    // may author. RLS guarantees the user can UPDATE only their own row; a
    // not-yet-created row is a safe no-op.
    final payload = <String, dynamic>{
      'role_code': roleCode,
      if (regionPreferenceId != null)
        'region_preference_id': regionPreferenceId,
    };
    try {
      final mutation = _client
          .from(_table)
          .update(payload)
          .eq('user_id', userId);
      await (onlyIfAbsent
          ? mutation.isFilter('region_preference_id', null)
          : mutation);
    } on PostgrestException catch (e) {
      if (isPermissionDenied(e)) {
        throw const CloudProfilePermissionDeniedException();
      }
      if (isUpdateInvalidDataRejection(e)) {
        throw const CloudProfileInvalidDataException();
      }
      throwProfileFailure(e);
    }
  }

  /// PostgREST surfaces RLS denials as SQLSTATE `42501` (insufficient_privilege)
  /// or as a PGRST-level parse message mentioning permission.
  static bool isPermissionDenied(PostgrestException e) {
    return e.code == '42501' ||
        (e.message?.toLowerCase().contains('permission denied') ?? false);
  }

  /// F7 — SQLSTATE codes that mean the canonical `profiles` row itself could
  /// not be provisioned: NOT NULL (23502), FK (23503), CHECK (23514),
  /// exclusion (23P01), and data errors (22000-22012, 22021-2202x exposed as
  /// e.g. 22P02). A unique violation (23505) and permission (42501) are handled
  /// BEFORE this check as their own typed conditions.
  static bool _isProvisioningRejection(PostgrestException e) {
    return e.code == '23502' ||
        e.code == '23503' ||
        e.code == '23514' ||
        e.code == '23P01' ||
        RegExp(r'^22[A-Z0-9]{3}$').hasMatch(e.code ?? '');
  }

  /// C4 M2 — UPDATE-time domain/invalid-data rejections. Includes the CREATE
  /// provisioning-rejection codes PLUS the unique-violation 23505, because an
  /// UPDATE duplicate must NOT be reinterpreted as successful provisioning.
  static bool isUpdateInvalidDataRejection(PostgrestException e) {
    return e.code == '23505' || _isProvisioningRejection(e);
  }

  /// C4 M2 — True when [e] represents a backend failure that is neither an
  /// RLS denial nor a known domain/invalid-data rejection. These are surfaced
  /// as typed unexpected backend failures rather than retryable network errors.
  static bool isUnexpectedBackendFailure(PostgrestException e) {
    return classifyProfileFailure(e) == ProfileFailureKind.unexpected;
  }
}
