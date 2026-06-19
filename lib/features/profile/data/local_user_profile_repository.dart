import 'dart:convert';
import '../domain/user_profile.dart';
import '../domain/user_profile_repository.dart';
import 'local_user_profile_data_source.dart';

class LocalUserProfileRepository implements UserProfileRepository {
  final LocalUserProfileDataSource _dataSource;

  LocalUserProfileRepository(this._dataSource);

  @override
  Future<LocalUserProfile?> loadProfile() async {
    final json = await _dataSource.read();
    if (json == null) return null;
    try {
      return LocalUserProfile.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveProfile(LocalUserProfile profile) async {
    final json = jsonEncode(profile.toJson());
    await _dataSource.write(json);
  }

  @override
  Future<void> clearProfile() async {
    await _dataSource.clear();
  }
}
