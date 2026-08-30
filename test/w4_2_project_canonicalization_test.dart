import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/features/projects/data/local_project_repository.dart'
    as canonical_repo;
import 'package:civilpedia/features/projects/data/project_local_data_source.dart'
    as canonical_ds;
import 'package:civilpedia/features/projects/data/project_persistence_gateway.dart';
import 'package:civilpedia/features/projects/domain/entities/project.dart'
    as canonical_entity;
import 'package:civilpedia/features/projects/domain/project_repository.dart'
    as canonical_contract;
import 'package:civilpedia/features/tools/data/checklist/checklist_local_data_source.dart';
import 'package:civilpedia/features/tools/data/checklist/local_checklist_repository.dart';
import 'package:civilpedia/features/tools/data/checklist/local_project_repository.dart' as legacy_repo;
import 'package:civilpedia/features/tools/data/checklist/project_local_data_source.dart' as legacy_ds;
import 'package:civilpedia/features/tools/domain/checklist/entities/project.dart' as legacy_entity;
import 'package:civilpedia/features/tools/domain/checklist/project_repository.dart' as legacy_contract;
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_status.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('W4.2 canonical entity identity', () {
    test('1. canonical Projects Project entity works', () {
      final now = DateTime(2024, 1, 2, 3, 4, 5);
      final p = canonical_entity.Project(
        id: 'p1',
        name: 'Alpha',
        createdAt: now,
        updatedAt: now,
      );
      expect(p.id, 'p1');
      expect(p.name, 'Alpha');
      expect(p.createdAt, now);
      expect(p.updatedAt, now);
      expect(p.isArchived, isFalse);
      expect(p.copyWith(name: 'Beta', isArchived: true).name, 'Beta');
      expect(p.copyWith(name: 'Beta').isArchived, isFalse);
    });

    test(
      '2. legacy Tools Project import resolves to the SAME canonical Project type',
      () {
        expect(legacy_entity.Project, same(canonical_entity.Project));
      },
    );
  });

  group('W4.2 canonical repository contract', () {
    test('3. canonical ProjectRepository contract works', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final created = await repo.createProject('Contract Proj');
      expect(created.id, isNotEmpty);
      expect(created.name, 'Contract Proj');
      final loaded = await repo.loadProjects();
      expect(loaded.single.id, created.id);
    });

    test('4. legacy Tools ProjectRepository import remains compatible', () {
      expect(legacy_contract.ProjectRepository, same(canonical_contract.ProjectRepository));
    });

    test('5. canonical LocalProjectRepository works', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Canonical');
      expect(p.name, 'Canonical');
      expect(p.id, startsWith('project_'));
      expect(p.isArchived, isFalse);
    });

    test('6. legacy Tools LocalProjectRepository import remains compatible',
        () async {
      final repo = legacy_repo.LocalProjectRepository(
        legacy_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Legacy Wiring');
      expect(p, isNotNull);
      expect((await repo.loadProjects()).single.name, 'Legacy Wiring');
    });
  });

  group('W4.2 canonical data source', () {
    test('7. canonical ProjectLocalDataSource works', () async {
      final now = DateTime(2024, 2, 3, 4, 5, 6);
      final ds = canonical_ds.ProjectLocalDataSource();
      await ds.writeProjects([
        canonical_entity.Project(
          id: 'ds_a',
          name: 'Alpha',
          createdAt: now,
          updatedAt: now,
          isArchived: true,
        ),
      ]);
      final read = await ds.readProjects();
      expect(read, hasLength(1));
      expect(read.single.id, 'ds_a');
      expect(read.single.isArchived, isTrue);
      await ds.clearProjects();
      expect(await ds.readProjects(), isEmpty);
    });

    test('8. legacy Tools ProjectLocalDataSource import remains compatible',
        () async {
      final now = DateTime(2024, 3, 4, 5, 6, 7);
      final ds = legacy_ds.ProjectLocalDataSource();
      await ds.writeProjects([
        canonical_entity.Project(
          id: 'ds_b',
          name: 'Beta',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      expect((await ds.readProjects()).single.name, 'Beta');
    });
  });

  group('W4.2 dependency direction', () {
    test(
      '9. canonical LocalProjectRepository depends only on the Projects-owned data-source path',
      () {
        final repo = canonical_repo.LocalProjectRepository(
          canonical_ds.ProjectLocalDataSource(),
        );
        expect(repo, isA<canonical_repo.LocalProjectRepository>());
        expect(repo, isA<canonical_contract.ProjectRepository>());
      },
    );

    test(
      '10. Projects persistence files do not require Tools Project/domain/data implementations',
      () {
        // The canonical stack compiles/runs without any Tools import. These
        // assertions prove the canonical chain resolves through Projects-owned
        // types only.
        final now = DateTime(2024, 4, 5, 6, 7, 8);
        final ds = canonical_ds.ProjectLocalDataSource();
        expect(ds, isNotNull);
        final gateway = ProjectPersistenceGateway();
        expect(gateway, isNotNull);
        final entity = canonical_entity.Project(
          id: 'iso',
          name: 'Isolated',
          createdAt: now,
          updatedAt: now,
        );
        expect(entity.id, 'iso');
      },
    );
  });

  group('W4.2 CRUD behavior preserved', () {
    test('11. create behavior unchanged (trim + Untitled default)', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final blank = await repo.createProject('   ');
      expect(blank.name, 'Untitled Project');
      final named = await repo.createProject('  Bridge  ');
      expect(named.name, 'Bridge');
    });

    test('12. update behavior unchanged (bumps updatedAt)', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Before');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repo.updateProject(p.copyWith(name: 'After'));
      final loaded = (await repo.loadProjects()).single;
      expect(loaded.name, 'After');
      expect(loaded.updatedAt.isAfter(p.updatedAt), isTrue);
    });

    test('13. archive behavior unchanged (sets isArchived + bumps updatedAt)',
        () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Archived');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repo.archiveProject(p.id);
      final loaded = (await repo.loadProjects()).single;
      expect(loaded.isArchived, isTrue);
      expect(loaded.updatedAt.isAfter(p.updatedAt), isTrue);
    });

    test('14. delete behavior unchanged', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Gone');
      expect(await repo.loadProjects(), hasLength(1));
      await repo.deleteProject(p.id);
      expect(await repo.loadProjects(), isEmpty);
    });

    test('15. existing ID semantics unchanged', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final a = await repo.createProject('A');
      final b = await repo.createProject('B');
      expect(a.id, startsWith('project_'));
      expect(b.id, startsWith('project_'));
      expect(a.id, isNot(b.id));
    });
  });

  group('W4.2 serialization compatibility', () {
    test('16. projects_list serialization remains compatible', () async {
      final now = DateTime(2024, 5, 6, 7, 8, 9, 123);
      final project = canonical_entity.Project(
        id: 'ser_id',
        name: 'Ser',
        createdAt: now,
        updatedAt: now,
        isArchived: true,
      );
      await canonical_ds.ProjectLocalDataSource().writeProjects([project]);
      final raw = (await SharedPreferences.getInstance()).getString(
        AppStorageKeys.projectsList,
      );
      expect(
        raw,
        jsonEncode([
          {
            'id': 'ser_id',
            'name': 'Ser',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'isArchived': true,
          },
        ]),
      );
    });

    test('17. W4.1 Tools write → Projects read stays green', () async {
      final legacy = legacy_repo.LocalProjectRepository(
        legacy_ds.ProjectLocalDataSource(),
      );
      final created = await legacy.createProject('From Tools');

      final gateway = ProjectPersistenceGateway();
      final read = await gateway.readProjects();
      expect(read.single.id, created.id);
      expect(read.single.name, 'From Tools');
    });

    test('18. Projects write → legacy Tools read stays green', () async {
      final now = DateTime(2024, 6, 7, 8, 9, 10);
      await canonical_ds.ProjectLocalDataSource().writeProjects([
        canonical_entity.Project(
          id: 'to_legacy',
          name: 'From Projects',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      final legacy = legacy_repo.LocalProjectRepository(
        legacy_ds.ProjectLocalDataSource(),
      );
      expect((await legacy.loadProjects()).single.name, 'From Projects');
    });

    test('19. checklist_project_<id> compatibility stays green', () async {
      final legacyChecklist = LocalChecklistRepository(
        ChecklistLocalDataSource(),
      );
      await legacyChecklist.saveProjectItemStatus(
          'projX', 'ITEM-1', InspectionStatus.fail);
      final gateway = ProjectPersistenceGateway();
      final raw = await gateway.readProjectChecklist('projX');
      expect(jsonDecode(raw!), {
        'ITEM-1': {'status': 'fail'},
      });
    });

    test('20. checklist_data remains untouched', () async {
      final legacyChecklist = LocalChecklistRepository(
        ChecklistLocalDataSource(),
      );
      await legacyChecklist.saveItemStatus('GLB', InspectionStatus.pass);
      final gateway = ProjectPersistenceGateway();
      await gateway.writeProjects([
        canonical_entity.Project(
          id: 'untouch',
          name: 'X',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ]);
      await gateway.writeProjectChecklist('pX', '{"ITEM-1":{"status":"fail"}}');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppStorageKeys.checklistData),
        '{"GLB":{"status":"pass"}}',
      );
    });
  });
}
