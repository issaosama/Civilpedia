import 'package:flutter/foundation.dart';
import '../../data/datasources/encyclopedia_json_datasource.dart';
import '../../domain/entities/category_info.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/topic_section.dart';
import '../../domain/repositories/encyclopedia_repository.dart';
import '../../../../core/di/app_dependencies.dart';

/// P2-F typed local-content failure state + known-good preservation.
///
/// Manual retry reattempts the SAME authoritative generated lane only
/// (P2-F §13). No auto-loop, no legacy/mock fallback, no connectivity.
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
  Map<String, CategoryInfo> _categories = {};
  bool _isLoading = false;
  EncyclopediaContentException? _contentFailure;
  bool _hasCompletedInitialLoad = false;

  // ── Identity tracking (P2-F §12): prevents cross-entity stale masquerading ──
  String? _requestedCategoryId;
  String? _requestedTopicId;

  List<EngineeringTopic> get topics => _searchQuery != null && _searchQuery!.trim().isNotEmpty
      ? _filteredTopics
      : _topics;
  List<EngineeringTopic> get allTopics => _topics;
  List<EngineeringTopic> get categoryTopics => _categoryTopics;
  EngineeringTopic? get currentTopic => _currentTopic;
  List<TopicSection> get currentSections => _currentSections;
  Map<String, CategoryInfo> get categories => _categories;
  bool get isLoading => _isLoading;

  /// Raw exception-derived text. Home/saved surfaces ONLY null-check this;
  /// it MUST NEVER be passed to any user-facing Text widget (P2-F §14).
  /// The four encyclopedia screens use [contentFailure] with localized copy.
  String? get error => _contentFailure?.toString();

  /// True once a catalog load attempt has finished, whether it succeeded
  /// (with or without topics) or failed.
  bool get hasCompletedInitialLoad => _hasCompletedInitialLoad;
  String? get currentSearchQuery => _searchQuery;
  bool get isSearchActive => _searchQuery != null && _searchQuery!.trim().isNotEmpty;

  // ── P2-F typed failure getters ──

  EncyclopediaContentException? get contentFailure => _contentFailure;
  bool get hasContentFailure => _contentFailure != null;

  /// True when a content failure is active but the detail content being shown
  /// belongs to the SAME topic that failed to reload (known-good, P2-F §12).
  bool get showingSameTopicKnownGood =>
      _contentFailure != null &&
      _currentTopic != null &&
      _requestedTopicId == _currentTopic!.id;

  /// True when a content failure is active but the topics for the currently
  /// requested category are preserved (same-category reload failure).
  /// A cross-category failure clears `_categoryTopics`, so this is
  /// identity-safe (P2-F §12).
  bool get showingSameCategoryKnownGood =>
      _contentFailure != null &&
      _requestedCategoryId != null &&
      _categoryTopics.isNotEmpty;

  /// True when a content failure is active but the authoritative full catalog
  /// known-good topics are preserved (reload failure). The catalog is a single
  /// authority, so preserved topics always belong to it.
  bool get showingKnownGoodCatalog =>
      _contentFailure != null && _topics.isNotEmpty;

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

  String categoryLabel(String id, {bool isArabic = true}) {
    final cat = _categories[id];
    if (cat == null) return id;
    return isArabic ? cat.titleAr : cat.titleEn;
  }

  EngineeringTopic? topicById(String id) {
    for (final topic in _topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  List<EngineeringTopic> resolveTopics(Iterable<String> ids) {
    final resolved = <EngineeringTopic>[];
    for (final id in ids) {
      final topic = topicById(id);
      if (topic != null) resolved.add(topic);
    }
    return resolved;
  }

  // ── Load operations ──

  Future<void> loadCategories() async {
    try {
      _categories = await _repository.getCategories();
    } catch (e) {
      _contentFailure = _classifyError(e);
    }
  }

  Future<void> loadTopicsByCategory(String categoryId) async {
    _setLoading();
    try {
      _categoryTopics = await _repository.getTopicsByCategory(categoryId);
      _requestedCategoryId = categoryId;
      _contentFailure = null;
    } catch (e) {
      _contentFailure = _classifyError(e);
      // Cross-category identity safety: never present another category's
      // topics as the requested category's. Same-category reload preserves
      // the known-good topic list (P2-F §12).
      if (_requestedCategoryId != categoryId) {
        _categoryTopics = const [];
      }
      _requestedCategoryId = categoryId;
    }
    _notify();
  }

  Future<void>? _loadAllTopicsFuture;

  Future<void> loadAllTopics() {
    final inFlight = _loadAllTopicsFuture;
    if (inFlight != null) return inFlight;
    final future = _loadAllTopicsCore().whenComplete(() {
      _loadAllTopicsFuture = null;
    });
    _loadAllTopicsFuture = future;
    return future;
  }

  Future<void> _loadAllTopicsCore() async {
    _setLoading();
    try {
      final loadedTopics = await _repository.getAllTopics();
      final loadedCategories = await _repository.getCategories();
      _topics = loadedTopics;
      _categories = loadedCategories;
      _contentFailure = null;
    } catch (e) {
      // Known-good preservation (P2-F §12): _topics/_categories are only
      // assigned on success, so a reload failure leaves them intact.
      _contentFailure = _classifyError(e);
    }
    _hasCompletedInitialLoad = true;
    _notify();
  }

  /// Loads a single topic detail. Cross-topic failure clears any stale
  /// previous topic data so Topic A is NEVER presented as Topic B
  /// (P2-F §12). Same-topic reload failure preserves known-good detail
  /// state and surfaces a controlled local content failure notice.
  Future<void> loadTopicDetail(String topicId) async {
    _setLoading();
    try {
      final topic = await _repository.getTopicById(topicId);
      final sections = await _repository.getSectionsForTopic(topicId);
      final blocks = <String, List<ContentBlock>>{};
      for (final section in sections) {
        blocks[section.id] =
            await _repository.getBlocksForSection(topicId, section.id);
      }
      _currentTopic = topic;
      _currentSections = sections;
      _blocksBySection
        ..clear()
        ..addAll(blocks);
      _requestedTopicId = topicId;
      _contentFailure = null;
    } catch (e) {
      _contentFailure = _classifyError(e);
      // Identity safety: if the failed topic is NOT the one already being
      // displayed, wipe the old data to prevent cross-topic masquerading.
      if (_currentTopic?.id != topicId) {
        _currentTopic = null;
        _currentSections = const [];
        _blocksBySection.clear();
      }
      _requestedTopicId = topicId;
    }
    _notify();
  }

  void searchTopics(String query) {
    _searchQuery = query;
    _contentFailure = null;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = null;
    notifyListeners();
  }

  // ── Internal helpers ──

  void _setLoading() {
    _isLoading = true;
    _contentFailure = null;
    notifyListeners();
  }

  void _notify() {
    _isLoading = false;
    notifyListeners();
  }

  /// Classifies any thrown exception into a typed P2-F content failure.
  /// Unexpected exceptions are wrapped as [EncyclopediaContentFailureKind.
  /// unexpected] so raw exception text never reaches UI.
  EncyclopediaContentException _classifyError(Object error) {
    if (error is EncyclopediaContentException) return error;
    return EncyclopediaContentException(
      EncyclopediaContentFailureKind.unexpected,
      cause: error,
    );
  }
}