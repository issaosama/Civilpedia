import 'dart:async';

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
import 'project_list_screen.dart';
import '../../../domain/checklist/entities/project.dart';
import '../../../../../core/services/language_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../domain/checklist/checklist_repository.dart';
import '../../../data/checklist/local_checklist_repository.dart';
import '../../../data/checklist/checklist_local_data_source.dart';

import '../../../../../localization/ar.dart';
import '../../../../../localization/en.dart';

class ChecklistScreen extends StatefulWidget {
  final Project? project;

  const ChecklistScreen({super.key, this.project});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final Map<String, InspectionItem> _items = {};
  final ChecklistRepository _repository = LocalChecklistRepository(
    ChecklistLocalDataSource(),
  );
  Timer? _notesDebounceTimer;
  String? _pendingNotesItemId;
  bool get _isProject => widget.project != null;
  String? get _projectId => widget.project?.id;
  String? get _projectName => widget.project?.name;

  @override
  void initState() {
    super.initState();
    _initItems();
    _loadPersistedStates();
  }

  void _initItems() {
    _items.clear();
    for (final cat in kCategories) {
      for (final item in kItemsForCategory(cat.id)) {
        _items[item.id] = item.copyWith();
      }
    }
  }

  Future<void> _loadPersistedStates() async {
    try {
      final states = _isProject
          ? await _repository.loadProjectItemStates(_projectId!)
          : await _repository.loadItemStates();
      for (final entry in states.entries) {
        final item = _items[entry.key];
        if (item != null) {
          item.status = entry.value.status;
          item.notes = entry.value.notes;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Persistence failure must not crash the checklist.
    }
  }

  @override
  void dispose() {
    _notesDebounceTimer?.cancel();
    super.dispose();
  }

  InspectionSummary get _summary {
    int passed = 0, failed = 0, pending = 0, na = 0;
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
        case InspectionStatus.na:
          na++;
      }
      if (item.isCritical) criticalTotal++;
      if (item.isRequired) requiredTotal++;
    }

    return InspectionSummary(
      totalItems: _items.length,
      passed: passed,
      failed: failed,
      pending: pending,
      na: na,
      criticalTotal: criticalTotal,
      criticalPassed: criticalPassed,
      requiredTotal: requiredTotal,
      requiredPassed: requiredPassed,
    );
  }

  void _setItemStatus(String itemId, InspectionStatus newStatus) {
    final item = _items[itemId];
    if (item == null || item.status == newStatus) return;
    setState(() => item.status = newStatus);
    if (_isProject) {
      _repository.saveProjectItemStatus(_projectId!, itemId, newStatus);
    } else {
      _repository.saveItemStatus(itemId, newStatus);
    }
  }

  void _updateItemNotes(String itemId, String notes) {
    final item = _items[itemId];
    if (item == null) return;
    setState(() => item.notes = notes);
    _pendingNotesItemId = itemId;
    _notesDebounceTimer?.cancel();
    _notesDebounceTimer = Timer(
      const Duration(milliseconds: 400),
      () {
        final id = _pendingNotesItemId;
        if (id != null) {
          if (_isProject) {
            _repository.saveProjectItemNotes(_projectId!, id, _items[id]?.notes);
          } else {
            _repository.saveItemNotes(id, _items[id]?.notes);
          }
          _pendingNotesItemId = null;
        }
      },
    );
  }

  void _resetAll() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isArabic = context.read<LanguageProvider>().isArabic;
        return AlertDialog(
          title: Text(isArabic ? 'إعادة تعيين قائمة الفحص؟' : 'Reset Checklist?'),
          content: Text(isArabic
              ? 'سيتم مسح حالات الفحص والملاحظات الحالية لهذا المشروع وإعادة جميع البنود إلى غير مفحوص.'
              : 'This will clear the current inspection statuses and notes for this project and return all items to Pending.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  for (final item in _items.values) {
                    item.status = InspectionStatus.pending;
                    item.notes = null;
                  }
                });
                if (_isProject) {
                  _repository.clearProject(_projectId!);
                } else {
                  _repository.clearAll();
                }
              },
              child: Text(isArabic ? 'إعادة تعيين' : 'Reset',
                  style: const TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCategory(InspectionCategory category, L10n l10n,
      String passLabel, String failLabel, String pendingLabel,
      String naLabel, String criticalLabel, String requiredLabel,
      String notesHint, String codeRefLabel) {
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
          naLabel: naLabel,
          criticalLabel: criticalLabel,
          requiredLabel: requiredLabel,
          notesHint: notesHint,
          codeRefLabel: codeRefLabel,
          onItemStatusChanged: _setItemStatus,
          onItemNotesChanged: _updateItemNotes,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final l10n = L10n(isArabic);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = _summary;

    String tr(String ar, String en) => isArabic ? ar : en;

    final passLabel = tr(Ar.inspectionPass, En.inspectionPass);
    final failLabel = tr(Ar.inspectionFail, En.inspectionFail);
    final pendingLabel = tr(Ar.inspectionPending, En.inspectionPending);
    final naLabel = tr(Ar.inspectionNA, En.inspectionNA);
    final criticalLabel = tr(Ar.inspectionCritical, En.inspectionCritical);
    final requiredLabel = tr(Ar.inspectionRequired, En.inspectionRequired);
    final notesHint = tr(Ar.inspectionNotes, En.inspectionNotes);
    final codeRefLabel = tr(Ar.inspectionCodeRef, En.inspectionCodeRef);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isProject ? _projectName! : tr(Ar.siteChecklist, En.siteChecklist),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InspectionSummaryCard(
            summary: summary,
            isArabic: isArabic,
            title: _isProject ? _projectName! : tr(Ar.siteChecklist, En.siteChecklist),
            passLabel: passLabel,
            failLabel: failLabel,
            pendingLabel: pendingLabel,
            naLabel: naLabel,
            criticalLabel: criticalLabel,
            requiredLabel: requiredLabel,
            totalItemsLabel: tr(Ar.inspectionTotalItems, En.inspectionTotalItems),
            resetLabel: tr(Ar.inspectionResetAll, En.inspectionResetAll),
            onReset: _resetAll,
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProjectListScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.folder, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(Ar.checklistMyProjects, En.checklistMyProjects),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ],
                ),
              ),
            ),
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
                  failLabel, pendingLabel, naLabel, criticalLabel,
                  requiredLabel, notesHint, codeRefLabel),
              ),
            );
          }),
        ],
      ),
    );
  }
}
