import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/hive_helper.dart';
import '../../data/local/preferences_helper.dart';
import '../../features/profile/domain/user_profile.dart';
import '../../features/profile/domain/user_profile_repository.dart';
import '../../features/tools/domain/checklist/checklist_repository.dart';
import '../../features/tools/domain/checklist/entities/project.dart';
import '../../features/tools/domain/checklist/project_repository.dart';
import '../../features/tools/presentation/screens/checklist/models/inspection_status.dart';
import '../schema/schema_constants.dart';
import '../storage/app_storage_keys.dart';
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

/// Thrown when a backup file fails structural/type validation before any
/// write is applied. Carries a human-readable reason.
class BackupFormatException implements Exception {
  final String message;

  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

/// Typed, fully-validated view of a backup ready to be applied. All sections
/// are normalized and type-checked before any write is issued, so a malformed
/// backup can never destructively overwrite current user data.
class _ValidatedBackup {
  final LocalUserProfile? localUserProfile;
  final List<Project> projects;
  final Map<String, ChecklistItemData> quickChecklist;
  final Map<String, Map<String, ChecklistItemData>> projectChecklists;
  final Map<String, dynamic> preferences;
  final List<String> favorites;
  final List<String> encyclopediaFavorites;
  final List<String> downloads;

  const _ValidatedBackup({
    this.localUserProfile,
    required this.projects,
    required this.quickChecklist,
    required this.projectChecklists,
    required this.preferences,
    required this.favorites,
    required this.encyclopediaFavorites,
    required this.downloads,
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
    final encyclopediaFavorites = HiveHelper.getEncyclopediaFavorites();
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
        encyclopediaFavorites:
            encyclopediaFavorites.isNotEmpty ? encyclopediaFavorites : null,
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
    try {
      _validateAndNormalize(jsonString);
    } on BackupFormatException catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorMessage: e.message,
      );
    } catch (_) {
      return const BackupValidationResult(
        isValid: false,
        errorMessage: 'Corrupt backup file: unable to parse JSON',
      );
    }
    return const BackupValidationResult(isValid: true);
  }

  Future<BackupRestoreResult> restoreFromBackup(String fileName) async {
    final jsonString = await _fileService.loadBackup(fileName);
    if (jsonString == null) {
      return const BackupRestoreResult(
        success: false,
        errorMessage: 'Backup file not found',
      );
    }

    // Parse + validate EVERYTHING up-front. No write happens until the whole
    // backup is confirmed structurally safe and version-supported.
    _ValidatedBackup backup;
    try {
      backup = _validateAndNormalize(jsonString);
    } on BackupFormatException catch (e) {
      return BackupRestoreResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (_) {
      return const BackupRestoreResult(
        success: false,
        errorMessage: 'Corrupt backup file: unable to parse JSON',
      );
    }

    int restored = 0;

    try {
      if (backup.localUserProfile != null) {
        await _userProfileRepo.saveProfile(backup.localUserProfile!);
        restored++;
      }
    } catch (_) {}

    try {
      if (backup.projects.isNotEmpty) {
        await _projectRepo.replaceAll(backup.projects);
        restored++;
      }
    } catch (_) {}

    try {
      if (backup.quickChecklist.isNotEmpty) {
        await _checklistRepo.saveItemStates(backup.quickChecklist);
        restored++;
      }
    } catch (_) {}

    try {
      if (backup.projectChecklists.isNotEmpty) {
        for (final entry in backup.projectChecklists.entries) {
          await _checklistRepo
              .saveProjectItemStates(entry.key, entry.value);
        }
        restored++;
      }
    } catch (_) {}

    try {
      if (backup.preferences.isNotEmpty) {
        final prefs = backup.preferences;
        if (prefs['isDarkMode'] is bool) {
          await PreferencesHelper.setDarkMode(prefs['isDarkMode'] as bool);
        }
        final sp = await SharedPreferences.getInstance();
        final lang = prefs['appLanguage'];
        await sp.setString(
          AppStorageKeys.appLanguage,
          lang is String && lang.isNotEmpty ? lang : 'ar',
        );
        final onboarding = prefs['onboardingSeen'];
        if (onboarding is bool) {
          await sp.setBool(AppStorageKeys.onboardingSeen, onboarding);
        }
        restored++;
      }
    } catch (_) {}

    try {
      if (backup.favorites.isNotEmpty) {
        await HiveHelper.restoreFavorites(backup.favorites);
        restored++;
      }
    } catch (_) {}

    try {
      if (backup.encyclopediaFavorites.isNotEmpty) {
        await HiveHelper.restoreEncyclopediaFavorites(
            backup.encyclopediaFavorites);
        restored++;
      }
    } catch (_) {}

    try {
      if (backup.downloads.isNotEmpty) {
        // Restore the download *references* only. Offline article content
        // (offline_<articleId>) is deferred / re-acquirable per BACKUP-1A scope.
        await HiveHelper.restoreDownloads(backup.downloads);
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

  /// Parses and fully validates a backup JSON string into a typed,
  /// normalized [_ValidatedBackup]. Throws [BackupFormatException] on:
  ///   - malformed / non-object top level
  ///   - unsupported or missing backup version
  ///   - structurally wrong section types (any section)
  /// No state is touched.
  _ValidatedBackup _validateAndNormalize(String jsonString) {
    final Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(jsonString);
      parsed = decoded as Map<String, dynamic>;
    } catch (_) {
      throw const BackupFormatException(
          'Corrupt backup file: unable to parse JSON');
    }

    final schemaVersion = parsed['backupSchemaVersion'];
    if (schemaVersion is! int) {
      throw const BackupFormatException(
          'Invalid backup: missing backupSchemaVersion');
    }
    if (schemaVersion < 1) {
      throw BackupFormatException(
          'Invalid backup schema version: $schemaVersion');
    }
    if (schemaVersion > SchemaConstants.currentBackupVersion) {
      throw BackupFormatException(
          'Backup was created by a newer version of the app. '
          'Please update Civilpedia to restore this backup.');
    }

    final sectionsRaw = parsed['sections'];
    if (sectionsRaw is! Map) {
      throw const BackupFormatException(
          'Backup file is missing the data sections');
    }
    final sections = sectionsRaw.cast<String, dynamic>();

    return _ValidatedBackup(
      localUserProfile: _validateProfile(sections['localUserProfile']),
      projects: _validateProjects(sections['projects']),
      quickChecklist:
          _validateChecklistItems(sections['quickChecklist'], 'quickChecklist'),
      projectChecklists: _validateProjectChecklists(
          sections['projectChecklists']),
      preferences: _validatePreferences(sections['preferences']),
      favorites: _validateStringList(sections['favorites'], 'favorites'),
      encyclopediaFavorites: _validateStringList(
          sections['encyclopediaFavorites'], 'encyclopediaFavorites'),
      downloads: _validateStringList(sections['downloads'], 'downloads'),
    );
  }

  LocalUserProfile? _validateProfile(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) {
      throw const BackupFormatException(
          'Invalid backup: localUserProfile must be an object');
    }
    try {
      return LocalUserProfile.fromJson(raw.cast<String, dynamic>());
    } catch (_) {
      throw const BackupFormatException(
          'Invalid backup: localUserProfile could not be parsed');
    }
  }

  List<Project> _validateProjects(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const BackupFormatException(
          'Invalid backup: projects must be a list');
    }
    final projects = <Project>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) {
        throw BackupFormatException(
            'Invalid backup: projects[$i] must be an object');
      }
      final map = item.cast<String, dynamic>();
      final project = _tryParseProject(map);
      if (project == null || project.id.isEmpty) {
        throw BackupFormatException(
            'Invalid backup: projects[$i] has invalid project data');
      }
      projects.add(project);
    }
    return projects;
  }

  Project? _tryParseProject(Map<String, dynamic> map) {
    try {
      return Project(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        isArchived: map['isArchived'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, ChecklistItemData> _validateChecklistItems(
      Object? raw, String sectionName) {
    final result = <String, ChecklistItemData>{};
    if (raw == null) return result;
    if (raw is! Map) {
      throw BackupFormatException(
          'Invalid backup: $sectionName must be an object');
    }
    raw.forEach((itemId, value) {
      if (itemId is! String || value is! Map) {
        throw BackupFormatException(
            'Invalid backup: $sectionName has invalid item');
      }
      final item = value.cast<String, dynamic>();
      final statusName = item['status'];
      if (statusName is! String) {
        throw BackupFormatException(
            'Invalid backup: $sectionName item missing status');
      }
      final status = _parseStatus(statusName);
      if (status == null) {
        throw BackupFormatException(
            'Invalid backup: $sectionName has unknown status "$statusName"');
      }
      final notes = item['notes'];
      if (notes != null && notes is! String) {
        throw BackupFormatException(
            'Invalid backup: $sectionName has invalid notes');
      }
      result[itemId] = ChecklistItemData(
        status: status,
        notes: notes as String?,
      );
    });
    return result;
  }

  Map<String, Map<String, ChecklistItemData>> _validateProjectChecklists(
      Object? raw) {
    final result = <String, Map<String, ChecklistItemData>>{};
    if (raw == null) return result;
    if (raw is! Map) {
      throw const BackupFormatException(
          'Invalid backup: projectChecklists must be an object');
    }
    raw.forEach((projectId, value) {
      if (projectId is! String || value is! Map) {
        throw const BackupFormatException(
            'Invalid backup: projectChecklists has invalid entry');
      }
      final checklists =
          _validateChecklistItems(value, 'projectChecklists');
      result[projectId] = checklists;
    });
    return result;
  }

  Map<String, dynamic> _validatePreferences(Object? raw) {
    if (raw == null) return const {};
    if (raw is! Map) {
      throw const BackupFormatException(
          'Invalid backup: preferences must be an object');
    }
    final prefs = raw.cast<String, dynamic>();
    if (prefs['isDarkMode'] != null && prefs['isDarkMode'] is! bool) {
      throw const BackupFormatException(
          'Invalid backup: preferences.isDarkMode must be a boolean');
    }
    if (prefs['appLanguage'] != null && prefs['appLanguage'] is! String) {
      throw const BackupFormatException(
          'Invalid backup: preferences.appLanguage must be a string');
    }
    return prefs;
  }

  List<String> _validateStringList(Object? raw, String sectionName) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw BackupFormatException(
          'Invalid backup: $sectionName must be a list');
    }
    for (final e in raw) {
      if (e is! String) {
        throw BackupFormatException(
            'Invalid backup: $sectionName must contain only strings');
      }
    }
    return raw.cast<String>();
  }

  InspectionStatus? _parseStatus(String name) {
    for (final s in InspectionStatus.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}
