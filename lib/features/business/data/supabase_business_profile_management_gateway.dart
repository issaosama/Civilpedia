import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../domain/business_profile_management_gateway.dart';
import '../domain/managed_business_profile.dart';
import '../domain/managed_business_profile_draft.dart';
import '../domain/managed_selectable_options.dart';

/// V1-R06 — Production [BusinessProfileManagementGateway] backed by the shared
/// Supabase client.
///
/// Reads and writes use ONLY the two narrow SECURITY DEFINER RPCs from
/// migration 00020 (`get_managed_business_profile`,
/// `update_managed_business_profile`); identity comes from the authenticated
/// session and business authority from `business_memberships` — never from
/// client-supplied user/owner ids. This gateway exposes NO direct table write
/// path and NO `service_role`.
///
/// Taxonomy lookups (`directory_categories`, `regions`) are read-only SELECTs
/// filtered to `is_active = true` under the existing public RLS policies.
class SupabaseBusinessProfileManagementGateway
    implements BusinessProfileManagementGateway {
  SupabaseBusinessProfileManagementGateway({
    required this.service,
    SupabaseClient? client,
  }) : _injectedClient = client;

  final SupabaseService service;
  final SupabaseClient? _injectedClient;

  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  static const String _readRpc = 'get_managed_business_profile';
  static const String _updateRpc = 'update_managed_business_profile';

  @override
  bool get isAvailable => service.isInitialized;

  @override
  Future<ManagedProfileReadResult> readManagedProfile(String entityId) async {
    if (!isAvailable) return const ManagedProfileReadUnavailable();
    if (!ManagedBusinessProfile.isValidUuid(entityId)) {
      return const ManagedProfileReadDenied(
        BusinessProfileManagementCause.unexpected,
      );
    }
    try {
      final response = await _client.rpc(
        _readRpc,
        params: <String, dynamic>{'p_entity_id': entityId},
      );
      final projection = _decodeSingleProjection(response);
      if (projection == null) {
        return const ManagedProfileReadDenied(
          BusinessProfileManagementCause.unexpected,
        );
      }
      final profile = ManagedBusinessProfile.tryFromJson(projection);
      if (profile == null) {
        return const ManagedProfileReadDenied(
          BusinessProfileManagementCause.unexpected,
        );
      }
      return ManagedProfileReadSuccess(profile);
    } on PostgrestException catch (error) {
      return ManagedProfileReadDenied(
        BusinessProfileManagementCause.fromServerCode(error.code),
      );
    } catch (_) {
      return const ManagedProfileReadDenied(
        BusinessProfileManagementCause.network,
      );
    }
  }

  @override
  Future<ManagedProfileUpdateResult> updateManagedProfile({
    required String entityId,
    required DateTime expectedUpdatedAt,
    required ManagedBusinessProfileDraft draft,
  }) async {
    if (!isAvailable) {
      return const ManagedProfileUpdateDenied(
        BusinessProfileManagementCause.unavailable,
      );
    }
    if (!ManagedBusinessProfile.isValidUuid(entityId)) {
      return const ManagedProfileUpdateDenied(
        BusinessProfileManagementCause.invalidData,
      );
    }
    try {
      final description = draft.description?.trim();
      final location = draft.primaryLocation;
      final response = await _client.rpc(
        _updateRpc,
        params: <String, dynamic>{
          'p_entity_id': entityId,
          'p_expected_updated_at':
              expectedUpdatedAt.toUtc().toIso8601String(),
          'p_name': draft.name.trim(),
          'p_description':
              (description == null || description.isEmpty) ? null : description,
          'p_contacts': [
            for (final contact in draft.contacts)
              <String, dynamic>{
                'contact_type': contact.type.code,
                'value': contact.value.trim(),
                'is_primary': contact.isPrimary,
              },
          ],
          'p_primary_location': (location == null || location.isEmpty)
              ? null
              : <String, dynamic>{
                  'region_id': location.regionId,
                  'address':
                      (location.address?.trim().isEmpty ?? true)
                          ? null
                          : location.address!.trim(),
                  'latitude': location.latitude,
                  'longitude': location.longitude,
                },
          'p_categories': [
            for (final category in draft.categories)
              <String, dynamic>{
                'category_id': category.categoryId,
                'is_primary': category.isPrimary,
              },
          ],
        },
      );
      final projection = _decodeSingleProjection(response);
      if (projection == null) {
        return const ManagedProfileUpdateDenied(
          BusinessProfileManagementCause.unexpected,
        );
      }
      final profile = ManagedBusinessProfile.tryFromJson(projection);
      if (profile == null) {
        return const ManagedProfileUpdateDenied(
          BusinessProfileManagementCause.unexpected,
        );
      }
      return ManagedProfileUpdateSuccess(profile);
    } on PostgrestException catch (error) {
      return ManagedProfileUpdateDenied(
        BusinessProfileManagementCause.fromServerCode(error.code),
      );
    } catch (_) {
      return const ManagedProfileUpdateDenied(
        BusinessProfileManagementCause.network,
      );
    }
  }

  @override
  Future<List<ManagedSelectableCategory>> loadActiveCategories() async {
    if (!isAvailable) {
      throw StateError('Business profile management gateway is not available');
    }
    final rows = await _client
        .from('directory_categories')
        .select('id, parent_category_id, code, name_ar, name_en, is_active')
        .eq('is_active', true);
    final result = <ManagedSelectableCategory>[];
    for (final row in rows) {
      final parsed = ManagedSelectableCategory.tryFromRow(row);
      if (parsed != null) result.add(parsed);
    }
    return result;
  }

  @override
  Future<List<ManagedSelectableRegion>> loadActiveRegions() async {
    if (!isAvailable) {
      throw StateError('Business profile management gateway is not available');
    }
    final rows = await _client
        .from('regions')
        .select(
          'id, parent_id, code, region_type, name_ar, name_en, is_active',
        )
        .eq('is_active', true);
    final result = <ManagedSelectableRegion>[];
    for (final row in rows) {
      final parsed = ManagedSelectableRegion.tryFromRow(row);
      if (parsed != null) result.add(parsed);
    }
    return result;
  }

  /// Decodes the frozen READ/UPDATE RPC jsonb projection.
  ///
  /// PostgREST may return a single jsonb object directly or a one-row table
  /// list depending on the endpoint version; this defensive decode accepts
  /// both and then lets the strict parser decide (fail closed on malformed
  /// shapes).
  static Map<String, dynamic>? _decodeSingleProjection(dynamic response) {
    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      if (map['entity'] is Map) return map;
      return map;
    }
    if (response is List) {
      if (response.length != 1) return null;
      return _decodeSingleProjection(response.first);
    }
    return null;
  }
}