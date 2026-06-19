import 'service_business_profile.dart';

abstract class ServiceBusinessRepository {
  Future<List<ServiceBusinessProfile>> loadAll();
  Future<ServiceBusinessProfile?> loadById(String id);
  Future<void> save(ServiceBusinessProfile profile);
  Future<void> delete(String id);
  Future<void> clearAll();
}
