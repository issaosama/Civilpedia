import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_item.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_status.dart';
import 'package:civilpedia/features/tools/presentation/screens/checklist/models/inspection_summary.dart';

InspectionSummary _summary(Map<String, InspectionItem> items) {
  int passed = 0, failed = 0, pending = 0, na = 0;
  for (final item in items.values) {
    switch (item.status) {
      case InspectionStatus.pass: passed++; break;
      case InspectionStatus.fail: failed++; break;
      case InspectionStatus.pending: pending++; break;
      case InspectionStatus.na: na++; break;
    }
  }
  return InspectionSummary(
    totalItems: items.length,
    passed: passed,
    failed: failed,
    pending: pending,
    na: na,
    criticalTotal: 0,
    criticalPassed: 0,
    requiredTotal: 0,
    requiredPassed: 0,
  );
}

void main() {
  group('InspectionItem status', () {
    test('new item defaults to Pending', () {
      final item = InspectionItem(id: '1', categoryId: 'c', titleKey: 't');
      expect(item.status, InspectionStatus.pending);
    });

    test('can set status to Pass', () {
      final item = InspectionItem(id: '1', categoryId: 'c', titleKey: 't');
      item.status = InspectionStatus.pass;
      expect(item.status, InspectionStatus.pass);
    });

    test('can set status to Fail', () {
      final item = InspectionItem(id: '1', categoryId: 'c', titleKey: 't');
      item.status = InspectionStatus.fail;
      expect(item.status, InspectionStatus.fail);
    });

    test('can set status to N/A', () {
      final item = InspectionItem(id: '1', categoryId: 'c', titleKey: 't');
      item.status = InspectionStatus.na;
      expect(item.status, InspectionStatus.na);
    });

    test('can return from inspected to Pending', () {
      final item = InspectionItem(id: '1', categoryId: 'c', titleKey: 't');
      item.status = InspectionStatus.fail;
      item.status = InspectionStatus.pending;
      expect(item.status, InspectionStatus.pending);
    });
  });

  group('InspectionSummary counts', () {
    test('all Pending => Pass=0, Fail=0, N/A=0', () {
      final items = {for (var i = 0; i < 5; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      final s = _summary(items);
      expect(s.passed, 0);
      expect(s.failed, 0);
      expect(s.na, 0);
      expect(s.pending, 5);
    });

    test('Pass increments Pass and Inspected', () {
      final items = {for (var i = 0; i < 3; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.pass;
      final s = _summary(items);
      expect(s.passed, 1);
      expect(s.inspected, 1);
    });

    test('Fail increments Fail and Inspected', () {
      final items = {for (var i = 0; i < 3; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.fail;
      final s = _summary(items);
      expect(s.failed, 1);
      expect(s.inspected, 1);
    });

    test('N/A increments N/A and Inspected', () {
      final items = {for (var i = 0; i < 3; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.na;
      final s = _summary(items);
      expect(s.na, 1);
      expect(s.inspected, 1);
    });

    test('Pending does not count as inspected', () {
      final items = {for (var i = 0; i < 5; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.pass;
      items['1']!.status = InspectionStatus.fail;
      items['2']!.status = InspectionStatus.na;
      final s = _summary(items);
      expect(s.inspected, 3); // pass+fail+na only
      expect(s.pending, 2);
    });

    test('inspectedCount = Pass + Fail + N/A', () {
      final items = {for (var i = 0; i < 10; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.pass;
      items['1']!.status = InspectionStatus.pass;
      items['2']!.status = InspectionStatus.fail;
      items['3']!.status = InspectionStatus.na;
      final s = _summary(items);
      expect(s.inspected, s.passed + s.failed + s.na);
    });

    test('Pass => Fail updates counts correctly', () {
      final items = {for (var i = 0; i < 3; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.pass;
      var s = _summary(items);
      expect(s.passed, 1);
      expect(s.failed, 0);

      items['0']!.status = InspectionStatus.fail;
      s = _summary(items);
      expect(s.passed, 0);
      expect(s.failed, 1);
      expect(s.inspected, 1);
    });

    test('Fail => N/A updates counts correctly', () {
      final items = {for (var i = 0; i < 3; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.fail;
      var s = _summary(items);
      expect(s.failed, 1);
      expect(s.na, 0);

      items['0']!.status = InspectionStatus.na;
      s = _summary(items);
      expect(s.failed, 0);
      expect(s.na, 1);
      expect(s.inspected, 1);
    });

    test('N/A => Pending decreases inspected count', () {
      final items = {for (var i = 0; i < 3; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.na;
      var s = _summary(items);
      expect(s.inspected, 1);

      items['0']!.status = InspectionStatus.pending;
      s = _summary(items);
      expect(s.inspected, 0);
      expect(s.pending, 3);
    });

    test('progress = inspected / totalItems', () {
      final items = {for (var i = 0; i < 8; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.pass;
      items['1']!.status = InspectionStatus.fail;
      items['2']!.status = InspectionStatus.na;
      final s = _summary(items);
      expect(s.inspected, 3);
      expect(s.progressPercent, closeTo(3.0 / 8.0, 1e-9));
    });

    test('complete only when Pending = 0', () {
      final items = {for (var i = 0; i < 3; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.pass;
      items['1']!.status = InspectionStatus.fail;
      items['2']!.status = InspectionStatus.na;
      final s = _summary(items);
      expect(s.pending, 0);
      expect(s.inspected, s.totalItems);
    });

    test('empty checklist => zero counts, safe progress', () {
      final s = _summary({});
      expect(s.totalItems, 0);
      expect(s.progressPercent, 0);
      expect(s.inspected, 0);
    });

    test('reset returns all to Pending', () {
      final items = {for (var i = 0; i < 5; i++) '$i': InspectionItem(id: '$i', categoryId: 'c', titleKey: 't')};
      items['0']!.status = InspectionStatus.pass;
      items['1']!.status = InspectionStatus.fail;
      items['2']!.status = InspectionStatus.na;

      for (final item in items.values) {
        item.status = InspectionStatus.pending;
      }
      final s = _summary(items);
      expect(s.pending, 5);
      expect(s.inspected, 0);
    });
  });

  group('InspectionStatus enum values', () {
    test('has four values: pending, pass, fail, na', () {
      expect(InspectionStatus.values.length, 4);
      expect(InspectionStatus.values, contains(InspectionStatus.pending));
      expect(InspectionStatus.values, contains(InspectionStatus.pass));
      expect(InspectionStatus.values, contains(InspectionStatus.fail));
      expect(InspectionStatus.values, contains(InspectionStatus.na));
    });

    test('enum names serialize correctly', () {
      expect(InspectionStatus.pending.name, 'pending');
      expect(InspectionStatus.pass.name, 'pass');
      expect(InspectionStatus.fail.name, 'fail');
      expect(InspectionStatus.na.name, 'na');
    });
  });
}
