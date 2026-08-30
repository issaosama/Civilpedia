import '../../../projects/domain/entities/project_calculation_record.dart';
import '../tool_key.dart';

/// W4.5 — canonical Tile calculation snapshot adapter (Tools domain).
///
/// Owns the single stable snapshot contract for a saved Tile calculation:
/// the [calculatorId], the [calculatorVersion] (version of THIS snapshot
/// schema, NOT the app/package version), and the stable field names for the
/// Tile V1 `inputSnapshot` / `outputSnapshot`.
///
/// The snapshot is a JSON-safe, immutable copy of the real Tile calculation
/// state at save time. Snapshot schema version `'1'` corresponds EXACTLY to the
/// field names below; do not rename keys without advancing [calculatorVersion]
/// in a later approved migration.
class TileCalculationSnapshot {
  TileCalculationSnapshot._();

  /// Stable semantic calculator identity for the Tile tool.
  static final String calculatorId = ToolKey.tile.stableId;

  /// Version of this Tile snapshot contract (not the app version).
  static const String calculatorVersion = '1';

  // ── Input field names ──
  static const String kAreaLength = 'areaLength';
  static const String kAreaWidth = 'areaWidth';
  static const String kQuantity = 'quantity';
  static const String kExcludedArea = 'excludedArea';
  static const String kTileLengthCm = 'tileLengthCm';
  static const String kTileWidthCm = 'tileWidthCm';
  static const String kUnit = 'unit';
  static const String kIsCustomTile = 'isCustomTile';
  static const String kAdditionalPercent = 'additionalPercent';
  static const String kIsCustomPercent = 'isCustomPercent';
  static const String kBoxEstimateEnabled = 'boxEstimateEnabled';
  static const String kCostEnabled = 'costEnabled';
  static const String kTilesPerBox = 'tilesPerBox';
  static const String kPrice = 'price';
  static const String kPriceMode = 'priceMode';

  // ── Output field names ──
  static const String kGross = 'gross';
  static const String kNet = 'net';
  static const String kTileArea = 'tileArea';
  static const String kTilesPerM2 = 'tilesPerM2';
  static const String kNetTiles = 'netTiles';
  static const String kAdditionalTiles = 'additionalTiles';
  static const String kFinalTiles = 'finalTiles';
  static const String kRequiredBoxes = 'requiredBoxes';
  static const String kTotalCost = 'totalCost';

  /// Builds the immutable Tile V1 `inputSnapshot` from the real Tile
  /// calculation input state. Optional estimate inputs are `null` when the
  /// corresponding feature is disabled; their booleans are always present so
  /// the record is self-describing.
  static Map<String, Object?> buildInputSnapshot({
    required double areaLength,
    required double areaWidth,
    required int quantity,
    required double excludedArea,
    required double tileLengthCm,
    required double tileWidthCm,
    required String unit,
    required bool isCustomTile,
    required double additionalPercent,
    required bool isCustomPercent,
    required bool boxEstimateEnabled,
    required bool costEnabled,
    int? tilesPerBox,
    double? price,
    String? priceMode,
  }) {
    return {
      kAreaLength: areaLength,
      kAreaWidth: areaWidth,
      kQuantity: quantity,
      kExcludedArea: excludedArea,
      kTileLengthCm: tileLengthCm,
      kTileWidthCm: tileWidthCm,
      kUnit: unit,
      kIsCustomTile: isCustomTile,
      kAdditionalPercent: additionalPercent,
      kIsCustomPercent: isCustomPercent,
      kBoxEstimateEnabled: boxEstimateEnabled,
      kCostEnabled: costEnabled,
      kTilesPerBox: tilesPerBox,
      kPrice: price,
      kPriceMode: priceMode,
    };
  }

  /// Builds the immutable Tile V1 `outputSnapshot` from the real computed Tile
  /// results. Optional outputs are `null` when the matching feature is
  /// disabled (rather than a fabricated zero).
  static Map<String, Object?> buildOutputSnapshot({
    required double gross,
    required double net,
    required double tileArea,
    required double tilesPerM2,
    required int netTiles,
    required int additionalTiles,
    required int finalTiles,
    int? requiredBoxes,
    double? totalCost,
  }) {
    return {
      kGross: gross,
      kNet: net,
      kTileArea: tileArea,
      kTilesPerM2: tilesPerM2,
      kNetTiles: netTiles,
      kAdditionalTiles: additionalTiles,
      kFinalTiles: finalTiles,
      kRequiredBoxes: requiredBoxes,
      kTotalCost: totalCost,
    };
  }

  /// Convenience: constructs a [ProjectCalculationRecord] payload for the Tile
  /// tool without any record/tool identity leaking into Tile presentation.
  static ProjectCalculationRecord record({
    required String projectId,
    required Map<String, Object?> inputSnapshot,
    required Map<String, Object?> outputSnapshot,
  }) {
    return ProjectCalculationRecord(
      id: '', // assigned by Projects save path
      projectId: projectId,
      calculatorId: calculatorId,
      calculatorVersion: calculatorVersion,
      title: null,
      inputSnapshot: inputSnapshot,
      outputSnapshot: outputSnapshot,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0), // assigned by Projects
    );
  }
}
