import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/features/projects/data/project_persistence_gateway.dart';
import 'package:civilpedia/features/tools/data/checklist/checklist_local_data_source.dart';
import 'package:civilpedia/features/tools/data/checklist/local_checklist_repository.dart';
import 'package:civilpedia/features/tools/data/checklist/local_project_repository.dart';
import 'package:civilpedia/features/tools/data/checklist/project_local_data_source.dart';
import 'package:civilpedia/features/tools/domain/checklist/entities/project.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_status.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('W4.1 projects_list dual compatibility', () {
    test(
      'legacy Tools path reads pre-existing projects_list records',
      () async {
        SharedPreferences.setMockInitialValues({
          AppStorageKeys.projectsList: jsonEncode([
            {
              'id': 'project_1_1111',
              'name': 'Ù…Ø´Ø±ÙˆØ¹ Ø§Ù„Ø¬Ø³Ø±',
              'createdAt': '2024-01-02T03:04:05.000',
              'updatedAt': '2024-01-03T03:04:05.000',
              'isArchived': true,
            },
            {
              'id': 'project_2_2222',
              'name': 'Tower A',
              'createdAt': '2024-02-02T03:04:05.000',
              'updatedAt': '2024-02-03T03:04:05.000',
              'isArchived': false,
            },
          ]),
        });

        final legacy = LocalProjectRepository(ProjectLocalDataSource());
        final projects = await legacy.loadProjects();

        expect(projects, hasLength(2));
        expect(projects[0].id, 'project_1_1111');
        expect(projects[0].name, 'Ù…Ø´Ø±ÙˆØ¹ Ø§Ù„Ø¬Ø³Ø±');
        expect(projects[0].isArchived, isTrue);
        expect(projects[1].name, 'Tower A');
        expect(projects[1].isArchived, isFalse);
      },
    );

    test(
      'new Projects-domain path reads the SAME pre-existing records',
      () async {
        const now = '2024-01-02T03:04:05.000';
        SharedPreferences.setMockInitialValues({
          AppStorageKeys.projectsList: jsonEncode([
            {
              'id': 'project_1_1111',
              'name': 'Bridge A',
              'createdAt': now,
              'updatedAt': now,
              'isArchived': false,
            },
          ]),
        });

        final gateway = ProjectPersistenceGateway();
        final projects = await gateway.readProjects();

        expect(projects, hasLength(1));
        expect(projects.single.id, 'project_1_1111');
        expect(projects.single.name, 'Bridge A');
        expect(projects.single.isArchived, isFalse);
      },
    );

    test('missing isArchived defaults to false on both paths', () async {
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.projectsList: jsonEncode([
          {
            'id': 'legacy_no_flag',
            'name': 'Old record',
            'createdAt': '2023-01-01T00:00:00.000',
            'updatedAt': '2023-01-01T00:00:00.000',
          },
        ]),
      });

      final viaLegacy = await LocalProjectRepository(
        ProjectLocalDataSource(),
      ).loadProjects();
      final viaGateway = await ProjectPersistenceGateway().readProjects();

      expect(viaLegacy.single.isArchived, isFalse);
      expect(viaGateway.single.isArchived, isFalse);
    });

    test(
      'legacy Tools write is immediately readable by the Projects path',
      () async {
        final legacy = LocalProjectRepository(ProjectLocalDataSource());
        final created = await legacy.createProject('Ù…Ø³ÙˆØ¯Ø© Ø£ÙˆÙ„ÙŠØ©');

        final gateway = ProjectPersistenceGateway();
        final read = await gateway.readProjects();

        expect(read, hasLength(1));
        expect(read.single.id, created.id);
        expect(read.single.name, 'Ù…Ø³ÙˆØ¯Ø© Ø£ÙˆÙ„ÙŠØ©');
      },
    );

    test(
      'Projects path write is immediately readable by the legacy Tools path',
      () async {
        final now = DateTime(2024, 5, 6, 7, 8, 9);
        final gateway = ProjectPersistenceGateway();
        await gateway.writeProjects([
          Project(
            id: 'project_write_999',
            name: 'From Domain',
            createdAt: now,
            updatedAt: now,
            isArchived: false,
          ),
        ]);

        final legacy = LocalProjectRepository(ProjectLocalDataSource());
        final read = await legacy.loadProjects();

        expect(read.single.id, 'project_write_999');
        expect(read.single.name, 'From Domain');
        expect(read.single.updatedAt, now);
      },
    );

    test('no second projects persistence key is created', () async {
      final legacy = LocalProjectRepository(ProjectLocalDataSource());
      await legacy.createProject('A');
      await ProjectPersistenceGateway().writeProjects([
        Project(
          id: 'pid',
          name: 'B',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ]);

      final prefs = await SharedPreferences.getInstance();
      final projectKeys = prefs
          .getKeys()
          .where((k) => k.startsWith('projects'))
          .toSet();
      expect(projectKeys, equals({AppStorageKeys.projectsList}));
    });

    test(
      'stored serialization remains byte-compatible with the legacy shape',
      () async {
        final now = DateTime(2024, 3, 4, 5, 6, 7, 890);
        final project = Project(
          id: 'pid',
          name: 'Bridge',
          createdAt: now,
          updatedAt: now,
          isArchived: true,
        );

        await ProjectPersistenceGateway().writeProjects([project]);

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(AppStorageKeys.projectsList);
        expect(
          raw,
          jsonEncode([
            {
              'id': 'pid',
              'name': 'Bridge',
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
              'isArchived': true,
            },
          ]),
        );
      },
    );

    test('read is side-effect free', () async {
      const stored =
          '[{"id":"p1","name":"N1","createdAt":"2024-01-01T00:00:00.000",'
          '"updatedAt":"2024-01-01T00:00:00.000","isArchived":false}]';
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.projectsList: stored,
      });

      final gateway = ProjectPersistenceGateway();
      await gateway.readProjects();
      await gateway.readProjects();
      await LocalProjectRepository(ProjectLocalDataSource()).loadProjects();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppStorageKeys.projectsList), stored);
      expect(prefs.getKeys(), equals({AppStorageKeys.projectsList}));
    });
  });

  group('W4.1 checklist_project_<id> dual compatibility', () {
    test(
      'legacy Tools path reads pre-existing project checklist records',
      () async {
        SharedPreferences.setMockInitialValues({
          AppStorageKeys.projectChecklist(
            'pA',
          ): '{"ITEM-1":{"status":"fail","notes":"rework"},"ITEM-2":{"status":"pass"}}',
        });

        final legacy = LocalChecklistRepository(ChecklistLocalDataSource());
        final states = await legacy.loadProjectItemStates('pA');

        expect(states['ITEM-1']!.status, InspectionStatus.fail);
        expect(states['ITEM-1']!.notes, 'rework');
        expect(states['ITEM-2']!.status, InspectionStatus.pass);
      },
    );

    test(
      'new Projects-domain path reads the same project checklist data',
      () async {
        const raw = '{"ITEM-1":{"status":"na"}}';
        SharedPreferences.setMockInitialValues({
          AppStorageKeys.projectChecklist('pA'): raw,
        });

        final gateway = ProjectPersistenceGateway();
        expect(await gateway.readProjectChecklist('pA'), raw);
      },
    );

    test('legacy Tools write is readable by the Projects path', () async {
      final legacy = LocalChecklistRepository(ChecklistLocalDataSource());
      await legacy.saveProjectItemStatus('pB', 'ITEM-9', InspectionStatus.na);

      final gateway = ProjectPersistenceGateway();
      final raw = await gateway.readProjectChecklist('pB');
      expect(jsonDecode(raw!), {
        'ITEM-9': {'status': 'na'},
      });
    });

    test(
      'Projects path write is read identically by the legacy Tools path',
      () async {
        final gateway = ProjectPersistenceGateway();
        await gateway.writeProjectChecklist(
          'pC',
          '{"ITEM-1":{"status":"pass","notes":"ok"}}',
        );

        final legacy = LocalChecklistRepository(ChecklistLocalDataSource());
        final states = await legacy.loadProjectItemStates('pC');

        expect(states['ITEM-1']!.status, InspectionStatus.pass);
        expect(states['ITEM-1']!.notes, 'ok');
      },
    );

    test('no alternate per-project checklist key is created', () async {
      final legacy = LocalChecklistRepository(ChecklistLocalDataSource());
      await legacy.saveProjectItemStatus('pX', 'ITEM-1', InspectionStatus.fail);
      await ProjectPersistenceGateway().writeProjectChecklist('pY', '{}');

      final prefs = await SharedPreferences.getInstance();
      final checklistKeys = prefs
          .getKeys()
          .where((k) => k.startsWith('checklist_'))
          .toSet();
      expect(
        checklistKeys,
        equals({
          AppStorageKeys.projectChecklist('pX'),
          AppStorageKeys.projectChecklist('pY'),
          AppStorageKeys.projectChecklistExecutions('pX'),
        }),
      );
    });

    test('multiple project IDs stay isolated', () async {
      final legacy = LocalChecklistRepository(ChecklistLocalDataSource());
      await legacy.saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.fail);
      await legacy.saveProjectItemStatus('p2', 'ITEM-1', InspectionStatus.pass);

      final a = await legacy.loadProjectItemStates('p1');
      final b = await legacy.loadProjectItemStates('p2');

      expect(a['ITEM-1']!.status, InspectionStatus.fail);
      expect(b['ITEM-1']!.status, InspectionStatus.pass);
    });

    test('reading one project never mutates another', () async {
      SharedPreferences.setMockInitialValues({
        AppStorageKeys.projectChecklist('p1'): '{"ITEM-1":{"status":"fail"}}',
        AppStorageKeys.projectChecklist('p2'): '{"ITEM-1":{"status":"pass"}}',
      });

      final gateway = ProjectPersistenceGateway();
      await gateway.readProjectChecklist('p1');
      final legacy = LocalChecklistRepository(ChecklistLocalDataSource());
      await legacy.loadProjectItemStates('p1');
      await legacy.loadProjectItemStates('p2');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppStorageKeys.projectChecklist('p1')),
        '{"ITEM-1":{"status":"fail"}}',
      );
      expect(
        prefs.getString(AppStorageKeys.projectChecklist('p2')),
        '{"ITEM-1":{"status":"pass"}}',
      );
    });
  });

  group('W4.1 checklist_data freeze (Tools-owned)', () {
    test('global checklist behavior remains unchanged', () async {
      final repo = LocalChecklistRepository(ChecklistLocalDataSource());
      await repo.saveItemStatus('ITEM-1', InspectionStatus.na);
      await repo.saveItemNotes('ITEM-1', 'noted');

      final states = await repo.loadItemStates();
      expect(states['ITEM-1']!.status, InspectionStatus.na);
      expect(states['ITEM-1']!.notes, 'noted');
    });

    test('Projects compatibility path never touches checklist_data', () async {
      final repo = LocalChecklistRepository(ChecklistLocalDataSource());
      await repo.saveItemStatus('GLB', InspectionStatus.pass);

      final gateway = ProjectPersistenceGateway();
      await gateway.writeProjectChecklist('pA', '{"ITEM-1":{"status":"fail"}}');
      await gateway.writeProjects([
        Project(
          id: 'pid',
          name: 'S',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ]);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppStorageKeys.checklistData),
        '{"GLB":{"status":"pass"}}',
      );
    });
  });

  group('W4.1 Tools behavior preservation', () {
    test('create/update/archive/delete/replaceAll still behave', () async {
      final repo = LocalProjectRepository(ProjectLocalDataSource());

      final created = await repo.createProject('   ');
      expect(created.name, 'Untitled Project');
      expect(created.id, startsWith('project_'));
      expect(created.isArchived, isFalse);

      await repo.updateProject(created.copyWith(name: 'Renamed'));
      expect((await repo.loadProjects()).single.name, 'Renamed');

      await repo.archiveProject(created.id);
      final afterArchive = (await repo.loadProjects()).single;
      expect(afterArchive.isArchived, isTrue);
      expect(
        afterArchive.updatedAt.isAfter(created.updatedAt),
        isTrue,
        reason: 'archive bumps updatedAt exactly like the legacy repo',
      );

      await repo.deleteProject(created.id);
      expect(await repo.loadProjects(), isEmpty);

      final now = DateTime(2024, 1, 1);
      await repo.replaceAll([
        Project(id: 'k1', name: 'K1', createdAt: now, updatedAt: now),
        Project(id: 'k2', name: 'K2', createdAt: now, updatedAt: now),
      ]);
      expect(
        (await repo.loadProjects()).map((p) => p.id),
        equals(['k1', 'k2']),
      );
    });

    test('project-aware checklist round trip preserved', () async {
      final repo = LocalChecklistRepository(ChecklistLocalDataSource());
      await repo.saveProjectItemNotes('p1', 'ITEM-1', 'note text');

      final states = await repo.loadProjectItemStates('p1');
      expect(states['ITEM-1']!.status, InspectionStatus.pending);
      expect(states['ITEM-1']!.notes, 'note text');
    });
  });

  group('W4.1 legacy adapter preservation', () {
    test(
      'legacy ProjectLocalDataSource survives W4.1 and works behaviorally',
      () async {
        final dataSource = ProjectLocalDataSource();
        final now = DateTime(2024, 2, 3, 4, 5, 6);

        await dataSource.writeProjects([
          Project(id: 'p_a', name: 'Alpha', createdAt: now, updatedAt: now),
          Project(
            id: 'p_b',
            name: 'Beta',
            createdAt: now,
            updatedAt: now,
            isArchived: true,
          ),
        ]);

        final read = await dataSource.readProjects();
        expect(read, hasLength(2));
        expect(read[0].id, 'p_a');
        expect(read[0].name, 'Alpha');
        expect(read[1].isArchived, isTrue);

        await dataSource.clearProjects();
        expect(await dataSource.readProjects(), isEmpty);
      },
    );

    test(
      'facade delegates to the same persisted truth as the gateway',
      () async {
        final facade = ProjectLocalDataSource();
        final gateway = ProjectPersistenceGateway();
        final now = DateTime(2024, 3, 4, 5, 6, 7);

        await facade.writeProjects([
          Project(id: 'from_facade', name: 'A', createdAt: now, updatedAt: now),
        ]);
        var viaGateway = await gateway.readProjects();
        expect(viaGateway.single.id, 'from_facade');
        expect(viaGateway.single.name, 'A');

        await gateway.writeProjects([
          Project(
            id: 'from_gateway',
            name: 'B',
            createdAt: now,
            updatedAt: now,
          ),
        ]);
        final viaFacade = await facade.readProjects();
        expect(viaFacade.single.id, 'from_gateway');
        expect(viaFacade.single.name, 'B');
      },
    );

    test(
      'single serialization contract: facade bytes equal gateway bytes',
      () async {
        final now = DateTime(2024, 4, 5, 6, 7, 8, 123);
        final projects = [
          Project(
            id: 'same_id',
            name: 'Same',
            createdAt: now,
            updatedAt: now,
            isArchived: true,
          ),
        ];
        const canonical =
            '[{"id":"same_id","name":"Same","createdAt":"2024-04-05T06:07:08.123",'
            '"updatedAt":"2024-04-05T06:07:08.123","isArchived":true}]';

        await ProjectPersistenceGateway().writeProjects(projects);
        final viaGateway = (await SharedPreferences.getInstance()).getString(
          AppStorageKeys.projectsList,
        );

        SharedPreferences.setMockInitialValues({});
        await ProjectLocalDataSource().writeProjects(projects);
        final viaFacade = (await SharedPreferences.getInstance()).getString(
          AppStorageKeys.projectsList,
        );

        expect(viaGateway, canonical);
        expect(viaFacade, canonical);
      },
    );
  });
}
