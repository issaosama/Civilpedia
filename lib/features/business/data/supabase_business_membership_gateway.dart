import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../domain/business_membership.dart';
import '../domain/business_membership_gateway.dart';

/// A6.1 — Production [BusinessMembershipGateway] backed by the shared Supabase
/// client's PostgREST `business_memberships` table.
///
/// Reads are gated by the existing RLS policy `business_memberships_select_own`
/// (migration 00010): an `authenticated` user can SELECT only rows where
/// `user_id = auth.uid()`. This gateway NEVER broadens that policy, NEVER uses
/// service_role, and exposes NO insert/update/delete path.
///
/// The query filters on `user_id` defensively to reinforce the read-own
/// semantics; RLS remains the authoritative backstop. Rows returned are mapped
/// strictly and an unknown role fails closed to [BusinessRole.unknown].
class SupabaseBusinessMembershipGateway implements BusinessMembershipGateway {
  SupabaseBusinessMembershipGateway({
    SupabaseClient? client,
    required this.service,
  }) : _injectedClient = client;

  // Injected for tests; production resolves lazily so merely constructing the
  // gateway never touches the global Supabase singleton.
  final SupabaseClient? _injectedClient;

  /// The backend boundary used to decide availability.
  final SupabaseService service;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  static const String _table = 'business_memberships';

  @override
  bool get isAvailable => service.isInitialized;

  @override
  Future<List<BusinessMembership>> listOwnMemberships(String userId) async {
    final rows = await _client.from(_table).select().eq('user_id', userId);
    final byKey = <String, BusinessMembership>{};
    for (final row in rows) {
      final parsed = BusinessMembership.tryFromRow(row);
      // Only memberships whose canonical user matches are safe to surface, and
      // the (user_id, entity_id) primary key means a duplicate row is a
      // defensive dedupe, never a second membership.
      if (parsed == null || parsed.userId != userId) continue;
      byKey['${parsed.userId}\u0000${parsed.entityId}'] = parsed;
    }
    final memberships = byKey.values.toList()
      ..sort((a, b) => a.entityId.compareTo(b.entityId));
    return memberships;
  }

  @override
  BusinessMembershipListResult listMembersForEntity(String entityId) {
    // Entity-member listing requires privileged server authorization that the
    // current RLS does not permit. It remains an interface capability that is
    // unavailable until the future business-management server phase.
    return const BusinessMembershipListUnavailable();
  }
}
