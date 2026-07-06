import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../localization/ar.dart';

const Color _fieldFill = AppColors.surface;

class CalculatorScreen extends StatefulWidget {
  final String type;

  const CalculatorScreen({super.key, required this.type});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _ElementCardData {
  String elementType = 'column';
  final lengthCtrl = TextEditingController();
  final widthCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final columnCountCtrl = TextEditingController();
  double volume = 0;
  String? error;

  _ElementCardData();

  void dispose() {
    lengthCtrl.dispose();
    widthCtrl.dispose();
    heightCtrl.dispose();
    columnCountCtrl.dispose();
  }
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // --- concrete multi-calc state ---
  final List<_ElementCardData> _cards = [];

  // --- waste factor ---
  double _wastePercent = 0;
  final _customWasteCtrl = TextEditingController();
  bool _isCustomWaste = false;

  // --- truck capacity ---
  double _truckCapacity = 8;

  // --- cost estimation ---
  final _costPerCubicCtrl = TextEditingController();
  bool _showCost = false;

  // --- simple calc state (steel, brick) ---
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _diameterCtrl = TextEditingController();
  String? _result;
  String _brickSize = '20×20×40';
  final List<String> _brickSizes = ['20×20×40', '10×20×40', '15×20×40', '25×12×6'];

  // --- steel calculator state ---
  int _steelDiameter = 12;
  double _steelWastePercent = 0;
  final _steelCustomWasteCtrl = TextEditingController();
  bool _steelIsCustomWaste = false;
  final _steelCostPerKgCtrl = TextEditingController();
  bool _showSteelCost = false;
  final _steelStockLengthCtrl = TextEditingController(text: '12');
  bool _steelCalculated = false;
  String? _steelError;

  String get _title {
    switch (widget.type) {
      case 'concrete':
        return Ar.concreteCalc;
      case 'steel':
        return Ar.steelWeightCalc;
      case 'brick':
        return Ar.brickCalc;
      default:
        return '';
    }
  }

  List<Map<String, String>> get _elementTypes => [
    {'value': 'column', 'label': Ar.columnLabel},
    {'value': 'slab', 'label': Ar.slabLabel},
    {'value': 'circular_column', 'label': Ar.circularColumnLabel},
    {'value': 'beam', 'label': Ar.beamLabel},
    {'value': 'footing', 'label': Ar.footingLabel},
  ];

  static bool _isCircular(String type) => type == 'circular_column';

  static const Map<int, double> _steelWeightPerMeter = {
    8: 0.395,
    10: 0.617,
    12: 0.888,
    16: 1.58,
    20: 2.47,
    25: 3.85,
    32: 6.31,
  };

  @override
  void initState() {
    super.initState();
    if (widget.type == 'concrete') {
      _cards.add(_ElementCardData());
    }
  }

  void _addCard() {
    setState(() => _cards.add(_ElementCardData()));
  }

  void _removeCard(int index) {
    setState(() {
      _cards[index].dispose();
      _cards.removeAt(index);
    });
  }

  void _calcCard(int index) {
    final card = _cards[index];
    final l = double.tryParse(card.lengthCtrl.text) ?? 0;
    final w = double.tryParse(card.widthCtrl.text) ?? 0;
    final h = double.tryParse(card.heightCtrl.text) ?? 0;

    if (l <= 0 || h <= 0 || (!_isCircular(card.elementType) && w <= 0)) {
      setState(() {
        card.volume = 0;
        card.error = Ar.invalidInputs;
      });
      return;
    }

    double vol;
    if (_isCircular(card.elementType)) {
      vol = math.pi * (l / 2) * (l / 2) * h;
    } else {
      vol = l * w * h;
    }

    if (card.elementType == 'column') {
      final count = int.tryParse(card.columnCountCtrl.text) ?? 1;
      vol *= count;
    }

    setState(() {
      card.volume = vol;
      card.error = null;
    });
  }

  double get _grandTotal => _cards.fold<double>(0, (sum, card) => sum + card.volume);

  double get _netTotal => _grandTotal;
  double get _wasteVolume => _netTotal * _wastePercent / 100;
  double get _totalRequired => _netTotal + _wasteVolume;
  int get _truckCount => (_totalRequired / _truckCapacity).ceil();
  double? get _totalConcreteCost {
    final cost = double.tryParse(_costPerCubicCtrl.text);
    if (cost == null || cost <= 0 || !_showCost) return null;
    return _totalRequired * cost;
  }

  // --- steel getters ---
  double get _steelLen => double.tryParse(_lengthCtrl.text) ?? 0;
  int get _steelBars => int.tryParse(_qtyCtrl.text) ?? 0;
  double get _steelWPM => 0.00617 * _steelDiameter * _steelDiameter;
  double get _steelTotalLen => _steelLen * _steelBars;
  double get _steelNetW => _steelTotalLen * _steelWPM;
  double get _steelWasteW => _steelNetW * _steelWastePercent / 100;
  double get _steelTotalW => _steelNetW + _steelWasteW;
  double? get _steelPriceKg => double.tryParse(_steelCostPerKgCtrl.text);
  bool get _steelHasCost => _showSteelCost && _steelPriceKg != null && _steelPriceKg! > 0;
  double get _steelStockLen => double.tryParse(_steelStockLengthCtrl.text) ?? 12;
  int get _steelReqBars => _steelStockLen > 0 ? (_steelTotalLen / _steelStockLen).ceil() : 0;
  double get _steelPurchLen => _steelReqBars * _steelStockLen;
  double get _steelRemainLen => _steelPurchLen - _steelTotalLen;
  double get _steelPurchW => _steelPurchLen * _steelWPM;

  String _firstFieldLabel(_ElementCardData card) =>
      _isCircular(card.elementType) ? Ar.diameter : Ar.length;

  String _assetPath(String type) {
    switch (type) {
      case 'column':
        return 'assets/images/column.png';
      case 'slab':
        return 'assets/images/slab.png';
      case 'footing':
        return 'assets/images/footing.png';
      case 'beam':
        return 'assets/images/beam.png';
      case 'circular_column':
        return 'assets/images/circular_column.png';
      default:
        return 'assets/images/column.png';
    }
  }

  IconData _placeholderIcon(String type) {
    switch (type) {
      case 'column':
        return Icons.view_column;
      case 'slab':
        return Icons.grid_on;
      case 'circular_column':
        return Icons.radio_button_unchecked;
      case 'beam':
        return Icons.view_headline;
      case 'footing':
        return Icons.square_foot;
      default:
        return Icons.architecture;
    }
  }

  // --- simple calc methods ---

  void _calculate() {
    switch (widget.type) {
      case 'steel':
        _calcSteel();
        break;
      case 'brick':
        _calcBrick();
        break;
    }
  }

  // Legacy method kept intentionally for backward compatibility.
  void _calcSteel() {
    final l = double.tryParse(_lengthCtrl.text) ?? 0;
    final q = double.tryParse(_qtyCtrl.text) ?? 0;
    final d = double.tryParse(_diameterCtrl.text) ?? 0;
    if (l <= 0 || q <= 0 || d <= 0) {
      setState(() => _result = Ar.enterPositiveValues);
      return;
    }
    final w = l * q * 0.00617 * (d * d);
    final display = w >= 1000
        ? '${(w / 1000).toStringAsFixed(2)} ${Ar.tons}'
        : '${w.toStringAsFixed(2)} ${Ar.kg}';
    setState(() => _result = '${Ar.weight}: $display');
  }

  void _calcBrick() {
    final l = double.tryParse(_lengthCtrl.text) ?? 0;
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    if (l <= 0 || h <= 0) {
      setState(() => _result = Ar.invalidInputs);
      return;
    }
    final parts = _brickSize.split('×');
    final bL = double.tryParse(parts[2]) ?? 0.4;
    final bH = double.tryParse(parts[0]) ?? 0.2;
    final area = l * h;
    final brickArea = (bL / 100) * (bH / 100);
    final bricks = (area / brickArea).ceil();
    final mortar = area * 0.02;
    setState(
      () => _result =
          '${Ar.bricksCount}: $bricks\n${Ar.mortarQuantity}: ${mortar.toStringAsFixed(2)} ${Ar.cubicMeters}',
    );
  }

  void _calcSteelWeight() {
    if (_steelLen <= 0 || _steelBars <= 0 || _steelWPM <= 0) {
      setState(() {
        _steelError = Ar.invalidInputs;
        _steelCalculated = false;
      });
      return;
    }
    setState(() {
      _steelError = null;
      _steelCalculated = true;
    });
  }

  @override
  void dispose() {
    for (final card in _cards) {
      card.dispose();
    }
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _qtyCtrl.dispose();
    _diameterCtrl.dispose();
    _customWasteCtrl.dispose();
    _costPerCubicCtrl.dispose();
    _steelCustomWasteCtrl.dispose();
    _steelCostPerKgCtrl.dispose();
    _steelStockLengthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'concrete') return _buildConcreteScreen();
    if (widget.type == 'steel') return _buildSteelScreen();
    return _buildSimpleScreen();
  }

  // ───────────── multi-card concrete screen ─────────────

  Widget _buildConcreteScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildInfoHeader(theme),
          AppSpacing.gapLg,
          ...List.generate(_cards.length, (i) => _buildCard(i, theme)),
          AppSpacing.gapMd,
          _buildAddButton(theme),
          AppSpacing.gapLg,
          _buildOptionsCard(theme),
          AppSpacing.gapXl,
        ],
      ),
      bottomNavigationBar: _buildGrandTotalBar(theme),
    );
  }

  Widget _buildInfoHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              Ar.addElementsInfo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index, ThemeData theme) {
    final card = _cards[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Illustration section
            _buildIllustration(card),
            // Divider
            Container(height: 1, color: AppColors.primary.withValues(alpha: 0.08)),
            // Card body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(index, theme),
                  AppSpacing.gapMd,
                  _buildTypeDropdown(card, theme),
                  AppSpacing.gapMd,
                  _buildCardField(_firstFieldLabel(card), card.lengthCtrl),
                  if (!_isCircular(card.elementType)) ...[
                    AppSpacing.gapSm,
                    _buildCardField(Ar.width, card.widthCtrl),
                  ],
                  AppSpacing.gapSm,
                  _buildCardField(
                    card.elementType == 'slab' ? Ar.thickness : Ar.height,
                    card.heightCtrl,
                  ),
                  // Conditional "Number of Columns" field
                  if (card.elementType == 'column') ...[
                    AppSpacing.gapSm,
                    _buildCardField(Ar.numberOfColumns, card.columnCountCtrl,
                        isInteger: true),
                  ],
                  AppSpacing.gapMd,
                  _buildCalcButton(index, theme),
                  if (card.error != null) _buildErrorResult(card, theme),
                  if (card.volume > 0 && card.error == null)
                    _buildVolumeResult(card, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(_ElementCardData card) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusMd),
          topRight: Radius.circular(DesignTokens.radiusMd),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        _assetPath(card.elementType),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(
            _placeholderIcon(card.elementType),
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(int index, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
          child: Text(
            '${Ar.element} ${index + 1}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: () => _removeCard(index),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close, size: 20, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown(_ElementCardData card, ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: card.elementType,
      decoration: _inputDecoration(Ar.elementType),
      items: _elementTypes
          .map(
            (e) => DropdownMenuItem(
              value: e['value'],
              child: Text(e['label']!,
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() {
            card.elementType = v;
            card.lengthCtrl.clear();
            card.widthCtrl.clear();
            card.heightCtrl.clear();
            card.columnCountCtrl.clear();
            card.volume = 0;
            card.error = null;
          });
        }
      },
    );
  }

  Widget _buildCalcButton(int index, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _calcCard(index),
        icon: const Icon(Icons.calculate, size: 20),
        label: Text(Ar.calculate),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorResult(_ElementCardData card, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          card.error!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildVolumeResult(_ElementCardData card, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Text(
          '${Ar.volume}: ${card.volume.toStringAsFixed(2)} ${Ar.cubicMeters}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAddButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _addCard,
      icon: Icon(Icons.add_circle_outline, size: 22, color: AppColors.primary),
      label: Text(Ar.addElement,
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),
    );
  }

  Widget _buildOptionsCard(ThemeData theme) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.options,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Waste Factor
            Text(
              Ar.wasteFactor,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final pct in [0, 3, 5, 7])
                  ChoiceChip(
                    label: Text('$pct%'),
                    selected: !_isCustomWaste && _wastePercent == pct,
                    onSelected: (_) => setState(() {
                      _wastePercent = pct.toDouble();
                      _isCustomWaste = false;
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: !_isCustomWaste && _wastePercent == pct
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ChoiceChip(
                  label: Text(Ar.wasteCustom),
                  selected: _isCustomWaste,
                  onSelected: (_) => setState(() => _isCustomWaste = true),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _isCustomWaste ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_isCustomWaste) ...[
              const SizedBox(height: 8),
              _buildCardField(Ar.wasteFactor, _customWasteCtrl),
            ],
            const Divider(height: 32),
            // Truck Capacity
            Text(
              Ar.truckCapacity,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final cap in [6, 8, 10])
                  ChoiceChip(
                    label: Text('$cap m³'),
                    selected: _truckCapacity == cap,
                    onSelected: (_) =>
                        setState(() => _truckCapacity = cap.toDouble()),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _truckCapacity == cap ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),
            // Cost Estimation
            Row(
              children: [
                Expanded(
                  child: Text(
                    Ar.costPerCubic,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _showCost,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _showCost = v),
                ),
              ],
            ),
            if (_showCost) ...[
              const SizedBox(height: 8),
              _buildCardField(Ar.costPerCubic, _costPerCubicCtrl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrandTotalBar(ThemeData theme) {
    final hasResults = _cards.isNotEmpty && _cards.any((c) => c.volume > 0);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.12), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            child: Icon(Icons.calculate, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Ar.grandTotal,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_totalRequired.toStringAsFixed(2)} ${Ar.cubicMeters}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasResults) ...[
                  const SizedBox(height: 6),
                  if (_wastePercent > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${Ar.netVolume}: ${_netTotal.toStringAsFixed(2)} ${Ar.cubicMeters}  |  ${Ar.wasteVolume} ($_wastePercent%): ${_wasteVolume.toStringAsFixed(2)} ${Ar.cubicMeters}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  Text(
                    _showCost && _totalConcreteCost != null
                        ? '${Ar.truckCount} (${_truckCapacity}m³): $_truckCount  |  ${Ar.concreteCost}: ${_totalConcreteCost!.toStringAsFixed(0)}'
                        : '${Ar.truckCount} (${_truckCapacity}m³): $_truckCount',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Text(
              '${_cards.length} ${Ar.element}',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── steel calculator screen ─────────────

  Widget _buildSteelScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildSteelInputCard(theme),
          AppSpacing.gapLg,
          _buildSteelOptionsCard(theme),
          if (_steelCalculated) ...[
            AppSpacing.gapLg,
            _buildSteelResultsCard(theme),
          ],
          if (_steelError != null) ...[
            AppSpacing.gapMd,
            _buildSteelErrorCard(theme),
          ],
          AppSpacing.gapXl,
        ],
      ),
      bottomNavigationBar: _buildSteelBottomBar(theme),
    );
  }

  Widget _buildSteelInputCard(ThemeData theme) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.steelInputSection,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCardField(Ar.length, _lengthCtrl),
            const SizedBox(height: 8),
            _buildCardField(Ar.quantity, _qtyCtrl, isInteger: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _steelDiameter,
              decoration: _inputDecoration(Ar.diameter),
              items: _steelWeightPerMeter.keys
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text('$d ${Ar.unitMm}'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _steelDiameter = v;
                    _steelCalculated = false;
                    _steelError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${Ar.steelWeightPerMeter}: ${_steelWPM.toStringAsFixed(3)} ${Ar.kg}/${Ar.meters}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calcSteelWeight,
                icon: const Icon(Icons.calculate, size: 20),
                label: Text(Ar.calculate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSteelOptionsCard(ThemeData theme) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.options,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Ar.wasteFactor,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final pct in [0, 3, 5, 7])
                  ChoiceChip(
                    label: Text('$pct%'),
                    selected:
                        !_steelIsCustomWaste && _steelWastePercent == pct,
                    onSelected: (_) => setState(() {
                      _steelWastePercent = pct.toDouble();
                      _steelIsCustomWaste = false;
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: !_steelIsCustomWaste && _steelWastePercent == pct
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ChoiceChip(
                  label: Text(Ar.wasteCustom),
                  selected: _steelIsCustomWaste,
                  onSelected: (_) =>
                      setState(() => _steelIsCustomWaste = true),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _steelIsCustomWaste ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_steelIsCustomWaste) ...[
              const SizedBox(height: 8),
              _buildCardField(Ar.wasteFactor, _steelCustomWasteCtrl),
            ],
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    Ar.steelPricePerKg,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _showSteelCost,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _showSteelCost = v),
                ),
              ],
            ),
            if (_showSteelCost) ...[
              const SizedBox(height: 8),
              _buildCardField(Ar.steelPricePerKg, _steelCostPerKgCtrl),
            ],
            const Divider(height: 32),
            Text(
              Ar.steelProcurementSection,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildCardField(Ar.steelStockLength, _steelStockLengthCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildSteelResultsCard(ThemeData theme) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.steelResults,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _steelResultRow(
                '${Ar.diameter}:', '$_steelDiameter ${Ar.unitMm}'),
            _steelResultRow('${Ar.steelWeightPerMeter}:',
                '${_steelWPM.toStringAsFixed(3)} ${Ar.kg}/${Ar.meters}'),
            _steelResultRow(
                '${Ar.length}:', '${_steelLen.toStringAsFixed(2)} ${Ar.meters}'),
            _steelResultRow('${Ar.quantity}:', '$_steelBars'),
            _steelResultRow('${Ar.steelTotalLength}:',
                '${_steelTotalLen.toStringAsFixed(2)} ${Ar.meters}'),
            const Divider(height: 24),
            _steelResultRow('${Ar.steelNetWeight}:',
                '${_steelNetW.toStringAsFixed(2)} ${Ar.kg}'),
            if (_steelWastePercent > 0)
              _steelResultRow(
                  '${Ar.steelWasteWeight} ($_steelWastePercent%):',
                  '${_steelWasteW.toStringAsFixed(2)} ${Ar.kg}'),
            _steelResultRow('${Ar.steelTotalRequiredWeight}:',
                '${_steelTotalW.toStringAsFixed(2)} ${Ar.kg}',
                isBold: true),
            _steelResultRow('${Ar.steelTotalTons}:',
                '${(_steelTotalW / 1000).toStringAsFixed(3)} ${Ar.tons}'),
            if (_steelHasCost) ...[
              const Divider(height: 24),
              _steelResultRow('${Ar.steelNetCost}:',
                  (_steelNetW * _steelPriceKg!).toStringAsFixed(0)),
              if (_steelWastePercent > 0)
                _steelResultRow('${Ar.steelWasteCost}:',
                    (_steelWasteW * _steelPriceKg!).toStringAsFixed(0)),
              _steelResultRow('${Ar.steelTotalCost}:',
                  (_steelTotalW * _steelPriceKg!).toStringAsFixed(0),
                  isBold: true),
            ],
            if (_steelTotalLen > 0) ...[
              const Divider(height: 24),
              Text(
                Ar.steelProcurementSection,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _steelResultRow('${Ar.steelStockLength}:',
                  '${_steelStockLen.toStringAsFixed(2)} ${Ar.meters}'),
              _steelResultRow('${Ar.steelTotalLength}:',
                  '${_steelTotalLen.toStringAsFixed(2)} ${Ar.meters}'),
              _steelResultRow(
                  '${Ar.steelBarsRequired}:', '$_steelReqBars'),
              _steelResultRow('${Ar.steelPurchasedLength}:',
                  '${_steelPurchLen.toStringAsFixed(2)} ${Ar.meters}'),
              _steelResultRow('${Ar.steelRemainingLength}:',
                  '${_steelRemainLen.toStringAsFixed(2)} ${Ar.meters}'),
              _steelResultRow('${Ar.steelPurchasedWeight}:',
                  '${_steelPurchW.toStringAsFixed(2)} ${Ar.kg}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSteelErrorCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        _steelError!,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSteelBottomBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.12), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            child: Icon(Icons.build, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Ar.weight,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _steelCalculated
                      ? '${_steelTotalW.toStringAsFixed(2)} ${Ar.kg} / ${(_steelTotalW / 1000).toStringAsFixed(3)} ${Ar.tons}'
                      : '0.00 ${Ar.kg} / 0.000 ${Ar.tons}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Text(
              '$_steelDiameter ${Ar.unitMm}',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _steelResultRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }

  Widget _buildCardField(String label, TextEditingController ctrl,
      {bool isInteger = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        if (isInteger)
          FilteringTextInputFormatter.digitsOnly
        else
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      textAlign: TextAlign.start,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      hintText: '0.0',
      hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.4)),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  // ───────────── simple calc screen (steel / brick) ─────────────

  Widget _buildSimpleScreen() {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(Ar.length, _lengthCtrl),
                if (widget.type != 'brick') _buildField(Ar.width, _widthCtrl),
                _buildField(Ar.height, _heightCtrl),
                if (widget.type == 'steel') ...[
                  _buildField(Ar.quantity, _qtyCtrl),
                  _buildField(Ar.diameter, _diameterCtrl),
                ],
                if (widget.type == 'brick') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _brickSize,
                    decoration: InputDecoration(
                      labelText: Ar.brickSizeLabel,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: _brickSizes
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text('$s ${Ar.cm}')))
                        .toList(),
                    onChanged: (v) => setState(() => _brickSize = v!),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    child: Text(Ar.calculate),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.cardRadius),
                    ),
                    child: Text(
                      _result!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        textAlign: TextAlign.start,
        decoration: InputDecoration(
          labelText: label,
          hintText: '0.0',
        ),
      ),
    );
  }
}
