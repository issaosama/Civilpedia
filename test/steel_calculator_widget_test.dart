import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/tools/presentation/screens/calculators/calculator_screen.dart';
import 'package:civilpedia/localization/ar.dart';

Widget _screen() => const MaterialApp(home: CalculatorScreen(type: 'steel'));

Future<void> _pumpSteel(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_screen());
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  await tester.enterText(find.widgetWithText(TextField, label), value);
  await tester.pump();
}

Future<void> _calculate(WidgetTester tester) async {
  await tester.tap(find.text(Ar.calculate));
  await tester.pump();
}

Future<void> _toggleSection(WidgetTester tester, String label) async {
  final row =
      find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
  await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
  await tester.pump();
}

Text _rowValue(WidgetTester tester, String label) {
  final row =
      find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
  final value = find.descendant(of: row, matching: find.byType(Text)).last;
  return tester.widget<Text>(value);
}

void main() {
  group('Steel Calculator widget', () {
    testWidgets('main Bar Length defaults to 12 m', (tester) async {
      await _pumpSteel(tester);
      final field = tester.widget<TextField>(
          find.widgetWithText(TextField, Ar.steelBarLength));
      expect(field.controller!.text, '12');
    });

    testWidgets('core calculation works with the visible 12 m default',
        (tester) async {
      await _pumpSteel(tester);
      await _calculate(tester);

      expect(find.text('10.654 كجم'), findsOneWidget);
      expect(find.text('10.65 كجم'), findsOneWidget);
      expect(find.text('93'), findsOneWidget);
    });

    testWidgets('16 mm × 12 m × 10 shows the expected weights',
        (tester) async {
      await _pumpSteel(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, '16'));
      await tester.pump();
      await _enter(tester, Ar.quantity, '10');
      await _calculate(tester);

      expect(find.textContaining('الوزن لكل متر: 1.578 كجم/م'), findsOneWidget);
      expect(find.text('18.940 كجم'), findsOneWidget);
      expect(find.text('120.00 م'), findsOneWidget);
      expect(find.text('189.40 كجم'), findsOneWidget);
      expect(find.text('0.189 طن'), findsOneWidget);
      expect(find.text('52'), findsOneWidget);
    });

    testWidgets('custom diameter 8 mm computes via the formula',
        (tester) async {
      await _pumpSteel(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.wasteCustom).first);
      await tester.pump();
      await _enter(tester, '${Ar.diameter} (${Ar.unitMm})', '8');
      await _calculate(tester);

      expect(find.textContaining('الوزن لكل متر: 0.395 كجم/م'), findsOneWidget);
      expect(find.text('4.735 كجم'), findsOneWidget);
      expect(find.text('4.74 كجم'), findsOneWidget);
    });

    testWidgets('optional additional 5% adds extra weight', (tester) async {
      await _pumpSteel(tester);
      await tester.tap(find.text('5%'));
      await tester.pump();
      await _calculate(tester);

      expect(find.text('10.654 كجم'), findsOneWidget);
      expect(find.text('10.65 كجم'), findsOneWidget);
      expect(find.textContaining('الوزن الإضافي (5%)'), findsOneWidget);
      expect(find.text('0.53 كجم'), findsOneWidget);
      expect(find.text('11.19 كجم'), findsOneWidget);
    });

    testWidgets('quantity zero shows a quantity error', (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.quantity, '0');
      await _calculate(tester);

      expect(find.text(Ar.invalidQuantity), findsOneWidget);
    });

    testWidgets('empty length shows a validation error', (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.steelBarLength, '');
      await _calculate(tester);

      expect(find.text(Ar.invalidInputs), findsOneWidget);
    });

    testWidgets('empty custom additional percent shows a validation error',
        (tester) async {
      await _pumpSteel(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.wasteCustom).last);
      await tester.pump();
      await _calculate(tester);

      expect(find.text(Ar.invalidInputs), findsOneWidget);
    });

    testWidgets('reset clears fields, results and restores defaults',
        (tester) async {
      await _pumpSteel(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, '16'));
      await tester.pump();
      await _enter(tester, Ar.quantity, '10');
      await _calculate(tester);
      expect(find.text('189.40 كجم'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.text('189.40 كجم'), findsNothing);
      final qtyField = tester.widget<TextField>(
          find.widgetWithText(TextField, Ar.quantity));
      expect(qtyField.controller!.text, '1');
      final lenField = tester.widget<TextField>(
          find.widgetWithText(TextField, Ar.steelBarLength));
      expect(lenField.controller!.text, '12');
      expect(find.widgetWithText(TextField,
          '${Ar.steelStockLength} (${Ar.meters})'), findsNothing);
    });

    testWidgets('changing an input after calculation invalidates results',
        (tester) async {
      await _pumpSteel(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, '16'));
      await tester.pump();
      await _enter(tester, Ar.quantity, '10');
      await _calculate(tester);
      expect(find.text('189.40 كجم'), findsOneWidget);

      await _enter(tester, Ar.steelBarLength, '6');
      expect(find.text('189.40 كجم'), findsNothing);

      await _calculate(tester);
      expect(find.text('94.70 كجم'), findsOneWidget);
    });

    testWidgets('changing diameter after calculation invalidates results',
        (tester) async {
      await _pumpSteel(tester);
      await _calculate(tester);
      expect(find.text('10.65 كجم'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '20'));
      await tester.pump();

      expect(find.text('10.65 كجم'), findsNothing);
      expect(find.textContaining('الوزن لكل متر: 2.466 كجم/م'), findsOneWidget);
    });

    testWidgets('procurement section is optional and collapsed by default',
        (tester) async {
      await _pumpSteel(tester);
      expect(find.widgetWithText(TextField,
          '${Ar.steelStockLength} (${Ar.meters})'), findsNothing);
      expect(find.text(Ar.steelProcurementEstimate), findsOneWidget);
    });

    testWidgets(
        'stock bar length defaults visibly to 12 m when procurement enabled',
        (tester) async {
      await _pumpSteel(tester);
      await _toggleSection(tester, Ar.steelProcurementEstimate);
      final field = tester.widget<TextField>(find.widgetWithText(
          TextField, '${Ar.steelStockLength} (${Ar.meters})'));
      expect(field.controller!.text, '12');
    });

    testWidgets('6 m required / 12 m stock / qty 10 => 5 stock bars',
        (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.steelBarLength, '6');
      await _enter(tester, Ar.quantity, '10');
      await _toggleSection(tester, Ar.steelProcurementEstimate);
      await _calculate(tester);

      expect(_rowValue(tester, '${Ar.steelBarsPerStockBar}:').data, '2');
      expect(_rowValue(tester, '${Ar.steelBarsRequired}:').data, '5');
    });

    testWidgets('7 m required / 12 m stock / qty 10 => 10 stock bars',
        (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.steelBarLength, '7');
      await _enter(tester, Ar.quantity, '10');
      await _toggleSection(tester, Ar.steelProcurementEstimate);
      await _calculate(tester);

      expect(_rowValue(tester, '${Ar.steelBarsPerStockBar}:').data, '1');
      expect(_rowValue(tester, '${Ar.steelBarsRequired}:').data, '10');
    });

    testWidgets('12 m required / 12 m stock is valid procurement',
        (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.quantity, '5');
      await _toggleSection(tester, Ar.steelProcurementEstimate);
      await _calculate(tester);

      expect(_rowValue(tester, '${Ar.steelBarsPerStockBar}:').data, '1');
      expect(_rowValue(tester, '${Ar.steelBarsRequired}:').data, '5');
      expect(find.text(Ar.steelStockShorter), findsNothing);
    });

    testWidgets(
        '14 m required / 12 m stock shows procurement validation, no splice',
        (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.steelBarLength, '14');
      await _toggleSection(tester, Ar.steelProcurementEstimate);
      await _calculate(tester);

      expect(find.text(Ar.steelStockShorter), findsOneWidget);
      expect(find.text('${Ar.steelBarsRequired}:'), findsNothing);
      expect(find.text('${Ar.steelBarsPerStockBar}:'), findsNothing);
    });

    testWidgets('invalid procurement does not invalidate core steel-weight result',
        (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.steelBarLength, '14');
      await _toggleSection(tester, Ar.steelProcurementEstimate);
      await _calculate(tester);

      expect(find.text(Ar.steelStockShorter), findsOneWidget);
      expect(find.text(Ar.invalidInputs), findsNothing);
      expect(find.text('12.43 كجم'), findsOneWidget);
    });

    testWidgets('bars-per-ton uses main bar length, not stock length',
        (tester) async {
      await _pumpSteel(tester);
      await _calculate(tester);
      expect(find.text('93'), findsOneWidget);

      await _enter(tester, Ar.steelBarLength, '6');
      expect(find.text('93'), findsNothing);

      await _calculate(tester);
      expect(find.text('187'), findsOneWidget);
    });

    testWidgets('cost is optional and price has no default', (tester) async {
      await _pumpSteel(tester);
      expect(find.widgetWithText(TextField, Ar.steelPricePerTon), findsNothing);

      await _toggleSection(tester, Ar.steelCostEstimate);
      final field = tester.widget<TextField>(
          find.widgetWithText(TextField, Ar.steelPricePerTon));
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('changing stock bar length updates procurement without hiding core result',
        (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.steelBarLength, '6');
      await _enter(tester, Ar.quantity, '10');
      await _toggleSection(tester, Ar.steelProcurementEstimate);
      await _calculate(tester);

      expect(_rowValue(tester, '${Ar.steelBarsRequired}:').data, '5');
      expect(find.text('53.27 كجم'), findsNWidgets(2));

      await _enter(tester, '${Ar.steelStockLength} (${Ar.meters})', '18');
      expect(find.text('53.27 كجم'), findsOneWidget);
      expect(_rowValue(tester, '${Ar.steelBarsPerStockBar}:').data, '3');
      expect(_rowValue(tester, '${Ar.steelBarsRequired}:').data, '4');
    });

    testWidgets('empty stock bar length shows valid-stock-length message',
        (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.steelBarLength, '6');
      await _enter(tester, Ar.quantity, '10');
      await _toggleSection(tester, Ar.steelProcurementEstimate);
      await _calculate(tester);

      await _enter(tester, '${Ar.steelStockLength} (${Ar.meters})', '');
      expect(find.text(Ar.steelStockLengthInvalid), findsOneWidget);
      expect(find.text('${Ar.steelBarsRequired}:'), findsNothing);
      expect(find.text('53.27 كجم'), findsOneWidget);
    });

    testWidgets('zero stock bar length shows valid-stock-length message',
        (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.steelBarLength, '6');
      await _enter(tester, Ar.quantity, '10');
      await _toggleSection(tester, Ar.steelProcurementEstimate);
      await _calculate(tester);

      await _enter(tester, '${Ar.steelStockLength} (${Ar.meters})', '0');
      expect(find.text(Ar.steelStockLengthInvalid), findsOneWidget);
      expect(find.text('${Ar.steelBarsRequired}:'), findsNothing);
      expect(find.text('53.27 كجم'), findsOneWidget);
    });

    testWidgets('valid stock bar length restores procurement results',
        (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.steelBarLength, '14');
      await _toggleSection(tester, Ar.steelProcurementEstimate);
      await _calculate(tester);
      expect(find.text(Ar.steelStockShorter), findsOneWidget);

      await _enter(tester, '${Ar.steelStockLength} (${Ar.meters})', '15');
      expect(find.text(Ar.steelStockShorter), findsNothing);
      expect(_rowValue(tester, '${Ar.steelBarsPerStockBar}:').data, '1');
      expect(_rowValue(tester, '${Ar.steelBarsRequired}:').data, '1');
    });

    testWidgets('changing price per ton does not invalidate core result',
        (tester) async {
      await _pumpSteel(tester);
      await _enter(tester, Ar.quantity, '10');
      await _calculate(tester);
      expect(find.text('106.54 كجم'), findsOneWidget);

      await _toggleSection(tester, Ar.steelCostEstimate);
      await _enter(tester, Ar.steelPricePerTon, '2000000');
      expect(find.text('106.54 كجم'), findsOneWidget);
      expect(find.text(Ar.steelCostHint), findsOneWidget);
    });
  });
}
