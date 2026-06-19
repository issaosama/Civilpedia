import 'user_profile.dart';

abstract class UserProfileRepository {
  Future<LocalUserProfile?> loadProfile();
  Future<void> saveProfile(LocalUserProfile profile);
  Future<void> clearProfile();
}
