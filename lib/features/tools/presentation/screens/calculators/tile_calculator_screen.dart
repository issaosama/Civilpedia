import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../localization/ar.dart';
import '../../../../tools/domain/tile/tile_quantity_calculator.dart';
import '../../widgets/calculator/calculator_error_card.dart';
import '../../widgets/calculator/calculator_primary_button.dart';
import '../../widgets/calculator/calculator_result_row.dart';

enum _TileUnit { mm, cm }
enum _PriceMode { perTile, perBox }

// ───────────── Tile Presets ─────────────
class _TilePreset {
  final String label;
  final double lengthCm;
  final double widthCm;
  const _TilePreset(this.label, this.lengthCm, this.widthCm);

  static const presets = [
    _TilePreset('30×30', 30, 30),
    _TilePreset('40×40', 40, 40),
    _TilePreset('60×60', 60, 60),
    _TilePreset('60×120', 60, 120),
    _TilePreset('80×80', 80, 80),
  ];

  static const default_ = _TilePreset('60×60', 60, 60);
}

// ───────────── Screen ─────────────

class TileCalculatorScreen extends StatefulWidget {
  const TileCalculatorScreen({super.key});

  @override
  State<TileCalculatorScreen> createState() => _TileCalculatorScreenState();
}

class _TileCalculatorScreenState extends State<TileCalculatorScreen> {
  final _areaLengthCtrl = TextEditingController();
  final _areaWidthCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _excludedAreaCtrl = TextEditingController();
  final _tileLengthCtrl = TextEditingController();
  final _tileWidthCtrl = TextEditingController();
  final _tilesPerBoxCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  _TileUnit _unit = _TileUnit.cm;
  _TilePreset _tilePreset = _TilePreset.default_;
  bool _isCustomTile = false;
  _PriceMode _priceMode = _PriceMode.perTile;
  double _additionalPercent = 0;
  final _customPercentCtrl = TextEditingController();
  bool _isCustomPercent = false;
  bool _showBoxEstimate = false;
  bool _showCost = false;
  bool _calculated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tileLengthCtrl.addListener(_invalidate);
    _tileWidthCtrl.addListener(_invalidate);
    _areaLengthCtrl.addListener(_invalidate);
    _areaWidthCtrl.addListener(_invalidate);
    _qtyCtrl.addListener(_invalidate);
    _excludedAreaCtrl.addListener(_invalidate);
    _customPercentCtrl.addListener(_invalidate);
    _tilesPerBoxCtrl.addListener(_onSecondaryChanged);
    _priceCtrl.addListener(_onSecondaryChanged);
  }

  void _invalidate() {
    if (!mounted) return;
    setState(() { _calculated = false; _error = null; });
  }

  void _onSecondaryChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _areaLengthCtrl.dispose();
    _areaWidthCtrl.dispose();
    _qtyCtrl.dispose();
    _excludedAreaCtrl.dispose();
    _tileLengthCtrl.dispose();
    _tileWidthCtrl.dispose();
    _tilesPerBoxCtrl.dispose();
    _priceCtrl.dispose();
    _customPercentCtrl.dispose();
    super.dispose();
  }

  // ── Getters ──
  double get _areaL => double.tryParse(_areaLengthCtrl.text) ?? 0;
  double get _areaW => double.tryParse(_areaWidthCtrl.text) ?? 0;
  int get _qty => int.tryParse(_qtyCtrl.text) ?? 0;
  double get _excludedArea =>
      double.tryParse(_excludedAreaCtrl.text) ?? 0;
  double toCm(double v) => _unit == _TileUnit.mm ? v / 10 : v;
  double get _tileLCm => _isCustomTile
      ? toCm(double.tryParse(_tileLengthCtrl.text) ?? 0)
      : _tilePreset.lengthCm;
  double get _tileWCm => _isCustomTile
      ? toCm(double.tryParse(_tileWidthCtrl.text) ?? 0)
      : _tilePreset.widthCm;

  double get _gross =>
      TileQuantityCalculator.grossAreaM2(lengthM: _areaL, widthM: _areaW, quantity: _qty);
  double get _net =>
      TileQuantityCalculator.netAreaM2(grossAreaM2: _gross, excludedAreaM2: _excludedArea);
  double get _tileArea =>
      TileQuantityCalculator.tileAreaM2(tileLengthCm: _tileLCm, tileWidthCm: _tileWCm);
  double get _raw =>
      TileQuantityCalculator.rawTileCount(netAreaM2: _net, tileAreaM2: _tileArea);
  int get _netTiles =>
      TileQuantityCalculator.netWholeTiles(rawTileCount: _raw);
  int get _finalTiles =>
      TileQuantityCalculator.finalTiles(rawTileCount: _raw, additionalPercent: _additionalPercent);
  int get _additional =>
      TileQuantityCalculator.additionalTiles(rawTileCount: _raw, additionalPercent: _additionalPercent);
  double get _tilesPerM2 =>
      TileQuantityCalculator.tilesPerM2(tileAreaM2: _tileArea);
  int get _tpb => int.tryParse(_tilesPerBoxCtrl.text) ?? 0;
  int get _boxes =>
      TileQuantityCalculator.requiredBoxes(finalTiles: _finalTiles, tilesPerBox: _tpb);
  double? get _price => double.tryParse(_priceCtrl.text);

  String get _percentLabel {
    final p = _additionalPercent;
    return p == p.truncateToDouble() ? p.toInt().toString() : p.toString();
  }

  // ── Calculate ──
  void _calc() {
    if (_areaL <= 0 || _areaW <= 0) {
      setState(() { _error = Ar.invalidInputs; _calculated = false; });
      return;
    }
    if (_qty <= 0) {
      setState(() { _error = Ar.invalidQuantity; _calculated = false; });
      return;
    }
    if (_tileLCm <= 0 || _tileWCm <= 0) {
      setState(() { _error = Ar.invalidInputs; _calculated = false; });
      return;
    }
    if (_excludedArea < 0 || _excludedArea >= _gross) {
      setState(() { _error = Ar.tileExcludedExceed; _calculated = false; });
      return;
    }
    if (_isCustomPercent) {
      final pct = double.tryParse(_customPercentCtrl.text);
      if (pct == null || pct < 0) {
        setState(() { _error = Ar.invalidInputs; _calculated = false; });
        return;
      }
      setState(() {
        _additionalPercent = pct;
        _error = null;
        _calculated = true;
      });
      return;
    }
    setState(() { _error = null; _calculated = true; });
  }

  void _reset() {
    _areaLengthCtrl.clear();
    _areaWidthCtrl.clear();
    _qtyCtrl.text = '1';
    _excludedAreaCtrl.clear();
    _tileLengthCtrl.clear();
    _tileWidthCtrl.clear();
    _tilesPerBoxCtrl.clear();
    _priceCtrl.clear();
    _customPercentCtrl.clear();
    setState(() {
      _unit = _TileUnit.cm;
      _tilePreset = _TilePreset.default_;
      _isCustomTile = false;
      _additionalPercent = 0;
      _isCustomPercent = false;
      _showBoxEstimate = false;
      _showCost = false;
      _priceMode = _PriceMode.perTile;
      _calculated = false;
      _error = null;
    });
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(Ar.tileCalc, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: Ar.reset,
              color: Colors.white, onPressed: _reset),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildInputCard(theme),
          if (_calculated) ...[AppSpacing.gapLg, _buildResultsCard(theme)],
          if (_error != null) ...[
            AppSpacing.gapMd,
            CalculatorErrorCard(message: _error!),
          ],
          AppSpacing.gapLg,
          _buildEstimatesCard(theme),
          AppSpacing.gapXl,
        ],
      ),
      bottomNavigationBar: _calculated ? _buildBottomBar(theme) : null,
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.12), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Icon(Icons.grid_view, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Ar.finalTileCount,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_finalTiles',
                  key: const Key('tile_bottom_bar_value'),
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Tile presets
          Text(Ar.tilePresets, style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final p in _TilePreset.presets)
              ChoiceChip(
                label: Text('${p.label} ${Ar.unitCm}'),
                selected: !_isCustomTile && _tilePreset == p,
                onSelected: (_) => setState(() { _tilePreset = p; _isCustomTile = false; _calculated = false; _error = null; }),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(color: !_isCustomTile && _tilePreset == p ? AppColors.primary : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ChoiceChip(
              label: Text(Ar.tileCustomSize),
              selected: _isCustomTile,
              onSelected: (_) => setState(() { _isCustomTile = true; _calculated = false; _error = null; }),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: _isCustomTile ? AppColors.primary : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ]),
          if (_isCustomTile) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ChoiceChip(label: Text(Ar.unitCm), selected: _unit == _TileUnit.cm,
                  onSelected: (_) => setState(() { _unit = _TileUnit.cm; _calculated = false; _error = null; }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: _unit == _TileUnit.cm ? AppColors.primary : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Expanded(child: ChoiceChip(label: Text(Ar.unitMm), selected: _unit == _TileUnit.mm,
                  onSelected: (_) => setState(() { _unit = _TileUnit.mm; _calculated = false; _error = null; }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: _unit == _TileUnit.mm ? AppColors.primary : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 12),
            _buildField('${Ar.tileLength} (${_unit == _TileUnit.mm ? Ar.unitMm : Ar.unitCm})', _tileLengthCtrl, theme),
            const SizedBox(height: 8),
            _buildField('${Ar.tileWidth} (${_unit == _TileUnit.mm ? Ar.unitMm : Ar.unitCm})', _tileWidthCtrl, theme),
          ],
          const SizedBox(height: 12),
          // Surface
          Text('${Ar.areaCoverage} (${Ar.squareMeters})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildField('${Ar.areaLength} (${Ar.meters})', _areaLengthCtrl, theme),
          const SizedBox(height: 8),
          _buildField('${Ar.areaWidth} (${Ar.meters})', _areaWidthCtrl, theme),
          const SizedBox(height: 8),
          _buildFieldInt(Ar.tileQuantity, _qtyCtrl, theme),
          const SizedBox(height: 8),
          _buildField(Ar.tileExcludedArea, _excludedAreaCtrl, theme),
          const SizedBox(height: 16),
          // Additional %
          Text(Ar.wastePercent, style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final pct in [0, 3, 5, 7, 10])
              ChoiceChip(
                label: Text('$pct%'),
                selected: !_isCustomPercent && _additionalPercent == pct,
                onSelected: (_) => setState(() { _additionalPercent = pct.toDouble(); _isCustomPercent = false; _calculated = false; _error = null; }),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(color: !_isCustomPercent && _additionalPercent == pct ? AppColors.primary : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ChoiceChip(
              label: Text(Ar.tileCustomSize),
              selected: _isCustomPercent,
              onSelected: (_) => setState(() { _isCustomPercent = true; _calculated = false; _error = null; }),
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: _isCustomPercent ? AppColors.primary : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ]),
          if (_isCustomPercent) ...[
            const SizedBox(height: 8),
            _buildField(Ar.wastePercent, _customPercentCtrl, theme),
          ],
          const SizedBox(height: 16),
          CalculatorPrimaryButton(
            onPressed: _calc,
            label: Ar.calcTile,
          ),
        ]),
      ),
    );
  }

  Widget _buildResultsCard(ThemeData theme) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Ar.result, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _row('${Ar.areaCoverage}:', '${_gross.toStringAsFixed(2)} ${Ar.squareMeters}', theme),
          if (_excludedArea > 0)
            _row('${Ar.tileExcludedDeducted}:', '${_excludedArea.toStringAsFixed(2)} ${Ar.squareMeters}', theme),
          _row('${Ar.areaCoverage}:', '${_net.toStringAsFixed(2)} ${Ar.squareMeters}', theme, isBold: true),
          if (_tileArea > 0)
            _row('${Ar.tileUnitArea}:', '${_tileArea.toStringAsFixed(4)} ${Ar.squareMeters}', theme),
          if (_tilesPerM2 > 0)
            _row('${Ar.tileUnitArea}:', _tilesPerM2.toStringAsFixed(1), theme),
          const Divider(height: 24),
          _row('${Ar.requiredTiles}:', '$_netTiles', theme),
          if (_additionalPercent > 0)
            _row('${Ar.tileAdditionalQuantity} ($_percentLabel%):', '$_additional', theme),
          _row('${Ar.finalTileCount}:', '$_finalTiles', theme, isBold: true),
        ]),
      ),
    );
  }

  Widget _buildEstimatesCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Box Estimate
          Row(children: [
            Expanded(child: Text(Ar.tileBoxEstimate, style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontWeight: FontWeight.w600))),
            Switch(value: _showBoxEstimate, activeColor: AppColors.primary,
                onChanged: (v) => setState(() { _showBoxEstimate = v; })),
          ]),
          if (_showBoxEstimate) ...[
            const SizedBox(height: 8),
            _buildFieldInt(Ar.tileTilesPerBoxLabel, _tilesPerBoxCtrl, theme),
            if (_calculated && _tpb > 0) ...[
              const SizedBox(height: 12),
              _row('${Ar.requiredBoxes}:', '$_boxes', theme),
            ],
          ],
          const Divider(height: 32),
          // Cost Estimate
          Row(children: [
            Expanded(child: Text(Ar.tileCostEstimate, style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontWeight: FontWeight.w600))),
            Switch(value: _showCost, activeColor: AppColors.primary,
                onChanged: (v) => setState(() { _showCost = v; if (!v) _priceCtrl.clear(); })),
          ]),
          if (_showCost) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ChoiceChip(label: Text(Ar.pricePerTile), selected: _priceMode == _PriceMode.perTile,
                  onSelected: (_) => setState(() { _priceMode = _PriceMode.perTile; _priceCtrl.clear(); }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: _priceMode == _PriceMode.perTile ? AppColors.primary : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Expanded(child: ChoiceChip(label: Text(Ar.pricePerBox), selected: _priceMode == _PriceMode.perBox,
                  onSelected: (_) => setState(() { _priceMode = _PriceMode.perBox; _priceCtrl.clear(); }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: _priceMode == _PriceMode.perBox ? AppColors.primary : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 8),
            _buildField(
                _priceMode == _PriceMode.perTile ? Ar.pricePerTile : Ar.pricePerBox,
                _priceCtrl, theme),
            if (_calculated && _price != null && _price! > 0) ...[
              const SizedBox(height: 12),
              Text(Ar.tilePriceEstimate, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_priceMode == _PriceMode.perTile) ...[
                _row('${Ar.totalCost}:',
                    TileQuantityCalculator.estimatedCostPerTile(finalTiles: _finalTiles, pricePerTile: _price!).toStringAsFixed(0), theme, isBold: true),
              ],
              if (_priceMode == _PriceMode.perBox && _tpb > 0) ...[
                _row('${Ar.totalCost}:',
                    TileQuantityCalculator.estimatedCostPerBox(requiredBoxes: _boxes, pricePerBox: _price!).toStringAsFixed(0), theme, isBold: true),
              ],
            ],
          ],
        ]),
      ),
    );
  }

  Widget _row(String label, String value, ThemeData theme, {bool isBold = false}) {
    return CalculatorResultRow(
      label: label,
      value: value,
      isBold: isBold,
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label, hintText: '0',
          hintStyle: TextStyle(color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withValues(alpha: 0.4)),
          filled: true, fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildFieldInt(String label, TextEditingController ctrl, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label, hintText: '1',
          hintStyle: TextStyle(color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withValues(alpha: 0.4)),
          filled: true, fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }
}
