import 'dart:convert';
import '../domain/service_business_profile.dart';
import '../domain/service_business_repository.dart';
import 'service_business_data_source.dart';

class LocalServiceBusinessRepository implements ServiceBusinessRepository {
  final ServiceBusinessDataSource _dataSource;

  LocalServiceBusinessRepository(this._dataSource);

  @override
  Future<List<ServiceBusinessProfile>> loadAll() async {
    final json = await _dataSource.read();
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => ServiceBusinessProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ServiceBusinessProfile?> loadById(String id) async {
    final all = await loadAll();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ServiceBusinessProfile profile) async {
    final all = await loadAll();
    final index = all.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      all[index] = profile;
    } else {
      all.add(profile);
    }
    await _writeAll(all);
  }

  @override
  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((p) => p.id == id);
    await _writeAll(all);
  }

  @override
  Future<void> clearAll() async {
    await _dataSource.clear();
  }

  Future<void> _writeAll(List<ServiceBusinessProfile> profiles) async {
    final json = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await _dataSource.write(json);
  }
}
