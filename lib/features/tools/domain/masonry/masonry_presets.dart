/// Masonry unit type for filtering presets and labelling results.
enum MasonryType { block, brick }

/// Explicitly-described masonry preset. The displayed label may use a
/// commercial convention, but every preset maps to self-describing named
/// dimensions and an explicit effective wall face.
class MasonryPreset {
  final String label;
  final MasonryType type;
  final double thicknessCm;
  final double heightCm;
  final double lengthCm;
  final double faceLengthCm;
  final double faceHeightCm;

  const MasonryPreset({
    required this.label,
    required this.type,
    required this.thicknessCm,
    required this.heightCm,
    required this.lengthCm,
    required this.faceLengthCm,
    required this.faceHeightCm,
  });

  /// Concrete blocks. Convention: label shows Thickness × Height × Length.
  /// Wall face = Height × Length. All dimensions are nominal/modular.
  static const block20x20x40 = MasonryPreset(
    label: '20×20×40',
    type: MasonryType.block,
    thicknessCm: 20,
    heightCm: 20,
    lengthCm: 40,
    faceLengthCm: 40,
    faceHeightCm: 20,
  );

  static const block10x20x40 = MasonryPreset(
    label: '10×20×40',
    type: MasonryType.block,
    thicknessCm: 10,
    heightCm: 20,
    lengthCm: 40,
    faceLengthCm: 40,
    faceHeightCm: 20,
  );

  static const block15x20x40 = MasonryPreset(
    label: '15×20×40',
    type: MasonryType.block,
    thicknessCm: 15,
    heightCm: 20,
    lengthCm: 40,
    faceLengthCm: 40,
    faceHeightCm: 20,
  );

  /// Clay bricks. The label follows the convention Length × Thickness × Height
  /// but the explicit named dimensions are correct regardless of the
  /// commercial label ordering.
  /// Stretcher wall face = Length × Height.
  static const brick25x12x6 = MasonryPreset(
    label: '25×12×6',
    type: MasonryType.brick,
    thicknessCm: 12,
    heightCm: 6,
    lengthCm: 25,
    faceLengthCm: 25,
    faceHeightCm: 6,
  );

  /// All available presets.
  static const all = <MasonryPreset>[
    block20x20x40,
    block10x20x40,
    block15x20x40,
    brick25x12x6,
  ];

  /// Presets for a given [MasonryType].
  static List<MasonryPreset> forType(MasonryType type) =>
      all.where((p) => p.type == type).toList();
}
