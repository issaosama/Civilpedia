import 'schema.dart';

class ValidationIssue {
  final String message;
  final bool isError;

  ValidationIssue(this.message, {this.isError = true});
}

class ValidationResult {
  final List<ValidationIssue> issues;
  final bool hasErrors;

  ValidationResult({required this.issues}) : hasErrors = issues.any((i) => i.isError);

  void printReport() {
    if (issues.isEmpty) {
      print('  ✓ No validation issues.');
      return;
    }
    for (final issue in issues) {
      final prefix = issue.isError ? '  ✗ ERROR' : '  ⚠ WARNING';
      print('$prefix: ${issue.message}');
    }
    print('  ${issues.length} issue(s) total (${issues.where((i) => i.isError).length} errors, ${issues.where((i) => !i.isError).length} warnings)');
  }
}

ValidationResult validateAll({
  required List<Map<String, String>> topics,
  required List<Map<String, String>> sections,
  required List<Map<String, String>> blocks,
  required List<Map<String, String>> checklistItems,
  required List<Map<String, String>> tableRows,
  required List<Map<String, String>> acceptReject,
  required List<Map<String, String>> commonMistakes,
  required List<Map<String, String>> equipmentItems,
}) {
  final issues = <ValidationIssue>[];

  // ── Topics validation ──
  final topicIds = <String>{};
  final duplicateTopicIds = <String>{};
  final topicStatuses = <String, String>{};
  int topicRow = 0;
  for (final row in topics) {
    topicRow++;
    final tid = row['topicId'] ?? '';
    if (tid.isEmpty) {
      issues.add(ValidationIssue('topics.csv row $topicRow: empty topicId'));
      continue;
    }
    if (!topicIds.add(tid)) {
      duplicateTopicIds.add(tid);
    }
    final status = row['status'] ?? '';
    final isDraft = status == 'Draft';
    topicStatuses[tid] = status;

    // categoryId
    final catId = row['categoryId'] ?? '';
    if (catId.isEmpty) {
      issues.add(ValidationIssue('topics.csv: topic "$tid" has empty categoryId'));
    } else if (!allowedCategories.contains(catId)) {
      issues.add(ValidationIssue('topics.csv: topic "$tid" has unsupported categoryId "$catId"', isError: false));
    }
    // level
    final level = row['level'] ?? '';
    if (level.isEmpty) {
      issues.add(ValidationIssue('topics.csv: topic "$tid" has empty level'));
    } else if (!supportedLevels.contains(level)) {
      issues.add(ValidationIssue('topics.csv: topic "$tid" has unsupported level "$level"'));
    }
    // status
    if (status.isEmpty) {
      issues.add(ValidationIssue('topics.csv: topic "$tid" has empty status'));
    } else if (!supportedStatuses.contains(status)) {
      issues.add(ValidationIssue('topics.csv: topic "$tid" has unsupported status "$status"'));
    }
    // planKey
    final planKey = row['planKey'] ?? '';
    if (planKey.isNotEmpty && !supportedPlanKeys.contains(planKey)) {
      issues.add(ValidationIssue('topics.csv: topic "$tid" has unsupported planKey "$planKey"', isError: false));
    }
    // featuredImageUrl
    final featuredImageUrl = row['featuredImageUrl'] ?? '';
    if (featuredImageUrl.isNotEmpty) {
      if (!featuredImageUrl.startsWith('assets/')) {
        issues.add(ValidationIssue('topics.csv: topic "$tid" featuredImageUrl should start with "assets/", got "$featuredImageUrl"', isError: false));
      }
      final ext = featuredImageUrl.split('.').last.toLowerCase();
      if (!['png', 'jpg', 'jpeg', 'webp'].contains(ext)) {
        issues.add(ValidationIssue('topics.csv: topic "$tid" featuredImageUrl should end with .png, .jpg, .jpeg, or .webp, got ".$ext"', isError: false));
      }
    }
    // tags
    final tags = row['tags'] ?? '';
    if (tags.isEmpty) {
      issues.add(ValidationIssue('topics.csv: topic "$tid" has empty tags', isError: false));
    }
    // createdAt / updatedAt
    final createdAt = row['createdAt'] ?? '';
    if (createdAt.isEmpty) {
      issues.add(ValidationIssue('topics.csv: topic "$tid" has empty createdAt — will use current timestamp as fallback', isError: false));
    }
    final updatedAt = row['updatedAt'] ?? '';
    if (updatedAt.isEmpty) {
      issues.add(ValidationIssue('topics.csv: topic "$tid" has empty updatedAt — will use current timestamp as fallback', isError: false));
    }
    // Required text fields — status-aware
    for (final field in ['titleAr', 'titleEn', 'summary', 'simpleExplanation_ar', 'simpleExplanation_en']) {
      final val = row[field] ?? '';
      if (val.isEmpty) {
        issues.add(ValidationIssue(
          'topics.csv: topic "$tid" is "$status" but has empty field "$field"',
          isError: !isDraft,
        ));
      }
    }
    // relatedToolRoutes
    final routes = row['relatedToolRoutes'] ?? '';
    if (routes.isNotEmpty) {
      for (final r in routes.split(',')) {
        final trimmed = r.trim();
        if (trimmed.isNotEmpty && !allowedToolRoutes.contains(trimmed)) {
          issues.add(ValidationIssue('topics.csv: topic "$tid" has unknown tool route "$trimmed"', isError: false));
        }
      }
    }
    // [DRAFT - REVIEW REQUIRED] markers
    for (final field in row.keys) {
      final val = row[field] ?? '';
      if (val.contains('[DRAFT - REVIEW REQUIRED]')) {
        issues.add(ValidationIssue('topics.csv: topic "$tid" field "$field" still contains [DRAFT - REVIEW REQUIRED] marker', isError: false));
      }
    }
  }
  for (final tid in duplicateTopicIds) {
    issues.add(ValidationIssue('topics.csv: duplicate topicId "$tid"'));
  }

  // ── Sections validation ──
  final sectionIds = <String>{};
  final duplicateSectionIds = <String>{};
  final topicWithSections = <String>{};
  int sectionRow = 0;
  for (final row in sections) {
    sectionRow++;
    final sid = row['sectionId'] ?? '';
    if (sid.isEmpty) {
      issues.add(ValidationIssue('sections.csv row $sectionRow: empty sectionId'));
      continue;
    }
    if (!sectionIds.add(sid)) {
      duplicateSectionIds.add(sid);
    }
    final tid = row['topicId'] ?? '';
    if (tid.isNotEmpty) {
      topicWithSections.add(tid);
      if (!topicIds.contains(tid)) {
        issues.add(ValidationIssue('sections.csv: section "$sid" references unknown topicId "$tid"'));
      }
    }
    final type = row['type'] ?? '';
    if (type.isEmpty) {
      issues.add(ValidationIssue('sections.csv: section "$sid" has empty type'));
    } else if (!supportedSectionTypes.contains(type)) {
      issues.add(ValidationIssue('sections.csv: section "$sid" has unsupported type "$type"'));
    }
    final order = row['order'] ?? '';
    if (order.isEmpty) issues.add(ValidationIssue('sections.csv: section "$sid" has empty order'));
    final title = row['title'] ?? '';
    if (title.isEmpty) issues.add(ValidationIssue('sections.csv: section "$sid" has empty title'));
  }
  for (final sid in duplicateSectionIds) {
    issues.add(ValidationIssue('sections.csv: duplicate sectionId "$sid"'));
  }
  // Check topics without sections — status-aware
  for (final tid in topicIds) {
    if (!topicWithSections.contains(tid)) {
      final isDraft = topicStatuses[tid] == 'Draft';
      issues.add(ValidationIssue(
        'topics.csv: topic "$tid" (status="${topicStatuses[tid] ?? '?'}") has no sections',
        isError: !isDraft,
      ));
    }
  }

  // ── Blocks validation ──
  final blocksBySection = <String, int>{};
  final blockSectionTypes = <String, String>{};
  int blockRow = 0;
  for (final row in blocks) {
    blockRow++;
    final sid = row['sectionId'] ?? '';
    if (sid.isEmpty) {
      issues.add(ValidationIssue('blocks.csv row $blockRow: empty sectionId'));
      continue;
    }
    blocksBySection.update(sid, (v) => v + 1, ifAbsent: () => 1);
    if (!sectionIds.contains(sid)) {
      issues.add(ValidationIssue('blocks.csv row $blockRow: references unknown sectionId "$sid"'));
    }
    final type = row['type'] ?? '';
    if (type.isEmpty) {
      issues.add(ValidationIssue('blocks.csv row $blockRow: empty type'));
    } else if (!supportedBlockTypes.contains(type)) {
      issues.add(ValidationIssue('blocks.csv row $blockRow: unsupported type "$type"'));
    } else {
      final required = blockRequiredFields[type] ?? [];
      for (final field in required) {
        final val = row[field] ?? '';
        if (val.isEmpty) {
          issues.add(ValidationIssue('blocks.csv row $blockRow: block type "$type" in section "$sid" missing required field "$field"'));
        }
      }
      // Type-specific validation
      if (type == 'text') {
        final variant = row['text_variant'] ?? '';
        if (variant.isNotEmpty && !supportedTextVariants.contains(variant)) {
          issues.add(ValidationIssue('blocks.csv row $blockRow: block in section "$sid" has unsupported text_variant "$variant"'));
        }
      }
      if (type == 'safety_note') {
        final severity = row['safety_severity'] ?? '';
        if (severity.isNotEmpty && !supportedSafetySeverities.contains(severity)) {
          issues.add(ValidationIssue('blocks.csv row $blockRow: block in section "$sid" has unsupported safety_severity "$severity"'));
        }
      }
      if (type == 'inspection_point') {
        final critical = row['point_critical'] ?? '';
        if (critical.isNotEmpty && !validTrueFalse.contains(critical.toUpperCase())) {
          issues.add(ValidationIssue('blocks.csv row $blockRow: block in section "$sid" has invalid point_critical "$critical" (must be TRUE/FALSE)'));
        }
      }
      if (type == 'image') {
        final imageUrl = row['image_url'] ?? '';
        if (imageUrl.isEmpty) {
          issues.add(ValidationIssue('blocks.csv row $blockRow: image block in section "$sid" has empty image_url'));
        }
      }
      if (type == 'checklist') {
        blockSectionTypes[sid] = type;
      }
      if (type == 'table') {
        blockSectionTypes[sid] = type;
      }
    }
  }
  // Check sections without blocks
  for (final sid in sectionIds) {
    if (!blocksBySection.containsKey(sid)) {
      issues.add(ValidationIssue('sections.csv: section "$sid" has no blocks', isError: false));
    }
  }

  // ── Checklist items validation ──
  final sectionsWithChecklistItems = <String>{};
  for (final row in checklistItems) {
    final sid = row['sectionId'] ?? '';
    if (sid.isNotEmpty) {
      sectionsWithChecklistItems.add(sid);
      if (!sectionIds.contains(sid)) {
        issues.add(ValidationIssue('checklist_items.csv: references unknown sectionId "$sid"'));
      }
      final text = row['itemText'] ?? '';
      if (text.isEmpty) {
        issues.add(ValidationIssue('checklist_items.csv: section "$sid" has checklist item with empty text'));
      }
    }
    final isReq = row['isRequired'] ?? '';
    if (isReq.isNotEmpty && !validTrueFalse.contains(isReq.toUpperCase())) {
      issues.add(ValidationIssue('checklist_items.csv: invalid isRequired "$isReq" (must be TRUE/FALSE)'));
    }
  }

  // ── Table rows validation ──
  final sectionsWithTableRows = <String>{};
  for (final row in tableRows) {
    final sid = row['sectionId'] ?? '';
    if (sid.isNotEmpty) {
      sectionsWithTableRows.add(sid);
      if (!sectionIds.contains(sid)) {
        issues.add(ValidationIssue('table_rows.csv: references unknown sectionId "$sid"'));
      }
    }
  }

  // Warn if checklist block has no linked checklist items
  for (final sid in blockSectionTypes.keys) {
    if (blockSectionTypes[sid] == 'checklist' && !sectionsWithChecklistItems.contains(sid)) {
      issues.add(ValidationIssue('blocks.csv: checklist block in section "$sid" has no linked checklist items', isError: false));
    }
    if (blockSectionTypes[sid] == 'table' && !sectionsWithTableRows.contains(sid)) {
      issues.add(ValidationIssue('blocks.csv: table block in section "$sid" has no linked table rows', isError: false));
    }
  }

  // ── Accept/reject validation ──
  for (final row in acceptReject) {
    final tid = row['topicId'] ?? '';
    if (tid.isNotEmpty && !topicIds.contains(tid)) {
      issues.add(ValidationIssue('accept_reject.csv: references unknown topicId "$tid"'));
    }
    final critical = row['isCritical'] ?? '';
    if (critical.isNotEmpty && !validTrueFalse.contains(critical.toUpperCase())) {
      issues.add(ValidationIssue('accept_reject.csv: invalid isCritical "$critical" (must be TRUE/FALSE)'));
    }
    final reviewReq = row['reviewRequired'] ?? '';
    if (reviewReq.toUpperCase() == 'TRUE') {
      issues.add(ValidationIssue('accept_reject.csv: item "${row['criteriaAr'] ?? ''}" for topic "$tid" has reviewRequired=TRUE', isError: false));
    }
  }

  // ── Common mistakes validation ──
  for (final row in commonMistakes) {
    final tid = row['topicId'] ?? '';
    if (tid.isNotEmpty && !topicIds.contains(tid)) {
      issues.add(ValidationIssue('common_mistakes.csv: references unknown topicId "$tid"'));
    }
  }

  // ── Equipment items validation ──
  for (final row in equipmentItems) {
    final sid = row['sectionId'] ?? '';
    if (sid.isNotEmpty && !sectionIds.contains(sid)) {
      issues.add(ValidationIssue('equipment_items.csv: references unknown sectionId "$sid"'));
    }
  }

  return ValidationResult(issues: issues);
}
