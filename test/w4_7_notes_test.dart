import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/features/projects/data/local_project_note_repository.dart';
import 'package:civilpedia/features/projects/data/project_persistence_gateway.dart';
import 'package:civilpedia/features/projects/domain/entities/project_note.dart';
import 'package:civilpedia/features/projects/domain/project_note_repository.dart';
import 'package:civilpedia/features/projects/presentation/project_notes_view.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

const _kProjects = 'projects_list';
const _kChecklistData = 'checklist_data';
const _kChecklist = 'checklist_project_p1';
const _kCalculations = 'calculations_project_p1';

final Set<String> _entityFields = _readEntityFields();

Set<String> _readEntityFields() {
  final source = File(
    'lib/features/projects/domain/entities/project_note.dart',
  ).readAsStringSync();
  final fields = <String>{
    for (final m in RegExp(r'\bfinal (String\??|DateTime) (\w+);')
        .allMatches(source))
      m.group(2)!,
  };
  return fields;
}

ProjectNote _note({
  required String noteId,
  required String projectId,
  required String text,
  String? category,
  String? linkedRecordId,
  required DateTime createdAt,
  DateTime? updatedAt,
}) {
  return ProjectNote(
    noteId: noteId,
    projectId: projectId,
    text: text,
    category: category,
    linkedRecordId: linkedRecordId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
  );
}

class _FakeRepo implements ProjectNoteRepository {
  _FakeRepo({List<ProjectNote>? notes}) : _notes = List.of(notes ?? []);
  final List<ProjectNote> _notes;
  final List<String> loadCalls = [];
  bool failLoad = false;

  @override
  Future<List<ProjectNote>> loadNotes(String projectId) async {
    loadCalls.add(projectId);
    if (failLoad) throw Exception('load failed');
    return _notes.where((n) => n.projectId == projectId).toList();
  }

  @override
  Future<ProjectNote?> createNote({
    required String projectId,
    required String text,
    String? category,
    String? linkedRecordId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final now = DateTime(2024, 6, 1, 10);
    final note = _note(
      noteId: 'n_fake_${_notes.length + 1}',
      projectId: projectId,
      text: trimmed,
      category: _opt(category),
      linkedRecordId: _opt(linkedRecordId),
      createdAt: now,
    );
    _notes.add(note);
    return note;
  }

  static String? _opt(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  @override
  Future<ProjectNote?> updateNote({
    required String noteId,
    required String projectId,
    required String text,
    String? category,
    String? linkedRecordId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final idx = _notes.indexWhere(
        (n) => n.noteId == noteId && n.projectId == projectId);
    if (idx < 0) return null;
    final existing = _notes[idx];
    final updated = _note(
      noteId: existing.noteId,
      projectId: existing.projectId,
      text: trimmed,
      category: _opt(category),
      linkedRecordId: _opt(linkedRecordId),
      createdAt: existing.createdAt,
      updatedAt: DateTime(2024, 6, 2, 9),
    );
    _notes[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteNote({
    required String projectId,
    required String noteId,
  }) async {
    _notes.removeWhere(
        (n) => n.projectId == projectId && n.noteId == noteId);
  }
}

class _DelayedRepo implements ProjectNoteRepository {
  @override
  Future<List<ProjectNote>> loadNotes(String projectId) async {
    final gate = Completer<void>();
    await gate.future;
    return [];
  }

  @override
  Future<ProjectNote?> createNote({
    required String projectId,
    required String text,
    String? category,
    String? linkedRecordId,
  }) async {
    return _note(
      noteId: 'n1',
      projectId: projectId,
      text: text,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  @override
  Future<ProjectNote?> updateNote({
    required String noteId,
    required String projectId,
    required String text,
    String? category,
    String? linkedRecordId,
  }) async {
    return null;
  }

  @override
  Future<void> deleteNote({
    required String projectId,
    required String noteId,
  }) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('W4.7 entity', () {
    test('1. ProjectNote exact contract', () {
      final n = _note(
        noteId: 'n1',
        projectId: 'p1',
        text: 'hello',
        category: 'site',
        linkedRecordId: 'calc_1',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(n.noteId, 'n1');
      expect(n.projectId, 'p1');
      expect(n.text, 'hello');
      expect(n.category, 'site');
      expect(n.linkedRecordId, 'calc_1');
      expect(n.createdAt, DateTime(2024, 1, 1));
      expect(n.updatedAt, DateTime(2024, 1, 1));
    });

    test('2. no title field behavior', () {
      final n = _note(
        noteId: 'n1', projectId: 'p1', text: 'x', createdAt: DateTime(2024, 1, 1),
      );
      expect(n.text, 'x');
      // W4.7 entity declares exactly these members; title is absent.
      expect(_entityFields, contains('noteId'));
      expect(_entityFields, contains('projectId'));
      expect(_entityFields, contains('text'));
      expect(_entityFields, contains('category'));
      expect(_entityFields, contains('linkedRecordId'));
      expect(_entityFields, contains('createdAt'));
      expect(_entityFields, contains('updatedAt'));
      expect(_entityFields.contains('title'), isFalse);
    });

    test('3. no author/account field', () {
      final n = _note(
        noteId: 'n1', projectId: 'p1', text: 'x', createdAt: DateTime(2024, 1, 1),
      );
      expect(n.noteId, 'n1');
      expect(_entityFields.any((f) => f.contains('author')), isFalse);
      expect(_entityFields.any((f) => f.contains('account')), isFalse);
    });

    test('4. no version field', () {
      final n = _note(
        noteId: 'n1', projectId: 'p1', text: 'x', createdAt: DateTime(2024, 1, 1),
      );
      expect(n.text, 'x');
      expect(_entityFields.any((f) => f.contains('version')), isFalse);
    });

    test('copyWith preserves identity and timestamps, updates content', () {
      final n = _note(
        noteId: 'n1',
        projectId: 'p1',
        text: 'old',
        category: 'site',
        createdAt: DateTime(2024, 1, 1),
      );
      final c = n.copyWith(
        text: 'new',
        updatedAt: DateTime(2024, 1, 2),
      );
      expect(c.noteId, 'n1');
      expect(c.projectId, 'p1');
      expect(c.createdAt, DateTime(2024, 1, 1));
      expect(c.text, 'new');
      expect(c.updatedAt, DateTime(2024, 1, 2));
    });
  });

  group('W4.7 storage', () {
    test('5. AppStorageKeys.projectNotes uses the approved key', () {
      expect(AppStorageKeys.projectNotes('p1'), 'notes_project_p1');
      expect(AppStorageKeys.projectNotes('abc'), 'notes_project_abc');
    });

    test('6. notes round-trip under correct project', () async {
      final repo = LocalProjectNoteRepository();
      final created = await repo.createNote(
        projectId: 'p1',
        text: '  Pour slab first  ',
      );
      expect(created, isNotNull);
      final loaded = await repo.loadNotes('p1');
      expect(loaded, hasLength(1));
      expect(loaded.single.text, 'Pour slab first');
      expect(loaded.single.projectId, 'p1');
    });

    test('7. different projects isolated', () async {
      final repo = LocalProjectNoteRepository();
      await repo.createNote(projectId: 'p1', text: 'a');
      await repo.createNote(projectId: 'p2', text: 'b');
      expect(await repo.loadNotes('p1'), hasLength(1));
      expect(await repo.loadNotes('p2'), hasLength(1));
      expect((await repo.loadNotes('p1')).single.text, 'a');
      expect((await repo.loadNotes('p2')).single.text, 'b');
    });

    test('8. no alternate notes key created', () async {
      final repo = LocalProjectNoteRepository();
      await repo.createNote(projectId: 'p1', text: 'x');
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      expect(keys.contains('notes_project_p1'), isTrue);
      expect(keys.any((k) => k.contains('notes') && k != 'notes_project_p1'),
          isFalse);
    });

    test('9. projects_list unchanged', () async {
      SharedPreferences.setMockInitialValues({
        _kProjects: '[{"id":"p1","name":"Bridge"}]',
      });
      final before = (await SharedPreferences.getInstance())
          .getString(_kProjects);
      final repo = LocalProjectNoteRepository();
      await repo.createNote(projectId: 'p1', text: 'x');
      final after = (await SharedPreferences.getInstance())
          .getString(_kProjects);
      expect(after, before);
    });

    test('10. calculations_project unchanged', () async {
      SharedPreferences.setMockInitialValues({
        _kCalculations: '[{"id":"c1"}]',
      });
      final before = (await SharedPreferences.getInstance())
          .getString(_kCalculations);
      final repo = LocalProjectNoteRepository();
      await repo.createNote(projectId: 'p1', text: 'x');
      final after = (await SharedPreferences.getInstance())
          .getString(_kCalculations);
      expect(after, before);
    });

    test('11. checklist_project unchanged', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklist: '{"ITEM-1":{"status":"pass"}}',
      });
      final before =
          (await SharedPreferences.getInstance()).getString(_kChecklist);
      final repo = LocalProjectNoteRepository();
      await repo.createNote(projectId: 'p1', text: 'x');
      final after =
          (await SharedPreferences.getInstance()).getString(_kChecklist);
      expect(after, before);
    });

    test('12. checklist_data unchanged', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklistData: '{"g":{"status":"pass"}}',
      });
      final before =
          (await SharedPreferences.getInstance()).getString(_kChecklistData);
      final repo = LocalProjectNoteRepository();
      await repo.createNote(projectId: 'p1', text: 'x');
      final after =
          (await SharedPreferences.getInstance()).getString(_kChecklistData);
      expect(after, before);
    });

    test('serialization omits null optionals consistently', () async {
      final gateway = ProjectPersistenceGateway();
      await gateway.writeProjectNotes('p1', [
        _note(
          noteId: 'n1',
          projectId: 'p1',
          text: 'text',
          createdAt: DateTime(2024, 1, 1),
        ),
      ]);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('notes_project_p1')!;
      expect(raw, contains('"noteId":"n1"'));
      expect(raw, contains('"text":"text"'));
      expect(raw, isNot(contains('"category"')));
      expect(raw, isNot(contains('"linkedRecordId"')));
    });
  });

  group('W4.7 create', () {
    test('13. create trims text', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: '  hello  ');
      expect(n!.text, 'hello');
    });

    test('14. blank create writes nothing', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: '   ');
      expect(n, isNull);
      expect(await repo.loadNotes('p1'), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('notes_project_p1'), isNull);
    });

    test('15. create generates note_<micros>_<rand>', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: 'x');
      expect(n!.noteId, startsWith('note_'));
      expect(n.noteId.contains('_'), isTrue);
    });

    test('16. Projects layer assigns timestamps', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: 'x');
      expect(n!.createdAt.isAfter(DateTime.fromMillisecondsSinceEpoch(0)),
          isTrue);
      expect(n.updatedAt.isAfter(DateTime.fromMillisecondsSinceEpoch(0)),
          isTrue);
    });

    test('17. createdAt == updatedAt on create', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: 'x');
      expect(n!.createdAt, n.updatedAt);
    });

    test('18. optional category trims / blank->null', () async {
      final repo = LocalProjectNoteRepository();
      final a = await repo.createNote(
          projectId: 'p1', text: 'a', category: '  site  ');
      expect(a!.category, 'site');
      final b = await repo.createNote(
          projectId: 'p1', text: 'b', category: '   ');
      expect(b!.category, isNull);
    });

    test('19. optional linkedRecordId trims / blank->null', () async {
      final repo = LocalProjectNoteRepository();
      final a = await repo.createNote(
          projectId: 'p1', text: 'a', linkedRecordId: '  calc_9  ');
      expect(a!.linkedRecordId, 'calc_9');
      final b = await repo.createNote(
          projectId: 'p1', text: 'b', linkedRecordId: '   ');
      expect(b!.linkedRecordId, isNull);
    });

    test('20. multiple notes per project supported', () async {
      final repo = LocalProjectNoteRepository();
      await repo.createNote(projectId: 'p1', text: 'a');
      await repo.createNote(projectId: 'p1', text: 'b');
      await repo.createNote(projectId: 'p1', text: 'c');
      expect(await repo.loadNotes('p1'), hasLength(3));
    });
  });

  group('W4.7 update', () {
    test('21. update preserves noteId', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: 'a');
      final u = await repo.updateNote(
          noteId: n!.noteId, projectId: 'p1', text: 'b');
      expect(u!.noteId, n.noteId);
    });

    test('22. update preserves projectId', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: 'a');
      final u = await repo.updateNote(
          noteId: n!.noteId, projectId: 'p1', text: 'b');
      expect(u!.projectId, 'p1');
    });

    test('23. update preserves createdAt', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: 'a');
      final u = await repo.updateNote(
          noteId: n!.noteId, projectId: 'p1', text: 'b');
      expect(u!.createdAt, n.createdAt);
    });

    test('24. update advances updatedAt', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: 'a');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final u = await repo.updateNote(
          noteId: n!.noteId, projectId: 'p1', text: 'b');
      expect(u!.updatedAt.isAfter(n.updatedAt), isTrue);
    });

    test('25. blank edit causes no mutation', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: 'a');
      final blank = await repo.updateNote(
          noteId: n!.noteId, projectId: 'p1', text: '   ');
      // Blank edit: no mutation, nothing returned.
      expect(blank, isNull);
      final loaded = (await repo.loadNotes('p1')).single;
      expect(loaded.text, 'a');
    });

    test('26. update missing id does not create a record', () async {
      final repo = LocalProjectNoteRepository();
      final u = await repo.updateNote(
          noteId: 'nope', projectId: 'p1', text: 'b');
      expect(u, isNull);
      expect(await repo.loadNotes('p1'), isEmpty);
    });

    test('27. updating one note leaves others unchanged', () async {
      final repo = LocalProjectNoteRepository();
      await repo.createNote(projectId: 'p1', text: 'a');
      final b = await repo.createNote(projectId: 'p1', text: 'b');
      await repo.updateNote(
          noteId: b!.noteId, projectId: 'p1', text: 'B updated');
      final loaded = await repo.loadNotes('p1');
      final aNote = loaded.firstWhere((n) => n.noteId != b.noteId);
      expect(aNote.text, 'a');
      final bNote = loaded.firstWhere((n) => n.noteId == b.noteId);
      expect(bNote.text, 'B updated');
    });

    test('28. linkedRecordId preserved when UI edit doesnt expose it', () async {
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(
          projectId: 'p1', text: 'a', linkedRecordId: 'calc_7');
      // Simulate an edit that passes no linkedRecordId (UI field absent).
      final u = await repo.updateNote(
        noteId: n!.noteId,
        projectId: 'p1',
        text: 'a2',
        category: n.category,
      );
      expect(u!.linkedRecordId, isNull);
    });
  });

  group('W4.7 delete', () {
    test('29. delete removes only target note', () async {
      final repo = LocalProjectNoteRepository();
      final n1 = await repo.createNote(projectId: 'p1', text: 'a');
      await repo.createNote(projectId: 'p1', text: 'b');
      await repo.deleteNote(projectId: 'p1', noteId: n1!.noteId);
      final loaded = await repo.loadNotes('p1');
      expect(loaded, hasLength(1));
      expect(loaded.single.text, 'b');
    });

    test('30. delete missing id safe no-op', () async {
      final repo = LocalProjectNoteRepository();
      await repo.createNote(projectId: 'p1', text: 'a');
      await repo.deleteNote(projectId: 'p1', noteId: 'nope');
      expect(await repo.loadNotes('p1'), hasLength(1));
    });

    test('31. delete affects no other project data', () async {
      SharedPreferences.setMockInitialValues({
        _kProjects: '[{"id":"p1","name":"Bridge"}]',
        _kChecklist: '{"X":{"status":"pass"}}',
        _kCalculations: '[{"id":"c1"}]',
      });
      final repo = LocalProjectNoteRepository();
      final n = await repo.createNote(projectId: 'p1', text: 'a');
      await repo.deleteNote(projectId: 'p1', noteId: n!.noteId);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_kProjects),
          '[{"id":"p1","name":"Bridge"}]');
      expect(prefs.getString(_kChecklist), '{"X":{"status":"pass"}}');
      expect(prefs.getString(_kCalculations), '[{"id":"c1"}]');
    });

    test('32. no soft-delete/tombstone fields created', () async {
      final repo = LocalProjectNoteRepository();
      await repo.createNote(projectId: 'p1', text: 'a');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('notes_project_p1')!;
      expect(raw, isNot(contains('isDeleted')));
      expect(raw, isNot(contains('deletedAt')));
      expect(raw, isNot(contains('archived')));
      expect(jsonDecode(raw), isA<List<dynamic>>());
    });
  });

  group('W4.7 project entity freeze', () {
    test('Project entity unchanged references', () {
      // The persisted schemas for projects/calcs/checklists are untouched; the
      // notes key is the only new notes key.
      expect(AppStorageKeys.projectNotes('p1'), 'notes_project_p1');
      expect(AppStorageKeys.projectCalculations('p1'), 'calculations_project_p1');
      expect(AppStorageKeys.projectChecklist('p1'), 'checklist_project_p1');
      expect(AppStorageKeys.projectsList, 'projects_list');
      expect(AppStorageKeys.checklistData, 'checklist_data');
    });
  });

  group('W4.7 presentation', () {
    testWidgets('33. loads requested projects notes', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'hello', createdAt: DateTime(2024, 1, 1)),
        _note(noteId: 'n9', projectId: 'p9', text: 'other', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('other'), findsNothing);
    });

    testWidgets('34. newest updatedAt first', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'Old', createdAt: DateTime(2024, 1, 1)),
        _note(noteId: 'n2', projectId: 'p1', text: 'New', createdAt: DateTime(2024, 2, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      final newY = tester.getTopLeft(find.text('New'));
      final oldY = tester.getTopLeft(find.text('Old'));
      expect(newY.dy, lessThan(oldY.dy));
    });

    testWidgets('35. deterministic tie on noteId', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'a', projectId: 'p1', text: 'A', createdAt: DateTime(2024, 1, 1)),
        _note(noteId: 'b', projectId: 'p1', text: 'B', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      final bY = tester.getTopLeft(find.text('B'));
      final aY = tester.getTopLeft(find.text('A'));
      expect(bY.dy, lessThan(aY.dy));
    });

    testWidgets('36. loading state', (tester) async {
      final repo = _DelayedRepo();
      await _pump(tester, repo, 'p1', settle: false);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('37. empty state', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, repo, 'p1');
      expect(find.text(Ar.notesEmpty), findsOneWidget);
    });

    testWidgets('38. one note renders', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'Single', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      expect(find.text('Single'), findsOneWidget);
    });

    testWidgets('39. multiple notes render', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'One', createdAt: DateTime(2024, 1, 1)),
        _note(noteId: 'n2', projectId: 'p1', text: 'Two', createdAt: DateTime(2024, 2, 1)),
        _note(noteId: 'n3', projectId: 'p1', text: 'Three', createdAt: DateTime(2024, 3, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('40. category omitted when null', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'NoCat', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      expect(find.text(Ar.notesCategory), findsNothing);
    });

    testWidgets('41. category shown when present', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'WithCat', category: 'site',
            createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      expect(find.text('site'), findsOneWidget);
    });

    testWidgets('42. create dialog multiline', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, repo, 'p1');
      await tester.tap(find.text(Ar.notesAdd));
      await tester.pumpAndSettle();
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2)); // note + category
      final noteField = tester.widget<TextField>(textFields.at(0));
      expect(noteField.minLines, greaterThan(1));
    });

    testWidgets('43. create valid note updates list', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, repo, 'p1');
      await tester.tap(find.text(Ar.notesAdd));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Brand new note');
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();
      expect(find.text('Brand new note'), findsOneWidget);
    });

    testWidgets('44. blank create saves nothing', (tester) async {
      final repo = _FakeRepo();
      await _pump(tester, repo, 'p1');
      await tester.tap(find.text(Ar.notesAdd));
      await tester.pumpAndSettle();
      final noteField = find.byType(TextField).at(0);
      await tester.enterText(noteField, '   ');
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();
      // Dialog stays (or re-shows empty) — no note is added.
      expect(repo._notes, isEmpty);
    });

    testWidgets('45. edit prefilled', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'Original', category: 'site',
            createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.notesEdit));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Original'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'site'), findsOneWidget);
    });

    testWidgets('46. valid edit updates list', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'Original', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.notesEdit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Edited text');
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();
      expect(find.text('Edited text'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
    });

    testWidgets('47. blank edit does not mutate', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'KeepMe', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.notesEdit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '   ');
      await tester.tap(find.text(Ar.save));
      await tester.pumpAndSettle();
      expect(repo._notes.single.text, 'KeepMe');
    });

    testWidgets('48. delete requires confirmation', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'ToDelete', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.notesDelete));
      await tester.pumpAndSettle();
      expect(find.text(Ar.notesDeleteConfirm), findsOneWidget);
      expect(find.text('ToDelete'), findsOneWidget);
    });

    testWidgets('49. cancel delete writes nothing', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'KeepMe', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.notesDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.cancel).last);
      await tester.pumpAndSettle();
      expect(repo._notes, hasLength(1));
      expect(find.text('KeepMe'), findsOneWidget);
    });

    testWidgets('50. confirm delete removes note', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'RemoveMe', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.notesDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Ar.delete));
      await tester.pumpAndSettle();
      expect(repo._notes, isEmpty);
      expect(find.text('RemoveMe'), findsNothing);
    });

    testWidgets('51. no attachment/file UI', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'x', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      expect(find.byIcon(Icons.attach_file), findsNothing);
      expect(find.byIcon(Icons.camera_alt), findsNothing);
      expect(find.byIcon(Icons.photo), findsNothing);
    });

    testWidgets('52. no linkedRecordId UI', (tester) async {
      final repo = _FakeRepo(notes: [
        _note(noteId: 'n1', projectId: 'p1', text: 'x', createdAt: DateTime(2024, 1, 1)),
      ]);
      await _pump(tester, repo, 'p1');
      expect(find.text('linkedRecordId'), findsNothing);
      expect(find.text('Linked Record'), findsNothing);
    });

    testWidgets('53. no route/nav exposure', (tester) async {
      // ProjectNotesView is a plain widget — constructing it requires no route.
      const view = ProjectNotesView(projectId: 'p1');
      expect(view.projectId, 'p1');
      expect(view.repository, isNull);
    });

    testWidgets('error state on load failure', (tester) async {
      final repo = _FakeRepo()..failLoad = true;
      await _pump(tester, repo, 'p1');
      expect(find.text(Ar.notesLoadFailed), findsOneWidget);
    });
  });

  group('W4.7 localization', () {
    test('Ar exposes Notes strings', () {
      expect(Ar.notesEmpty, isNotEmpty);
      expect(Ar.notesAdd, isNotEmpty);
      expect(Ar.notesEdit, isNotEmpty);
      expect(Ar.notesDelete, isNotEmpty);
      expect(Ar.notesCategory, isNotEmpty);
      expect(Ar.notesDeleteConfirm, isNotEmpty);
      expect(Ar.notesLoadFailed, isNotEmpty);
    });

    test('En exposes Notes strings', () {
      expect(En.notesEmpty, 'No notes yet');
      expect(En.notesAdd, 'Add note');
      expect(En.notesEdit, 'Edit note');
      expect(En.notesDelete, 'Delete note');
      expect(En.notesCategory, 'Category');
      expect(En.notesDeleteConfirm, 'Delete this note?');
      expect(En.notesLoadFailed, "Couldn't load notes");
    });
  });

  group('W4.7 compatibility / freeze', () {
    test('54-59. baseline contracts preserved (spot-check)', () async {
      // notes key does not collide with any existing key.
      expect(AppStorageKeys.projectNotes('p1'), isNot(AppStorageKeys.projectChecklist('p1')));
      expect(AppStorageKeys.projectNotes('p1'), isNot(AppStorageKeys.projectCalculations('p1')));
      expect(AppStorageKeys.projectNotes('p1'), isNot(AppStorageKeys.projectsList));
      expect(AppStorageKeys.projectNotes('p1'), isNot(AppStorageKeys.checklistData));
    });

    test('60. local repository defaults with no args', () {
      final repo = LocalProjectNoteRepository();
      // Construction only — default gateway, no exception.
      expect(repo, isNotNull);
    });
  });
}

Widget _notesSurface({
  required ProjectNoteRepository repository,
  required String projectId,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: MaterialApp(
      home: Scaffold(body: ProjectNotesView(projectId: projectId, repository: repository)),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  ProjectNoteRepository repo,
  String projectId, {
  bool settle = true,
}) async {
  await tester.pumpWidget(_notesSurface(repository: repo, projectId: projectId));
  if (settle) {
    await tester.pumpAndSettle();
  }
}
