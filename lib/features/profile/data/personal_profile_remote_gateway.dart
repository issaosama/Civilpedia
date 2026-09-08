import 'cloud_profile.dart';

/// Thrown by [PersonalProfileRemoteGateway.createProfile] when an INSERT
/// fails because a row for the same `user_id` already exists (a concurrent
/// client won the race, or a duplicate already exists). The caller must
/// re-read the existing row and evaluate as an existing-cloud case.
class CloudProfileAlreadyExistsException implements Exception {
  const CloudProfileAlreadyExistsException();
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
  Future<CloudProfile?> fetchByUserId(String userId);

  /// Creates a new cloud profile row from [profile]. The caller guarantees
  /// the row does not exist yet.
  ///
  /// Throws [CloudProfileAlreadyExistsException] when the insert races an
  /// already-existing row, and any other [Exception] on a generic failure.
  Future<void> createProfile(CloudProfile profile);

  /// Single-column safe update of `profiles.region_preference_id` for
  /// [userId]. Used ONLY for the A5.8 conditional fill path (cloud
  /// `region_preference_id` NULL + a locally-selected preference). Never used
  /// to overwrite an existing cloud preference. A network failure MUST throw.
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  });
}
