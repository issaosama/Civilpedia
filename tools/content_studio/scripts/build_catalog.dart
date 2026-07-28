/// Builds a combined catalog.generated.json from individual topic JSON files.
///
/// Usage:
///   dart run tools/content_studio/scripts/build_catalog.dart
///
/// Reads:  app_ready_jsons/topics/*.topic.json
/// Writes: app_ready_jsons/catalog.generated.json
///
/// Does NOT modify assets/encyclopedia/catalog.json.

import 'dart:convert';
import 'dart:io';

const topicsDir = r'D:\Civilpedia\app_ready_jsons\topics';
const outputPath = r'D:\Civilpedia\app_ready_jsons\catalog.generated.json';

final errors = <String>[];
final warnings = <String>[];
int filesRead = 0;
int filesValid = 0;
final seenTopicIds = <String>{};

void main() {
  print('=== Catalog Generator ===');
  print('Input:  $topicsDir');
  print('Output: $outputPath\n');

  final topicsDirObj = Directory(topicsDir);
  if (!topicsDirObj.existsSync()) {
    fail('Input directory not found: $topicsDir');
    return;
  }

  final files = topicsDirObj.listSync().whereType<File>()
      .where((f) => f.path.endsWith('.topic.json')).toList();

  if (files.isEmpty) {
    fail('No *.topic.json files found in $topicsDir');
    return;
  }

  print('Found ${files.length} topic file(s)\n');

  final topics = <Map<String, dynamic>>[];
  final sections = <String, List<Map<String, dynamic>>>{};
  final blocks = <String, List<Map<String, dynamic>>>{};
  bool hasFatalError = false;

  for (final file in files) {
    filesRead++;
    final fileName = file.uri.pathSegments.last;
    print('Processing: $fileName');

    try {
      final content = file.readAsStringSync();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validate top-level structure
      if (!data.containsKey('topic')) {
        error('$fileName: missing "topic" key');
        continue;
      }
      if (!data.containsKey('sections')) {
        error('$fileName: missing "sections" key');
        continue;
      }
      if (!data.containsKey('blocks')) {
        error('$fileName: missing "blocks" key');
        continue;
      }

      final topicData = data['topic'] as Map<String, dynamic>;
      final sectionsData = data['sections'] as List;
      final blocksData = data['blocks'] as Map<String, dynamic>;

      // Validate topic.id
      final topicId = topicData['id'] as String?;
      if (topicId == null || topicId.isEmpty) {
        error('$fileName: topic.id is missing or empty');
        continue;
      }

      // Check for duplicate topicId
      if (seenTopicIds.contains(topicId)) {
        error('$fileName: duplicate topic id "$topicId"');
        continue;
      }
      seenTopicIds.add(topicId);

      // Per-file section-ID dedup set (must be per file — section IDs
      // like "sec-overview" are intentionally reused across topics)
      final seenSectionIds = <String>{};

      // Validate sections
      final cleanedSections = <Map<String, dynamic>>[];
      for (final s in sectionsData) {
        final sec = s as Map<String, dynamic>;
        final secId = sec['id'] as String?;
        if (secId == null || secId.isEmpty) {
          error('$fileName: section missing "id"');
          continue;
        }
        if (seenSectionIds.contains(secId)) {
          error('$fileName: duplicate section id "$secId"');
          continue;
        }
        seenSectionIds.add(secId);

        if (!sec.containsKey('title')) {
          warn('$fileName: section "$secId" missing "title"');
        }
        if (!sec.containsKey('type')) {
          warn('$fileName: section "$secId" missing "type"');
        }
        if (!sec.containsKey('order')) {
          warn('$fileName: section "$secId" missing "order"');
        }
        cleanedSections.add({
          'id': secId,
          'title': sec['title'] ?? '',
          'type': sec['type'] ?? '',
          'order': sec['order'] ?? 0,
        });
      }
      sections[topicId] = cleanedSections;

      // Validate blocks
      for (final entry in blocksData.entries) {
        final secId = entry.key;
        final blkList = entry.value as List;

        if (!seenSectionIds.contains(secId)) {
          warn('$fileName: blocks reference section "$secId" which is not in sections list');
        }

        final cleanedBlocks = <Map<String, dynamic>>[];
        for (final b in blkList) {
          final blk = b as Map<String, dynamic>;
          if (!blk.containsKey('type')) {
            error('$fileName: block in section "$secId" missing "type"');
            continue;
          }
          if (!blk.containsKey('order')) {
            warn('$fileName: block in section "$secId" missing "order"');
          }
          final type = blk['type'] as String;

          // Type-specific validation
          if (type == 'table') {
            final data = blk['data'] as Map<String, dynamic>?;
            if (data == null) {
              error('$fileName: table block in "$secId" missing "data"');
            } else {
              final headers = data['headers'] as List?;
              if (headers == null || headers.isEmpty) {
                error('$fileName: table block in "$secId" has missing/empty headers');
              }
            }
          }
          if (type == 'checklist') {
            final items = blk['items'] as List?;
            if (items != null && items.isEmpty) {
              warn('$fileName: checklist in "$secId" has empty items');
            }
          }

          cleanedBlocks.add(Map.from(blk));
        }
        blocks['${topicId}__$secId'] = cleanedBlocks;
      }

      // Build the topic entry (flatten topic wrapper → top-level fields)
      final topicEntry = <String, dynamic>{};
      for (final key in topicData.keys) {
        topicEntry[key] = topicData[key];
      }
      topics.add(topicEntry);
      filesValid++;
      print('  ✅ Valid: topicId=$topicId, ${cleanedSections.length} sections, '
          '${blocksData.values.fold(0, (int sum, v) => sum + (v as List).length)} blocks');

    } catch (e) {
      error('$fileName: failed to parse - $e');
    }
  }

  print('\n=== Summary ===');
  print('Files read:   $filesRead');
  print('Files valid:  $filesValid');
  print('Errors:       ${errors.length}');
  print('Warnings:     ${warnings.length}');

  if (errors.isNotEmpty) {
    print('\n--- Errors ---');
    for (final e in errors) {
      print('  ❌ $e');
    }
  }
  if (warnings.isNotEmpty) {
    print('\n--- Warnings ---');
    for (final w in warnings) {
      print('  ⚠️  $w');
    }
  }

  if (errors.isNotEmpty) {
    print('\n❌ Build aborted due to ${errors.length} error(s). No output written.');
    exit(1);
  }

  // Build categories array from unique categoryIds
  final categoryIds = topics
      .map((t) => t['categoryId'] as String?)
      .whereType<String>()
      .toSet()
      .toList()
    ..sort();
  final categories = categoryIds.map((id) {
    final label = _categoryLabels[id] ?? <String, String>{'ar': id, 'en': id};
    return <String, dynamic>{
      'id': id,
      'title': {'ar': label['ar'], 'en': label['en']},
    };
  }).toList();

  // Build output
  final now = DateTime.now().toUtc().toIso8601String();
  final meta = {
    'format': 'civilpedia-catalog-generated',
    'schemaVersion': 1,
    'generatedAt': now,
    'source': 'app_ready_jsons/topics',
    'topicCount': topics.length,
    'sectionCount': sections.values.fold(0, (int s, v) => s + v.length),
    'blockCount': blocks.values.fold(0, (int s, v) => s + v.length),
  };
  final output = <String, dynamic>{
    '_meta': meta,
    'categories': categories,
    'topics': topics,
    'sections': sections,
    'blocks': blocks,
  };

  final outputFile = File(outputPath);
  outputFile.writeAsStringSync(jsonEncode(output));
  print('\n✅ Output written: $outputPath');
  print('   Topics: ${topics.length}, Sections: ${meta['sectionCount']}, '
      'Blocks: ${meta['blockCount']}');
}

const _categoryLabels = <String, Map<String, String>>{
  'concrete': {'ar': 'الخرسانة', 'en': 'Concrete'},
  'steel': {'ar': 'الحديد', 'en': 'Steel Works'},
  'soil': {'ar': 'التربة', 'en': 'Soil Works'},
  'roads': {'ar': 'الطرق', 'en': 'Roads & Pavement'},
  'finishing': {'ar': 'أعمال الإنهاءات', 'en': 'Finishing Works'},
  'finishing-works': {'ar': 'أعمال الإنهاءات', 'en': 'Finishing Works'},
  'structural-works': {'ar': 'أعمال هيكلية', 'en': 'Structural Works'},
  'waterproofing-finishing': {
    'ar': 'العزل المائي والإنهاءات',
    'en': 'Waterproofing & Finishing',
  },
  'engineering-basics': {'ar': 'أساسيات الهندسة', 'en': 'Engineering Basics'},
  'asphalt': {'ar': 'الأسفلت', 'en': 'Asphalt'},
  'general': {'ar': 'عام', 'en': 'General'},
};

void error(String msg) {
  errors.add(msg);
}

void warn(String msg) {
  warnings.add(msg);
}

void fail(String msg) {
  print('\n❌ $msg');
  exit(1);
}
