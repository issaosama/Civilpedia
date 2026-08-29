import '../../../routes/app_routes.dart';
import '../../tools/domain/tool_key.dart';
import '../domain/search_result.dart';

/// W2.1 — Flutter-side compatibility route resolver for search results.
///
/// This is the SINGLE compatibility boundary that keeps legacy raw route
/// strings out of the Search contract. It:
///
/// 1. Normalizes supported legacy/raw Tool route identities (both the
///    no-slash registry spelling `calculator/concrete` and the content
///    spelling `/calculator/concrete`) into the canonical [ToolKey].
/// 2. Resolves a typed [SearchResult] destination to an existing canonical
///    `AppRoutes` path, using:
///      - [AppRoutes] (F0.1) as canonical route owner,
///      - [ToolKey] (F0.5) as canonical tool identity.
/// 3. Preserves current supported tool destinations.
/// 4. Returns `null` (safe, explicit unresolved) for unknown/unsupported legacy
///    routes — it never guesses, never defaults to an unrelated tool, and never
///    throws for ordinary unknown input.
///
/// Raw routes are accepted ONLY at this compatibility edge and are normalized
/// to typed identity before any destination is resolved. Consumers of the
/// future Global Search pipeline must not do `context.go(result.rawRoute)`.
///
/// This resolver does not create `/search`, does not add routes, and does not
/// migrate Content Studio / generated content. It is infrastructure only.
class SearchRouteResolver {
  const SearchRouteResolver();

  /// Resolves a typed search result to a canonical `AppRoutes` destination.
  ///
  /// - Knowledge: returns the canonical topic detail route for [id]
  ///   (`AppRoutes.topicDetailFor`).
  /// - Tool: [id] is a [ToolKey.stableId]; returns the canonical tool route, or
  ///   `null` if [id] is not a known tool.
  String? routeFor({required SearchResultType type, required String id}) {
    switch (type) {
      case SearchResultType.knowledge:
        return AppRoutes.topicDetailFor(id);
      case SearchResultType.tool:
        final key = toolKeyFromStableId(id);
        return key == null ? null : toolRoute(key);
    }
  }

  /// Resolves a typed knowledge topic id to its canonical route.
  String? knowledgeRoute(String topicId) =>
      routeFor(type: SearchResultType.knowledge, id: topicId);

  /// Resolves a typed tool key to its canonical route.
  String? toolRoute(ToolKey key) {
    switch (key) {
      case ToolKey.concrete:
        return AppRoutes.calculatorConcrete;
      case ToolKey.steel:
        return AppRoutes.calculatorSteel;
      case ToolKey.brick:
        return AppRoutes.calculatorBrick;
      case ToolKey.checklist:
        return AppRoutes.calculatorChecklist;
      case ToolKey.tile:
        return AppRoutes.calculatorTile;
    }
  }

  /// Maps a [ToolKey.stableId] to its [ToolKey], or `null` if unknown.
  ToolKey? toolKeyFromStableId(String stableId) {
    for (final key in ToolKey.values) {
      if (key.stableId == stableId) return key;
    }
    return null;
  }

  /// Compatibility edge: maps a legacy/raw tool route identity to its
  /// canonical [ToolKey].
  ///
  /// Accepts both `calculator/<id>` (registry/`ToolModel.route`, no leading
  /// slash) and `/calculator/<id>` (content `relatedToolRoutes`, leading
  /// slash). Returns `null` for unknown or non-tool routes.
  ToolKey? toolKeyFromLegacyRoute(String rawRoute) {
    final normalized = rawRoute.startsWith('/')
        ? rawRoute.substring(1)
        : rawRoute;
    for (final key in ToolKey.values) {
      if (normalized == 'calculator/${key.stableId}') return key;
    }
    return null;
  }

  /// Compatibility edge: maps a legacy/raw tool route directly to its canonical
  /// `AppRoutes` destination, or `null` if unsupported.
  String? routeFromLegacyToolRoute(String rawRoute) {
    final key = toolKeyFromLegacyRoute(rawRoute);
    return key == null ? null : toolRoute(key);
  }
}
