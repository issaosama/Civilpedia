import 'dart:math' as math;

/// Pure, widget-independent masonry quantity math.
///
/// All wall dimensions are in meters. Masonry face dimensions are in
/// centimeters and normalised to meters internally. The calculator never
/// rounds intermediate values; precision is applied only at display time.
class MasonryQuantityCalculator {
  MasonryQuantityCalculator._();

  /// Gross wall area of [quantity] identical walls in m².
  static double grossWallArea({
    required double lengthM,
    required double heightM,
    required int quantity,
  }) {
    if (lengthM <= 0 || heightM <= 0 || quantity <= 0) return 0;
    return lengthM * heightM * quantity;
  }

  /// Net wall area after deducting [openingsAreaM2] in m².
  /// Returns 0 when the openings area is invalid or would yield a negative net.
  static double netWallArea({
    required double grossAreaM2,
    required double openingsAreaM2,
  }) {
    if (grossAreaM2 <= 0) return 0;
    if (openingsAreaM2 < 0 || openingsAreaM2 > grossAreaM2) return 0;
    return grossAreaM2 - openingsAreaM2;
  }

  /// Effective face area of one masonry module (nominal size including
  /// mortar joint) in m². The face dimensions are in cm and converted here.
  static double moduleFaceAreaM2({
    required double faceLengthCm,
    required double faceHeightCm,
  }) {
    if (faceLengthCm <= 0 || faceHeightCm <= 0) return 0;
    return faceLengthCm / 100 * faceHeightCm / 100;
  }

  /// Raw (unrounded) unit count: net wall area divided by module face area.
  static double rawUnitCount({
    required double netAreaM2,
    required double moduleFaceAreaM2,
  }) {
    if (netAreaM2 <= 0 || moduleFaceAreaM2 <= 0) return 0;
    return netAreaM2 / moduleFaceAreaM2;
  }

  /// Net whole units: ceil of the raw count (whole blocks needed).
  static int netWholeUnits({required double rawUnitCount}) {
    if (rawUnitCount <= 0) return 0;
    return rawUnitCount.ceil();
  }

  /// Final units after the optional additional percentage.
  /// Applies the percentage to the raw count before rounding, then ceils
  /// to avoid intermediate-rounding inflation.
  static int finalUnits({
    required double rawUnitCount,
    required double additionalPercent,
  }) {
    if (rawUnitCount <= 0 || additionalPercent < 0) return 0;
    return (rawUnitCount * (1 + additionalPercent / 100)).ceil();
  }

  /// Additional units attributed to the optional percentage.
  static int additionalUnits({
    required double rawUnitCount,
    required double additionalPercent,
  }) {
    if (rawUnitCount <= 0 || additionalPercent <= 0) return 0;
    return math.max(0, finalUnits(rawUnitCount: rawUnitCount, additionalPercent: additionalPercent) -
        netWholeUnits(rawUnitCount: rawUnitCount));
  }

  /// Theoretical units per m² (unrounded). Useful for density reference.
  static double unitsPerM2({required double moduleFaceAreaM2}) {
    if (moduleFaceAreaM2 <= 0) return 0;
    return 1 / moduleFaceAreaM2;
  }
}
