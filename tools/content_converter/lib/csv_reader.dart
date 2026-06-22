import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

class CsvReadResult {
  final List<Map<String, String>> rows;
  final String? error;
  final int lineCount;

  CsvReadResult({required this.rows, this.error, required this.lineCount});
}

CsvReadResult readCsv(String path) {
  if (!File(path).existsSync()) {
    return CsvReadResult(rows: [], error: 'File not found: $path', lineCount: 0);
  }

  List<int> bytes;
  try {
    bytes = File(path).readAsBytesSync();
  } catch (e) {
    return CsvReadResult(rows: [], error: 'Failed to read $path: $e', lineCount: 0);
  }

  // Strip UTF-8 BOM if present
  if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
    bytes = bytes.sublist(3);
  }

  String content;
  try {
    content = utf8.decode(bytes);
  } catch (e) {
    return CsvReadResult(rows: [], error: 'Invalid UTF-8 in $path: $e', lineCount: 0);
  }

  if (content.trim().isEmpty) {
    return CsvReadResult(rows: [], error: 'Empty file: $path', lineCount: 0);
  }

  // Normalize line endings: CRLF -> LF, then trailing CR -> LF
  content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  List<List<dynamic>> parsed;
  try {
    parsed = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(content);
  } catch (e) {
    return CsvReadResult(rows: [], error: 'CSV parse error in $path: $e', lineCount: 0);
  }

  if (parsed.length < 2) {
    return CsvReadResult(rows: [], error: 'CSV file has no data rows (header only or empty): $path', lineCount: 0);
  }

  final headers = parsed[0].map((h) => h.toString().trim()).toList();
  if (headers.isEmpty) {
    return CsvReadResult(rows: [], error: 'CSV file has no headers: $path', lineCount: 0);
  }

  final rows = <Map<String, String>>[];
  for (int i = 1; i < parsed.length; i++) {
    final row = parsed[i];
    final map = <String, String>{};
    for (int j = 0; j < headers.length; j++) {
      final value = j < row.length ? row[j].toString().trim() : '';
      map[headers[j]] = value;
    }
    // Skip completely empty rows
    if (map.values.every((v) => v.isEmpty)) continue;
    rows.add(map);
  }

  if (rows.isEmpty) {
    return CsvReadResult(rows: [], error: 'CSV file has no non-empty data rows: $path', lineCount: 0);
  }

  return CsvReadResult(rows: rows, lineCount: parsed.length);
}
