import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/content_block.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/topic_section.dart';

class EncyclopediaJsonDataSource {
  List<EngineeringTopic>? _topics;
  Map<String, List<TopicSection>>? _sections;
  Map<String, List<ContentBlock>>? _blocks;
  bool _loaded = false;
  bool _usingGeneratedCatalog = false;

  bool get usingGeneratedCatalog => _usingGeneratedCatalog;

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
    final jsonString = await rootBundle.loadString(path);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    _topics = (json['topics'] as List<dynamic>)
        .map((t) => EngineeringTopic.fromJson(t as Map<String, dynamic>))
        .toList();

    _sections = (json['sections'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>)
            .map((s) => TopicSection.fromJson(s as Map<String, dynamic>))
            .toList(),
      ),
    );

    _blocks = (json['blocks'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>)
            .map((b) => contentBlockFromJson(b as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  Future<List<EngineeringTopic>> fetchAllTopics() async {
    await _ensureLoaded();
    return List.unmodifiable(_topics!);
  }

  Future<List<EngineeringTopic>> fetchTopicsByCategory(
      String categoryId) async {
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
        .where((t) =>
            t.titleAr.contains(q) ||
            (t.titleEn?.toLowerCase().contains(q) == true) ||
            t.tags.any((tag) => tag.contains(q)) ||
            t.summary.contains(q))
        .toList();
  }

  Future<List<TopicSection>> fetchSectionsForTopic(String topicId) async {
    await _ensureLoaded();
    return _sections![topicId] ?? <TopicSection>[];
  }

  Future<List<ContentBlock>> fetchBlocksForSection(String sectionId) async {
    await _ensureLoaded();
    return _blocks![sectionId] ?? <ContentBlock>[];
  }
}
