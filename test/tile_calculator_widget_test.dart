import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/tools/presentation/screens/calculators/tile_calculator_screen.dart';
import 'package:civilpedia/localization/ar.dart';

Widget _screen() => const MaterialApp(home: TileCalculatorScreen());

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
  await tester.pumpWidget(_screen());
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
  group('Tile Calculator widget', () {
    testWidgets('60×60 cm, 5 m × 4 m → 56 tiles', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      // 20 / 0.36 = 55.56 → ceil 56
      expect(find.text('56'), findsNWidgets(2)); // net tiles + final tiles
    });

    testWidgets('quantity 2 doubles the count', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _enter(tester, Ar.tileQuantity, '2');
      await _calc(tester);
      expect(find.text('112'), findsNWidgets(2)); // 40 / 0.36 = 111.11 → ceil 112
    });

    testWidgets('excluded area reduces tile count', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _enter(tester, Ar.tileExcludedArea, '2');
      await _calc(tester);
      // 18 / 0.36 = 50
      expect(find.text('50'), findsNWidgets(2));
    });

    testWidgets('30×30 cm preset works', (tester) async {
      await _pump(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, '30×30 سم'));
      await tester.pump();
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      // 20 / 0.09 = 222.22 → ceil 223
      expect(find.text('223'), findsNWidgets(2));
    });

    testWidgets('custom tile size works', (tester) async {
      await _pump(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.tileCustomSize).first);
      await tester.pump();
      await _enter(tester, '${Ar.tileLength} (سم)', '80');
      await _enter(tester, '${Ar.tileWidth} (سم)', '80');
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      // 20 / 0.64 = 31.25 → ceil 32
      expect(find.text('32'), findsNWidgets(2));
    });

    testWidgets('additional 5% adds extra tiles', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await tester.tap(find.text('5%'));
      await tester.pump();
      await _calc(tester);
      // ceil(55.56*1.05=58.33)=59 final, 59-56=3 additional
      expect(find.text('59'), findsOneWidget); // final row
      expect(find.text('3'), findsOneWidget); // additional
    });

    testWidgets('excluded area > gross shows validation', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _enter(tester, Ar.tileExcludedArea, '25');
      await _calc(tester);
      expect(find.text(Ar.tileExcludedExceed), findsOneWidget);
    });

    testWidgets('zero surface length shows validation', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '0');
      await _calc(tester);
      expect(find.text(Ar.invalidInputs), findsOneWidget);
    });

    testWidgets('reset restores defaults', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      expect(find.text('56'), findsWidgets);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.text('56'), findsNothing);
    });

    testWidgets('changing tile preset invalidates result', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      expect(find.text('56'), findsWidgets);

      await tester.tap(find.widgetWithText(ChoiceChip, '40×40 سم'));
      await tester.pump();
      expect(find.text('56'), findsNothing);
    });

    // ── Box Estimate ──
    testWidgets('Box Estimate is disabled by default', (tester) async {
      await _pump(tester);
      expect(find.widgetWithText(TextField, Ar.tileTilesPerBoxLabel), findsNothing);
    });

    testWidgets('enabling Box Estimate shows Tiles-per-Box with no default', (tester) async {
      await _pump(tester);
      final row = find.ancestor(of: find.text(Ar.tileBoxEstimate), matching: find.byType(Row)).first;
      await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
      await tester.pump();

      final f = tester.widget<TextField>(find.widgetWithText(TextField, Ar.tileTilesPerBoxLabel));
      expect(f.controller!.text, isEmpty);
    });

    testWidgets('53 final tiles / 10 per box = 6 boxes', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '3.6');
      // 5×3.6=18, 60×60 tile=0.36, raw=50
      await tester.tap(find.text('5%'));
      await tester.pump();
      // final = ceil(50×1.05=52.5)=53
      final row = find.ancestor(of: find.text(Ar.tileBoxEstimate), matching: find.byType(Row)).first;
      await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
      await tester.pump();
      await _enter(tester, Ar.tileTilesPerBoxLabel, '10');
      await _calc(tester);

      // 53/10=5.3 → ceil 6 (uses FINAL tiles)
      final boxRow = find.ancestor(of: find.text('${Ar.requiredBoxes}:'), matching: find.byType(Row)).first;
      final boxVal = find.descendant(of: boxRow, matching: find.byType(Text)).last;
      expect(tester.widget<Text>(boxVal).data, '6');
    });

    testWidgets('empty Tiles per Box does not hide core result', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      expect(find.text('56'), findsWidgets);

      final row = find.ancestor(of: find.text(Ar.tileBoxEstimate), matching: find.byType(Row)).first;
      await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
      await tester.pump();
      expect(find.text('56'), findsWidgets);
    });

    testWidgets('editing Tiles per Box updates boxes without hiding core', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);

      final row = find.ancestor(of: find.text(Ar.tileBoxEstimate), matching: find.byType(Row)).first;
      await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
      await tester.pump();
      await _enter(tester, Ar.tileTilesPerBoxLabel, '10');
      expect(find.text('56'), findsWidgets); // core still present
    });

    // ── Cost Estimate ──
    testWidgets('Cost Estimate is disabled by default', (tester) async {
      await _pump(tester);
      expect(find.widgetWithText(TextField, Ar.pricePerTile), findsNothing);
      expect(find.widgetWithText(TextField, Ar.pricePerBox), findsNothing);
    });

    testWidgets('per-tile cost: 56 final × 1000 = 56000', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);

      final row = find.ancestor(of: find.text(Ar.tileCostEstimate), matching: find.byType(Row)).first;
      await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
      await tester.pump();
      await _enter(tester, Ar.pricePerTile, '1000');
      expect(find.text('56'), findsWidgets); // core still present
      expect(find.text('56000'), findsOneWidget);
    });

    testWidgets('per-box cost needs valid Tiles per Box', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);

      // Enable Box + enter tpb
      var boxRow = find.ancestor(of: find.text(Ar.tileBoxEstimate), matching: find.byType(Row)).first;
      await tester.tap(find.descendant(of: boxRow, matching: find.byType(Switch)));
      await tester.pump();
      await _enter(tester, Ar.tileTilesPerBoxLabel, '10');

      // Enable Cost + tap per-box chip
      var costRow = find.ancestor(of: find.text(Ar.tileCostEstimate), matching: find.byType(Row)).first;
      await tester.tap(find.descendant(of: costRow, matching: find.byType(Switch)));
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.pricePerBox));
      await tester.pump();
      await _enter(tester, Ar.pricePerBox, '5000');

      expect(find.text('56'), findsWidgets); // core still present
      // 56/10=5.6 → ceil 6 boxes, 6×5000=30000
      expect(find.text('30000'), findsOneWidget);
    });

    testWidgets('per-box without tpb shows no cost, core stays valid', (tester) async {
      await _pump(tester);
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      expect(find.text('56'), findsWidgets);

      var costRow = find.ancestor(of: find.text(Ar.tileCostEstimate), matching: find.byType(Row)).first;
      await tester.tap(find.descendant(of: costRow, matching: find.byType(Switch)));
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.pricePerBox));
      await tester.pump();
      await _enter(tester, Ar.pricePerBox, '5000');

      // per-box cost uses _tpb which is 0 (empty), no cost row
      expect(find.text('56'), findsWidgets);
      expect(find.text('${Ar.totalCost}:'), findsNothing);
    });

    // ── cm/mm unit UX ──
    testWidgets('preset mode does not show the cm/mm unit selector', (tester) async {
      await _pump(tester);
      expect(find.widgetWithText(ChoiceChip, Ar.unitCm), findsNothing);
      expect(find.widgetWithText(ChoiceChip, Ar.unitMm), findsNothing);
    });

    testWidgets('preset label explicitly communicates cm', (tester) async {
      await _pump(tester);
      expect(find.widgetWithText(ChoiceChip, '60×60 سم'), findsOneWidget);
    });

    testWidgets('selecting Custom reveals the cm/mm unit selector', (tester) async {
      await _pump(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.tileCustomSize).first);
      await tester.pump();
      expect(find.widgetWithText(ChoiceChip, Ar.unitCm), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, Ar.unitMm), findsOneWidget);
    });

    testWidgets('custom 600 mm = 60 cm gives same tile count', (tester) async {
      await _pump(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.tileCustomSize).first);
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.unitMm));
      await tester.pump();
      await _enter(tester, '${Ar.tileLength} (${Ar.unitMm})', '600');
      await _enter(tester, '${Ar.tileWidth} (${Ar.unitMm})', '600');
      await _enter(tester, '${Ar.areaLength} (${Ar.meters})', '5');
      await _enter(tester, '${Ar.areaWidth} (${Ar.meters})', '4');
      await _calc(tester);
      expect(find.text('56'), findsNWidgets(2));
    });

    testWidgets('returning from Custom to preset hides the unit selector',
        (tester) async {
      await _pump(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.tileCustomSize).first);
      await tester.pump();
      expect(find.widgetWithText(ChoiceChip, Ar.unitCm), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '60×60 سم'));
      await tester.pump();
      expect(find.widgetWithText(ChoiceChip, Ar.unitCm), findsNothing);
    });
  });
}
