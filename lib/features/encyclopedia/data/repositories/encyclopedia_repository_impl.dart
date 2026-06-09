import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/topic_section.dart';
import '../../domain/repositories/encyclopedia_repository.dart';
import '../datasources/encyclopedia_local_datasource.dart';

class EncyclopediaRepositoryImpl implements EncyclopediaRepository {
  final EncyclopediaLocalDataSource _dataSource;

  EncyclopediaRepositoryImpl(this._dataSource);

  @override
  Future<List<EngineeringTopic>> getAllTopics() async {
    return _dataSource.fetchAllTopics();
  }

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(
      String categoryId) async {
    return _dataSource.fetchTopicsByCategory(categoryId);
  }

  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    return _dataSource.fetchTopicById(id);
  }

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async {
    return _dataSource.searchTopics(query);
  }

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async {
    return _dataSource.fetchSectionsForTopic(topicId);
  }

  @override
  Future<List<ContentBlock>> getBlocksForSection(String sectionId) async {
    return _dataSource.fetchBlocksForSection(sectionId);
  }
}
