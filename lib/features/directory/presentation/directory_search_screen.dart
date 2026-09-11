import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/navigation/shell_content_insets.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_app_bar.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../../routes/app_routes.dart';
import '../domain/canonical_directory_entity.dart';
import '../domain/canonical_directory_query_engine.dart';
import '../domain/cloud_directory_repository.dart';
import 'canonical_entity_type_presentation.dart';
import 'directory_provider_card.dart';

/// V1-R05 — Directory-local search + location/category filter surface.
///
/// Uses canonical cloud-backed data from [CloudDirectoryRepository].
/// Loads the bounded canonical dataset via cache-first + cloud-refresh, then
/// applies search/filter purely in memory via [CanonicalDirectoryQueryEngine].
///
/// State exposure:
/// * loading: cloud refresh in progress, no cached data yet;
/// * fresh: successfully refreshed canonical data;
/// * stale: rendered from cache, cloud refresh failed/unavailable;
/// * empty: authoritative empty cloud directory;
/// * error: neither cache nor cloud produced data.
class DirectorySearchScreen extends StatefulWidget {
  /// Pre-selected canonical entity type to start with. Null = browse mode.
  final String? initialEntityType;

  /// Repository to load canonical entities from. Production default is
  /// [AppDependencies.directoryRepo].
  final CloudDirectoryRepository? repository;

  /// Bottom scroll clearance for the result list.
  final double bottomContentPadding;

  const DirectorySearchScreen({
    super.key,
    this.initialEntityType,
    this.repository,
    this.bottomContentPadding = AppSpacing.huge,
  });

  @override
  State<DirectorySearchScreen> createState() => _DirectorySearchScreenState();
}

class _DirectorySearchScreenState extends State<DirectorySearchScreen> {
  static const Duration _debounceDuration = Duration(milliseconds: 280);

  late final CloudDirectoryRepository _repository;
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  List<CanonicalDirectoryEntity> _entities = const [];
  DirectoryLoadState _loadState = DirectoryLoadState.error;
  bool _loading = true;
  DateTime? _refreshedAt;

  String _text = '';
  String? _entityType;
  String? _regionCode;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppDependencies.directoryRepo;
    _entityType = widget.initialEntityType;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    final result = await _repository.load();
    if (!mounted) return;
    setState(() {
      _entities = result.entities;
      _loadState = result.state;
      _refreshedAt = result.refreshedAt;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    final result = await _repository.refresh();
    if (!mounted) return;
    if (result.succeeded) {
      setState(() {
        _entities = result.entities;
        _loadState = result.entities.isEmpty
            ? DirectoryLoadState.empty
            : DirectoryLoadState.fresh;
        _refreshedAt = result.refreshedAt;
      });
    }
    // On failure, keep existing state (stale cache).
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

  List<CanonicalDirectoryEntity> get _results {
    if (_entities.isEmpty) return const [];
    return CanonicalDirectoryQueryEngine.apply(
      _entities,
      CanonicalDirectoryQuery(
        text: _text,
        entityType: _entityType,
        regionCode: _regionCode,
        categoryId: _categoryId,
      ),
    );
  }

  /// Collect all distinct region codes from the loaded entities for the
  /// region filter dropdown.
  List<String> get _availableRegionCodes {
    final codes = <String>{};
    for (final entity in _entities) {
      for (final loc in entity.locations) {
        if (loc.regionCode.isNotEmpty) codes.add(loc.regionCode);
      }
    }
    return codes.toList()..sort();
  }

  /// Collect all distinct category ids from the loaded entities.
  List<CanonicalDirectoryCategory> get _availableCategories {
    final cats = <String, CanonicalDirectoryCategory>{};
    for (final entity in _entities) {
      for (final cat in entity.categories) {
        cats[cat.id] = cat;
      }
    }
    return cats.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final title = isArabic ? Ar.directorySearchTitle : En.directorySearchTitle;

    return Scaffold(
      appBar: CivilAppBar(title: Text(title)),
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
              controller: _searchController,
              onChanged: _onTextChanged,
              hintText: isArabic ? Ar.directorySearchHint : En.directorySearchHint,
              lightSurface: true,
            ),
          ),
          _buildFilters(context, isArabic),
          Expanded(child: _buildBody(context, isArabic)),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, bool isArabic) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterDropdown<String>(
                  label: isArabic ? Ar.directoryFilterCategory : En.directoryFilterCategory,
                  value: _entityType,
                  allLabel: isArabic ? Ar.directoryFilterAll : En.directoryFilterAll,
                  options: CanonicalEntityTypePresentation.orderedTypes,
                  optionLabel: (type) =>
                      CanonicalEntityTypePresentation.labelFor(type, isArabic: isArabic),
                  onChanged: _onEntityTypeChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _FilterDropdown<String>(
                  label: isArabic ? Ar.directoryFilterLocation : En.directoryFilterLocation,
                  value: _regionCode,
                  allLabel: isArabic ? Ar.directoryFilterAll : En.directoryFilterAll,
                  options: _availableRegionCodes,
                  optionLabel: (code) => code,
                  onChanged: _onRegionChanged,
                ),
              ),
            ],
          ),
          if (_availableCategories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _FilterDropdown<String>(
              label: isArabic ? Ar.directoryFilterCategory : En.directoryFilterCategory,
              value: _categoryId,
              allLabel: isArabic ? Ar.directoryFilterAll : En.directoryFilterAll,
              options: _availableCategories.map((c) => c.id).toList(),
              optionLabel: (id) => _availableCategories
                  .firstWhere((c) => c.id == id, orElse: () => _availableCategories.first)
                  .name,
              onChanged: _onCategoryChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isArabic) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final results = _results;

    // Stale/offline banner.
    if (_loadState == DirectoryLoadState.stale) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.warning.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'عرض بيانات مخزنة — قد لا تكون محدّثة'
                        : 'Showing cached data — may not be up to date',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
          if (results.isEmpty && _entities.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(child: _buildResultsList(context, results)),
        ],
      );
    }

    if (_loadState == DirectoryLoadState.error) {
      return ErrorStateWidget(
        message: isArabic ? Ar.errorOccurred : En.errorOccurred,
        onRetry: _load,
      );
    }

    if (_loadState == DirectoryLoadState.empty || (_entities.isEmpty && results.isEmpty)) {
      return EmptyStateWidget(
        icon: Icons.business_center_outlined,
        message: isArabic ? Ar.directoryEmptyDirectory : En.directoryEmptyDirectory,
      );
    }

    if (results.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        message: isArabic ? Ar.directoryNoResults : En.directoryNoResults,
      );
    }

    return _buildResultsList(context, results);
  }

  Widget _buildResultsList(
    BuildContext context,
    List<CanonicalDirectoryEntity> results,
  ) {
    final isShellHosted = ShellContentInsets.maybeOf(context) != null;
    final effectiveBottomPadding = isShellHosted
        ? shellSafeBottomPadding(context)
        : widget.bottomContentPadding + MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.lg,
          end: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: effectiveBottomPadding,
        ),
        itemCount: results.length,
        separatorBuilder: (_, __) => AppSpacing.gapMd,
        itemBuilder: (context, index) {
          final entity = results[index];
          return DirectoryProviderCard(
            entity: entity,
            onTap: () => _openDetail(context, entity),
          );
        },
      ),
    );
  }

  /// Opens provider detail through the canonical `/directory/entity/:id`
  /// route. The canonical `directory_entities.id` is the route identity; the
  /// whole entity is passed only as a non-authoritative first-frame hint.
  void _openDetail(BuildContext context, CanonicalDirectoryEntity entity) {
    context.push(
      AppRoutes.directoryEntityDetailFor(entity.id),
      extra: entity,
    );
  }
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
    return DropdownButtonFormField<T?>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceWhite.withValues(alpha: 0.95),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      items: [
        DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
        for (final option in options)
          DropdownMenuItem<T?>(
            value: option,
            child: Text(
              optionLabel(option),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
