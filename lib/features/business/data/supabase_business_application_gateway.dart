import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../domain/business_application.dart';
import '../domain/business_application_gateway.dart';
import '../domain/business_application_policy.dart';
import '../domain/business_application_type.dart';
import '../domain/business_membership_gateway.dart';

/// A6.3 — Production [BusinessApplicationGateway] backed by the shared Supabase
/// client's PostgREST `business_applications` table.
///
/// RLS contract preserved exactly (00010/00011): SELECT own + INSERT own with
/// `WITH CHECK applicant_user_id = auth.uid()`; UPDATE is REVOKED. This
/// gateway exposes NO update/delete path and never uses service_role.
///
/// Mutations are server-authorized RPCs (migration 00016) only:
///   `submit_business_application` / `resubmit_business_application`.
/// This file performs no direct PostgREST table modification for transitions.
///
/// Claim safety is enforced in three layers:
/// * domain policy ([BusinessApplicationPolicy]) using the current user's OWN
///   memberships and OWN applications (authorized own-reads) — UX prechecks;
/// * authoritative DB backstops (migration 00014) mapped to typed rejections:
///     - partial unique index uq_business_applications_live_claim → 23505
///       (concurrent duplicate live claim),
///     - BEFORE INSERT trigger guard_claim_application_insert → P0CLM
///       (target exists but claim_status is not 'unclaimed');
/// * existing FK / RLS signals: 23503 (target missing) and 42501 (applicant
///   mismatch).
/// Race conditions are therefore resolved by the database, not the client.
class SupabaseBusinessApplicationGateway implements BusinessApplicationGateway {
  SupabaseBusinessApplicationGateway({
    required this.service,
    this.membershipGateway,
    SupabaseClient? client,
  }) : _injectedClient = client;

  /// The backend boundary used to decide availability.
  final SupabaseService service;

  /// Read-only membership boundary used for claim-ownership checks. Optional
  /// so a build without a configured backend stays safely inert.
  final BusinessMembershipGateway? membershipGateway;

  // Injected for tests; production resolves lazily so merely constructing the
  // gateway never touches the global Supabase singleton.
  final SupabaseClient? _injectedClient;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  static const String _table = 'business_applications';

  @override
  bool get isAvailable => service.isInitialized;

  @override
  Future<List<BusinessApplication>> listOwnApplications(String userId) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('applicant_user_id', userId);
    final applications = <BusinessApplication>[];
    for (final row in rows) {
      final parsed = BusinessApplication.tryFromRow(row);
      // Defensive own-read reinforcement; RLS is the authoritative backstop.
      if (parsed != null && parsed.belongsTo(userId)) {
        applications.add(parsed);
      }
    }
    applications.sort((a, b) {
      final byTime = b.createdAt.compareTo(a.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return applications;
  }

  @override
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  ) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('applicant_user_id', userId)
        .eq('id', applicationId)
        .maybeSingle();
    if (row == null) return null;
    final parsed = BusinessApplication.tryFromRow(row);
    if (parsed == null || !parsed.belongsTo(userId)) return null;
    return parsed;
  }

  @override
  Future<BusinessApplicationCreateResult> createNewDraft({
    required String currentUserId,
    Map<String, dynamic>? metadata,
  }) async {
    final decision = BusinessApplicationPolicy.evaluateNew(
      currentUserId: currentUserId,
    );
    if (decision is BusinessApplicationPolicyDenied) {
      return BusinessApplicationCreateDenied(decision.cause);
    }

    final payload = <String, dynamic>{
      'applicant_user_id': currentUserId,
      'application_type': BusinessApplicationType.newApplication.code,
      'status': 'DRAFT',
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    };

    try {
      final row = await _client
          .from(_table)
          .insert(payload)
          .select()
          .single();
      final application = BusinessApplication.tryFromRow(row);
      if (application == null) {
        throw const PostgrestException(
          message: 'Inserted application row could not be parsed',
        );
      }
      return BusinessApplicationCreated(application);
    } on PostgrestException catch (e) {
      // 42501 = row-level security violation: the supplied applicant_user_id
      // is not the authenticated session user. The caller supplied a different
      // id (or no valid session) → fail closed.
      if (e.code == '42501') {
        return const BusinessApplicationCreateDenied(
          BusinessApplicationRejectionCause.applicantMismatch,
        );
      }
      rethrow;
    }
  }

  @override
  Future<BusinessApplicationCreateResult> createClaimDraft({
    required String currentUserId,
    required String targetEntityId,
  }) async {
    final memberships =
        await membershipGateway?.listOwnMemberships(currentUserId) ?? const [];
    final ownApplications = await listOwnApplications(currentUserId);

    final decision = BusinessApplicationPolicy.evaluateClaim(
      currentUserId: currentUserId,
      targetEntityId: targetEntityId,
      memberships: memberships,
      ownApplications: ownApplications,
    );
    if (decision is BusinessApplicationPolicyDenied) {
      return BusinessApplicationCreateDenied(decision.cause);
    }

    final payload = <String, dynamic>{
      'applicant_user_id': currentUserId,
      'application_type': BusinessApplicationType.claim.code,
      'target_entity_id': targetEntityId,
      'status': 'DRAFT',
    };

    try {
      final row = await _client
          .from(_table)
          .insert(payload)
          .select()
          .single();
      final application = BusinessApplication.tryFromRow(row);
      if (application == null) {
        throw const PostgrestException(
          message: 'Inserted application row could not be parsed',
        );
      }
      return BusinessApplicationCreated(application);
    } on PostgrestException catch (e) {
      switch (e.code?.toUpperCase()) {
        case '42501':
          // Row-level security violation: supplied applicant_user_id is not
          // the authenticated session user → fail closed.
          return const BusinessApplicationCreateDenied(
            BusinessApplicationRejectionCause.applicantMismatch,
          );
        case '23503':
          // Foreign-key violation: the target entity does not exist (or the
          // referenced auth user does not). Deterministic fail-closed; also
          // covers a target that disappeared between precheck and insert.
          return const BusinessApplicationCreateDenied(
            BusinessApplicationRejectionCause.targetNotFound,
          );
        case '23505':
          // Unique violation on the authoritative partial index
          // uq_business_applications_live_claim (00014): a concurrent request
          // already holds a live (non-final) CLAIM for the same applicant +
          // target. Exactly one of the concurrent inserts wins.
          return const BusinessApplicationCreateDenied(
            BusinessApplicationRejectionCause.duplicateClaim,
          );
        case 'P0CLM':
          // Authoritative BEFORE INSERT trigger (00014): the target exists but
          // its canonical claim_status is not 'unclaimed' → not claimable.
          return const BusinessApplicationCreateDenied(
            BusinessApplicationRejectionCause.targetNotClaimable,
          );
        default:
          rethrow;
      }
    }
  }

  @override
  Future<BusinessApplicationSubmitResult> submitApplication(
    BusinessApplication application,
  ) {
    // Server-authorized RPC mutation (00016). UPDATE on business_applications
    // remains revoked for authenticated (00011); the client only names the
    // application id.
    return _callApplicantMutation(
      rpcName: 'submit_business_application',
      application: application,
    );
  }

  @override
  Future<BusinessApplicationSubmitResult> resubmitApplication(
    BusinessApplication application,
  ) {
    return _callApplicantMutation(
      rpcName: 'resubmit_business_application',
      application: application,
    );
  }

  Future<BusinessApplicationSubmitResult> _callApplicantMutation({
    required String rpcName,
    required BusinessApplication application,
  }) async {
    try {
      final response = await _client
          .rpc(rpcName, params: {'p_application_id': application.id});
      if (response is! Map<String, dynamic>) {
        return const BusinessApplicationSubmitDenied(
          BusinessApplicationSubmitCause.unexpected,
        );
      }
      final parsed = BusinessApplication.tryFromRow(response);
      if (parsed == null) {
        return const BusinessApplicationSubmitDenied(
          BusinessApplicationSubmitCause.unexpected,
        );
      }
      return BusinessApplicationSubmitted(parsed);
    } on PostgrestException catch (e) {
      // Deterministic custom SQLSTATE (00016) → typed cause. Unknown server
      // errors fail closed to `unexpected`; raw error text never reaches UI.
      return BusinessApplicationSubmitDenied(
        BusinessApplicationSubmitCause.fromServerCode(e.code),
      );
    } catch (_) {
      return const BusinessApplicationSubmitDenied(
        BusinessApplicationSubmitCause.unexpected,
      );
    }
  }
}