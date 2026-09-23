import 'package:civilpedia/features/business/domain/directory_entity_types.dart';
import 'package:civilpedia/features/home/presentation/widgets/engineering_directory_section.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(
          body: SingleChildScrollView(child: EngineeringDirectorySection()),
        ),
      ),
      GoRoute(
        path: '/directory',
        builder: (_, __) => const Scaffold(body: Text('Directory destination')),
        routes: [
          GoRoute(
            path: 'search',
            builder: (_, state) =>
                Scaffold(body: Text('Directory search: ${state.extra}')),
          ),
        ],
      ),
    ],
  );
}

Widget _app(GoRouter router, {Locale locale = const Locale('ar')}) {
  return MaterialApp.router(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: router,
  );
}

void main() {
  testWidgets('renders the four localized Directory discovery previews', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_router()));
    await tester.pumpAndSettle();

    expect(find.text(Ar.directoryLandingTitle), findsOneWidget);
    expect(find.text(Ar.homeDirectoryDescription), findsOneWidget);
    expect(find.text(Ar.homeDirectorySuppliersTitle), findsOneWidget);
    expect(find.text(Ar.homeDirectorySuppliersSubtitle), findsOneWidget);
    expect(find.text(Ar.homeDirectoryCompaniesTitle), findsOneWidget);
    expect(find.text(Ar.homeDirectoryCompaniesSubtitle), findsOneWidget);
    expect(find.text(Ar.homeDirectoryEngineeringOfficesTitle), findsOneWidget);
    expect(
      find.text(Ar.homeDirectoryEngineeringOfficesSubtitle),
      findsOneWidget,
    );
    expect(find.text(Ar.directoryServices), findsOneWidget);
    expect(find.text(Ar.homeDirectoryServicesSubtitle), findsOneWidget);
    expect(find.text(Ar.viewAll), findsOneWidget);
  });

  testWidgets('renders production English Directory preview copy', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_router(), locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text(En.directoryLandingTitle), findsOneWidget);
    expect(find.text(En.homeDirectoryDescription), findsOneWidget);
    expect(find.text(En.homeDirectorySuppliersTitle), findsOneWidget);
    expect(find.text(En.homeDirectorySuppliersSubtitle), findsOneWidget);
    expect(find.text(En.homeDirectoryCompaniesTitle), findsOneWidget);
    expect(find.text(En.homeDirectoryCompaniesSubtitle), findsOneWidget);
    expect(find.text(En.homeDirectoryEngineeringOfficesTitle), findsOneWidget);
    expect(
      find.text(En.homeDirectoryEngineeringOfficesSubtitle),
      findsOneWidget,
    );
    expect(find.text(En.directoryServices), findsOneWidget);
    expect(find.text(En.homeDirectoryServicesSubtitle), findsOneWidget);
    expect(find.text(En.viewAll), findsOneWidget);
  });

  testWidgets('View All reuses the canonical Directory root', (tester) async {
    final router = _router();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text(Ar.viewAll));
    await tester.pumpAndSettle();

    expect(find.text('Directory destination'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/directory');
  });

  const cardMappings = <String, String>{
    Ar.homeDirectorySuppliersTitle: DirectoryEntityType.supplier,
    Ar.homeDirectoryCompaniesTitle: DirectoryEntityType.company,
    Ar.homeDirectoryEngineeringOfficesTitle:
        DirectoryEntityType.engineeringOffice,
    Ar.directoryServices: DirectoryEntityType.serviceProvider,
  };

  for (final entry in cardMappings.entries) {
    testWidgets('${entry.key} opens Directory search with ${entry.value}', (
      tester,
    ) async {
      final router = _router();
      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();

      final card = find.byKey(ValueKey('home-directory-${entry.value}'));
      final inkWell = find.descendant(of: card, matching: find.byType(InkWell));
      expect(inkWell, findsOneWidget);

      await tester.tap(inkWell);
      await tester.pumpAndSettle();

      expect(find.text('Directory search: ${entry.value}'), findsOneWidget);
    });
  }
}
