import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../localization/ar.dart';
import '../../data/search_aggregator_production.dart';
import '../../domain/search_aggregator.dart';
import '../../domain/search_result.dart';
import '../../navigation/search_route_resolver.dart';

/// W2.3 — Global Search V1 aggregator shell.
///
/// Reuses the shared [SearchBarWidget], consumes the W2.2 [SearchAggregator],
/// and routes results via the W2.1 [SearchRouteResolver] (the single
/// compatibility boundary). It renders a unified Knowledge + Tools result list
/// in aggregator order with no filters/tabs/ranking/history. This is a root
/// full-screen route above the app shell; it owns no detail screens.
class GlobalSearchScreen extends StatefulWidget {
  /// Search aggregator to query. Defaults to the production composition; tests
  /// inject a fake so the screen stays decoupled from data/repositories.
  final SearchAggregator? aggregator;

  const GlobalSearchScreen({super.key, this.aggregator});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  late final SearchAggregator _aggregator;
  final SearchRouteResolver _resolver = const SearchRouteResolver();

  String _query = '';
  bool _loading = false;
  List<SearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _aggregator = widget.aggregator ?? productionSearchAggregator();
  }

  Future<void> _search(String raw) async {
    final query = raw.trim();
    setState(() {
      _query = query;
      _loading = true;
    });
    final results = await _aggregator.search(query);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = results;
    });
  }

  void _openResult(SearchResult result) {
    final route = _resolver.routeFor(type: result.type, id: result.id);
    if (route == null) return;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Scaffold(
      appBar: CivilAppBar(title: const Text(Ar.globalSearchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SearchBarWidget(
              onSubmitted: _search,
              hintText: Ar.globalSearchHint,
              lightSurface: !isDark,
            ),
          ),
          Expanded(child: _buildResults(context, isDark, mutedText)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, bool isDark, Color mutedText) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_query.isEmpty) {
      return _message(
        icon: Icons.search,
        text: Ar.initialSearchPrompt,
        color: mutedText,
      );
    }

    if (_results.isEmpty) {
      return _message(
        icon: Icons.search_off,
        text: Ar.noSearchResults,
        color: mutedText,
      );
    }

    return ListView.separated(
      padding: AppSpacing.padLg,
      itemCount: _results.length,
      separatorBuilder: (_, __) => AppSpacing.gapMd,
      itemBuilder: (context, index) =>
          _resultTile(context, _results[index], isDark: isDark),
    );
  }

  Widget _message({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            AppSpacing.gapMd,
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultTile(
    BuildContext context,
    SearchResult result, {
    required bool isDark,
  }) {
    final isTool = result.type == SearchResultType.tool;
    final resolved = _resolver.routeFor(type: result.type, id: result.id);
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return CivilSurfaceCard(
      onTap: resolved == null ? null : () => _openResult(result),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
            ),
            child: Icon(
              isTool ? Icons.calculate_outlined : Icons.menu_book_outlined,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (result.subtitle != null && result.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    result.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: secondary),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: secondary),
        ],
      ),
    );
  }
}
