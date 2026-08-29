import '../../../data/repositories/article_repository.dart';

/// Home read-facing boundary (W1.1 — Home data-source normalization, read-compat).
///
/// Home is an aggregator/composer, NOT a source of truth. This boundary is the
/// single Home-facing surface through which Home resolves the reads that still
/// legitimately come from the legacy [ArticleRepository] (Latest Articles and
/// the Tools registry).
///
/// Read-compatible only: this boundary wraps the existing legacy reads without
/// migrating ownership, deleting [ArticleRepository], changing article content
/// or ordering, or introducing any new data source. W1.1 performs no data
/// migration and no UI change. Deep ArticleRepository consolidation is
/// deferred per M8 (CONSOLIDATE / DEPRECATE LATER).
class HomeContentSource {
  const HomeContentSource();

  /// Latest legacy articles surfaced on Home's "Latest Articles" section.
  ///
  /// Wraps [ArticleRepository.getLatestArticles] verbatim; ordering and content
  /// are preserved exactly.
  List<dynamic> get latestArticles => ArticleRepository().getLatestArticles();

  /// The tool registry surfaced by Home's Quick Tools section.
  ///
  /// Wraps [ArticleRepository.tools] verbatim; the presentation still owns
  /// navigation behavior (unchanged).
  List<dynamic> get tools => ArticleRepository.tools;
}
