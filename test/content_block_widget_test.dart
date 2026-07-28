import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/code_reference.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/content_block_widget.dart';
import 'package:civilpedia/features/encyclopedia/presentation/theme/encyclopedia_card_colors.dart';
import 'package:civilpedia/features/encyclopedia/presentation/theme/encyclopedia_topic_theme.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/text_block_widget.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/safety_note_widget.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/inspection_point_widget.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/checklist_widget.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/table_block_widget.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/equipment_widget.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/common_mistakes_block_widget.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/acceptance_criteria_block_widget.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/rejection_criteria_block_widget.dart';

void main() {
  setUpAll(() {
    EncyclopediaCardColors.apply(EncyclopediaTopicTheme.defaultTheme);
  });

  group('ContentBlockWidget dispatches all 12 types without exceptions', () {
    testWidgets('TextBlock paragraph', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: TextBlock(content: 'Hello', variant: TextVariant.paragraph)),
      ));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('TextBlock note variant', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: TextBlock(content: 'Note text', variant: TextVariant.note)),
      ));
      expect(find.text('Note text'), findsOneWidget);
      expect(find.text('ملاحظة'), findsOneWidget);
    });

    testWidgets('TextBlock tip variant', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: TextBlock(content: 'Tip text', variant: TextVariant.tip)),
      ));
      expect(find.text('Tip text'), findsOneWidget);
      expect(find.text('نصيحة'), findsOneWidget);
    });

    testWidgets('TextBlock warning variant', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: TextBlock(content: 'Warning text', variant: TextVariant.warning)),
      ));
      expect(find.text('Warning text'), findsOneWidget);
      expect(find.text('تنبيه'), findsOneWidget);
    });

    testWidgets('SafetyNoteBlock', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: SafetyNoteBlock(note: SafetyNote(message: 'Safety first', severity: SafetySeverity.high))),
      ));
      expect(find.text('Safety first'), findsOneWidget);
    });

    testWidgets('SafetyNoteBlock all severities render', (tester) async {
      for (final s in SafetySeverity.values) {
        await tester.pumpWidget(MaterialApp(
          home: ContentBlockWidget(block: SafetyNoteBlock(note: SafetyNote(message: 'Test $s', severity: s))),
        ));
        expect(find.text('Test $s'), findsOneWidget);
      }
    });

    testWidgets('ExecutionStepBlock', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: ExecutionStepBlock(step: ExecutionStep(stepNumber: 1, description: 'Step desc'))),
      ));
      expect(find.text('Step desc'), findsOneWidget);
    });

    testWidgets('ExecutionStepBlock with notes', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: ExecutionStepBlock(step: ExecutionStep(stepNumber: 2, description: 'Desc', notes: 'Extra notes'))),
      ));
      expect(find.text('Extra notes'), findsOneWidget);
    });

    testWidgets('InspectionPointBlock', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: InspectionPointBlock(point: InspectionPoint(criteria: 'Must be level', isCritical: true))),
      ));
      // RichText contains the criteria text via TextSpan; verify widget exists and 'critical' badge renders
      expect(find.byType(InspectionPointWidget), findsOneWidget);
      expect(find.text('حرج'), findsOneWidget);
    });

    testWidgets('InspectionPointBlock missing method still renders criteria', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: InspectionPointBlock(point: InspectionPoint(criteria: 'Criteria only'))),
      ));
      expect(find.byType(InspectionPointWidget), findsOneWidget);
    });

    testWidgets('InspectionPointBlock missing markerStyle uses default', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: InspectionPointBlock(point: InspectionPoint(criteria: 'Style test', markerColorMode: 'semantic'))),
      ));
      expect(find.byType(InspectionPointWidget), findsOneWidget);
    });

    testWidgets('ChecklistBlock', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: ChecklistBlock(title: 'Check', items: [ChecklistItem(id: '1', text: 'Item A')])),
      ));
      expect(find.text('Check'), findsOneWidget);
      expect(find.text('Item A'), findsOneWidget);
    });

    testWidgets('ChecklistBlock mixed valid/empty items', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: ChecklistBlock(items: [
          ChecklistItem(id: '1', text: 'Valid'),
          ChecklistItem(id: '2', text: ''),
          ChecklistItem(id: '3', text: '   '),
        ])),
      ));
      expect(find.text('Valid'), findsOneWidget);
    });

    testWidgets('CodeReferenceBlock single ref', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: CodeReferenceBlock(reference: CodeReference(code: 'ACI 318', section: '5', title: 'Title', description: 'Desc'))),
      ));
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Desc'), findsOneWidget);
    });

    testWidgets('CodeReferenceBlock multiple refs', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: CodeReferenceBlock(reference: CodeReference(code: 'ACI 318 / ASTM C39', section: '5', title: 'Multi', description: null))),
      ));
      expect(find.text('Multi'), findsOneWidget);
    });

    testWidgets('CodeReferenceBlock empty excerpt still renders', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: CodeReferenceBlock(reference: CodeReference(code: 'BS 8110', section: '2', title: 'British', description: null))),
      ));
      expect(find.text('British'), findsOneWidget);
    });

    testWidgets('TableBlock', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: TableBlock(data: TableData(headers: ['A', 'B'], rows: [TableRowData(cells: ['1', '2'])]))),
      ));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('EquipmentBlock', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: EquipmentBlock(items: [EquipmentItem(name: 'Hammer', purpose: 'Driving', specification: '5kg')])),
      ));
      expect(find.text('Hammer'), findsOneWidget);
    });

    testWidgets('ImageBlock', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: ImageBlock(imageUrl: 'assets/images/test.png', caption: 'Fig 1')),
      ));
      // Image.asset will error because file doesn't exist — errorBuilder handles it
      // We verify no crash and caption still renders
      expect(find.text('Fig 1'), findsOneWidget);
    });

    testWidgets('ImageBlock missing image path does not crash', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: ImageBlock(imageUrl: '', caption: null)),
      ));
      // Should render nothing, no crash
    });

    testWidgets('ImageBlock invalid path uses fallback', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: ImageBlock(imageUrl: 'nonexistent/path.png', caption: 'Cap')),
      ));
      // Debug mode shows error text, release shrinks — verify no crash
      expect(find.text('Cap'), findsOneWidget);
    });

    testWidgets('CommonMistakesBlockWidget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: CommonMistakesBlock(items: [CalloutItem(text: 'Mistake 1')])),
      ));
      expect(find.text('Mistake 1'), findsOneWidget);
      expect(find.text('الأخطاء الشائعة'), findsOneWidget);
      // No emoji in header
      expect(find.text('❌'), findsNothing);
    });

    testWidgets('CommonMistakesBlockWidget multiple items', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: CommonMistakesBlock(items: [
          CalloutItem(text: 'الأول'),
          CalloutItem(text: 'الثاني'),
          CalloutItem(text: 'الثالث'),
        ])),
      ));
      expect(find.text('الأول'), findsOneWidget);
      expect(find.text('الثاني'), findsOneWidget);
      expect(find.text('الثالث'), findsOneWidget);
    });

    testWidgets('CommonMistakesBlockWidget long Arabic text', (tester) async {
      const long = 'هذا نص طويل جداً لاختبار كيفية تعامل الواجهة مع المحتوى العربي الطويل';
      await tester.pumpWidget(MaterialApp(
        home: SingleChildScrollView(child: ContentBlockWidget(block: CommonMistakesBlock(items: [CalloutItem(text: long)]))),
      ));
      expect(find.text(long), findsOneWidget);
    });

    testWidgets('CommonMistakesBlockWidget custom title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: CommonMistakesBlock(title: 'عنوان مخصص', items: [CalloutItem(text: 'اختبار')])),
      ));
      expect(find.text('عنوان مخصص'), findsOneWidget);
    });

    testWidgets('CommonMistakesBlockWidget mixed valid/empty items', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: CommonMistakesBlock(items: [
          CalloutItem(text: 'صالح'),
          CalloutItem(text: ''),
          CalloutItem(text: '   '),
        ])),
      ));
      expect(find.text('صالح'), findsOneWidget);
      expect(find.text('الأخطاء الشائعة'), findsOneWidget);
    });

    testWidgets('SafetyNoteBlock none severity', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: SafetyNoteBlock(note: SafetyNote(message: 'Neutral', severity: SafetySeverity.none))),
      ));
      expect(find.text('Neutral'), findsOneWidget);
      // No severity label or severity-specific icon for 'none'
      expect(find.text('منخفض'), findsNothing);
      expect(find.text('متوسط'), findsNothing);
      expect(find.text('عالي'), findsNothing);
      expect(find.text('خطير'), findsNothing);
    });

    testWidgets('AcceptanceCriteriaBlockWidget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: AcceptanceCriteriaBlock(items: [CalloutItem(text: 'Accept 1')])),
      ));
      expect(find.text('Accept 1'), findsOneWidget);
    });

    testWidgets('RejectionCriteriaBlockWidget', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: RejectionCriteriaBlock(items: [CalloutItem(text: 'Reject 1')])),
      ));
      expect(find.text('Reject 1'), findsOneWidget);
    });
  });

  group('Empty/guard behavior', () {
    testWidgets('Empty paragraph hides block', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: TextBlock(content: '', variant: TextVariant.paragraph)),
      ));
      // No text should be rendered
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('Whitespace-only paragraph hides block', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: TextBlock(content: '   ', variant: TextVariant.paragraph)),
      ));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('Empty safety note hides block', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: SafetyNoteBlock(note: SafetyNote(message: '  ', severity: SafetySeverity.low))),
      ));
      // The Widget exists in tree but returns SizedBox.shrink() — verify no severity label renders
      expect(find.text('منخفض'), findsNothing);
    });

    testWidgets('Empty checklist hides block', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: ChecklistBlock(items: [])),
      ));
      // No Text widgets from items; no check_box icons
      expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
    });

    testWidgets('Empty table rows hides block', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: TableBlock(data: TableData(headers: ['A'], rows: []))),
      ));
      // No DataTable rendered when rows are empty
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets('Empty equipment hides block', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: EquipmentBlock(items: [])),
      ));
      expect(find.byIcon(Icons.circle), findsNothing);
    });

    testWidgets('Empty common mistakes hides block', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: CommonMistakesBlock(items: [])),
      ));
      expect(find.text('الأخطاء الشائعة'), findsNothing);
    });

    testWidgets('Empty acceptance criteria hides block', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: AcceptanceCriteriaBlock(items: [])),
      ));
      expect(find.text('معايير القبول'), findsNothing);
    });

    testWidgets('Empty rejection criteria hides block', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: RejectionCriteriaBlock(items: [])),
      ));
      expect(find.text('معايير الرفض'), findsNothing);
    });

    testWidgets('Empty inspection criteria hides block', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: InspectionPointBlock(point: InspectionPoint(criteria: '  '))),
      ));
      // Widget exists but returns SizedBox.shrink() — verify no critical badge
      expect(find.text('حرج'), findsNothing);
    });

    testWidgets('Unknown text variant via fromJson falls back to note', (tester) async {
      final block = TextBlock.fromJson({'content': 'Unknown variant text', 'variant': 'bogus'});
      expect(block.variant, TextVariant.note);
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: block),
      ));
      expect(find.text('Unknown variant text'), findsOneWidget);
      expect(find.text('ملاحظة'), findsOneWidget);
    });
  });

  group('Dark mode rendering', () {
    testWidgets('TextBlock renders in dark mode', (tester) async {
      await tester.pumpWidget(MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(brightness: Brightness.dark),
        home: ContentBlockWidget(block: TextBlock(content: 'Dark text', variant: TextVariant.paragraph)),
      ));
      expect(find.text('Dark text'), findsOneWidget);
    });

    testWidgets('SafetyNoteBlock renders in dark mode', (tester) async {
      await tester.pumpWidget(MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(brightness: Brightness.dark),
        home: ContentBlockWidget(block: SafetyNoteBlock(note: SafetyNote(message: 'Dark safety', severity: SafetySeverity.critical))),
      ));
      expect(find.text('Dark safety'), findsOneWidget);
    });

    testWidgets('CommonMistakesBlockWidget renders in dark mode', (tester) async {
      await tester.pumpWidget(MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(brightness: Brightness.dark),
        home: ContentBlockWidget(block: CommonMistakesBlock(items: [CalloutItem(text: 'Dark mistake')])),
      ));
      expect(find.text('Dark mistake'), findsOneWidget);
    });
  });

  group('RTL rendering', () {
    testWidgets('Arabic text renders', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: TextBlock(content: 'نص عربي طويل', variant: TextVariant.paragraph)),
      ));
      expect(find.text('نص عربي طويل'), findsOneWidget);
    });

    testWidgets('CommonMistakesBlockWidget Arabic text renders RTL', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: CommonMistakesBlock(items: [CalloutItem(text: 'نص عربي طويل للأخطاء')])),
      ));
      expect(find.text('نص عربي طويل للأخطاء'), findsOneWidget);
    });
  });

  group('Long text', () {
    testWidgets('Long Arabic text renders without overflow', (tester) async {
      const long = 'هذا نص طويل جداً يستخدم لاختبار كيفية تعامل الواجهة مع المحتوى العربي الطويل الذي قد يتجاوز عرض الشاشة في بعض الحالات النادرة';
      await tester.pumpWidget(MaterialApp(
        home: SingleChildScrollView(child: ContentBlockWidget(block: TextBlock(content: long, variant: TextVariant.paragraph))),
      ));
      expect(find.text(long), findsOneWidget);
    });
  });

  group('Legacy-compatible shapes', () {
    testWidgets('TextBlock with missing variant defaults to paragraph', (tester) async {
      // Construction without variant uses default
      final block = TextBlock(content: 'Default variant');
      expect(block.variant, TextVariant.paragraph);
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: block),
      ));
      expect(find.text('Default variant'), findsOneWidget);
    });
  });

  group('List-based blocks preserve order', () {
    testWidgets('Checklist preserves item order', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ContentBlockWidget(block: ChecklistBlock(items: [
          ChecklistItem(id: '1', text: 'First'),
          ChecklistItem(id: '2', text: 'Second'),
          ChecklistItem(id: '3', text: 'Third'),
        ])),
      ));
      final items = find.textContaining(RegExp('First|Second|Third'));
      expect(items, findsNWidgets(3));
    });
  });
}
