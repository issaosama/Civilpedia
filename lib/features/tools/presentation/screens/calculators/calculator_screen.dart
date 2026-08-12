import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../localization/ar.dart';
import '../../widgets/calculator/calculator_error_card.dart';
import '../../widgets/calculator/calculator_primary_button.dart';
import '../../widgets/calculator/calculator_result_row.dart';
import '../../../../tools/domain/concrete/concrete_volume_calculator.dart';
import '../../../../tools/domain/steel/steel_weight_calculator.dart';
import '../../../../tools/domain/masonry/masonry_quantity_calculator.dart';
import '../../../../tools/domain/masonry/masonry_presets.dart';

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
  final qtyCtrl = TextEditingController(text: '1');
  double singleVolume = 0;
  double netVolume = 0;
  String? error;

  _ElementCardData();

  void dispose() {
    lengthCtrl.dispose();
    widthCtrl.dispose();
    heightCtrl.dispose();
    qtyCtrl.dispose();
  }
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // --- concrete multi-calc state ---
  final List<_ElementCardData> _cards = [];

  // --- dimension unit (applies to every element card) ---
  ConcreteDimensionUnit _dimensionUnit = ConcreteDimensionUnit.meters;

  // --- additional percentage (waste) ---
  double _wastePercent = 0;
  final _customWasteCtrl = TextEditingController();
  bool _isCustomWaste = false;

  // --- optional supply & cost estimation ---
  final _truckCapacityCtrl = TextEditingController();
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
  static const List<int> _steelDiameterPresets = [
    6, 8, 10, 12, 14, 16, 18, 20, 22, 25, 28, 32, 36, 40,
  ];
  int _steelDiameter = 12;
  bool _steelIsCustomDiameter = false;
  final _steelCustomDiameterCtrl = TextEditingController();
  double _steelWastePercent = 0;
  final _steelCustomWasteCtrl = TextEditingController();
  bool _steelIsCustomWaste = false;
  final _steelCostPerTonCtrl = TextEditingController();
  bool _showSteelCost = false;
  final _steelStockLengthCtrl = TextEditingController(text: '12');
  bool _showSteelProcurement = false;
  bool _steelCalculated = false;
  String? _steelError;

  // --- brick calculator state ---
  MasonryType _masonryType = MasonryType.block;
  MasonryPreset _masonryPreset = MasonryPreset.block20x20x40;
  bool _isCustomMasonry = false;
  final _masonryCustomHeightCtrl = TextEditingController();
  final _masonryCustomLengthCtrl = TextEditingController();
  final _masonryOpeningsCtrl = TextEditingController();
  double _brickAdditionalPercent = 0;
  final _brickCustomPercentCtrl = TextEditingController();
  bool _brickIsCustomPercent = false;
  bool _brickCalculated = false;
  String? _brickError;

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
    {'value': 'wall', 'label': Ar.wallLabel},
    {'value': 'footing', 'label': Ar.footingLabel},
  ];

  static bool _isCircular(String type) => type == 'circular_column';

  static ConcreteElementType _enumType(String type) {
    switch (type) {
      case 'slab':
        return ConcreteElementType.slab;
      case 'column':
        return ConcreteElementType.column;
      case 'circular_column':
        return ConcreteElementType.circularColumn;
      case 'beam':
        return ConcreteElementType.beam;
      case 'wall':
        return ConcreteElementType.wall;
      case 'footing':
        return ConcreteElementType.footing;
      default:
        return ConcreteElementType.column;
    }
  }

  String get _unitSymbol => switch (_dimensionUnit) {
        ConcreteDimensionUnit.meters => Ar.meters,
        ConcreteDimensionUnit.centimeters => Ar.cm,
        ConcreteDimensionUnit.millimeters => Ar.unitMm,
      };

  @override
  void initState() {
    super.initState();
    if (widget.type == 'concrete') {
      _cards.add(_ElementCardData());
    } else if (widget.type == 'steel') {
      _lengthCtrl.text = '12';
      _qtyCtrl.text = '1';
      _lengthCtrl.addListener(_invalidateSteel);
      _qtyCtrl.addListener(_invalidateSteel);
      _steelCustomDiameterCtrl.addListener(_invalidateSteel);
      _steelCustomWasteCtrl.addListener(_invalidateSteel);
      _steelStockLengthCtrl.addListener(_onSecondaryInputChanged);
      _steelCostPerTonCtrl.addListener(_onSecondaryInputChanged);
    } else if (widget.type == 'brick') {
      _qtyCtrl.text = '1';
      _lengthCtrl.addListener(_invalidateBrick);
      _heightCtrl.addListener(_invalidateBrick);
      _qtyCtrl.addListener(_invalidateBrick);
      _masonryOpeningsCtrl.addListener(_invalidateBrick);
      _masonryCustomHeightCtrl.addListener(_invalidateBrick);
      _masonryCustomLengthCtrl.addListener(_invalidateBrick);
      _brickCustomPercentCtrl.addListener(_invalidateBrick);
    }
  }

  void _invalidateSteel() {
    if (!mounted) return;
    setState(() {
      _steelCalculated = false;
      _steelError = null;
    });
  }

  void _onSecondaryInputChanged() {
    if (!mounted) return;
    setState(() {});
  }

  // --- brick methods ---

  void _invalidateBrick() {
    if (!mounted) return;
    setState(() {
      _brickCalculated = false;
      _brickError = null;
    });
  }

  double get _brickLen => double.tryParse(_lengthCtrl.text) ?? 0;
  double get _brickHeight => double.tryParse(_heightCtrl.text) ?? 0;
  int get _brickQty => int.tryParse(_qtyCtrl.text) ?? 0;
  double get _brickOpenings =>
      double.tryParse(_masonryOpeningsCtrl.text) ?? 0;

  double get _brickFaceLengthCm => _isCustomMasonry
      ? (double.tryParse(_masonryCustomLengthCtrl.text) ?? 0)
      : _masonryPreset.faceLengthCm;
  double get _brickFaceHeightCm => _isCustomMasonry
      ? (double.tryParse(_masonryCustomHeightCtrl.text) ?? 0)
      : _masonryPreset.faceHeightCm;

  double get _brickGross =>
      MasonryQuantityCalculator.grossWallArea(
          lengthM: _brickLen, heightM: _brickHeight, quantity: _brickQty);
  double get _brickNet =>
      MasonryQuantityCalculator.netWallArea(
          grossAreaM2: _brickGross, openingsAreaM2: _brickOpenings);
  double get _brickModuleArea => MasonryQuantityCalculator.moduleFaceAreaM2(
      faceLengthCm: _brickFaceLengthCm, faceHeightCm: _brickFaceHeightCm);
  double get _brickRaw => MasonryQuantityCalculator.rawUnitCount(
      netAreaM2: _brickNet, moduleFaceAreaM2: _brickModuleArea);
  double get _brickUnitsPerM2 =>
      MasonryQuantityCalculator.unitsPerM2(moduleFaceAreaM2: _brickModuleArea);
  int get _brickNetUnits =>
      MasonryQuantityCalculator.netWholeUnits(rawUnitCount: _brickRaw);
  int get _brickFinalUnits => MasonryQuantityCalculator.finalUnits(
      rawUnitCount: _brickRaw, additionalPercent: _brickAdditionalPercent);
  int get _brickAdditionalUnits => MasonryQuantityCalculator.additionalUnits(
      rawUnitCount: _brickRaw, additionalPercent: _brickAdditionalPercent);

  String get _brickPercentLabel {
    final p = _brickAdditionalPercent;
    return p == p.truncateToDouble() ? p.toInt().toString() : p.toString();
  }

  void _calcBrickWeight() {
    if (_brickLen <= 0 || _brickHeight <= 0) {
      setState(() {
        _brickError = Ar.invalidInputs;
        _brickCalculated = false;
      });
      return;
    }
    if (_brickQty <= 0) {
      setState(() {
        _brickError = Ar.invalidQuantity;
        _brickCalculated = false;
      });
      return;
    }
    if (_brickFaceLengthCm <= 0 || _brickFaceHeightCm <= 0) {
      setState(() {
        _brickError = Ar.invalidInputs;
        _brickCalculated = false;
      });
      return;
    }
    if (_brickOpenings < 0 || _brickOpenings > _brickGross) {
      setState(() {
        _brickError = Ar.masonryOpeningsExceed;
        _brickCalculated = false;
      });
      return;
    }
    if (_brickIsCustomPercent) {
      final pct = double.tryParse(_brickCustomPercentCtrl.text);
      if (pct == null || pct < 0) {
        setState(() {
          _brickError = Ar.invalidInputs;
          _brickCalculated = false;
        });
        return;
      }
      setState(() {
        _brickAdditionalPercent = pct;
        _brickError = null;
        _brickCalculated = true;
      });
      return;
    }
    setState(() {
      _brickError = null;
      _brickCalculated = true;
    });
  }

  void _resetBrick() {
    _lengthCtrl.clear();
    _heightCtrl.clear();
    _qtyCtrl.text = '1';
    _masonryOpeningsCtrl.clear();
    _masonryCustomHeightCtrl.clear();
    _masonryCustomLengthCtrl.clear();
    _brickCustomPercentCtrl.clear();
    setState(() {
      _masonryType = MasonryType.block;
      _masonryPreset = MasonryPreset.block20x20x40;
      _isCustomMasonry = false;
      _brickAdditionalPercent = 0;
      _brickIsCustomPercent = false;
      _brickCalculated = false;
      _brickError = null;
    });
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
    final type = _enumType(card.elementType);
    final isCircular = type == ConcreteElementType.circularColumn;
    final l = double.tryParse(card.lengthCtrl.text) ?? 0;
    final w = double.tryParse(card.widthCtrl.text) ?? 0;
    final h = double.tryParse(card.heightCtrl.text) ?? 0;
    final qty = int.tryParse(card.qtyCtrl.text) ?? 0;

    final dimsValid = l > 0 && h > 0 && (isCircular || w > 0);
    final qtyValid = qty >= 1;

    if (!dimsValid || !qtyValid) {
      setState(() {
        card.singleVolume = 0;
        card.netVolume = 0;
        card.error = !dimsValid ? Ar.invalidInputs : Ar.invalidQuantity;
      });
      return;
    }

    final unitFactor = _dimensionUnit.factorToMeters;
    // Self-describing named dimensions: each element passes exactly the
    // dimensions its geometry needs, so diameter, height, width and thickness
    // can never be confused with one another.
    final single = switch (type) {
      ConcreteElementType.slab => ConcreteVolumeCalculator.singleElementVolume(
          type: type,
          length: l * unitFactor,
          width: w * unitFactor,
          thickness: h * unitFactor,
        ),
      ConcreteElementType.beam => ConcreteVolumeCalculator.singleElementVolume(
          type: type,
          length: l * unitFactor,
          width: w * unitFactor,
          height: h * unitFactor,
        ),
      ConcreteElementType.column => ConcreteVolumeCalculator.singleElementVolume(
          type: type,
          width: l * unitFactor,
          depth: w * unitFactor,
          height: h * unitFactor,
        ),
      ConcreteElementType.circularColumn =>
        ConcreteVolumeCalculator.singleElementVolume(
          type: type,
          diameter: l * unitFactor,
          height: h * unitFactor,
        ),
      ConcreteElementType.wall => ConcreteVolumeCalculator.singleElementVolume(
          type: type,
          length: l * unitFactor,
          thickness: w * unitFactor,
          height: h * unitFactor,
        ),
      ConcreteElementType.footing =>
        ConcreteVolumeCalculator.singleElementVolume(
          type: type,
          length: l * unitFactor,
          width: w * unitFactor,
          thickness: h * unitFactor,
        ),
    };
    final net = ConcreteVolumeCalculator.netVolume(volume: single, quantity: qty);

    setState(() {
      card.singleVolume = single;
      card.netVolume = net;
      card.error = null;
    });
  }

  double get _netTotal => _cards.fold<double>(0, (sum, card) => sum + card.netVolume);

  double get _effectiveWastePercent =>
      _isCustomWaste ? (double.tryParse(_customWasteCtrl.text) ?? 0) : _wastePercent;

  String get _effectiveWastePercentLabel {
    final p = _effectiveWastePercent;
    return p == p.truncateToDouble() ? p.toInt().toString() : p.toString();
  }
  double get _wasteVolume => _netTotal * _effectiveWastePercent / 100;
  double get _totalRequired => _netTotal + _wasteVolume;

  /// Null until the engineer provides a positive mixer/truck capacity.
  double? get _truckCapacity {
    final v = double.tryParse(_truckCapacityCtrl.text);
    if (v == null || v <= 0) return null;
    return v;
  }

  int? get _truckCount {
    final capacity = _truckCapacity;
    if (capacity == null) return null;
    return ConcreteVolumeCalculator.truckCount(
      totalVolume: _totalRequired,
      truckCapacity: capacity,
    );
  }

  double? get _totalConcreteCost {
    final cost = double.tryParse(_costPerCubicCtrl.text);
    if (cost == null || cost <= 0 || !_showCost) return null;
    return ConcreteVolumeCalculator.estimatedCost(
      totalVolume: _totalRequired,
      pricePerCubicMeter: cost,
    );
  }

  // --- steel getters ---
  String get _steelDiaLabel => _steelIsCustomDiameter
      ? _steelCustomDiameterCtrl.text
      : '$_steelDiameter';
  double get _steelDiameterMm => _steelIsCustomDiameter
      ? (double.tryParse(_steelCustomDiameterCtrl.text) ?? 0)
      : _steelDiameter.toDouble();
  double get _steelLen => double.tryParse(_lengthCtrl.text) ?? 0;
  int get _steelBars => int.tryParse(_qtyCtrl.text) ?? 0;
  double get _steelWPM =>
      SteelWeightCalculator.unitWeightKgPerM(diameterMm: _steelDiameterMm);
  double get _steelWeightPerBar => SteelWeightCalculator.weightPerBar(
      unitWeightKgPerM: _steelWPM, lengthM: _steelLen);
  double get _steelTotalLen =>
      SteelWeightCalculator.totalLengthM(lengthM: _steelLen, quantity: _steelBars);
  double get _steelNetW => SteelWeightCalculator.netWeightKg(
      totalLengthM: _steelTotalLen, unitWeightKgPerM: _steelWPM);
  double get _steelAdditionalW => SteelWeightCalculator.additionalWeightKg(
      netWeightKg: _steelNetW, additionalPercent: _steelWastePercent);
  double get _steelTotalW => SteelWeightCalculator.finalWeightKg(
      netWeightKg: _steelNetW, additionalPercent: _steelWastePercent);
  double get _steelFinalTon =>
      SteelWeightCalculator.finalWeightTon(finalWeightKg: _steelTotalW);
  String get _steelWastePercentLabel {
    final p = _steelWastePercent;
    return p == p.truncateToDouble() ? p.toInt().toString() : p.toString();
  }
  int get _steelBarsPerTon =>
      SteelWeightCalculator.barsPerTon(weightPerBarKg: _steelWeightPerBar);
  double? get _steelPriceTon => double.tryParse(_steelCostPerTonCtrl.text);
  bool get _steelHasCost => _showSteelCost && _steelPriceTon != null && _steelPriceTon! > 0;
  double get _steelStockLen => double.tryParse(_steelStockLengthCtrl.text) ?? 0;
  bool get _steelProcurementValid =>
      _steelStockLen > 0 && _steelStockLen >= _steelLen;
  int get _steelBarsPerStockBar => SteelWeightCalculator.barsPerStockBar(
      stockBarLengthM: _steelStockLen, barLengthM: _steelLen);
  int get _steelReqBars => _steelProcurementValid
      ? SteelWeightCalculator.requiredStockBars(
          barLengthM: _steelLen,
          quantity: _steelBars,
          stockBarLengthM: _steelStockLen)
      : 0;
  double get _steelPurchLen => SteelWeightCalculator.purchasedLengthM(
      stockBars: _steelReqBars, stockBarLengthM: _steelStockLen);
  double get _steelRemainLen => SteelWeightCalculator.remainingLengthM(
      purchasedLengthM: _steelPurchLen, requiredLengthM: _steelTotalLen);
  double get _steelPurchW => SteelWeightCalculator.purchasedWeightKg(
      purchasedLengthM: _steelPurchLen, unitWeightKgPerM: _steelWPM);

  /// Dimension fields and their explicit labels for the selected element type.
  /// Only the fields required by the geometry are shown.
  List<({String label, TextEditingController ctrl})> _fieldsFor(
      _ElementCardData card) {
    switch (card.elementType) {
      case 'slab':
        return [
          (label: Ar.length, ctrl: card.lengthCtrl),
          (label: Ar.width, ctrl: card.widthCtrl),
          (label: Ar.thickness, ctrl: card.heightCtrl),
        ];
      case 'column':
        return [
          (label: Ar.width, ctrl: card.lengthCtrl),
          (label: Ar.depth, ctrl: card.widthCtrl),
          (label: Ar.height, ctrl: card.heightCtrl),
        ];
      case 'circular_column':
        return [
          (label: Ar.diameter, ctrl: card.lengthCtrl),
          (label: Ar.height, ctrl: card.heightCtrl),
        ];
      case 'beam':
        return [
          (label: Ar.length, ctrl: card.lengthCtrl),
          (label: Ar.width, ctrl: card.widthCtrl),
          (label: Ar.height, ctrl: card.heightCtrl),
        ];
      case 'wall':
        return [
          (label: Ar.length, ctrl: card.lengthCtrl),
          (label: Ar.thickness, ctrl: card.widthCtrl),
          (label: Ar.height, ctrl: card.heightCtrl),
        ];
      case 'footing':
        return [
          (label: Ar.length, ctrl: card.lengthCtrl),
          (label: Ar.width, ctrl: card.widthCtrl),
          (label: Ar.thickness, ctrl: card.heightCtrl),
        ];
      default:
        return [
          (label: Ar.length, ctrl: card.lengthCtrl),
          (label: Ar.width, ctrl: card.widthCtrl),
          (label: Ar.height, ctrl: card.heightCtrl),
        ];
    }
  }

  void _resetAll() {
    setState(() {
      for (final card in _cards) {
        card.dispose();
      }
      _cards
        ..clear()
        ..add(_ElementCardData());
      _dimensionUnit = ConcreteDimensionUnit.meters;
      _wastePercent = 0;
      _isCustomWaste = false;
      _customWasteCtrl.clear();
      _truckCapacityCtrl.clear();
      _showCost = false;
      _costPerCubicCtrl.clear();
    });
  }

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
      case 'wall':
        return Icons.wallpaper;
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
    final w = l *
        q *
        SteelWeightCalculator.unitWeightKgPerM(diameterMm: d);
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
    if (_steelDiameterMm <= 0 || _steelLen <= 0) {
      setState(() {
        _steelError = Ar.invalidInputs;
        _steelCalculated = false;
      });
      return;
    }
    if (_steelBars <= 0) {
      setState(() {
        _steelError = Ar.invalidQuantity;
        _steelCalculated = false;
      });
      return;
    }
    if (_steelIsCustomWaste) {
      final pct = double.tryParse(_steelCustomWasteCtrl.text);
      if (pct == null || pct < 0) {
        setState(() {
          _steelError = Ar.invalidInputs;
          _steelCalculated = false;
        });
        return;
      }
      setState(() {
        _steelWastePercent = pct;
        _steelError = null;
        _steelCalculated = true;
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
    _truckCapacityCtrl.dispose();
    _costPerCubicCtrl.dispose();
    _steelCustomDiameterCtrl.dispose();
    _steelCustomWasteCtrl.dispose();
    _steelCostPerTonCtrl.dispose();
    _steelStockLengthCtrl.dispose();
    _masonryCustomHeightCtrl.dispose();
    _masonryCustomLengthCtrl.dispose();
    _masonryOpeningsCtrl.dispose();
    _brickCustomPercentCtrl.dispose();
    super.dispose();
  }

  void _resetSteel() {
    _lengthCtrl.text = '12';
    _qtyCtrl.text = '1';
    _steelCustomDiameterCtrl.clear();
    _steelCustomWasteCtrl.clear();
    _steelCostPerTonCtrl.clear();
    _steelStockLengthCtrl.text = '12';
    setState(() {
      _steelDiameter = 12;
      _steelIsCustomDiameter = false;
      _steelWastePercent = 0;
      _steelIsCustomWaste = false;
      _showSteelProcurement = false;
      _showSteelCost = false;
      _steelCalculated = false;
      _steelError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'concrete') return _buildConcreteScreen();
    if (widget.type == 'steel') return _buildSteelScreen();
    if (widget.type == 'brick') return _buildBrickScreen();
    return _buildSimpleScreen();
  }

  // ───────────── multi-card concrete screen ─────────────

  Widget _buildConcreteScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: Ar.reset,
            color: Colors.white,
            onPressed: _resetAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildInfoHeader(theme),
          AppSpacing.gapLg,
          _buildUnitSelector(theme),
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

  Widget _buildUnitSelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.dimensionUnit,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final unit in ConcreteDimensionUnit.values)
                  ChoiceChip(
                    label: Text(_unitLabel(unit)),
                    selected: _dimensionUnit == unit,
                    onSelected: (_) => setState(() {
                      _dimensionUnit = unit;
                      // Results are stale: dimensions are now read in the new unit.
                      for (final card in _cards) {
                        card.singleVolume = 0;
                        card.netVolume = 0;
                        card.error = null;
                      }
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _dimensionUnit == unit
                          ? AppColors.primary
                          : isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Ar.dimensionUnitHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _unitLabel(ConcreteDimensionUnit unit) => switch (unit) {
        ConcreteDimensionUnit.meters => Ar.meters,
        ConcreteDimensionUnit.centimeters => Ar.cm,
        ConcreteDimensionUnit.millimeters => Ar.unitMm,
      };

  Widget _buildInfoHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
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
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
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
                  for (final field in _fieldsFor(card)) ...[
                    _buildCardField(field.label, field.ctrl),
                    AppSpacing.gapSm,
                  ],
                  _buildCardField(Ar.quantity, card.qtyCtrl, isInteger: true),
                  AppSpacing.gapMd,
                  _buildCalcButton(index, theme),
                  if (card.error != null) _buildErrorResult(card, theme),
                  if (card.netVolume > 0 && card.error == null)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
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
    final isDark = theme.brightness == Brightness.dark;
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
            child: Icon(Icons.close, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown(_ElementCardData card, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      value: card.elementType,
      decoration: _inputDecoration(Ar.elementType),
      items: _elementTypes
          .map(
            (e) => DropdownMenuItem(
              value: e['value'],
              child: Text(e['label']!,
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
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
            card.qtyCtrl.text = '1';
            card.singleVolume = 0;
            card.netVolume = 0;
            card.error = null;
          });
        }
      },
    );
  }

  Widget _buildCalcButton(int index, ThemeData theme) {
    return CalculatorPrimaryButton(
      onPressed: () => _calcCard(index),
      label: Ar.calculate,
    );
  }

  Widget _buildErrorResult(_ElementCardData card, ThemeData theme) {
    return CalculatorErrorCard(message: card.error!);
  }

  Widget _buildVolumeResult(_ElementCardData card, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final qty = int.tryParse(card.qtyCtrl.text) ?? 1;
    final isCircular = _isCircular(card.elementType);

    final l = double.tryParse(card.lengthCtrl.text) ?? 0;
    final w = double.tryParse(card.widthCtrl.text) ?? 0;
    final h = double.tryParse(card.heightCtrl.text) ?? 0;

    final formulaText = isCircular
        ? '(π/4) × ${l.toStringAsFixed(3)}² × ${h.toStringAsFixed(3)} $_unitSymbol'
        : '${l.toStringAsFixed(3)} × ${w.toStringAsFixed(3)} × ${h.toStringAsFixed(3)} $_unitSymbol';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${Ar.formula}: $formulaText = ${card.singleVolume.toStringAsFixed(3)} ${Ar.cubicMeters}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (qty > 1) ...[
              const SizedBox(height: 4),
              Text(
                '${Ar.singleElementVolume}: ${card.singleVolume.toStringAsFixed(3)} ${Ar.cubicMeters}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${Ar.netVolume}${qty > 1 ? ' (×$qty)' : ''}: ${card.netVolume.toStringAsFixed(3)} ${Ar.cubicMeters}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
    final isDark = theme.brightness == Brightness.dark;
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.options,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Optional user-selected additional percentage (default 0%)
            Text(
              Ar.additionalPercent,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                          : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                    color: _isCustomWaste ? AppColors.primary : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_isCustomWaste) ...[
              const SizedBox(height: 8),
              _buildCardField(Ar.additionalPercent, _customWasteCtrl),
            ],
            const Divider(height: 32),
            // Optional supply & cost estimation (secondary, opt-in)
            Text(
              Ar.supplyCostSection,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCardField(
                '${Ar.truckCapacity} (${Ar.cubicMeters})', _truckCapacityCtrl),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    Ar.costPerCubic,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
    final isDark = theme.brightness == Brightness.dark;
    final hasResults = _cards.isNotEmpty && _cards.any((c) => c.netVolume > 0);
    final truckCount = _truckCount;
    final capacity = _truckCapacity;
    final cost = _totalConcreteCost;

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
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_totalRequired.toStringAsFixed(3)} ${Ar.cubicMeters}',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasResults) ...[
                  const SizedBox(height: 6),
                  if (_effectiveWastePercent > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${Ar.netVolume}: ${_netTotal.toStringAsFixed(3)} ${Ar.cubicMeters}  |  ${Ar.wasteVolume} ($_effectiveWastePercentLabel%): ${_wasteVolume.toStringAsFixed(3)} ${Ar.cubicMeters}',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  if (truckCount != null && capacity != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${Ar.truckCount} (${capacity.toStringAsFixed(1)} ${Ar.cubicMeters}): $truckCount',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (cost != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${Ar.concreteCost}: ${cost.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: Ar.reset,
            color: Colors.white,
            onPressed: _resetSteel,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildSteelInputCard(theme),
          if (_steelCalculated) ...[
            AppSpacing.gapLg,
            _buildSteelResultsCard(theme),
          ],
          if (_steelError != null) ...[
            AppSpacing.gapMd,
            _buildSteelErrorCard(theme),
          ],
          AppSpacing.gapLg,
          _buildSteelEstimatesCard(theme),
          AppSpacing.gapXl,
        ],
      ),
      bottomNavigationBar: _buildSteelBottomBar(theme),
    );
  }

  Widget _buildSteelInputCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.steelInputSection,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${Ar.diameter} (${Ar.unitMm})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final d in _steelDiameterPresets)
                  ChoiceChip(
                    label: Text('$d'),
                    selected: !_steelIsCustomDiameter && _steelDiameter == d,
                    onSelected: (_) => setState(() {
                      _steelDiameter = d;
                      _steelIsCustomDiameter = false;
                      _steelCalculated = false;
                      _steelError = null;
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: !_steelIsCustomDiameter && _steelDiameter == d
                          ? AppColors.primary
                          : isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ChoiceChip(
                  label: Text(Ar.wasteCustom),
                  selected: _steelIsCustomDiameter,
                  onSelected: (_) => setState(() {
                    _steelIsCustomDiameter = true;
                    _steelCalculated = false;
                    _steelError = null;
                  }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _steelIsCustomDiameter
                        ? AppColors.primary
                        : isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_steelIsCustomDiameter) ...[
              const SizedBox(height: 8),
              _buildCardField(
                  '${Ar.diameter} (${Ar.unitMm})', _steelCustomDiameterCtrl),
            ],
            const SizedBox(height: 12),
            _buildCardField(Ar.steelBarLength, _lengthCtrl),
            const SizedBox(height: 8),
            _buildCardField(Ar.quantity, _qtyCtrl, isInteger: true),
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
            Text(
              Ar.additionalPercent,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                    selected: !_steelIsCustomWaste && _steelWastePercent == pct,
                    onSelected: (_) => setState(() {
                      _steelWastePercent = pct.toDouble();
                      _steelIsCustomWaste = false;
                      _steelCalculated = false;
                      _steelError = null;
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: !_steelIsCustomWaste && _steelWastePercent == pct
                          ? AppColors.primary
                          : isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ChoiceChip(
                  label: Text(Ar.wasteCustom),
                  selected: _steelIsCustomWaste,
                  onSelected: (_) => setState(() {
                    _steelIsCustomWaste = true;
                    _steelCalculated = false;
                    _steelError = null;
                  }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _steelIsCustomWaste
                        ? AppColors.primary
                        : isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_steelIsCustomWaste) ...[
              const SizedBox(height: 8),
              _buildCardField(Ar.additionalPercent, _steelCustomWasteCtrl),
            ],
            const SizedBox(height: 16),
            CalculatorPrimaryButton(
              onPressed: _calcSteelWeight,
              label: Ar.calculate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSteelEstimatesCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.steelAdditionalEstimates,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // A. Procurement Estimate
            Row(
              children: [
                Expanded(
                  child: Text(
                    Ar.steelProcurementEstimate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _showSteelProcurement,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _showSteelProcurement = v),
                ),
              ],
            ),
            if (_showSteelProcurement) ...[
              const SizedBox(height: 8),
              _buildCardField(
                  '${Ar.steelStockLength} (${Ar.meters})', _steelStockLengthCtrl),
              if (_steelCalculated) ...[
                const SizedBox(height: 12),
                if (_steelStockLen <= 0) ...[
                  Text(
                    Ar.steelStockLengthInvalid,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (_steelStockLen < _steelLen) ...[
                  Text(
                    Ar.steelStockShorter,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  _steelResultRow('${Ar.steelBarsPerStockBar}:',
                      '$_steelBarsPerStockBar'),
                  _steelResultRow('${Ar.steelBarsRequired}:',
                      '$_steelReqBars'),
                  _steelResultRow('${Ar.steelPurchasedLength}:',
                      '${_steelPurchLen.toStringAsFixed(2)} ${Ar.meters}'),
                  _steelResultRow('${Ar.steelRemainingLength}:',
                      '${_steelRemainLen.toStringAsFixed(2)} ${Ar.meters}'),
                  _steelResultRow('${Ar.steelPurchasedWeight}:',
                      '${_steelPurchW.toStringAsFixed(2)} ${Ar.kg}'),
                ],
              ],
            ],
            const Divider(height: 32),
            // B. Cost Estimate
            Row(
              children: [
                Expanded(
                  child: Text(
                    Ar.steelCostEstimate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
              _buildCardField(Ar.steelPricePerTon, _steelCostPerTonCtrl),
              if (_steelCalculated && _steelHasCost) ...[
                const SizedBox(height: 12),
                Text(
                  Ar.steelCostHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _steelResultRow('${Ar.steelNetCost}:',
                    SteelWeightCalculator.estimatedCost(
                            finalWeightTon: _steelNetW / 1000,
                            pricePerTon: _steelPriceTon!)
                        .toStringAsFixed(0)),
                _steelResultRow('${Ar.steelTotalCost}:',
                    SteelWeightCalculator.estimatedCost(
                            finalWeightTon: _steelTotalW / 1000,
                            pricePerTon: _steelPriceTon!)
                        .toStringAsFixed(0),
                    isBold: true),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSteelResultsCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.steelResults,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _steelResultRow(
                '${Ar.diameter}:', '$_steelDiaLabel ${Ar.unitMm}'),
            _steelResultRow('${Ar.steelWeightPerMeter}:',
                '${_steelWPM.toStringAsFixed(3)} ${Ar.kg}/${Ar.meters}'),
            _steelResultRow('${Ar.steelWeightPerBar}:',
                '${_steelWeightPerBar.toStringAsFixed(3)} ${Ar.kg}'),
            _steelResultRow('${Ar.steelTotalLength}:',
                '${_steelTotalLen.toStringAsFixed(2)} ${Ar.meters}'),
            const Divider(height: 24),
            if (_steelWastePercent > 0)
              _steelResultRow('${Ar.steelNetWeight}:',
                  '${_steelNetW.toStringAsFixed(2)} ${Ar.kg}'),
            if (_steelWastePercent > 0)
              _steelResultRow(
                  '${Ar.steelAdditionalWeight} ($_steelWastePercentLabel%):',
                  '${_steelAdditionalW.toStringAsFixed(2)} ${Ar.kg}'),
            _steelResultRow('${Ar.steelTotalRequiredWeight}:',
                '${_steelTotalW.toStringAsFixed(2)} ${Ar.kg}',
                isBold: true),
            _steelResultRow('${Ar.steelTotalTons}:',
                '${_steelFinalTon.toStringAsFixed(3)} ${Ar.tons}'),
            _steelResultRow('${Ar.steelBarsPerTon} (${Ar.steelApproximate}):',
                '$_steelBarsPerTon'),
          ],
        ),
      ),
    );
  }

  Widget _buildSteelErrorCard(ThemeData theme) {
    return CalculatorErrorCard(message: _steelError!);
  }

  Widget _buildSteelBottomBar(ThemeData theme) {
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
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _steelCalculated
                      ? '${_steelTotalW.toStringAsFixed(2)} ${Ar.kg} / ${(_steelTotalW / 1000).toStringAsFixed(3)} ${Ar.tons}'
                      : '0.00 ${Ar.kg} / 0.000 ${Ar.tons}',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
              '$_steelDiaLabel ${Ar.unitMm}',
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
    return CalculatorResultRow(
      label: label,
      value: value,
      isBold: isBold,
    );
  }

  Widget _buildCardField(String label, TextEditingController ctrl,
      {bool isInteger = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      keyboardType: isInteger
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        if (isInteger)
          FilteringTextInputFormatter.digitsOnly
        else
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      textAlign: TextAlign.start,
      style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary, fontSize: 15),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 14),
      hintText: '0.0',
      hintStyle: TextStyle(color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withValues(alpha: 0.4)),
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : _fieldFill,
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

  // ───────────── brick calculator screen ─────────────

  Widget _buildBrickScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: Ar.reset,
            color: Colors.white,
            onPressed: _resetBrick,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildBrickInputCard(theme),
          if (_brickCalculated) ...[
            AppSpacing.gapLg,
            _buildBrickResultsCard(theme),
          ],
          if (_brickError != null) ...[
            AppSpacing.gapMd,
            _buildBrickErrorCard(theme),
          ],
          AppSpacing.gapXl,
        ],
      ),
      bottomNavigationBar: _buildBrickBottomBar(theme),
    );
  }

  Widget _buildBrickInputCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final presets = MasonryPreset.forType(_masonryType);
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.masonryInputSection,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // masonry type
            Text(
              Ar.masonryUnitType,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(Ar.concreteBlock),
                    selected: _masonryType == MasonryType.block,
                    onSelected: (_) => setState(() {
                      _masonryType = MasonryType.block;
                      _masonryPreset = MasonryPreset.forType(MasonryType.block).first;
                      _isCustomMasonry = false;
                      _brickCalculated = false;
                      _brickError = null;
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _masonryType == MasonryType.block
                          ? AppColors.primary
                          : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text(Ar.clayBrick),
                    selected: _masonryType == MasonryType.brick,
                    onSelected: (_) => setState(() {
                      _masonryType = MasonryType.brick;
                      _masonryPreset = MasonryPreset.forType(MasonryType.brick).first;
                      _isCustomMasonry = false;
                      _brickCalculated = false;
                      _brickError = null;
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _masonryType == MasonryType.brick
                          ? AppColors.primary
                          : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // presets
            Text(
              Ar.masonryPresets,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final p in presets)
                  ChoiceChip(
                    label: Text('${p.label} ${Ar.cm}'),
                    selected: !_isCustomMasonry && _masonryPreset == p,
                    onSelected: (_) => setState(() {
                      _masonryPreset = p;
                      _isCustomMasonry = false;
                      _brickCalculated = false;
                      _brickError = null;
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: !_isCustomMasonry && _masonryPreset == p
                          ? AppColors.primary
                          : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ChoiceChip(
                  label: Text(Ar.masonryCustomTitle),
                  selected: _isCustomMasonry,
                  onSelected: (_) => setState(() {
                    _isCustomMasonry = true;
                    _brickCalculated = false;
                    _brickError = null;
                  }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _isCustomMasonry
                        ? AppColors.primary
                        : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_isCustomMasonry) ...[
              const SizedBox(height: 12),
              _buildCardField(Ar.masonryCustomFaceHeight,
                  _masonryCustomHeightCtrl),
              const SizedBox(height: 8),
              _buildCardField(Ar.masonryCustomFaceLength,
                  _masonryCustomLengthCtrl),
              const SizedBox(height: 4),
              Text(
                Ar.masonryCustomModuleHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildCardField(Ar.masonryWallLength, _lengthCtrl),
            const SizedBox(height: 8),
            _buildCardField(Ar.masonryWallHeight, _heightCtrl),
            const SizedBox(height: 8),
            _buildCardField(Ar.masonryWallQuantity, _qtyCtrl,
                isInteger: true),
            const SizedBox(height: 8),
            _buildCardField(Ar.masonryOpenings, _masonryOpeningsCtrl),
            const SizedBox(height: 16),
            Text(
              Ar.additionalPercent,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                    selected: !_brickIsCustomPercent &&
                        _brickAdditionalPercent == pct,
                    onSelected: (_) => setState(() {
                      _brickAdditionalPercent = pct.toDouble();
                      _brickIsCustomPercent = false;
                      _brickCalculated = false;
                      _brickError = null;
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: !_brickIsCustomPercent &&
                              _brickAdditionalPercent == pct
                          ? AppColors.primary
                          : isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ChoiceChip(
                  label: Text(Ar.wasteCustom),
                  selected: _brickIsCustomPercent,
                  onSelected: (_) => setState(() {
                    _brickIsCustomPercent = true;
                    _brickCalculated = false;
                    _brickError = null;
                  }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _brickIsCustomPercent
                        ? AppColors.primary
                        : isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_brickIsCustomPercent) ...[
              const SizedBox(height: 8),
              _buildCardField(Ar.additionalPercent, _brickCustomPercentCtrl),
            ],
            const SizedBox(height: 16),
            CalculatorPrimaryButton(
              onPressed: _calcBrickWeight,
              label: Ar.calculate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrickResultsCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Ar.masonryResults,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _steelResultRow('${Ar.masonryGrossArea}:',
                '${_brickGross.toStringAsFixed(2)} ${Ar.squareMeters}'),
            if (_brickOpenings > 0)
              _steelResultRow('${Ar.masonryOpeningsDeducted}:',
                  '${_brickOpenings.toStringAsFixed(2)} ${Ar.squareMeters}'),
            _steelResultRow('${Ar.masonryNetArea}:',
                '${_brickNet.toStringAsFixed(2)} ${Ar.squareMeters}',
                isBold: true),
            if (_brickUnitsPerM2 > 0)
              _steelResultRow(
                  '${Ar.masonryUnitsPerM2}:', _brickUnitsPerM2.toStringAsFixed(1)),
            const Divider(height: 24),
            _steelResultRow(
                '${Ar.masonryNetUnits}:', '$_brickNetUnits'),
            if (_brickAdditionalPercent > 0)
              _steelResultRow(
                  '${Ar.masonryAdditionalUnits} ($_brickPercentLabel%):',
                  '$_brickAdditionalUnits'),
            _steelResultRow('${Ar.masonryFinalUnits}:',
                '$_brickFinalUnits',
                isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBrickErrorCard(ThemeData theme) {
    return CalculatorErrorCard(message: _brickError!);
  }

  Widget _buildBrickBottomBar(ThemeData theme) {
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
                  Ar.masonryFinalUnits,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _brickCalculated
                      ? '$_brickFinalUnits'
                      : '0',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
              _isCustomMasonry
                  ? '${Ar.masonryCustomTitle} ${Ar.cm}'
                  : '${_masonryPreset.label} ${Ar.cm}',
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
