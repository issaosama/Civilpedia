import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_profile.dart';
import 'personal_profile_remote_gateway.dart';

/// A5.6 — Production [PersonalProfileRemoteGateway] backed by the shared
/// Supabase client's PostgREST `profiles` table.
///
/// Rows are gated by existing RLS: an `authenticated` user may SELECT/INSERT/
/// UPDATE only their own row (`user_id = auth.uid()`). This gateway never uses
/// service_role and never reads rows it is not authorized to see.
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
      phone: rows['phone'] as String?,
    );
  }

  @override
  Future<void> createProfile(CloudProfile profile) async {
    final payload = <String, dynamic>{
      'user_id': profile.userId,
      if (profile.displayName != null) 'display_name': profile.displayName,
      if (profile.photoUrl != null) 'photo_url': profile.photoUrl,
      if (profile.roleCode != null) 'role_code': profile.roleCode,
      if (profile.preferredRegionId != null)
        'preferred_region_id': profile.preferredRegionId,
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
}
