import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_status.dart';
import 'package:civilpedia/features/tools/data/checklist/local_checklist_repository.dart';
import 'package:civilpedia/features/tools/data/checklist/checklist_local_data_source.dart';

void main() {
  group('LocalChecklistRepository N/A persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('N/A can be saved and restored', () async {
      final dataSource = ChecklistLocalDataSource();
      final repo = LocalChecklistRepository(dataSource);

      await repo.saveItemStatus('ITEM-1', InspectionStatus.na);
      final states = await repo.loadItemStates();

      expect(states['ITEM-1']!.status, InspectionStatus.na);
    });

    test('N/A persists across repository recreation', () async {
      var dataSource = ChecklistLocalDataSource();
      var repo = LocalChecklistRepository(dataSource);
      await repo.saveItemStatus('ITEM-1', InspectionStatus.na);

      // Recreate repository
      dataSource = ChecklistLocalDataSource();
      repo = LocalChecklistRepository(dataSource);
      final states = await repo.loadItemStates();

      expect(states['ITEM-1']!.status, InspectionStatus.na);
    });

    test('existing Pass/Fail/Pending still deserialize correctly', () async {
      // Store legacy statuses directly via JSON
      SharedPreferences.setMockInitialValues({
        'checklist_data':
            '{"ITEM-1":{"status":"pass"},"ITEM-2":{"status":"fail"},"ITEM-3":{"status":"pending"}}',
      });

      final dataSource = ChecklistLocalDataSource();
      final repo = LocalChecklistRepository(dataSource);
      final states = await repo.loadItemStates();

      expect(states['ITEM-1']!.status, InspectionStatus.pass);
      expect(states['ITEM-2']!.status, InspectionStatus.fail);
      expect(states['ITEM-3']!.status, InspectionStatus.pending);
    });

    test('notes remain associated with correct item', () async {
      SharedPreferences.setMockInitialValues({
        'checklist_data':
            '{"ITEM-1":{"status":"fail","notes":"needs rework"}}',
      });

      final dataSource = ChecklistLocalDataSource();
      final repo = LocalChecklistRepository(dataSource);
      final states = await repo.loadItemStates();

      expect(states['ITEM-1']!.status, InspectionStatus.fail);
      expect(states['ITEM-1']!.notes, 'needs rework');
    });

    test('unknown status string falls back to Pending', () async {
      SharedPreferences.setMockInitialValues({
        'checklist_data':
            '{"ITEM-1":{"status":"unknown_value"}}',
      });

      final dataSource = ChecklistLocalDataSource();
      final repo = LocalChecklistRepository(dataSource);
      final states = await repo.loadItemStates();

      // Safe fallback
      expect(states['ITEM-1']!.status, InspectionStatus.pending);
    });

    test('saveItemNotes preserves existing status', () async {
      final dataSource = ChecklistLocalDataSource();
      final repo = LocalChecklistRepository(dataSource);

      await repo.saveItemStatus('ITEM-1', InspectionStatus.na);
      await repo.saveItemNotes('ITEM-1', 'not applicable here');

      final states = await repo.loadItemStates();
      expect(states['ITEM-1']!.status, InspectionStatus.na);
      expect(states['ITEM-1']!.notes, 'not applicable here');
    });
  });

  group('LocalChecklistRepository project isolation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Project A and Project B states are independent', () async {
      final dataSource = ChecklistLocalDataSource();
      final repo = LocalChecklistRepository(dataSource);

      await repo.saveProjectItemStatus('projA', 'ITEM-1', InspectionStatus.fail);
      await repo.saveProjectItemStatus('projB', 'ITEM-1', InspectionStatus.pass);

      final statesA = await repo.loadProjectItemStates('projA');
      final statesB = await repo.loadProjectItemStates('projB');

      expect(statesA['ITEM-1']!.status, InspectionStatus.fail);
      expect(statesB['ITEM-1']!.status, InspectionStatus.pass);
    });

    test('reset Project A does not affect Project B', () async {
      final dataSource = ChecklistLocalDataSource();
      final repo = LocalChecklistRepository(dataSource);

      await repo.saveProjectItemStatus('projA', 'ITEM-1', InspectionStatus.fail);
      await repo.saveProjectItemStatus('projB', 'ITEM-1', InspectionStatus.pass);

      await repo.clearProject('projA');

      final statesA = await repo.loadProjectItemStates('projA');
      final statesB = await repo.loadProjectItemStates('projB');

      expect(statesA, isEmpty);
      expect(statesB['ITEM-1']!.status, InspectionStatus.pass);
    });

    test('global checklist is independent from project checklists', () async {
      final dataSource = ChecklistLocalDataSource();
      final repo = LocalChecklistRepository(dataSource);

      await repo.saveItemStatus('ITEM-1', InspectionStatus.na);
      await repo.saveProjectItemStatus('projA', 'ITEM-1', InspectionStatus.fail);

      final globals = await repo.loadItemStates();
      final projects = await repo.loadProjectItemStates('projA');

      expect(globals['ITEM-1']!.status, InspectionStatus.na);
      expect(projects['ITEM-1']!.status, InspectionStatus.fail);
    });
  });

  group('LocalChecklistRepository reset', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('clearAll removes all items', () async {
      final dataSource = ChecklistLocalDataSource();
      final repo = LocalChecklistRepository(dataSource);

      await repo.saveItemStatus('ITEM-1', InspectionStatus.fail);
      await repo.clearAll();

      final states = await repo.loadItemStates();
      expect(states, isEmpty);
    });

    test('clearProject removes only project items, global items survive', () async {
      final dataSource = ChecklistLocalDataSource();
      final repo = LocalChecklistRepository(dataSource);

      await repo.saveItemStatus('ITEM-1', InspectionStatus.na);
      await repo.saveProjectItemStatus('projA', 'ITEM-1', InspectionStatus.fail);
      await repo.clearProject('projA');

      final globals = await repo.loadItemStates();
      final projects = await repo.loadProjectItemStates('projA');

      expect(globals['ITEM-1']!.status, InspectionStatus.na);
      expect(projects, isEmpty);
    });
  });
}
