import 'saved_item_reference.dart';

/// W3.1 — A pure read source for one legacy favorite id list.
typedef SavedReferenceIdsReader = Future<List<String>> Function();

/// W3.1 — Canonical Saved-reference resolver (M8 W3.1: "Merges dual stores
/// read-only").
///
/// The resolver reads BOTH current favorite stores and merges them into one
/// canonical [SavedItemReference] projection. It is READ-ONLY:
///
/// - never writes the legacy lists,
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
  }) : _encyclopediaTopicIds = encyclopediaTopicIds,
       _legacyArticleIds = legacyArticleIds;

  final SavedReferenceIdsReader _encyclopediaTopicIds;
  final SavedReferenceIdsReader _legacyArticleIds;

  /// Reads and merges both stores into the canonical Saved-reference list.
  ///
  /// Both reads complete before the merge, so the result never depends on
  /// async timing or completion order.
  Future<List<SavedItemReference>> resolve() async {
    final topicIds = await _encyclopediaTopicIds();
    final articleIds = await _legacyArticleIds();
    return merge(
      encyclopediaTopicIds: topicIds,
      legacyArticleIds: articleIds,
    );
  }

  /// Deterministic read-only merge of the two legacy stores (M7 §13/§29).
  ///
  /// Each store keeps its internal order exactly as persisted:
  /// `encyclopediaFavorites` is most-recent-first and `favorites` is append
  /// order. Cross-store order is a fixed concatenation — Knowledge topics
  /// first, then legacy articles — with no ranking, no interleaving, and no
  /// fabricated timestamps. References are never de-duplicated: current write
  /// paths already prevent intra-store duplicates, and namespaces make
  /// cross-store duplicates impossible, so the projection preserves exactly
  /// what is stored.
  static List<SavedItemReference> merge({
    required List<String> encyclopediaTopicIds,
    required List<String> legacyArticleIds,
  }) {
    return <SavedItemReference>[
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
  }
}