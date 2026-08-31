import '../../profile/domain/service_business_profile.dart';
import '../../profile/domain/service_business_repository.dart';
import '../domain/directory_data_version.dart';
import '../domain/directory_repository.dart';

/// W5.1 compatibility wrapper over the legacy `sb_profiles` store.
///
/// This adapter implements [DirectoryRepository] by DELEGATING to the existing
/// [ServiceBusinessRepository] (`businessRepo`). It does NOT read
/// SharedPreferences directly, does NOT duplicate `sb_profiles`
/// serialization, and does NOT own a second physical store — so there is
/// exactly one underlying persistence truth (`sb_profiles`).
///
/// Version-awareness: the wrapped legacy source is interpreted internally as
/// [DirectoryDataVersion.v0]. This is bookkeeping only — no persisted envelope
/// conversion and no new schema-version key are written (read and write stay
/// byte-for-byte compatible with the legacy array shape).
class SbProfilesDirectoryRepository implements DirectoryRepository {
  final ServiceBusinessRepository _businessRepo;

  /// The compatibility source is always Legacy/V0 in W5.1.
  DirectoryDataVersion get sourceVersion => DirectoryDataVersion.v0;

  SbProfilesDirectoryRepository({
    required ServiceBusinessRepository businessRepo,
  }) : _businessRepo = businessRepo;

  @override
  Future<List<ServiceBusinessProfile>> loadAll() => _businessRepo.loadAll();

  @override
  Future<ServiceBusinessProfile?> loadById(String id) =>
      _businessRepo.loadById(id);

  @override
  Future<void> save(ServiceBusinessProfile profile) =>
      _businessRepo.save(profile);

  @override
  Future<void> delete(String id) => _businessRepo.delete(id);

  @override
  Future<void> clearAll() => _businessRepo.clearAll();
}
