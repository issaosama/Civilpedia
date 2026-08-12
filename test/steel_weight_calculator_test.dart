import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/tools/domain/steel/steel_weight_calculator.dart';

void main() {
  group('SteelWeightCalculator.unitWeightKgPerM', () {
    test('known diameters match standard unit weights', () {
      expect(SteelWeightCalculator.unitWeightKgPerM(diameterMm: 8),
          closeTo(0.395, 0.005));
      expect(SteelWeightCalculator.unitWeightKgPerM(diameterMm: 10),
          closeTo(0.617, 0.005));
      expect(SteelWeightCalculator.unitWeightKgPerM(diameterMm: 12),
          closeTo(0.888, 0.005));
      expect(SteelWeightCalculator.unitWeightKgPerM(diameterMm: 16),
          closeTo(1.578, 0.005));
      expect(SteelWeightCalculator.unitWeightKgPerM(diameterMm: 20),
          closeTo(2.466, 0.005));
      expect(SteelWeightCalculator.unitWeightKgPerM(diameterMm: 25),
          closeTo(3.853, 0.005));
      expect(SteelWeightCalculator.unitWeightKgPerM(diameterMm: 32),
          closeTo(6.313, 0.005));
    });

    test('non-positive diameter yields zero', () {
      expect(SteelWeightCalculator.unitWeightKgPerM(diameterMm: 0), 0);
      expect(SteelWeightCalculator.unitWeightKgPerM(diameterMm: -5), 0);
    });
  });

  group('steel pipeline 16 mm × 12 m × 10', () {
    final wpm = SteelWeightCalculator.unitWeightKgPerM(diameterMm: 16);

    test('single bar weight', () {
      expect(
        SteelWeightCalculator.weightPerBar(
            unitWeightKgPerM: wpm, lengthM: 12),
        closeTo(18.94, 0.01),
      );
    });

    test('total length', () {
      expect(SteelWeightCalculator.totalLengthM(lengthM: 12, quantity: 10),
          closeTo(120, 1e-9));
    });

    test('net, additional, final and tons', () {
      final net = SteelWeightCalculator.netWeightKg(
          totalLengthM: 120, unitWeightKgPerM: wpm);
      expect(net, closeTo(189.4, 0.01));

      expect(
        SteelWeightCalculator.additionalWeightKg(
            netWeightKg: net, additionalPercent: 5),
        closeTo(9.47, 0.01),
      );

      final finalWeight =
          SteelWeightCalculator.finalWeightKg(netWeightKg: net, additionalPercent: 5);
      expect(finalWeight, closeTo(198.87, 0.01));
      expect(
        SteelWeightCalculator.finalWeightTon(finalWeightKg: finalWeight),
        closeTo(0.1989, 0.001),
      );
    });

    test('0% adds nothing and keeps final equal to net', () {
      final net = SteelWeightCalculator.netWeightKg(
          totalLengthM: 120, unitWeightKgPerM: wpm);
      expect(
        SteelWeightCalculator.additionalWeightKg(
            netWeightKg: net, additionalPercent: 0),
        0,
      );
      expect(
        SteelWeightCalculator.finalWeightKg(
            netWeightKg: net, additionalPercent: 0),
        closeTo(net, 1e-9),
      );
    });

    test('1000 kg at 5% gives 1050 kg final and 50 kg additional', () {
      expect(
        SteelWeightCalculator.additionalWeightKg(
            netWeightKg: 1000, additionalPercent: 5),
        closeTo(50, 1e-9),
      );
      expect(
        SteelWeightCalculator.finalWeightKg(
            netWeightKg: 1000, additionalPercent: 5),
        closeTo(1050, 1e-9),
      );
    });

    test('no intermediate rounding in the pipeline', () {
      final wpm25 = SteelWeightCalculator.unitWeightKgPerM(diameterMm: 25);
      final total = SteelWeightCalculator.netWeightKg(
          totalLengthM: SteelWeightCalculator.totalLengthM(lengthM: 12, quantity: 7),
          unitWeightKgPerM: wpm25);
      expect(total, closeTo(12 * 7 * wpm25, 1e-9));
    });
  });

  group('SteelWeightCalculator.barsPerTon', () {
    test('16 mm × 12 m bar → 52 bars per ton', () {
      final wpm = SteelWeightCalculator.unitWeightKgPerM(diameterMm: 16);
      final bar = SteelWeightCalculator.weightPerBar(
          unitWeightKgPerM: wpm, lengthM: 12);
      expect(SteelWeightCalculator.barsPerTon(weightPerBarKg: bar), 52);
    });

    test('non-positive bar weight yields zero', () {
      expect(SteelWeightCalculator.barsPerTon(weightPerBarKg: 0), 0);
    });
  });

  group('SteelWeightCalculator.barsPerStockBar', () {
    test('6 m bars fit twice in a 12 m stock bar', () {
      expect(
        SteelWeightCalculator.barsPerStockBar(
            stockBarLengthM: 12, barLengthM: 6),
        2,
      );
    });

    test('7 m bars fit once in a 12 m stock bar', () {
      expect(
        SteelWeightCalculator.barsPerStockBar(
            stockBarLengthM: 12, barLengthM: 7),
        1,
      );
    });

    test('12 m bars fit once in a 12 m stock bar', () {
      expect(
        SteelWeightCalculator.barsPerStockBar(
            stockBarLengthM: 12, barLengthM: 12),
        1,
      );
    });

    test('14 m bars do not fit in a 12 m stock bar', () {
      expect(
        SteelWeightCalculator.barsPerStockBar(
            stockBarLengthM: 12, barLengthM: 14),
        0,
      );
    });

    test('non-positive inputs yield zero', () {
      expect(
        SteelWeightCalculator.barsPerStockBar(
            stockBarLengthM: 0, barLengthM: 6),
        0,
      );
      expect(
        SteelWeightCalculator.barsPerStockBar(
            stockBarLengthM: 12, barLengthM: 0),
        0,
      );
    });
  });

  group('SteelWeightCalculator.requiredStockBars', () {
    test('7 m bars from 12 m stock is 10, not the naive 6', () {
      expect(
        SteelWeightCalculator.requiredStockBars(
            barLengthM: 7, quantity: 10, stockBarLengthM: 12),
        10,
      );
    });

    test('6 m bars pack two per 12 m stock bar', () {
      expect(
        SteelWeightCalculator.requiredStockBars(
            barLengthM: 6, quantity: 10, stockBarLengthM: 12),
        5,
      );
    });

    test('bar longer than the stock bar is rejected; no splice assumed', () {
      expect(
        SteelWeightCalculator.requiredStockBars(
            barLengthM: 13, quantity: 3, stockBarLengthM: 12),
        0,
      );
    });

    test('purchased length, remaining length and purchased weight', () {
      final wpm = SteelWeightCalculator.unitWeightKgPerM(diameterMm: 12);
      final bars = SteelWeightCalculator.requiredStockBars(
          barLengthM: 6, quantity: 10, stockBarLengthM: 12);
      final purchased =
          SteelWeightCalculator.purchasedLengthM(stockBars: bars, stockBarLengthM: 12);
      expect(purchased, closeTo(60, 1e-9));
      expect(
        SteelWeightCalculator.remainingLengthM(
            purchasedLengthM: purchased, requiredLengthM: 60),
        0,
      );
      expect(
        SteelWeightCalculator.purchasedWeightKg(
            purchasedLengthM: purchased, unitWeightKgPerM: wpm),
        closeTo(60 * wpm, 1e-9),
      );
    });

    test('invalid inputs yield zero', () {
      expect(
        SteelWeightCalculator.requiredStockBars(
            barLengthM: 6, quantity: 0, stockBarLengthM: 12),
        0,
      );
      expect(
        SteelWeightCalculator.requiredStockBars(
            barLengthM: 6, quantity: 10, stockBarLengthM: 0),
        0,
      );
    });
  });

  group('SteelWeightCalculator.finalWeightKg', () {
    test('negative additional percent returns 0, not a reduced weight', () {
      expect(
        SteelWeightCalculator.finalWeightKg(
            netWeightKg: 1000, additionalPercent: -5),
        0,
      );
    });

    test('0% returns exactly the net weight', () {
      expect(
        SteelWeightCalculator.finalWeightKg(
            netWeightKg: 1000, additionalPercent: 0),
        closeTo(1000, 1e-9),
      );
    });

    test('5% returns 1050 kg for 1000 kg net', () {
      expect(
        SteelWeightCalculator.finalWeightKg(
            netWeightKg: 1000, additionalPercent: 5),
        closeTo(1050, 1e-9),
      );
    });
  });
  group('SteelWeightCalculator.estimatedCost', () {
    test('final ton × price per ton', () {
      expect(
        SteelWeightCalculator.estimatedCost(
            finalWeightTon: 1.25, pricePerTon: 800),
        closeTo(1000, 1e-9),
      );
    });

    test('non-positive inputs yield zero', () {
      expect(
        SteelWeightCalculator.estimatedCost(
            finalWeightTon: 0, pricePerTon: 800),
        0,
      );
      expect(
        SteelWeightCalculator.estimatedCost(
            finalWeightTon: 1, pricePerTon: 0),
        0,
      );
    });
  });
}
