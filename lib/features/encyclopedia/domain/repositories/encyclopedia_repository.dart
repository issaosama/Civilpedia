import '../../domain/entities/category_info.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/topic_section.dart';

abstract class EncyclopediaRepository {
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId);

  Future<EngineeringTopic?> getTopicById(String id);

  Future<List<EngineeringTopic>> searchTopics(String query);

  Future<List<EngineeringTopic>> getAllTopics();

  Future<List<TopicSection>> getSectionsForTopic(String topicId);

  Future<List<ContentBlock>> getBlocksForSection(String topicId, String sectionId);

  Future<Map<String, CategoryInfo>> getCategories();
}
