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
class SupabasePersonalProfileRemoteGateway
    implements PersonalProfileRemoteGateway {
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
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (rows == null) return null;
    return CloudProfile(
      userId: (rows['user_id'] as String?) ?? userId,
      displayName: rows['display_name'] as String?,
      photoUrl: rows['photo_url'] as String?,
      roleCode: rows['role_code'] as String?,
      preferredRegionId: rows['preferred_region_id'] as String?,
      regionPreferenceId: rows['region_preference_id'] as String?,
      phone: rows['phone'] as String?,
    );
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
      // 23505 = unique_violation on the user_id primary key subjected to a
      // concurrent/duplicate insert race. Surface it as an explicit signal so
      // the coordinator can re-read and evaluate as an existing-cloud case.
      if (e.code == '23505') {
        throw const CloudProfileAlreadyExistsException();
      }
      rethrow;
    }
  }

  @override
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  }) async {
    // Only the six-zone preference column is touched. RLS guarantees the
    // authenticated user can UPDATE only their own row.
    await _client
        .from(_table)
        .update({'region_preference_id': regionPreferenceId})
        .eq('user_id', userId);
  }
}
