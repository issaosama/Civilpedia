import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../data/search_aggregator_production.dart';
import '../../domain/search_aggregator.dart';
import '../../domain/search_result.dart';
import '../../navigation/search_route_resolver.dart';

/// W2.3 — Global Search V1 aggregator shell (W2.4 live search).
///
/// Reuses the shared [SearchBarWidget], consumes the W2.2 [SearchAggregator],
/// and routes results via the W2.1 [SearchRouteResolver] (the single
/// compatibility boundary). It renders a unified Knowledge + Tools result list
/// in aggregator order with no filters/tabs/ranking/history. This is a root
/// full-screen route above the app shell; it owns no detail screens.
///
/// The field is the SOLE query entry point: Home pushes a plain `/search` and
/// the user types only here. Typing searches automatically through a short
/// debounce; a request-generation token discards stale async completions so a
/// newer query's results are never overwritten by an older in-flight search.
class GlobalSearchScreen extends StatefulWidget {
  /// Search aggregator to query. Defaults to the production composition; tests
  /// inject a fake so the screen stays decoupled from data/repositories.
  final SearchAggregator? aggregator;

  const GlobalSearchScreen({super.key, this.aggregator});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  /// Debounce window: typing pauses briefly before the aggregator runs, so each
  /// pause triggers one search rather than one per keystroke.
  static const Duration _debounceDuration = Duration(milliseconds: 280);

  late final SearchAggregator _aggregator;
  final SearchRouteResolver _resolver = const SearchRouteResolver();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  int _requestId = 0;

  String _query = '';
  bool _loading = false;
  List<SearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _aggregator = widget.aggregator ?? productionSearchAggregator();
  }

  /// Live-search handler bound to [SearchBarWidget.onChanged].
  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    // Invalidate any in-flight search for the previous text immediately, so a
    // late older completion can never overwrite the current query's results.
    _requestId++;
    final query = raw.trim();
    if (query.isEmpty) {
      // Empty/whitespace: cancel pending debounce, no aggregator run, clear
      // any previous results and restore the initial-search prompt.
      setState(() {
        _query = '';
        _loading = false;
        _results = const [];
      });
      return;
    }
    _debounce = Timer(_debounceDuration, () => _runSearch(query));
  }

  /// Keyboard search action. Harmless fallback only: live search makes it
  /// unnecessary, so it just cancels a pending debounce and searches now.
  void _onSubmitted(String raw) {
    _debounce?.cancel();
    _requestId++;
    final query = raw.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _loading = false;
        _results = const [];
      });
      return;
    }
    _runSearch(query);
  }

  Future<void> _runSearch(String query) async {
    final requestId = _requestId;
    setState(() {
      _query = query;
      _loading = true;
    });
    final results = await _aggregator.search(query);
    if (!mounted || requestId != _requestId) return;
    setState(() {
      _loading = false;
      _results = results;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _openResult(SearchResult result) {
    final route = _resolver.routeFor(type: result.type, id: result.id);
    if (route == null) return;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Scaffold(
      appBar: CivilAppBar(
        title: Text(isArabic ? Ar.globalSearchTitle : En.globalSearchTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = constraints.maxWidth < 600
              ? AppSpacing.lg
              : constraints.maxWidth < 840
              ? AppSpacing.xl + AppSpacing.xs
              : AppSpacing.xl + AppSpacing.md;
          final availableWidth = constraints.maxWidth - (gutter * 2);
          final contentWidth = availableWidth > 760.0 ? 760.0 : availableWidth;

          return Align(
            alignment: AlignmentDirectional.topCenter,
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.xs,
                    ),
                    child: SearchBarWidget(
                      controller: _searchController,
                      onChanged: _onQueryChanged,
                      onSubmitted: _onSubmitted,
                      hintText: isArabic
                          ? Ar.globalSearchHint
                          : En.globalSearchHint,
                      lightSurface: !isDark,
                      autofocus: true,
                    ),
                  ),
                  Expanded(
                    child: _buildResults(
                      context,
                      isDark,
                      mutedText,
                      isArabic: isArabic,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    bool isDark,
    Color mutedText, {
    required bool isArabic,
  }) {
    if (_loading) {
      return _SearchStateView.loading(
        label: isArabic ? Ar.loading : En.loading,
      );
    }

    if (_query.isEmpty) {
      return _SearchStateView.message(
        icon: Icons.search,
        text: isArabic ? Ar.initialSearchPrompt : En.initialSearchPrompt,
        color: mutedText,
      );
    }

    if (_results.isEmpty) {
      return _SearchStateView.message(
        icon: Icons.search_off,
        text: isArabic ? Ar.noSearchResults : En.noSearchResults,
        color: mutedText,
      );
    }

    return ListView.separated(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      itemCount: _results.length,
      separatorBuilder: (_, __) => AppSpacing.gapMd,
      itemBuilder: (context, index) =>
          _resultTile(context, _results[index], isDark: isDark),
    );
  }

  Widget _resultTile(
    BuildContext context,
    SearchResult result, {
    required bool isDark,
  }) {
    final isTool = result.type == SearchResultType.tool;
    final resolved = _resolver.routeFor(type: result.type, id: result.id);
    final isActionable = resolved != null;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final accent = isTool
        ? (isDark ? AppColors.darkBrandAmber : AppColors.brandAmberPressed)
        : (isDark ? AppColors.darkBrandBlue : AppColors.brandBlue);
    final iconSurface = isTool
        ? (isDark ? AppColors.darkWarningSoft : AppColors.brandAmberSoft)
        : (isDark ? AppColors.darkInfoSoft : AppColors.brandBlueSoft);
    final forwardIcon = Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right;

    return Semantics(
      button: isActionable,
      enabled: isActionable,
      label: result.title,
      child: CivilSurfaceCard(
        hasBorder: true,
        onTap: isActionable ? () => _openResult(result) : null,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconSurface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
              ),
              child: Icon(
                isTool ? Icons.calculate_outlined : Icons.menu_book_outlined,
                color: accent,
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
                  if (result.subtitle != null &&
                      result.subtitle!.isNotEmpty) ...[
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
            if (isActionable) Icon(forwardIcon, color: secondary),
          ],
        ),
      ),
    );
  }
}

class _SearchStateView extends StatelessWidget {
  const _SearchStateView._({
    required this.label,
    this.icon,
    this.color,
    this.loading = false,
  });

  factory _SearchStateView.loading({required String label}) =>
      _SearchStateView._(label: label, loading: true);

  factory _SearchStateView.message({
    required IconData icon,
    required String text,
    required Color color,
  }) => _SearchStateView._(label: text, icon: icon, color: color);

  final String label;
  final IconData? icon;
  final Color? color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Semantics(
      label: label,
      liveRegion: loading,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl + AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox.square(
                  dimension: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: theme.colorScheme.secondary,
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusIcon,
                    ),
                  ),
                  child: Icon(icon, size: 28, color: effectiveColor),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
