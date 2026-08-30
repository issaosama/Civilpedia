import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/projects/data/local_project_repository.dart'
    as canonical_repo;
import 'package:civilpedia/features/projects/data/project_local_data_source.dart'
    as canonical_ds;
import 'package:civilpedia/features/projects/data/project_persistence_gateway.dart';
import 'package:civilpedia/features/projects/domain/entities/project.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/project_list_screen.dart';
import 'package:civilpedia/localization/ar.dart';

final _kStorage = 'projects_list';

Widget _projectListScreen() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: const MaterialApp(home: ProjectListScreen()),
  );
}

Future<void> _pumpWithProjects(
  WidgetTester tester,
  List<Map<String, dynamic>> projects,
) async {
  SharedPreferences.setMockInitialValues({
    _kStorage: jsonEncode(projects),
  });
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_projectListScreen());
  await tester.pump();
}

Map<String, dynamic> _projectJson({
  required String id,
  required String name,
  required DateTime createdAt,
  bool isArchived = false,
}) {
  return {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': createdAt.toIso8601String(),
    'isArchived': isArchived,
  };
}

canonical_repo.LocalProjectRepository _repo() =>
    canonical_repo.LocalProjectRepository(canonical_ds.ProjectLocalDataSource());

Future<List<Project>> _persisted() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = jsonDecode(prefs.getString(_kStorage)!) as List;
  return raw
      .map((m) => Project(
            id: (m as Map<String, dynamic>)['id'] as String,
            name: m['name'] as String,
            createdAt: DateTime.parse(m['createdAt'] as String),
            updatedAt: DateTime.parse(m['updatedAt'] as String),
            isArchived: m['isArchived'] as bool? ?? false,
          ))
      .toList();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('W4.4 repository: Restore lifecycle', () {
    test('1. restoreProject returns an archived project to active', () async {
      final repo = _repo();
      final created = await repo.createProject('Bridge');
      await repo.archiveProject(created.id);
      final archived = (await repo.loadProjects()).single;
      expect(archived.isArchived, isTrue);

      await repo.restoreProject(created.id);
      final restored = (await repo.loadProjects()).single;
      expect(restored.isArchived, isFalse);
    });

    test('2. restoreProject persists the de-archive transition', () async {
      final repo = _repo();
      final created = await repo.createProject('Tower');
      await repo.archiveProject(created.id);
      await repo.restoreProject(created.id);

      final persisted = await _persisted();
      expect(persisted.single.isArchived, isFalse);
    });

    test('3. archive then restore preserves id and createdAt', () async {
      final repo = _repo();
      final created = await repo.createProject('Dam');
      await repo.archiveProject(created.id);
      await repo.restoreProject(created.id);

      final restored = (await repo.loadProjects()).single;
      expect(restored.id, created.id);
      expect(restored.createdAt, created.createdAt);
      expect(restored.name, created.name);
    });

    test('4. restoreProject is a no-op when project is already active',
        () async {
      final repo = _repo();
      final created = await repo.createProject('Active');
      final before = created.updatedAt;
      await repo.restoreProject(created.id);
      final after = (await repo.loadProjects()).single;
      expect(after.isArchived, isFalse);
      expect(after.updatedAt, before);
    });

    test('5. restoreProject is a no-op when project does not exist',
        () async {
      final repo = _repo();
      await repo.createProject('Only');
      await repo.restoreProject('missing_id');
      expect((await repo.loadProjects()).length, 1);
      expect((await repo.loadProjects()).single.isArchived, isFalse);
    });

    test('6. restoreProject bumps updatedAt from the archived state', () async {
      final repo = _repo();
      final created = await repo.createProject('Min');
      await repo.archiveProject(created.id);
      final archivedUpdated = (await repo.loadProjects()).single.updatedAt;
      await repo.restoreProject(created.id);
      final restored = (await repo.loadProjects()).single;
      expect(restored.isArchived, isFalse);
      expect(
        restored.updatedAt.isAfter(archivedUpdated) ||
            !restored.updatedAt.isBefore(archivedUpdated),
        isTrue,
      );
    });
  });

  group('W4.4 repository: archive compatibility', () {
    test('7. archiveProject still only flips isArchived and bumps updatedAt',
        () async {
      final repo = _repo();
      final created = await repo.createProject('Retain');
      final before = created.updatedAt;
      await repo.archiveProject(created.id);
      final archived = (await repo.loadProjects()).single;
      expect(archived.isArchived, isTrue);
      expect(archived.id, created.id);
      expect(archived.createdAt, created.createdAt);
      expect(
        archived.updatedAt.isBefore(before) == false,
        isTrue,
      );
    });

    test('8. legacy archived records are read and restorable', () async {
      final now = DateTime(2024, 1, 1);
      SharedPreferences.setMockInitialValues({
        _kStorage: jsonEncode([
          _projectJson(id: 'legacy_archived', name: 'Old', createdAt: now, isArchived: true),
        ]),
      });
      final repo = _repo();
      final loaded = await repo.loadProjects();
      expect(loaded.single.isArchived, isTrue);

      await repo.restoreProject('legacy_archived');
      final after = await _persisted();
      expect(after.single.isArchived, isFalse);
    });

    test('9. legacy record without isArchived still reads as active',
        () async {
      final now = DateTime(2024, 1, 1);
      SharedPreferences.setMockInitialValues({
        _kStorage: jsonEncode([
          {
            'id': 'no_flag',
            'name': 'Legacy',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        ]),
      });
      final repo = _repo();
      final loaded = await repo.loadProjects();
      expect(loaded.single.isArchived, isFalse);
    });

    test('10. projects_list serialization shape is unchanged', () async {
      final now = DateTime(2024, 2, 3, 4, 5, 6, 789, 123);
      final gateway = ProjectPersistenceGateway();
      await gateway.writeProjects([
        Project(
          id: 'sync_1',
          name: 'Sync',
          createdAt: now,
          updatedAt: now,
          isArchived: false,
        ),
      ]);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorage);
      expect(
        raw,
        '[{"id":"sync_1","name":"Sync",'
        '"createdAt":"2024-02-03T04:05:06.789123",'
        '"updatedAt":"2024-02-03T04:05:06.789123",'
        '"isArchived":false}]',
      );
    });
  });

  group('W4.4 UI: archived view + restore', () {
    testWidgets('11. active view hides archived projects by default', (tester) async {
      final now = DateTime(2024, 1, 1);
      await _pumpWithProjects(tester, [
        _projectJson(id: 'a1', name: 'ActiveOne', createdAt: now),
        _projectJson(id: 'ar1', name: 'Hidden', createdAt: now, isArchived: true),
      ]);
      expect(find.text('ActiveOne'), findsOneWidget);
      expect(find.text('Hidden'), findsNothing);
    });

    testWidgets('12. archived toggle reveals archived projects', (tester) async {
      final now = DateTime(2024, 1, 1);
      await _pumpWithProjects(tester, [
        _projectJson(id: 'a1', name: 'ActiveOne', createdAt: now),
        _projectJson(id: 'ar1', name: 'Hidden', createdAt: now, isArchived: true),
      ]);
      await tester.tap(find.text(Ar.projectArchived));
      await tester.pumpAndSettle();
      expect(find.text('Hidden'), findsOneWidget);
      expect(find.text('ActiveOne'), findsNothing);
    });

    testWidgets('13. no archived projects shows the archived empty state',
        (tester) async {
      final now = DateTime(2024, 1, 1);
      await _pumpWithProjects(tester, [
        _projectJson(id: 'a1', name: 'OnlyActive', createdAt: now),
      ]);
      await tester.tap(find.text(Ar.projectArchived));
      await tester.pumpAndSettle();
      expect(find.text(Ar.projectNoArchived), findsOneWidget);
    });

    testWidgets('14. archived view offers a Restore action', (tester) async {
      final now = DateTime(2024, 1, 1);
      await _pumpWithProjects(tester, [
        _projectJson(id: 'ar1', name: 'Hidden', createdAt: now, isArchived: true),
      ]);
      await tester.tap(find.text(Ar.projectArchived));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text(Ar.projectRestore), findsOneWidget);
    });

    testWidgets('15. restored project returns to the active list', (tester) async {
      final now = DateTime(2024, 1, 1);
      await _pumpWithProjects(tester, [
        _projectJson(id: 'ar1', name: 'Hidden', createdAt: now, isArchived: true),
      ]);
      await tester.tap(find.text(Ar.projectArchived));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.projectRestore));
      await tester.pumpAndSettle();

      // The persisted record is no longer archived.
      final persisted = await _persisted();
      expect(persisted.single.isArchived, isFalse);

      // A fresh ProjectListScreen (default = active view) shows it.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_projectListScreen());
      await tester.pumpAndSettle();
      expect(find.text('Hidden'), findsOneWidget);
    });

    testWidgets('16. active view still shows Archive action', (tester) async {
      final now = DateTime(2024, 1, 1);
      await _pumpWithProjects(tester, [
        _projectJson(id: 'a1', name: 'ActiveOne', createdAt: now),
      ]);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text(Ar.projectArchive), findsOneWidget);
      expect(find.text(Ar.projectRestore), findsNothing);
    });
  });

  group('W4.4 compatibility + behavior preservation', () {
    test('18. archive does not touch checklist_project_<id>', () async {
      const checklistKey = 'checklist_project_p1';
      SharedPreferences.setMockInitialValues({
        _kStorage: jsonEncode([
          _projectJson(id: 'p1', name: 'Checklist', createdAt: DateTime(2024, 1, 1)),
        ]),
        checklistKey: '{"ITEM-1":{"status":"pass"}}',
      });
      final repo = _repo();
      await repo.archiveProject('p1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(checklistKey), '{"ITEM-1":{"status":"pass"}}');
    });

    test('19. restore does not touch checklist_project_<id>', () async {
      const checklistKey = 'checklist_project_p1';
      SharedPreferences.setMockInitialValues({
        _kStorage: jsonEncode([
          _projectJson(id: 'p1', name: 'Checklist', createdAt: DateTime(2024, 1, 1), isArchived: true),
        ]),
        checklistKey: '{"ITEM-1":{"status":"pass"}}',
      });
      final repo = _repo();
      await repo.restoreProject('p1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(checklistKey), '{"ITEM-1":{"status":"pass"}}');
    });

    test('20. delete still removes the project after archive', () async {
      final repo = _repo();
      final created = await repo.createProject('Doomed');
      await repo.archiveProject(created.id);
      await repo.deleteProject(created.id);
      expect(await repo.loadProjects(), isEmpty);
    });
  });
}
