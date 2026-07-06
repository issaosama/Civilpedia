import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../localization/ar.dart';
import '../../../../../localization/en.dart';

// ───────────── Enums ─────────────

enum _TileOrientation { sameDirection, alternating, diagonal }

enum _TileUnit { mm, cm }

enum _PriceMode { perTile, perBox }

// ───────────── Result Model ─────────────

class _TileResult {
  final double area;
  final double tileArea;
  final int rawTiles;
  final double wastePercent;
  final int wasteQuantity;
  final int totalTiles;
  final int boxes;
  final double? materialCost;
  final double? wasteCost;
  final int spareTiles;
  final String roomCategory;

  const _TileResult({
    required this.area,
    required this.tileArea,
    required this.rawTiles,
    required this.wastePercent,
    required this.wasteQuantity,
    required this.totalTiles,
    required this.boxes,
    this.materialCost,
    this.wasteCost,
    required this.spareTiles,
    required this.roomCategory,
  });
}

// ───────────── Screen ─────────────

class TileCalculatorScreen extends StatefulWidget {
  const TileCalculatorScreen({super.key});

  @override
  State<TileCalculatorScreen> createState() => _TileCalculatorScreenState();
}

class _TileCalculatorScreenState extends State<TileCalculatorScreen> {
  // ── Controllers ──
  final _areaLengthCtrl = TextEditingController();
  final _areaWidthCtrl = TextEditingController();
  final _tileLengthCtrl = TextEditingController();
  final _tileWidthCtrl = TextEditingController();
  final _wastePercentCtrl = TextEditingController();
  final _tilesPerBoxCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // ── State ──
  _TileOrientation _orientation = _TileOrientation.sameDirection;
  _TileUnit _unit = _TileUnit.mm;
  _PriceMode _priceMode = _PriceMode.perTile;
  _TileResult? _result;
  bool _showCost = false;

  // ── Constants ──
  static const Map<_TileOrientation, double> _defaultWaste = {
    _TileOrientation.sameDirection: 5,
    _TileOrientation.alternating: 8,
    _TileOrientation.diagonal: 12,
  };

  String _wasteRecommendation() {
    return switch (_orientation) {
      _TileOrientation.sameDirection => Ar.wasteRecStraight,
      _TileOrientation.alternating => Ar.wasteRecAlternating,
      _TileOrientation.diagonal => Ar.wasteRecDiagonal,
    };
  }

  // ── Lifecycle ──
  @override
  void initState() {
    super.initState();
    _wastePercentCtrl.text = _defaultWaste[_orientation]!.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _areaLengthCtrl.dispose();
    _areaWidthCtrl.dispose();
    _tileLengthCtrl.dispose();
    _tileWidthCtrl.dispose();
    _wastePercentCtrl.dispose();
    _tilesPerBoxCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── Orientation Change ──
  void _onOrientationChanged(_TileOrientation? value) {
    if (value == null) return;
    setState(() {
      _orientation = value;
      _wastePercentCtrl.text = _defaultWaste[value]!.toStringAsFixed(0);
      _result = null;
    });
  }

  // ── Calculation ──
  void _calculate() {
    final areaL = double.tryParse(_areaLengthCtrl.text) ?? 0;
    final areaW = double.tryParse(_areaWidthCtrl.text) ?? 0;
    final tileL = double.tryParse(_tileLengthCtrl.text) ?? 0;
    final tileW = double.tryParse(_tileWidthCtrl.text) ?? 0;
    final wastePct = double.tryParse(_wastePercentCtrl.text) ?? 0;

    if (areaL <= 0 || areaW <= 0 || tileL <= 0 || tileW <= 0 || wastePct < 0) {
      _showError(Ar.invalidInputs);
      return;
    }

    final tileLM = _unit == _TileUnit.mm ? tileL / 1000 : tileL / 100;
    final tileWM = _unit == _TileUnit.mm ? tileW / 1000 : tileW / 100;

    if (tileLM <= 0 || tileWM <= 0) {
      _showError(Ar.invalidInputs);
      return;
    }

    if (tileLM > areaL || tileWM > areaW) {
      _showError(Ar.tileTooLarge);
      return;
    }

    final area = areaL * areaW;
    final tileArea = tileLM * tileWM;
    final rawTiles = area / tileArea;
    final wasteFactor = wastePct / 100;
    final wasteQty = (rawTiles * wasteFactor).ceil();
    final totalTiles = (rawTiles * (1 + wasteFactor)).ceil();

    final tpb = double.tryParse(_tilesPerBoxCtrl.text) ?? 0;
    final boxes = tpb > 0 ? (totalTiles / tpb).ceil() : 0;

    double? materialCost;
    double? wasteCost;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (price > 0 && _showCost) {
      if (_priceMode == _PriceMode.perTile) {
        materialCost = totalTiles * price;
        wasteCost = wasteQty * price;
      } else if (boxes > 0) {
        materialCost = boxes * price;
      }
    }

    int spareTiles;
    String roomCategory;
    if (area < 15) {
      spareTiles = 5;
      roomCategory = Ar.smallRoom;
    } else if (area <= 30) {
      spareTiles = 10;
      roomCategory = Ar.mediumRoom;
    } else {
      spareTiles = 15;
      roomCategory = Ar.largeRoom;
    }

    setState(() {
      _result = _TileResult(
        area: area,
        tileArea: tileArea,
        rawTiles: rawTiles.ceil(),
        wastePercent: wastePct,
        wasteQuantity: wasteQty,
        totalTiles: totalTiles,
        boxes: boxes,
        materialCost: materialCost,
        wasteCost: wasteCost,
        spareTiles: spareTiles,
        roomCategory: roomCategory,
      );
    });
  }

  void _showError(String message) {
    setState(() => _result = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(Ar.tileCalc)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          _buildInfoHeader(theme),
          AppSpacing.gapLg,
          _buildInputCard(theme),
          if (_result != null) ...[
            AppSpacing.gapLg,
            _buildResultsCard(theme),
          ],
          AppSpacing.gapXl,
        ],
      ),
    );
  }

  Widget _buildInfoHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: const Icon(Icons.grid_on, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Ar.tileCalc,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Ar.tileCalcDesc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── Input Card ─────────────

  Widget _buildInputCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Unit Selector ──
          Center(
            child: SegmentedButton<_TileUnit>(
              segments: [
                ButtonSegment(
                  value: _TileUnit.mm,
                  label: Text(Ar.unitMm),
                ),
                ButtonSegment(
                  value: _TileUnit.cm,
                  label: Text(Ar.unitCm),
                ),
              ],
              selected: {_unit},
              onSelectionChanged: (set) {
                setState(() {
                  _unit = set.first;
                  _tileLengthCtrl.clear();
                  _tileWidthCtrl.clear();
                  _result = null;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          AppSpacing.gapLg,

          // ── Area Dimensions ──
          Text(
            '${Ar.areaCoverage} (${Ar.squareMeters})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.gapSm,
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: Ar.areaLength,
                  ctrl: _areaLengthCtrl,
                  suffix: Ar.meters,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  label: Ar.areaWidth,
                  ctrl: _areaWidthCtrl,
                  suffix: Ar.meters,
                  theme: theme,
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,

          // ── Tile Dimensions ──
          Text(
            '${Ar.tileLength} (${_unit == _TileUnit.mm ? Ar.unitMm : Ar.unitCm})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.gapSm,
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: Ar.tileLength,
                  ctrl: _tileLengthCtrl,
                  suffix: _unit == _TileUnit.mm ? Ar.unitMm : Ar.unitCm,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  label: Ar.tileWidth,
                  ctrl: _tileWidthCtrl,
                  suffix: _unit == _TileUnit.mm ? Ar.unitMm : Ar.unitCm,
                  theme: theme,
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,

          // ── Orientation ──
          DropdownButtonFormField<_TileOrientation>(
            value: _orientation,
            decoration: _inputDecoration(Ar.tileOrientation, theme),
            items: [
              DropdownMenuItem(
                value: _TileOrientation.sameDirection,
                child: Text(Ar.sameDirection),
              ),
              DropdownMenuItem(
                value: _TileOrientation.alternating,
                child: Text(Ar.alternating),
              ),
              DropdownMenuItem(
                value: _TileOrientation.diagonal,
                child: Text(Ar.diagonal),
              ),
            ],
            onChanged: _onOrientationChanged,
          ),
          AppSpacing.gapMd,

          // ── Waste Percentage ──
          RichText(
            text: TextSpan(
              text: '${Ar.wastePercent}: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: _wasteRecommendation(),
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapXs,
          _buildField(
            label: Ar.wastePercent,
            ctrl: _wastePercentCtrl,
            suffix: '%',
            theme: theme,
          ),
          AppSpacing.gapLg,

          // ── Divider ──
          Divider(),
          AppSpacing.gapSm,

          // ── Tiles Per Box ──
          _buildField(
            label: Ar.tilesPerBox,
            ctrl: _tilesPerBoxCtrl,
            suffix: '',
            theme: theme,
            hint: '0 =',
          ),
          AppSpacing.gapMd,

          // ── Cost Toggle ──
          Row(
            children: [
              Expanded(
                child: Text(
                  Ar.costOption,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: _showCost,
                onChanged: (v) => setState(() {
                  _showCost = v;
                  _result = null;
                  if (!v) _priceCtrl.clear();
                }),
              ),
            ],
          ),

          if (_showCost) ...[
            // ── Price Mode Toggle ──
            Center(
              child: SegmentedButton<_PriceMode>(
                segments: [
                  ButtonSegment(
                    value: _PriceMode.perTile,
                    label: Text(Ar.pricePerTile),
                  ),
                  ButtonSegment(
                    value: _PriceMode.perBox,
                    label: Text(Ar.pricePerBox),
                  ),
                ],
                selected: {_priceMode},
                onSelectionChanged: (set) {
                  setState(() {
                    _priceMode = set.first;
                    _priceCtrl.clear();
                    _result = null;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            AppSpacing.gapMd,
            _buildField(
              label: _priceMode == _PriceMode.perTile
                  ? Ar.pricePerTile
                  : Ar.pricePerBox,
              ctrl: _priceCtrl,
              suffix: isRtl ? Ar.currency : En.currency,
              theme: theme,
            ),
          ],

          AppSpacing.gapLg,

          // ── Calculate Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate, size: 20),
              label: Text(Ar.calcTile),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── Results Card ─────────────

  Widget _buildResultsCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final r = _result!;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle,
                    color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                Ar.result,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          Divider(),
          AppSpacing.gapSm,

          // ── Coverage Section ──
          _resultRow(
            Ar.areaCoverage,
            '${r.area.toStringAsFixed(2)} ${Ar.concreteVolume}',
            theme,
          ),
          _resultRow(
            Ar.tileUnitArea,
            '${r.tileArea.toStringAsFixed(4)} ${Ar.concreteVolume}',
            theme,
          ),
          AppSpacing.gapSm,
          Divider(),
          AppSpacing.gapSm,

          // ── Tile Count Section ──
          _resultRow(Ar.requiredTiles, '${r.rawTiles}', theme),
          _resultRow(Ar.wastePercent, '${r.wastePercent.toStringAsFixed(1)}%', theme),
          _wasteBreakdown(theme),
          _resultRow(Ar.wasteQuantity, '$r.wasteQuantity', theme),
          AppSpacing.gapSm,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Ar.finalTileCount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                Text(
                  '${r.totalTiles}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (r.boxes > 0) ...[
            AppSpacing.gapSm,
            _resultRow(Ar.requiredBoxes, '$r.boxes', theme),
          ],

          // ── Cost Section ──
          if (r.materialCost != null) ...[
            AppSpacing.gapSm,
            Divider(),
            AppSpacing.gapSm,
            _resultRow(
              Ar.materialCost,
              _formatCurrency(r.materialCost!),
              theme,
            ),
            if (r.wasteCost != null)
              _resultRow(
                Ar.wasteCost,
                _formatCurrency(r.wasteCost!),
                theme,
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Ar.totalCost,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    _formatCurrency(r.materialCost! + (r.wasteCost ?? 0)),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Spare Recommendation ──
          AppSpacing.gapMd,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.build, color: AppColors.info, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Ar.spareRecommendation,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${Ar.spareText.replaceAll('%d', '${r.spareTiles}')} (${r.roomCategory})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wasteBreakdown(ThemeData theme) {
    final wastePct = _result!.wastePercent;
    final cutting = 2.0;
    double edgeTrim;
    double pattern;
    switch (_orientation) {
      case _TileOrientation.sameDirection:
        edgeTrim = wastePct - cutting;
        pattern = 0;
        break;
      case _TileOrientation.alternating:
        edgeTrim = 4.0;
        pattern = wastePct - cutting - edgeTrim;
        break;
      case _TileOrientation.diagonal:
        edgeTrim = 6.0;
        pattern = wastePct - cutting - edgeTrim;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _breakdownItem(Ar.cuttingLoss, cutting, theme),
          _breakdownItem(Ar.edgeTrimLoss, edgeTrim, theme),
          if (pattern > 0) _breakdownItem(Ar.patternLoss, pattern, theme),
        ],
      ),
    );
  }

  Widget _breakdownItem(String label, double pct, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_left, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$label: ${pct.toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(0);
  }

  // ───────────── Shared Widgets ─────────────

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required String suffix,
    required ThemeData theme,
    String hint = '0',
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        textAlign: TextAlign.right,
        style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withValues(alpha: 0.4)),
          suffixText: suffix.isNotEmpty ? suffix : null,
          suffixStyle: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontSize: 13,
          ),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 14),
      hintText: '0',
      hintStyle: TextStyle(color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withValues(alpha: 0.4)),
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
