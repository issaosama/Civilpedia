import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/backup/backup_file_service.dart';
import 'package:civilpedia/core/backup/backup_service.dart';
import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/data/local/hive_helper.dart';
import 'package:civilpedia/data/local/preferences_helper.dart';
import 'package:civilpedia/features/profile/data/local_user_profile_data_source.dart';
import 'package:civilpedia/features/profile/data/local_user_profile_repository.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/tools/data/checklist/checklist_local_data_source.dart';
import 'package:civilpedia/features/tools/data/checklist/local_checklist_repository.dart';
import 'package:civilpedia/features/tools/data/checklist/local_project_repository.dart';
import 'package:civilpedia/features/tools/data/checklist/project_local_data_source.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_status.dart';

const _boxName = 'backup_test_box';

void main() {
  late Directory tempDir;
  late Directory hiveDir;

  BackupService newService(String backupDirPath) => BackupService(
        userProfileRepo:
            LocalUserProfileRepository(LocalUserProfileDataSource()),
        checklistRepo: LocalChecklistRepository(ChecklistLocalDataSource()),
        projectRepo: LocalProjectRepository(ProjectLocalDataSource()),
        fileService: BackupFileService(backupDirPath),
      );

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('civilpedia_backup_test');
    hiveDir = await Directory.systemTemp.createTemp('civilpedia_backup_hive');
    await HiveHelper.init(path: hiveDir.path, boxName: _boxName);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesHelper.init();
    await Hive.box(_boxName).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
    try {
      hiveDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<String> writeJson(Map<String, dynamic> json) async {
    final fileService = BackupFileService(tempDir.path);
    final name = 'manual_${DateTime.now().microsecondsSinceEpoch}.json';
    await fileService.saveBackup(name, jsonEncode(json));
    return name;
  }

  group('Backup export coverage', () {
    test('profile seeded into repository is exported', () async {
      final service = newService(tempDir.path);
      final profileRepo = LocalUserProfileRepository(
          LocalUserProfileDataSource());
      await profileRepo.saveProfile(LocalUserProfile(
        anonymousInstallId: 'install-77',
        name: 'Ali',
        title: 'Site Engineer',
      ));

      final backup = await service.buildBackup();
      expect(backup.sections.localUserProfile, isNotNull);
      expect(backup.sections.localUserProfile!['name'], 'Ali');
    });

    test('preferences are exported', () async {
      await PreferencesHelper.setDarkMode(true);
      final service = newService(tempDir.path);
      final backup = await service.buildBackup();
      expect(backup.sections.preferences, isNotNull);
      expect(backup.sections.preferences!['isDarkMode'], isTrue);
      expect(backup.sections.preferences!['appLanguage'], 'ar');
    });

    test('projects and project checklists are exported', () async {
      final projectRepo = LocalProjectRepository(ProjectLocalDataSource());
      final project = await projectRepo.createProject('Bridge');
      final checklistRepo =
          LocalChecklistRepository(ChecklistLocalDataSource());
      await checklistRepo.saveProjectItemStatus(
          project.id, 'ITEM-1', InspectionStatus.fail);

      final backup = await newService(tempDir.path).buildBackup();
      expect(backup.sections.projects, isNotNull);
      expect(backup.sections.projects!.length, 1);
      expect(backup.sections.projects!.first['id'], project.id);
      expect(backup.sections.projects!.first['name'], 'Bridge');
      expect(backup.sections.projectChecklists,
          contains(project.id));
    });

    test('legacy favorites, encyclopedia favorites, and downloads exported',
        () async {
      await HiveHelper.toggleFavorite('art-legacy');
      await HiveHelper.addEncyclopediaFavorite('topic-enc');
      await HiveHelper.toggleDownload('art-offline');

      final backup = await newService(tempDir.path).buildBackup();
      expect(backup.sections.favorites, ['art-legacy']);
      expect(backup.sections.encyclopediaFavorites, ['topic-enc']);
      expect(backup.sections.downloads, ['art-offline']);
    });

    test('no auth credentials or secrets are exported', () async {
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.authEmail: 'user@example.com',
        AppStorageKeys.authName: 'User',
        AppStorageKeys.registerEmail('user@example.com'): 'SuperSecret123',
      });

      final backup = await newService(tempDir.path).buildBackup();
      final json = jsonEncode(backup.toJson());
      expect(json, isNot(contains('SuperSecret123')));
      expect(json, isNot(contains('auth_email')));
      expect(json, isNot(contains('auth_name')));
      expect(json, isNot(contains('register_')));
    });
  });

  group('Backup round-trip restore', () {
    test('profile, projects, checklists, favorites, prefs all round-trip',
        () async {
      // Seed
      final seedProjectRepo =
          LocalProjectRepository(ProjectLocalDataSource());
      final project = await seedProjectRepo.createProject('Round Trip');
      final seedChecklistRepo =
          LocalChecklistRepository(ChecklistLocalDataSource());
      await seedChecklistRepo.saveItemStatus('G-1', InspectionStatus.pass);
      await seedChecklistRepo.saveItemNotes('G-1', 'done');
      await seedChecklistRepo.saveProjectItemStatus(
          project.id, 'P-1', InspectionStatus.fail);
      final seedProfileRepo =
          LocalUserProfileRepository(LocalUserProfileDataSource());
      await seedProfileRepo.saveProfile(LocalUserProfile(
        anonymousInstallId: 'install-rt',
        name: 'Round',
      ));
      await PreferencesHelper.setDarkMode(true);
      await HiveHelper.toggleFavorite('art-1');
      await HiveHelper.addEncyclopediaFavorite('topic-1');
      await HiveHelper.toggleDownload('art-2');

      // Export
      final service = newService(tempDir.path);
      final fileName =
          'rt_${DateTime.now().microsecondsSinceEpoch}.json';
      await service.exportToFile(fileName);

      // Mutate current state so restore has something to reproduce
      final mutateProjectRepo =
          LocalProjectRepository(ProjectLocalDataSource());
      await mutateProjectRepo.replaceAll(const []);
      final mutateChecklistRepo =
          LocalChecklistRepository(ChecklistLocalDataSource());
      await mutateChecklistRepo.clearAll();
      await mutateChecklistRepo.clearProject(project.id);
      await PreferencesHelper.setDarkMode(false);
      await HiveHelper.restoreFavorites(const []);
      await HiveHelper.restoreEncyclopediaFavorites(const []);
      await HiveHelper.restoreDownloads(const []);

      // Restore
      final restored = await service.restoreFromBackup(fileName);
      expect(restored.success, isTrue);
      expect(restored.errorMessage, isNull);

      // Verify through fresh repositories (persisted state)
      final freshProjectRepo =
          LocalProjectRepository(ProjectLocalDataSource());
      final projects = await freshProjectRepo.loadProjects();
      expect(projects.length, 1);
      expect(projects.first.id, project.id);
      expect(projects.first.name, 'Round Trip');

      final freshChecklistRepo =
          LocalChecklistRepository(ChecklistLocalDataSource());
      final quick = await freshChecklistRepo.loadItemStates();
      expect(quick['G-1']!.status, InspectionStatus.pass);
      expect(quick['G-1']!.notes, 'done');
      final pCheck = await freshChecklistRepo.loadProjectItemStates(project.id);
      expect(pCheck['P-1']!.status, InspectionStatus.fail);

      final freshProfileRepo =
          LocalUserProfileRepository(LocalUserProfileDataSource());
      final profile = await freshProfileRepo.loadProfile();
      expect(profile, isNotNull);
      expect(profile!.name, 'Round');

      expect(PreferencesHelper.isDarkMode, isTrue);
      expect(HiveHelper.getFavorites(), ['art-1']);
      expect(HiveHelper.getEncyclopediaFavorites(), ['topic-1']);
      expect(HiveHelper.getDownloads(), ['art-2']);
    });

    test('onboardingSeen restores true after it was changed', () async {
      // Backup onboardingSeen=true
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(AppStorageKeys.onboardingSeen, true);

      final service = newService(tempDir.path);
      final fileName =
          'onb_${DateTime.now().microsecondsSinceEpoch}.json';
      await service.exportToFile(fileName);
      expect(PreferencesHelper.isOnboardingSeen, isTrue);

      // Change current stored value to false
      await sp.setBool(AppStorageKeys.onboardingSeen, false);
      expect(PreferencesHelper.isOnboardingSeen, isFalse);

      // Restore -> true again
      final restored = await service.restoreFromBackup(fileName);
      expect(restored.success, isTrue);
      expect(PreferencesHelper.isOnboardingSeen, isTrue);
    });

    test('onboardingSeen restores false when backup says false', () async {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(AppStorageKeys.onboardingSeen, true);

      // Seed a backup via buildBackup, then override to false manually.
      final service = newService(tempDir.path);
      final fileName =
          'onb_false_${DateTime.now().microsecondsSinceEpoch}.json';
      await service.exportToFile(fileName);

      // Rewrite the file with onboardingSeen=false
      final fileService = BackupFileService(tempDir.path);
      final raw = await fileService.loadBackup(fileName);
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      json['sections']['preferences']['onboardingSeen'] = false;
      await fileService.saveBackup(fileName, jsonEncode(json));

      // Change current stored value to true
      await sp.setBool(AppStorageKeys.onboardingSeen, true);
      expect(PreferencesHelper.isOnboardingSeen, isTrue);

      final restored = await service.restoreFromBackup(fileName);
      expect(restored.success, isTrue);
      expect(PreferencesHelper.isOnboardingSeen, isFalse);
    });

    test('missing optional sections preserve existing data', () async {
      // Existing data
      final projectRepo = LocalProjectRepository(ProjectLocalDataSource());
      await projectRepo.createProject('Keep Me');
      await PreferencesHelper.setDarkMode(true);

      // Valid backup with ONLY favorites
      final name = await writeJson({
        'backupSchemaVersion': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'sections': {
          'favorites': ['keep-fav'],
        },
      });

      final result = await newService(tempDir.path).restoreFromBackup(name);
      expect(result.success, isTrue);

      expect(HiveHelper.getFavorites(), ['keep-fav']);
      // Unaffected sections preserved
      expect((await (LocalProjectRepository(ProjectLocalDataSource()))
              .loadProjects())
          .length, 1);
      expect(PreferencesHelper.isDarkMode, isTrue);
    });
  });

  group('Backup validation safety', () {
    test('unsupported future version is rejected safely', () async {
      final projectRepo = LocalProjectRepository(ProjectLocalDataSource());
      await projectRepo.createProject('Existing');
      await HiveHelper.toggleFavorite('keep-me');

      final name = await writeJson({
        'backupSchemaVersion': 999,
        'exportedAt': DateTime.now().toIso8601String(),
        'sections': {
          'favorites': ['should-not-apply'],
        },
      });

      final result = await newService(tempDir.path).restoreFromBackup(name);
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('newer version'));

      // Nothing was changed
      expect(HiveHelper.getFavorites(), ['keep-me']);
      expect((await (LocalProjectRepository(ProjectLocalDataSource()))
              .loadProjects())
          .length, 1);
    });

    test('malformed JSON is rejected safely', () async {
      await HiveHelper.toggleFavorite('keep-me');
      final fileService = BackupFileService(tempDir.path);
      final name = 'broken_${DateTime.now().microsecondsSinceEpoch}.json';
      await fileService.saveBackup(name, '{not valid json');

      final result = await newService(tempDir.path).restoreFromBackup(name);
      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(HiveHelper.getFavorites(), ['keep-me']);
    });

    test('wrong-type section is rejected before any write', () async {
      await HiveHelper.toggleFavorite('keep-me');
      final projectRepo = LocalProjectRepository(ProjectLocalDataSource());
      await projectRepo.createProject('existing');

      // projects present but is a string (wrong type)
      final name = await writeJson({
        'backupSchemaVersion': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'sections': {
          'projects': 'not-a-list',
          'favorites': ['should-not-apply'],
        },
      });

      final result = await newService(tempDir.path).restoreFromBackup(name);
      expect(result.success, isFalse);
      expect(HiveHelper.getFavorites(), ['keep-me']);
      expect((await (LocalProjectRepository(ProjectLocalDataSource()))
              .loadProjects())
          .length, 1);
    });

    test('legacy v1 backup shape remains readable', () async {
      final name = await writeJson({
        'backupSchemaVersion': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'sections': {
          'favorites': ['legacy-fav'],
        },
      });

      final result = await newService(tempDir.path).restoreFromBackup(name);
      expect(result.success, isTrue);
      expect(HiveHelper.getFavorites(), ['legacy-fav']);
    });

    test('validateBackup returns false for unsupported version', () async {
      final name = await writeJson({
        'backupSchemaVersion': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'sections': {},
      });
      final result = await newService(tempDir.path).validateBackup(name);
      expect(result.isValid, isFalse);
    });

    test('validateBackup returns true for supported v1', () async {
      final name = await writeJson({
        'backupSchemaVersion': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'sections': {},
      });
      final result = await newService(tempDir.path).validateBackup(name);
      expect(result.isValid, isTrue);
    });

    test('AppStorageKeys remain the storage identity authority', () {
      expect(AppStorageKeys.checklistData, 'checklist_data');
      expect(AppStorageKeys.projectsList, 'projects_list');
      expect(AppStorageKeys.favorites, 'favorites');
      expect(AppStorageKeys.encyclopediaFavorites, 'encyclopediaFavorites');
      expect(AppStorageKeys.downloads, 'downloads');
    });
  });
}
