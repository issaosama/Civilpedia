import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/tools/domain/concrete/concrete_volume_calculator.dart';

void main() {
  group('ConcreteVolumeCalculator.singleElementVolume', () {
    test('slab 5 × 4 × 0.20 m = 4.000 m³', () {
      final v = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.slab,
        length: 5,
        width: 4,
        thickness: 0.20,
      );
      expect(v, closeTo(4.0, 1e-9));
    });

    test('beam 5 × 0.30 × 0.50 m = 0.750 m³', () {
      final v = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.beam,
        length: 5,
        width: 0.30,
        height: 0.50,
      );
      expect(v, closeTo(0.75, 1e-9));
    });

    test('rectangular column 0.40 × 0.40 × 3.00 m = 0.480 m³', () {
      final v = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.column,
        width: 0.40,
        depth: 0.40,
        height: 3.00,
      );
      expect(v, closeTo(0.48, 1e-9));
    });

    test('circular column D = 0.40 m, H = 3.00 m ≈ 0.377 m³', () {
      final v = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.circularColumn,
        diameter: 0.40,
        height: 3.00,
      );
      expect(v, closeTo(math.pi * 0.40 * 0.40 / 4 * 3.00, 1e-9));
      expect(v.toStringAsFixed(3), '0.377');
    });

    test('wall 5 × 0.20 × 3.00 m = 3.000 m³', () {
      final v = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.wall,
        length: 5,
        thickness: 0.20,
        height: 3.00,
      );
      expect(v, closeTo(3.0, 1e-9));
    });

    test('footing 2 × 2 × 0.50 m = 2.000 m³', () {
      final v = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.footing,
        length: 2,
        width: 2,
        thickness: 0.50,
      );
      expect(v, closeTo(2.0, 1e-9));
    });
  });

  group('Irrelevant dimensions are ignored', () {
    test('circular column ignores width/depth/thickness/length', () {
      final v = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.circularColumn,
        length: 99,
        width: 99,
        depth: 99,
        thickness: 99,
        diameter: 0.40,
        height: 3.00,
      );
      expect(v, closeTo(math.pi * 0.40 * 0.40 / 4 * 3.00, 1e-9));
    });

    test('column ignores length/thickness/diameter', () {
      final v = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.column,
        length: 99,
        thickness: 99,
        diameter: 99,
        width: 0.40,
        depth: 0.40,
        height: 3.00,
      );
      expect(v, closeTo(0.48, 1e-9));
    });

    test('wall ignores width/depth/diameter', () {
      final v = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.wall,
        width: 99,
        depth: 99,
        diameter: 99,
        length: 5,
        thickness: 0.20,
        height: 3.00,
      );
      expect(v, closeTo(3.0, 1e-9));
    });
  });

  group('Unit conversion', () {
    test('equivalent slab in m, cm and mm all produce 4.000 m³', () {
      final inMeters = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.slab,
        length: 5 * ConcreteDimensionUnit.meters.factorToMeters,
        width: 4 * ConcreteDimensionUnit.meters.factorToMeters,
        thickness: 0.20 * ConcreteDimensionUnit.meters.factorToMeters,
      );
      final inCm = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.slab,
        length: 500 * ConcreteDimensionUnit.centimeters.factorToMeters,
        width: 400 * ConcreteDimensionUnit.centimeters.factorToMeters,
        thickness: 20 * ConcreteDimensionUnit.centimeters.factorToMeters,
      );
      final inMm = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.slab,
        length: 5000 * ConcreteDimensionUnit.millimeters.factorToMeters,
        width: 4000 * ConcreteDimensionUnit.millimeters.factorToMeters,
        thickness: 200 * ConcreteDimensionUnit.millimeters.factorToMeters,
      );

      expect(inMeters, closeTo(4.0, 1e-9));
      expect(inCm, closeTo(4.0, 1e-9));
      expect(inMm, closeTo(4.0, 1e-9));
      expect(inMeters.toStringAsFixed(3), '4.000');
      expect(inCm.toStringAsFixed(3), '4.000');
      expect(inMm.toStringAsFixed(3), '4.000');
    });

    test('unit factors are exact', () {
      expect(ConcreteDimensionUnit.meters.factorToMeters, 1);
      expect(ConcreteDimensionUnit.centimeters.factorToMeters, 0.01);
      expect(ConcreteDimensionUnit.millimeters.factorToMeters, 0.001);
    });
  });

  group('Quantity', () {
    test('column 0.480 m³ × 10 = 4.800 m³ net', () {
      final single = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.column,
        width: 0.40,
        depth: 0.40,
        height: 3.00,
      );
      final net = ConcreteVolumeCalculator.netVolume(volume: single, quantity: 10);
      expect(net, closeTo(4.8, 1e-9));
      expect(net.toStringAsFixed(3), '4.800');
    });

    test('quantity 1 leaves net equal to single', () {
      final single = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.slab,
        length: 5,
        width: 4,
        thickness: 0.2,
      );
      expect(
        ConcreteVolumeCalculator.netVolume(volume: single, quantity: 1),
        closeTo(single, 1e-12),
      );
    });
  });

  group('Additional percentage', () {
    test('net 10.000 m³ + 5% = 10.500 m³', () {
      final total = ConcreteVolumeCalculator.totalVolume(
        netVolume: 10,
        additionalPercent: 5,
      );
      expect(total, closeTo(10.5, 1e-9));
      expect(total.toStringAsFixed(3), '10.500');
    });

    test('0% leaves the net volume unchanged', () {
      final total = ConcreteVolumeCalculator.totalVolume(
        netVolume: 4,
        additionalPercent: 0,
      );
      expect(total, closeTo(4, 1e-12));
    });

    test('total applies quantity before percentage', () {
      final single = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.slab,
        length: 5,
        width: 4,
        thickness: 0.2,
      );
      final net = ConcreteVolumeCalculator.netVolume(volume: single, quantity: 10);
      final total = ConcreteVolumeCalculator.totalVolume(
        netVolume: net,
        additionalPercent: 5,
      );
      expect(total, closeTo(42.0, 1e-9));
    });
  });

  group('Truck count', () {
    test('rounds up a partial load: 10.500 m³ ÷ 8 m³ → 2 trucks', () {
      expect(
        ConcreteVolumeCalculator.truckCount(totalVolume: 10.5, truckCapacity: 8),
        2,
      );
    });

    test('exact division: 16 m³ ÷ 8 m³ → 2 trucks', () {
      expect(
        ConcreteVolumeCalculator.truckCount(totalVolume: 16, truckCapacity: 8),
        2,
      );
    });

    test('whole load plus remainder rounds up: 10 m³ ÷ 3 m³ → 4 trucks', () {
      expect(
        ConcreteVolumeCalculator.truckCount(totalVolume: 10, truckCapacity: 3),
        4,
      );
    });

    test('returns 0 for invalid volume or capacity', () {
      expect(
        ConcreteVolumeCalculator.truckCount(totalVolume: 0, truckCapacity: 8),
        0,
      );
      expect(
        ConcreteVolumeCalculator.truckCount(totalVolume: 10, truckCapacity: 0),
        0,
      );
    });
  });

  group('Cost estimate', () {
    test('final volume × price per m³', () {
      final cost = ConcreteVolumeCalculator.estimatedCost(
        totalVolume: 10.5,
        pricePerCubicMeter: 120,
      );
      expect(cost, closeTo(1260, 1e-9));
    });

    test('uses the percentage-inflated total, not the net', () {
      final total = ConcreteVolumeCalculator.totalVolume(
        netVolume: 10,
        additionalPercent: 5,
      );
      final cost = ConcreteVolumeCalculator.estimatedCost(
        totalVolume: total,
        pricePerCubicMeter: 100,
      );
      expect(cost, closeTo(1050, 1e-9));
    });
  });

  group('No intermediate rounding', () {
    test('full double precision is kept through the pipeline', () {
      final single = ConcreteVolumeCalculator.singleElementVolume(
        type: ConcreteElementType.slab,
        length: 3.333333333,
        width: 2.5,
        thickness: 0.123456789,
      );
      final net = ConcreteVolumeCalculator.netVolume(volume: single, quantity: 7);
      final total = ConcreteVolumeCalculator.totalVolume(
        netVolume: net,
        additionalPercent: 3,
      );
      // Exactly the unrounded product, only formatting at the end.
      expect(
        total,
        closeTo(3.333333333 * 2.5 * 0.123456789 * 7 * 1.03, 1e-9),
      );
    });
  });
}
