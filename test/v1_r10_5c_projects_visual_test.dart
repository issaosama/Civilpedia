import 'dart:async';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/core/widgets/civil_app_bar.dart';
import 'package:civilpedia/core/widgets/civil_surface_card.dart';
import 'package:civilpedia/features/projects/domain/entities/project.dart';
import 'package:civilpedia/features/projects/domain/project_repository.dart';
import 'package:civilpedia/features/projects/presentation/project_list_screen.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/checklist_screen.dart';
import 'package:civilpedia/features/tools/presentation/widgets/project_picker_dialog.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

typedef _LoadPlan = Future<List<Project>> Function();

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository(this.loadPlans);

  final List<_LoadPlan> loadPlans;
  int loadCount = 0;

  @override
  Future<List<Project>> loadProjects() {
    final index = loadCount++;
    return loadPlans[index < loadPlans.length ? index : loadPlans.length - 1]();
  }

  @override
  Future<Project> createProject(String name) =>
      throw UnimplementedError('Not used by this visual test.');

  @override
  Future<void> updateProject(Project project) async {}

  @override
  Future<void> archiveProject(String projectId) async {}

  @override
  Future<void> restoreProject(String projectId) async {}

  @override
  Future<void> deleteProject(String projectId) async {}

  @override
  Future<void> replaceAll(List<Project> projects) async {}
}

class _PickerLauncher extends StatefulWidget {
  const _PickerLauncher({required this.repository});

  final ProjectRepository repository;

  @override
  State<_PickerLauncher> createState() => _PickerLauncherState();
}

class _PickerLauncherState extends State<_PickerLauncher> {
  Project? selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FilledButton(
            key: const Key('open-picker'),
            onPressed: () async {
              final result = await showDialog<Project>(
                context: context,
                builder: (_) =>
                    ProjectPickerDialog(repository: widget.repository),
              );
              if (mounted) setState(() => selected = result);
            },
            child: const Text('open'),
          ),
          if (selected != null)
            Text(selected!.id, key: const Key('selected-project-id')),
        ],
      ),
    );
  }
}

Project _project(String id, String name, {bool archived = false}) {
  final createdAt = DateTime.utc(
    2026,
    9,
    int.parse(id.replaceAll(RegExp(r'\D'), '')),
  );
  return Project(
    id: id,
    name: name,
    createdAt: createdAt,
    updatedAt: createdAt,
    isArchived: archived,
  );
}

Future<void> _setSurface(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _app({required Widget home, ThemeData? theme, double textScale = 1}) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      locale: const Locale('ar'),
      theme: theme ?? AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
      home: home,
    ),
  );
}

void main() {
  group('V1-R10.5-C project list presentation', () {
    testWidgets(
      'uses canonical components, preserves ordering, RTL, and compact gutters',
      (tester) async {
        await _setSurface(tester);
        final second = _project('p2', 'المشروع الثاني');
        final first = _project('p1', 'المشروع الأول');
        final repository = _FakeProjectRepository([
          () async => [second, first],
        ]);

        await tester.pumpWidget(
          _app(home: ProjectListScreen(repository: repository)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CivilAppBar), findsOneWidget);
        expect(find.byType(CivilSurfaceCard), findsNWidgets(2));
        expect(
          tester.getTopLeft(find.text(second.name)).dy,
          lessThan(tester.getTopLeft(find.text(first.name)).dy),
        );
        expect(
          Directionality.of(tester.element(find.text(first.name))),
          TextDirection.rtl,
        );
        expect(
          tester
              .getSize(find.byKey(const Key('projects-responsive-content')))
              .width,
          358,
        );
      },
    );

    testWidgets('caps readable content width at 760dp', (tester) async {
      await _setSurface(tester, size: const Size(1000, 844));
      final repository = _FakeProjectRepository([() async => []]);

      await tester.pumpWidget(
        _app(home: ProjectListScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(find.byKey(const Key('projects-responsive-content')))
            .width,
        760,
      );
    });

    testWidgets('renders populated rows with light and dark theme roles', (
      tester,
    ) async {
      await _setSurface(tester);
      final project = _project('p1', 'مشروع الأدوار');

      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final repository = _FakeProjectRepository([
          () async => [project],
        ]);
        await tester.pumpWidget(
          _app(
            theme: theme,
            home: ProjectListScreen(repository: repository),
          ),
        );
        await tester.pumpAndSettle();

        final card = find.byKey(const ValueKey('project-card-p1'));
        final material = tester.widget<Material>(
          find.descendant(of: card, matching: find.byType(Material)).first,
        );
        expect(material.color, theme.colorScheme.surface);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
      'distinguishes loading, valid empty, initial failure, and retry',
      (tester) async {
        await _setSurface(tester);
        final firstLoad = Completer<List<Project>>();
        final repository = _FakeProjectRepository([
          () => firstLoad.future,
          () async => [],
        ]);

        await tester.pumpWidget(
          _app(home: ProjectListScreen(repository: repository)),
        );
        expect(find.byKey(const Key('projects-loading-state')), findsOneWidget);

        firstLoad.completeError(StateError('private repository detail'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('projects-failure-state')), findsOneWidget);
        expect(find.textContaining('private repository detail'), findsNothing);

        await tester.tap(find.byKey(const Key('projects-retry-action')));
        await tester.pumpAndSettle();
        expect(repository.loadCount, 2);
        expect(find.byKey(const Key('projects-empty-state')), findsOneWidget);
        expect(find.text(Ar.projectNoProjects), findsOneWidget);
      },
    );

    testWidgets('preserves known-good data when a later reload fails', (
      tester,
    ) async {
      await _setSurface(tester);
      final active = _project('p1', 'مشروع نشط');
      final archived = _project('p2', 'مشروع مؤرشف', archived: true);
      final repository = _FakeProjectRepository([
        () async => [active, archived],
        () async => throw StateError('reload failed'),
      ]);

      await tester.pumpWidget(
        _app(home: ProjectListScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(find.text(active.name), findsOneWidget);

      await tester.tap(find.text(Ar.projectArchived));
      await tester.pumpAndSettle();

      expect(find.text(archived.name), findsOneWidget);
      expect(find.byKey(const Key('projects-empty-state')), findsNothing);
      expect(find.byKey(const Key('projects-failure-state')), findsNothing);
    });

    testWidgets('switches between exact active and archived project sets', (
      tester,
    ) async {
      await _setSurface(tester);
      final active = _project('p1', 'مشروع نشط');
      final archived = _project('p2', 'مشروع مؤرشف', archived: true);
      final repository = _FakeProjectRepository([
        () async => [active, archived],
      ]);

      await tester.pumpWidget(
        _app(home: ProjectListScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      expect(find.text(active.name), findsOneWidget);
      expect(find.text(archived.name), findsNothing);

      await tester.tap(find.text(Ar.projectArchived));
      await tester.pumpAndSettle();
      expect(find.text(active.name), findsNothing);
      expect(find.text(archived.name), findsOneWidget);
    });

    testWidgets('opens ChecklistScreen with the exact selected Project', (
      tester,
    ) async {
      await _setSurface(tester);
      final project = _project('p1', 'مشروع مختار');
      final repository = _FakeProjectRepository([
        () async => [project],
      ]);

      await tester.pumpWidget(
        _app(home: ProjectListScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('project-card-p1')));
      await tester.pumpAndSettle();

      final checklist = tester.widget<ChecklistScreen>(
        find.byType(ChecklistScreen),
      );
      expect(checklist.project, same(project));
    });
  });

  group('V1-R10.5-C project picker presentation', () {
    testWidgets(
      'filters archived projects and preserves active ordering/identity',
      (tester) async {
        await _setSurface(tester);
        final first = _project('p1', 'المشروع الأول');
        final archived = _project('p2', 'مؤرشف', archived: true);
        final second = _project('p3', 'المشروع الثاني');
        final repository = _FakeProjectRepository([
          () async => [first, archived, second],
        ]);

        await tester.pumpWidget(
          _app(home: _PickerLauncher(repository: repository)),
        );
        await tester.tap(find.byKey(const Key('open-picker')));
        await tester.pumpAndSettle();

        expect(find.text(archived.name), findsNothing);
        expect(
          tester.getTopLeft(find.text(first.name)).dy,
          lessThan(tester.getTopLeft(find.text(second.name)).dy),
        );

        await tester.tap(
          find.byKey(const ValueKey('project-picker-option-p3')),
        );
        await tester.pumpAndSettle();
        final state = tester.state<_PickerLauncherState>(
          find.byType(_PickerLauncher),
        );
        expect(state.selected, same(second));
      },
    );

    testWidgets(
      'shows loading, retryable safe failure, retry, and empty states',
      (tester) async {
        await _setSurface(tester);
        final firstLoad = Completer<List<Project>>();
        final repository = _FakeProjectRepository([
          () => firstLoad.future,
          () async => [],
        ]);

        await tester.pumpWidget(
          _app(home: _PickerLauncher(repository: repository)),
        );
        await tester.tap(find.byKey(const Key('open-picker')));
        await tester.pump();
        expect(
          find.byKey(const Key('project-picker-loading-state')),
          findsOneWidget,
        );

        firstLoad.completeError(StateError('raw exception'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('project-picker-failure-state')),
          findsOneWidget,
        );
        expect(find.textContaining('raw exception'), findsNothing);

        await tester.tap(find.byKey(const Key('project-picker-retry-action')));
        await tester.pumpAndSettle();
        expect(repository.loadCount, 2);
        expect(
          find.byKey(const Key('project-picker-empty-state')),
          findsOneWidget,
        );
        expect(find.text(Ar.projectNoActiveProjects), findsOneWidget);
      },
    );

    for (final scale in [1.0, 1.3]) {
      testWidgets('long Arabic names fit 390x844 at text scale $scale', (
        tester,
      ) async {
        await _setSurface(tester);
        final longName =
            'مشروع مجمع المباني الهندسية والخدمات '
            'المتكاملة ذو الاسم الطويل لاختبار الالتفاف';
        final repository = _FakeProjectRepository([
          () async => [_project('p1', longName)],
        ]);

        await tester.pumpWidget(
          _app(
            textScale: scale,
            home: _PickerLauncher(repository: repository),
          ),
        );
        await tester.tap(find.byKey(const Key('open-picker')));
        await tester.pumpAndSettle();

        expect(find.text(longName), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
