import 'search_result.dart';

/// W2.2 — Global Search V1 aggregation layer (pure Search-domain contract).
///
/// Search is an AGGREGATOR / PROJECTION surface, NOT a data owner. This pure
/// domain file introduces only the smallest aggregation contract:
///
/// - [SearchSource] — a typed, dependency-injected search source.
/// - [SearchAggregator] — combines Knowledge + Tools sources with independent
///   per-source failure isolation, deterministic ordering, and no ranking.
///
/// Nothing here touches data/presentation/navigation. Concrete production
/// source adapters and wiring live in
/// `lib/features/search/data/search_aggregator_production.dart`, which composes
/// this aggregator with the authoritative domain lookup logic.
///
/// Navigation is NOT performed here. Results carry stable identity only; a
/// later consumer routes them via the W2.1 `SearchRouteResolver`. This
/// aggregator never touches `SearchRouteResolver` and never stores raw route
/// strings.

/// A single search source projection: given a query, produces typed search
/// results. Kept a plain function type so the aggregator can be substituted
/// with fakes/stubs in unit tests without interfaces/factories/DI machinery.
typedef SearchSource = Future<List<SearchResult>> Function(String query);

/// Aggregates Knowledge + Tools search results into one unified, typed list.
///
/// Per-domain failure isolation is NON-NEGOTIABLE:
///
/// - Knowledge success + Tools success → combined results.
/// - Knowledge failure  + Tools success → Tools results only.
/// - Knowledge success  + Tools failure → Knowledge results only.
/// - Both failures                       → controlled empty result, no crash.
///
/// Each domain is queried inside its OWN try/catch, so a failure in one domain
/// never prevents the healthy domain from being queried or contributing. The
/// try/catch isolates the domain LOOKUP boundary only; it is not a broad
/// catch-all masking unrelated programming defects elsewhere.
///
/// Ordering: deterministic domain-order concatenation (Knowledge first, then
/// Tools). No ranking / relevance / cross-domain ordering is invented.
class SearchAggregator {
  final SearchSource _knowledgeSource;
  final SearchSource _toolsSource;

  const SearchAggregator({
    required SearchSource knowledgeSource,
    required SearchSource toolsSource,
  }) : _knowledgeSource = knowledgeSource,
       _toolsSource = toolsSource;

  /// Runs a search across both domains and returns the unified result list.
  ///
  /// The query is trimmed once and passed unchanged to both sources (each
  /// source treats an empty/whitespace-passed query as "return all", matching
  /// the app's established empty-search convention).
  Future<List<SearchResult>> search(String query) async {
    final trimmed = query.trim();
    final knowledge = await _runSource(_knowledgeSource, trimmed);
    final tools = await _runSource(_toolsSource, trimmed);
    return <SearchResult>[...knowledge, ...tools];
  }

  Future<List<SearchResult>> _runSource(
    SearchSource source,
    String query,
  ) async {
    try {
      return await source(query);
    } catch (_) {
      return const <SearchResult>[];
    }
  }
}
