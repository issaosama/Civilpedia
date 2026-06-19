import '../../features/encyclopedia/data/datasources/encyclopedia_local_datasource.dart';
import '../../features/encyclopedia/data/repositories/encyclopedia_repository_impl.dart';
import '../../features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import '../../features/profile/data/local_user_profile_data_source.dart';
import '../../features/profile/data/local_user_profile_repository.dart';
import '../../features/profile/data/local_service_business_repository.dart';
import '../../features/profile/data/service_business_data_source.dart';
import '../../features/profile/domain/user_profile_repository.dart';
import '../../features/profile/domain/service_business_repository.dart';

class AppDependencies {
  AppDependencies._();

  static late final EncyclopediaLocalDataSource _encyclopediaDataSource;
  static late final EncyclopediaRepository _encyclopediaRepo;

  static late final LocalUserProfileDataSource _userProfileDataSource;
  static late final UserProfileRepository _userProfileRepo;

  static late final ServiceBusinessDataSource _businessDataSource;
  static late final ServiceBusinessRepository _businessRepo;

  static Future<void> init() async {
    _encyclopediaDataSource = EncyclopediaLocalDataSource();
    _encyclopediaRepo = EncyclopediaRepositoryImpl(_encyclopediaDataSource);

    _userProfileDataSource = LocalUserProfileDataSource();
    _userProfileRepo = LocalUserProfileRepository(_userProfileDataSource);

    _businessDataSource = ServiceBusinessDataSource();
    _businessRepo = LocalServiceBusinessRepository(_businessDataSource);
  }

  static EncyclopediaRepository get encyclopediaRepo => _encyclopediaRepo;

  static UserProfileRepository get userProfileRepo => _userProfileRepo;

  static ServiceBusinessRepository get businessRepo => _businessRepo;
}
