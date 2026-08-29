import '../../../core/di/app_dependencies.dart';
import '../../../data/repositories/article_repository.dart';
import '../../encyclopedia/domain/repositories/encyclopedia_repository.dart';
import '../../tools/domain/tool_key.dart';
import '../domain/search_aggregator.dart';
import '../domain/search_result.dart';

/// W2.2 — production search composition layer.
///
/// This is the single application-edge point that wires the pure
/// [SearchAggregator] to the authoritative domain lookup logic. It is allowed
/// to import data/infrastructure (`ArticleRepository`, `AppDependencies`) and
/// the domain-facing source contracts; the Search *domain* file
/// (`search_aggregator.dart`) stays infrastructure-free.
///
/// Conceptually:
///
///   production composition
///   → SearchAggregator(
///       knowledgeSource: knowledgeSearchSource(...),
///       toolsSource: toolsSearchSource(...),
///     )

/// Production wiring: Knowledge reads the authoritative Encyclopedia
/// repository; Tools read the authoritative registry.
SearchAggregator productionSearchAggregator() => SearchAggregator(
  knowledgeSource: knowledgeSearchSource(AppDependencies.encyclopediaRepo),
  toolsSource: toolsSearchSource(),
);

/// Production Knowledge source adapter.
///
/// Consumes the authoritative [EncyclopediaRepository.searchTopics] — the
/// existing pure-domain lookup. No Knowledge search algorithm is reimplemented
/// here (no title/tag/keyTopics/normalization/Arabic behavior duplication).
/// Maps each matching topic to a typed [SearchResult]:
///
///   id      = topic.id (stable topic identity)
///   type    = SearchResultType.knowledge
///   title   = titleAr
///   subtitle = summary
SearchSource knowledgeSearchSource(EncyclopediaRepository repository) {
  return (String query) async {
    final topics = await repository.searchTopics(query);
    return topics
        .map(
          (topic) => SearchResult(
            id: topic.id,
            type: SearchResultType.knowledge,
            title: topic.titleAr,
            subtitle: topic.summary,
          ),
        )
        .toList();
  };
}

/// Production Tools source adapter.
///
/// Consumes the authoritative registry ([ArticleRepository.tools]) — no second
/// hard-coded tool list is created here. Only registry entries whose `id`
/// resolves to a canonical [ToolKey] are surfaced; each is projected as:
///
///   id      = ToolKey.stableId (canonical tool identity — never a raw route)
///   type    = SearchResultType.tool
///   title   = tool.name
///   subtitle = tool.description
///
/// Matching is a minimal substring check over name/description (the smallest
/// lookup projection; the registry previously had no search API). Empty query
/// returns all supported tools.
SearchSource toolsSearchSource() {
  return (String query) async {
    final q = query.toLowerCase();
    final results = <SearchResult>[];
    for (final tool in ArticleRepository.tools) {
      final key = _toolKeyFromStableId(tool.id);
      if (key == null) continue;
      final matches =
          q.isEmpty ||
          tool.name.toLowerCase().contains(q) ||
          tool.description.toLowerCase().contains(q);
      if (matches) {
        results.add(
          SearchResult(
            id: key.stableId,
            type: SearchResultType.tool,
            title: tool.name,
            subtitle: tool.description,
          ),
        );
      }
    }
    return results;
  };
}

ToolKey? _toolKeyFromStableId(String stableId) {
  for (final key in ToolKey.values) {
    if (key.stableId == stableId) return key;
  }
  return null;
}
