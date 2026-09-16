import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/remote_operation_policy.dart';
import 'cloud_profile.dart';

/// Profile request rejection, not proof that the SDK session was lost.
class CloudProfileAuthException implements Exception {
  const CloudProfileAuthException();
}

enum ProfileFailureKind {
  infrastructure,
  auth,
  permission,
  invalidData,
  malformed,
  unexpected,
}

/// P2-C1 — narrow failure taxonomy for authenticated profile READS.
///
/// This deliberately has no `offline` value: only the presentation layer may
/// promote a request-level [network] failure to confirmed offline after
/// consulting the canonical ConnectivityProvider.
enum ProfileReadFailureKind {
  network,
  timeout,
  serviceUnavailable,
  malformedResponse,
  permissionDenied,
  authRestricted,
  unexpected,
}

/// Classifies authenticated-profile reads without relying on raw error text.
///
/// PostgREST `code` is a PostgreSQL/PostgREST code, not an HTTP status. In
/// particular the literal value `503` is intentionally *not* considered proof
/// of temporary service unavailability.
ProfileReadFailureKind classifyProfileReadFailure(Object error) {
  if (error is CloudProfileAuthException ||
      error is AuthSessionMissingException ||
      error is AuthInvalidJwtException) {
    return ProfileReadFailureKind.authRestricted;
  }
  if (error is CloudProfilePermissionDeniedException) {
    return ProfileReadFailureKind.permissionDenied;
  }
  if (error is CloudProfileParseException ||
      error is FormatException ||
      error is TypeError) {
    return ProfileReadFailureKind.malformedResponse;
  }
  if (error is CloudProfileUnexpectedException) {
    return ProfileReadFailureKind.unexpected;
  }
  if (error is InfrastructureFailureException) {
    return switch (error.failure.kind) {
      InfrastructureFailureKind.offline ||
      InfrastructureFailureKind.network => ProfileReadFailureKind.network,
      InfrastructureFailureKind.timeout => ProfileReadFailureKind.timeout,
      InfrastructureFailureKind.serviceUnavailable =>
        ProfileReadFailureKind.serviceUnavailable,
      InfrastructureFailureKind.malformedResponse =>
        ProfileReadFailureKind.malformedResponse,
      InfrastructureFailureKind.unknown => ProfileReadFailureKind.unexpected,
    };
  }
  if (error is TimeoutException) return ProfileReadFailureKind.timeout;
  if (error is SocketException ||
      error is HandshakeException ||
      error is HttpException ||
      error is ClientException ||
      error is AuthRetryableFetchException) {
    return ProfileReadFailureKind.network;
  }
  if (error is AuthException) {
    return error.statusCode == '401'
        ? ProfileReadFailureKind.authRestricted
        : ProfileReadFailureKind.unexpected;
  }
  if (error is PostgrestException) {
    final code = error.code ?? '';
    if (const {'PGRST301', 'PGRST302', 'PGRST303', '401'}.contains(code)) {
      return ProfileReadFailureKind.authRestricted;
    }
    if (code == '42501') return ProfileReadFailureKind.permissionDenied;
    if (code.startsWith('08') ||
        code.startsWith('53') ||
        const {'PGRST000', 'PGRST001', 'PGRST002', 'PGRST003'}.contains(code)) {
      return ProfileReadFailureKind.serviceUnavailable;
    }
    if (code == '200' || code == '406' || code == 'PGRST116') {
      return ProfileReadFailureKind.malformedResponse;
    }
    return ProfileReadFailureKind.unexpected;
  }
  return switch (classifyInfrastructureFailure(error).kind) {
    InfrastructureFailureKind.offline ||
    InfrastructureFailureKind.network => ProfileReadFailureKind.network,
    InfrastructureFailureKind.timeout => ProfileReadFailureKind.timeout,
    InfrastructureFailureKind.serviceUnavailable =>
      ProfileReadFailureKind.serviceUnavailable,
    InfrastructureFailureKind.malformedResponse =>
      ProfileReadFailureKind.malformedResponse,
    InfrastructureFailureKind.unknown => ProfileReadFailureKind.unexpected,
  };
}

/// Converts any raw READ failure to a sanitized typed boundary exception.
/// Mutation/bootstrap classification remains owned by [throwProfileFailure].
Never throwProfileReadFailure(Object error) {
  switch (classifyProfileReadFailure(error)) {
    case ProfileReadFailureKind.network:
      throw const InfrastructureFailureException(
        InfrastructureFailure(InfrastructureFailureKind.network),
      );
    case ProfileReadFailureKind.timeout:
      throw const InfrastructureFailureException(
        InfrastructureFailure(InfrastructureFailureKind.timeout),
      );
    case ProfileReadFailureKind.serviceUnavailable:
      throw const InfrastructureFailureException(
        InfrastructureFailure(InfrastructureFailureKind.serviceUnavailable),
      );
    case ProfileReadFailureKind.malformedResponse:
      throw const CloudProfileParseException('Invalid profile response');
    case ProfileReadFailureKind.permissionDenied:
      throw const CloudProfilePermissionDeniedException();
    case ProfileReadFailureKind.authRestricted:
      throw const CloudProfileAuthException();
    case ProfileReadFailureKind.unexpected:
      throw const CloudProfileUnexpectedException();
  }
}

/// The deadline wrapper knows whether a timed-out raw write is still running.
/// A manual retry must not issue a competing mutation during that interval.
abstract interface class ProfileMutationSettlement {
  bool isProfileMutationPending(String userId);
}

/// An uncertain-write retry may fill an absent region, but cannot overwrite a
/// region installed after its preflight reread by another device/request.
abstract interface class ConditionalProfileRetryGateway {
  Future<void> saveEditableFieldsIfRegionAbsent({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  });
}

/// Shared C4 classification for lookup, read, mutation and bootstrap. Raw
/// messages are never used to infer authentication or transport failure.
ProfileFailureKind classifyProfileFailure(Object error) {
  if (error is CloudProfileAuthException) return ProfileFailureKind.auth;
  if (error is CloudProfilePermissionDeniedException)
    return ProfileFailureKind.permission;
  if (error is CloudProfileInvalidDataException ||
      error is CloudProfileAlreadyExistsException) {
    return ProfileFailureKind.invalidData;
  }
  if (error is CloudProfileParseException || error is FormatException)
    return ProfileFailureKind.malformed;
  if (error is CloudProfileUnexpectedException)
    return ProfileFailureKind.unexpected;
  if (error is PostgrestException) {
    // Public PostgREST JWT contract: errors.html#group-3-jwt. PGRST300 is
    // server configuration, not evidence of a rejected user session.
    if (const {'PGRST301', 'PGRST302', 'PGRST303', '401'}.contains(error.code))
      return ProfileFailureKind.auth;
    if (error.code == '42501') return ProfileFailureKind.permission;
    if (const {
          '23502',
          '23503',
          '23514',
          '23P01',
          '23505',
        }.contains(error.code) ||
        RegExp(r'^22[A-Z0-9]{3}$').hasMatch(error.code ?? ''))
      return ProfileFailureKind.invalidData;
    // postgrest 2.8.0 uses the HTTP status when no backend code is present.
    if (error.code == '503') return ProfileFailureKind.infrastructure;
    if (error.code == '200' || error.code == '406' || error.code == 'PGRST116')
      return ProfileFailureKind.malformed;
    return ProfileFailureKind.unexpected;
  }
  // Canonical GoTrue exceptions can escape token acquisition in the shared
  // SDK HTTP client. Retryable fetch failures are not auth rejection.
  if (error is AuthRetryableFetchException || error is ClientException)
    return ProfileFailureKind.infrastructure;
  if (error is AuthSessionMissingException || error is AuthInvalidJwtException)
    return ProfileFailureKind.auth;
  if (error is AuthException) {
    return error.statusCode == '401'
        ? ProfileFailureKind.auth
        : ProfileFailureKind.unexpected;
  }
  return switch (classifyInfrastructureFailure(error).kind) {
    InfrastructureFailureKind.offline ||
    InfrastructureFailureKind.network ||
    InfrastructureFailureKind.timeout ||
    InfrastructureFailureKind.serviceUnavailable =>
      ProfileFailureKind.infrastructure,
    InfrastructureFailureKind.malformedResponse => ProfileFailureKind.malformed,
    InfrastructureFailureKind.unknown => ProfileFailureKind.unexpected,
  };
}

Never throwProfileFailure(Object error) {
  switch (classifyProfileFailure(error)) {
    case ProfileFailureKind.auth:
      throw const CloudProfileAuthException();
    case ProfileFailureKind.permission:
      throw const CloudProfilePermissionDeniedException();
    case ProfileFailureKind.invalidData:
      throw const CloudProfileInvalidDataException();
    case ProfileFailureKind.malformed:
      throw const CloudProfileParseException('Invalid profile response');
    case ProfileFailureKind.unexpected:
      throw const CloudProfileUnexpectedException();
    case ProfileFailureKind.infrastructure:
      if (error is PostgrestException) {
        throw const InfrastructureFailureException(
          InfrastructureFailure(InfrastructureFailureKind.serviceUnavailable),
        );
      }
      throw error;
  }
}

/// Thrown by [PersonalProfileRemoteGateway.createProfile] when an INSERT
/// fails because a row for the same `user_id` already exists (a concurrent
/// client won the race, or a duplicate already exists). The caller must
/// re-read the existing row and evaluate as an existing-cloud case.
class CloudProfileAlreadyExistsException implements Exception {
  const CloudProfileAlreadyExistsException();
}

/// Thrown by [PersonalProfileRemoteGateway] when the backend denies a read or
/// write with a permission error (RLS). The caller must surface a typed
/// `permissionDenied` failure and never fabricate or mutate data.
class CloudProfilePermissionDeniedException implements Exception {
  const CloudProfilePermissionDeniedException();
}

/// F7 — thrown by [PersonalProfileRemoteGateway.createProfile] when the INSERT
/// genuinely fails to provision the canonical row for a provisioning-specific
/// reason (constraint/data violation, invalid payload, backend rejection).
///
/// Distinct from [CloudProfileAlreadyExistsException] (insert race) and
/// [CloudProfilePermissionDeniedException] (RLS); callers expose a typed
/// `provisioningFailure` and never surface the raw backend message.
class CloudProfileProvisioningException implements Exception {
  const CloudProfileProvisioningException();
}

/// Thrown by [PersonalProfileRemoteGateway.updateRegionPreferenceId] and
/// [PersonalProfileRemoteGateway.saveEditableFields] when the backend rejects
/// the mutation for a domain/data reason (constraint violation, invalid value,
/// duplicate on update). This is the UPDATE-time equivalent of an invalid-data
/// failure; it must NEVER be interpreted as a successful create/provision.
class CloudProfileInvalidDataException implements Exception {
  const CloudProfileInvalidDataException();
}

/// Thrown when the backend returns an unexpected SQLSTATE or otherwise
/// unclassifiable failure on a profile mutation/read. Callers map this to a
/// typed `unexpected` cause; the raw backend message is never surfaced.
class CloudProfileUnexpectedException implements Exception {
  const CloudProfileUnexpectedException();
}

/// A5.6 — Boundary to the Supabase `public.profiles` table.
///
/// Strictly narrow: read-own by canonical user id and create-own. It performs
/// NO network/business logic of its own and is the ONLY seam that touches the
/// profiles table (never called from widgets).
///
/// Implementations must be safe to fake in tests; the production implementation
/// talks to PostgREST via the shared Supabase client.
abstract class PersonalProfileRemoteGateway {
  /// Returns the cloud profile row for [userId], or null when none exists.
  /// A read/network failure MUST throw so the caller can treat it as a
  /// retryable offline/failure outcome without touching local data.
  ///
  /// May throw [CloudProfileParseException] when the row violates the strict
  /// schema contract, and [CloudProfilePermissionDeniedException] on RLS
  /// denial.
  Future<CloudProfile?> fetchByUserId(String userId);

  /// Creates a new cloud profile row from [profile]. The caller guarantees
  /// the row does not exist yet.
  ///
  /// Throws [CloudProfileAlreadyExistsException] when the insert races an
  /// already-existing row, [CloudProfilePermissionDeniedException] on RLS
  /// denial, and [CloudProfileProvisioningException] when the row cannot be
  /// provisioned for a provisioning-specific reason (F7). Any other
  /// [Exception] is a generic failure.
  Future<void> createProfile(CloudProfile profile);

  /// Single-column safe update of `profiles.region_preference_id` for
  /// [userId]. Used ONLY for the A5.8 conditional fill path (cloud
  /// `region_preference_id` NULL + a locally-selected preference). The backend
  /// predicate guarantees the column is currently NULL; an existing value is
  /// never overwritten.
  ///
  /// Throws [CloudProfilePermissionDeniedException] on RLS denial,
  /// [CloudProfileInvalidDataException] on a domain/constraint/data rejection
  /// (including UPDATE-time unique violation 23505), and
  /// [CloudProfileUnexpectedException] for an unclassifiable backend failure.
  /// Network/infrastructure failures are left for the caller's classifier.
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  });

  /// V1-R08 — the ONLY authenticated cloud mutation authored by the save
  /// foundation: writes `profiles.role_code` (always, canonical value only)
  /// and, when [regionPreferenceId] is non-null, `profiles.region_preference_id`.
  ///
  /// Never touches `display_name`, `photo_url`, `phone`, or the legacy
  /// `preferred_region_id`, and never clears `region_preference_id` (a null
  /// [regionPreferenceId] leaves the column untouched).
  ///
  /// Throws [CloudProfilePermissionDeniedException] on RLS denial,
  /// [CloudProfileInvalidDataException] on a domain/constraint/data rejection,
  /// and [CloudProfileUnexpectedException] for an unclassifiable backend
  /// failure. Network/infrastructure failures are left for the caller's
  /// classifier.
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  });
}
