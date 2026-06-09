import 'package:flutter/foundation.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/topic_section.dart';
import '../../data/datasources/encyclopedia_local_datasource.dart';
import '../../data/repositories/encyclopedia_repository_impl.dart';

class EncyclopediaProvider extends ChangeNotifier {
  final _repository =
      EncyclopediaRepositoryImpl(EncyclopediaLocalDataSource());

  List<EngineeringTopic> _topics = [];
  EngineeringTopic? _currentTopic;
  List<TopicSection> _currentSections = [];
  final Map<String, List<ContentBlock>> _blocksBySection = {};
  bool _isLoading = false;
  String? _error;

  List<EngineeringTopic> get topics => _topics;
  EngineeringTopic? get currentTopic => _currentTopic;
  List<TopicSection> get currentSections => _currentSections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ContentBlock> blocksForSection(String sectionId) =>
      _blocksBySection[sectionId] ?? [];

  bool blocksLoadedForSection(String sectionId) =>
      _blocksBySection.containsKey(sectionId);

  Future<void> loadTopicsByCategory(String categoryId) async {
    _setLoading();
    try {
      _topics = await _repository.getTopicsByCategory(categoryId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _notify();
  }

  Future<void> loadAllTopics() async {
    _setLoading();
    try {
      _topics = await _repository.getAllTopics();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _notify();
  }

  Future<void> loadTopicDetail(String topicId) async {
    _setLoading();
    try {
      _currentTopic = await _repository.getTopicById(topicId);
      _currentSections = await _repository.getSectionsForTopic(topicId);
      _blocksBySection.clear();
      for (final section in _currentSections) {
        final blocks =
            await _repository.getBlocksForSection(section.id);
        _blocksBySection[section.id] = blocks;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _notify();
  }

  void _setLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _notify() {
    _isLoading = false;
    notifyListeners();
  }
}
