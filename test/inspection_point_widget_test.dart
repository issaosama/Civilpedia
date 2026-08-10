import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/presentation/theme/encyclopedia_card_colors.dart';
import 'package:civilpedia/features/encyclopedia/presentation/theme/encyclopedia_topic_theme.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/inspection_point_widget.dart';

void main() {
  setUpAll(() {
    EncyclopediaCardColors.apply(EncyclopediaTopicTheme.defaultTheme);
  });

  Widget wrap(
    Widget child, {
    TextDirection direction = TextDirection.rtl,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, inner) => Directionality(
        textDirection: direction,
        child: inner!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  InspectionPointBlock block(InspectionPoint point) => InspectionPointBlock(point: point);

  BoxDecoration? _circleDecoration(WidgetTester tester) {
    for (final c in tester.widgetList<Container>(find.byType(Container))) {
      final deco = c.decoration;
      if (deco is BoxDecoration && deco.shape == BoxShape.circle) {
        return deco;
      }
    }
    return null;
  }

  BoxDecoration? _badgeDecoration(WidgetTester tester) {
    for (final c in tester.widgetList<Container>(find.byType(Container))) {
      final deco = c.decoration;
      if (deco is BoxDecoration &&
          deco.shape != BoxShape.circle &&
          deco.borderRadius == BorderRadius.circular(4)) {
        return deco;
      }
    }
    return null;
  }

  Color? _findSpanColor(InlineSpan span, String criteria, [Color? inherited]) {
    if (span is TextSpan) {
      final effective = span.style?.color ?? inherited;
      if (span.text == criteria) return effective;
      for (final child in span.children ?? const <InlineSpan>[]) {
        final color = _findSpanColor(child, criteria, effective);
        if (color != null) return color;
      }
    }
    return null;
  }

  Color? _criteriaColor(WidgetTester tester, String criteria) {
    final rich = tester.widget<RichText>(find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains(criteria),
    ));
    return _findSpanColor(rich.text, criteria);
  }

  Color? _detailsColor(WidgetTester tester, String detailsText) {
    return tester.widget<Text>(find.text(detailsText)).style?.color;
  }

  group('InspectionPointWidget preview parity', () {
    testWidgets('1. normal inspection point renders marker, criteria, and details line', (tester) async {
      final p = InspectionPoint(
        criteria: 'عدم وجود جفاف على سطح الخرسانة',
        acceptableTolerance: 'لون موحد للسطح',
        method: 'الفحص البصري للسطح',
      );
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      expect(find.byType(InspectionPointWidget), findsOneWidget);
      expect(find.text('!'), findsOneWidget, reason: 'default inspection marker symbol');
      expect(find.text('حرج'), findsNothing, reason: 'non-critical point has no badge');
      expect(find.textContaining(p.criteria, findRichText: true), findsOneWidget);
      expect(find.text('القبول: لون موحد للسطح'), findsOneWidget);
      expect(find.text('الطريقة: الفحص البصري للسطح'), findsOneWidget);
      expect(find.textContaining(' | '), findsNothing, reason: 'no inline separator between acceptance and method');
    });

    testWidgets('2. critical inspection point renders badge', (tester) async {
      final p = InspectionPoint(
        criteria: 'بدء المعالجة بالوقت المناسب',
        method: 'مراجعة سجل الصب',
        isCritical: true,
      );
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      expect(find.text('حرج'), findsOneWidget);
      expect(find.textContaining(p.criteria, findRichText: true), findsOneWidget);
      expect(find.text('الطريقة: مراجعة سجل الصب'), findsOneWidget);
    });

    testWidgets('3. criteria + tolerance + method render two labeled detail lines', (tester) async {
      final p = InspectionPoint(
        criteria: 'استقامة العنصر',
        acceptableTolerance: '± 5 مم',
        method: 'استخدام الشاقول أو الليزر',
      );
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      expect(find.text('القبول: ± 5 مم'), findsOneWidget);
      expect(find.text('الطريقة: استخدام الشاقول أو الليزر'), findsOneWidget);
      expect(_detailsColor(tester, 'القبول: ± 5 مم'),
          EncyclopediaCardColors.textMuted, reason: 'acceptance line uses muted color like fp-text-muted');
      expect(_detailsColor(tester, 'الطريقة: استخدام الشاقول أو الليزر'),
          EncyclopediaCardColors.textMuted, reason: 'method line uses muted color like fp-text-muted');
    });

    testWidgets('4. missing optional method omits الطريقة label', (tester) async {
      final p = InspectionPoint(
        criteria: 'مستوى السطح',
        acceptableTolerance: 'لا يزيد عن 3 مم لكل متر',
      );
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      expect(find.text('القبول: لا يزيد عن 3 مم لكل متر'), findsOneWidget);
      expect(find.textContaining('الطريقة:'), findsNothing);
    });

    testWidgets('4b. method-only point omits the acceptance line', (tester) async {
      final p = InspectionPoint(criteria: 'استقامة العمود', method: 'استخدام الشاقول');
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      expect(find.text('الطريقة: استخدام الشاقول'), findsOneWidget);
      expect(find.textContaining('القبول:'), findsNothing);
    });

    testWidgets('4c. both fields empty renders no details area', (tester) async {
      final p = InspectionPoint(criteria: 'فحص عام');
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      expect(find.textContaining('القبول:'), findsNothing);
      expect(find.textContaining('الطريقة:'), findsNothing);
      expect(find.text('!'), findsOneWidget, reason: 'marker and title remain');
    });

    testWidgets('4d. whitespace-only values omitted; trimmed values render', (tester) async {
      final p = InspectionPoint(
        criteria: 'نظافة الموقع',
        acceptableTolerance: '   ',
        method: '  فحص بصري  ',
      );
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      expect(find.textContaining('القبول:'), findsNothing, reason: 'whitespace-only acceptance is hidden');
      expect(find.text('الطريقة: فحص بصري'), findsOneWidget, reason: 'method is trimmed before render');
      expect(find.text('الطريقة:   فحص بصري  '), findsNothing, reason: 'raw un-trimmed value must not render');
    });

    testWidgets('5. long Arabic criteria and method render without error', (tester) async {
      final p = InspectionPoint(
        criteria: 'التأكد من عدم ظهور أي تشققات سطحية أو جفاف مبكر على كامل سطح الخرسانة المصبوبة حديثاً خلال فترة المعالجة الرطبة',
        acceptableTolerance: 'يجب ألا يجف السطح الخرساني خلال مدة المعالجة وإذا جف يُعاد التبليل فوراً ويُبلغ المهندس المسؤول',
        method: 'الفحص البصري الدوري للتأكد من بقاء السطح رطباً أو مغطى بأغطية واقية طوال مدة المعالجة المحددة',
      );
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      expect(tester.takeException(), isNull);
      expect(find.textContaining(p.criteria, findRichText: true), findsOneWidget);
    });

    testWidgets('6. RTL places marker to the right of the criteria text', (tester) async {
      final p = InspectionPoint(criteria: 'محاذاة الأعمدة', method: 'فحص رأسي');
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      final markerFinder = find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).shape == BoxShape.circle,
      );
      final criteriaFinder = find.textContaining(p.criteria, findRichText: true);
      expect(markerFinder, findsOneWidget);
      expect(criteriaFinder, findsOneWidget);

      final markerX = tester.getTopLeft(markerFinder).dx;
      final criteriaX = tester.getTopLeft(criteriaFinder).dx;
      expect(markerX, greaterThan(criteriaX), reason: 'marker must sit on the right side in RTL');
    });

    testWidgets('7. dark mode uses dark primary text and keeps badge', (tester) async {
      final p = InspectionPoint(
        criteria: 'معالجة الخرسانة',
        method: 'مراجعة السجلات',
        isCritical: true,
      );
      await tester.pumpWidget(wrap(
        InspectionPointWidget(block: block(p)),
        brightness: Brightness.dark,
      ));

      expect(_criteriaColor(tester, p.criteria), EncyclopediaCardColors.darkTextPrimary);
      expect(_detailsColor(tester, 'الطريقة: مراجعة السجلات'), EncyclopediaCardColors.darkTextMuted);
      expect(find.text('حرج'), findsOneWidget);
    });

    testWidgets('8. semantic marker styles use vivid style color', (tester) async {
      final p = InspectionPoint(
        criteria: 'نظافة الوجهات',
        markerStyle: 'success',
        markerColorMode: 'semantic',
      );
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      final deco = _circleDecoration(tester);
      expect(deco, isNotNull);
      expect(deco!.color, const Color(0xFF388E3C), reason: 'success semantic background');
      expect(find.text('✓'), findsOneWidget);
    });

    testWidgets('8b. theme marker mode uses topic accent', (tester) async {
      final p = InspectionPoint(criteria: 'فحص عام');
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      final deco = _circleDecoration(tester);
      expect(deco, isNotNull);
      expect(deco!.color, EncyclopediaCardColors.accent, reason: 'theme mode uses topic accent');
    });

    testWidgets('9. critical badge styling matches preview (10px, red on 10% red)', (tester) async {
      final p = InspectionPoint(criteria: 'حرج للغاية', isCritical: true);
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));

      final badgeText = tester.widget<Text>(find.text('حرج'));
      expect(badgeText.style?.fontSize, 10);
      expect(badgeText.style?.fontWeight, FontWeight.bold);
      expect(badgeText.style?.color, EncyclopediaCardColors.calloutRejectBorder);

      final deco = _badgeDecoration(tester);
      expect(deco, isNotNull);
      final bg = deco!.color!;
      expect(bg.a, closeTo(0.1, 0.02));
      expect(bg.r, closeTo(0xDC / 255, 0.001));
      expect(bg.g, closeTo(0x26 / 255, 0.001));
      expect(bg.b, closeTo(0x26 / 255, 0.001));
    });

    testWidgets('10. long Arabic content does not overflow in a narrow layout', (tester) async {
      final p = InspectionPoint(
        criteria: 'التأكد من استقامة أعمال البناء بالطوب وخلوها من العيوب والميول غير المسموح بها في أي اتجاه عبر كامل الوجهات والفتحات',
        acceptableTolerance: 'ألا يتجاوز الميل المسموح به الحدود المقررة في المواصفة المعتمدة للمشروع',
        method: 'استخدام الشاقول والميزان وتطبيق متطلبات الجودة على جميع المدماك دون استثناء',
      );
      await tester.pumpWidget(wrap(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: InspectionPointWidget(block: block(p)),
        ),
      ));

      expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow with wrapping Arabic text');
      expect(find.textContaining(p.criteria, findRichText: true), findsOneWidget);
    });

    testWidgets('11. empty criteria omits the widget entirely', (tester) async {
      final p = InspectionPoint(criteria: '   ');
      await tester.pumpWidget(wrap(InspectionPointWidget(block: block(p))));
      expect(find.byType(InspectionPointWidget), findsOneWidget);
      expect(find.text('!'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
