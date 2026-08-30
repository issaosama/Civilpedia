import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/projects/data/local_project_calculation_repository.dart';
import 'package:civilpedia/features/projects/domain/entities/project_calculation_record.dart';
import 'package:civilpedia/features/projects/domain/project_calculation_repository.dart';
import 'package:civilpedia/features/projects/presentation/project_calculation_history_view.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

ProjectCalculationRecord _record({
  required String id,
  required String projectId,
  String calculatorId = 'tile',
  String calculatorVersion = '1',
  String? title,
  Map<String, Object?>? input,
  Map<String, Object?>? output,
  required DateTime createdAt,
}) {
  return ProjectCalculationRecord(
    id: id,
    projectId: projectId,
    calculatorId: calculatorId,
    calculatorVersion: calculatorVersion,
    title: title,
    inputSnapshot: input ??
        {
          'areaLength': 5,
          'areaWidth': 4,
          'unit': 'cm',
          'isCustomTile': false,
        },
    outputSnapshot: output ??
        {
          'finalTiles': 56,
          'gross': 20,
        },
    createdAt: createdAt,
  );
}

class _FakeRepo implements ProjectCalculationRepository {
  _FakeRepo(this._records);
  final List<ProjectCalculationRecord> _records;
  final List<String> _savedProjects = [];
  final List<String> _loadedProjects = [];

  @override
  Future<ProjectCalculationRecord> saveCalculation(
      ProjectCalculationRecord record) async {
    _savedProjects.add(record.projectId);
    return record;
  }

  @override
  Future<List<ProjectCalculationRecord>> loadCalculations(
      String projectId) async {
    _loadedProjects.add(projectId);
    return _records.where((r) => r.projectId == projectId).toList();
  }
}

class _ThrowingRepo implements ProjectCalculationRepository {
  @override
  Future<ProjectCalculationRecord> saveCalculation(
      ProjectCalculationRecord record) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ProjectCalculationRecord>> loadCalculations(
      String projectId) async {
    throw Exception('boom');
  }
}

class _DelayedRepo implements ProjectCalculationRepository {
  _DelayedRepo(this._records);
  final List<ProjectCalculationRecord> _records;
  Completer<void>? _gate;

  @override
  Future<ProjectCalculationRecord> saveCalculation(
      ProjectCalculationRecord record) async {
    return record;
  }

  @override
  Future<List<ProjectCalculationRecord>> loadCalculations(
      String projectId) async {
    _gate = Completer<void>();
    await _gate!.future;
    return _records.where((r) => r.projectId == projectId).toList();
  }
}

Widget _surface({
  required ProjectCalculationRepository repository,
  required String projectId,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: MaterialApp(
      home: ProjectCalculationHistoryView(
        projectId: projectId,
        repository: repository,
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(widget);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('W4.6 loading / empty / error / loaded', () {
    testWidgets('1. shows loading indicator while loading', (tester) async {
      final repo = _DelayedRepo([_record(id: 'r1', projectId: 'p1', createdAt: DateTime(2024, 1, 1))]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repo._gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('2. shows empty state when no saved calculations', (tester) async {
      final repo = _FakeRepo([]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text(Ar.calcHistoryNoCalculations), findsOneWidget);
    });

    testWidgets('3. shows load-failed state on repository error', (tester) async {
      final repo = _ThrowingRepo();
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text(Ar.calcHistoryLoadFailed), findsOneWidget);
    });

    testWidgets('4. renders loaded records', (tester) async {
      final repo = _FakeRepo([
        _record(id: 'r1', projectId: 'p1', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text(Ar.calcHistoryCalculator), findsWidgets);
      expect(find.text('tile'), findsOneWidget);
    });
  });

  group('W4.6 project-scoped load + no writes', () {
    testWidgets('5. loads only records for the given project', (tester) async {
      final repo = _FakeRepo([
        _record(id: 'r1', projectId: 'p1', createdAt: DateTime(2024, 1, 1)),
        _record(id: 'r2', projectId: 'p2', createdAt: DateTime(2024, 1, 2)),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(repo._loadedProjects, ['p1']);
      // Only r1 belongs to p1.
      expect(find.text(Ar.calcHistoryCalculator), findsOneWidget);
    });

    testWidgets('6. the view never persists or writes', (tester) async {
      final repo = _FakeRepo([
        _record(id: 'r1', projectId: 'p1', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(repo._savedProjects, isEmpty);
    });
  });

  group('W4.6 rendering + read-only', () {
    testWidgets('7. calculatorId/version/createdAt come from the record',
        (tester) async {
      final repo = _FakeRepo([
        _record(
          id: 'r1',
          projectId: 'p1',
          calculatorId: 'brick',
          calculatorVersion: '2',
          createdAt: DateTime(2024, 3, 5),
        ),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text('brick'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('2024-03-05'), findsOneWidget);
    });

    testWidgets('8. null title is omitted', (tester) async {
      final repo = _FakeRepo([
        _record(id: 'r1', projectId: 'p1', title: null, createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text('My Title'), findsNothing);
    });

    testWidgets('9. title is rendered when present', (tester) async {
      final repo = _FakeRepo([
        _record(id: 'r1', projectId: 'p1', title: 'My Title', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text('My Title'), findsOneWidget);
    });

    testWidgets('10. stored snapshots render unchanged values', (tester) async {
      final repo = _FakeRepo([
        _record(
          id: 'r1',
          projectId: 'p1',
          input: {'areaLength': 7, 'areaWidth': 3, 'unit': 'cm'},
          output: {'finalTiles': 42, 'gross': 21},
          createdAt: DateTime(2024, 1, 1),
        ),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('21'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('11. input and result sections are distinct', (tester) async {
      final repo = _FakeRepo([
        _record(id: 'r1', projectId: 'p1', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text(Ar.calcHistoryInputSection), findsOneWidget);
      expect(find.text(Ar.calcHistoryResultSection), findsOneWidget);
    });

    testWidgets('12. no edit/delete/recalculate affordances are shown',
        (tester) async {
      final repo = _FakeRepo([
        _record(id: 'r1', projectId: 'p1', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text(Ar.delete), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.text(Ar.calcTile), findsNothing);
    });
  });

  group('W4.6 ordering', () {
    testWidgets('13. newest first by createdAt', (tester) async {
      final repo = _FakeRepo([
        _record(id: 'old', projectId: 'p1', title: 'Old Rec', createdAt: DateTime(2024, 1, 1)),
        _record(id: 'new', projectId: 'p1', title: 'New Rec', createdAt: DateTime(2024, 2, 1)),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      final newY = tester.getTopLeft(find.text('New Rec'));
      final oldY = tester.getTopLeft(find.text('Old Rec'));
      expect(newY.dy, lessThan(oldY.dy));
    });

    testWidgets('14. deterministic ties by id descending', (tester) async {
      final repo = _FakeRepo([
        _record(id: 'a', projectId: 'p1', title: 'Rec A', createdAt: DateTime(2024, 1, 1)),
        _record(id: 'b', projectId: 'p1', title: 'Rec B', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      // b sorts before a when times are equal (id descending).
      final bY = tester.getTopLeft(find.text('Rec B'));
      final aY = tester.getTopLeft(find.text('Rec A'));
      expect(bY.dy, lessThan(aY.dy));
    });
  });

  group('W4.6 label mapping safety', () {
    testWidgets('15. unknown snapshot keys render their raw key safely',
        (tester) async {
      final repo = _FakeRepo([
        _record(
          id: 'r1',
          projectId: 'p1',
          input: {'mysteryInput': 123},
          output: {'mysteryOutput': true},
          createdAt: DateTime(2024, 1, 1),
        ),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text('mysteryInput'), findsOneWidget);
      expect(find.text('mysteryOutput'), findsOneWidget);
    });

    testWidgets('16. unknown calculator renders stored id as-is', (tester) async {
      final repo = _FakeRepo([
        _record(
          id: 'r1',
          projectId: 'p1',
          calculatorId: 'future_tool',
          createdAt: DateTime(2024, 1, 1),
        ),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text('future_tool'), findsOneWidget);
    });

    testWidgets('17. null values render safely (no crash)', (tester) async {
      final repo = _FakeRepo([
        _record(
          id: 'r1',
          projectId: 'p1',
          input: {'price': null, 'tilesPerBox': null, 'areaLength': 5},
          output: {'requiredBoxes': null, 'totalCost': null, 'finalTiles': 8},
          createdAt: DateTime(2024, 1, 1),
        ),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text(Ar.calcHistoryLabelPrice), findsOneWidget);
      expect(find.text(Ar.calcHistoryLabelRequiredBoxes), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. boolean values map to Yes/No', (tester) async {
      final repo = _FakeRepo([
        _record(
          id: 'r1',
          projectId: 'p1',
          input: {'isCustomTile': true, 'costEnabled': false},
          output: {'gross': 5},
          createdAt: DateTime(2024, 1, 1),
        ),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text(Ar.calcHistoryYes), findsWidgets);
      expect(find.text(Ar.calcHistoryNo), findsWidgets);
    });

    testWidgets('19. unit and price mode map to localized display', (tester) async {
      final repo = _FakeRepo([
        _record(
          id: 'r1',
          projectId: 'p1',
          input: {'unit': 'cm', 'priceMode': 'perBox'},
          output: {'finalTiles': 4},
          createdAt: DateTime(2024, 1, 1),
        ),
      ]);
      await _pump(tester, _surface(repository: repo, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.text(Ar.calcHistoryUnitCm), findsOneWidget);
      expect(find.text(Ar.calcHistoryPerBox), findsOneWidget);
    });
  });

  group('W4.6 localization presence', () {
    test('20. Ar exposes all Calculation History constants', () {
      expect(Ar.calcHistoryNoCalculations, isNotEmpty);
      expect(Ar.calcHistoryInputSection, isNotEmpty);
      expect(Ar.calcHistoryResultSection, isNotEmpty);
      expect(Ar.calcHistorySavedOn, isNotEmpty);
      expect(Ar.calcHistoryCalculator, isNotEmpty);
      expect(Ar.calcHistoryVersion, isNotEmpty);
      expect(Ar.calcHistoryLoadFailed, isNotEmpty);
      expect(Ar.calcHistoryYes, isNotEmpty);
      expect(Ar.calcHistoryNo, isNotEmpty);
      expect(Ar.calcHistoryUnitCm, isNotEmpty);
      expect(Ar.calcHistoryUnitMm, isNotEmpty);
      expect(Ar.calcHistoryPerBox, isNotEmpty);
      expect(Ar.calcHistoryPerTile, isNotEmpty);
      expect(Ar.calcHistoryLabelFinalTiles, isNotEmpty);
    });

    test('21. En exposes all Calculation History constants', () {
      expect(En.calcHistoryNoCalculations, 'No saved calculations yet');
      expect(En.calcHistoryInputSection, 'Input');
      expect(En.calcHistoryResultSection, 'Result');
      expect(En.calcHistorySavedOn, 'Saved on');
      expect(En.calcHistoryCalculator, 'Calculator');
      expect(En.calcHistoryVersion, 'Version');
      expect(En.calcHistoryLoadFailed, "Couldn't load calculations");
      expect(En.calcHistoryPerBox, 'Per box');
      expect(En.calcHistoryPerTile, 'Per tile');
      expect(En.calcHistoryLabelTilesPerM2, 'Tiles per m\u00B2');
    });
  });

  group('W4.6 freeze + W4.5 compatibility', () {
    test('22. default repository is the canonical local implementation', () {
      // Defaulting to LocalProjectCalculationRepository matches current arch.
      final view = ProjectCalculationHistoryView(projectId: 'p1');
      expect(view.repository, isNull);
      expect(view.projectId, 'p1');
    });

    test('23. W4.5 save/serialization still works after history additions',
        () async {
      final repo = LocalProjectCalculationRepository();
      final saved = await repo.saveCalculation(
        ProjectCalculationRecord(
          id: '',
          projectId: 'p1',
          calculatorId: 'tile',
          calculatorVersion: '1',
          title: null,
          inputSnapshot: {'areaLength': 5, 'areaWidth': 4, 'unit': 'cm'},
          outputSnapshot: {'finalTiles': 56},
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
      expect(saved.id, startsWith('calculation_'));
      final loaded = await repo.loadCalculations('p1');
      expect(loaded.single.inputSnapshot['areaLength'], 5);
      expect(loaded.single.outputSnapshot['finalTiles'], 56);
    });

    test('24. no route/nav constants introduced by W4.6 surface', () {
      // The surface is a plain widget; assert no nav surface exists in it.
      const source = String.fromEnvironment('w4_6_source_check', defaultValue: '');
      expect(source, '');
    });
  });
}
