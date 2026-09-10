import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../domain/business_application.dart';
import '../domain/business_application_staff_gateway.dart';

/// A6.3/A6.4 — Production [BusinessApplicationStaffGateway] calling the
/// SECURITY DEFINER staff RPCs of migrations 00016 and 00018.
///
/// Every call goes through PostgREST RPC only — this file performs no direct
/// PostgREST table modification (`business_applications` update privilege is
/// revoked for `authenticated` by 00011). Authorization is server-side: each
/// RPC derives the actor from `auth.uid()` and requires a permission via
/// `staff_memberships` → `role_permissions` → `permissions.code`. The gateway
/// never accepts or forwards actor identity; the session is the sole identity.
///
/// The returned application row is the authoritative server state. Unknown
/// server failures are mapped to a typed cause; raw error text never reaches
/// the UI.
class SupabaseBusinessApplicationStaffGateway
    implements BusinessApplicationStaffGateway {
  SupabaseBusinessApplicationStaffGateway({
    required this.service,
    SupabaseClient? client,
  }) : _injectedClient = client;

  /// The backend boundary used to decide availability.
  final SupabaseService service;

  // Injected for tests; production resolves lazily so merely constructing the
  // gateway never touches the global Supabase singleton.
  final SupabaseClient? _injectedClient;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  @override
  bool get isAvailable => service.isInitialized;

  @override
  Future<BusinessApplicationStaffResult> beginReview(String applicationId) {
    return _callRpc('staff_begin_application_review', {
      'p_application_id': applicationId,
    });
  }

  @override
  Future<BusinessApplicationStaffResult> returnForCorrection(
    String applicationId, {
    required String reason,
  }) {
    return _callRpc('staff_return_application_for_correction', {
      'p_application_id': applicationId,
      'p_reason': reason,
    });
  }

  @override
  Future<BusinessApplicationStaffResult> markContacted(
    String applicationId, {
    required String contactType,
    String? result,
    String? notes,
  }) {
    return _callRpc('staff_mark_application_contacted', {
      'p_application_id': applicationId,
      'p_contact_type': contactType,
      if (result != null) 'p_result': result,
      if (notes != null) 'p_notes': notes,
    });
  }

  @override
  Future<BusinessApplicationStaffResult> scheduleVisit(
    String applicationId, {
    required DateTime scheduledAt,
    String? location,
    String? notes,
  }) {
    return _callRpc('staff_schedule_application_visit', {
      'p_application_id': applicationId,
      'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
      if (location != null) 'p_location': location,
      if (notes != null) 'p_notes': notes,
    });
  }

  @override
  Future<BusinessApplicationStaffResult> approve(String applicationId) {
    return _callRpc('staff_approve_business_application', {
      'p_application_id': applicationId,
    });
  }

  @override
  Future<BusinessApplicationStaffResult> activate(String applicationId) {
    return _callRpc('staff_activate_business_application', {
      'p_application_id': applicationId,
    });
  }

  @override
  Future<BusinessApplicationStaffResult> reject(
    String applicationId, {
    required String reason,
  }) {
    return _callRpc('staff_reject_business_application', {
      'p_application_id': applicationId,
      'p_reason': reason,
    });
  }

  Future<BusinessApplicationStaffResult> _callRpc(
    String rpcName,
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _client.rpc(rpcName, params: params);
      if (response is! Map<String, dynamic>) {
        return const BusinessApplicationStaffDenied(
          BusinessApplicationStaffCause.unexpected,
        );
      }
      final parsed = BusinessApplication.tryFromRow(response);
      if (parsed == null) {
        return const BusinessApplicationStaffDenied(
          BusinessApplicationStaffCause.unexpected,
        );
      }
      return BusinessApplicationStaffSucceeded(parsed);
    } on PostgrestException catch (e) {
      return BusinessApplicationStaffDenied(
        BusinessApplicationStaffCause.fromServerCode(e.code),
      );
    } catch (_) {
      return const BusinessApplicationStaffDenied(
        BusinessApplicationStaffCause.unexpected,
      );
    }
  }
}
