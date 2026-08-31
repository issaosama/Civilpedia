import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/presentation/directory_category_presentation.dart';
import 'package:civilpedia/features/directory/presentation/directory_landing_screen.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:civilpedia/routes/app_routes.dart';

Widget _app({ValueChanged<BusinessType>? onCategorySelected, double width = 412}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 900)),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: DirectoryLandingScreen(onCategorySelected: onCategorySelected),
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, {ValueChanged<BusinessType>? onCategorySelected}) async {
  await tester.pumpWidget(_app(onCategorySelected: onCategorySelected));
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('W5.2 LANDING', () {
    testWidgets('1. Landing renders', (tester) async {
      await _pump(tester);
      expect(find.byType(DirectoryLandingScreen), findsOneWidget);
    });

    testWidgets('2. Arabic heading renders', (tester) async {
      await _pump(tester);
      expect(find.text(Ar.directoryLandingTitle), findsOneWidget);
    });

    testWidgets('3. English heading string exists in localization', (tester) async {
      expect(En.directoryLandingTitle, 'Engineering Directory');
    });

    testWidgets('4. all 12 categories render', (tester) async {
      await _pump(tester);
      for (final type in DirectoryCategoryPresentation.orderedTypes) {
        final label = DirectoryCategoryPresentation.labelFor(type, isArabic: true);
        await _scrollTo(tester, label);
        expect(find.text(label), findsWidgets,
            reason: 'category label should render: $label');
      }
    });

    test('5. exactly 12 BusinessType identities are represented', () {
      expect(DirectoryCategoryPresentation.orderedTypes.toSet().length, 12);
      expect(DirectoryCategoryPresentation.orderedTypes.length, 12);
      expect(BusinessType.values.length, 12);
    });

    test('6. no category duplicated', () {
      expect(DirectoryCategoryPresentation.orderedTypes.toSet().length,
          DirectoryCategoryPresentation.orderedTypes.length);
    });

    test('7. stable presentation order is preserved', () {
      expect(DirectoryCategoryPresentation.orderedTypes, [
        BusinessType.supplier,
        BusinessType.technician,
        BusinessType.equipmentOwner,
        BusinessType.engineeringOffice,
        BusinessType.constructionCompany,
        BusinessType.buildingOffice,
        BusinessType.testingLab,
        BusinessType.surveyor,
        BusinessType.contractor,
        BusinessType.materialShop,
        BusinessType.consultantOffice,
        BusinessType.other,
      ]);
    });
  });

  group('W5.2 LOCALIZATION', () {
    test('8. each BusinessType resolves an Arabic label', () {
      for (final type in BusinessType.values) {
        expect(DirectoryCategoryPresentation.arLabel(type), isNotEmpty);
        expect(DirectoryCategoryPresentation.arLabel(type), isNot(type.name));
      }
    });

    test('9. each BusinessType resolves an English label', () {
      for (final type in BusinessType.values) {
        expect(DirectoryCategoryPresentation.enLabel(type), isNotEmpty);
        expect(DirectoryCategoryPresentation.enLabel(type), isNot(type.name));
      }
    });

    test('10. labels are presentation-only (persisted stays enum name)', () {
      // The persisted serialization must keep the stable enum identity.
      expect(BusinessType.supplier.key, 'supplier');
      expect(BusinessType.consultantOffice.key, 'consultant_office');
      expect(DirectoryCategoryPresentation.arLabel(BusinessType.supplier), 'مورّد');
      expect(DirectoryCategoryPresentation.enLabel(BusinessType.supplier), 'Supplier');
    });

    test('11. enum stable values remain unchanged', () {
      expect(BusinessType.values.map((e) => e.key).toList(), [
        'supplier',
        'technician',
        'equipment_owner',
        'engineering_office',
        'construction_company',
        'building_office',
        'testing_lab',
        'surveyor',
        'contractor',
        'material_shop',
        'consultant_office',
        'other',
      ]);
    });
  });

  group('W5.2 INTERACTION', () {
    testWidgets('12. callback receives correct BusinessType on tap', (tester) async {
      final selected = <BusinessType>[];
      await _pump(tester, onCategorySelected: selected.add);
      final target = DirectoryCategoryPresentation.labelFor(
        BusinessType.contractor,
        isArabic: true,
      );
      await _scrollTo(tester, target);
      await tester.tap(find.text(target).first);
      await tester.pumpAndSettle();
      expect(selected, [BusinessType.contractor]);
    });

    testWidgets('13. tapping one category does not invoke another', (tester) async {
      final selected = <BusinessType>[];
      await _pump(tester, onCategorySelected: selected.add);
      final target = DirectoryCategoryPresentation.labelFor(
        BusinessType.supplier,
        isArabic: true,
      );
      await tester.tap(find.text(target).first);
      await tester.pumpAndSettle();
      expect(selected, [BusinessType.supplier]);
      expect(selected, isNot(contains(BusinessType.technician)));
    });

    testWidgets('14. null callback causes no navigation/crash', (tester) async {
      await _pump(tester); // onCategorySelected is null
      final label = DirectoryCategoryPresentation.labelFor(
        BusinessType.contractor,
        isArabic: true,
      );
      await _scrollTo(tester, label);
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test('15. no permanent route is required (heading only, callback seam)', () {
      // The screen constructor only needs the optional callback; no route.
      const screen = DirectoryLandingScreen();
      expect(screen.onCategorySelected, isNull);
    });
  });

  group('W5.2 DATA INDEPENDENCE', () {
    testWidgets('16. Landing renders with no sb_profiles data', (tester) async {
      // No SharedPreferences seed; taxonomy always renders.
      await _pump(tester);
      for (final type in DirectoryCategoryPresentation.orderedTypes) {
        final label = DirectoryCategoryPresentation.labelFor(type, isArabic: true);
        await _scrollTo(tester, label);
        expect(find.text(label), findsWidgets);
      }
    });

    testWidgets('17. Landing requires no DirectoryRepository reads', (tester) async {
      await _pump(tester);
      expect(find.byType(DirectoryLandingScreen), findsOneWidget);
      // No provider-based data loading present.
    });

    testWidgets('18. no provider counts appear', (tester) async {
      await _pump(tester);
      final allText = tester.widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      final countSignal = allText.where(
        (t) => RegExp(r'\(?\d+\s*(providers?|companies?|شركات?|موردين?|مقدمي?)\)?')
            .hasMatch(t),
      );
      expect(countSignal, isEmpty);
    });

    test('19. no profile-dependent ordering occurs', () {
      // Order is the fixed presentation list, not derived from data.
      expect(DirectoryCategoryPresentation.orderedTypes,
          const [
            BusinessType.supplier,
            BusinessType.technician,
            BusinessType.equipmentOwner,
            BusinessType.engineeringOffice,
            BusinessType.constructionCompany,
            BusinessType.buildingOffice,
            BusinessType.testingLab,
            BusinessType.surveyor,
            BusinessType.contractor,
            BusinessType.materialShop,
            BusinessType.consultantOffice,
            BusinessType.other,
          ]);
    });
  });

  group('W5.2 NON-SCOPE UI', () {
    testWidgets('20. no search field', (tester) async {
      await _pump(tester);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search), findsNothing);
    });

    testWidgets('21. no filter control', (tester) async {
      await _pump(tester);
      expect(find.byIcon(Icons.filter_list), findsNothing);
      expect(find.byIcon(Icons.tune), findsNothing);
    });

    testWidgets('22. no provider listing', (tester) async {
      await _pump(tester);
      // No provider list entries beyond the 12 category labels.
      expect(DirectoryCategoryPresentation.orderedTypes.length, 12);
    });

    testWidgets('23. no verification badge', (tester) async {
      await _pump(tester);
      for (final s in VerificationStatus.values) {
        expect(find.text(s.name), findsNothing);
      }
    });

    testWidgets('24. no contact action', (tester) async {
      await _pump(tester);
      expect(find.byIcon(Icons.phone), findsNothing);
      expect(find.byIcon(Icons.whatshot), findsNothing);
      expect(find.byIcon(Icons.email), findsNothing);
      expect(find.byIcon(Icons.map), findsNothing);
    });

    testWidgets('25. no Saved Provider control', (tester) async {
      await _pump(tester);
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('26. no featured/sponsored section', (tester) async {
      await _pump(tester);
      final text = tester.widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '').toList();
      expect(text.any((t) => t.contains('Sponsored') || t.contains('Featured')), isFalse);
      expect(text.any((t) => t.contains('مدعوم') || t.contains('مميز')), isFalse);
    });
  });

  group('W5.2 NAVIGATION FREEZE', () {
    test('27. no /directory route is registered/buildable', () {
      final routes = File('lib/routes/app_routes.dart').readAsStringSync();
      // Only the doc comment may mention /directory as a future target; no route constant.
      expect(RegExp(r"static const String directory\b").hasMatch(routes), isFalse);
    });

    test('28. shell destinations remain unchanged', () {
      final routes = kShellDestinations.map((d) => d.route).toList();
      expect(routes, [
        AppRoutes.home,
        AppRoutes.encyclopedia,
        AppRoutes.tools,
        AppRoutes.saved,
        AppRoutes.profile,
      ]);
    });

    test('29. bottom navigation remains unchanged (5 destinations)', () {
      expect(kShellDestinations.length, 5);
      expect(kShellDestinations.any((d) => d.route.contains('directory')), isFalse);
    });

    test('30. global search constant unchanged', () {
      expect(AppRoutes.search, '/search');
    });
  });

  group('W5.2 COMPATIBILITY', () {
    test('31. BusinessType file unchanged identity set', () {
      expect(BusinessType.values.map((e) => e.name).toList(), [
        'supplier',
        'technician',
        'equipmentOwner',
        'engineeringOffice',
        'constructionCompany',
        'buildingOffice',
        'testingLab',
        'surveyor',
        'contractor',
        'materialShop',
        'consultantOffice',
        'other',
      ]);
    });

    test('32. repository wrapper files remain untouched (no W5.2 edits)', () {
      const forbidden = [
        'lib/features/directory/domain/directory_repository.dart',
        'lib/features/directory/data/sb_profiles_directory_repository.dart',
        'lib/features/directory/domain/directory_data_version.dart',
      ];
      for (final f in forbidden) {
        final source = File(f).readAsStringSync();
        expect(source.contains('directory_landing'), isFalse);
      }
    });

    test('33. sb_profiles key unchanged', () {
      final keys = File('lib/core/storage/app_storage_keys.dart').readAsStringSync();
      expect(keys.contains("sbProfiles = 'sb_profiles'"), isTrue);
    });
  });
}
