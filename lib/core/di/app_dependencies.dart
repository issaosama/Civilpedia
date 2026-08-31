import 'package:path_provider/path_provider.dart';

import '../../features/directory/data/sb_profiles_directory_repository.dart';
import '../../features/directory/domain/directory_repository.dart';
import '../../features/encyclopedia/data/datasources/encyclopedia_json_datasource.dart';
import '../../features/encyclopedia/data/datasources/encyclopedia_local_datasource.dart';
import '../../features/encyclopedia/data/repositories/encyclopedia_repository_impl.dart';
import '../../features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import '../../features/profile/data/local_user_profile_data_source.dart';
import '../../features/profile/data/local_user_profile_repository.dart';
import '../../features/profile/data/local_service_business_repository.dart';
import '../../features/profile/data/service_business_data_source.dart';
import '../../features/profile/domain/user_profile_repository.dart';
import '../../features/profile/domain/service_business_repository.dart';
import '../../features/tools/data/checklist/checklist_local_data_source.dart';
import '../../features/tools/data/checklist/local_checklist_repository.dart';
import '../../features/tools/data/checklist/local_project_repository.dart';
import '../../features/tools/data/checklist/project_local_data_source.dart';
import '../../features/tools/domain/checklist/checklist_repository.dart';
import '../../features/tools/domain/checklist/project_repository.dart';
import '../backup/backup_file_service.dart';
import '../backup/backup_service.dart';

class AppDependencies {
  AppDependencies._();

  static late final EncyclopediaLocalDataSource _encyclopediaDataSource;
  static late final EncyclopediaJsonDataSource _encyclopediaJsonDataSource;
  static late final EncyclopediaRepository _encyclopediaRepo;

  static late final LocalUserProfileDataSource _userProfileDataSource;
  static late final UserProfileRepository _userProfileRepo;

  static late final ServiceBusinessDataSource _businessDataSource;
  static late final ServiceBusinessRepository _businessRepo;
  static late final DirectoryRepository _directoryRepo;

  static late final ChecklistLocalDataSource _checklistDataSource;
  static late final ChecklistRepository _checklistRepo;

  static late final ProjectLocalDataSource _projectDataSource;
  static late final ProjectRepository _projectRepo;

  static late final BackupFileService _backupFileService;
  static late final BackupService _backupService;

  static Future<void> init() async {
    _encyclopediaDataSource = EncyclopediaLocalDataSource();
    _encyclopediaJsonDataSource = EncyclopediaJsonDataSource();
    _encyclopediaRepo = EncyclopediaRepositoryImpl(
      _encyclopediaJsonDataSource,
      _encyclopediaDataSource,
    );

    _userProfileDataSource = LocalUserProfileDataSource();
    _userProfileRepo = LocalUserProfileRepository(_userProfileDataSource);

    _businessDataSource = ServiceBusinessDataSource();
    _businessRepo = LocalServiceBusinessRepository(_businessDataSource);
    _directoryRepo = SbProfilesDirectoryRepository(businessRepo: _businessRepo);

    _checklistDataSource = ChecklistLocalDataSource();
    _checklistRepo = LocalChecklistRepository(_checklistDataSource);

    _projectDataSource = ProjectLocalDataSource();
    _projectRepo = LocalProjectRepository(_projectDataSource);

    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = '${docsDir.path}/backups';
    _backupFileService = BackupFileService(backupDir);
    _backupService = BackupService(
      userProfileRepo: _userProfileRepo,
      checklistRepo: _checklistRepo,
      projectRepo: _projectRepo,
      fileService: _backupFileService,
    );
  }

  static EncyclopediaRepository get encyclopediaRepo => _encyclopediaRepo;

  static UserProfileRepository get userProfileRepo => _userProfileRepo;

  static ServiceBusinessRepository get businessRepo => _businessRepo;

  static DirectoryRepository get directoryRepo => _directoryRepo;

  static ChecklistRepository get checklistRepo => _checklistRepo;

  static ProjectRepository get projectRepo => _projectRepo;

  static BackupService get backupService => _backupService;

  static BackupFileService get backupFileService => _backupFileService;
}
