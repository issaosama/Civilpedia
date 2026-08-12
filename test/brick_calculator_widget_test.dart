import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/tools/presentation/screens/calculators/calculator_screen.dart';
import 'package:civilpedia/localization/ar.dart';

Widget _screen() => const MaterialApp(home: CalculatorScreen(type: 'brick'));

Future<void> _pumpBrick(WidgetTester tester) async {
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

void main() {
  group('Masonry Calculator widget', () {
    testWidgets('block 20×20×40, 5 m × 3 m gives 188 final units',
        (tester) async {
      await _pumpBrick(tester);
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _calculate(tester);

      // 5×3=15 m², face 0.08 m² → raw 187.5, ceil 188
      expect(find.text('15.00 م²'), findsNWidgets(2));
      expect(find.text('188'), findsNWidgets(3));
    });

    testWidgets('wall quantity 2 doubles the units', (tester) async {
      await _pumpBrick(tester);
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _enter(tester, Ar.masonryWallQuantity, '2');
      await _calculate(tester);

      expect(find.text('30.00 م²'), findsNWidgets(2));
      expect(find.text('375'), findsNWidgets(3));
    });

    testWidgets('opening deduction reduces final units', (tester) async {
      await _pumpBrick(tester);
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _enter(tester, Ar.masonryOpenings, '3');
      await _calculate(tester);

      expect(find.textContaining('الفتحات المخصومة'), findsOneWidget);
      expect(find.text('12.00 م²'), findsOneWidget);
      expect(find.text('150'), findsNWidgets(3));
    });

    testWidgets('block 10×20×40 preset gives same face as 20×20×40',
        (tester) async {
      await _pumpBrick(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, '10×20×40 سم'));
      await tester.pump();
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _calculate(tester);

      expect(find.text('188'), findsNWidgets(3));
    });

    testWidgets('brick 25×12×6 preset uses 25×6 face', (tester) async {
      await _pumpBrick(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.clayBrick));
      await tester.pump();
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _calculate(tester);

      expect(find.text('1000'), findsNWidgets(3));
    });

    testWidgets('custom masonry size computes correctly', (tester) async {
      await _pumpBrick(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, Ar.masonryCustomTitle));
      await tester.pump();
      await _enter(tester, Ar.masonryCustomFaceHeight, '25');
      await _enter(tester, Ar.masonryCustomFaceLength, '50');
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _calculate(tester);

      expect(find.text('120'), findsNWidgets(3));
    });

    testWidgets('additional 5% adds extra units', (tester) async {
      await _pumpBrick(tester);
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await tester.tap(find.text('5%'));
      await tester.pump();
      await _calculate(tester);

      expect(find.textContaining('وحدات إضافية (5%)'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('197'), findsNWidgets(2));
    });

    testWidgets('openings > gross area shows validation', (tester) async {
      await _pumpBrick(tester);
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _enter(tester, Ar.masonryOpenings, '20');
      await _calculate(tester);

      expect(find.text(Ar.masonryOpeningsExceed), findsOneWidget);
    });

    testWidgets('zero wall length shows validation error', (tester) async {
      await _pumpBrick(tester);
      await _enter(tester, Ar.masonryWallLength, '0');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _calculate(tester);

      expect(find.text(Ar.invalidInputs), findsOneWidget);
    });

    testWidgets('quantity zero shows quantity error', (tester) async {
      await _pumpBrick(tester);
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _enter(tester, Ar.masonryWallQuantity, '0');
      await _calculate(tester);

      expect(find.text(Ar.invalidQuantity), findsOneWidget);
    });

    testWidgets('reset restores defaults and clears results', (tester) async {
      await _pumpBrick(tester);
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _calculate(tester);
      expect(find.text('188'), findsWidgets);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(find.text('188'), findsNothing);
      final qtyField = tester.widget<TextField>(
          find.widgetWithText(TextField, Ar.masonryWallQuantity));
      expect(qtyField.controller!.text, '1');
    });

    testWidgets('changing masonry size after calc invalidates result',
        (tester) async {
      await _pumpBrick(tester);
      await _enter(tester, Ar.masonryWallLength, '5');
      await _enter(tester, Ar.masonryWallHeight, '3');
      await _calculate(tester);
      expect(find.text('188'), findsWidgets);

      await tester.tap(find.widgetWithText(ChoiceChip, '15×20×40 سم'));
      await tester.pump();
      expect(find.text('188'), findsNothing);
    });

    testWidgets('changing masonry type switches presets', (tester) async {
      await _pumpBrick(tester);
      expect(find.widgetWithText(ChoiceChip, '20×20×40 سم'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '25×12×6 سم'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, Ar.clayBrick));
      await tester.pump();

      expect(find.widgetWithText(ChoiceChip, '20×20×40 سم'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, '25×12×6 سم'), findsOneWidget);
    });
  });
}
