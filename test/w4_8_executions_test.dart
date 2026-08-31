import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civilpedia/core/storage/app_storage_keys.dart';
import 'package:civilpedia/features/projects/data/project_persistence_gateway.dart';
import 'package:civilpedia/features/projects/domain/entities/project_checklist_execution.dart';
import 'package:civilpedia/features/tools/data/checklist/checklist_local_data_source.dart';
import 'package:civilpedia/features/tools/data/checklist/local_checklist_repository.dart';
import 'package:civilpedia/features/tools/domain/checklist/checklist_template_contract.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_status.dart';

const _kProjects = 'projects_list';
const _kChecklistData = 'checklist_data';
const _kChecklist = 'checklist_project_p1';
const _kCalculations = 'calculations_project_p1';
const _kNotes = 'notes_project_p1';
const _kExecutions = 'checklist_executions_project_p1';

final Set<String> _execFields = _readExecFields();

Set<String> _readExecFields() {
  final source = File(
    'lib/features/projects/domain/entities/project_checklist_execution.dart',
  ).readAsStringSync();
  final fields = <String>{
    for (final m in RegExp(r'final\s+.*?\b(\w+);').allMatches(source))
      m.group(1)!,
  };
  return fields;
}

LocalChecklistRepository _projectRepo() =>
    LocalChecklistRepository(ChecklistLocalDataSource());

ProjectPersistenceGateway _gateway() => ProjectPersistenceGateway();

ProjectChecklistExecution _active(List<ProjectChecklistExecution> list) =>
    list.singleWhere((e) => e.completedAt == null);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('W4.8 STORAGE', () {
    test('1. projectChecklistExecutions key contract', () {
      expect(AppStorageKeys.projectChecklistExecutions('p1'),
          'checklist_executions_project_p1');
    });

    test('2. no key conflict with existing project keys', () {
      expect(AppStorageKeys.projectChecklistExecutions('p1'),
          isNot(AppStorageKeys.projectChecklist('p1')));
      expect(AppStorageKeys.projectChecklistExecutions('p1'),
          isNot(AppStorageKeys.checklistData));
      expect(AppStorageKeys.projectChecklistExecutions('p1'),
          isNot(AppStorageKeys.projectsList));
      expect(AppStorageKeys.projectChecklistExecutions('p1'),
          isNot(AppStorageKeys.projectCalculations('p1')));
      expect(AppStorageKeys.projectChecklistExecutions('p1'),
          isNot(AppStorageKeys.projectNotes('p1')));
    });

    test('3. executions isolated by project', () async {
      final repo = _projectRepo();
      await repo.saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await repo.saveProjectItemStatus('p2', 'ITEM-2', InspectionStatus.fail);
      final p1 = await _gateway().readProjectChecklistExecutions('p1');
      final p2 = await _gateway().readProjectChecklistExecutions('p2');
      expect(p1, hasLength(1));
      expect(p2, hasLength(1));
      expect(_active(p1).templateId, isNotNull);
      expect((await _gateway().readProjectChecklistExecutions('p1')).single
          .projectId, 'p1');
      expect((await _gateway().readProjectChecklistExecutions('p2')).single
          .projectId, 'p2');
    });

    test('4. legacy checklist_project_<id> remains alongside executions',
        () async {
      SharedPreferences.setMockInitialValues({});
      final repo = _projectRepo();
      await repo.saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_kExecutions), isNotNull);
      expect(prefs.getString(_kChecklist), isNotNull);
    });

    test('5. checklist_data unchanged', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklistData: '{"g":{"status":"pass"}}',
      });
      final before = (await SharedPreferences.getInstance())
          .getString(_kChecklistData);
      final repo = _projectRepo();
      await repo.saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final after =
          (await SharedPreferences.getInstance()).getString(_kChecklistData);
      expect(after, before);
    });

    test('6. projects_list unchanged', () async {
      SharedPreferences.setMockInitialValues({
        _kProjects: '[{"id":"p1","name":"Bridge"}]',
      });
      final before =
          (await SharedPreferences.getInstance()).getString(_kProjects);
      final repo = _projectRepo();
      await repo.saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final after =
          (await SharedPreferences.getInstance()).getString(_kProjects);
      expect(after, before);
    });

    test('7. calculations_project_<id> unchanged', () async {
      SharedPreferences.setMockInitialValues({
        _kCalculations: '[{"id":"c1"}]',
      });
      final before =
          (await SharedPreferences.getInstance()).getString(_kCalculations);
      final repo = _projectRepo();
      await repo.saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final after =
          (await SharedPreferences.getInstance()).getString(_kCalculations);
      expect(after, before);
    });

    test('8. notes_project_<id> unchanged', () async {
      SharedPreferences.setMockInitialValues({
        _kNotes: '[{"noteId":"n1"}]',
      });
      final before =
          (await SharedPreferences.getInstance()).getString(_kNotes);
      final repo = _projectRepo();
      await repo.saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final after =
          (await SharedPreferences.getInstance()).getString(_kNotes);
      expect(after, before);
    });
  });

  group('W4.8 ENTITY', () {
    test('9. exact ProjectChecklistExecution contract fields', () {
      expect(_execFields, containsAll([
        'executionId',
        'projectId',
        'templateId',
        'templateVersion',
        'executedItemSnapshot',
        'startedAt',
        'completedAt',
        'result',
        'notes',
      ]));
    });

    test('10. native templateId == site_inspection', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.templateId, ChecklistTemplateContract.templateId);
      expect(exec.templateId, 'site_inspection');
    });

    test('11. native templateVersion == 1', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.templateVersion, ChecklistTemplateContract.templateVersion);
      expect(exec.templateVersion, '1');
    });

    test('12. legacy normalized templateVersion == null', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklist: '{"ITEM-1":{"status":"pass","notes":"old note"}}',
      });
      await _projectRepo().loadProjectItemStates('p1');
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.templateVersion, isNull);
    });

    test('13. result nullable/null for both legacy and native', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final native =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(native.result, isNull);

      SharedPreferences.setMockInitialValues({
        _kChecklist: '{"ITEM-1":{"status":"fail"}}',
      });
      await _projectRepo().loadProjectItemStates('p1');
      final legacy =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(legacy.result, isNull);
    });

    test('14. execution-level notes null (W4.8)', () async {
      await _projectRepo().saveProjectItemNotes('p1', 'ITEM-1', 'note text');
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.notes, isNull);
    });

    test('15. no attachments / title / author fields added', () {
      const forbidden = [
        'title',
        'authorId',
        'createdBy',
        'isDeleted',
        'isArchived',
        'schemaVersion',
        'attachments',
        'attachment',
      ];
      for (final f in forbidden) {
        expect(_execFields.contains(f), isFalse,
            reason: 'entity must not contain field `$f`');
      }
    });
  });

  group('W4.8 LEGACY NORMALIZATION', () {
    test('16. existing legacy map becomes exactly one execution', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklist:
            '{"ITEM-1":{"status":"pass","notes":"a"},"ITEM-2":{"status":"fail"}}',
      });
      await _projectRepo().loadProjectItemStates('p1');
      final execs = await _gateway().readProjectChecklistExecutions('p1');
      expect(execs, hasLength(1));
    });

    test('17. itemId preserved', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklist: '{"CONC-01":{"status":"pass"}}',
      });
      await _projectRepo().loadProjectItemStates('p1');
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.executedItemSnapshot.single['itemId'], 'CONC-01');
    });

    test('18. status preserved', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklist: '{"ITEM-1":{"status":"na"}}',
      });
      await _projectRepo().loadProjectItemStates('p1');
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.executedItemSnapshot.single['status'], 'na');
    });

    test('19. notes preserved', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklist: '{"ITEM-1":{"status":"fail","notes":"needs work"}}',
      });
      await _projectRepo().loadProjectItemStates('p1');
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.executedItemSnapshot.single['notes'], 'needs work');
    });

    test('20. startedAt remains null for legacy', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklist: '{"ITEM-1":{"status":"pass"}}',
      });
      await _projectRepo().loadProjectItemStates('p1');
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.startedAt, isNull);
    });

    test('21. completedAt remains null until Reset', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklist: '{"ITEM-1":{"status":"pass"}}',
      });
      await _projectRepo().loadProjectItemStates('p1');
      expect(
          (await _gateway().readProjectChecklistExecutions('p1')).single
              .completedAt,
          isNull);
    });

    test('22. repeated migration does not duplicate', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklist: '{"ITEM-1":{"status":"pass"}}',
      });
      final repo = _projectRepo();
      await repo.loadProjectItemStates('p1');
      await repo.loadProjectItemStates('p1');
      await repo.loadProjectItemStates('p1');
      expect(await _gateway().readProjectChecklistExecutions('p1'), hasLength(1));
    });

    test('23. empty legacy state creates no execution', () async {
      SharedPreferences.setMockInitialValues({});
      await _projectRepo().loadProjectItemStates('p1');
      expect(await _gateway().readProjectChecklistExecutions('p1'), isEmpty);
    });
  });

  group('W4.8 DUAL WRITE', () {
    test('24. status change still writes legacy key', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final prefs = await SharedPreferences.getInstance();
      final legacy = jsonDecode(prefs.getString(_kChecklist)!)
          as Map<String, dynamic>;
      expect(legacy['ITEM-1']!['status'], 'pass');
    });

    test('25. same status action updates Projects active execution', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.completedAt, isNull);
      expect(exec.executedItemSnapshot.single['itemId'], 'ITEM-1');
      expect(exec.executedItemSnapshot.single['status'], 'pass');
    });

    test('26. notes change still writes legacy key', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.fail);
      await _projectRepo().saveProjectItemNotes('p1', 'ITEM-1', 'note x');
      final legacy = jsonDecode(
          (await SharedPreferences.getInstance()).getString(_kChecklist)!)
          as Map<String, dynamic>;
      expect(legacy['ITEM-1']!['notes'], 'note x');
    });

    test('27. same notes action updates SAME active execution', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.fail);
      final first =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      await _projectRepo().saveProjectItemNotes('p1', 'ITEM-1', 'note x');
      final execs = await _gateway().readProjectChecklistExecutions('p1');
      expect(execs, hasLength(1));
      expect(execs.single.executionId, first.executionId);
      expect(execs.single.executedItemSnapshot.single['notes'], 'note x');
    });

    test('28. repeated item changes do not create execution-per-tap', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-2', InspectionStatus.fail);
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-3', InspectionStatus.na);
      expect(await _gateway().readProjectChecklistExecutions('p1'), hasLength(1));
    });

    test('29. active snapshot reflects post-write legacy state', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().saveProjectItemNotes('p1', 'ITEM-1', 'done');
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-2', InspectionStatus.fail);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      final snap = {
        for (final m in exec.executedItemSnapshot)
          m['itemId']: {'status': m['status'], 'notes': m['notes']},
      };
      expect(snap['ITEM-1']!['status'], 'pass');
      expect(snap['ITEM-1']!['notes'], 'done');
      expect(snap['ITEM-2']!['status'], 'fail');
    });
  });

  group('W4.8 NATIVE LIFECYCLE', () {
    test('30. first native write creates execution', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      expect(await _gateway().readProjectChecklistExecutions('p1'), hasLength(1));
    });

    test('31. executionId format is correct', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.executionId, startsWith('checklist_execution_'));
      expect(exec.executionId.split('_').length, greaterThanOrEqualTo(4));
    });

    test('32. native startedAt assigned by Projects layer', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.startedAt, isNotNull);
    });

    test('33. native completedAt initially null', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      expect(
          (await _gateway().readProjectChecklistExecutions('p1')).single
              .completedAt,
          isNull);
    });

    test('34. subsequent writes preserve executionId', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final firstId =
          (await _gateway().readProjectChecklistExecutions('p1')).single
              .executionId;
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.fail);
      final execs = await _gateway().readProjectChecklistExecutions('p1');
      expect(execs.single.executionId, firstId);
    });

    test('35. subsequent writes preserve startedAt', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final firstStarted =
          (await _gateway().readProjectChecklistExecutions('p1')).single
              .startedAt;
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-2', InspectionStatus.fail);
      expect(
          (await _gateway().readProjectChecklistExecutions('p1')).single
              .startedAt,
          firstStarted);
    });

    test('36. active native snapshot updates', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.fail);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.executedItemSnapshot.single['status'], 'fail');
    });
  });

  group('W4.8 RESET / COMPLETION', () {
    test('37. Reset finalizes active execution BEFORE legacy clear', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().saveProjectItemNotes('p1', 'ITEM-1', 'keep me');
      await _projectRepo().clearProject('p1');
      final execs = await _gateway().readProjectChecklistExecutions('p1');
      expect(execs.single.completedAt, isNotNull);
      expect(execs.single.executedItemSnapshot.single['status'], 'pass');
      expect(execs.single.executedItemSnapshot.single['notes'], 'keep me');
    });

    test('38. completedAt assigned on Reset', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().clearProject('p1');
      expect(
          (await _gateway().readProjectChecklistExecutions('p1')).single
              .completedAt,
          isNotNull);
    });

    test('39. completed execution immutable after Reset', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().clearProject('p1');
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.fail);
      final execs = await _gateway().readProjectChecklistExecutions('p1');
      expect(execs, hasLength(2));
      final completed = execs.first;
      expect(completed.completedAt, isNotNull);
      expect(completed.executedItemSnapshot.single['status'], 'pass');
    });

    test('40. Reset still clears legacy checklist_project_<id>', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().clearProject('p1');
      final states = await _projectRepo().loadProjectItemStates('p1');
      expect(states, isEmpty);
    });

    test('41. Reset does NOT clear execution history', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().clearProject('p1');
      expect(await _gateway().readProjectChecklistExecutions('p1'), hasLength(1));
    });

    test('42. Reset on empty state creates no execution', () async {
      await _projectRepo().clearProject('p1');
      expect(await _gateway().readProjectChecklistExecutions('p1'), isEmpty);
    });

    test('43. next write after Reset creates NEW executionId', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().clearProject('p1');
      final first =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.na);
      final execs = await _gateway().readProjectChecklistExecutions('p1');
      expect(execs, hasLength(2));
      expect(execs[1].executionId, isNot(first.executionId));
    });

    test('44. prior execution remains unchanged after new run', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().clearProject('p1');
      final first =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-2', InspectionStatus.fail);
      final execs = await _gateway().readProjectChecklistExecutions('p1');
      expect(execs[0].executionId, first.executionId);
      expect(execs[0].completedAt, isNotNull);
      expect(execs[0].executedItemSnapshot.single['itemId'], 'ITEM-1');
      expect(execs[1].completedAt, isNull);
      expect(execs[1].executedItemSnapshot.single['itemId'], 'ITEM-2');
    });

    test('45. multiple runs accumulate', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().clearProject('p1');
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.na);
      await _projectRepo().clearProject('p1');
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.fail);
      await _projectRepo().clearProject('p1');
      expect(await _gateway().readProjectChecklistExecutions('p1'), hasLength(3));
    });
  });

  group('W4.8 SNAPSHOT', () {
    test('46. snapshot contains itemId', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final snap =
          (await _gateway().readProjectChecklistExecutions('p1')).single
              .executedItemSnapshot;
      expect(snap.single.keys, contains('itemId'));
    });

    test('47. snapshot contains exact status', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.executedItemSnapshot.single['status'], 'pass');
    });

    test('48. snapshot contains per-item notes', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.fail);
      await _projectRepo().saveProjectItemNotes('p1', 'ITEM-1', 'note here');
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.executedItemSnapshot.single['notes'], 'note here');
    });

    test('49. snapshot does NOT fabricate label/title', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.executedItemSnapshot.single.containsKey('title'), isFalse);
      expect(exec.executedItemSnapshot.single.containsKey('label'), isFalse);
    });

    test('50. snapshot does NOT fabricate category', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.executedItemSnapshot.single.containsKey('category'), isFalse);
    });

    test('51. snapshot does NOT fabricate codeRef', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      final exec =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(exec.executedItemSnapshot.single.containsKey('codeRef'), isFalse);
    });

    test('52. deep-copy/serialization isolates completed record from mutation',
        () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().clearProject('p1');
      var loaded =
          (await _gateway().readProjectChecklistExecutions('p1')).single;
      loaded.executedItemSnapshot.single['status'] = 'hacked';
      loaded = (await _gateway().readProjectChecklistExecutions('p1')).single;
      expect(loaded.executedItemSnapshot.single['status'], 'pass');
    });
  });

  group('W4.8 COMPATIBILITY', () {
    test('53. existing checklist status behavior remains green', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.fail);
      final states = await _projectRepo().loadProjectItemStates('p1');
      expect(states['ITEM-1']!.status, InspectionStatus.fail);
    });

    test('54. notes persist with status (debounce end state)', () async {
      await _projectRepo()
          .saveProjectItemStatus('p1', 'ITEM-1', InspectionStatus.pass);
      await _projectRepo().saveProjectItemNotes('p1', 'ITEM-1', 'final');
      final states = await _projectRepo().loadProjectItemStates('p1');
      expect(states['ITEM-1']!.status, InspectionStatus.pass);
      expect(states['ITEM-1']!.notes, 'final');
    });

    test('55. legacy readers still load state', () async {
      SharedPreferences.setMockInitialValues({
        _kChecklist: '{"ITEM-1":{"status":"fail","notes":"x"}}',
      });
      final states = await _projectRepo().loadProjectItemStates('p1');
      expect(states['ITEM-1']!.status, InspectionStatus.fail);
      expect(states['ITEM-1']!.notes, 'x');
    });

    test('56. global checklist unaffected by project reset', () async {
      final repo = _projectRepo();
      await repo.saveItemStatus('ITEM-1', InspectionStatus.na);
      await repo.saveProjectItemStatus('p1', 'ITEM-2', InspectionStatus.fail);
      await repo.clearProject('p1');
      final globals = await repo.loadItemStates();
      expect(globals['ITEM-1']!.status, InspectionStatus.na);
    });

    test('65. Project entity unchanged', () {
      final source = File('lib/features/projects/domain/entities/project.dart')
          .readAsStringSync();
      expect(source, isNot(contains('ChecklistExecution')));
      expect(source, isNot(contains('execution')));
    });

    test('66. no route/nav or visible controls added', () {
      final screen = File(
        'lib/features/tools/presentation/screens/checklist/checklist_screen.dart',
      ).readAsStringSync();
      expect(screen, isNot(contains('ExecutionHistory')));
      expect(screen, isNot(contains('Start Execution')));
      expect(screen, isNot(contains('Complete')));
      expect(screen, isNot(contains('Submit')));
    });

    test('template contract is stable and non-derived', () {
      expect(ChecklistTemplateContract.templateId, 'site_inspection');
      expect(ChecklistTemplateContract.templateVersion, '1');
    });
  });
}
