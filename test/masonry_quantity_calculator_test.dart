import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/tools/domain/masonry/masonry_quantity_calculator.dart';
import 'package:civilpedia/features/tools/domain/masonry/masonry_presets.dart';

void main() {
  group('MasonryQuantityCalculator.grossWallArea', () {
    test('5 m × 3 m × 1 = 15 m²', () {
      expect(
        MasonryQuantityCalculator.grossWallArea(
            lengthM: 5, heightM: 3, quantity: 1),
        closeTo(15, 1e-9),
      );
    });

    test('5 m × 3 m × 2 = 30 m²', () {
      expect(
        MasonryQuantityCalculator.grossWallArea(
            lengthM: 5, heightM: 3, quantity: 2),
        closeTo(30, 1e-9),
      );
    });

    test('non-positive inputs yield zero', () {
      expect(
        MasonryQuantityCalculator.grossWallArea(
            lengthM: 0, heightM: 3, quantity: 1),
        0,
      );
      expect(
        MasonryQuantityCalculator.grossWallArea(
            lengthM: 5, heightM: 0, quantity: 1),
        0,
      );
      expect(
        MasonryQuantityCalculator.grossWallArea(
            lengthM: 5, heightM: 3, quantity: 0),
        0,
      );
    });
  });

  group('MasonryQuantityCalculator.netWallArea', () {
    test('15 m² − 3 m² = 12 m²', () {
      expect(
        MasonryQuantityCalculator.netWallArea(
            grossAreaM2: 15, openingsAreaM2: 3),
        closeTo(12, 1e-9),
      );
    });

    test('zero openings yields gross area', () {
      expect(
        MasonryQuantityCalculator.netWallArea(
            grossAreaM2: 15, openingsAreaM2: 0),
        closeTo(15, 1e-9),
      );
    });

    test('openings exceeding gross area yields zero', () {
      expect(
        MasonryQuantityCalculator.netWallArea(
            grossAreaM2: 15, openingsAreaM2: 20),
        0,
      );
    });

    test('negative openings yields zero', () {
      expect(
        MasonryQuantityCalculator.netWallArea(
            grossAreaM2: 15, openingsAreaM2: -1),
        0,
      );
    });
  });

  group('MasonryQuantityCalculator.moduleFaceAreaM2', () {
    test('40 × 20 cm face = 0.08 m²', () {
      expect(
        MasonryQuantityCalculator.moduleFaceAreaM2(
            faceLengthCm: 40, faceHeightCm: 20),
        closeTo(0.08, 1e-9),
      );
    });

    test('25 × 6 cm brick face = 0.015 m²', () {
      expect(
        MasonryQuantityCalculator.moduleFaceAreaM2(
            faceLengthCm: 25, faceHeightCm: 6),
        closeTo(0.015, 1e-9),
      );
    });

    test('non-positive dimensions yield zero', () {
      expect(
        MasonryQuantityCalculator.moduleFaceAreaM2(
            faceLengthCm: 0, faceHeightCm: 20),
        0,
      );
    });
  });

  group('MasonryQuantityCalculator.rawUnitCount', () {
    test('12 m² / 0.08 m² = 150', () {
      expect(
        MasonryQuantityCalculator.rawUnitCount(
            netAreaM2: 12, moduleFaceAreaM2: 0.08),
        closeTo(150, 1e-9),
      );
    });
  });

  group('MasonryQuantityCalculator.netWholeUnits', () {
    test('150 → 150', () {
      expect(MasonryQuantityCalculator.netWholeUnits(rawUnitCount: 150), 150);
    });

    test('150.1 → 151 (ceil)', () {
      expect(MasonryQuantityCalculator.netWholeUnits(rawUnitCount: 150.1), 151);
    });
  });

  group('MasonryQuantityCalculator.finalUnits / additionalUnits', () {
    test('150 raw + 5% → 158 final, 8 additional', () {
      expect(
        MasonryQuantityCalculator.finalUnits(
            rawUnitCount: 150, additionalPercent: 5),
        158,
      );
      expect(
        MasonryQuantityCalculator.additionalUnits(
            rawUnitCount: 150, additionalPercent: 5),
        8,
      );
    });

    test('150 raw + 0% → 150 final, 0 additional', () {
      expect(
        MasonryQuantityCalculator.finalUnits(
            rawUnitCount: 150, additionalPercent: 0),
        150,
      );
      expect(
        MasonryQuantityCalculator.additionalUnits(
            rawUnitCount: 150, additionalPercent: 0),
        0,
      );
    });

    test('negative percentage yields zero', () {
      expect(
        MasonryQuantityCalculator.finalUnits(
            rawUnitCount: 150, additionalPercent: -5),
        0,
      );
    });

    test('1000 raw + 5% → 1050 final, 50 additional', () {
      expect(
        MasonryQuantityCalculator.finalUnits(
            rawUnitCount: 1000, additionalPercent: 5),
        1050,
      );
      expect(
        MasonryQuantityCalculator.additionalUnits(
            rawUnitCount: 1000, additionalPercent: 5),
        50,
      );
    });
  });

  group('MasonryQuantityCalculator.unitsPerM2', () {
    test('0.08 m² module → 12.5 units/m²', () {
      expect(
        MasonryQuantityCalculator.unitsPerM2(moduleFaceAreaM2: 0.08),
        closeTo(12.5, 1e-6),
      );
    });
  });

  group('MasonryPreset face mappings', () {
    test('block 20×20×40 has face 40×20 cm', () {
      const p = MasonryPreset.block20x20x40;
      expect(p.faceLengthCm, 40);
      expect(p.faceHeightCm, 20);
      expect(p.thicknessCm, 20);
    });

    test('block 10×20×40 has face 40×20 cm', () {
      const p = MasonryPreset.block10x20x40;
      expect(p.faceLengthCm, 40);
      expect(p.faceHeightCm, 20);
      expect(p.thicknessCm, 10);
    });

    test('block 15×20×40 has face 40×20 cm', () {
      const p = MasonryPreset.block15x20x40;
      expect(p.faceLengthCm, 40);
      expect(p.faceHeightCm, 20);
      expect(p.thicknessCm, 15);
    });

    test('brick 25×12×6 has stretcher face 25×6 cm', () {
      const p = MasonryPreset.brick25x12x6;
      expect(p.faceLengthCm, 25);
      expect(p.faceHeightCm, 6);
    });
  });

  group('MasonryPreset.forType', () {
    test('block returns 3 presets', () {
      expect(
          MasonryPreset.forType(MasonryType.block).length, 3);
    });

    test('brick returns 1 preset', () {
      expect(
          MasonryPreset.forType(MasonryType.brick).length, 1);
    });
  });
}
