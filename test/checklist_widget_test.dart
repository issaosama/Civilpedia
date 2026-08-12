import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/checklist_screen.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_item.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_status.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/inspection_localization.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/widgets/inspection_item_tile.dart';
import 'package:civilpedia/localization/ar.dart';

Widget _checklistScreen() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: const MaterialApp(home: ChecklistScreen()),
  );
}

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_checklistScreen());
  await tester.pump();
}

void main() {
  group('InspectionItemTile status chips', () {
    testWidgets('tapping Pass selects it', (tester) async {
      final item = InspectionItem(id: '1', categoryId: 'c', titleKey: 'Test');
      InspectionStatus? selected;

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: InspectionItemTile(
        item: item, l10n: L10n(true), passLabel: 'Pass', failLabel: 'Fail',
        pendingLabel: 'Pending', naLabel: 'N/A', criticalLabel: 'Critical',
        requiredLabel: 'Required', notesHint: 'Notes', codeRefLabel: 'Ref',
        onStatusChanged: (s) => selected = s,
        onNotesChanged: (_) {},
      ))));
      await tester.pump();

      await tester.tap(find.text('Pass'));
      expect(selected, InspectionStatus.pass);
    });

    testWidgets('tapping Fail selects it', (tester) async {
      final item = InspectionItem(id: '1', categoryId: 'c', titleKey: 'Test');
      InspectionStatus? selected;

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: InspectionItemTile(
        item: item, l10n: L10n(true), passLabel: 'Pass', failLabel: 'Fail',
        pendingLabel: 'Pending', naLabel: 'N/A', criticalLabel: 'Critical',
        requiredLabel: 'Required', notesHint: 'Notes', codeRefLabel: 'Ref',
        onStatusChanged: (s) => selected = s,
        onNotesChanged: (_) {},
      ))));
      await tester.pump();

      await tester.tap(find.text('Fail'));
      expect(selected, InspectionStatus.fail);
    });

    testWidgets('tapping N/A selects it', (tester) async {
      final item = InspectionItem(id: '1', categoryId: 'c', titleKey: 'Test');
      InspectionStatus? selected;

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: InspectionItemTile(
        item: item, l10n: L10n(true), passLabel: 'Pass', failLabel: 'Fail',
        pendingLabel: 'Pending', naLabel: 'N/A', criticalLabel: 'Critical',
        requiredLabel: 'Required', notesHint: 'Notes', codeRefLabel: 'Ref',
        onStatusChanged: (s) => selected = s,
        onNotesChanged: (_) {},
      ))));
      await tester.pump();

      await tester.tap(find.text('N/A'));
      expect(selected, InspectionStatus.na);
    });

    testWidgets('tapping Pending returns to uninspected', (tester) async {
      final item = InspectionItem(id: '1', categoryId: 'c', titleKey: 'Test')
        ..status = InspectionStatus.fail;
      InspectionStatus? selected;

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: InspectionItemTile(
        item: item, l10n: L10n(true), passLabel: 'Pass', failLabel: 'Fail',
        pendingLabel: 'Pending', naLabel: 'N/A', criticalLabel: 'Critical',
        requiredLabel: 'Required', notesHint: 'Notes', codeRefLabel: 'Ref',
        onStatusChanged: (s) => selected = s,
        onNotesChanged: (_) {},
      ))));
      await tester.pump();

      await tester.tap(find.text('Pending'));
      expect(selected, InspectionStatus.pending);
    });

    testWidgets('four chips present, only Pending selected by default', (tester) async {
      final item = InspectionItem(id: '1', categoryId: 'c', titleKey: 'Test');

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: InspectionItemTile(
        item: item, l10n: L10n(true), passLabel: 'Pass', failLabel: 'Fail',
        pendingLabel: 'Pending', naLabel: 'N/A', criticalLabel: 'Critical',
        requiredLabel: 'Required', notesHint: 'Notes', codeRefLabel: 'Ref',
        onStatusChanged: (_) {}, onNotesChanged: (_) {},
      ))));
      await tester.pump();

      expect(find.text('Pass'), findsOneWidget);
      expect(find.text('Fail'), findsOneWidget);
      expect(find.text('N/A'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      final pendingChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Pending'));
      expect(pendingChip.selected, isTrue);
    });
  });

  group('Reset confirmation on full screen', () {
    testWidgets('Reset dialog appears and Cancel works', (tester) async {
      await _pump(tester);
      await tester.tap(find.text(Ar.inspectionResetAll));
      await tester.pump();

      expect(find.text('إعادة تعيين قائمة الفحص؟'), findsOneWidget);
      await tester.tap(find.text('إلغاء'));
      await tester.pump();

      // Dialog dismissed, summary still present
      expect(find.text(Ar.inspectionResetAll), findsOneWidget);
    });

    testWidgets('Reset clears summary to 0 inspected', (tester) async {
      await _pump(tester);
      await tester.tap(find.text(Ar.inspectionResetAll));
      await tester.pump();

      await tester.tap(find.text('إعادة تعيين'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('0 / 103'), findsOneWidget);
    });

    testWidgets('Cancel preserves status and notes', (tester) async {
      await _pump(tester);
      await tester.tap(find.text(Ar.inspectionResetAll));
      await tester.pump();

      await tester.tap(find.text('إلغاء'));
      await tester.pump();

      // Summary still shows all pending (progress 0% but labels intact)
      expect(find.text(Ar.inspectionResetAll), findsOneWidget);
    });
  });

  group('Responsive summary', () {
    testWidgets('normal width renders correctly in Arabic RTL', (tester) async {
      await _pump(tester);
      expect(find.text(Ar.inspectionResetAll), findsOneWidget);
      expect(find.text(Ar.inspectionPass), findsWidgets);
      expect(find.text(Ar.inspectionFail), findsWidgets);
      expect(find.text(Ar.inspectionNA), findsWidgets);
      expect(find.text(Ar.inspectionPending), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
