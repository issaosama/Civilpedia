import 'saved_item_reference.dart';

/// W3.1 — A pure read source for one legacy favorite id list.
typedef SavedReferenceIdsReader = Future<List<String>> Function();

/// W5.6 — A pure read source for the structured Saved-reference store.
typedef SavedReferenceStoreReader = Future<List<SavedItemReference>> Function();

/// W3.1 — Canonical Saved-reference resolver (M8 W3.1: "Merges dual stores
/// read-only").
///
/// The resolver reads the favorite stores AND the structured W5.6 store and
/// merges them into one canonical [SavedItemReference] projection. It is
/// READ-ONLY:
///
/// - never writes the legacy lists,
/// - never writes the structured store,
/// - never creates new Hive/SharedPreferences keys,
/// - never reorders or rewrites either stored list.
///
/// Read sources are injected as plain function types (same pattern as the
/// W2.2 `SearchAggregator`), so the resolver stays a pure domain unit with no
/// Hive or DI wiring. Production composition lives in
/// `lib/features/saved/data/hive_saved_reference_resolver.dart`.
///
/// Failure isolation: each store is read in its own awaited call, and the
/// merge receives whatever each read returned. A throwing reader surfaces as
/// the store's real defect rather than being masked.
class SavedReferenceResolver {
  const SavedReferenceResolver({
    required SavedReferenceIdsReader encyclopediaTopicIds,
    required SavedReferenceIdsReader legacyArticleIds,
    SavedReferenceStoreReader? structuredReferences,
  }) : _encyclopediaTopicIds = encyclopediaTopicIds,
       _legacyArticleIds = legacyArticleIds,
       _structuredReferences = structuredReferences;

  final SavedReferenceIdsReader _encyclopediaTopicIds;
  final SavedReferenceIdsReader _legacyArticleIds;
  final SavedReferenceStoreReader? _structuredReferences;

  /// Reads and merges all stores into the canonical Saved-reference list.
  ///
  /// All reads complete before the merge, so the result never depends on
  /// async timing or completion order. A resolver without a structured source
  /// behaves exactly as the W3.1 resolver did.
  Future<List<SavedItemReference>> resolve() async {
    final topicIds = await _encyclopediaTopicIds();
    final articleIds = await _legacyArticleIds();
    final List<SavedItemReference> structured;
    if (_structuredReferences != null) {
      structured = await _structuredReferences();
    } else {
      structured = const [];
    }
    return merge(
      encyclopediaTopicIds: topicIds,
      legacyArticleIds: articleIds,
      structuredReferences: structured,
    );
  }

  /// Deterministic read-only merge of the legacy stores and the structured
  /// W5.6 store (M7 §13/§29; W5.6 §Saved Reference Resolver).
  ///
  /// Each store keeps its internal order exactly as persisted:
  /// - `encyclopediaFavorites` is most-recent-first,
  /// - `favorites` is append order,
  /// - the structured store preserves insertion order (and true `savedAt`).
  ///
  /// Cross-store order is a fixed concatenation — Knowledge topics first, then
  /// legacy articles, then structured references — with no ranking and no
  /// interleaving. Legacy references keep `savedAt == null`; structured
  /// references keep their real `savedAt`. Duplicates are avoided by the
  /// canonical deterministic [SavedItemReference.id] (the structured store
  /// already prevents its own duplicates, and legacy namespaces cannot collide
  /// with it), so the projection never contains two identical ids.
  static List<SavedItemReference> merge({
    required List<String> encyclopediaTopicIds,
    required List<String> legacyArticleIds,
    List<SavedItemReference> structuredReferences = const [],
  }) {
    final result = <SavedItemReference>[
      for (final id in encyclopediaTopicIds)
        SavedItemReference(
          ownerDomain: SavedReferenceOwners.knowledge,
          entityType: SavedReferenceEntityTypes.topic,
          entityId: id,
        ),
      for (final id in legacyArticleIds)
        SavedItemReference(
          ownerDomain: SavedReferenceOwners.knowledge,
          entityType: SavedReferenceEntityTypes.article,
          entityId: id,
        ),
    ];
    final seen = <String>{for (final r in result) r.id};
    for (final ref in structuredReferences) {
      if (seen.add(ref.id)) {
        result.add(ref);
      }
    }
    return result;
  }
}