import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/navigation/shell_content_insets.dart';
import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

/// Minimal stand-in for a branch content screen. Carries per-branch stateful
/// widgets so IndexedStack state preservation can be asserted.
class _BranchProbe extends StatelessWidget {
  final String label;

  const _BranchProbe({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Column(
        children: [
          Text('probe:$label', key: ValueKey('probe-$label')),
          TextField(key: ValueKey('field-$label')),
          ElevatedButton(
            key: ValueKey('push-outside-$label'),
            onPressed: () => context.push('/outside'),
            child: const Text('push outside'),
          ),
        ],
      ),
    );
  }
}

class _FakeTransportSource implements TransportSource {
  _FakeTransportSource();
  @override
  Future<bool> checkAvailability() async => true;
  @override
  Stream<bool> get availabilityChanges => const Stream.empty();
}

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

/// Mirrors the production shell structure: StatefulShellRoute.indexedStack
/// driven by kShellDestinations plus a representative root-pushed route.
GoRouter _buildTestRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          for (final destination in kShellDestinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: destination.route,
                  builder: (_, __) => _BranchProbe(label: destination.route),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: '/outside',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('outside')),
          body: const Text('outside-body'),
        ),
      ),
    ],
  );
}

Future<void> _pumpShell(
  WidgetTester tester, {
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
  double bottomInset = 0,
}) async {
  final connectivity = ConnectivityProvider(source: _FakeTransportSource());
  await connectivity.initialization;
  await tester.pumpWidget(
    ChangeNotifierProvider<ConnectivityProvider>.value(
      value: connectivity,
      child: MaterialApp.router(
        locale: locale,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              padding: mediaQuery.padding.copyWith(bottom: bottomInset),
            ),
            child: child!,
          );
        },
        routerConfig: _buildTestRouter(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

NavigatorState _rootNavigatorOf(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

void _mockSystemNavigatorPop(WidgetTester tester, List<bool> log) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') {
        log.add(true);
      }
      return null;
    },
  );
}

void main() {
  testWidgets('renders all five W6.3 destinations with RTL Arabic labels', (
    tester,
  ) async {
    await _pumpShell(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text(Ar.home), findsOneWidget);
    expect(find.text(Ar.encyclopedia), findsOneWidget);
    expect(find.text(Ar.tools), findsOneWidget);
    expect(find.text(Ar.checklistMyProjects), findsOneWidget);
    expect(find.text(Ar.directory), findsOneWidget);
    expect(find.byKey(const ValueKey('probe-/home')), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(Ar.home))),
      TextDirection.rtl,
    );

    // Order contract required by W6.3 (indexed-stack branch order).
    expect(kShellDestinations[0].route, '/home');
    expect(kShellDestinations[1].route, '/encyclopedia');
    expect(kShellDestinations[2].route, '/tools');
    expect(kShellDestinations[3].route, '/projects');
    expect(kShellDestinations[4].route, '/directory');
  });

  testWidgets('English shell: all five nav labels use canonical En values', (
    tester,
  ) async {
    await _pumpShell(tester, locale: const Locale('en'));

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text(En.home), findsOneWidget);
    expect(find.text(En.encyclopedia), findsOneWidget);
    expect(find.text(En.tools), findsOneWidget);
    expect(find.text(En.checklistMyProjects), findsOneWidget);
    expect(find.text(En.directory), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(En.home))),
      TextDirection.ltr,
    );
  });

  testWidgets('light shell uses accessible restrained selected styling', (
    tester,
  ) async {
    await _pumpShell(tester);

    final navigation = tester.widget<Container>(
      find.byKey(const ValueKey('shell-bottom-navigation')),
    );
    final navigationDecoration = navigation.decoration! as BoxDecoration;
    expect(navigationDecoration.color, AppColors.surfaceElevated);
    expect(navigationDecoration.boxShadow, hasLength(1));

    final selectedIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('shell-nav-icon-0')),
    );
    final selectedLabel = tester.widget<Text>(
      find.byKey(const ValueKey('shell-nav-label-0')),
    );
    final unselectedIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('shell-nav-icon-1')),
    );
    expect(selectedIcon.color, AppColors.brandAmberPressed);
    expect(selectedLabel.style?.color, AppColors.brandAmberPressed);
    expect(selectedLabel.style?.fontSize, 11);
    expect(unselectedIcon.color, AppColors.textSecondary);
    expect(
      tester.getSize(find.byKey(const ValueKey('shell-nav-item-0'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('dark shell uses surface separation without a cast shadow', (
    tester,
  ) async {
    await _pumpShell(tester, themeMode: ThemeMode.dark);

    final navigation = tester.widget<Container>(
      find.byKey(const ValueKey('shell-bottom-navigation')),
    );
    final navigationDecoration = navigation.decoration! as BoxDecoration;
    final selectedIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('shell-nav-icon-0')),
    );
    final unselectedIcon = tester.widget<Icon>(
      find.byKey(const ValueKey('shell-nav-icon-1')),
    );

    expect(navigationDecoration.color, AppColors.darkSurfaceElevated);
    expect(navigationDecoration.boxShadow, isNull);
    expect(selectedIcon.color, AppColors.darkBrandAmber);
    expect(unselectedIcon.color, AppColors.darkTextSecondary);
  });

  testWidgets('compact and expanded widths keep the five-item shell bounded', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    await _pumpShell(tester);

    expect(
      tester
          .getSize(find.byKey(const ValueKey('shell-bottom-navigation')))
          .width,
      358,
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('shell-bottom-navigation')))
          .width,
      760,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('device safe area is included in the published obstruction', (
    tester,
  ) async {
    await _pumpShell(tester, bottomInset: 34);

    final probeElement = tester.element(
      find.byKey(const ValueKey('probe-/home')),
    );
    final insets = ShellContentInsets.of(probeElement);
    expect(insets.bottomObstruction, 104);
  });

  testWidgets('English first-back at branch root confirms exit with En copy', (
    tester,
  ) async {
    final popLog = <bool>[];
    _mockSystemNavigatorPop(tester, popLog);
    await _pumpShell(tester, locale: const Locale('en'));

    await _rootNavigatorOf(tester).maybePop();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(En.exitConfirm), findsOneWidget);
    expect(popLog, isEmpty);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('every destination reaches its branch', (tester) async {
    await _pumpShell(tester);

    for (final destination in kShellDestinations.skip(1)) {
      await tester.tap(find.text(destination.label));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('probe-${destination.route}')),
        findsOneWidget,
        reason: '${destination.route} branch did not become visible',
      );
    }
  });

  testWidgets('IndexedStack preserves branch state across tab switches', (
    tester,
  ) async {
    await _pumpShell(tester);

    await tester.enterText(
      find.byKey(const ValueKey('field-/home')),
      'kept-state',
    );
    await tester.pump();

    await tester.tap(find.text(Ar.tools));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('probe-/tools')), findsOneWidget);

    await tester.tap(find.text(Ar.home));
    await tester.pumpAndSettle();

    expect(find.text('kept-state'), findsOneWidget);
  });

  testWidgets('re-selecting the current tab is inert', (tester) async {
    await _pumpShell(tester);

    await tester.tap(find.text(Ar.home));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('probe-/home')), findsOneWidget);
    expect(find.text(Ar.exitConfirm), findsNothing);
  });

  testWidgets(
    'first back press at a branch root is blocked and confirms exit',
    (tester) async {
      final popLog = <bool>[];
      _mockSystemNavigatorPop(tester, popLog);
      await _pumpShell(tester);

      await _rootNavigatorOf(tester).maybePop();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(Ar.exitConfirm), findsOneWidget);
      expect(popLog, isEmpty);
      expect(find.byKey(const ValueKey('probe-/home')), findsOneWidget);

      // Let the SnackBar timer fire so no timer is left pending.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('second back press within the window exits via SystemNavigator', (
    tester,
  ) async {
    final popLog = <bool>[];
    _mockSystemNavigatorPop(tester, popLog);
    await _pumpShell(tester);

    await _rootNavigatorOf(tester).maybePop();
    await tester.pump(const Duration(milliseconds: 100));
    await _rootNavigatorOf(tester).maybePop();
    await tester.pump();

    expect(popLog, hasLength(1));

    // Drain the pending SnackBar timer from the first (blocked) press.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('root-pushed routes render above, not inside, the shell', (
    tester,
  ) async {
    await _pumpShell(tester);

    await tester.tap(find.byKey(const ValueKey('push-outside-/home')));
    await tester.pumpAndSettle();

    expect(find.text('outside-body'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byKey(const ValueKey('probe-/home')), findsOneWidget);
  });

  testWidgets(
    'AppShell publishes shellBottomObstruction through ShellContentInsets',
    (tester) async {
      await _pumpShell(tester);

      final probeElement = tester.element(
        find.byKey(const ValueKey('probe-/home')),
      );
      final insets = ShellContentInsets.maybeOf(probeElement);
      expect(
        insets,
        isNotNull,
        reason: 'branch content must be inside ShellContentInsets',
      );
      expect(
        insets!.bottomObstruction,
        AppShell.shellBottomObstruction,
        reason: 'published obstruction must equal canonical constant (86)',
      );
    },
  );
}
