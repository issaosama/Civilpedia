import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/storage/app_storage_keys.dart';

void main() {
  group('AppStorageKeys — canonical persisted storage keys', () {
    test('SharedPreferences app-wide keys match legacy literals byte-for-byte',
        () {
      expect(AppStorageKeys.isDarkMode, 'isDarkMode');
      expect(AppStorageKeys.onboardingSeen, 'onboardingSeen');
      expect(AppStorageKeys.appLanguage, 'app_language');
    });

    test('SharedPreferences auth keys match legacy literals', () {
      expect(AppStorageKeys.authEmail, 'auth_email');
      expect(AppStorageKeys.authName, 'auth_name');
    });

    test('SharedPreferences profile keys match legacy literals', () {
      expect(AppStorageKeys.localUserProfile, 'local_user_profile');
      expect(AppStorageKeys.sbProfiles, 'sb_profiles');
    });

    test('SharedPreferences checklist/project keys match legacy literals', () {
      expect(AppStorageKeys.checklistData, 'checklist_data');
      expect(AppStorageKeys.projectsList, 'projects_list');
    });

    test('Hive box and list keys match legacy literals', () {
      expect(AppStorageKeys.hiveBoxName, 'civilpedia');
      expect(AppStorageKeys.favorites, 'favorites');
      expect(AppStorageKeys.encyclopediaFavorites, 'encyclopediaFavorites');
      expect(AppStorageKeys.downloads, 'downloads');
    });

    test('projectChecklist builder matches legacy per-project pattern', () {
      expect(AppStorageKeys.projectChecklist('abc123'),
          'checklist_project_abc123');
      expect(AppStorageKeys.projectChecklist('_a-b'),
          'checklist_project__a-b');
    });

    test('offlineArticle builder matches legacy offline pattern', () {
      expect(AppStorageKeys.offlineArticle('art-9'), 'offline_art-9');
      expect(AppStorageKeys.offlineArticle('x y'), 'offline_x y');
    });

    test('registerEmail builder matches legacy register pattern', () {
      expect(AppStorageKeys.registerEmail('user@example.com'),
          'register_user@example.com');
    });

    test('registerEmailName builder matches legacy register name pattern', () {
      expect(AppStorageKeys.registerEmailName('user@example.com'),
          'register_user@example.com_name');
    });

    test('dynamic keys are unique for distinct inputs', () {
      expect(AppStorageKeys.projectChecklist('1'),
          isNot(AppStorageKeys.projectChecklist('2')));
      expect(AppStorageKeys.offlineArticle('1'),
          isNot(AppStorageKeys.offlineArticle('2')));
      expect(AppStorageKeys.registerEmail('a@b.c'),
          isNot(AppStorageKeys.registerEmail('d@e.f')));
      expect(AppStorageKeys.registerEmailName('a@b.c'),
          isNot(AppStorageKeys.registerEmailName('d@e.f')));
    });
  });
}
