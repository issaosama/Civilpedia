import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/topic_section.dart';
import '../../domain/repositories/encyclopedia_repository.dart';
import '../datasources/encyclopedia_json_datasource.dart';
import '../datasources/encyclopedia_local_datasource.dart';

class EncyclopediaRepositoryImpl implements EncyclopediaRepository {
  final EncyclopediaJsonDataSource _jsonDataSource;
  final EncyclopediaLocalDataSource _fallbackDataSource;

  EncyclopediaRepositoryImpl(
    this._jsonDataSource,
    this._fallbackDataSource,
  );

  @override
  Future<List<EngineeringTopic>> getAllTopics() async {
    try {
      return await _jsonDataSource.fetchAllTopics();
    } catch (_) {
      return _fallbackDataSource.fetchAllTopics();
    }
  }

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(
      String categoryId) async {
    try {
      return await _jsonDataSource.fetchTopicsByCategory(categoryId);
    } catch (_) {
      return _fallbackDataSource.fetchTopicsByCategory(categoryId);
    }
  }

  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    try {
      return await _jsonDataSource.fetchTopicById(id);
    } catch (_) {
      return _fallbackDataSource.fetchTopicById(id);
    }
  }

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async {
    try {
      return await _jsonDataSource.searchTopics(query);
    } catch (_) {
      return _fallbackDataSource.searchTopics(query);
    }
  }

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async {
    try {
      return await _jsonDataSource.fetchSectionsForTopic(topicId);
    } catch (_) {
      return _fallbackDataSource.fetchSectionsForTopic(topicId);
    }
  }

  @override
  Future<List<ContentBlock>> getBlocksForSection(String topicId, String sectionId) async {
    try {
      return await _jsonDataSource.fetchBlocksForSection(topicId, sectionId);
    } catch (_) {
      return _fallbackDataSource.fetchBlocksForSection(topicId, sectionId);
    }
  }
}
