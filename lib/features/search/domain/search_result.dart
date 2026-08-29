/// W2.1 — Global Search V1 typed result projection contract.
///
/// Search is a PROJECTION / AGGREGATION domain. It must NOT own domain
/// entities: it never holds `EngineeringTopic`, `ToolModel`, `ArticleModel`,
/// `Project`, or a Directory entity. It also must NOT become a second route
/// registry — no raw route strings live here as identity.
///
/// A [SearchResult] is a lightweight projection keyed by a stable identity and
/// a typed domain ([SearchResultType]). Routing a result to a canonical app
/// destination is the responsibility of the route resolver
/// (`lib/features/search/navigation/search_route_resolver.dart`), never of the
/// consumer calling `context.go(result.rawRoute)`.
library;

/// The typed domain of a search result projection, for the W2 Global Search V1
/// source domains. V1 searches only Knowledge + Tools; Projects/Directory types
/// are intentionally absent until their domains require search.
enum SearchResultType {
  /// A Knowledge / Encyclopedia topic result.
  knowledge,

  /// A Tools result (calculator / checklist).
  tool,
}

/// Lightweight, durable projection of a single search result.
///
/// Fields:
/// - [id] — stable source-domain identity. For a knowledge result this is the
///   Encyclopedia topic `id`; for a tool result this is the `ToolKey.stableId`.
///   It is never a raw route path.
/// - [type] — the typed domain ([SearchResultType]).
/// - [title] — display title for the result.
/// - [subtitle] — optional short supporting text (used by later result UI only
///   if W2.3 needs it).
class SearchResult {
  final String id;
  final SearchResultType type;
  final String title;
  final String? subtitle;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
  });

  @override
  bool operator ==(Object other) =>
      other is SearchResult &&
      other.id == id &&
      other.type == type &&
      other.title == title &&
      other.subtitle == subtitle;

  @override
  int get hashCode => Object.hash(id, type, title, subtitle);

  @override
  String toString() =>
      'SearchResult(id: $id, type: ${type.name}, title: $title)';
}
