import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/features/tools/domain/tool_key.dart';
import 'package:civilpedia/routes/app_routes.dart';

void main() {
  group('ToolKey — current production tool inventory', () {
    test('contains exactly the intended current production tools', () {
      expect(ToolKey.values.map((k) => k.stableId).toList(), [
        'concrete',
        'steel',
        'brick',
        'checklist',
        'tile',
      ]);
    });

    test('every supported ToolKey is unique', () {
      final ids = ToolKey.values.map((k) => k.stableId).toSet();
      expect(ids.length, ToolKey.values.length);
    });

    test('stable machine identities are unique', () {
      final seen = <String>{};
      for (final key in ToolKey.values) {
        expect(
          seen.add(key.stableId),
          isTrue,
          reason: 'duplicate stableId "${key.stableId}"',
        );
      }
    });
  });

  group('ToolKey — identity independent of route', () {
    test('stableId matches the ToolModel/ToolRegistry ids', () {
      // The production registry keys its tools by these ids (ArticleRepository
      // ToolModel.id). ToolKey mirrors that identity and must not drift from it.
      const productionToolIds = [
        'concrete',
        'steel',
        'brick',
        'checklist',
        'tile',
      ];
      expect(ToolKey.values.map((k) => k.stableId).toList(), productionToolIds);
    });

    test('ToolKey is an identity contract, NOT a route contract', () {
      // No ToolKey value may itself be a route path (identity must stay
      // conceptually separate from destination).
      for (final key in ToolKey.values) {
        expect(
          key.stableId.startsWith('calculator/'),
          isFalse,
          reason: 'identity "${key.stableId}" leaked route semantics',
        );
        expect(
          key.stableId.startsWith('/'),
          isFalse,
          reason: 'identity "${key.stableId}" should not carry a path root',
        );
      }
    });

    test('no accidental mapping/resolver behavior is exposed', () {
      // F0.5 ships identity only. There must be no route-to-tool resolution
      // available on the contract (a later phase adds the resolver).
      expect(
        ToolKey.values.map((k) => k.name).contains('resolver'),
        isFalse,
        reason: 'no resolver member should exist in F0.5',
      );
    });
  });

  group('ToolKey — stability of the current route surface', () {
    test('current route paths remain unchanged', () {
      // Byte-for-byte the production routes (matching AppRoutes F0.1). F0.5
      // must not alter them; ToolKey identity is the only addition.
      expect(AppRoutes.calculatorConcrete, '/calculator/concrete');
      expect(AppRoutes.calculatorSteel, '/calculator/steel');
      expect(AppRoutes.calculatorBrick, '/calculator/brick');
      expect(AppRoutes.calculatorChecklist, '/calculator/checklist');
      expect(AppRoutes.calculatorTile, '/calculator/tile');
    });

    test('ToolKey does not duplicate or redefine route constants', () {
      // Identity values and route paths share the same suffix tokens by
      // coincidence of naming, but the contract itself holds no paths.
      expect(ToolKey.values.any((k) => k.stableId.contains('/')), isFalse);
    });
  });
}
