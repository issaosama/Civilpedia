import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/navigation/shell_content_insets.dart';
import 'package:civilpedia/localization/ar.dart';

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

Future<void> _pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _buildTestRouter(),
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
  testWidgets('renders all five Phase-B destinations with RTL Arabic labels',
      (tester) async {
    await _pumpShell(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text(Ar.home), findsOneWidget);
    expect(find.text(Ar.encyclopedia), findsOneWidget);
    expect(find.text(Ar.tools), findsOneWidget);
    expect(find.text(Ar.saved), findsOneWidget);
    expect(find.text(Ar.account), findsOneWidget);
    expect(find.byKey(const ValueKey('probe-/home')), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(Ar.home))),
      TextDirection.rtl,
    );

    // Order contract required for Phase B.
    expect(kShellDestinations[0].route, '/home');
    expect(kShellDestinations[1].route, '/encyclopedia');
    expect(kShellDestinations[2].route, '/tools');
    expect(kShellDestinations[3].route, '/saved');
    expect(kShellDestinations[4].route, '/profile');
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

  testWidgets('IndexedStack preserves branch state across tab switches',
      (tester) async {
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

  testWidgets('first back press at a branch root is blocked and confirms exit',
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
  });

  testWidgets('second back press within the window exits via SystemNavigator',
      (tester) async {
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

  testWidgets('root-pushed routes render above, not inside, the shell',
      (tester) async {
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

    final probeElement = tester.element(find.byKey(const ValueKey('probe-/home')));
    final insets = ShellContentInsets.maybeOf(probeElement);
    expect(insets, isNotNull,
        reason: 'branch content must be inside ShellContentInsets');
    expect(insets!.bottomObstruction, AppShell.shellBottomObstruction,
        reason: 'published obstruction must equal canonical constant (86)');
  });
}
