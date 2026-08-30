import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_colors.dart';
import 'package:civilpedia/core/theme/design_tokens.dart';
import 'package:civilpedia/core/theme/spacing.dart';
import 'package:civilpedia/features/projects/data/local_project_calculation_repository.dart';
import 'package:civilpedia/features/projects/domain/entities/project_calculation_record.dart';
import 'package:civilpedia/features/projects/domain/project_calculation_repository.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';

/// W4.6 — reusable, read-only Calculation History surface owned by the
/// canonical Projects feature.
///
/// It loads the saved [ProjectCalculationRecord]s for [projectId] through the
/// canonical [ProjectCalculationRepository] and renders only the stored record
/// data (title, calculatorId, calculatorVersion, createdAt, inputSnapshot,
/// outputSnapshot). It NEVER recomputes using Tile calculator logic and offers
/// no edit / delete / rename / recalculate / live-reopen affordance.
///
/// The surface is intentionally PRODUCTION-UNEXPOSED: it declares no route,
/// no navigation entry, and no Bottom Navigation / ProjectList change. It is a
/// directly-constructible widget for future visual QA or wiring only when
/// approved.
class ProjectCalculationHistoryView extends StatefulWidget {
  final String projectId;
  final ProjectCalculationRepository? repository;

  const ProjectCalculationHistoryView({
    super.key,
    required this.projectId,
    this.repository,
  });

  @override
  State<ProjectCalculationHistoryView> createState() =>
      _ProjectCalculationHistoryViewState();
}

class _ProjectCalculationHistoryViewState
    extends State<ProjectCalculationHistoryView> {
  late final ProjectCalculationRepository _repository;
  bool _loading = true;
  bool _loadFailed = false;
  List<ProjectCalculationRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        LocalProjectCalculationRepository();
    _load();
  }

  Future<void> _load() async {
    try {
      final records = await _repository.loadCalculations(widget.projectId);
      if (!mounted) return;
      setState(() {
        _records = _sorted(records);
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  /// Presentation-only ordering: newest [createdAt] first, then highest record
  /// [id] first for deterministic ties. Never mutates the stored records.
  static List<ProjectCalculationRecord> _sorted(
      List<ProjectCalculationRecord> records) {
    final copy = List<ProjectCalculationRecord>.of(records);
    copy.sort((a, b) {
      final byTime = b.createdAt.compareTo(a.createdAt);
      if (byTime != 0) return byTime;
      return b.id.compareTo(a.id);
    });
    return copy;
  }

  bool get _isArabic => context.read<LanguageProvider>().isArabic;

  String _tr(String ar, String en) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadFailed) {
      return Center(
        child: Padding(
          padding: AppSpacing.padLg,
          child: Text(
            _tr(Ar.calcHistoryLoadFailed, En.calcHistoryLoadFailed),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      );
    }
    if (_records.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.padLg,
          child: Text(
            _tr(Ar.calcHistoryNoCalculations, En.calcHistoryNoCalculations),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: AppSpacing.padLg,
      itemCount: _records.length,
      separatorBuilder: (_, __) => AppSpacing.gapLg,
      itemBuilder: (context, index) =>
          _HistoryCard(record: _records[index], tr: _tr, isArabic: _isArabic),
    );
  }
}

/// Renders a single stored [ProjectCalculationRecord] read-only.
class _HistoryCard extends StatelessWidget {
  final ProjectCalculationRecord record;
  final String Function(String ar, String en) tr;
  final bool isArabic;

  const _HistoryCard({
    required this.record,
    required this.tr,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (record.title?.isNotEmpty ?? false) ? record.title! : null;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: AppSpacing.padLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.mainText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapXs,
            ],
            _MetaRow(
              label: tr(Ar.calcHistoryCalculator, En.calcHistoryCalculator),
              value: record.calculatorId,
            ),
            _MetaRow(
              label: tr(Ar.calcHistoryVersion, En.calcHistoryVersion),
              value: record.calculatorVersion,
            ),
            _MetaRow(
              label: tr(Ar.calcHistorySavedOn, En.calcHistorySavedOn),
              value: _formatDate(record.createdAt),
            ),
            AppSpacing.gapSm,
            _SectionHeader(tr(Ar.calcHistoryInputSection, En.calcHistoryInputSection)),
            _SnapshotRows(
              snapshot: record.inputSnapshot,
              tr: tr,
              isInput: true,
            ),
            AppSpacing.gapMd,
            _SectionHeader(tr(Ar.calcHistoryResultSection, En.calcHistoryResultSection)),
            _SnapshotRows(
              snapshot: record.outputSnapshot,
              tr: tr,
              isInput: false,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mainText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Renders a stored snapshot (input or output) as presenter-visible rows.
///
/// Known Tile V1 keys are mapped to localized labels; unknown keys fall back
/// to their raw key safely. Values are rendered format-safely (null => empty).
class _SnapshotRows extends StatelessWidget {
  final Map<String, Object?> snapshot;
  final String Function(String ar, String en) tr;
  final bool isInput;

  const _SnapshotRows({
    required this.snapshot,
    required this.tr,
    required this.isInput,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    snapshot.forEach((key, value) {
      final label = _labelFor(key, tr);
      final display = _displayFor(key, value, tr);
      rows.add(_SnapshotRow(label: label, value: display));
    });
    return Column(children: rows);
  }

  String _displayFor(
      String key, Object? value, String Function(String, String) tr) {
    if (value == null) return '';
    switch (key) {
      case TileSnapshotKeys.kUnit:
        final unit = value.toString();
        if (unit == 'cm') return tr(Ar.calcHistoryUnitCm, En.calcHistoryUnitCm);
        if (unit == 'mm') return tr(Ar.calcHistoryUnitMm, En.calcHistoryUnitMm);
        return unit;
      case TileSnapshotKeys.kPriceMode:
        final mode = value.toString();
        if (mode == 'perBox') {
          return tr(Ar.calcHistoryPerBox, En.calcHistoryPerBox);
        }
        if (mode == 'perTile') {
          return tr(Ar.calcHistoryPerTile, En.calcHistoryPerTile);
        }
        return mode;
      case TileSnapshotKeys.kIsCustomTile:
      case TileSnapshotKeys.kIsCustomPercent:
      case TileSnapshotKeys.kBoxEstimateEnabled:
      case TileSnapshotKeys.kCostEnabled:
        return value == true
            ? tr(Ar.calcHistoryYes, En.calcHistoryYes)
            : tr(Ar.calcHistoryNo, En.calcHistoryNo);
      default:
        return _formatNumber(value);
    }
  }

  String _formatNumber(Object value) {
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toString();
    }
    return value.toString();
  }

  String _labelFor(
      String key, String Function(String, String) tr) {
    switch (key) {
      case TileSnapshotKeys.kAreaLength:
        return tr(Ar.calcHistoryLabelAreaLength, En.calcHistoryLabelAreaLength);
      case TileSnapshotKeys.kAreaWidth:
        return tr(Ar.calcHistoryLabelAreaWidth, En.calcHistoryLabelAreaWidth);
      case TileSnapshotKeys.kQuantity:
        return tr(Ar.calcHistoryLabelQuantity, En.calcHistoryLabelQuantity);
      case TileSnapshotKeys.kExcludedArea:
        return tr(Ar.calcHistoryLabelExcludedArea, En.calcHistoryLabelExcludedArea);
      case TileSnapshotKeys.kTileLengthCm:
        return tr(Ar.calcHistoryLabelTileLengthCm, En.calcHistoryLabelTileLengthCm);
      case TileSnapshotKeys.kTileWidthCm:
        return tr(Ar.calcHistoryLabelTileWidthCm, En.calcHistoryLabelTileWidthCm);
      case TileSnapshotKeys.kUnit:
        return tr(Ar.calcHistoryLabelUnit, En.calcHistoryLabelUnit);
      case TileSnapshotKeys.kIsCustomTile:
        return tr(Ar.calcHistoryLabelIsCustomTile, En.calcHistoryLabelIsCustomTile);
      case TileSnapshotKeys.kAdditionalPercent:
        return tr(Ar.calcHistoryLabelAdditionalPercent, En.calcHistoryLabelAdditionalPercent);
      case TileSnapshotKeys.kIsCustomPercent:
        return tr(Ar.calcHistoryLabelIsCustomPercent, En.calcHistoryLabelIsCustomPercent);
      case TileSnapshotKeys.kBoxEstimateEnabled:
        return tr(Ar.calcHistoryLabelBoxEstimateEnabled, En.calcHistoryLabelBoxEstimateEnabled);
      case TileSnapshotKeys.kCostEnabled:
        return tr(Ar.calcHistoryLabelCostEnabled, En.calcHistoryLabelCostEnabled);
      case TileSnapshotKeys.kTilesPerBox:
        return tr(Ar.calcHistoryLabelTilesPerBox, En.calcHistoryLabelTilesPerBox);
      case TileSnapshotKeys.kPrice:
        return tr(Ar.calcHistoryLabelPrice, En.calcHistoryLabelPrice);
      case TileSnapshotKeys.kPriceMode:
        return tr(Ar.calcHistoryLabelPriceMode, En.calcHistoryLabelPriceMode);
      case TileSnapshotKeys.kGross:
        return tr(Ar.calcHistoryLabelGross, En.calcHistoryLabelGross);
      case TileSnapshotKeys.kNet:
        return tr(Ar.calcHistoryLabelNet, En.calcHistoryLabelNet);
      case TileSnapshotKeys.kTileArea:
        return tr(Ar.calcHistoryLabelTileArea, En.calcHistoryLabelTileArea);
      case TileSnapshotKeys.kTilesPerM2:
        return tr(Ar.calcHistoryLabelTilesPerM2, En.calcHistoryLabelTilesPerM2);
      case TileSnapshotKeys.kNetTiles:
        return tr(Ar.calcHistoryLabelNetTiles, En.calcHistoryLabelNetTiles);
      case TileSnapshotKeys.kAdditionalTiles:
        return tr(Ar.calcHistoryLabelAdditionalTiles, En.calcHistoryLabelAdditionalTiles);
      case TileSnapshotKeys.kFinalTiles:
        return tr(Ar.calcHistoryLabelFinalTiles, En.calcHistoryLabelFinalTiles);
      case TileSnapshotKeys.kRequiredBoxes:
        return tr(Ar.calcHistoryLabelRequiredBoxes, En.calcHistoryLabelRequiredBoxes);
      case TileSnapshotKeys.kTotalCost:
        return tr(Ar.calcHistoryLabelTotalCost, En.calcHistoryLabelTotalCost);
      default:
        return key;
    }
  }
}

class _SnapshotRow extends StatelessWidget {
  final String label;
  final String value;
  const _SnapshotRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mainText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Presentation-only known snapshot key names. These mirror the Tile V1 schema
/// keys but are simple local constants so Projects owns no Tile business logic.
class TileSnapshotKeys {
  TileSnapshotKeys._();

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
  static const String kGross = 'gross';
  static const String kNet = 'net';
  static const String kTileArea = 'tileArea';
  static const String kTilesPerM2 = 'tilesPerM2';
  static const String kNetTiles = 'netTiles';
  static const String kAdditionalTiles = 'additionalTiles';
  static const String kFinalTiles = 'finalTiles';
  static const String kRequiredBoxes = 'requiredBoxes';
  static const String kTotalCost = 'totalCost';
}
