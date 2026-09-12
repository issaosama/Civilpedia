import 'cloud_profile.dart';

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
  /// `region_preference_id` NULL + a locally-selected preference). Never used
  /// to overwrite an existing cloud preference. A network failure MUST throw.
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
  /// Throws [CloudProfilePermissionDeniedException] on RLS denial; any other
  /// failure is a retryable/permission condition the caller maps to a typed
  /// result.
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  });
}