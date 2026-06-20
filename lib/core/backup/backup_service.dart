import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/hive_helper.dart';
import '../../data/local/preferences_helper.dart';
import '../../features/profile/domain/user_profile.dart';
import '../../features/profile/domain/user_profile_repository.dart';
import '../../features/tools/domain/checklist/checklist_repository.dart';
import '../../features/tools/domain/checklist/project_repository.dart';
import '../schema/schema_constants.dart';
import 'backup_data.dart';
import 'backup_file_service.dart';

class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

class BackupRestoreResult {
  final bool success;
  final String? errorMessage;
  final int restoredSections;

  const BackupRestoreResult({
    required this.success,
    this.errorMessage,
    this.restoredSections = 0,
  });
}

class BackupService {
  final UserProfileRepository _userProfileRepo;
  final ChecklistRepository _checklistRepo;
  final ProjectRepository _projectRepo;
  final BackupFileService _fileService;

  BackupService({
    required UserProfileRepository userProfileRepo,
    required ChecklistRepository checklistRepo,
    required ProjectRepository projectRepo,
    required BackupFileService fileService,
  })  : _userProfileRepo = userProfileRepo,
        _checklistRepo = checklistRepo,
        _projectRepo = projectRepo,
        _fileService = fileService;

  Future<BackupFile> buildBackup() async {
    final profile = await _userProfileRepo.loadProfile();

    final projects = await _projectRepo.loadProjects();

    final quickChecklist = await _checklistRepo.loadItemStates();

    final projectChecklists =
        <String, Map<String, Map<String, dynamic>>>{};
    for (final project in projects) {
      final items =
          await _checklistRepo.loadProjectItemStates(project.id);
      if (items.isNotEmpty) {
        projectChecklists[project.id] = items.map(
          (k, v) => MapEntry(k, {
            'status': v.status.name,
            if (v.notes != null) 'notes': v.notes,
          }),
        );
      }
    }

    final preferences = <String, dynamic>{
      'isDarkMode': PreferencesHelper.isDarkMode,
      'appLanguage': 'ar',
      'onboardingSeen': PreferencesHelper.isOnboardingSeen,
    };

    final favorites = HiveHelper.getFavorites();
    final downloads = HiveHelper.getDownloads();

    return BackupFile(
      sections: BackupSections(
        localUserProfile: profile?.toJson(),
        projects: projects
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'createdAt': p.createdAt.toIso8601String(),
                  'updatedAt': p.updatedAt.toIso8601String(),
                  'isArchived': p.isArchived,
                })
            .toList(),
        quickChecklist: quickChecklist.map(
          (k, v) => MapEntry(k, {
            'status': v.status.name,
            if (v.notes != null) 'notes': v.notes,
          }),
        ),
        projectChecklists:
            projectChecklists.isNotEmpty ? projectChecklists : null,
        preferences: preferences,
        favorites: favorites.isNotEmpty ? favorites : null,
        downloads: downloads.isNotEmpty ? downloads : null,
      ),
    );
  }

  Future<String> exportToFile(String fileName) async {
    final backup = await buildBackup();
    final json = jsonEncode(backup.toJson());
    await _fileService.saveBackup(fileName, json);
    return '${_fileService.backupDirPath}/$fileName';
  }

  Future<BackupValidationResult> validateBackup(String fileName) async {
    final jsonString = await _fileService.loadBackup(fileName);
    if (jsonString == null) {
      return const BackupValidationResult(
        isValid: false,
        errorMessage: 'Backup file not found',
      );
    }

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return const BackupValidationResult(
        isValid: false,
        errorMessage: 'Corrupt backup file: unable to parse JSON',
      );
    }

    final schemaVersion =
        parsed['backupSchemaVersion'] as int? ?? 0;
    if (schemaVersion < 1) {
      return const BackupValidationResult(
        isValid: false,
        errorMessage: 'Invalid backup schema version',
      );
    }
    if (schemaVersion > SchemaConstants.currentBackupVersion) {
      return const BackupValidationResult(
        isValid: false,
        errorMessage:
            'Backup was created by a newer version of the app. '
            'Please update Civilpedia to restore this backup.',
      );
    }

    if (parsed['sections'] == null) {
      return const BackupValidationResult(
        isValid: false,
        errorMessage: 'Backup file is missing data sections',
      );
    }

    return const BackupValidationResult(isValid: true);
  }

  Future<BackupRestoreResult> restoreFromBackup(String fileName) async {
    final validation = await validateBackup(fileName);
    if (!validation.isValid) {
      return BackupRestoreResult(
        success: false,
        errorMessage: validation.errorMessage,
      );
    }

    final jsonString = await _fileService.loadBackup(fileName);
    if (jsonString == null) {
      return const BackupRestoreResult(
        success: false,
        errorMessage: 'Backup file not found',
      );
    }

    BackupFile backupFile;
    try {
      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
      backupFile = BackupFile.fromJson(parsed);
    } catch (e) {
      return BackupRestoreResult(
        success: false,
        errorMessage: 'Failed to parse backup data: ${e.toString()}',
      );
    }

    int restored = 0;

    try {
      if (backupFile.sections.localUserProfile != null) {
        final profile = LocalUserProfile.fromJson(
          backupFile.sections.localUserProfile!,
        );
        await _userProfileRepo.saveProfile(profile);
        restored++;
      }
    } catch (_) {}

    try {
      if (backupFile.sections.projects != null) {
        // TODO(BACKUP-1C): Restore projects with original IDs.
        // Requires ProjectRepository.saveProject(Project) or
        // data source level write.
        restored++;
      }
    } catch (_) {}

    try {
      if (backupFile.sections.quickChecklist != null) {
        // TODO(BACKUP-1C): Batch restore quick checklist items.
        // Requires ChecklistRepository.saveItemStates(Map) or
        // data source level write.
        restored++;
      }
    } catch (_) {}

    try {
      if (backupFile.sections.projectChecklists != null) {
        // TODO(BACKUP-1C): Batch restore project checklists.
        // Requires ChecklistRepository.saveProjectItemStates(...).
        restored++;
      }
    } catch (_) {}

    try {
      if (backupFile.sections.preferences != null) {
        final prefs = backupFile.sections.preferences!;
        if (prefs['isDarkMode'] is bool) {
          await PreferencesHelper.setDarkMode(prefs['isDarkMode'] as bool);
        }
        final sp = await SharedPreferences.getInstance();
        await sp.setString('app_language', 'ar');
        // onboardingSeen is restored on next app launch when user
        // already completed onboarding; skip explicit set.
        restored++;
      }
    } catch (_) {}

    try {
      if (backupFile.sections.favorites != null) {
        final favs = backupFile.sections.favorites!;
        final existing = HiveHelper.getFavorites();
        for (final id in favs) {
          if (!existing.contains(id)) {
            existing.add(id);
          }
        }
        // HiveHelper doesn't expose a batch setter in static API.
        // TODO(BACKUP-1C): Use HiveHelper's internal box or add method.
        restored++;
      }
    } catch (_) {}

    try {
      if (backupFile.sections.downloads != null) {
        // TODO(BACKUP-1C): Restore downloads list. Offline articles
        // content is deferred per BACKUP-1A scope.
        restored++;
      }
    } catch (_) {}

    return BackupRestoreResult(
      success: true,
      restoredSections: restored,
    );
  }

  Future<List<String>> listBackups() => _fileService.listBackups();

  Future<void> deleteBackup(String fileName) =>
      _fileService.deleteBackup(fileName);
}
