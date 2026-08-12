import 'dart:math' as math;

/// Pure, widget-independent reinforcement steel weight math.
///
/// The bar diameter is in millimeters and all lengths are in meters.
/// Steel density is 7850 kg/m³. The calculator never rounds intermediate
/// values; precision is applied only at display time by the UI.
class SteelWeightCalculator {
  SteelWeightCalculator._();

  /// Theoretical unit weight of a plain/corrugated bar in kg/m:
  /// `(π/4) · (diameterMm / 1000)² · 7850`.
  /// Returns 0 when the diameter is not positive.
  static double unitWeightKgPerM({required double diameterMm}) {
    if (diameterMm <= 0) return 0;
    final d = diameterMm / 1000;
    return math.pi * d * d / 4 * 7850;
  }

  /// Weight of a single bar in kg. Returns 0 when inputs are not positive.
  static double weightPerBar({
    required double unitWeightKgPerM,
    required double lengthM,
  }) {
    if (unitWeightKgPerM <= 0 || lengthM <= 0) return 0;
    return unitWeightKgPerM * lengthM;
  }

  /// Total length of [quantity] identical bars in meters. Returns 0 when
  /// inputs are invalid.
  static double totalLengthM({required double lengthM, required int quantity}) {
    if (lengthM <= 0 || quantity <= 0) return 0;
    return lengthM * quantity;
  }

  /// Net steel weight in kg: total length × unit weight.
  static double netWeightKg({
    required double totalLengthM,
    required double unitWeightKgPerM,
  }) {
    if (totalLengthM <= 0 || unitWeightKgPerM <= 0) return 0;
    return totalLengthM * unitWeightKgPerM;
  }

  /// Extra weight added by the optional additional percentage, in kg.
  /// Returns 0 when there is no additional percentage.
  static double additionalWeightKg({
    required double netWeightKg,
    required double additionalPercent,
  }) {
    if (netWeightKg <= 0 || additionalPercent <= 0) return 0;
    return netWeightKg * additionalPercent / 100;
  }

  /// Final steel weight in kg after the optional additional percentage,
  /// e.g. 5% → Net × (1 + 5 / 100). This is an optional convenience
  /// (default 0%) and not a code-prescribed engineering allowance.
  static double finalWeightKg({
    required double netWeightKg,
    required double additionalPercent,
  }) {
    if (netWeightKg <= 0 || additionalPercent < 0) return 0;
    return netWeightKg * (1 + additionalPercent / 100);
  }

  /// Final weight converted to metric tons.
  static double finalWeightTon({required double finalWeightKg}) {
    if (finalWeightKg <= 0) return 0;
    return finalWeightKg / 1000;
  }

  /// Approximate number of whole bars per metric ton: `floor(1000 / weightPerBar)`.
  /// Theoretical only; the real count depends on the mill and bar tolerance.
  static int barsPerTon({required double weightPerBarKg}) {
    if (weightPerBarKg <= 0) return 0;
    return (1000 / weightPerBarKg).floor();
  }

  /// Number of identical [barLengthM] bars that fit inside one stock bar.
  /// Returns 0 when the stock bar is not long enough for a single required bar
  /// or when either length is not positive.
  static int barsPerStockBar({
    required double stockBarLengthM,
    required double barLengthM,
  }) {
    if (stockBarLengthM <= 0 || barLengthM <= 0 || stockBarLengthM < barLengthM) {
      return 0;
    }
    return (stockBarLengthM / barLengthM).floor();
  }

  /// Number of stock bars of length [stockBarLengthM] needed to produce
  /// [quantity] identical bars of length [barLengthM].
  ///
  /// Packs as many identical bars as fit inside one stock bar:
  /// `barsPerStockBar = floor(stockBarLengthM / barLengthM)`.
  /// Returns 0 when the stock bar is shorter than the required bar; the caller
  /// must surface a procurement-only validation instead of assuming lap splices.
  static int requiredStockBars({
    required double barLengthM,
    required int quantity,
    required double stockBarLengthM,
  }) {
    if (barLengthM <= 0 || quantity <= 0 || stockBarLengthM <= 0) return 0;
    final barsPerStockBar = (stockBarLengthM / barLengthM).floor();
    if (barsPerStockBar >= 1) {
      return (quantity / barsPerStockBar).ceil();
    }
    return 0;
  }

  /// Total purchased length for [stockBars] stock bars, in meters.
  static double purchasedLengthM({
    required int stockBars,
    required double stockBarLengthM,
  }) {
    if (stockBars <= 0 || stockBarLengthM <= 0) return 0;
    return stockBars * stockBarLengthM;
  }

  /// Unused (left-over) length after cutting all required bars, in meters.
  static double remainingLengthM({
    required double purchasedLengthM,
    required double requiredLengthM,
  }) {
    if (purchasedLengthM <= 0 || requiredLengthM <= 0) return 0;
    final r = purchasedLengthM - requiredLengthM;
    return r > 0 ? r : 0;
  }

  /// Weight of the purchased steel in kg.
  static double purchasedWeightKg({
    required double purchasedLengthM,
    required double unitWeightKgPerM,
  }) {
    if (purchasedLengthM <= 0 || unitWeightKgPerM <= 0) return 0;
    return purchasedLengthM * unitWeightKgPerM;
  }

  /// Estimated cost from the final weight and a price per metric ton.
  /// Estimate only: the user-provided price may not match the final market.
  static double estimatedCost({
    required double finalWeightTon,
    required double pricePerTon,
  }) {
    if (finalWeightTon <= 0 || pricePerTon <= 0) return 0;
    return finalWeightTon * pricePerTon;
  }
}
