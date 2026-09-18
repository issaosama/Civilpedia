import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../../../core/services/logger_service.dart';
import '../../domain/entities/category_info.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/topic_section.dart';

/// Frozen P2-F local-content failure classification.
///
/// The generated catalog authority has NO network/offline/timeout variants.
/// Normal non-failure states (authoritative empty, searchNoResults,
/// topicNotFound) are NOT represented here.
enum EncyclopediaContentFailureKind {
  /// The authoritative generated packaged asset cannot be read/opened/loaded.
  assetUnavailable,

  /// The authoritative catalog failed structural/integrity validation:
  /// invalid JSON, invalid root shape, missing/wrong metadata, unsupported
  /// schema version, count inconsistency, or ANY parse skip in authoritative
  /// generated content. No partial authoritative publication.
  malformedContent,

  /// Any other unexpected local failure.
  unexpected,
}

/// Typed local-content failure for the Encyclopedia generated-catalog lane.
///
/// This is the ONLY failure type the P2-F production path may surface.
/// `cause` and `skips` are diagnostic-only; user-facing presentation MUST use
/// localized controlled copy, never raw exception text.
class EncyclopediaContentException implements Exception {
  const EncyclopediaContentException(
    this.kind, {
    this.message,
    this.cause,
    this.skips = const [],
  });

  final EncyclopediaContentFailureKind kind;

  /// Diagnostic message for development logging only. Never user-facing.
  final String? message;

  /// Underlying cause for diagnostics. Never user-facing.
  final Object? cause;

  /// Parse skips responsible for a [EncyclopediaContentFailureKind.
  /// malformedContent] failure (diagnostic only).
  final List<CatalogParseSkip> skips;

  @override
  String toString() {
    final buffer = StringBuffer('EncyclopediaContentException(kind: $kind');
    if (message != null) buffer.write(', message: $message');
    if (cause != null) buffer.write(', cause: $cause');
    if (skips.isNotEmpty) buffer.write(', skips: ${skips.length}');
    buffer.write(')');
    return buffer.toString();
  }
}

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
/// collection missing / not a list or map) throw [FormatException]. The P2-F
/// production datasource treats those, and ANY recorded [CatalogParseSkip], as
/// [EncyclopediaContentFailureKind.malformedContent] with no fallback.
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
  /// The ONLY production runtime authority (P2-F §3).
  static const String authoritativeAssetPath =
      'assets/encyclopedia/catalog.generated.json';

  static const String _generatedFormat = 'civilpedia-catalog-generated';
  static const int _generatedSchemaVersion = 1;

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

  /// Skips recorded during the most recent successful load. Diagnostic only;
  /// any skip in authoritative content fails the load as malformedContent.
  @visibleForTesting
  List<CatalogParseSkip> get lastSkips => _skips;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await _loadAuthoritative();
  }

  /// Runs the authoritative generated-catalog lane ONLY. There is no legacy or
  /// mock fallback: a failed authoritative load surfaces a typed
  /// [EncyclopediaContentException] and `_loaded` stays false so a retry
  /// re-attempts the same lane.
  Future<void> _loadAuthoritative() async {
    final json = await _readAuthoritativeMap();
    _validateMeta(json);
    final result = _parseStrict(json);
    _verifyDeclaredCounts(json['_meta'] as Map<String, dynamic>, result);

    _topics = result.topics;
    _sections = result.sections;
    _blocks = result.blocks;
    _categories = result.categories;
    _skips = const [];
    _usingGeneratedCatalog = true;
    _loaded = true;
  }

  Future<Map<String, dynamic>> _readAuthoritativeMap() async {
    final String jsonString;
    try {
      // `cache: false` so a manual retry genuinely re-attempts the
      // authoritative lane instead of replaying a memoized failed load
      // (CachingAssetBundle._stringCache retains errored futures).
      jsonString = await (_bundle ?? rootBundle)
          .loadString(authoritativeAssetPath, cache: false);
    } catch (e) {
      throw EncyclopediaContentException(
        EncyclopediaContentFailureKind.assetUnavailable,
        message: 'could not load the generated catalog asset',
        cause: e,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
        message: 'generated catalog is not valid JSON',
        cause: e,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
        message: 'generated catalog root must be a JSON object',
      );
    }
    return decoded;
  }

  void _validateMeta(Map<String, dynamic> json) {
    final meta = json['_meta'];
    if (meta is! Map<String, dynamic>) {
      throw const EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
        message: 'generated catalog requires a _meta object',
      );
    }
    if (meta['format'] != _generatedFormat) {
      throw const EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
        message: 'generated catalog format is not accepted',
      );
    }
    if (meta['schemaVersion'] != _generatedSchemaVersion) {
      throw const EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
        message: 'generated catalog schema version is not supported',
      );
    }
  }

  /// Strict complete authoritative parse (P2-F §7, §11). The tolerant parser
  /// records per-item skips for diagnostics, but ANY skip fails the whole
  /// authoritative catalog as malformedContent — no partial publication.
  CatalogParseResult _parseStrict(Map<String, dynamic> json) {
    final CatalogParseResult result;
    try {
      result = parseCatalogJson(json);
    } catch (e) {
      throw EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
        message: 'generated catalog structural parse failure',
        cause: e,
      );
    }
    if (result.skips.isNotEmpty) {
      LoggerService.debug('[catalog] imposed failures: '
          '${result.skips.length} malformed content items rejected');
      throw EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
        message: 'generated catalog contains malformed content',
        skips: result.skips,
      );
    }
    return result;
  }

  void _verifyDeclaredCounts(
    Map<String, dynamic> meta,
    CatalogParseResult result,
  ) {
    var sectionCount = 0;
    for (final list in result.sections.values) {
      sectionCount += list.length;
    }
    var blockCount = 0;
    for (final list in result.blocks.values) {
      blockCount += list.length;
    }

    final declared = <String, int>{
      'topicCount': result.topics.length,
      'sectionCount': sectionCount,
      'blockCount': blockCount,
    };
    for (final entry in declared.entries) {
      final value = meta[entry.key];
      if (value is! int || value != entry.value) {
        throw EncyclopediaContentException(
          EncyclopediaContentFailureKind.malformedContent,
          message:
              'generated catalog ${entry.key} does not match parsed content',
        );
      }
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
