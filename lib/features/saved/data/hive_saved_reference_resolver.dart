import '../../../data/local/hive_helper.dart';
import '../domain/saved_reference_resolver.dart';
import 'hive_saved_reference_store.dart';

/// W3.1/W5.6 — Production composition: a [SavedReferenceResolver] bound to the
/// canonical Hive reads.
///
/// Reads route through `HiveHelper` (legacy lists) and the structured
/// [HiveSavedReferenceStore] (W5.6). READ-ONLY — nothing here writes.
SavedReferenceResolver hiveSavedReferenceResolver() {
  return SavedReferenceResolver(
    encyclopediaTopicIds: () async => HiveHelper.getEncyclopediaFavorites(),
    legacyArticleIds: () async => HiveHelper.getFavorites(),
    structuredReferences: const HiveSavedReferenceStore().loadAll,
  );
}