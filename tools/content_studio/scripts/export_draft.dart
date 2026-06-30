import 'dart:convert';
import 'dart:io';

Map<String, dynamic> _localized(dynamic obj) {
  if (obj is! Map) return {'ar': '', 'en': ''};
  return {
    'ar': (obj['ar'] as String?) ?? '',
    'en': (obj['en'] as String?) ?? '',
  };
}

Map<String, dynamic> _exportTopic(Map<String, dynamic> src, Map<String, dynamic> meta) {
  return {
    'id': (src['id'] as String?) ?? '',
    'titleAr': (src['titleAr'] as String?) ?? '',
    'titleEn': (src['titleEn'] as String?) ?? '',
    'categoryId': (src['categoryId'] as String?) ?? '',
    'summary': (src['summaryAr'] as String?) ?? (src['summary'] as String?) ?? '',
    'tags': (src['tags'] as List?)?.cast<String>() ?? [],
    'relatedTopicIds': (src['relatedTopicIds'] as List?)?.cast<String>() ?? [],
    'createdAt': src['createdAt'] ?? meta['createdAt'] ?? null,
    'updatedAt': src['updatedAt'] ?? meta['updatedAt'] ?? null,
    'level': (src['level'] as String?) ?? 'basic',
    'planKey': src['planKey'],
    'featuredImageUrl': src['featuredImageUrl'],
    'simpleExplanation': _localized(src['simpleExplanation']),
    'beforeWork': _localized(src['beforeWork']),
    'duringWork': _localized(src['duringWork']),
    'afterWork': _localized(src['afterWork']),
    'commonMistakes': _exportCommonMistakes(src['commonMistakes']),
    'acceptRejectItems': _exportAcceptReject(src['acceptRejectItems']),
    'codeNotes': _localized(src['codeNotes']),
    'siteNotes': _localized(src['siteNotes']),
    'reportWording': _localized(src['reportWording']),
    'visual_theme': _exportVisualTheme(src['visual_theme']),
    'relatedToolRoutes': (src['relatedToolRoutes'] as List?)?.cast<String>() ?? [],
    'relatedChecklistIds': (src['relatedChecklistIds'] as List?)?.cast<String>() ?? [],
  };
}

const _validThemeKeys = ['cement_gray', 'navy', 'teal', 'olive', 'amber', 'maroon'];

Map<String, dynamic> _exportVisualTheme(dynamic vt) {
  final accent = (vt is Map) ? vt['accent'] : null;
  return {'accent': (accent is String && _validThemeKeys.contains(accent)) ? accent : 'cement_gray'};
}

List<Map<String, dynamic>> _exportCommonMistakes(dynamic mistakes) {
  if (mistakes is! List) return [];
  return mistakes.map((m) => {
    'ar': (m['ar'] as String?) ?? '',
    'en': (m['en'] as String?) ?? '',
  }).toList();
}

List<Map<String, dynamic>> _exportAcceptReject(dynamic items) {
  if (items is! List) return [];
  return items.map((item) => {
    'criteriaAr': (item['criteriaAr'] as String?) ?? '',
    'criteriaEn': (item['criteriaEn'] as String?) ?? '',
    'acceptanceLimitAr': (item['acceptanceLimitAr'] as String?) ?? '',
    'acceptanceLimitEn': (item['acceptanceLimitEn'] as String?) ?? '',
    'methodAr': (item['methodAr'] as String?) ?? '',
    'methodEn': (item['methodEn'] as String?) ?? '',
    'isCritical': item['isCritical'] == true,
    'reviewRequired': item['reviewRequired'] != false,
    'planKey': (item['planKey'] as String?) ?? '',
    'codeReference': (item['codeReference'] as String?) ?? '',
  }).toList();
}

List<Map<String, dynamic>> _exportSections(List sections) {
  return sections.map((s) => {
    'id': s['id'],
    'title': s['title'],
    'type': s['type'],
    'order': s['order'],
  }).toList();
}

Map<String, dynamic> _exportBlocks(List sections) {
  final result = <String, dynamic>{};
  for (final section in sections) {
    final sectionId = section['id'] as String?;
    if (sectionId == null || sectionId.isEmpty) continue;
    final srcBlocks = (section['blocks'] as List?) ?? [];
    result[sectionId] = srcBlocks.map((b) => _exportBlock(b)).toList();
  }
  return result;
}

Map<String, dynamic> _exportBlock(Map<String, dynamic> src) {
  final type = src['type'] as String? ?? '';
  final order = src['order'];
  final block = <String, dynamic>{'type': type, 'order': order};

  switch (type) {
    case 'text': {
      final content = src['content'] as Map<String, dynamic>? ?? {};
      block['content'] = (content['ar'] as String?) ?? '';
      if (src['variant'] != null) block['variant'] = src['variant'];
      break;
    }
    case 'execution_step': {
      final desc = src['description'] as Map<String, dynamic>? ?? {};
      final notes = src['notes'] as Map<String, dynamic>? ?? {};
      block['step'] = {
        'stepNumber': src['stepNumber'] ?? 1,
        'description': (desc['ar'] as String?) ?? '',
        'notes': (notes['ar'] as String?) ?? '',
      };
      break;
    }
    case 'safety_note': {
      final msg = src['message'] as Map<String, dynamic>? ?? {};
      block['note'] = {
        'message': (msg['ar'] as String?) ?? '',
        'severity': (src['severity'] as String?) ?? 'medium',
      };
      break;
    }
    case 'table': {
      final caption = src['caption'] as Map<String, dynamic>? ?? {};
      block['data'] = {
        'caption': (caption['ar'] as String?) ?? '',
        'headers': (src['headers'] as List?)?.cast<String>() ?? [],
        'rows': ((src['rows'] as List?) ?? []).map((r) => {
          'cells': (r['cells'] as List?)?.cast<String>() ?? [],
        }).toList(),
      };
      break;
    }
    case 'checklist': {
      final title = src['title'] as Map<String, dynamic>? ?? {};
      block['title'] = (title['ar'] as String?) ?? '';
      block['items'] = ((src['items'] as List?) ?? []).asMap().entries.map((e) {
        final idx = e.key + 1;
        final item = e.value as Map<String, dynamic>;
        return {
          'id': (item['id'] as String?) ?? 'item-${idx.toString().padLeft(2, '0')}',
          'text': (item['textAr'] as String?) ?? '',
          'isRequired': item['isRequired'] != false,
        };
      }).toList();
      break;
    }
    case 'inspection_point': {
      block['point'] = {
        'criteria': (src['criteriaAr'] as String?) ?? '',
        'method': (src['methodAr'] as String?) ?? '',
        'isCritical': src['isCritical'] == true,
        'acceptableTolerance': (src['acceptableTolerance'] as String?) ?? '',
      };
      break;
    }
    case 'code_reference': {
      final title = src['title'] as Map<String, dynamic>? ?? {};
      final excerpt = src['excerpt'] as Map<String, dynamic>? ?? {};
      block['reference'] = {
        'code': (src['code'] as String?) ?? '',
        'title': (title['ar'] as String?) ?? (title['en'] as String?) ?? '',
        'section': (src['section'] as String?) ?? '',
        'description': (excerpt['ar'] as String?) ?? (excerpt['en'] as String?) ?? '',
      };
      break;
    }
    case 'equipment': {
      block['title'] = (src['title'] as String?) ?? '';
      block['items'] = ((src['items'] as List?) ?? []).map((item) => {
        'name': (item['nameAr'] as String?) ?? (item['name'] as String?) ?? '',
        'purpose': (item['purpose'] as String?) ?? '',
        'specification': (item['specification'] as String?) ?? '',
      }).toList();
      break;
    }
    case 'image': {
      block['imageUrl'] = (src['url'] as String?) ?? (src['imageUrl'] as String?) ?? '';
      final caption = src['caption'] as Map<String, dynamic>? ?? {};
      block['caption'] = (caption['ar'] as String?) ?? '';
      break;
    }
    default: {
      block.addAll(src);
    }
  }

  return block;
}

void main(List<String> args) {
  if (args.length < 1) {
    print('Usage: dart run export_draft.dart <draft_json_path> [output_path]');
    exit(1);
  }

  final draftPath = args[0];
  final outputPath = args.length > 1 ? args[1] : '';

  final draftFile = File(draftPath);
  if (!draftFile.existsSync()) {
    print('ERROR: Not found: $draftPath');
    exit(1);
  }

  final source = jsonDecode(draftFile.readAsStringSync()) as Map<String, dynamic>;
  final meta = (source['_meta'] as Map<String, dynamic>?) ?? {};
  final draftTopic = (source['topic'] as Map<String, dynamic>?) ?? {};
  final draftSections = (source['sections'] as List?) ?? [];

  final topic = _exportTopic(draftTopic, meta);
  final sections = _exportSections(draftSections);
  final blocks = _exportBlocks(draftSections);

  final output = <String, dynamic>{
    'topic': topic,
    'sections': sections,
    'blocks': blocks,
  };

  final json = const JsonEncoder.withIndent('  ').convert(output);

  if (outputPath.isNotEmpty) {
    File(outputPath).writeAsStringSync(json);
    print('Written: $outputPath');
  } else {
    print(json);
  }
}
