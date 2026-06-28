/// Read-only comparison of official catalog vs generated catalog.
///
/// Usage:
///   dart run tools/content_studio/scripts/compare_catalogs.dart

import 'dart:convert';
import 'dart:io';

String officialPath = r'D:\Civilpedia\assets\encyclopedia\catalog.json';
String generatedPath = r'D:\Civilpedia\app_ready_jsons\catalog.generated.json';

void section(String s) => print('\n=== $s ===');
String diffStr(Set<String> s) => s.isEmpty ? 'none' : s.join(', ');

void main() {
  print('=== Catalog Compatibility Comparison ===');
  print('Official:  $officialPath');
  print('Generated: $generatedPath\n');

  if (!File(officialPath).existsSync()) {
    print('❌ Official catalog not found: $officialPath'); return;
  }
  if (!File(generatedPath).existsSync()) {
    print('❌ Generated catalog not found: $generatedPath'); return;
  }

  final oJson = jsonDecode(File(officialPath).readAsStringSync()) as Map<String, dynamic>;
  final gJson = jsonDecode(File(generatedPath).readAsStringSync()) as Map<String, dynamic>;

  section('1. TOP-LEVEL KEYS');
  compareKeys(oJson, gJson, 'root');

  section('2. _meta SECTION');
  print('Official has _meta: ${oJson.containsKey("_meta")}');
  if (oJson.containsKey('_meta')) {
    print('Official _meta keys: ${(oJson['_meta'] as Map).keys.join(", ")}');
  }
  print('Generated _meta keys: ${(gJson['_meta'] as Map).keys.join(", ")}');

  section('3. TOPICS ARRAY');
  final oTopics = (oJson['topics'] as List).cast<Map<String, dynamic>>();
  final gTopics = (gJson['topics'] as List).cast<Map<String, dynamic>>();
  print('Official count:  ${oTopics.length}');
  print('Generated count: ${gTopics.length}');

  final oIds = oTopics.map((t) => t['id'] as String).toSet();
  final gIds = gTopics.map((t) => t['id'] as String).toSet();
  print('Topic IDs — Official: ${oIds.join(", ")}');
  print('Topic IDs — Generated: ${gIds.join(", ")}');
  print('Only in official: ${diffStr(oIds.difference(gIds))}');
  print('Only in generated: ${diffStr(gIds.difference(oIds))}');

  // Compare topic field shapes
  if (oTopics.isNotEmpty && gTopics.isNotEmpty) {
    final oKeys = oTopics.first.keys.toSet();
    final gKeys = gTopics.first.keys.toSet();
    print('\nTopic field keys (from first topic):');
    print('Official-only: ${diffStr(oKeys.difference(gKeys))}');
    print('Generated-only: ${diffStr(gKeys.difference(oKeys))}');
    print('Intersection: ${oKeys.intersection(gKeys).join(", ")}');
  }

  // Detailed comparison for iraqi-tiles-types
  Map<String, dynamic>? oTile;
  Map<String, dynamic>? gTile;
  try {
    oTile = oTopics.firstWhere((t) => t['id'] == 'iraqi-tiles-types');
  } catch (_) {}
  try {
    gTile = gTopics.firstWhere((t) => t['id'] == 'iraqi-tiles-types');
  } catch (_) {}

  if (oTile != null && gTile != null) {
    section('4. DETAILED TOPIC FIELDS (iraqi-tiles-types)');
    final allKeys = <String>{...oTile.keys, ...gTile.keys};
    for (final key in allKeys.toList()..sort()) {
      final ov = oTile[key];
      final gv = gTile[key];
      if (key == 'tags' || key == 'relatedTopicIds' || key == 'relatedChecklistIds') {
        // Arrays — compare by length
        final ovList = (ov as List?) ?? [];
        final gvList = (gv as List?) ?? [];
        print('  $key: official=[${ovList.join(", ")}] generated=[${gvList.join(", ")}]');
        continue;
      }
      if (key == 'commonMistakes' || key == 'acceptRejectItems' || key == 'sections') continue;
      if (key == 'simpleExplanation' || key == 'beforeWork' || key == 'duringWork' || key == 'afterWork' ||
          key == 'codeNotes' || key == 'siteNotes' || key == 'reportWording') {
        final ovMap = ov as Map? ?? {};
        final gvMap = gv as Map? ?? {};
        final ok = ovMap.keys.join(", ");
        final gk = gvMap.keys.join(", ");
        if (ok == gk) {
          print('  $key: same keys {$ok} ✅');
        } else {
          print('  $key: official={$ok} generated={$gk} ❌ DIFF');
        }
        continue;
      }
      // Scalar comparison
      if (ov == gv) {
        print('  $key: "$ov" ✅');
      } else {
        print('  $key: official="$ov" generated="$gv" ❌ DIFF');
      }
    }
  }

  section('5. SECTIONS MAP');
  final oSections = (oJson['sections'] as Map<String, dynamic>);
  final gSections = (gJson['sections'] as Map<String, dynamic>);
  print('Official keys:  ${oSections.keys.join(", ")}');
  print('Generated keys: ${gSections.keys.join(", ")}');
  print('Only official: ${diffStr(oSections.keys.toSet().difference(gSections.keys.toSet()))}');
  print('Only generated: ${diffStr(gSections.keys.toSet().difference(oSections.keys.toSet()))}');

  // Compare section shapes
  final allSectionTopicKeys = <String>{...oSections.keys, ...gSections.keys};
  for (final tid in allSectionTopicKeys) {
    final oList = oSections[tid] as List?;
    final gList = gSections[tid] as List?;
    if (oList == null) { print('  Topic "$tid": MISSING in official'); continue; }
    if (gList == null) { print('  Topic "$tid": MISSING in generated'); continue; }
    print('  Topic "$tid": official=${oList.length} sections, generated=${gList.length} sections');
    for (final gs in gList.cast<Map<String, dynamic>>()) {
      final match = oList.cast<Map<String, dynamic>>().where((s) => s['id'] == gs['id']);
      if (match.isEmpty) { print('    Section ${gs['id']}: only in generated'); continue; }
      final ms = match.first;
      final diff = ms.keys.toSet().difference(gs.keys.toSet());
      if (diff.isNotEmpty) print('    Section ${gs['id']}: official has extra keys: $diff');
      final diff2 = gs.keys.toSet().difference(ms.keys.toSet());
      if (diff2.isNotEmpty) print('    Section ${gs['id']}: generated has extra keys: $diff2');
    }
  }

  section('6. BLOCKS MAP');
  final oBlocks = (oJson['blocks'] as Map<String, dynamic>);
  final gBlocks = (gJson['blocks'] as Map<String, dynamic>);
  print('Official keys:  ${oBlocks.keys.join(", ")}');
  print('Generated keys: ${gBlocks.keys.join(", ")}');
  print('Only official: ${diffStr(oBlocks.keys.toSet().difference(gBlocks.keys.toSet()))}');
  print('Only generated: ${diffStr(gBlocks.keys.toSet().difference(oBlocks.keys.toSet()))}');

  // Block type comparison per section
  final allBlockKeys = <String>{...oBlocks.keys, ...gBlocks.keys};
  for (final secId in allBlockKeys) {
    final oBList = oBlocks[secId] as List?;
    final gBList = gBlocks[secId] as List?;
    print('\n--- Section: $secId ---');
    if (oBList == null) { print('  Official: MISSING'); } else { print('  Official: ${oBList.length} blocks'); }
    if (gBList == null) { print('  Generated: MISSING'); } else { print('  Generated: ${gBList.length} blocks'); }

    if (oBList != null && gBList != null && oBList.length == gBList.length) {
      for (int i = 0; i < oBList.length; i++) {
        final ob = oBList[i] as Map<String, dynamic>;
        final gb = gBList[i] as Map<String, dynamic>;
        final oType = ob['type'] as String;
        final gType = gb['type'] as String;
        if (oType != gType) { print('  Block $i: TYPE MISMATCH $oType vs $gType ❌'); continue; }

        final oBKeys = ob.keys.toSet();
        final gBKeys = gb.keys.toSet();
        final extraO = oBKeys.difference(gBKeys);
        final extraG = gBKeys.difference(oBKeys);
        if (extraO.isNotEmpty) print('  Block $i ($oType): official has extra keys: $extraO');
        if (extraG.isNotEmpty) print('  Block $i ($oType): generated has extra keys: $extraG');

        if (oType == 'table') {
          final od = (ob['data'] as Map<String, dynamic>);
          final gd = (gb['data'] as Map<String, dynamic>);
          print('  Table: official caption="${od['caption']}" generated="${gd['caption']}"');
          print('  Table: official ${(od['headers'] as List).length} headers, generated ${(gd['headers'] as List).length}');
          print('  Table: official ${(od['rows'] as List).length} rows, generated ${(gd['rows'] as List).length}');
        }
        if (oType == 'execution_step') {
          final os = (ob['step'] as Map<String, dynamic>);
          final gs = (gb['step'] as Map<String, dynamic>);
          print('  Step ${os['stepNumber']}: official desc="${os['description']}"');
          print('  Step ${gs['stepNumber']}: generated desc="${gs['description']}"');
        }
        if (oType == 'safety_note') {
          final on = (ob['note'] as Map<String, dynamic>);
          final gn = (gb['note'] as Map<String, dynamic>);
          print('  Safety: official msg="${on['message']}" generated="${gn['message']}"');
          print('  Safety: official severity="${on['severity']}" generated="${gn['severity']}"');
        }
        if (oType == 'text') {
          print('  Text: official content="${ob['content']}"');
          print('  Text: generated content="${gb['content']}"');
          print('  Text: official variant="${ob['variant']}" generated variant="${gb['variant']}"');
        }
        if (oType == 'checklist') {
          final oItems = (ob['items'] as List?)?.length ?? 0;
          final gItems = (gb['items'] as List?)?.length ?? 0;
          print('  Checklist: official items=$oItems generated items=$gItems');
        }
      }
    }
  }

  section('7. COMMON MISTAKES');
  if (oTile != null && gTile != null) {
    final oM = (oTile['commonMistakes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final gM = (gTile['commonMistakes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    print('Official: ${oM.length} items');
    print('Generated: ${gM.length} items');
    if (oM.isNotEmpty) {
      final keys = oM.first.keys.join(", ");
      print('Official keys: $keys');
    }
    if (gM.isNotEmpty) {
      final keys = gM.first.keys.join(", ");
      print('Generated keys: $keys');
    }
  }

  section('8. ACCEPT/REJECT ITEMS');
  if (oTile != null && gTile != null) {
    final oA = (oTile['acceptRejectItems'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final gA = (gTile['acceptRejectItems'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    print('Official: ${oA.length} items');
    print('Generated: ${gA.length} items');
    if (oA.isNotEmpty) print('Official keys: ${oA.first.keys.join(", ")}');
    if (gA.isNotEmpty) print('Generated keys: ${gA.first.keys.join(", ")}');
  }

  section('9. REPORT WORDING');
  if (oTile != null && gTile != null) {
    print('Official:  ${jsonEncode(oTile['reportWording'])}');
    print('Generated: ${jsonEncode(gTile['reportWording'])}');
  }

  section('10. RELATED TOOL ROUTES');
  if (oTile != null && gTile != null) {
    print('Official:  ${oTile['relatedToolRoutes']}');
    print('Generated: ${gTile['relatedToolRoutes']}');
  }

  section('11. FEATURED IMAGE');
  if (oTile != null && gTile != null) {
    print('Official:  ${oTile['featuredImageUrl']}');
    print('Generated: ${gTile['featuredImageUrl']}');
  }

  print('\n=== Comparison complete ===');
  print('See catalog_compatibility_report.md for full analysis.');
}

void compareKeys(Map<String, dynamic> a, Map<String, dynamic> b, String label) {
  final aKeys = a.keys.toSet();
  final bKeys = b.keys.toSet();
  print('$label keys:');
  print('  Both: ${aKeys.intersection(bKeys).join(", ")}');
  print('  Only in official: ${diffStr(aKeys.difference(bKeys))}');
  print('  Only in generated: ${diffStr(bKeys.difference(aKeys))}');
}
