import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../../../core/network/remote_operation_policy.dart';
import '../domain/business_application.dart';
import '../domain/business_application_gateway.dart';
import '../domain/business_application_policy.dart';
import '../domain/business_membership_gateway.dart';
import '../domain/business_remote_read.dart';
import 'business_remote_read_classifier.dart';

/// A6.3.1 — Production [BusinessApplicationGateway] backed by the shared
/// Supabase client.
///
/// Table mutation privileges are closed for `authenticated`: INSERT and UPDATE
/// are revoked, and DELETE was never granted. Creation and lifecycle mutations
/// use narrow SECURITY DEFINER RPCs; this gateway exposes no generic table
/// insert/update/delete path and never uses service_role.
///
/// Server-authorized RPCs:
/// * creation (00017): `create_new_business_application` /
///   `create_claim_business_application`;
/// * lifecycle (00016): `submit_business_application` /
///   `resubmit_business_application`.
/// Applicant identity is derived by each RPC from `auth.uid()` and is never
/// sent as a parameter.
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
    this.readTimeout = RemoteOperationPolicy.read,
  }) : _injectedClient = client;

  /// The backend boundary used to decide availability.
  final SupabaseService service;

  /// Read-only membership boundary used for claim-ownership checks. Optional
  /// so a build without a configured backend stays safely inert.
  final BusinessMembershipGateway? membershipGateway;
  final Duration readTimeout;

  // Injected for tests; production resolves lazily so merely constructing the
  // gateway never touches the global Supabase singleton.
  final SupabaseClient? _injectedClient;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  static const String _table = 'business_applications';

  @override
  bool get isAvailable => service.isInitialized;

  @override
  Future<List<BusinessApplication>> listOwnApplications(String userId) async {
    if (!isAvailable) {
      throw const BusinessRemoteReadException(
        BusinessRemoteReadFailureKind.serviceUnavailable,
      );
    }
    try {
      final rows = await runWithRemoteDeadline(
        _client.from(_table).select().eq('applicant_user_id', userId),
        timeout: readTimeout,
      );
      final applications = <BusinessApplication>[];
      for (final row in rows) {
        final parsed = _tryParseAuthoritativeReadRow(row);
        // A row outside the requested actor or a malformed required row is a
        // complete-response failure, never a silently reduced list.
        if (parsed == null || !parsed.belongsTo(userId)) {
          throw const BusinessRemoteReadException(
            BusinessRemoteReadFailureKind.malformedResponse,
          );
        }
        applications.add(parsed);
      }
      applications.sort((a, b) {
        final byTime = b.createdAt.compareTo(a.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
      return List.unmodifiable(applications);
    } catch (error) {
      throwBusinessRemoteReadFailure(error);
    }
  }

  @override
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  ) async {
    if (!isAvailable) {
      throw const BusinessRemoteReadException(
        BusinessRemoteReadFailureKind.serviceUnavailable,
      );
    }
    try {
      final row = await runWithRemoteDeadline(
        _client
            .from(_table)
            .select()
            .eq('applicant_user_id', userId)
            .eq('id', applicationId)
            .maybeSingle(),
        timeout: readTimeout,
      );
      if (row == null) return null;
      final parsed = _tryParseAuthoritativeReadRow(row);
      if (parsed == null ||
          parsed.id != applicationId ||
          !parsed.belongsTo(userId)) {
        throw const BusinessRemoteReadException(
          BusinessRemoteReadFailureKind.malformedResponse,
        );
      }
      return parsed;
    } catch (error) {
      throwBusinessRemoteReadFailure(error);
    }
  }

  /// P2-D authoritative application reads require both server timestamps.
  ///
  /// The shared domain parser remains permissive for historical synthetic and
  /// mutation paths; this read boundary must not fabricate remote timestamps.
  static BusinessApplication? _tryParseAuthoritativeReadRow(
    Map<String, dynamic> row,
  ) {
    final createdAt = row['created_at'];
    final updatedAt = row['updated_at'];
    if (createdAt is! String ||
        updatedAt is! String ||
        DateTime.tryParse(createdAt) == null ||
        DateTime.tryParse(updatedAt) == null) {
      return null;
    }
    return BusinessApplication.tryFromRow(row);
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

    try {
      final row = await _client.rpc(
        'create_new_business_application',
        params: <String, dynamic>{
          'p_metadata': metadata == null || metadata.isEmpty ? null : metadata,
        },
      );
      if (row is! Map<String, dynamic>) {
        throw const PostgrestException(
          message: 'Created application row could not be parsed',
        );
      }
      final application = BusinessApplication.tryFromRow(row);
      if (application == null) {
        throw const PostgrestException(
          message: 'Created application row could not be parsed',
        );
      }
      return BusinessApplicationCreated(application);
    } on PostgrestException catch (e) {
      switch (e.code?.toUpperCase()) {
        case 'P0AUT':
          return const BusinessApplicationCreateDenied(
            BusinessApplicationRejectionCause.guestUser,
          );
        case 'P0DAT':
          return const BusinessApplicationCreateDenied(
            BusinessApplicationRejectionCause.invalidMetadata,
          );
        default:
          rethrow;
      }
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

    try {
      final row = await _client.rpc(
        'create_claim_business_application',
        params: <String, dynamic>{'p_target_entity_id': targetEntityId},
      );
      if (row is! Map<String, dynamic>) {
        throw const PostgrestException(
          message: 'Created application row could not be parsed',
        );
      }
      final application = BusinessApplication.tryFromRow(row);
      if (application == null) {
        throw const PostgrestException(
          message: 'Created application row could not be parsed',
        );
      }
      return BusinessApplicationCreated(application);
    } on PostgrestException catch (e) {
      switch (e.code?.toUpperCase()) {
        case 'P0AUT':
          return const BusinessApplicationCreateDenied(
            BusinessApplicationRejectionCause.guestUser,
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
        case 'P0DAT':
          return const BusinessApplicationCreateDenied(
            BusinessApplicationRejectionCause.missingTarget,
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
      final response = await _client.rpc(
        rpcName,
        params: {'p_application_id': application.id},
      );
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
