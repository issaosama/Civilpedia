import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/tools/domain/tile/tile_quantity_calculator.dart';

void main() {
  group('TileQuantityCalculator.grossAreaM2', () {
    test('5 m × 4 m × 1 = 20 m²', () {
      expect(TileQuantityCalculator.grossAreaM2(lengthM: 5, widthM: 4, quantity: 1), closeTo(20, 1e-9));
    });
    test('5 m × 4 m × 2 = 40 m²', () {
      expect(TileQuantityCalculator.grossAreaM2(lengthM: 5, widthM: 4, quantity: 2), closeTo(40, 1e-9));
    });
    test('non-positive inputs yield zero', () {
      expect(TileQuantityCalculator.grossAreaM2(lengthM: 0, widthM: 4, quantity: 1), 0);
      expect(TileQuantityCalculator.grossAreaM2(lengthM: 5, widthM: 0, quantity: 1), 0);
      expect(TileQuantityCalculator.grossAreaM2(lengthM: 5, widthM: 4, quantity: 0), 0);
    });
  });

  group('TileQuantityCalculator.netAreaM2', () {
    test('20 − 0 = 20', () {
      expect(TileQuantityCalculator.netAreaM2(grossAreaM2: 20, excludedAreaM2: 0), closeTo(20, 1e-9));
    });
    test('20 − 2 = 18', () {
      expect(TileQuantityCalculator.netAreaM2(grossAreaM2: 20, excludedAreaM2: 2), closeTo(18, 1e-9));
    });
    test('excluded >= gross yields zero', () {
      expect(TileQuantityCalculator.netAreaM2(grossAreaM2: 20, excludedAreaM2: 20), 0);
      expect(TileQuantityCalculator.netAreaM2(grossAreaM2: 20, excludedAreaM2: 25), 0);
    });
    test('negative excluded yields zero', () {
      expect(TileQuantityCalculator.netAreaM2(grossAreaM2: 20, excludedAreaM2: -1), 0);
    });
  });

  group('TileQuantityCalculator.tileAreaM2', () {
    test('60 × 60 cm = 0.36 m²', () {
      expect(TileQuantityCalculator.tileAreaM2(tileLengthCm: 60, tileWidthCm: 60), closeTo(0.36, 1e-9));
    });
    test('60 × 120 cm = 0.72 m²', () {
      expect(TileQuantityCalculator.tileAreaM2(tileLengthCm: 60, tileWidthCm: 120), closeTo(0.72, 1e-9));
    });
    test('non-positive yields zero', () {
      expect(TileQuantityCalculator.tileAreaM2(tileLengthCm: 0, tileWidthCm: 60), 0);
    });
  });

  group('TileQuantityCalculator.rawTileCount / netWholeTiles', () {
    test('18 / 0.36 = 50', () {
      expect(TileQuantityCalculator.rawTileCount(netAreaM2: 18, tileAreaM2: 0.36), closeTo(50, 1e-9));
      expect(TileQuantityCalculator.netWholeTiles(rawTileCount: 50), 50);
    });
    test('20 / 0.36 ≈ 55.56 → ceil = 56', () {
      final raw = TileQuantityCalculator.rawTileCount(netAreaM2: 20, tileAreaM2: 0.36);
      expect(raw, closeTo(55.5556, 1e-4));
      expect(TileQuantityCalculator.netWholeTiles(rawTileCount: raw), 56);
    });
  });

  group('TileQuantityCalculator.finalTiles / additionalTiles', () {
    test('50 + 5% → 53 final, 3 additional', () {
      expect(TileQuantityCalculator.finalTiles(rawTileCount: 50, additionalPercent: 5), 53);
      expect(TileQuantityCalculator.additionalTiles(rawTileCount: 50, additionalPercent: 5), 3);
    });
    test('0% adds nothing', () {
      expect(TileQuantityCalculator.finalTiles(rawTileCount: 50, additionalPercent: 0), 50);
      expect(TileQuantityCalculator.additionalTiles(rawTileCount: 50, additionalPercent: 0), 0);
    });
    test('negative percent yields zero', () {
      expect(TileQuantityCalculator.finalTiles(rawTileCount: 50, additionalPercent: -5), 0);
    });
    test('no intermediate rounding inflation: 55.56 raw + 5%', () {
      final f = TileQuantityCalculator.finalTiles(rawTileCount: 55.5556, additionalPercent: 5);
      expect(f, 59); // ceil(58.33) = 59, not ceil(56)*1.05=59
    });
  });

  group('TileQuantityCalculator.tilesPerM2', () {
    test('0.36 m² tile → ~2.78 per m²', () {
      expect(TileQuantityCalculator.tilesPerM2(tileAreaM2: 0.36), closeTo(2.78, 0.01));
    });
  });

  group('TileQuantityCalculator.requiredBoxes', () {
    test('53 tiles / 10 per box → 6 boxes', () {
      expect(TileQuantityCalculator.requiredBoxes(finalTiles: 53, tilesPerBox: 10), 6);
    });
    test('invalid inputs yield zero', () {
      expect(TileQuantityCalculator.requiredBoxes(finalTiles: 0, tilesPerBox: 10), 0);
      expect(TileQuantityCalculator.requiredBoxes(finalTiles: 50, tilesPerBox: 0), 0);
    });
  });

  group('TileQuantityCalculator cost', () {
    test('per-tile: 53 × 1000 = 53000', () {
      expect(TileQuantityCalculator.estimatedCostPerTile(finalTiles: 53, pricePerTile: 1000), 53000);
    });
    test('per-box: 6 × 5000 = 30000', () {
      expect(TileQuantityCalculator.estimatedCostPerBox(requiredBoxes: 6, pricePerBox: 5000), 30000);
    });
    test('invalid inputs yield zero', () {
      expect(TileQuantityCalculator.estimatedCostPerTile(finalTiles: 0, pricePerTile: 1000), 0);
      expect(TileQuantityCalculator.estimatedCostPerTile(finalTiles: 50, pricePerTile: 0), 0);
    });
  });
}
