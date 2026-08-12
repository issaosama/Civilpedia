import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/project_list_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

Widget _projectListScreen() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: const MaterialApp(home: ProjectListScreen()),
  );
}

Future<void> _pumpWithProjects(
  WidgetTester tester,
  List<Map<String, dynamic>> projects,
) async {
  SharedPreferences.setMockInitialValues({
    'projects_list': jsonEncode(projects),
  });
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_projectListScreen());
  await tester.pump();
}

Map<String, dynamic> _projectJson({
  required String id,
  required String name,
  required DateTime createdAt,
}) {
  return {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': createdAt.toIso8601String(),
    'isArchived': false,
  };
}

void main() {
  group('ProjectListScreen Arabic localization', () {
    testWidgets('shows My Projects title and empty state in Arabic',
        (tester) async {
      await _pumpWithProjects(tester, []);

      expect(find.text(Ar.checklistMyProjects), findsOneWidget);
      expect(find.text(Ar.projectNoProjects), findsOneWidget);
      expect(find.text(Ar.projectCreateFirst), findsOneWidget);

      expect(find.text(En.checklistMyProjects), findsNothing);
      expect(find.text(En.projectNoProjects), findsNothing);
      expect(find.text(En.projectCreateFirst), findsNothing);
    });

    testWidgets('create-project dialog labels are Arabic', (tester) async {
      await _pumpWithProjects(tester, []);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text(Ar.projectCreateTitle), findsOneWidget);
      expect(find.text(Ar.projectNameHint), findsOneWidget);
      expect(find.text(Ar.cancel), findsOneWidget);
      expect(find.text(Ar.save), findsOneWidget);

      expect(find.text(En.projectCreateTitle), findsNothing);
      expect(find.text(En.projectNameHint), findsNothing);
    });

    testWidgets('creating a project works and shows Arabic created date',
        (tester) async {
      await _pumpWithProjects(tester, []);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'مشروع ١');
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();

      expect(find.text('مشروع ١'), findsOneWidget);
      expect(find.textContaining('تم الإنشاء في'), findsOneWidget);
      expect(find.text(Ar.projectNoProjects), findsNothing);
    });

    group('with an existing project', () {
      testWidgets('rename dialog labels are Arabic', (tester) async {
        await _pumpWithProjects(tester, [
          _projectJson(id: 'p1', name: 'مشروع تجريبي', createdAt: DateTime(2026)),
        ]);

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.projectRename));
        await tester.pump();

        expect(find.text(Ar.projectRenameTitle), findsOneWidget);
        expect(find.text(Ar.projectNameHint), findsOneWidget);
        expect(find.text(Ar.cancel), findsOneWidget);
        expect(find.text(Ar.save), findsOneWidget);

        expect(find.text(En.projectRenameTitle), findsNothing);
      });

      testWidgets('rename project works', (tester) async {
        await _pumpWithProjects(tester, [
          _projectJson(id: 'p1', name: 'اسم قديم', createdAt: DateTime(2026)),
        ]);

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.projectRename));
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'اسم جديد');
        await tester.tap(find.text(Ar.save));
        await tester.pumpAndSettle();

        expect(find.text('اسم جديد'), findsOneWidget);
        expect(find.text('اسم قديم'), findsNothing);
      });

      testWidgets('delete confirmation labels are Arabic', (tester) async {
        await _pumpWithProjects(tester, [
          _projectJson(id: 'p1', name: 'مشروع تجريبي', createdAt: DateTime(2026)),
        ]);

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.delete));
        await tester.pump();

        expect(find.text(Ar.projectDeleteTitle), findsOneWidget);
        expect(
          find.text(Ar.projectDeleteConfirm('مشروع تجريبي')),
          findsOneWidget,
        );
        expect(find.text(Ar.cancel), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(Ar.delete),
          ),
          findsOneWidget,
        );

        expect(find.text(En.projectDeleteTitle), findsNothing);
      });

      testWidgets('delete project works', (tester) async {
        await _pumpWithProjects(tester, [
          _projectJson(id: 'p1', name: 'مشروع تجريبي', createdAt: DateTime(2026)),
        ]);

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.delete));
        await tester.pump();
        await tester.tap(find.widgetWithText(TextButton, Ar.delete));
        await tester.pumpAndSettle();

        expect(find.text(Ar.projectNoProjects), findsOneWidget);
        expect(find.text('مشروع تجريبي'), findsNothing);
      });

      testWidgets('archive project works', (tester) async {
        await _pumpWithProjects(tester, [
          _projectJson(id: 'p1', name: 'مشروع تجريبي', createdAt: DateTime(2026)),
        ]);

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PopupMenuItem<String>, Ar.projectArchive));
        await tester.pumpAndSettle();

        expect(find.text(Ar.projectNoProjects), findsOneWidget);
        expect(find.text('مشروع تجريبي'), findsNothing);
      });

      testWidgets('menu actions are Arabic', (tester) async {
        await _pumpWithProjects(tester, [
          _projectJson(id: 'p1', name: 'مشروع تجريبي', createdAt: DateTime(2026)),
        ]);

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pump();

        expect(find.text(Ar.projectRename), findsOneWidget);
        expect(find.text(Ar.projectArchive), findsOneWidget);
        expect(find.text(Ar.delete), findsOneWidget);

        expect(find.text(En.projectRename), findsNothing);
        expect(find.text(En.projectArchive), findsNothing);
        expect(find.text('Delete'), findsNothing);
      });
    });
  });
}
