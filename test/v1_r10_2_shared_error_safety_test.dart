import 'package:civilpedia/core/widgets/async_value_widget.dart';
import 'package:civilpedia/core/widgets/state_widgets.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hostileMessages = <String>[
    'PostgrestException(message: private table details)',
    'SQLSTATE 42501 permission denied for relation profiles',
    'SocketException: connection failed at internal-host:5432',
    'stack trace text\n#0 Repository.load (repository.dart:42)',
  ];

  group('AsyncValueWidget presentation safety', () {
    testWidgets('never renders arbitrary technical error values', (
      tester,
    ) async {
      for (final hostileMessage in hostileMessages) {
        await _pump(
          tester,
          locale: const Locale('en'),
          child: AsyncValueWidget(
            error: Exception(hostileMessage),
            onData: () => const Text('data'),
          ),
        );

        expect(find.text(En.errorOccurred), findsOneWidget);
        expect(find.textContaining(hostileMessage), findsNothing);
      }
    });

    testWidgets('custom error builder receives safe fallback, not raw error', (
      tester,
    ) async {
      const hostileMessage = 'SQLSTATE 42501 private policy detail';

      await _pump(
        tester,
        locale: const Locale('en'),
        child: AsyncValueWidget(
          error: hostileMessage,
          onError: (safeMessage, _) => Text(safeMessage),
          onData: () => const Text('data'),
        ),
      );

      expect(find.text(En.errorOccurred), findsOneWidget);
      expect(find.textContaining(hostileMessage), findsNothing);
    });

    testWidgets('explicit localized safe message remains supported', (
      tester,
    ) async {
      const safeMessage = 'Could not load saved items.';

      await _pump(
        tester,
        locale: const Locale('en'),
        child: AsyncValueWidget(
          error: 'SocketException(internal details)',
          safeMessage: safeMessage,
          onData: () => const Text('data'),
        ),
      );

      expect(find.text(safeMessage), findsOneWidget);
      expect(find.textContaining('SocketException'), findsNothing);
    });

    testWidgets('retry callback and localized label remain functional', (
      tester,
    ) async {
      var retries = 0;

      await _pump(
        tester,
        locale: const Locale('en'),
        child: AsyncValueWidget(
          error: 'backend message',
          onRetry: () => retries += 1,
          onData: () => const Text('data'),
        ),
      );

      await tester.tap(find.text(En.retry));
      await tester.pump();
      expect(retries, 1);
    });
  });

  group('shared state locale and safety', () {
    testWidgets('legacy ErrorStateWidget message cannot expose raw details', (
      tester,
    ) async {
      const hostileMessage = 'PostgrestException(SQLSTATE 42501)';

      await _pump(
        tester,
        locale: const Locale('en'),
        child: const ErrorStateWidget(message: hostileMessage),
      );

      expect(find.text(En.errorOccurred), findsOneWidget);
      expect(find.textContaining(hostileMessage), findsNothing);
    });

    testWidgets('Arabic and English default error copy follow active locale', (
      tester,
    ) async {
      await _pump(
        tester,
        locale: const Locale('ar'),
        child: const ErrorStateWidget(),
      );
      expect(find.text(Ar.errorOccurred), findsOneWidget);

      await _pump(
        tester,
        locale: const Locale('en'),
        child: const ErrorStateWidget(),
      );
      expect(find.text(En.errorOccurred), findsOneWidget);
      expect(find.text(Ar.errorOccurred), findsNothing);
    });

    testWidgets('EmptyStateWidget default follows active locale', (
      tester,
    ) async {
      await _pump(
        tester,
        locale: const Locale('ar'),
        child: const EmptyStateWidget(),
      );
      expect(find.text(Ar.emptyHere), findsOneWidget);

      await _pump(
        tester,
        locale: const Locale('en'),
        child: const EmptyStateWidget(),
      );
      expect(find.text(En.emptyHere), findsOneWidget);
      expect(find.text(Ar.emptyHere), findsNothing);
    });

    testWidgets('explicit safe error copy and retry remain supported', (
      tester,
    ) async {
      const safeMessage = 'Unable to load this section.';
      var retries = 0;

      await _pump(
        tester,
        locale: const Locale('en'),
        child: ErrorStateWidget(
          safeMessage: safeMessage,
          onRetry: () => retries += 1,
        ),
      );

      expect(find.text(safeMessage), findsOneWidget);
      await tester.tap(find.text(En.retry));
      await tester.pump();
      expect(retries, 1);
    });
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: child),
    ),
  );
}
