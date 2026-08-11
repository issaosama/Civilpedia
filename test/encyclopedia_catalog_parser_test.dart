import 'dart:convert';
import 'dart:io';

import 'package:civilpedia/features/encyclopedia/data/datasources/encyclopedia_json_datasource.dart';
import 'package:civilpedia/features/encyclopedia/data/datasources/encyclopedia_local_datasource.dart';
import 'package:civilpedia/features/encyclopedia/data/repositories/encyclopedia_repository_impl.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final data = assets[key];
    if (data == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(utf8.encode(data));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> validTopic(String id) => {
    'id': id,
    'titleAr': 'العنوان $id',
    'categoryId': 'concrete',
    'summary': 'ملخص $id',
    'tags': <String>[],
    'relatedTopicIds': <String>[],
    'createdAt': '2024-01-01T00:00:00.000Z',
    'updatedAt': '2024-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> validSection(String id, [String type = 'execution']) => {
    'id': id,
    'title': 'قسم $id',
    'type': type,
    'order': 1,
  };

  Map<String, dynamic> buildCatalog({
    List<dynamic>? topics,
    Map<String, dynamic>? sections,
    Map<String, dynamic>? blocks,
    Object? categories,
  }) => {
    'topics': topics ?? [validTopic('t1'), validTopic('t2')],
    'sections':
        sections ??
        {
          't1': [validSection('s1')],
        },
    'blocks':
        blocks ??
        {
          't1__s1': [
            {'type': 'text', 'content': 'hello'},
          ],
        },
    if (categories != null) 'categories': categories,
  };

  group('parseCatalogJson - isolation', () {
    test('parses a valid catalog without skips', () {
      final result = parseCatalogJson(buildCatalog());
      expect(result.topics.length, 2);
      expect(result.sections['t1'], isNotNull);
      expect(result.sections['t1']!.length, 1);
      expect(result.blocks['t1__s1'], isNotNull);
      expect(result.blocks['t1__s1']!.length, 1);
      expect(result.categories, isEmpty);
      expect(result.skips, isEmpty);
    });

    test(
      'skips only the malformed block and keeps valid siblings in order',
      () {
        final result = parseCatalogJson(
          buildCatalog(
            blocks: {
              't1__s1': [
                {'type': 'text', 'content': 'first'},
                {'type': 'unknown_type', 'content': 'nope'},
                {'type': 'text', 'content': 'last'},
              ],
            },
          ),
        );
        final blocks = result.blocks['t1__s1']!;
        expect(blocks.length, 2);
        expect(blocks[0], isA<TextBlock>());
        expect((blocks[0] as TextBlock).content, 'first');
        expect(blocks[1], isA<TextBlock>());
        expect((blocks[1] as TextBlock).content, 'last');
        expect(result.skips.length, 1);
        expect(result.skips.single.kind, 'block');
        expect(result.skips.single.blockIndex, 1);
        expect(result.skips.single.blockType, 'unknown_type');
        expect(result.skips.single.topicId, 't1');
        expect(result.skips.single.sectionId, 't1__s1');
      },
    );

    test('skips a non-object block entry without dropping siblings', () {
      final result = parseCatalogJson(
        buildCatalog(
          blocks: {
            't1__s1': [
              {'type': 'text', 'content': 'ok'},
              'not-an-object',
            ],
          },
        ),
      );
      expect(result.blocks['t1__s1']!.length, 1);
      expect(result.skips.single.kind, 'block');
      expect(result.skips.single.blockIndex, 1);
    });

    test('skips a malformed topic and keeps the valid one', () {
      final result = parseCatalogJson(
        buildCatalog(
          topics: [
            validTopic('t1'),
            {'id': null, 'titleAr': 'broken'},
          ],
        ),
      );
      expect(result.topics.length, 1);
      expect(result.topics.single.id, 't1');
      expect(result.skips.single.kind, 'topic');
      expect(result.skips.single.blockIndex, 1);
    });

    test('skips a non-object topic entry', () {
      final result = parseCatalogJson(buildCatalog(topics: ['oops']));
      expect(result.topics, isEmpty);
      expect(result.skips.single.kind, 'topic');
      expect(result.skips.single.reason, 'entry is not an object');
    });

    test('skips a section with an invalid type', () {
      final result = parseCatalogJson(
        buildCatalog(
          sections: {
            't1': [
              validSection('s1', 'bogus_type'),
              validSection('s2', 'safety'),
            ],
          },
        ),
      );
      expect(result.sections['t1']!.length, 1);
      expect(result.sections['t1']!.single.id, 's2');
      expect(result.skips.single.kind, 'section');
      expect(result.skips.single.sectionId, 's1');
    });

    test('skips a section whose list value is not an array', () {
      final result = parseCatalogJson(
        buildCatalog(
          sections: {
            't1': 'not-a-list',
            't2': [validSection('s2')],
          },
        ),
      );
      expect(result.sections.containsKey('t1'), isFalse);
      expect(result.sections['t2']!.length, 1);
      expect(result.skips.single.kind, 'section');
      expect(result.skips.single.sectionId, 't1');
    });

    test('skips a block list value that is not an array', () {
      final result = parseCatalogJson(
        buildCatalog(
          blocks: {
            't1__s1': 42,
            't1__s2': [
              {'type': 'text', 'content': 'ok'},
            ],
          },
        ),
      );
      expect(result.blocks.containsKey('t1__s1'), isFalse);
      expect(result.blocks['t1__s2']!.length, 1);
      expect(result.skips.single.kind, 'block');
      expect(result.skips.single.sectionId, 't1__s1');
    });

    test('missing safety severity falls back to medium', () {
      final result = parseCatalogJson(
        buildCatalog(
          blocks: {
            't1__s1': [
              {
                'type': 'safety_note',
                'note': {'message': 'انتبه'},
              },
            ],
          },
        ),
      );
      final note = (result.blocks['t1__s1']!.single as SafetyNoteBlock).note;
      expect(note.severity, SafetySeverity.medium);
      expect(result.skips, isEmpty);
    });

    test('unknown safety severity falls back to medium', () {
      final result = parseCatalogJson(
        buildCatalog(
          blocks: {
            't1__s1': [
              {
                'type': 'safety_note',
                'note': {'message': 'انتبه', 'severity': 'extreme'},
              },
            ],
          },
        ),
      );
      final note = (result.blocks['t1__s1']!.single as SafetyNoteBlock).note;
      expect(note.severity, SafetySeverity.medium);
      expect(result.skips, isEmpty);
    });

    test('known safety severity is preserved', () {
      final result = parseCatalogJson(
        buildCatalog(
          blocks: {
            't1__s1': [
              {
                'type': 'safety_note',
                'note': {'message': 'خطر', 'severity': 'critical'},
              },
            ],
          },
        ),
      );
      final note = (result.blocks['t1__s1']!.single as SafetyNoteBlock).note;
      expect(note.severity, SafetySeverity.critical);
    });

    test('invalid topic level keeps the topic with a null level', () {
      final result = parseCatalogJson(
        buildCatalog(
          topics: [
            {...validTopic('t1'), 'level': 'expert-99'},
          ],
        ),
      );
      expect(result.topics.single.id, 't1');
      expect(result.topics.single.level, isNull);
      expect(result.skips, isEmpty);
    });

    test('malformed category entry is skipped', () {
      final result = parseCatalogJson(
        buildCatalog(
          categories: [
            {
              'id': 'c1',
              'title': {'ar': 'خرسانة'},
            },
            {'nope': true},
          ],
        ),
      );
      expect(result.categories.keys, ['c1']);
      expect(result.skips.single.kind, 'category');
    });

    test('non-list categories are ignored with a skip', () {
      final result = parseCatalogJson(buildCatalog(categories: 'not-a-list'));
      expect(result.categories, isEmpty);
      expect(result.skips.single.kind, 'category');
    });

    test('all topics malformed yields an empty topic list, no throw', () {
      final result = parseCatalogJson(
        buildCatalog(
          topics: [
            {'id': null},
            {'titleAr': 'broken'},
          ],
        ),
      );
      expect(result.topics, isEmpty);
      expect(result.skips.length, 2);
      expect(result.sections['t1']!.length, 1);
      expect(result.blocks['t1__s1']!.length, 1);
    });
  });

  group('parseCatalogJson - catalog-level failures', () {
    test('throws FormatException when topics is not a list', () {
      expect(() => parseCatalogJson({'topics': 'nope'}), throwsFormatException);
    });

    test('throws FormatException when sections is not an object', () {
      expect(
        () => parseCatalogJson({
          'topics': [validTopic('t1')],
          'sections': [validSection('s1')],
          'blocks': const {},
        }),
        throwsFormatException,
      );
    });

    test('throws FormatException when blocks is not an object', () {
      expect(
        () => parseCatalogJson({
          'topics': [validTopic('t1')],
          'sections': const {},
          'blocks': 'nope',
        }),
        throwsFormatException,
      );
    });
  });

  group(
    'EncyclopediaJsonDataSource - no mock fallback for isolated defects',
    () {
      test(
        'loads generated catalog with one malformed block skipped',
        () async {
          final catalog = buildCatalog(
            blocks: {
              't1__s1': [
                {'type': 'text', 'content': 'ok'},
                {'type': 'boom', 'content': 'bad'},
              ],
            },
          );
          final dataSource = EncyclopediaJsonDataSource(
            bundle: _TestAssetBundle({
              'assets/encyclopedia/catalog.generated.json': jsonEncode(catalog),
            }),
          );
          final topics = await dataSource.fetchAllTopics();

          expect(topics.length, 2);
          expect(dataSource.usingGeneratedCatalog, isTrue);
          expect(dataSource.lastSkips.length, 1);
          expect(dataSource.lastSkips.single.blockType, 'boom');

          final sections = await dataSource.fetchSectionsForTopic('t1');
          expect(sections.length, 1);

          final blocks = await dataSource.fetchBlocksForSection('t1', 's1');
          expect(blocks.length, 1);
          expect((blocks.single as TextBlock).content, 'ok');
        },
      );

      test(
        'all malformed topics yields empty list, not mock fallback',
        () async {
          final catalog = buildCatalog(
            topics: [
              {'id': null},
            ],
          );
          final dataSource = EncyclopediaJsonDataSource(
            bundle: _TestAssetBundle({
              'assets/encyclopedia/catalog.generated.json': jsonEncode(catalog),
            }),
          );
          final topics = await dataSource.fetchAllTopics();

          expect(topics, isEmpty);
          expect(dataSource.usingGeneratedCatalog, isTrue);
          expect(dataSource.lastSkips.single.kind, 'topic');
        },
      );
    },
  );

  group('EncyclopediaRepositoryImpl - catastrophic fallback preserved', () {
    test(
      'falls back to local mock data when catalog files are invalid',
      () async {
        final repository = EncyclopediaRepositoryImpl(
          EncyclopediaJsonDataSource(
            bundle: _TestAssetBundle({
              'assets/encyclopedia/catalog.generated.json': 'not json',
              'assets/encyclopedia/catalog.json': 'also not json',
            }),
          ),
          EncyclopediaLocalDataSource(),
        );
        final topics = await repository.getAllTopics();

        expect(topics.length, 7);
      },
    );
  });

  group('parseCatalogJson - production catalog regression', () {
    test('parses the real generated catalog without losing content', () {
      final file = File('assets/encyclopedia/catalog.generated.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'production catalog must exist for regression check',
      );
      final decoded = jsonDecode(file.readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());

      final result = parseCatalogJson(decoded as Map<String, dynamic>);

      expect(result.topics.length, 13);
      expect(result.sections.length, 13);
      final sectionCount = result.sections.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );
      expect(sectionCount, 117);
      expect(result.blocks.length, 117);
      final blockCount = result.blocks.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );
      expect(blockCount, 539);
      expect(result.categories.length, 6);
      expect(
        result.skips,
        isEmpty,
        reason: 'no content item may be skipped in the production catalog',
      );
    });
  });
}
