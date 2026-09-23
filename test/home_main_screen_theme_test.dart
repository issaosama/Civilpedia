import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/core/widgets/search_bar_widget.dart';
import 'package:civilpedia/data/local/preferences_helper.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/home/presentation/home_main_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeConnectivityProvider extends ConnectivityProvider {
  _FakeConnectivityProvider() : super();

  @override
  void dispose() {
    // The parent's async _init() has enough time to complete during pump(),
    // so super.dispose() can safely cancel the initialized subscription.
    super.dispose();
  }
}

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  @override
  Future<List<EngineeringTopic>> getAllTopics() async => const [];

  @override
  Future<EngineeringTopic?> getTopicById(String id) async => null;

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async =>
      const [];

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => const {};

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => const [];
}

Widget _pumpHome({
  required ThemeData theme,
  Locale locale = const Locale('ar'),
}) {
  final provider = EncyclopediaProvider(
    repository: _FakeEncyclopediaRepository(),
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(isArabic: locale.languageCode == 'ar'),
      ),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<ConnectivityProvider>(
        create: (_) => _FakeConnectivityProvider(),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: theme,
      home: const HomeMainScreen(),
    ),
  );
}

Widget _pumpThemeAwareHome(ThemeProvider themeProvider) {
  final encyclopediaProvider = EncyclopediaProvider(
    repository: _FakeEncyclopediaRepository(),
  );
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: encyclopediaProvider),
      ChangeNotifierProvider(create: (_) => LanguageProvider(isArabic: true)),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider.value(value: themeProvider),
      ChangeNotifierProvider<ConnectivityProvider>(
        create: (_) => _FakeConnectivityProvider(),
      ),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, provider, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: provider.themeMode,
        home: const HomeMainScreen(),
      ),
    ),
  );
}

void main() {
  group('HomeMainScreen theme-aware background', () {
    test('dark palette uses the final true-black surface hierarchy', () {
      expect(AppColors.darkBackground, const Color(0xFF000000));
      expect(AppColors.darkSurface, const Color(0xFF121212));
      expect(AppColors.darkSurfaceSecondary, const Color(0xFF1A1A1A));
      expect(AppColors.darkSurfaceElevated, const Color(0xFF262626));
    });

    testWidgets('uses light theme scaffold background', (tester) async {
      await tester.pumpWidget(_pumpHome(theme: AppTheme.lightTheme));
      await tester.pump(const Duration(milliseconds: 200));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        materialApp.theme?.scaffoldBackgroundColor,
        AppTheme.lightTheme.scaffoldBackgroundColor,
      );
    });

    testWidgets('uses dark theme scaffold background', (tester) async {
      await tester.pumpWidget(_pumpHome(theme: AppTheme.darkTheme));
      await tester.pump(const Duration(milliseconds: 200));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNull);

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        materialApp.theme?.scaffoldBackgroundColor,
        AppTheme.darkTheme.scaffoldBackgroundColor,
      );
    });
  });

  group('P2-A HomeHeader connectivity-dot removal', () {
    testWidgets(
      'real HomeMainScreen renders without the removed home connectivity dot',
      (tester) async {
        await tester.pumpWidget(_pumpHome(theme: AppTheme.lightTheme));
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.byIcon(Icons.wifi),
          findsNothing,
          reason: 'old HomeHeader connectivity dot used Icons.wifi when online',
        );
        expect(
          find.byIcon(Icons.wifi_off),
          findsNothing,
          reason:
              'old HomeHeader connectivity dot used Icons.wifi_off when offline',
        );
      },
    );
  });

  group('R10.4-A final Home header', () {
    testWidgets('upper Home uses compact brand and search without greeting', (
      tester,
    ) async {
      await tester.pumpWidget(_pumpHome(theme: AppTheme.lightTheme));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(Ar.welcome), findsNothing);
      expect(find.text(En.welcome), findsNothing);

      final brand = find.byKey(const ValueKey('home-brand-lockup'));
      final logo = find.descendant(of: brand, matching: find.byType(Image));
      expect(tester.getSize(logo), const Size(31, 31));
      final wordmark = tester.widget<Text>(
        find.descendant(of: brand, matching: find.text(Ar.appName)),
      );
      expect(wordmark.style?.fontSize, 18);

      expect(
        tester.widget<SearchBarWidget>(find.byType(SearchBarWidget)).compact,
        isTrue,
      );
      final searchHeight = tester.getSize(find.byType(TextField)).height;
      expect(searchHeight, inInclusiveRange(48, 50));
    });

    testWidgets('brand lockup is centered independently of side controls', (
      tester,
    ) async {
      await tester.pumpWidget(_pumpHome(theme: AppTheme.lightTheme));
      await tester.pump(const Duration(milliseconds: 200));

      final screenCenter = tester.getCenter(find.byType(HomeMainScreen)).dx;
      final brandCenter = tester
          .getCenter(find.byKey(const ValueKey('home-brand-lockup')))
          .dx;

      expect(brandCenter, closeTo(screenCenter, 0.5));
      final brand = find.byKey(const ValueKey('home-brand-lockup'));
      final logo = find.descendant(of: brand, matching: find.byType(Image));
      final wordmark = find.descendant(
        of: brand,
        matching: find.text(Ar.appName),
      );
      expect(
        tester.getCenter(logo).dx,
        lessThan(tester.getCenter(wordmark).dx),
      );
      expect(find.byKey(const ValueKey('home-profile-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-theme-toggle')), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search), findsNothing);
    });

    testWidgets('theme capsule toggles the existing theme provider', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await PreferencesHelper.init();
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(_pumpThemeAwareHome(themeProvider));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('home-theme-toggle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(themeProvider.isDarkMode, isTrue);
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(HomeMainScreen))).brightness,
        Brightness.dark,
      );
    });
  });

  testWidgets('Home View All actions use signature Amber', (tester) async {
    await tester.pumpWidget(_pumpHome(theme: AppTheme.lightTheme));
    await tester.pump(const Duration(milliseconds: 200));

    final actions = find.widgetWithText(TextButton, Ar.viewAll);
    expect(actions, findsNWidgets(4));
    for (final element in actions.evaluate()) {
      final button = element.widget as TextButton;
      expect(
        button.style?.foregroundColor?.resolve(<WidgetState>{}),
        AppColors.brandAmber,
      );
    }
  });

  group('R10.4-A locale presentation', () {
    testWidgets('Arabic Home uses RTL section and search copy', (tester) async {
      await tester.pumpWidget(_pumpHome(theme: AppTheme.lightTheme));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(Ar.quickAccess), findsNothing);
      expect(find.text(Ar.siteTools), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.hintText, Ar.homeEngineeringSearchHint);
      expect(
        Directionality.of(tester.element(find.text(Ar.siteTools))),
        TextDirection.rtl,
      );
    });

    testWidgets('English Home uses LTR section and search copy', (
      tester,
    ) async {
      await tester.pumpWidget(
        _pumpHome(theme: AppTheme.darkTheme, locale: const Locale('en')),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(En.quickAccess), findsNothing);
      expect(find.text(En.siteTools), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.hintText, En.homeEngineeringSearchHint);
      expect(
        Directionality.of(tester.element(find.text(En.siteTools))),
        TextDirection.ltr,
      );
    });
  });
}
