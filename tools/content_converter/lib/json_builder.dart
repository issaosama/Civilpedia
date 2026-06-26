import 'dart:convert';
import 'dart:io';

class CatalogBuilder {
  final List<Map<String, String>> topics;
  final List<Map<String, String>> sections;
  final List<Map<String, String>> blocks;
  final List<Map<String, String>> checklistItems;
  final List<Map<String, String>> tableRows;
  final List<Map<String, String>> acceptReject;
  final List<Map<String, String>> commonMistakes;
  final List<Map<String, String>> equipmentItems;

  CatalogBuilder({
    required this.topics,
    required this.sections,
    required this.blocks,
    required this.checklistItems,
    required this.tableRows,
    required this.acceptReject,
    required this.commonMistakes,
    required this.equipmentItems,
  });

  Map<String, dynamic> build() {
    final catalogTopics = <Map<String, dynamic>>[];
    final catalogSections = <String, List<Map<String, dynamic>>>{};
    final catalogBlocks = <String, List<Map<String, dynamic>>>{};

    for (final t in topics) {
      final tid = t['topicId'] ?? '';

      final topicJson = <String, dynamic>{
        'id': tid,
        'titleAr': t['titleAr'] ?? '',
        'titleEn': t['titleEn'] ?? '',
        'categoryId': t['categoryId'] ?? '',
        'summary': t['summary'] ?? '',
        'tags': (t['tags'] ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'relatedTopicIds': (t['relatedTopicIds'] ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'createdAt': _nullIfEmpty(t['createdAt'] ?? '') ?? DateTime.now().toIso8601String(),
        'updatedAt': _nullIfEmpty(t['updatedAt'] ?? '') ?? DateTime.now().toIso8601String(),
        'level': t['level'] ?? 'basic',
        'planKey': _nullIfEmpty(t['planKey'] ?? ''),
        'featuredImageUrl': _nullIfEmpty(t['featuredImageUrl'] ?? ''),
        'simpleExplanation': {
          'ar': t['simpleExplanation_ar'] ?? '',
          'en': t['simpleExplanation_en'] ?? '',
        },
        'beforeWork': {
          'ar': t['beforeWork_ar'] ?? '',
          'en': t['beforeWork_en'] ?? '',
        },
        'duringWork': {
          'ar': t['duringWork_ar'] ?? '',
          'en': t['duringWork_en'] ?? '',
        },
        'afterWork': {
          'ar': t['afterWork_ar'] ?? '',
          'en': t['afterWork_en'] ?? '',
        },
        'commonMistakes': _commonMistakesForTopic(tid),
        'acceptRejectItems': _acceptRejectForTopic(tid),
        'codeNotes': {
          'ar': t['codeNotes_ar'] ?? '',
          'en': t['codeNotes_en'] ?? '',
        },
        'siteNotes': {
          'ar': t['siteNotes_ar'] ?? '',
          'en': t['siteNotes_en'] ?? '',
        },
        'reportWording': {
          'ar': t['reportWording_ar'] ?? '',
          'en': t['reportWording_en'] ?? '',
        },
        'relatedToolRoutes': (t['relatedToolRoutes'] ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'relatedChecklistIds': (t['relatedChecklistIds'] ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      };

      catalogTopics.add(topicJson);

      // Build sections for this topic
      final topicSections = sections.where((s) => s['topicId'] == tid).toList();
      final sectionList = <Map<String, dynamic>>[];
      for (final s in topicSections) {
        final sid = s['sectionId'] ?? '';
        sectionList.add({
          'id': sid,
          'title': s['title'] ?? '',
          'type': s['type'] ?? 'general',
          'order': _parseInt(s['order'] ?? '0'),
        });

        // Build blocks for this section
        final sectionBlocks = _blocksForSection(sid);
        if (sectionBlocks.isNotEmpty) {
          catalogBlocks[sid] = sectionBlocks;
        }
      }
      // Sort sections by order
      sectionList.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      catalogSections[tid] = sectionList;
    }

    return {
      'topics': catalogTopics,
      'sections': catalogSections,
      'blocks': catalogBlocks,
    };
  }

  List<Map<String, dynamic>> _blocksForSection(String sectionId) {
    final result = <Map<String, dynamic>>[];
    final sectionBlocks = blocks.where((b) => b['sectionId'] == sectionId).toList();
    sectionBlocks.sort((a, b) {
      final ao = _parseInt(a['order'] ?? '0');
      final bo = _parseInt(b['order'] ?? '0');
      return ao.compareTo(bo);
    });

    for (final b in sectionBlocks) {
      final type = b['type'] ?? '';
      final blockJson = <String, dynamic>{
        'type': type,
      };

      switch (type) {
        case 'text':
          blockJson['content'] = b['text_content'] ?? '';
          blockJson['variant'] = b['text_variant'] ?? 'paragraph';
          break;
        case 'execution_step':
          blockJson['step'] = {
            'stepNumber': _parseInt(b['step_number'] ?? '0'),
            'description': b['step_description'] ?? '',
          };
          if ((b['step_image'] ?? '').isNotEmpty) {
            (blockJson['step'] as Map<String, dynamic>)['imageUrl'] = b['step_image'];
          }
          if ((b['step_notes'] ?? '').isNotEmpty) {
            (blockJson['step'] as Map<String, dynamic>)['notes'] = b['step_notes'];
          }
          break;
        case 'inspection_point':
          blockJson['point'] = {
            'criteria': b['point_criteria'] ?? '',
            'method': b['point_method'] ?? '',
            'isCritical': (b['point_critical'] ?? '').toUpperCase() == 'TRUE',
          };
          if ((b['point_tolerance'] ?? '').isNotEmpty) {
            (blockJson['point'] as Map<String, dynamic>)['acceptableTolerance'] = b['point_tolerance'];
          }
          if ((b['point_tool'] ?? '').isNotEmpty) {
            (blockJson['point'] as Map<String, dynamic>)['tool'] = b['point_tool'];
          }
          break;
        case 'safety_note':
          blockJson['note'] = {
            'message': b['safety_message'] ?? '',
            'severity': b['safety_severity'] ?? 'medium',
          };
          if ((b['safety_code'] ?? '').isNotEmpty) {
            (blockJson['note'] as Map<String, dynamic>)['codeReference'] = b['safety_code'];
          }
          if ((b['safety_action'] ?? '').isNotEmpty) {
            (blockJson['note'] as Map<String, dynamic>)['action'] = b['safety_action'];
          }
          break;
        case 'code_reference':
          blockJson['reference'] = {
            'code': b['code_code'] ?? '',
            'title': b['code_title'] ?? '',
            'section': b['code_section'] ?? '',
          };
          if ((b['code_description'] ?? '').isNotEmpty) {
            (blockJson['reference'] as Map<String, dynamic>)['description'] = b['code_description'];
          }
          break;
        case 'checklist': {
          final blockOrder = b['order'] ?? '';
          final items = checklistItems.where((c) =>
            c['sectionId'] == sectionId &&
            (blockOrder.isEmpty || c['blockOrder'] == blockOrder)
          ).toList();
          blockJson['title'] = b['checklist_title'] ?? '';
          blockJson['items'] = items.map((c) => <String, dynamic>{
            'id': c['itemId'] ?? '',
            'text': c['itemText'] ?? '',
            'isRequired': (c['isRequired'] ?? '').toUpperCase() == 'TRUE',
          }).toList();
          break;
        }
        case 'table': {
          final blockOrder = b['order'] ?? '';
          final rows = tableRows.where((r) =>
            r['sectionId'] == sectionId &&
            (blockOrder.isEmpty || r['blockOrder'] == blockOrder)
          ).toList();
          final headers = (b['table_headers'] ?? '').split(',').map((h) => h.trim()).where((h) => h.isNotEmpty).toList();
          blockJson['data'] = {
            'caption': b['table_caption'] ?? '',
            'headers': headers,
            'rows': rows.map((r) {
              final cellValues = (r['cells'] ?? '').split(',').map((c) => c.trim()).toList();
              final cells = <String>[];
              for (int i = 0; i < headers.length; i++) {
                cells.add(i < cellValues.length ? cellValues[i] : '');
              }
              return {'cells': cells};
            }).toList(),
          };
          break;
        }
        case 'equipment': {
          final blockOrder = b['order'] ?? '';
          final items = equipmentItems.where((e) =>
            e['sectionId'] == sectionId &&
            (blockOrder.isEmpty || e['blockOrder'] == blockOrder)
          ).toList();
          blockJson['title'] = b['equipment_title'] ?? '';
          blockJson['items'] = items.map((e) => <String, dynamic>{
            'name': e['name'] ?? '',
            'purpose': e['purpose'] ?? '',
            'specification': e['specification'] ?? '',
          }).toList();
          break;
        }
        case 'image':
          blockJson['imageUrl'] = b['image_url'] ?? '';
          if ((b['image_caption'] ?? '').isNotEmpty) {
            blockJson['caption'] = b['image_caption'];
          }
          break;
      }

      result.add(blockJson);
    }

    return result;
  }

  List<Map<String, dynamic>> _acceptRejectForTopic(String topicId) {
    return acceptReject
        .where((a) => a['topicId'] == topicId)
        .map((a) => <String, dynamic>{
              'criteriaAr': a['criteriaAr'] ?? '',
              'criteriaEn': a['criteriaEn'] ?? '',
              'acceptanceLimitAr': a['acceptanceLimitAr'] ?? '',
              'acceptanceLimitEn': a['acceptanceLimitEn'] ?? '',
              'methodAr': a['methodAr'] ?? '',
              'methodEn': a['methodEn'] ?? '',
              'isCritical': (a['isCritical'] ?? '').toUpperCase() == 'TRUE',
              'reviewRequired': (a['reviewRequired'] ?? '').toUpperCase() == 'TRUE',
              'planKey': a['planKey'] ?? '',
              'codeReference': a['codeReference'] ?? '',
            })
        .toList();
  }

  List<Map<String, dynamic>> _commonMistakesForTopic(String topicId) {
    final items = commonMistakes.where((m) => m['topicId'] == topicId).toList();
    // If we have explicit commonMistakes CSV rows, use them
    if (items.isNotEmpty) {
      return items.map((m) => <String, dynamic>{
        'ar': m['mistakeAr'] ?? '',
        'en': m['mistakeEn'] ?? '',
      }).toList();
    }
    // Fallback: return empty list, errors populated from CSV if present
    return [];
  }

  String? _nullIfEmpty(String s) {
    s = s.trim();
    return s.isEmpty ? null : s;
  }

  int _parseInt(String s) {
    s = s.trim();
    if (s.isEmpty) return 0;
    final dot = s.indexOf('.');
    if (dot > 0) s = s.substring(0, dot);
    return int.tryParse(s) ?? 0;
  }
}

void writeCatalog(Map<String, dynamic> catalog, String outputPath) {
  final encoder = const JsonEncoder.withIndent('  ');
  final json = encoder.convert(catalog);
  File(outputPath).writeAsStringSync(json, flush: true);
}
