import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/inspection_seed_data.dart';
import 'models/inspection_item.dart';
import 'models/inspection_status.dart';
import 'models/inspection_summary.dart';
import 'inspection_localization.dart';
import 'widgets/inspection_summary_card.dart';
import 'widgets/inspection_category_card.dart';
import '../../../../../core/services/language_provider.dart';

import '../../../../../localization/ar.dart';
import '../../../../../localization/en.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final Map<String, InspectionItem> _items = {};
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _initItems();
  }

  void _initItems() {
    _items.clear();
    for (final cat in kCategories) {
      for (final item in kItemsForCategory(cat.id)) {
        _items[item.id] = item;
      }
    }
  }

  InspectionSummary get _summary {
    int passed = 0, failed = 0, pending = 0;
    int criticalTotal = 0, criticalPassed = 0;
    int requiredTotal = 0, requiredPassed = 0;

    for (final item in _items.values) {
      switch (item.status) {
        case InspectionStatus.pass:
          passed++;
          if (item.isCritical) criticalPassed++;
          if (item.isRequired) requiredPassed++;
        case InspectionStatus.fail:
          failed++;
        case InspectionStatus.pending:
          pending++;
      }
      if (item.isCritical) criticalTotal++;
      if (item.isRequired) requiredTotal++;
    }

    return InspectionSummary(
      totalItems: _items.length,
      passed: passed,
      failed: failed,
      pending: pending,
      criticalTotal: criticalTotal,
      criticalPassed: criticalPassed,
      requiredTotal: requiredTotal,
      requiredPassed: requiredPassed,
    );
  }

  void _toggleItemStatus(String itemId) {
    final item = _items[itemId];
    if (item == null) return;
    setState(() {
      item.status = switch (item.status) {
        InspectionStatus.pending => InspectionStatus.pass,
        InspectionStatus.pass => InspectionStatus.fail,
        InspectionStatus.fail => InspectionStatus.pending,
      };
    });
  }

  void _updateItemNotes(String itemId, String notes) {
    final item = _items[itemId];
    if (item == null) return;
    setState(() => item.notes = notes);
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_expandedCategories.contains(categoryId)) {
        _expandedCategories.remove(categoryId);
      } else {
        _expandedCategories.add(categoryId);
      }
    });
  }

  void _resetAll() {
    setState(() {
      for (final item in _items.values) {
        item.status = InspectionStatus.pending;
        item.notes = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final l10n = L10n(isArabic);
    final summary = _summary;

    String tr(String ar, String en) => isArabic ? ar : en;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(Ar.siteChecklist, En.siteChecklist)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InspectionSummaryCard(
            summary: summary,
            isArabic: isArabic,
            title: tr(Ar.siteChecklist, En.siteChecklist),
            passLabel: tr(Ar.inspectionPass, En.inspectionPass),
            failLabel: tr(Ar.inspectionFail, En.inspectionFail),
            pendingLabel: tr(Ar.inspectionPending, En.inspectionPending),
            criticalLabel: tr(Ar.inspectionCritical, En.inspectionCritical),
            requiredLabel: tr(Ar.inspectionRequired, En.inspectionRequired),
            totalItemsLabel: tr(Ar.inspectionTotalItems, En.inspectionTotalItems),
            resetLabel: tr(Ar.inspectionResetAll, En.inspectionResetAll),
            onReset: _resetAll,
          ),
          const SizedBox(height: 16),
          ...kCategories.map((cat) {
            final items = kItemsForCategory(cat.id)
                .map((seed) => _items[seed.id]!)
                .toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InspectionCategoryCard(
                category: cat,
                items: items,
                isExpanded: _expandedCategories.contains(cat.id),
                l10n: l10n,
                passLabel: tr(Ar.inspectionPass, En.inspectionPass),
                failLabel: tr(Ar.inspectionFail, En.inspectionFail),
                pendingLabel: tr(Ar.inspectionPending, En.inspectionPending),
                criticalLabel: tr(Ar.inspectionCritical, En.inspectionCritical),
                requiredLabel: tr(Ar.inspectionRequired, En.inspectionRequired),
                notesHint: tr(Ar.inspectionNotes, En.inspectionNotes),
                codeRefLabel: tr(Ar.inspectionCodeRef, En.inspectionCodeRef),
                onToggle: () => _toggleCategory(cat.id),
                onItemStatusChanged: _toggleItemStatus,
                onItemNotesChanged: _updateItemNotes,
              ),
            );
          }),
        ],
      ),
    );
  }
}
