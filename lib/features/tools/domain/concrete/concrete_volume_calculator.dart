import 'dart:math' as math;

/// Element geometries supported by the concrete volume calculator.
///
/// Each geometry uses a self-describing set of named dimensions:
///   - [ConcreteElementType.slab]: length, width, thickness
///   - [ConcreteElementType.beam]: length, width, height
///   - [ConcreteElementType.column]: width, depth, height
///   - [ConcreteElementType.circularColumn]: diameter, height
///   - [ConcreteElementType.wall]: length, thickness, height
///   - [ConcreteElementType.footing]: length, width, thickness
enum ConcreteElementType { slab, beam, column, circularColumn, wall, footing }

/// Dimension unit for the current calculation. All entered dimensions share
/// one unit; the calculator normalizes to meters before computing.
enum ConcreteDimensionUnit { meters, centimeters, millimeters }

extension ConcreteDimensionUnitX on ConcreteDimensionUnit {
  /// Multiplier that converts a value in this unit to meters.
  double get factorToMeters => switch (this) {
        ConcreteDimensionUnit.meters => 1,
        ConcreteDimensionUnit.centimeters => 0.01,
        ConcreteDimensionUnit.millimeters => 0.001,
      };
}

/// Pure, widget-independent concrete volume math.
///
/// All volume inputs are expected to already be normalized to meters.
/// The calculator never rounds intermediate values; precision is applied only
/// at display time by the UI.
class ConcreteVolumeCalculator {
  ConcreteVolumeCalculator._();

  /// Net volume of a single element in m³.
  ///
  /// Pass only the named dimensions that apply to [type]; every other named
  /// parameter defaults to 0 and is ignored by the matching formula:
  ///   - circularColumn: `(π/4) · diameter² · height`
  ///   - slab / footing: `length · width · thickness`
  ///   - beam: `length · width · height`
  ///   - column: `width · depth · height`
  ///   - wall: `length · thickness · height`
  static double singleElementVolume({
    required ConcreteElementType type,
    double length = 0,
    double width = 0,
    double depth = 0,
    double height = 0,
    double thickness = 0,
    double diameter = 0,
  }) {
    switch (type) {
      case ConcreteElementType.circularColumn:
        return math.pi * diameter * diameter / 4 * height;
      case ConcreteElementType.slab:
      case ConcreteElementType.footing:
        return length * width * thickness;
      case ConcreteElementType.beam:
        return length * width * height;
      case ConcreteElementType.column:
        return width * depth * height;
      case ConcreteElementType.wall:
        return length * thickness * height;
    }
  }

  /// Total net concrete volume for [quantity] identical elements in m³.
  static double netVolume({required double volume, required int quantity}) {
    return volume * quantity;
  }

  /// Final concrete volume after the user-selected additional percentage,
  /// e.g. 5% → Total = Net × (1 + 5 / 100). This is an optional convenience
  /// (default 0%) and not a code-prescribed engineering allowance.
  static double totalVolume({
    required double netVolume,
    required double additionalPercent,
  }) {
    return netVolume * (1 + additionalPercent / 100);
  }

  /// Estimated number of truck loads needed for [totalVolume], rounded up
  /// because a partial load still requires a truck. Returns 0 when the input
  /// is not a positive volume or capacity. This is an estimate only: actual
  /// dispatch is the engineer's decision.
  static int truckCount({
    required double totalVolume,
    required double truckCapacity,
  }) {
    if (totalVolume <= 0 || truckCapacity <= 0) return 0;
    return (totalVolume / truckCapacity).ceil();
  }

  /// Estimated concrete cost in the same currency unit as [pricePerCubicMeter].
  /// The result is an estimate: the user-provided price per m³ may not match
  /// the final market price.
  static double estimatedCost({
    required double totalVolume,
    required double pricePerCubicMeter,
  }) {
    return totalVolume * pricePerCubicMeter;
  }
}
