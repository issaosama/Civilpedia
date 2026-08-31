import '../../profile/domain/service_business_profile.dart';

/// Canonical Directory-domain repository boundary.
///
/// W5.1 — establishes the Directory-owned repository abstraction so future
/// Directory code depends on this contract rather than reaching into
/// `sb_profiles` / SharedPreferences directly. The compatibility
/// implementation wraps the legacy `ServiceBusinessRepository` / `businessRepo`
/// underneath, preserving ONE underlying persistence truth.
///
/// The entity contract is [ServiceBusinessProfile] (kept where it lives and
/// NOT duplicated). These are the minimal operations required by W5.1; no
/// query/search/filter APIs are added here (W5.3 owns search/filter).
abstract class DirectoryRepository {
  /// Returns every stored provider, in persisted order. Unknown/missing
  /// values resolve exactly as the legacy repository defines.
  Future<List<ServiceBusinessProfile>> loadAll();

  /// Returns the provider with [id], or null if none matches.
  Future<ServiceBusinessProfile?> loadById(String id);

  /// Persists [profile] through the compatibility path (upsert by id).
  Future<void> save(ServiceBusinessProfile profile);

  /// Removes the provider with [id], if present.
  Future<void> delete(String id);

  /// Clears all provider data.
  Future<void> clearAll();
}
