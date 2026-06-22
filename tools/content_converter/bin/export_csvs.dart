/// Extracts CSVs from an existing catalog.json for spreadsheet editing.
/// Usage: dart run bin/export_csvs.dart [output_dir]
import 'dart:convert';
import 'dart:io';

String csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String csvLine(List<String> values) => values.map(csvField).join(',');

void writeUtf8Csv(String path, String content) {
  File(path).writeAsBytesSync(utf8.encode(content), flush: true);
}

void main(List<String> args) {
  final outputDir = args.isNotEmpty ? args[0] : 'sample';
  final catalogPath = '../../assets/encyclopedia/catalog.json';
  final catalog = jsonDecode(File(catalogPath).readAsStringSync()) as Map<String, dynamic>;
  final topics = catalog['topics'] as List;
  final sections = catalog['sections'] as Map<String, dynamic>;
  final blocks = catalog['blocks'] as Map<String, dynamic>;

  var dir = Directory(outputDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // ── topics.csv ──
  final topicHeaders = [
    'topicId', 'titleAr', 'titleEn', 'categoryId', 'summary', 'tags',
    'relatedTopicIds', 'createdAt', 'updatedAt', 'level', 'status', 'planKey',
    'simpleExplanation_ar', 'simpleExplanation_en',
    'beforeWork_ar', 'beforeWork_en',
    'duringWork_ar', 'duringWork_en',
    'afterWork_ar', 'afterWork_en',
    'codeNotes_ar', 'codeNotes_en',
    'siteNotes_ar', 'siteNotes_en',
    'reportWordingAr', 'reportWordingEn',
    'relatedToolRoutes', 'relatedChecklistIds',
  ];
  var topicLines = [topicHeaders.join(',')];
  for (final t in topics) {
    final g = (String key) => t[key]?.toString() ?? '';
    final list = (String key) => (t[key] as List?)?.cast<String>().join(',') ?? '';
    final obj = (String key, String lang) => ((t[key] as Map<String, dynamic>?) ?? {})[lang]?.toString() ?? '';
    topicLines.add(csvLine([
      g('id'), g('titleAr'), g('titleEn'), g('categoryId'), g('summary'),
      list('tags'), list('relatedTopicIds'),
      g('createdAt'), g('updatedAt'), g('level'), 'Draft',
      t['planKey'] == null ? '' : t['planKey'].toString(),
      obj('simpleExplanation', 'ar'), obj('simpleExplanation', 'en'),
      obj('beforeWork', 'ar'), obj('beforeWork', 'en'),
      obj('duringWork', 'ar'), obj('duringWork', 'en'),
      obj('afterWork', 'ar'), obj('afterWork', 'en'),
      obj('codeNotes', 'ar'), obj('codeNotes', 'en'),
      obj('siteNotes', 'ar'), obj('siteNotes', 'en'),
      obj('reportWording', 'ar'), obj('reportWording', 'en'),
      list('relatedToolRoutes'), list('relatedChecklistIds'),
    ]));
  }
  writeUtf8Csv('$outputDir/topics.csv', topicLines.join('\n'));
  print('topics.csv: ${topicLines.length - 1} rows');

  // ── sections.csv ──
  var secLines = ['sectionId,topicId,title,type,order'];
  for (final tid in sections.keys) {
    for (final s in sections[tid] as List) {
      secLines.add(csvLine([
        s['id']?.toString() ?? '', tid,
        s['title']?.toString() ?? '',
        s['type']?.toString() ?? '',
        s['order']?.toString() ?? '0',
      ]));
    }
  }
  writeUtf8Csv('$outputDir/sections.csv', secLines.join('\n'));
  print('sections.csv: ${secLines.length - 1} rows');

  // ── blocks.csv ──
  final blockHeaders = [
    'sectionId', 'blockOrder', 'type',
    'text_content', 'text_variant',
    'step_number', 'step_description', 'step_image', 'step_note',
    'point_criteria', 'point_method', 'point_critical', 'point_acceptableTolerance', 'point_tool',
    'safety_message', 'safety_severity', 'safety_code', 'safety_action',
    'code_code', 'code_title', 'code_section', 'code_excerpt',
    'checklist_title', 'table_title', 'table_headers',
    'equipment_title', 'image_url', 'image_caption',
  ];
  var blockLines = [blockHeaders.join(',')];
  for (final sid in blocks.keys) {
    final blist = blocks[sid] as List;
    for (int bi = 0; bi < blist.length; bi++) {
      final b = blist[bi] as Map<String, dynamic>;
      final type = b['type'] as String? ?? '';
      final row = <String, String>{
        'sectionId': sid, 'blockOrder': (bi + 1).toString(), 'type': type,
        'text_content': '', 'text_variant': '',
        'step_number': '', 'step_description': '', 'step_image': '', 'step_note': '',
        'point_criteria': '', 'point_method': '', 'point_critical': '', 'point_acceptableTolerance': '', 'point_tool': '',
        'safety_message': '', 'safety_severity': '', 'safety_code': '', 'safety_action': '',
        'code_code': '', 'code_title': '', 'code_section': '', 'code_excerpt': '',
        'checklist_title': '', 'table_title': '', 'table_headers': '',
        'equipment_title': '', 'image_url': '', 'image_caption': '',
      };
      switch (type) {
        case 'text':
          row['text_content'] = b['content']?.toString() ?? '';
          row['text_variant'] = b['variant']?.toString() ?? 'paragraph';
          break;
        case 'execution_step':
          final step = b['step'] as Map<String, dynamic>? ?? {};
          row['step_number'] = step['stepNumber']?.toString() ?? '0';
          row['step_description'] = step['description']?.toString() ?? '';
          row['step_image'] = step['imageUrl']?.toString() ?? '';
          row['step_note'] = step['notes']?.toString() ?? '';
          break;
        case 'inspection_point':
          final point = b['point'] as Map<String, dynamic>? ?? {};
          row['point_criteria'] = point['criteria']?.toString() ?? '';
          row['point_method'] = point['method']?.toString() ?? '';
          row['point_critical'] = (point['isCritical'] == true).toString().toUpperCase();
          row['point_acceptableTolerance'] = point['acceptableTolerance']?.toString() ?? '';
          row['point_tool'] = point['tool']?.toString() ?? '';
          break;
        case 'safety_note':
          final note = b['note'] as Map<String, dynamic>? ?? {};
          row['safety_message'] = note['message']?.toString() ?? '';
          row['safety_severity'] = note['severity']?.toString() ?? 'medium';
          row['safety_code'] = note['codeReference']?.toString() ?? '';
          row['safety_action'] = note['action']?.toString() ?? '';
          break;
        case 'code_reference':
          final ref = b['reference'] as Map<String, dynamic>? ?? {};
          row['code_code'] = ref['code']?.toString() ?? '';
          row['code_title'] = ref['title']?.toString() ?? '';
          row['code_section'] = ref['section']?.toString() ?? '';
          row['code_excerpt'] = ref['description']?.toString() ?? '';
          break;
        case 'checklist':
          row['checklist_title'] = b['title']?.toString() ?? '';
          break;
        case 'table':
          final data = b['data'] as Map<String, dynamic>? ?? {};
          row['table_title'] = data['caption']?.toString() ?? '';
          final hdrs = data['headers'] as List? ?? [];
          row['table_headers'] = hdrs.map((h) => h.toString()).join(',');
          break;
        case 'equipment':
          row['equipment_title'] = b['title']?.toString() ?? '';
          break;
        case 'image':
          row['image_url'] = b['url']?.toString() ?? '';
          row['image_caption'] = b['caption']?.toString() ?? '';
          break;
      }
      blockLines.add(csvLine(blockHeaders.map((h) => row[h] ?? '').toList()));
    }
  }
  writeUtf8Csv('$outputDir/blocks.csv', blockLines.join('\n'));
  print('blocks.csv: ${blockLines.length - 1} rows');

  // ── checklist_items.csv ──
  var clLines = ['itemId,sectionId,textAr,textEn,isRequired,category'];
  for (final sid in blocks.keys) {
    final blist = blocks[sid] as List;
    for (final b in blist) {
      if (b['type'] != 'checklist') continue;
      for (final item in b['items'] as List? ?? []) {
        clLines.add(csvLine([
          item['id']?.toString() ?? '', sid,
          item['text']?.toString() ?? '',
          item['textEn']?.toString() ?? '',
          (item['isRequired'] == true).toString().toUpperCase(),
          item['category']?.toString() ?? '',
        ]));
      }
    }
  }
  writeUtf8Csv('$outputDir/checklist_items.csv', clLines.join('\n'));
  print('checklist_items.csv: ${clLines.length - 1} rows');

  // ── table_rows.csv ──
  var trLines = <String>[];
  var maxCols = 0;
  for (final sid in blocks.keys) {
    for (final b in blocks[sid] as List) {
      if (b['type'] != 'table') continue;
      for (final r in (b['data'] as Map)['rows'] as List? ?? []) {
        final cells = (r['cells'] as List?)?.length ?? 0;
        if (cells > maxCols) maxCols = cells;
      }
    }
  }
  var trHeaders = ['sectionId', 'blockOrder'];
  for (int i = 1; i <= maxCols; i++) trHeaders.add('column_$i');
  trLines.add(trHeaders.join(','));
  for (final sid in blocks.keys) {
    final blist = blocks[sid] as List;
    for (int bi = 0; bi < blist.length; bi++) {
      if (blist[bi]['type'] != 'table') continue;
      for (final r in (blist[bi]['data'] as Map)['rows'] as List? ?? []) {
        final cells = r['cells'] as List? ?? [];
        final vals = [sid, (bi + 1).toString()];
        for (final c in cells) vals.add(c.toString());
        while (vals.length < trHeaders.length) vals.add('');
        trLines.add(csvLine(vals));
      }
    }
  }
  writeUtf8Csv('$outputDir/table_rows.csv', trLines.join('\n'));
  print('table_rows.csv: ${trLines.length - 1} rows');

  // ── accept_reject.csv ──
  var arLines = ['topicId,criteriaAr,criteriaEn,acceptanceLimitAr,acceptanceLimitEn,methodAr,methodEn,isCritical,reviewRequired,planKey,codeReference'];
  for (final t in topics) {
    final tid = t['id'] as String? ?? '';
    for (final item in t['acceptRejectItems'] as List? ?? []) {
      arLines.add(csvLine([
        tid, item['criteriaAr']?.toString() ?? '',
        item['criteriaEn']?.toString() ?? '',
        item['acceptanceLimitAr']?.toString() ?? '',
        item['acceptanceLimitEn']?.toString() ?? '',
        item['methodAr']?.toString() ?? '', item['methodEn']?.toString() ?? '',
        (item['isCritical'] == true).toString().toUpperCase(),
        (item['reviewRequired'] == true).toString().toUpperCase(),
        item['planKey']?.toString() ?? '',
        item['codeReference']?.toString() ?? '',
      ]));
    }
  }
  writeUtf8Csv('$outputDir/accept_reject.csv', arLines.join('\n'));
  print('accept_reject.csv: ${arLines.length - 1} rows');

  // ── common_mistakes.csv ──
  var cmLines = ['topicId,issueAr,issueEn,correctionAr,correctionEn,severity,codeReference'];
  for (final t in topics) {
    final tid = t['id'] as String? ?? '';
    for (final m in t['commonMistakes'] as List? ?? []) {
      cmLines.add(csvLine([
        tid, m['ar']?.toString() ?? '', m['en']?.toString() ?? '',
        m['correctionAr']?.toString() ?? '', m['correctionEn']?.toString() ?? '',
        m['severity']?.toString() ?? 'medium',
        m['codeReference']?.toString() ?? '',
      ]));
    }
  }
  writeUtf8Csv('$outputDir/common_mistakes.csv', cmLines.join('\n'));
  print('common_mistakes.csv: ${cmLines.length - 1} rows');

  // ── equipment_items.csv ──
  var eqLines = ['sectionId,nameAr,nameEn,specification,purpose'];
  for (final sid in blocks.keys) {
    for (final b in blocks[sid] as List) {
      if (b['type'] != 'equipment') continue;
      for (final item in b['items'] as List? ?? []) {
        eqLines.add(csvLine([
          sid, item['name']?.toString() ?? '',
          item['nameEn']?.toString() ?? '',
          item['specification']?.toString() ?? '',
          item['purpose']?.toString() ?? '',
        ]));
      }
    }
  }
  writeUtf8Csv('$outputDir/equipment_items.csv', eqLines.join('\n'));
  print('equipment_items.csv: ${eqLines.length - 1} rows');

  print('\nDone. CSVs written to $outputDir/');
}
