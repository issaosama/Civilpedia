import 'package:civilpedia/core/navigation/shell_content_insets.dart';
import 'package:civilpedia/core/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exposes the resolved [shellSafeBottomPadding] value as text for assertion.
class _BottomExposer extends StatelessWidget {
  final double breathing;
  const _BottomExposer({this.breathing = AppSpacing.lg});
  @override
  Widget build(BuildContext context) {
    return Text(
      shellSafeBottomPadding(
        context,
        breathingRoom: breathing,
      ).toString(),
    );
  }
}

/// Builds a widget tree with optional device bottom inset and shell scope.
/// [shellObstruction] being non-null wraps the tree in `ShellContentInsets`.
Widget _root({
  required Widget Function(BuildContext) child,
  double? shellObstruction,
  double deviceBottomInset = 0,
}) {
  Widget probe = Builder(
    builder: (context) => child(context),
  );
  Widget result = MaterialApp(home: Scaffold(body: probe));
  if (deviceBottomInset > 0) {
    result = MediaQuery(
      data: MediaQueryData(
        size: const Size(400, 800),
        padding: EdgeInsets.only(bottom: deviceBottomInset),
      ),
      child: result,
    );
  }
  if (shellObstruction != null) {
    result = ShellContentInsets(
      bottomObstruction: shellObstruction,
      child: result,
    );
  }
  return result;
}

void main() {
  group('ShellContentInsets', () {
    testWidgets('publishes provided bottomObstruction to descendants',
        (tester) async {
      await tester.pumpWidget(
        _root(
          shellObstruction: 137,
          child: (_) => const _BottomExposer(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('153.0'), findsOneWidget); // 137 + 16 breathing
    });

    testWidgets('maybeOf returns null outside AppShell scope', (tester) async {
      await tester.pumpWidget(_root(child: (_) => const SizedBox()));
      await tester.pumpAndSettle();
      expect(ShellContentInsets.maybeOf(tester.element(find.byType(SizedBox))),
          isNull);
    });

    testWidgets('helper outside shell uses device bottom inset fallback',
        (tester) async {
      await tester.pumpWidget(
        _root(
          deviceBottomInset: 34,
          child: (_) => const _BottomExposer(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('50.0'), findsOneWidget); // max(0, 34) + 16
    });

    testWidgets('helper uses MAX(shell obstruction, device inset), NOT sum',
        (tester) async {
      await tester.pumpWidget(
        _root(
          shellObstruction: 137,
          deviceBottomInset: 34,
          child: (_) => const _BottomExposer(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('153.0'), findsOneWidget); // max(137,34) + 16
      expect(find.text('187.0'), findsNothing); // not 137+34+16
    });

    testWidgets('breathingRoom is added exactly once', (tester) async {
      await tester.pumpWidget(
        _root(
          shellObstruction: 100,
          child: (_) => const _BottomExposer(breathing: AppSpacing.xl),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('120.0'), findsOneWidget); // max(100,0) + 20
      expect(find.text('240.0'), findsNothing);
    });

    testWidgets('arbitrary injected shell obstruction (137px) honored',
        (tester) async {
      await tester.pumpWidget(
        _root(
          shellObstruction: 137,
          child: (_) => const _BottomExposer(breathing: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('137.0'), findsOneWidget);
    });
  });

  group('shellSafeBottomPadding root fallback', () {
    testWidgets('no shell and no inset -> just breathing room', (tester) async {
      await tester.pumpWidget(
        _root(child: (_) => const _BottomExposer(breathing: AppSpacing.sm)),
      );
      await tester.pumpAndSettle();
      expect(find.text('8.0'), findsOneWidget);
    });
  });
}
