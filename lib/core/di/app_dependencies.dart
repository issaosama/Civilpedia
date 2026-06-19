import '../../features/encyclopedia/data/datasources/encyclopedia_local_datasource.dart';
import '../../features/encyclopedia/data/repositories/encyclopedia_repository_impl.dart';
import '../../features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import '../../features/profile/data/local_user_profile_data_source.dart';
import '../../features/profile/data/local_user_profile_repository.dart';
import '../../features/profile/domain/user_profile_repository.dart';

class AppDependencies {
  AppDependencies._();

  static late final EncyclopediaLocalDataSource _encyclopediaDataSource;
  static late final EncyclopediaRepository _encyclopediaRepo;

  static late final LocalUserProfileDataSource _userProfileDataSource;
  static late final UserProfileRepository _userProfileRepo;

  static Future<void> init() async {
    _encyclopediaDataSource = EncyclopediaLocalDataSource();
    _encyclopediaRepo = EncyclopediaRepositoryImpl(_encyclopediaDataSource);

    _userProfileDataSource = LocalUserProfileDataSource();
    _userProfileRepo = LocalUserProfileRepository(_userProfileDataSource);
  }

  static EncyclopediaRepository get encyclopediaRepo => _encyclopediaRepo;

  static UserProfileRepository get userProfileRepo => _userProfileRepo;
}
