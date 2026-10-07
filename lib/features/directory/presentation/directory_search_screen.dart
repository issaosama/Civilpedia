import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/navigation/shell_content_insets.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_app_bar.dart';
import '../../../core/widgets/remote_data_notice.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../../routes/app_routes.dart';
import '../application/directory_refresh_controller.dart';
import '../domain/canonical_directory_entity.dart';
import '../domain/canonical_directory_query_engine.dart';
import '../domain/cloud_directory_repository.dart';
import 'canonical_entity_type_presentation.dart';
import 'directory_provider_card.dart';

/// Organic canonical Directory discovery. Localized labels and responsive
/// layout do not change query identities, debounce, ordering or refresh policy.
class DirectorySearchScreen extends StatefulWidget {
  final String? initialEntityType;
  final CloudDirectoryRepository? repository;
  final ConnectivityProvider? connectivityProvider;
  final double bottomContentPadding;

  const DirectorySearchScreen({
    super.key,
    this.initialEntityType,
    this.repository,
    this.connectivityProvider,
    this.bottomContentPadding = AppSpacing.huge,
  });

  @override
  State<DirectorySearchScreen> createState() => _DirectorySearchScreenState();
}

class _DirectorySearchScreenState extends State<DirectorySearchScreen> {
  static const Duration _debounceDuration = Duration(milliseconds: 280);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  DirectoryRefreshController? _controller;
  String _text = '';
  String? _entityType;
  String? _regionCode;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _entityType = widget.initialEntityType;
    _initController();
  }

  void _initController() {
    final repository = widget.repository ?? AppDependencies.directoryRepo;
    final controller = DirectoryRefreshController(
      repository: repository,
      connectivity: widget.connectivityProvider,
    );
    _controller = controller;
    controller.initialize();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _controller?.refresh(userInitiated: true);
  }

  void _onTextChanged(String raw) {
    _debounce?.cancel();
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      setState(() => _text = '');
      return;
    }
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      setState(() => _text = trimmed);
    });
  }

  void _onEntityTypeChanged(String? value) {
    setState(() => _entityType = value);
  }

  void _onRegionChanged(String? value) {
    setState(() => _regionCode = value);
  }

  void _onCategoryChanged(String? value) {
    setState(() => _categoryId = value);
  }

  DirectoryRefreshController get _controllerState => _controller!;

  List<CanonicalDirectoryEntity> get _results {
    final entities = _controllerState.entities;
    if (entities.isEmpty) return const [];
    return CanonicalDirectoryQueryEngine.apply(
      entities,
      CanonicalDirectoryQuery(
        text: _text,
        entityType: _entityType,
        regionCode: _regionCode,
        categoryId: _categoryId,
      ),
    );
  }

  List<String> get _availableRegionCodes {
    final codes = <String>{};
    for (final entity in _controllerState.entities) {
      for (final loc in entity.locations) {
        if (loc.regionCode.isNotEmpty) codes.add(loc.regionCode);
      }
    }
    return codes.toList()..sort();
  }

  List<CanonicalDirectoryCategory> get _availableCategories {
    final cats = <String, CanonicalDirectoryCategory>{};
    for (final entity in _controllerState.entities) {
      for (final cat in entity.categories) {
        cats[cat.id] = cat;
      }
    }
    // Keep the accepted generic-name sort; bilingual display adds no ranking.
    return cats.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  String _categoryLabel(CanonicalDirectoryCategory category, bool isArabic) {
    final candidates = isArabic
        ? [category.nameAr, category.nameEn, category.name, category.code]
        : [category.nameEn, category.nameAr, category.name, category.code];
    for (final value in candidates) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return isArabic ? Ar.directoryNotSpecified : En.directoryNotSpecified;
  }

  String _regionLabel(String code, bool isArabic) {
    // First useful label in existing entity/location order, retaining the
    // original code as the dropdown value and query identity.
    for (final entity in _controllerState.entities) {
      for (final location in entity.locations) {
        if (location.regionCode != code) continue;
        final names = isArabic
            ? [
                location.regionNameAr,
                location.regionNameEn,
                location.regionName,
              ]
            : [
                location.regionNameEn,
                location.regionNameAr,
                location.regionName,
              ];
        for (final name in names) {
          if (name != null && name.trim().isNotEmpty) return name.trim();
        }
      }
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final controller = _controller;

    return Scaffold(
      appBar: CivilAppBar(
        title: Text(
          isArabic ? Ar.directorySearchTitle : En.directorySearchTitle,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final gutter = width < 600
              ? AppSpacing.lg
              : width < 840
              ? AppSpacing.xxl
              : 2 * AppSpacing.lg;
          return ListenableBuilder(
            listenable: controller ?? const _EmptyListenable(),
            builder: (context, _) =>
                _buildContent(context, isArabic, width, gutter),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isArabic,
    double width,
    double gutter,
  ) {
    final controller = _controller;
    final isShellHosted = ShellContentInsets.maybeOf(context) != null;
    final effectiveBottomPadding = isShellHosted
        ? shellSafeBottomPadding(context)
        : widget.bottomContentPadding + MediaQuery.paddingOf(context).bottom;
    final results = controller == null
        ? const <CanonicalDirectoryEntity>[]
        : _results;
    final loading =
        controller == null || (controller.isLoading && !controller.hasSnapshot);
    final stale = controller?.loadState == DirectoryLoadState.stale;
    final error = !loading && controller.loadState == DirectoryLoadState.error;
    // Only a successful empty read or an explicitly stale empty snapshot is
    // empty content. An error with zero entities remains a real failure.
    final empty =
        !loading &&
        (controller.loadState == DirectoryLoadState.empty ||
            (stale && controller.entities.isEmpty));
    final noMatch = !loading && !error && !empty && results.isEmpty;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              gutter,
              AppSpacing.lg,
              gutter,
              AppSpacing.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SearchBarWidget(
                        controller: _searchController,
                        onChanged: _onTextChanged,
                        hintText: isArabic
                            ? Ar.directorySearchHint
                            : En.directorySearchHint,
                        lightSurface: true,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFilters(context, isArabic, width),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (stale && !loading)
            SliverPadding(
              padding: EdgeInsetsDirectional.fromSTEB(
                gutter,
                0,
                gutter,
                AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: _readable(
                  _buildStaleNotice(context, isArabic, controller),
                ),
              ),
            ),
          if (loading || error || empty || noMatch)
            SliverPadding(
              padding: EdgeInsetsDirectional.only(
                start: gutter,
                end: gutter,
                bottom: effectiveBottomPadding,
              ),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: _readable(
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : error
                      ? _buildError(context, isArabic, controller)
                      : EmptyStateWidget(
                          key: ValueKey(
                            empty
                                ? 'cui1-directory-empty'
                                : 'cui1-directory-no-match',
                          ),
                          icon: empty
                              ? Icons.business_center_outlined
                              : Icons.search_off,
                          message: empty
                              ? (isArabic
                                    ? Ar.cui1EmptyDirectory
                                    : En.cui1EmptyDirectory)
                              : (isArabic
                                    ? Ar.cui1NoResults
                                    : En.cui1NoResults),
                        ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsetsDirectional.only(
                start: gutter,
                end: gutter,
                bottom: effectiveBottomPadding,
              ),
              sliver: SliverList(
                key: const ValueKey('cui1-search-results'),
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) return const SizedBox(height: AppSpacing.md);
                  final entity = results[index ~/ 2];
                  return _readable(
                    DirectoryProviderCard(
                      entity: entity,
                      onTap: () => _openDetail(context, entity),
                    ),
                  );
                }, childCount: results.length * 2 - 1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _readable(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: child,
    ),
  );

  Widget _buildFilters(BuildContext context, bool isArabic, double width) {
    final categories = _availableCategories;
    final filters = <Widget>[
      _FilterDropdown<String>(
        label: isArabic ? Ar.cui1EntityType : En.cui1EntityType,
        value: _entityType,
        allLabel: isArabic ? Ar.directoryFilterAll : En.directoryFilterAll,
        options: CanonicalEntityTypePresentation.orderedTypes,
        optionLabel: (type) =>
            CanonicalEntityTypePresentation.labelFor(type, isArabic: isArabic),
        onChanged: _onEntityTypeChanged,
      ),
      _FilterDropdown<String>(
        label: isArabic
            ? Ar.directoryFilterLocation
            : En.directoryFilterLocation,
        value: _regionCode,
        allLabel: isArabic ? Ar.directoryFilterAll : En.directoryFilterAll,
        options: _availableRegionCodes,
        optionLabel: (code) => _regionLabel(code, isArabic),
        onChanged: _onRegionChanged,
      ),
      if (categories.isNotEmpty)
        _FilterDropdown<String>(
          label: isArabic
              ? Ar.directoryFilterCategory
              : En.directoryFilterCategory,
          value: _categoryId,
          allLabel: isArabic ? Ar.directoryFilterAll : En.directoryFilterAll,
          options: categories.map((category) => category.id).toList(),
          optionLabel: (id) => _categoryLabel(
            categories.firstWhere(
              (category) => category.id == id,
              orElse: () => categories.first,
            ),
            isArabic,
          ),
          onChanged: _onCategoryChanged,
        ),
    ];
    final columns = width < 600
        ? 1
        : width < 840
        ? 2
        : 3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final filter in filters)
              SizedBox(width: fieldWidth, child: filter),
          ],
        );
      },
    );
  }

  Widget _buildStaleNotice(
    BuildContext context,
    bool isArabic,
    DirectoryRefreshController controller,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.cause != null) ...[
          RemoteDataNotice(
            cause: controller.cause!,
            mode: RemoteDataNoticeMode.compact,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _retryButton(isArabic, controller),
          ),
        ] else if (controller.isLoading)
          Text(
            isArabic ? Ar.cui1Updating : En.cui1Updating,
            key: const ValueKey('cui1-directory-updating'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isArabic ? Ar.cui1Snapshot : En.cui1Snapshot,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildError(
    BuildContext context,
    bool isArabic,
    DirectoryRefreshController controller,
  ) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      RemoteDataNotice(
        cause: controller.cause ?? RemoteDataCause.unexpected,
        mode: RemoteDataNoticeMode.noData,
      ),
      const SizedBox(height: AppSpacing.lg),
      _retryButton(isArabic, controller),
    ],
  );

  Widget _retryButton(bool isArabic, DirectoryRefreshController controller) =>
      OutlinedButton.icon(
        onPressed: controller.isLoading ? null : controller.refresh,
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: const Icon(Icons.refresh_rounded),
        label: Text(isArabic ? Ar.retry : En.retry),
      );

  /// The canonical ID is authority; the extra remains only a first-frame hint.
  void _openDetail(BuildContext context, CanonicalDirectoryEntity entity) {
    context.push(AppRoutes.directoryEntityDetailFor(entity.id), extra: entity);
  }
}

class _EmptyListenable implements Listenable {
  const _EmptyListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String allLabel;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.allLabel,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              label,
              key: ValueKey('cui1-filter-label-$label'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Semantics(
          label: label,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: DropdownButtonFormField<T?>(
              value: value,
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              // Unselected long popup labels must not enlarge the closed field.
              // The current selection still grows naturally when its text wraps.
              selectedItemBuilder: (context) => [
                for (var index = 0; index <= options.length; index++)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    heightFactor: 1,
                    child: Text(
                      value == null ? allLabel : optionLabel(value as T),
                    ),
                  ),
              ],
              dropdownColor: colors.surfaceContainer,
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              items: [
                DropdownMenuItem<T?>(
                  value: null,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(allLabel),
                  ),
                ),
                for (final option in options)
                  DropdownMenuItem<T?>(
                    value: option,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(optionLabel(option)),
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
