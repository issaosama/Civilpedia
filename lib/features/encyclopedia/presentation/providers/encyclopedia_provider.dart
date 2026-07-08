import 'package:flutter/foundation.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/topic_section.dart';
import '../../domain/repositories/encyclopedia_repository.dart';
import '../../../../core/di/app_dependencies.dart';

class EncyclopediaProvider extends ChangeNotifier {
  final EncyclopediaRepository _repository;
  String? _searchQuery;

  EncyclopediaProvider({EncyclopediaRepository? repository})
      : _repository = repository ?? AppDependencies.encyclopediaRepo;

  List<EngineeringTopic> _topics = [];
  List<EngineeringTopic> _categoryTopics = [];
  EngineeringTopic? _currentTopic;
  List<TopicSection> _currentSections = [];
  final Map<String, List<ContentBlock>> _blocksBySection = {};
  bool _isLoading = false;
  String? _error;

  List<EngineeringTopic> get topics => _searchQuery != null && _searchQuery!.trim().isNotEmpty
      ? _filteredTopics
      : _topics;
  List<EngineeringTopic> get categoryTopics => _categoryTopics;
  EngineeringTopic? get currentTopic => _currentTopic;
  List<TopicSection> get currentSections => _currentSections;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSearchQuery => _searchQuery;
  bool get isSearchActive => _searchQuery != null && _searchQuery!.trim().isNotEmpty;

  List<EngineeringTopic> get _filteredTopics {
    if (_searchQuery == null || _searchQuery!.trim().isEmpty) return _topics;
    final q = _searchQuery!.trim().toLowerCase();
    return _topics.where((t) =>
      t.titleAr.toLowerCase().contains(q) ||
      (t.titleEn?.toLowerCase().contains(q) ?? false) ||
      t.summary.toLowerCase().contains(q) ||
      t.tags.any((tag) => tag.toLowerCase().contains(q)) ||
      t.keyTopics.any((kt) => kt.toLowerCase().contains(q))
    ).toList();
  }

  List<ContentBlock> blocksForSection(String sectionId) =>
      _blocksBySection[sectionId] ?? <ContentBlock>[];

  bool blocksLoadedForSection(String sectionId) =>
      _blocksBySection.containsKey(sectionId);

  Future<void> loadTopicsByCategory(String categoryId) async {
    _setLoading();
    try {
      _categoryTopics = await _repository.getTopicsByCategory(categoryId);
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

  void searchTopics(String query) {
    _searchQuery = query;
    _error = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = null;
    notifyListeners();
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
