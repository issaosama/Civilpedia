import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../../../core/services/logger_service.dart';
import '../../domain/entities/category_info.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/topic_section.dart';

/// Records a single content item that was skipped because it could not be
/// parsed without aborting the rest of the catalog.
class CatalogParseSkip {
  const CatalogParseSkip({
    required this.kind,
    this.topicId,
    this.sectionId,
    this.blockIndex,
    this.blockType,
    this.reason,
  });

  /// One of: topic, section, block, category.
  final String kind;
  final String? topicId;
  final String? sectionId;
  final int? blockIndex;
  final String? blockType;
  final String? reason;

  @override
  String toString() {
    final buffer = StringBuffer(kind);
    if (topicId != null) buffer.write(' topic=$topicId');
    if (sectionId != null) buffer.write(' section=$sectionId');
    if (blockIndex != null) buffer.write(' blockIndex=$blockIndex');
    if (blockType != null) buffer.write(' type=$blockType');
    if (reason != null) buffer.write(' reason=$reason');
    return buffer.toString();
  }
}

/// Result of parsing a full catalog document.
class CatalogParseResult {
  final List<EngineeringTopic> topics;
  final Map<String, List<TopicSection>> sections;
  final Map<String, List<ContentBlock>> blocks;
  final Map<String, CategoryInfo> categories;
  final List<CatalogParseSkip> skips;

  const CatalogParseResult({
    required this.topics,
    required this.sections,
    required this.blocks,
    required this.categories,
    required this.skips,
  });
}

/// Parses a decoded catalog document, isolating malformed topics, sections,
/// blocks and category entries so a single bad content item can never drop
/// the entire valid catalog.
///
/// Only catalog-level structural failures (root not an object, or a top-level
/// collection missing / not a list or map) throw [FormatException]; callers
/// treat those as catastrophic and fall back to the legacy catalog.
CatalogParseResult parseCatalogJson(Map<String, dynamic> json) {
  final skips = <CatalogParseSkip>[];

  final topics = <EngineeringTopic>[];
  final topicsJson = json['topics'];
  if (topicsJson is! List) {
    throw const FormatException('catalog "topics" must be a JSON array');
  }
  for (var i = 0; i < topicsJson.length; i++) {
    final entry = topicsJson[i];
    if (entry is! Map<String, dynamic>) {
      skips.add(
        CatalogParseSkip(
          kind: 'topic',
          blockIndex: i,
          reason: 'entry is not an object',
        ),
      );
      continue;
    }
    try {
      topics.add(EngineeringTopic.fromJson(entry));
    } catch (e) {
      skips.add(
        CatalogParseSkip(
          kind: 'topic',
          topicId: _stringOrNull(entry['id']),
          blockIndex: i,
          reason: e.toString(),
        ),
      );
    }
  }

  final sections = <String, List<TopicSection>>{};
  final sectionsJson = json['sections'];
  if (sectionsJson is! Map<String, dynamic>) {
    throw const FormatException('catalog "sections" must be a JSON object');
  }
  sectionsJson.forEach((key, value) {
    final topicId = key.split('__').first;
    if (value is! List) {
      skips.add(
        CatalogParseSkip(
          kind: 'section',
          topicId: topicId,
          sectionId: key,
          reason: 'section list is not an array',
        ),
      );
      return;
    }
    final list = <TopicSection>[];
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is! Map<String, dynamic>) {
        skips.add(
          CatalogParseSkip(
            kind: 'section',
            topicId: topicId,
            sectionId: key,
            blockIndex: i,
            reason: 'entry is not an object',
          ),
        );
        continue;
      }
      try {
        list.add(TopicSection.fromJson(entry));
      } catch (e) {
        skips.add(
          CatalogParseSkip(
            kind: 'section',
            topicId: topicId,
            sectionId: _stringOrNull(entry['id']) ?? key,
            blockIndex: i,
            reason: e.toString(),
          ),
        );
      }
    }
    sections[key] = list;
  });

  final blocks = <String, List<ContentBlock>>{};
  final blocksJson = json['blocks'];
  if (blocksJson is! Map<String, dynamic>) {
    throw const FormatException('catalog "blocks" must be a JSON object');
  }
  blocksJson.forEach((key, value) {
    final topicId = key.split('__').first;
    if (value is! List) {
      skips.add(
        CatalogParseSkip(
          kind: 'block',
          topicId: topicId,
          sectionId: key,
          reason: 'block list is not an array',
        ),
      );
      return;
    }
    final list = <ContentBlock>[];
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is! Map<String, dynamic>) {
        skips.add(
          CatalogParseSkip(
            kind: 'block',
            topicId: topicId,
            sectionId: key,
            blockIndex: i,
            reason: 'entry is not an object',
          ),
        );
        continue;
      }
      try {
        list.add(contentBlockFromJson(entry));
      } catch (e) {
        skips.add(
          CatalogParseSkip(
            kind: 'block',
            topicId: topicId,
            sectionId: key,
            blockIndex: i,
            blockType: _stringOrNull(entry['type']),
            reason: e.toString(),
          ),
        );
      }
    }
    blocks[key] = list;
  });

  final categories = <String, CategoryInfo>{};
  final categoriesJson = json['categories'];
  if (categoriesJson is List) {
    for (var i = 0; i < categoriesJson.length; i++) {
      final entry = categoriesJson[i];
      if (entry is! Map<String, dynamic>) {
        skips.add(
          CatalogParseSkip(
            kind: 'category',
            blockIndex: i,
            reason: 'entry is not an object',
          ),
        );
        continue;
      }
      try {
        final category = CategoryInfo.fromJson(entry);
        categories[category.id] = category;
      } catch (e) {
        skips.add(
          CatalogParseSkip(
            kind: 'category',
            blockIndex: i,
            reason: e.toString(),
          ),
        );
      }
    }
  } else if (categoriesJson != null) {
    skips.add(
      const CatalogParseSkip(
        kind: 'category',
        reason: 'categories is not an array',
      ),
    );
  }

  return CatalogParseResult(
    topics: topics,
    sections: sections,
    blocks: blocks,
    categories: categories,
    skips: skips,
  );
}

String? _stringOrNull(Object? value) => value is String ? value : null;

class EncyclopediaJsonDataSource {
  EncyclopediaJsonDataSource({AssetBundle? bundle}) : _bundle = bundle;

  final AssetBundle? _bundle;
  List<EngineeringTopic>? _topics;
  Map<String, List<TopicSection>>? _sections;
  Map<String, List<ContentBlock>>? _blocks;
  Map<String, CategoryInfo>? _categories;
  List<CatalogParseSkip> _skips = const [];
  bool _loaded = false;
  bool _usingGeneratedCatalog = false;

  bool get usingGeneratedCatalog => _usingGeneratedCatalog;

  /// Skips recorded during the most recent successful load.
  @visibleForTesting
  List<CatalogParseSkip> get lastSkips => _skips;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    try {
      await _tryLoad('assets/encyclopedia/catalog.generated.json');
      _usingGeneratedCatalog = true;
    } catch (_) {
      await _tryLoad('assets/encyclopedia/catalog.json');
      _usingGeneratedCatalog = false;
    }

    _loaded = true;
  }

  Future<void> _tryLoad(String path) async {
    final jsonString = await (_bundle ?? rootBundle).loadString(path);
    final json = jsonDecode(jsonString);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('catalog root must be a JSON object');
    }

    final result = parseCatalogJson(json);
    _topics = result.topics;
    _sections = result.sections;
    _blocks = result.blocks;
    _categories = result.categories;
    _skips = result.skips;
    _logSkips();
  }

  void _logSkips() {
    for (final skip in _skips) {
      LoggerService.debug('[catalog] skipped malformed content: $skip');
    }
  }

  Future<List<EngineeringTopic>> fetchAllTopics() async {
    await _ensureLoaded();
    return List.unmodifiable(_topics!);
  }

  Future<List<EngineeringTopic>> fetchTopicsByCategory(
    String categoryId,
  ) async {
    await _ensureLoaded();
    return _topics!.where((t) => t.categoryId == categoryId).toList();
  }

  Future<EngineeringTopic?> fetchTopicById(String id) async {
    await _ensureLoaded();
    try {
      return _topics!.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<EngineeringTopic>> searchTopics(String query) async {
    await _ensureLoaded();
    final q = query.toLowerCase();
    return _topics!
        .where(
          (t) =>
              t.titleAr.contains(q) ||
              (t.titleEn?.toLowerCase().contains(q) == true) ||
              t.tags.any((tag) => tag.contains(q)) ||
              t.summary.contains(q),
        )
        .toList();
  }

  Future<List<TopicSection>> fetchSectionsForTopic(String topicId) async {
    await _ensureLoaded();
    return _sections![topicId] ?? <TopicSection>[];
  }

  Future<List<ContentBlock>> fetchBlocksForSection(
    String topicId,
    String sectionId,
  ) async {
    await _ensureLoaded();
    return _blocks!['${topicId}__$sectionId'] ?? <ContentBlock>[];
  }

  Future<Map<String, CategoryInfo>> fetchCategories() async {
    await _ensureLoaded();
    return Map.unmodifiable(_categories ?? const {});
  }
}
