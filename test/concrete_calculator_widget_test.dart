import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/tools/presentation/screens/calculators/calculator_screen.dart';
import 'package:civilpedia/localization/ar.dart';

Widget _screen() => const MaterialApp(home: CalculatorScreen(type: 'concrete'));

Future<void> _pumpConcrete(WidgetTester tester) async {
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

Future<void> _selectType(WidgetTester tester, String label) async {
  await tester.tap(find.text(Ar.columnLabel).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _selectUnit(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

Future<void> _calculate(WidgetTester tester) async {
  await tester.tap(find.text(Ar.calculate));
  await tester.pump();
}

Future<void> _enterSlabInMeters(WidgetTester tester) async {
  await _selectType(tester, Ar.slabLabel);
  await _enter(tester, Ar.length, '5');
  await _enter(tester, Ar.width, '4');
  await _enter(tester, Ar.thickness, '0.2');
}

void main() {
  group('Concrete Calculator widget', () {
    testWidgets('slab in meters gives 4.000 m³', (tester) async {
      await _pumpConcrete(tester);
      await _enterSlabInMeters(tester);
      await _calculate(tester);

      expect(find.textContaining('5.000 × 4.000 × 0.200 م'), findsOneWidget);
      expect(find.text('الحجم الصافي: 4.000 م³'), findsOneWidget);
    });

    testWidgets('same slab in centimeters gives 4.000 m³', (tester) async {
      await _pumpConcrete(tester);
      await _selectUnit(tester, Ar.cm);
      await _selectType(tester, Ar.slabLabel);
      await _enter(tester, Ar.length, '500');
      await _enter(tester, Ar.width, '400');
      await _enter(tester, Ar.thickness, '20');
      await _calculate(tester);

      expect(find.textContaining('500.000 × 400.000 × 20.000 سم'), findsOneWidget);
      expect(find.text('الحجم الصافي: 4.000 م³'), findsOneWidget);
    });

    testWidgets('same slab in millimeters gives 4.000 m³', (tester) async {
      await _pumpConcrete(tester);
      await _selectUnit(tester, Ar.unitMm);
      await _selectType(tester, Ar.slabLabel);
      await _enter(tester, Ar.length, '5000');
      await _enter(tester, Ar.width, '4000');
      await _enter(tester, Ar.thickness, '200');
      await _calculate(tester);

      expect(find.textContaining('5000.000 × 4000.000 × 200.000 مم'), findsOneWidget);
      expect(find.text('الحجم الصافي: 4.000 م³'), findsOneWidget);
    });

    testWidgets('beam 5 × 0.30 × 0.50 gives 0.750 m³', (tester) async {
      await _pumpConcrete(tester);
      await _selectType(tester, Ar.beamLabel);
      await _enter(tester, Ar.length, '5');
      await _enter(tester, Ar.width, '0.30');
      await _enter(tester, Ar.height, '0.50');
      await _calculate(tester);

      expect(find.text('الحجم الصافي: 0.750 م³'), findsOneWidget);
    });

    testWidgets('rectangular column 0.40 × 0.40 × 3.00 gives 0.480 m³',
        (tester) async {
      await _pumpConcrete(tester);
      await _enter(tester, Ar.width, '0.40');
      await _enter(tester, Ar.depth, '0.40');
      await _enter(tester, Ar.height, '3.00');
      await _calculate(tester);

      expect(find.text('الحجم الصافي: 0.480 م³'), findsOneWidget);
    });

    testWidgets('circular column D=0.40 × H=3.00 gives 0.377 m³ and hides width',
        (tester) async {
      await _pumpConcrete(tester);
      await _selectType(tester, Ar.circularColumnLabel);
      await _enter(tester, Ar.diameter, '0.40');
      await _enter(tester, Ar.height, '3.00');
      await _calculate(tester);

      expect(find.widgetWithText(TextField, Ar.width), findsNothing);
      expect(find.textContaining('(π/4) × 0.400² × 3.000 م'), findsOneWidget);
      expect(find.text('الحجم الصافي: 0.377 م³'), findsOneWidget);
    });

    testWidgets('wall 5 × 0.20 × 3.00 gives 3.000 m³', (tester) async {
      await _pumpConcrete(tester);
      await _selectType(tester, Ar.wallLabel);
      await _enter(tester, Ar.length, '5');
      await _enter(tester, Ar.thickness, '0.20');
      await _enter(tester, Ar.height, '3.00');
      await _calculate(tester);

      expect(find.text('الحجم الصافي: 3.000 م³'), findsOneWidget);
    });

    testWidgets('footing 2 × 2 × 0.50 gives 2.000 m³', (tester) async {
      await _pumpConcrete(tester);
      await _selectType(tester, Ar.footingLabel);
      await _enter(tester, Ar.length, '2');
      await _enter(tester, Ar.width, '2');
      await _enter(tester, Ar.thickness, '0.50');
      await _calculate(tester);

      expect(find.text('الحجم الصافي: 2.000 م³'), findsOneWidget);
    });

    testWidgets('quantity 10 multiplies the net volume', (tester) async {
      await _pumpConcrete(tester);
      await _enter(tester, Ar.width, '0.40');
      await _enter(tester, Ar.depth, '0.40');
      await _enter(tester, Ar.height, '3.00');
      await _enter(tester, Ar.quantity, '10');
      await _calculate(tester);

      expect(find.text('حجم العنصر الواحد: 0.480 م³'), findsOneWidget);
      expect(find.text('الحجم الصافي (×10): 4.800 م³'), findsOneWidget);
    });

    testWidgets('additional percentage 5% raises the grand total', (tester) async {
      await _pumpConcrete(tester);
      await _enterSlabInMeters(tester);
      await _calculate(tester);
      expect(find.text('4.000 م³'), findsOneWidget);

      await tester.tap(find.text('5%'));
      await tester.pump();

      expect(find.textContaining('الحجم الإضافي (5%)'), findsOneWidget);
      expect(find.text('4.200 م³'), findsOneWidget);
    });

    testWidgets('zero dimension shows a validation error', (tester) async {
      await _pumpConcrete(tester);
      await _enter(tester, Ar.width, '0');
      await _enter(tester, Ar.depth, '0.40');
      await _enter(tester, Ar.height, '3.00');
      await _calculate(tester);

      expect(find.text(Ar.invalidInputs), findsOneWidget);
      expect(find.textContaining('الحجم الصافي'), findsNothing);
    });

    testWidgets('empty dimension shows a validation error', (tester) async {
      await _pumpConcrete(tester);
      await _enter(tester, Ar.width, '0.40');
      await _enter(tester, Ar.depth, '0.40');
      await _calculate(tester);

      expect(find.text(Ar.invalidInputs), findsOneWidget);
    });

    testWidgets('quantity zero shows a quantity error', (tester) async {
      await _pumpConcrete(tester);
      await _enter(tester, Ar.width, '0.40');
      await _enter(tester, Ar.depth, '0.40');
      await _enter(tester, Ar.height, '3.00');
      await _enter(tester, Ar.quantity, '0');
      await _calculate(tester);

      expect(find.text(Ar.invalidQuantity), findsOneWidget);
    });

    testWidgets('switching element type clears values and hides irrelevant fields',
        (tester) async {
      await _pumpConcrete(tester);
      await _enter(tester, Ar.width, '0.40');
      await _enter(tester, Ar.depth, '0.40');
      await _enter(tester, Ar.height, '3.00');
      await _calculate(tester);
      expect(find.text('الحجم الصافي: 0.480 م³'), findsOneWidget);

      await _selectType(tester, Ar.circularColumnLabel);

      expect(find.widgetWithText(TextField, Ar.width), findsNothing);
      expect(find.widgetWithText(TextField, Ar.depth), findsNothing);
      expect(find.widgetWithText(TextField, Ar.diameter), findsOneWidget);
      expect(find.textContaining('الحجم الصافي'), findsNothing);
    });

    testWidgets('repeated calculation updates the result', (tester) async {
      await _pumpConcrete(tester);
      await _enterSlabInMeters(tester);
      await _calculate(tester);
      expect(find.text('الحجم الصافي: 4.000 م³'), findsOneWidget);

      await _enter(tester, Ar.thickness, '0.30');
      await _calculate(tester);

      expect(find.text('الحجم الصافي: 6.000 م³'), findsOneWidget);
      expect(find.text('الحجم الصافي: 4.000 م³'), findsNothing);
    });

    testWidgets('reset clears fields, results and the unit', (tester) async {
      await _pumpConcrete(tester);
      await _selectUnit(tester, Ar.cm);
      await _selectType(tester, Ar.slabLabel);
      await _enter(tester, Ar.length, '500');
      await _enter(tester, Ar.width, '400');
      await _enter(tester, Ar.thickness, '20');
      await _calculate(tester);
      expect(find.textContaining('الحجم الصافي'), findsWidgets);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.textContaining('الحجم الصافي'), findsNothing);
      expect(find.widgetWithText(TextField, Ar.width), findsOneWidget);
      final widthField =
          tester.widget<TextField>(find.widgetWithText(TextField, Ar.width));
      expect(widthField.controller!.text, isEmpty);
      final mChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'م'));
      expect(mChip.selected, isTrue);
    });

    testWidgets('truck count appears only when a capacity is provided',
        (tester) async {
      await _pumpConcrete(tester);
      await _enterSlabInMeters(tester);
      await _calculate(tester);

      expect(find.textContaining(Ar.truckCount), findsNothing);

      await tester.dragUntilVisible(
        find.text(Ar.options),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await _enter(tester, '${Ar.truckCapacity} (${Ar.cubicMeters})', '8');
      await _calculate(tester);

      expect(find.textContaining('${Ar.truckCount} (8.0 ${Ar.cubicMeters}): 1'),
          findsOneWidget);
    });

    testWidgets('cost appears only when enabled and a price is provided',
        (tester) async {
      await _pumpConcrete(tester);
      await _enterSlabInMeters(tester);
      await _calculate(tester);
      expect(find.textContaining(Ar.concreteCost), findsNothing);

      await tester.dragUntilVisible(
        find.text(Ar.options),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await _enter(tester, Ar.costPerCubic, '100');
      await _calculate(tester);

      expect(find.text('${Ar.concreteCost}: 400'), findsOneWidget);
    });
  });
}
