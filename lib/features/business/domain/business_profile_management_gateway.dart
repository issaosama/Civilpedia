import 'managed_business_profile.dart';
import 'managed_business_profile_draft.dart';
import 'managed_selectable_options.dart';

/// V1-R06 — Typed management failures for the frozen server RPC contract
/// (migration 00020).
///
/// Server SQLSTATE bridging:
/// * P0AUT → [unauthenticated] — session/sign-in required;
/// * P0PER → [permissionDenied] — no OWNER/ADMIN management access;
/// * P0NOT → [notFound] — business unavailable/not found;
/// * P0DAT → [invalidData] — invalid profile data/reference;
/// * P0CON → [conflict] — stale optimistic-concurrency version;
/// * connectivity/backend failures → [network] / [unavailable];
/// * anything else → [unexpected] (production-safe generic error).
enum BusinessProfileManagementCause {
  unauthenticated,
  permissionDenied,
  notFound,
  invalidData,
  conflict,
  network,
  unavailable,
  unexpected;

  static BusinessProfileManagementCause fromServerCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'P0AUT':
        return BusinessProfileManagementCause.unauthenticated;
      case 'P0PER':
        return BusinessProfileManagementCause.permissionDenied;
      case 'P0NOT':
        return BusinessProfileManagementCause.notFound;
      case 'P0DAT':
        return BusinessProfileManagementCause.invalidData;
      case 'P0CON':
        return BusinessProfileManagementCause.conflict;
      default:
        return BusinessProfileManagementCause.unexpected;
    }
  }
}

/// Outcome of a management read (`get_managed_business_profile`).
sealed class ManagedProfileReadResult {
  const ManagedProfileReadResult();
}

/// The authoritative management projection was returned and parsed.
class ManagedProfileReadSuccess extends ManagedProfileReadResult {
  const ManagedProfileReadSuccess(this.profile);

  final ManagedBusinessProfile profile;
}

/// The server denied/failed the read with a typed cause.
class ManagedProfileReadDenied extends ManagedProfileReadResult {
  const ManagedProfileReadDenied(this.cause);

  final BusinessProfileManagementCause cause;
}

/// The backend is unavailable, so no management authority can be inferred.
class ManagedProfileReadUnavailable extends ManagedProfileReadResult {
  const ManagedProfileReadUnavailable();
}

/// Outcome of a management update (`update_managed_business_profile`).
sealed class ManagedProfileUpdateResult {
  const ManagedProfileUpdateResult();
}

/// The authoritative post-save projection was returned and parsed. The caller
/// MUST replace its management state with this value (server authority).
class ManagedProfileUpdateSuccess extends ManagedProfileUpdateResult {
  const ManagedProfileUpdateSuccess(this.profile);

  final ManagedBusinessProfile profile;
}

/// The server rejected/denied the mutation with a typed cause. The draft is
/// preserved for the user.
class ManagedProfileUpdateDenied extends ManagedProfileUpdateResult {
  const ManagedProfileUpdateDenied(this.cause);

  final BusinessProfileManagementCause cause;
}

/// V1-R06 — Read/mutation boundary for OWNER/ADMIN business-profile
/// management.
///
/// This seam is SEPARATE from the public Directory read authority
/// ([CloudDirectoryRepository]): it owns the narrow management RPCs and the
/// read-only taxonomy lookups. It exposes NO direct Directory table writes and
/// NO membership/taxonomy mutation.
///
/// The canonical identity for every method is `directory_entities.id`.
/// Authorization always comes from the server (`auth.uid()` +
/// `business_memberships`); UI capability checks are UX only.
abstract class BusinessProfileManagementGateway {
  /// Whether the backend is available such that management calls can run.
  /// False keeps the app safely unable to read or mutate.
  bool get isAvailable;

  /// Loads the OWNER/ADMIN management projection for [entityId]. The server
  /// remains the source of authorization even when the caller reaches the
  /// route directly (P0PER fails closed).
  Future<ManagedProfileReadResult> readManagedProfile(String entityId);

  /// Atomically saves the editable draft. [expectedUpdatedAt] MUST be the
  /// authoritative profile's `updated_at` at edit start (optimistic
  /// concurrency). The returned [ManagedProfileUpdateSuccess.profile] is the
  /// authoritative new projection.
  Future<ManagedProfileUpdateResult> updateManagedProfile({
    required String entityId,
    required DateTime expectedUpdatedAt,
    required ManagedBusinessProfileDraft draft,
  });

  /// Read-only ACTIVE canonical Directory category lookup
  /// (`directory_categories`). THROWS on a read/network failure so the caller
  /// can distinguish an authoritative empty catalog from an error.
  Future<List<ManagedSelectableCategory>> loadActiveCategories();

  /// Read-only ACTIVE physical region lookup (`regions`). THROWS on a
  /// read/network failure so the caller can distinguish an authoritative empty
  /// taxonomy from an error.
  Future<List<ManagedSelectableRegion>> loadActiveRegions();
}