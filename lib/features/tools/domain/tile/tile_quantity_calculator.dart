import 'dart:math' as math;

/// Pure, widget-independent tile quantity math.
///
/// All surface dimensions are in meters. Tile dimensions are in centimeters
/// and normalised to meters internally. The calculator never rounds
/// intermediate values; precision is applied only at display time.
class TileQuantityCalculator {
  TileQuantityCalculator._();

  /// Gross surface area of [quantity] identical surfaces in m².
  static double grossAreaM2({
    required double lengthM,
    required double widthM,
    required int quantity,
  }) {
    if (lengthM <= 0 || widthM <= 0 || quantity <= 0) return 0;
    return lengthM * widthM * quantity;
  }

  /// Net surface area after deducting [excludedAreaM2] in m².
  /// Returns 0 when the excluded area is invalid or exceeds gross.
  static double netAreaM2({
    required double grossAreaM2,
    required double excludedAreaM2,
  }) {
    if (grossAreaM2 <= 0) return 0;
    if (excludedAreaM2 < 0 || excludedAreaM2 >= grossAreaM2) return 0;
    return grossAreaM2 - excludedAreaM2;
  }

  /// Single tile face area in m². Tile dimensions are in cm.
  static double tileAreaM2({
    required double tileLengthCm,
    required double tileWidthCm,
  }) {
    if (tileLengthCm <= 0 || tileWidthCm <= 0) return 0;
    return tileLengthCm / 100 * tileWidthCm / 100;
  }

  /// Raw (unrounded) tile count.
  static double rawTileCount({
    required double netAreaM2,
    required double tileAreaM2,
  }) {
    if (netAreaM2 <= 0 || tileAreaM2 <= 0) return 0;
    return netAreaM2 / tileAreaM2;
  }

  /// Net whole tiles: ceil of the raw count.
  static int netWholeTiles({required double rawTileCount}) {
    if (rawTileCount <= 0) return 0;
    return rawTileCount.ceil();
  }

  /// Final tiles after the optional additional percentage.
  /// Applies the percentage to the RAW count before rounding, then ceils
  /// to avoid intermediate-rounding inflation.
  static int finalTiles({
    required double rawTileCount,
    required double additionalPercent,
  }) {
    if (rawTileCount <= 0 || additionalPercent < 0) return 0;
    return (rawTileCount * (1 + additionalPercent / 100)).ceil();
  }

  /// Additional tiles attributed to the optional percentage.
  static int additionalTiles({
    required double rawTileCount,
    required double additionalPercent,
  }) {
    if (rawTileCount <= 0 || additionalPercent <= 0) return 0;
    return math.max(
        0,
        finalTiles(
                rawTileCount: rawTileCount,
                additionalPercent: additionalPercent) -
            netWholeTiles(rawTileCount: rawTileCount));
  }

  /// Theoretical tiles per m² (unrounded).
  static double tilesPerM2({required double tileAreaM2}) {
    if (tileAreaM2 <= 0) return 0;
    return 1 / tileAreaM2;
  }

  /// Required boxes: ceil of final tiles / tiles per box.
  /// Returns 0 when [tilesPerBox] is not a valid positive integer.
  static int requiredBoxes({
    required int finalTiles,
    required int tilesPerBox,
  }) {
    if (finalTiles <= 0 || tilesPerBox <= 0) return 0;
    return (finalTiles / tilesPerBox).ceil();
  }

  /// Estimated cost based on price per tile and final tile count.
  static double estimatedCostPerTile({
    required int finalTiles,
    required double pricePerTile,
  }) {
    if (finalTiles <= 0 || pricePerTile <= 0) return 0;
    return finalTiles * pricePerTile;
  }

  /// Estimated cost based on required boxes and price per box.
  static double estimatedCostPerBox({
    required int requiredBoxes,
    required double pricePerBox,
  }) {
    if (requiredBoxes <= 0 || pricePerBox <= 0) return 0;
    return requiredBoxes * pricePerBox;
  }
}
