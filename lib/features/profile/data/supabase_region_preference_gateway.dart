import 'package:supabase_flutter/supabase_flutter.dart';

import 'region_preference_gateway.dart';

/// A5.7 — Production [RegionPreferenceGateway] backed by the public
/// `region_preferences` table through the shared Supabase client.
///
/// Reference data changes rarely, so a successful load is cached in-memory for
/// the process lifetime (no repeated Supabase round-trips). A failed load is
/// NEVER cached, so the next call retries safely.
///
/// Reads are gated by the public `region_preferences_select_all` RLS policy
/// (migration 00013). This gateway never uses service_role.
class SupabaseRegionPreferenceGateway implements RegionPreferenceGateway {
  SupabaseRegionPreferenceGateway({SupabaseClient? client})
      : _injectedClient = client;

  // Injected for tests; production resolves lazily so merely constructing the
  // gateway never touches the global Supabase singleton.
  final SupabaseClient? _injectedClient;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  static const String _table = 'region_preferences';

  Map<String, String>? _codeToId;

  Future<Map<String, String>> _loadOnce() async {
    final cached = _codeToId;
    if (cached != null) return cached;
    final rows = await _client
        .from(_table)
        .select('id, code')
        .eq('is_active', true);
    final map = <String, String>{
      for (final row in rows)
        (row['code'] as String): (row['id'] as String),
    };
    _codeToId = map;
    return map;
  }

  @override
  Future<String?> resolvePreferenceIdByCode(String code) async {
    final resolved = await _loadOnce();
    return resolved[code];
  }
}