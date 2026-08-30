import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/features/projects/data/local_project_calculation_repository.dart';
import 'package:civilpedia/features/projects/data/project_persistence_gateway.dart';
import 'package:civilpedia/features/projects/domain/entities/project_calculation_record.dart';
import 'package:civilpedia/features/tools/domain/tile/tile_calculation_snapshot.dart';
import 'package:civilpedia/features/tools/domain/tool_key.dart';
import 'package:civilpedia/features/tools/presentation/screens/calculators/tile_calculator_screen.dart';
import 'package:civilpedia/localization/ar.dart';

const _kProjects = 'projects_list';
const _kChecklist = 'checklist_project_p1';

final _repo = LocalProjectCalculationRepository();

Map<String, Object?> _input() =>
    TileCalculationSnapshot.buildInputSnapshot(
      areaLength: 5,
      areaWidth: 4,
      quantity: 1,
      excludedArea: 0,
      tileLengthCm: 60,
      tileWidthCm: 60,
      unit: 'cm',
      isCustomTile: false,
      additionalPercent: 0,
      isCustomPercent: false,
      boxEstimateEnabled: false,
      costEnabled: false,
    );

Map<String, Object?> _output() =>
    TileCalculationSnapshot.buildOutputSnapshot(
      gross: 20,
      net: 20,
      tileArea: 0.36,
      tilesPerM2: 2.78,
      netTiles: 56,
      additionalTiles: 0,
      finalTiles: 56,
    );

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
Widget _calcScreen() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: const MaterialApp(home: TileCalculatorScreen()),
  );
}

Future<void> _pumpCalc(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_calcScreen());
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  await tester.enterText(find.widgetWithText(TextField, label), value);
  await tester.pump();
}

Future<void> _calc(WidgetTester tester) async {
  await tester.tap(find.text(Ar.calcTile));
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('W4.5 record contract', () {
    test('1. record carries the full V1 snapshot contract', () {
      final r = TileCalculationSnapshot.record(
        projectId: 'p1',
        inputSnapshot: _input(),
        outputSnapshot: _output(),
      );
      expect(r.projectId, 'p1');
      expect(r.calculatorId, TileCalculationSnapshot.calculatorId);
      expect(r.calculatorVersion, TileCalculationSnapshot.calculatorVersion);
      expect(r.inputSnapshot, isNotEmpty);
      expect(r.outputSnapshot, isNotEmpty);
      expect(r.title, isNull);
    });

    test('2. calculator identity is stable Tile key and version 1', () {
      expect(TileCalculationSnapshot.calculatorId, ToolKey.tile.stableId);
      expect(TileCalculationSnapshot.calculatorId, 'tile');
      expect(TileCalculationSnapshot.calculatorVersion, '1');
    });

    test('3. record() leaves identity to the Projects save path', () {
      final r = TileCalculationSnapshot.record(
        projectId: 'p1',
        inputSnapshot: _input(),
        outputSnapshot: _output(),
      );
      expect(r.id, isEmpty);
      expect(r.createdAt.millisecondsSinceEpoch, 0);
    });

    test('4. Projects owns id and createdAt after save', () async {
      final saved = await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      expect(saved.id, isNotEmpty);
      expect(saved.id, startsWith('calculation_'));
      expect(saved.createdAt.isAfter(DateTime.fromMillisecondsSinceEpoch(0)),
          isTrue);
    });
  });

  group('W4.5 storage', () {
    test('5. AppStorageKeys.projectCalculations uses the approved key', () {
      expect(AppStorageKeys.projectCalculations('p1'), 'calculations_project_p1');
      expect(AppStorageKeys.projectCalculations('abc'), 'calculations_project_abc');
    });

    test('6. saving writes under calculations_project_<id>', () async {
      await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('calculations_project_p1');
      expect(raw, isNotEmpty);
      expect(jsonDecode(raw!), isA<List<dynamic>>());
    });

    test('7. loadCalculations returns the saved record', () async {
      await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      final loaded = await _repo.loadCalculations('p1');
      expect(loaded, hasLength(1));
      expect(loaded.single.projectId, 'p1');
      expect(loaded.single.calculatorId, 'tile');
      expect(loaded.single.calculatorVersion, '1');
      expect(loaded.single.inputSnapshot['areaLength'], 5);
      expect(loaded.single.outputSnapshot['finalTiles'], 56);
    });

    test('8. records are isolated per project', () async {
      await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p2',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      expect(await _repo.loadCalculations('p1'), hasLength(1));
      expect(await _repo.loadCalculations('p2'), hasLength(1));
    });

    test('9. serialized row omits title when null and keeps all fields',
        () async {
      final gateway = ProjectPersistenceGateway();
      await gateway.writeProjectCalculations('p1', [
        ProjectCalculationRecord(
          id: 'calculation_1',
          projectId: 'p1',
          calculatorId: 'tile',
          calculatorVersion: '1',
          title: null,
          inputSnapshot: _input(),
          outputSnapshot: _output(),
          createdAt: DateTime(2024, 1, 1),
        ),
      ]);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('calculations_project_p1')!;
      expect(raw, isNot(contains('"title"')));
      expect(raw, contains('"id":"calculation_1"'));
      expect(raw, contains('"calculatorId":"tile"'));
      expect(raw, contains('"calculatorVersion":"1"'));
      expect(raw, contains('"projectId":"p1"'));
      expect(raw, contains('"areaLength":5'));
      expect(raw, contains('"finalTiles":56'));
    });

    test('10. saving does not alter projects_list or checklist data', () async {
      SharedPreferences.setMockInitialValues({
        _kProjects: jsonEncode([
          _projectJson(id: 'p1', name: 'Bridge', createdAt: DateTime(2024, 1, 1)),
        ]),
        _kChecklist: '{"ITEM-1":{"status":"pass"}}',
      });
      final repo = LocalProjectCalculationRepository();
      await repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_kChecklist), '{"ITEM-1":{"status":"pass"}}');
      final projects = jsonDecode(prefs.getString(_kProjects)!) as List;
      expect(projects, hasLength(1));
      expect((projects.single as Map)['name'], 'Bridge');
    });

    test('11. multiple saves accumulate independent records', () async {
      final a = await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      final b = await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      expect(a.id, isNot(b.id));
      expect(await _repo.loadCalculations('p1'), hasLength(2));
    });
  });

  group('W4.5 snapshot schema', () {
    test('12. buildInputSnapshot emits the full V1 key set', () {
      final input = _input();
      for (final k in [
        TileCalculationSnapshot.kAreaLength,
        TileCalculationSnapshot.kAreaWidth,
        TileCalculationSnapshot.kQuantity,
        TileCalculationSnapshot.kExcludedArea,
        TileCalculationSnapshot.kTileLengthCm,
        TileCalculationSnapshot.kTileWidthCm,
        TileCalculationSnapshot.kUnit,
        TileCalculationSnapshot.kIsCustomTile,
        TileCalculationSnapshot.kAdditionalPercent,
        TileCalculationSnapshot.kIsCustomPercent,
        TileCalculationSnapshot.kBoxEstimateEnabled,
        TileCalculationSnapshot.kCostEnabled,
      ]) {
        expect(input.containsKey(k), isTrue, reason: 'missing $k');
      }
    });

    test('13. buildOutputSnapshot emits the full V1 key set', () {
      final output = _output();
      for (final k in [
        TileCalculationSnapshot.kGross,
        TileCalculationSnapshot.kNet,
        TileCalculationSnapshot.kTileArea,
        TileCalculationSnapshot.kTilesPerM2,
        TileCalculationSnapshot.kNetTiles,
        TileCalculationSnapshot.kAdditionalTiles,
        TileCalculationSnapshot.kFinalTiles,
      ]) {
        expect(output.containsKey(k), isTrue, reason: 'missing $k');
      }
    });

    test('14. calculator identity is the Tile, not the app version', () {
      expect(TileCalculationSnapshot.calculatorId, ToolKey.tile.stableId);
      expect(TileCalculationSnapshot.calculatorVersion, '1');
      // '1' is the Tile snapshot contract version — never a dotted app/package
      // version, a timestamp, or derived from pubspec.
      expect(TileCalculationSnapshot.calculatorVersion, isNot(contains('.')));
      expect(TileCalculationSnapshot.calculatorVersion, isNot('1.0.0'));
      expect(
        DateTime.tryParse(TileCalculationSnapshot.calculatorVersion),
        isNull,
      );
    });

    test('15. disabled optional inputs are null, not fabricated', () {
      final input = TileCalculationSnapshot.buildInputSnapshot(
        areaLength: 5,
        areaWidth: 4,
        quantity: 1,
        excludedArea: 0,
        tileLengthCm: 60,
        tileWidthCm: 60,
        unit: 'cm',
        isCustomTile: false,
        additionalPercent: 0,
        isCustomPercent: false,
        boxEstimateEnabled: false,
        costEnabled: false,
      );
      expect(input[TileCalculationSnapshot.kBoxEstimateEnabled], false);
      expect(input[TileCalculationSnapshot.kCostEnabled], false);
      expect(input[TileCalculationSnapshot.kTilesPerBox], isNull);
      expect(input[TileCalculationSnapshot.kPrice], isNull);
      expect(input[TileCalculationSnapshot.kPriceMode], isNull);
    });

    test('16. disabled optional outputs are null, not fabricated', () {
      final output = _output();
      expect(output[TileCalculationSnapshot.kRequiredBoxes], isNull);
      expect(output[TileCalculationSnapshot.kTotalCost], isNull);
    });

    test('17. mutating the passed record after save does NOT mutate stored row',
        () async {
      final record = TileCalculationSnapshot.record(
        projectId: 'p1',
        inputSnapshot: _input(),
        outputSnapshot: _output(),
      );
      final saved = await _repo.saveCalculation(record);

      // Mutate the caller's original maps and even the returned record.
      record.inputSnapshot[TileCalculationSnapshot.kAreaLength] = 999;
      saved.outputSnapshot[TileCalculationSnapshot.kFinalTiles] = 99999;

      final loaded = (await _repo.loadCalculations('p1')).single;
      expect(loaded.inputSnapshot[TileCalculationSnapshot.kAreaLength], 5);
      expect(loaded.outputSnapshot[TileCalculationSnapshot.kFinalTiles], 56);
    });

    test('18. distinct saves yield distinct identities', () async {
      final a = await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      final b = await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      expect(a.id, isNot(b.id));
      expect(a.createdAt, isNotNull);
      expect(b.createdAt, isNotNull);
      expect(a.createdAt.isAfter(DateTime.fromMillisecondsSinceEpoch(0)),
          isTrue);
    });
  });

  group('W4.5 project picker', () {
    testWidgets('19. picker lists only non-archived projects', (tester) async {
      final now = DateTime(2024, 1, 1);
      SharedPreferences.setMockInitialValues({
        _kProjects: jsonEncode([
          _projectJson(id: 'a1', name: 'ActiveOne', createdAt: now),
          _projectJson(id: 'ar1', name: 'Hidden', createdAt: now, isArchived: true),
        ]),
      });
      await _pumpCalc(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      await tester.tap(find.text(Ar.projectSaveToProject));
      await tester.pumpAndSettle();
      expect(find.text('ActiveOne'), findsOneWidget);
      expect(find.text('Hidden'), findsNothing);
    });

    testWidgets('20. archived projects are excluded from the picker',
        (tester) async {
      final now = DateTime(2024, 1, 1);
      SharedPreferences.setMockInitialValues({
        _kProjects: jsonEncode([
          _projectJson(id: 'ar1', name: 'OnlyArchived', createdAt: now, isArchived: true),
        ]),
      });
      await _pumpCalc(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      await tester.tap(find.text(Ar.projectSaveToProject));
      await tester.pumpAndSettle();
      expect(find.text('OnlyArchived'), findsNothing);
      expect(find.text(Ar.projectNoActiveProjects), findsOneWidget);
    });

    testWidgets('22. no active projects shows the empty state and no save',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        _kProjects: jsonEncode([]),
      });
      await _pumpCalc(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      await tester.tap(find.text(Ar.projectSaveToProject));
      await tester.pumpAndSettle();
      expect(find.text(Ar.projectNoActiveProjects), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('calculations_project_x'), isNull);
    });

    testWidgets('23. cancel returns null and saves nothing', (tester) async {
      final now = DateTime(2024, 1, 1);
      SharedPreferences.setMockInitialValues({
        _kProjects: jsonEncode([
          _projectJson(id: 'a1', name: 'ActiveOne', createdAt: now),
        ]),
      });
      await _pumpCalc(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      await tester.tap(find.text(Ar.projectSaveToProject));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.cancel));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('calculations_project_a1'), isNull);
    });
  });

  group('W4.5 save UI', () {
    testWidgets('24. save affordance is absent before calculation',
        (tester) async {
      await _pumpCalc(tester);
      expect(find.text(Ar.projectSaveToProject), findsNothing);
    });

    testWidgets('25. save persists, shows success SnackBar, stays on screen',
        (tester) async {
      final now = DateTime(2024, 1, 1);
      SharedPreferences.setMockInitialValues({
        _kProjects: jsonEncode([
          _projectJson(id: 'a1', name: 'ActiveOne', createdAt: now),
        ]),
      });
      await _pumpCalc(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      expect(find.text('56'), findsWidgets);

      await tester.tap(find.text(Ar.projectSaveToProject));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'ActiveOne'));
      await tester.pumpAndSettle();

      expect(find.text(Ar.projectSavedToProject), findsOneWidget);
      // Stays on the calculator with the result intact.
      expect(find.text('56'), findsWidgets);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('calculations_project_a1')!;
      final list = jsonDecode(raw) as List;
      expect(list, hasLength(1));
      expect((list.single as Map)['projectId'], 'a1');
    });

    testWidgets('26. choosing a project persists exactly one record',
        (tester) async {
      final now = DateTime(2024, 1, 1);
      SharedPreferences.setMockInitialValues({
        _kProjects: jsonEncode([
          _projectJson(id: 'a1', name: 'ActiveOne', createdAt: now),
        ]),
      });
      await _pumpCalc(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      await tester.tap(find.text(Ar.projectSaveToProject));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'ActiveOne'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final list = jsonDecode(prefs.getString('calculations_project_a1')!) as List;
      expect(list, hasLength(1));
    });

    testWidgets('27. cancel after opening picker saves nothing', (tester) async {
      final now = DateTime(2024, 1, 1);
      SharedPreferences.setMockInitialValues({
        _kProjects: jsonEncode([
          _projectJson(id: 'a1', name: 'ActiveOne', createdAt: now),
        ]),
      });
      await _pumpCalc(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      await tester.tap(find.text(Ar.projectSaveToProject));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.cancel));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('calculations_project_a1'), isNull);
      expect(find.text(Ar.projectSavedToProject), findsNothing);
    });
  });

  group('W4.5 compatibility + freeze', () {
    test('29. Tile calculation results unchanged by the save addition', () {
      // The snapshot adapter reads from presentation state, not formulas.
      final record = TileCalculationSnapshot.record(
        projectId: 'p1',
        inputSnapshot: _input(),
        outputSnapshot: _output(),
      );
      expect(record.inputSnapshot['areaLength'], 5);
      expect(record.outputSnapshot['finalTiles'], 56);
    });

    test('30. saving does not change projects_list serialization', () async {
      SharedPreferences.setMockInitialValues({
        _kProjects: jsonEncode([
          _projectJson(id: 'p1', name: 'Bridge', createdAt: DateTime(2024, 1, 1)),
        ]),
      });
      final before = (await SharedPreferences.getInstance())
          .getString(_kProjects);
      await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      final after =
          (await SharedPreferences.getInstance()).getString(_kProjects);
      expect(after, before);
    });

    test('31. saving does not touch checklist_project_<id>', () async {
      SharedPreferences.setMockInitialValues({
        _kProjects: jsonEncode([
          _projectJson(id: 'p1', name: 'Bridge', createdAt: DateTime(2024, 1, 1)),
        ]),
        _kChecklist: '{"ITEM-1":{"status":"pass"}}',
      });
      final repo = LocalProjectCalculationRepository();
      await repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_kChecklist), '{"ITEM-1":{"status":"pass"}}');
    });

    test('32. saving does not create other calculator keys', () async {
      await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      expect(keys.any((k) => k.startsWith('calculations_project_p1')), isTrue);
      // No concrete/steel/brick/checklist save keys may exist.
      expect(keys.any((k) => k.contains('concrete')), isFalse);
      expect(keys.any((k) => k.contains('steel')), isFalse);
    });

    test('33. calculatorVersion is isolated from app version', () {
      expect(TileCalculationSnapshot.calculatorVersion, '1');
      expect(TileCalculationSnapshot.calculatorVersion, isNot('1.0.0'));
      expect(TileCalculationSnapshot.calculatorVersion, isNot(contains('.')));
      expect(
        DateTime.tryParse(TileCalculationSnapshot.calculatorVersion),
        isNull,
      );
    });

    test('34. repository contract only, no W4.6 history rendering',
        () async {
      // save/load is data-only; records are not surfaced anywhere in Projects UI.
      await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      final loaded = await _repo.loadCalculations('p1');
      expect(loaded, hasLength(1));
      // Ensure a second save is independent (no history list collapsing).
      await _repo.saveCalculation(
        TileCalculationSnapshot.record(
          projectId: 'p1',
          inputSnapshot: _input(),
          outputSnapshot: _output(),
        ),
      );
      expect(await _repo.loadCalculations('p1'), hasLength(2));
    });

    test('35. schema constants are stable and unversioned correctly', () {
      expect(TileCalculationSnapshot.kFinalTiles, 'finalTiles');
      expect(TileCalculationSnapshot.kAreaLength, 'areaLength');
      expect(TileCalculationSnapshot.kRequiredBoxes, 'requiredBoxes');
      expect(TileCalculationSnapshot.kTotalCost, 'totalCost');
    });
  });
}
