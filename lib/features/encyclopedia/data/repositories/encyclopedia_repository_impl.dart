import '../../domain/entities/category_info.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/topic_section.dart';
import '../../domain/repositories/encyclopedia_repository.dart';
import '../datasources/encyclopedia_json_datasource.dart';
import '../datasources/encyclopedia_local_datasource.dart';

/// P2-F repository implementation.
///
/// Production authority is the generated catalog lane only. There is NO
/// runtime legacy/mock fallback: typed local-content failures
/// ([EncyclopediaContentException]) and any unexpected error propagate to the
/// caller. The optional local/mock source is dev/test infrastructure that is
/// consulted ONLY when [useDevFallback] is explicitly enabled.
class EncyclopediaRepositoryImpl implements EncyclopediaRepository {
  final EncyclopediaJsonDataSource _jsonDataSource;
  final EncyclopediaLocalDataSource? _fallbackDataSource;
  final bool _useDevFallback;

  EncyclopediaRepositoryImpl(
    this._jsonDataSource,
    this._fallbackDataSource, {
    bool useDevFallback = false,
  }) : _useDevFallback = useDevFallback;

  Future<T> _run<T>(
    Future<T> Function() source,
    Future<T> Function() devFallback,
  ) async {
    try {
      return await source();
    } catch (e) {
      if (e is EncyclopediaContentException &&
          _useDevFallback &&
          _fallbackDataSource != null) {
        return await devFallback();
      }
      rethrow;
    }
  }

  @override
  Future<List<EngineeringTopic>> getAllTopics() {
    return _run(
      () => _jsonDataSource.fetchAllTopics(),
      () => _fallbackDataSource!.fetchAllTopics(),
    );
  }

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) {
    return _run(
      () => _jsonDataSource.fetchTopicsByCategory(categoryId),
      () => _fallbackDataSource!.fetchTopicsByCategory(categoryId),
    );
  }

  @override
  Future<EngineeringTopic?> getTopicById(String id) {
    return _run(
      () => _jsonDataSource.fetchTopicById(id),
      () => _fallbackDataSource!.fetchTopicById(id),
    );
  }

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) {
    return _run(
      () => _jsonDataSource.searchTopics(query),
      () => _fallbackDataSource!.searchTopics(query),
    );
  }

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) {
    return _run(
      () => _jsonDataSource.fetchSectionsForTopic(topicId),
      () => _fallbackDataSource!.fetchSectionsForTopic(topicId),
    );
  }

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) {
    return _run(
      () => _jsonDataSource.fetchBlocksForSection(topicId, sectionId),
      () => _fallbackDataSource!.fetchBlocksForSection(topicId, sectionId),
    );
  }

  @override
  Future<Map<String, CategoryInfo>> getCategories() {
    return _run(
      () => _jsonDataSource.fetchCategories(),
      () => _fallbackDataSource!.fetchCategories(),
    );
  }
}