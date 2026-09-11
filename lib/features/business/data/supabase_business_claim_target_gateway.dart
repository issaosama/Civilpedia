import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../domain/business_claim_target.dart';
import '../domain/business_claim_target_gateway.dart';

/// V1-R04 — Production [BusinessClaimTargetGateway] backed by the shared
/// Supabase client's PostgREST boundary.
///
/// Seam contract (§6):
/// * authenticated SELECT on `public.directory_entities`;
/// * projection: `id`, `name`, `entity_type`, `claim_status`,
///   `verification_status`;
/// * client filter: `claim_status = 'unclaimed'` (UX guard — the select RLS
///   policy `directory_entities_select_active` already limits reads to
///   `lifecycle_status = 'active'` rows, so unclaimed + active is exactly the
///   claimable candidate set);
/// * NO new table, NO RPC, NO migration, NO mutation surface.
///
/// The id read here is the canonical `directory_entities.id`. It is the ONLY
/// value that may be passed to `createClaimDraft(p_target_entity_id)`;
/// local Directory projection ids are never valid claim targets.
class SupabaseBusinessClaimTargetGateway implements BusinessClaimTargetGateway {
  SupabaseBusinessClaimTargetGateway({
    required this.service,
    SupabaseClient? client,
  }) : _injectedClient = client;

  /// The backend boundary used to decide availability.
  final SupabaseService service;

  // Injected for tests; production resolves lazily so merely constructing the
  // gateway never touches the global Supabase singleton.
  final SupabaseClient? _injectedClient;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  static const String _table = 'directory_entities';

  static const List<String> _projection = <String>[
    'id',
    'name',
    'entity_type',
    'claim_status',
    'verification_status',
  ];

  @override
  bool get isAvailable => service.isInitialized;

  /// Whether a canonical authenticated session is currently active on the
  /// client. The claim candidates read only ever runs for an authenticated
  /// actor — the PostgREST query is NEVER executed as anon.
  bool get _hasAuthenticatedSession =>
      _client.auth.currentSession?.user != null;

  @override
  Future<List<BusinessClaimTarget>> listUnclaimedTargets() async {
    // Auth guard before the query: unauthenticated/unanonymous is the existing
    // typed "safely empty" result — no anon SELECT on directory_entities.
    if (!_hasAuthenticatedSession) {
      return const [];
    }
    final rows = await _client
        .from(_table)
        .select(_projection.join(','))
        .eq('claim_status', 'unclaimed')
        .order('name');
    final targets = <BusinessClaimTarget>[];
    for (final row in rows) {
      final parsed = BusinessClaimTarget.tryFromRow(row);
      // Defensive read-time reinforcement: only rows that still parse and are
      // canonically unclaimed are surfaced. RLS/trigger remain authoritative.
      if (parsed != null && parsed.isUnclaimed) {
        targets.add(parsed);
      }
    }
    return targets;
  }
}