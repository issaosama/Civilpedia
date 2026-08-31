import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/core/navigation/shell_content_insets.dart';
import 'package:civilpedia/features/tools/presentation/screens/tools_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';

/// Exercises that migrated shell screens correctly consume the shared
/// shell-safe bottom clearance under an injected obstruction much larger than
/// normal spacing, proving they rely on the semantic contract rather than on
/// today's 86px layout. The exact numeric behavior of shellSafeBottomPadding
/// (MAX, breathing-once, dual-host fallback) is covered comprehensively in
/// shell_content_insets_test.dart.
void main() {
  const injectedObstruction = 137.0;
  const breathing = 16.0; // AppSpacing.lg
  const expectedShell = injectedObstruction + breathing; // 153

  group('AppShell source of truth', () {
    test('shellBottomObstruction = nav height + bottom margin (86)', () {
      // The canonical metrics live only on AppShell; the derived value is
      // asserted here to keep the single source of truth authoritative.
      expect(AppShell.shellBottomObstruction, 86);
    });
  });

  group('ToolsScreen', () {
    testWidgets('final SliverGrid bottoms clear injected shell obstruction',
        (tester) async {
      await tester.pumpWidget(
        ShellContentInsets(
          bottomObstruction: injectedObstruction,
          child: MaterialApp(
            home: ChangeNotifierProvider(
              create: (_) => LanguageProvider(),
              child: const ToolsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sliverPaddings = tester
          .widgetList<SliverPadding>(find.byType(SliverPadding))
          .map((w) =>
              w.padding.resolve(TextDirection.ltr).bottom)
          .toList();
      // The tools grid SliverPadding must use the shell-safe value (153),
      // not the previous fixed AppSpacing.huge (40).
      expect(sliverPaddings, contains(expectedShell));
    });
  });
}
