import 'package:flutter/foundation.dart';
import '../../domain/user_profile.dart';
import '../../domain/user_profile_repository.dart';

class UserProfileProvider extends ChangeNotifier {
  final UserProfileRepository _repository;
  LocalUserProfile? _profile;
  bool _isLoaded = false;

  UserProfileProvider({required UserProfileRepository repository})
      : _repository = repository;

  LocalUserProfile? get profile => _profile;
  bool get isLoaded => _isLoaded;

  Future<void> loadProfile() async {
    _profile = await _repository.loadProfile();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> saveProfile(LocalUserProfile profile) async {
    await _repository.saveProfile(profile);
    _profile = profile;
    notifyListeners();
  }

  Future<void> clearProfile() async {
    await _repository.clearProfile();
    _profile = null;
    notifyListeners();
  }
}
