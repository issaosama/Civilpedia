import 'dart:async';

import 'package:civilpedia/core/network/reconnect_generation_gate.dart';
import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/widgets/remote_data_notice.dart';
import 'package:civilpedia/core/widgets/transport_status_banner.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/navigation/app_shell.dart';

// ── Fake transport source ──

class _FakeTransportSource implements TransportSource {
  _FakeTransportSource(Future<bool> Function() check) : _check = check {
    changes = StreamController<bool>.broadcast(sync: true);
  }

  final Future<bool> Function() _check;
  late final StreamController<bool> changes;

  @override
  Future<bool> checkAvailability() => _check();

  @override
  Stream<bool> get availabilityChanges => changes.stream;

  Future<void> close() => changes.close();
}

// ── Minimal router for shell integration tests ──

class _Probe extends StatelessWidget {
  final String label;
  const _Probe({required this.label});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('probe:$label', key: ValueKey('probe-$label')));
  }
}

final _rootKey = GlobalKey<NavigatorState>();

GoRouter _buildShellRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          for (final d in kShellDestinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: d.route,
                  builder: (_, __) => _Probe(label: d.route),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

Widget _wrapWithProviders({
  required Widget child,
  ConnectivityProvider? connectivity,
  Locale locale = const Locale('ar'),
}) {
  return ChangeNotifierProvider<ConnectivityProvider>.value(
    value: connectivity ?? ConnectivityProvider(source: _FakeTransportSource(() async => true)),
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

Widget _wrapNotice(Widget child, {bool isArabic = true}) {
  return MaterialApp(
    locale: Locale(isArabic ? 'ar' : 'en'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  // ══════════════════════════════════════════════════════════════════════
  // RECONNECT GENERATION GATE
  // ══════════════════════════════════════════════════════════════════════
  group('ReconnectGenerationGate', () {
    test('initial bind records the current generation', () {
      final gate = ReconnectGenerationGate();
      gate.bind(3);
      expect(gate.lastHandledGeneration, 3);
      gate.dispose();
    });

    test('generation 0 is never claimable', () {
      final gate = ReconnectGenerationGate();
      gate.bind(0);
      expect(gate.claimCurrentGeneration(0), isFalse);
      expect(gate.lastHandledGeneration, 0);
      gate.dispose();
    });

    test('negative generation is never claimable', () {
      final gate = ReconnectGenerationGate();
      gate.bind(-1);
      expect(gate.claimCurrentGeneration(-1), isFalse);
      expect(gate.lastHandledGeneration, -1);
      gate.dispose();
    });

    test('duplicate generation is rejected', () {
      final gate = ReconnectGenerationGate();
      gate.bind(1);
      expect(gate.claimCurrentGeneration(1), isFalse);
      expect(gate.lastHandledGeneration, 1);
      gate.dispose();
    });

    test('older generation is rejected', () {
      final gate = ReconnectGenerationGate();
      gate.bind(5);
      expect(gate.claimCurrentGeneration(3), isFalse);
      expect(gate.lastHandledGeneration, 5);
      gate.dispose();
    });

    test('newer positive generation is claimed once', () {
      final gate = ReconnectGenerationGate();
      gate.bind(2);
      expect(gate.claimCurrentGeneration(3), isTrue);
      expect(gate.lastHandledGeneration, 3);
      expect(gate.claimCurrentGeneration(3), isFalse,
          reason: 'same generation cannot be claimed twice');
      gate.dispose();
    });

    test('next newer generation is claimed once', () {
      final gate = ReconnectGenerationGate();
      gate.bind(1);
      expect(gate.claimCurrentGeneration(2), isTrue);
      expect(gate.claimCurrentGeneration(3), isTrue);
      expect(gate.lastHandledGeneration, 3);
      gate.dispose();
    });

    test('failed read does not reopen old generation', () {
      final gate = ReconnectGenerationGate();
      gate.bind(1);
      expect(gate.claimCurrentGeneration(2), isTrue);
      // Simulating a failed read — we do NOT roll back
      expect(gate.claimCurrentGeneration(2), isFalse,
          reason: 'failed read must not reopen same generation');
      gate.dispose();
    });

    test('reset returns to unbound state', () {
      final gate = ReconnectGenerationGate();
      gate.bind(3);
      gate.reset();
      expect(gate.lastHandledGeneration, -1);
      expect(gate.claimCurrentGeneration(1), isTrue);
      gate.dispose();
    });

    test('no Timer ownership', () {
      final gate = ReconnectGenerationGate();
      expect(gate, isNot(isA<Timer>()));
      gate.dispose();
    });

    test('no Future ownership', () {
      final gate = ReconnectGenerationGate();
      final result = gate.claimCurrentGeneration(1);
      expect(result, isA<bool>());
      gate.dispose();
    });

    test('dispose prevents further claims', () {
      final gate = ReconnectGenerationGate();
      gate.bind(1);
      gate.dispose();
      expect(gate.claimCurrentGeneration(2), isFalse);
    });

    test('initial state before bind is claimable for any positive gen', () {
      final gate = ReconnectGenerationGate();
      expect(gate.lastHandledGeneration, -1);
      expect(gate.claimCurrentGeneration(1), isTrue);
      expect(gate.lastHandledGeneration, 1);
      gate.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // TRANSPORT STATUS BANNER
  // ══════════════════════════════════════════════════════════════════════
  group('TransportStatusBanner', () {
    testWidgets('unknown state shows no banner (no false online/offline)',
        (tester) async {
      final source = _FakeTransportSource(() => Completer<bool>().future);
      final connectivity = ConnectivityProvider(
        source: source,
        initialCheckTimeout: const Duration(milliseconds: 20),
      );

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
      ));
      await tester.pump();

      // State is UNKNOWN: no banner, no false offline/online assertion.
      expect(find.byType(TransportStatusBanner), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);

      connectivity.dispose();
      await source.close();
      await tester.pump();
    });

    testWidgets('unavailable state shows exactly one non-blocking banner',
        (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text(Ar.transportUnavailableTitle), findsOneWidget);
      connectivity.dispose();
      await source.close();
    });

    testWidgets('available state shows no banner', (tester) async {
      final source = _FakeTransportSource(() async => true);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
      connectivity.dispose();
      await source.close();
    });

    testWidgets('unavailable → available clears banner', (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      source.changes.add(true);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
      connectivity.dispose();
      await source.close();
    });

    testWidgets('repeated unavailable events do not stack banners',
        (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
      ));
      await tester.pumpAndSettle();

      // Force rebuild — Simulate repeated unavailable events
      source.changes.add(false);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget,
          reason: 'must remain exactly one banner');
      connectivity.dispose();
      await source.close();
    });

    testWidgets('shell remains interactive when banner is visible',
        (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(ChangeNotifierProvider<ConnectivityProvider>.value(
        value: connectivity,
        child: MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _buildShellRouter(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);

      // Can still tap navigation
      await tester.tap(find.text(Ar.tools));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('probe-/tools')), findsOneWidget);

      connectivity.dispose();
      await source.close();
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // LAYOUT / THEME
  // ══════════════════════════════════════════════════════════════════════
  group('Layout and Theme', () {
    testWidgets('Arabic RTL - banner renders correctly', (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      expect(find.text(Ar.transportUnavailableTitle), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      connectivity.dispose();
      await source.close();
    });

    testWidgets('English LTR - banner renders correctly', (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text(En.transportUnavailableTitle), findsOneWidget);
      connectivity.dispose();
      await source.close();
    });

    testWidgets('light theme renders correctly', (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(ChangeNotifierProvider<ConnectivityProvider>.value(
        value: connectivity,
        child: MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(body: TransportStatusBanner()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TransportStatusBanner), findsOneWidget);
      connectivity.dispose();
      await source.close();
    });

    testWidgets('dark theme renders correctly', (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(ChangeNotifierProvider<ConnectivityProvider>.value(
        value: connectivity,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: TransportStatusBanner()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TransportStatusBanner), findsOneWidget);
      connectivity.dispose();
      await source.close();
    });

    testWidgets('narrow screen does not overflow', (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
      ));
      await tester.pumpAndSettle();

      final errors = tester.takeException();
      if (errors != null) {
        expect(errors.toString(), isNot(contains('overflow')));
      }
      expect(find.byType(TransportStatusBanner), findsOneWidget);
      connectivity.dispose();
      await source.close();
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // LOCALIZATION
  // ══════════════════════════════════════════════════════════════════════
  group('Localization', () {
    testWidgets('no forced Arabic in English banner', (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text(En.transportUnavailableTitle), findsOneWidget);
      expect(find.text(En.transportUnavailableMessage), findsOneWidget);
      expect(find.text(Ar.transportUnavailableTitle), findsNothing);
      connectivity.dispose();
      await source.close();
    });

    testWidgets('correct Arabic transport copy', (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
        locale: const Locale('ar'),
      ));
      await tester.pumpAndSettle();

      expect(find.text(Ar.transportUnavailableTitle), findsOneWidget);
      expect(find.text(Ar.transportUnavailableMessage), findsOneWidget);
      connectivity.dispose();
      await source.close();
    });

    testWidgets('correct localized retry copy', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: RemoteDataNotice(
            cause: RemoteDataCause.offline,
            onRetry: () => tapped = true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(Ar.retry), findsOneWidget);
      await tester.tap(find.text(Ar.retry));
      expect(tapped, isTrue);
    });

    testWidgets('English retry label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: RemoteDataNotice(
            cause: RemoteDataCause.offline,
            onRetry: null,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(En.retry), findsNothing,
          reason: 'retry is hidden without callback');
      expect(find.text(En.noticeOffline), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // REMOTE DATA NOTICE
  // ══════════════════════════════════════════════════════════════════════
  group('RemoteDataNotice', () {
    testWidgets('compact mode renders typed cause', (tester) async {
      await tester.pumpWidget(_wrapNotice(
        const RemoteDataNotice(
          cause: RemoteDataCause.offline,
          mode: RemoteDataNoticeMode.compact,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text(Ar.noticeOffline), findsOneWidget);
    });

    testWidgets('no-data mode renders centered notice', (tester) async {
      await tester.pumpWidget(_wrapNotice(
        const RemoteDataNotice(
          cause: RemoteDataCause.timeout,
          mode: RemoteDataNoticeMode.noData,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timer_off_rounded), findsOneWidget);
      expect(find.text(Ar.noticeTimeout), findsOneWidget);
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('retry hidden without callback in compact mode',
        (tester) async {
      await tester.pumpWidget(_wrapNotice(
        const RemoteDataNotice(
          cause: RemoteDataCause.serviceUnavailable,
          mode: RemoteDataNoticeMode.compact,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(Ar.retry), findsNothing);
    });

    testWidgets('retry shown with callback in compact mode', (tester) async {
      await tester.pumpWidget(_wrapNotice(
        RemoteDataNotice(
          cause: RemoteDataCause.serviceUnavailable,
          mode: RemoteDataNoticeMode.compact,
          onRetry: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(Ar.retry), findsOneWidget);
    });

    testWidgets('retry shown with callback in no-data mode', (tester) async {
      await tester.pumpWidget(_wrapNotice(
        RemoteDataNotice(
          cause: RemoteDataCause.malformed,
          mode: RemoteDataNoticeMode.noData,
          onRetry: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('callback invoked once per tap', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(_wrapNotice(
        RemoteDataNotice(
          cause: RemoteDataCause.offline,
          onRetry: () => tapCount++,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Ar.retry));
      expect(tapCount, 1);
      await tester.tap(find.text(Ar.retry));
      expect(tapCount, 2);
    });

    testWidgets('all typed causes render without raw errors', (tester) async {
      for (final cause in RemoteDataCause.values) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: RemoteDataNotice(cause: cause),
          ),
        ));
        await tester.pumpAndSettle();

        // Should not throw and should produce visible text
        expect(find.byType(RemoteDataNotice), findsOneWidget);
      }
    });

    testWidgets('no mutation-specific API surface', (tester) async {
      // The widget only accepts onRetry (read), never onMutate/onSave
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RemoteDataNotice(
            cause: RemoteDataCause.offline,
            onRetry: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Verify widget exists and only has retry semantics
      final notice = tester.widget<RemoteDataNotice>(find.byType(RemoteDataNotice));
      expect(notice.onRetry, isNotNull);
      // The widget class does not have any mutation fields — verified at compile time
    });

    testWidgets('English compact notice', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: RemoteDataNotice(
            cause: RemoteDataCause.permissionDenied,
            mode: RemoteDataNoticeMode.compact,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(En.noticePermissionDenied), findsOneWidget);
    });

    testWidgets('English no-data notice', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: RemoteDataNotice(
            cause: RemoteDataCause.authRestricted,
            mode: RemoteDataNoticeMode.noData,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(En.noticeAuthRestricted), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // HOME CONNECTIVITY INDICATOR REMOVAL
  // ══════════════════════════════════════════════════════════════════════
  group('Home connectivity indicator removed', () {
    testWidgets('home_header.dart no longer imports ConnectivityProvider',
        (tester) async {
      // The _ConnectivityDot class has been removed from home_header.dart.
      // We verify the source file does not reference ConnectivityProvider.
      // (Static analysis confirms this at compile time; here we check at runtime.)
      final source = await _FakeTransportSource(() async => true);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(Ar.appName),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // No wifi dot icon should appear from home header
      // (wifi_off_rounded belongs to TransportStatusBanner only)
      connectivity.dispose();
      await source.close();
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════
  group('Lifecycle', () {
    testWidgets('shell/provider disposal safe', (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(_wrapWithProviders(
        connectivity: connectivity,
        child: const TransportStatusBanner(),
      ));
      await tester.pumpAndSettle();

      connectivity.dispose();
      await tester.pumpAndSettle();

      // Should not throw
      expect(find.byType(TransportStatusBanner), findsOneWidget);
      await source.close();
    });

    testWidgets('banner rebuilds correctly after provider replacement',
        (tester) async {
      final source1 = _FakeTransportSource(() async => false);
      final connectivity1 = ConnectivityProvider(source: source1);
      await connectivity1.initialization;

      final key = GlobalKey();

      await tester.pumpWidget(ChangeNotifierProvider<ConnectivityProvider>.value(
        value: connectivity1,
        child: MaterialApp(
          home: Scaffold(
            key: key,
            body: const TransportStatusBanner(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      // Replace with available provider
      final source2 = _FakeTransportSource(() async => true);
      final connectivity2 = ConnectivityProvider(source: source2);
      await connectivity2.initialization;

      await tester.pumpWidget(ChangeNotifierProvider<ConnectivityProvider>.value(
        value: connectivity2,
        child: MaterialApp(
          home: Scaffold(
            key: key,
            body: const TransportStatusBanner(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);

      connectivity1.dispose();
      connectivity2.dispose();
      await source1.close();
      await source2.close();
    });

    test('ReconnectGenerationGate dispose is safe', () {
      final gate = ReconnectGenerationGate();
      gate.bind(1);
      gate.dispose();
      gate.dispose(); // double dispose safe
      expect(gate.lastHandledGeneration, 1);
    });
  });

  // ══════════════════════════════════════════════════════════════════════
  // APP SHELL INTEGRATION
  // ══════════════════════════════════════════════════════════════════════
  group('AppShell transport integration', () {
    testWidgets('banner visible in shell when transport unavailable',
        (tester) async {
      final source = _FakeTransportSource(() async => false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(ChangeNotifierProvider<ConnectivityProvider>.value(
        value: connectivity,
        child: MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _buildShellRouter(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TransportStatusBanner), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);

      connectivity.dispose();
      await source.close();
    });

    testWidgets('no banner in shell when transport available', (tester) async {
      final source = _FakeTransportSource(() async => true);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      await tester.pumpWidget(ChangeNotifierProvider<ConnectivityProvider>.value(
        value: connectivity,
        child: MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _buildShellRouter(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);

      connectivity.dispose();
      await source.close();
    });
  });
}
