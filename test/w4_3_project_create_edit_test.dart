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
import 'package:civilpedia/features/projects/domain/project_name_policy.dart';
import 'package:civilpedia/features/tools/data/checklist/checklist_local_data_source.dart';
import 'package:civilpedia/features/tools/data/checklist/local_checklist_repository.dart';
import 'package:civilpedia/features/tools/data/checklist/local_project_repository.dart'
    as legacy_repo;
import 'package:civilpedia/features/tools/data/checklist/project_local_data_source.dart'
    as legacy_ds;
import 'package:civilpedia/features/tools/presentation/screens/checklist/checklist_screen.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/project_list_screen.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_status.dart';
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('W4.3 canonical ProjectNamePolicy (pure domain)', () {
    test('creates a trimmed name', () {
      expect(ProjectNamePolicy.createName('  Bridge  '), 'Bridge');
      expect(ProjectNamePolicy.createName('Bridge'), 'Bridge');
    });

    test('blank/whitespace create resolves to Untitled Project', () {
      expect(ProjectNamePolicy.createName(''), 'Untitled Project');
      expect(ProjectNamePolicy.createName('   '), 'Untitled Project');
    });

    test('blank/whitespace rename resolves to null (no change)', () {
      expect(ProjectNamePolicy.renameName(''), isNull);
      expect(ProjectNamePolicy.renameName('   '), isNull);
    });

    test('rename trims a non-blank name', () {
      expect(ProjectNamePolicy.renameName('  New  Name  '), 'New  Name');
    });
  });

  group('W4.3 Create (repository + UI)', () {
    testWidgets('1. Create UI opens from the ProjectList entry', (tester) async {
      await _pumpWithProjects(tester, []);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(Ar.projectCreateTitle), findsOneWidget);
    });

    testWidgets('2. entering a normal name creates the project', (tester) async {
      await _pumpWithProjects(tester, []);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'مشروع ١');
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();
      expect(find.text('مشروع ١'), findsOneWidget);
      expect(find.text(Ar.projectNoProjects), findsNothing);
    });

    testWidgets('3. create input is trimmed correctly', (tester) async {
      await _pumpWithProjects(tester, []);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '   محور  ', );
      // enterText replaces whole text; emulate a trailing-space input.
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();
      final sp = SharedPreferences.getInstance();
      final raw = jsonDecode((await sp).getString(_kStorage)!) as List;
      expect(raw.single['name'], 'محور');
    });

    testWidgets('4. blank/whitespace create preserves Untitled Project', (tester) async {
      await _pumpWithProjects(tester, []);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();
      expect(find.text('Untitled Project'), findsOneWidget);
    });

    testWidgets('5. cancel creates nothing', (tester) async {
      await _pumpWithProjects(tester, []);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.tap(find.text(Ar.cancel));
      await tester.pumpAndSettle();
      expect(find.text(Ar.projectNoProjects), findsOneWidget);
      final raw = jsonDecode(
          (await SharedPreferences.getInstance()).getString(_kStorage)!) as List;
      expect(raw, isEmpty);
    });

    test('6. new project gets a valid stable ID', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('ID Check');
      expect(p.id, startsWith('project_'));
      expect(p.id.length, greaterThan('project_'.length));
    });

    test('7. createdAt/updatedAt are assigned on creation', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Timestamps');
      expect(p.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))),
          isTrue);
      expect(p.updatedAt, p.createdAt);
    });

    test('8. new project is active / not archived', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Active');
      expect(p.isArchived, isFalse);
    });

    testWidgets('9. created project appears in the current list', (tester) async {
      await _pumpWithProjects(tester, []);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'ظاهر');
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();
      expect(find.text('ظاهر'), findsOneWidget);
    });
  });

  group('W4.3 Edit / Rename (repository + UI)', () {
    testWidgets('10. rename opens from the existing action', (tester) async {
      await _pumpWithProjects(tester, [
        _projectJson(id: 'p1', name: 'مشروع تجريبي', createdAt: DateTime(2026)),
      ]);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.projectRename));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(Ar.projectRenameTitle), findsOneWidget);
    });

    testWidgets('11. existing name is shown in the field', (tester) async {
      await _pumpWithProjects(tester, [
        _projectJson(id: 'p1', name: 'اسم قديم', createdAt: DateTime(2026)),
      ]);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.projectRename));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'اسم قديم'), findsOneWidget);
    });

    testWidgets('12. rename changes the name', (tester) async {
      await _pumpWithProjects(tester, [
        _projectJson(id: 'p1', name: 'اسم قديم', createdAt: DateTime(2026)),
      ]);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.projectRename));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'اسم جديد');
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();
      expect(find.text('اسم جديد'), findsOneWidget);
      expect(find.text('اسم قديم'), findsNothing);
    });

    test('13. rename keeps the exact same Project ID', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Before');
      final beforeId = p.id;
      await repo.updateProject(p.copyWith(name: 'After'));
      final loaded = (await repo.loadProjects()).single;
      expect(loaded.id, beforeId);
    });

    test('14. rename keeps createdAt', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Before');
      final beforeCreated = p.createdAt;
      await repo.updateProject(p.copyWith(name: 'After'));
      final loaded = (await repo.loadProjects()).single;
      expect(loaded.createdAt, beforeCreated);
    });

    test('15. rename keeps archive state', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Before');
      await repo.archiveProject(p.id);
      final archived = (await repo.loadProjects()).single;
      await repo.updateProject(archived.copyWith(name: 'After'));
      final loaded = (await repo.loadProjects()).single;
      expect(loaded.isArchived, isTrue);
      expect(loaded.name, 'After');
    });

    test('16. rename advances updatedAt', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final p = await repo.createProject('Before');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repo.updateProject(p.copyWith(name: 'After'));
      final loaded = (await repo.loadProjects()).single;
      expect(loaded.updatedAt.isAfter(p.updatedAt), isTrue);
    });

    testWidgets('17. cancel edit changes nothing', (tester) async {
      await _pumpWithProjects(tester, [
        _projectJson(id: 'p1', name: 'اسم قديم', createdAt: DateTime(2026)),
      ]);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.projectRename));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'اسم ملغي');
      await tester.tap(find.text(Ar.cancel));
      await tester.pumpAndSettle();
      expect(find.text('اسم قديم'), findsOneWidget);
      expect(find.text('اسم ملغي'), findsNothing);
    });

    testWidgets('18. blank/whitespace rename is a no-op', (tester) async {
      await _pumpWithProjects(tester, [
        _projectJson(id: 'p1', name: 'اسم قديم', createdAt: DateTime(2026)),
      ]);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.projectRename));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();
      expect(find.text('اسم قديم'), findsOneWidget);
      final raw =
          jsonDecode((await SharedPreferences.getInstance()).getString(_kStorage)!)
              as List;
      expect(raw.single['name'], 'اسم قديم');
    });
  });

  group('W4.3 domain / repository + serialization', () {
    test('19. create normalization works without UI', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final blank = await repo.createProject('   ');
      expect(blank.name, 'Untitled Project');
      final regular = await repo.createProject('  Alpha  ');
      expect(regular.name, 'Alpha');
    });

    test('20. edit normalization/validation works without UI', () async {
      expect(ProjectNamePolicy.renameName('   '), isNull);
      expect(ProjectNamePolicy.renameName(''), isNull);
      expect(ProjectNamePolicy.renameName(' X '), 'X');
    });

    test('21. duplicate names remain allowed (ID-based identity)', () async {
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      final a = await repo.createProject('Same');
      final b = await repo.createProject('Same');
      final all = await repo.loadProjects();
      expect(all, hasLength(2));
      expect(all.map((p) => p.name).toSet(), {'Same'});
      expect(a.id, isNot(b.id));
    });

    test('22. projects_list serialization remains compatible', () async {
      final now = DateTime(2024, 5, 6, 7, 8, 9, 123);
      final repo = canonical_repo.LocalProjectRepository(
        canonical_ds.ProjectLocalDataSource(),
      );
      await repo.replaceAll([
        Project(
          id: 'ser',
          name: 'Serial',
          createdAt: now,
          updatedAt: now,
          isArchived: true,
        ),
      ]);
      final raw = (await SharedPreferences.getInstance()).getString(_kStorage);
      expect(
        raw,
        jsonEncode([
          {
            'id': 'ser',
            'name': 'Serial',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'isArchived': true,
          },
        ]),
      );
    });
  });

  group('W4.3 compatibility + behavior preservation', () {
    test('24. legacy Tools import path still operates', () async {
      final legacy = legacy_repo.LocalProjectRepository(
        legacy_ds.ProjectLocalDataSource(),
      );
      final p = await legacy.createProject('Legacy Path');
      expect(p.name, 'Legacy Path');
      expect((await legacy.loadProjects()).single.name, 'Legacy Path');
    });

    test('25. checklist_project_<id> unaffected', () async {
      final checklist = LocalChecklistRepository(ChecklistLocalDataSource());
      await checklist.saveProjectItemStatus('pX', 'ITEM-1', InspectionStatus.fail);
      final gateway = ProjectPersistenceGateway();
      final raw = await gateway.readProjectChecklist('pX');
      expect(jsonDecode(raw!), {
        'ITEM-1': {'status': 'fail'},
      });
    });

    test('26. checklist_data unaffected', () async {
      final checklist = LocalChecklistRepository(ChecklistLocalDataSource());
      await checklist.saveItemStatus('GLB', InspectionStatus.pass);
      final gateway = ProjectPersistenceGateway();
      await gateway.writeProjects([
        Project(
          id: 'pid',
          name: 'N',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ]);
      final sp = await SharedPreferences.getInstance();
      expect(
        sp.getString('checklist_data'),
        '{"GLB":{"status":"pass"}}',
      );
    });

    testWidgets('27. archive behavior remains green', (tester) async {
      await _pumpWithProjects(tester, [
        _projectJson(id: 'p1', name: 'أرشفة', createdAt: DateTime(2026)),
      ]);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.projectArchive));
      await tester.pumpAndSettle();
      expect(find.text(Ar.projectNoProjects), findsOneWidget);
      final raw = jsonDecode(
          (await SharedPreferences.getInstance()).getString(_kStorage)!) as List;
      expect(raw.single['isArchived'], isTrue);
    });

    testWidgets('28. delete behavior remains green', (tester) async {
      await _pumpWithProjects(tester, [
        _projectJson(id: 'p1', name: 'حذف', createdAt: DateTime(2026)),
      ]);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.delete));
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, Ar.delete));
      await tester.pumpAndSettle();
      expect(find.text(Ar.projectNoProjects), findsOneWidget);
      final sp = await SharedPreferences.getInstance();
      expect(jsonDecode(sp.getString(_kStorage)!) as List, isEmpty);
    });

    testWidgets('29. project-to-checklist opening remains green', (tester) async {
      await _pumpWithProjects(tester, [
        _projectJson(id: 'p1', name: 'يفتح', createdAt: DateTime(2026)),
      ]);
      await tester.tap(find.text('يفتح'));
      await tester.pumpAndSettle();
      expect(find.byType(ChecklistScreen), findsOneWidget);
    });
  });
}
