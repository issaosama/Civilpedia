import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/features/tools/presentation/widgets/calculator/calculator_error_card.dart';
import 'package:civilpedia/features/tools/presentation/widgets/calculator/calculator_primary_button.dart';
import 'package:civilpedia/features/tools/presentation/widgets/calculator/calculator_result_row.dart';

void main() {
  group('CalculatorResultRow', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorResultRow(label: 'Label', value: 'Value'),
          ),
        ),
      );

      expect(find.text('Label'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
    });

    testWidgets('bold value uses bold font weight', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorResultRow(
              label: 'Label',
              value: 'Value',
              isBold: true,
            ),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('Value'));
      expect(valueText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('long label renders without overflow', (tester) async {
      const longLabel =
          'This is a very long label that should wrap safely in narrow layouts';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: CalculatorResultRow(
                label: longLabel,
                value: '123',
              ),
            ),
          ),
        ),
      );

      expect(find.text(longLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('works in RTL Arabic direction', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: CalculatorResultRow(
                label: 'القيمة',
                value: '١٢٣',
              ),
            ),
          ),
        ),
      );

      expect(find.text('القيمة'), findsOneWidget);
      expect(find.text('١٢٣'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CalculatorErrorCard', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculatorErrorCard(message: 'Something went wrong'),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('uses error color styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light(error: Colors.red)),
          home: const Scaffold(
            body: CalculatorErrorCard(message: 'Error'),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.borderRadius, isNotNull);
    });
  });

  group('CalculatorPrimaryButton', () {
    testWidgets('renders label and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorPrimaryButton(
              onPressed: () {},
              label: 'Calculate',
            ),
          ),
        ),
      );

      expect(find.text('Calculate'), findsOneWidget);
      expect(find.byIcon(Icons.calculate), findsOneWidget);
    });

    testWidgets('tapping invokes onPressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorPrimaryButton(
              onPressed: () => pressed = true,
              label: 'Calculate',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Calculate'));
      expect(pressed, isTrue);
    });

    testWidgets('uses primary brand color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorPrimaryButton(
              onPressed: () {},
              label: 'Calculate',
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byWidgetPredicate((w) => w is ElevatedButton),
      );
      final style = button.style as ButtonStyle;
      final bg = style.backgroundColor?.resolve({});
      expect(bg, AppColors.primary);
    });

    testWidgets('fills available width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorPrimaryButton(
              onPressed: () {},
              label: 'Calculate',
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.ancestor(
        of: find.byWidgetPredicate((w) => w is ElevatedButton),
        matching: find.byType(SizedBox),
      ));
      expect(sizedBox.width, double.infinity);
    });
  });
}
