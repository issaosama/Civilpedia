import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/inspection_seed_data.dart';
import 'models/inspection_item.dart';
import 'models/inspection_status.dart';
import 'models/inspection_summary.dart';
import 'inspection_localization.dart';
import 'widgets/inspection_summary_card.dart';
import 'widgets/inspection_category_card.dart';
import 'checklist_category_detail_screen.dart';
import 'models/inspection_category.dart';
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

  void _resetAll() {
    setState(() {
      for (final item in _items.values) {
        item.status = InspectionStatus.pending;
        item.notes = null;
      }
    });
  }

  void _navigateToCategory(InspectionCategory category, L10n l10n,
      String passLabel, String failLabel, String pendingLabel,
      String criticalLabel, String requiredLabel, String notesHint,
      String codeRefLabel) {
    final items = kItemsForCategory(category.id)
        .map((seed) => _items[seed.id]!)
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistCategoryDetailScreen(
          category: category,
          items: items,
          l10n: l10n,
          passLabel: passLabel,
          failLabel: failLabel,
          pendingLabel: pendingLabel,
          criticalLabel: criticalLabel,
          requiredLabel: requiredLabel,
          notesHint: notesHint,
          codeRefLabel: codeRefLabel,
          onItemStatusChanged: _toggleItemStatus,
          onItemNotesChanged: _updateItemNotes,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final l10n = L10n(isArabic);
    final summary = _summary;

    String tr(String ar, String en) => isArabic ? ar : en;

    final passLabel = tr(Ar.inspectionPass, En.inspectionPass);
    final failLabel = tr(Ar.inspectionFail, En.inspectionFail);
    final pendingLabel = tr(Ar.inspectionPending, En.inspectionPending);
    final criticalLabel = tr(Ar.inspectionCritical, En.inspectionCritical);
    final requiredLabel = tr(Ar.inspectionRequired, En.inspectionRequired);
    final notesHint = tr(Ar.inspectionNotes, En.inspectionNotes);
    final codeRefLabel = tr(Ar.inspectionCodeRef, En.inspectionCodeRef);

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
            passLabel: passLabel,
            failLabel: failLabel,
            pendingLabel: pendingLabel,
            criticalLabel: criticalLabel,
            requiredLabel: requiredLabel,
            totalItemsLabel: tr(Ar.inspectionTotalItems, En.inspectionTotalItems),
            resetLabel: tr(Ar.inspectionResetAll, En.inspectionResetAll),
            onReset: _resetAll,
          ),
          const SizedBox(height: 16),
          ...kCategories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InspectionCategoryCard(
                category: cat,
                items: kItemsForCategory(cat.id)
                    .map((seed) => _items[seed.id]!)
                    .toList(),
                l10n: l10n,
                onTap: () => _navigateToCategory(cat, l10n, passLabel,
                    failLabel, pendingLabel, criticalLabel, requiredLabel,
                    notesHint, codeRefLabel),
              ),
            );
          }),
        ],
      ),
    );
  }
}
