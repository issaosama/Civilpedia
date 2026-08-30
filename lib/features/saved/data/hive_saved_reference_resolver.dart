import '../../../data/local/hive_helper.dart';
import '../domain/saved_reference_resolver.dart';

/// W3.1 — Production composition: a [SavedReferenceResolver] bound to the
/// canonical Hive reads.
///
/// Both reads route through `HiveHelper`, the single canonical owner of the
/// `civilpedia` box and its keys (F0.2 `AppStorageKeys`). READ-ONLY —
/// nothing here writes.
SavedReferenceResolver hiveSavedReferenceResolver() {
  return SavedReferenceResolver(
    encyclopediaTopicIds: () async => HiveHelper.getEncyclopediaFavorites(),
    legacyArticleIds: () async => HiveHelper.getFavorites(),
  );
}