import 'dart:io';

import 'package:content_converter/csv_reader.dart';
import 'package:content_converter/json_builder.dart';
import 'package:content_converter/validator.dart';

void main(List<String> args) {
  final baseDir = args.isNotEmpty ? args[0] : 'sample';
  final outputPath = args.length > 1 ? args[1] : '../assets/encyclopedia/catalog.json';

  print('Content Converter');
  print('  Input directory: $baseDir');
  print('  Output: $outputPath');
  print('');

  // Read all CSVs
  final filenames = [
    'topics.csv',
    'sections.csv',
    'blocks.csv',
    'checklist_items.csv',
    'table_rows.csv',
    'accept_reject.csv',
    'common_mistakes.csv',
    'equipment_items.csv',
  ];

  final results = <String, CsvReadResult>{};
  for (final f in filenames) {
    final path = '$baseDir/$f';
    print('Reading $f...');
    final result = readCsv(path);
    results[f] = result;
    if (result.error != null) {
      print('  ✗ ${result.error}');
    } else {
      print('  ✓ ${result.rows.length} rows');
    }
  }

  // Allow continuation on warning-only read failures (empty files, missing files)
  final criticalReadErrors = results.values.any((r) => r.error != null && r.error!.contains('File not found'));
  if (criticalReadErrors) {
    print('');
    print('ERROR: Critical read failures. Aborting.');
    exit(1);
  }

  print('');

  // Validate
  print('Validating...');
  final validationResult = validateAll(
    topics: results['topics.csv']!.rows,
    sections: results['sections.csv']!.rows,
    blocks: results['blocks.csv']!.rows,
    checklistItems: results['checklist_items.csv']!.rows,
    tableRows: results['table_rows.csv']!.rows,
    acceptReject: results['accept_reject.csv']!.rows,
    commonMistakes: results['common_mistakes.csv']!.rows,
    equipmentItems: results['equipment_items.csv']!.rows,
  );
  validationResult.printReport();

  if (validationResult.hasErrors) {
    print('');
    print('ERROR: Validation contains hard errors. Aborting.');
    print('Fix errors and re-run. Warnings do not block generation.');
    exit(1);
  }

  print('');

  // Build
  print('Building catalog...');
  final builder = CatalogBuilder(
    topics: results['topics.csv']!.rows,
    sections: results['sections.csv']!.rows,
    blocks: results['blocks.csv']!.rows,
    checklistItems: results['checklist_items.csv']!.rows,
    tableRows: results['table_rows.csv']!.rows,
    acceptReject: results['accept_reject.csv']!.rows,
    commonMistakes: results['common_mistakes.csv']!.rows,
    equipmentItems: results['equipment_items.csv']!.rows,
  );

  final catalog = builder.build();
  final topicCount = (catalog['topics'] as List).length;

  writeCatalog(catalog, outputPath);

  final fileSize = File(outputPath).lengthSync();
  print('  ✓ $topicCount topics written to $outputPath ($fileSize bytes)');
  print('');
  print('Done.');
}
