import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/location/baghdad_area.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_app_bar.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../profile/domain/service_business_profile.dart';
import '../domain/directory_query.dart';
import '../domain/directory_query_engine.dart';
import '../domain/directory_repository.dart';
import 'directory_category_presentation.dart';
import 'directory_provider_card.dart';
import 'directory_provider_detail_screen.dart';

/// Directory-local search + location/category filter surface (W5.3).
///
/// PRODUCTION-UNEXPOSED: nothing routes or navigates to this screen until the
/// W6 readiness gate wires it. It loads [DirectoryRepository.loadAll] once and
/// applies search/filter purely in memory via [DirectoryQueryEngine].
///
/// W5.3 owns search/filter only. W5.4 owns the canonical provider listing and
/// detail; results render via [DirectoryProviderCard] and tapping opens
/// [DirectoryProviderDetailScreen] through an internal (production-unexposed)
/// Navigator push. No contact, verification, saved, or sponsored/featured/plan
/// signals are shown on the listing card itself.
class DirectorySearchScreen extends StatefulWidget {
  /// Pre-selected [BusinessType] to start with, used by the W5.2
  /// [DirectoryLandingScreen.onCategorySelected] seam. Null starts in browse
  /// mode (all categories).
  final BusinessType? initialCategory;

  /// Repository to load profiles from. Defaults to the canonical W5.1
  /// [AppDependencies.directoryRepo]. Tests inject a fake.
  final DirectoryRepository? repository;

  const DirectorySearchScreen({
    super.key,
    this.initialCategory,
    this.repository,
  });

  @override
  State<DirectorySearchScreen> createState() => _DirectorySearchScreenState();
}

class _DirectorySearchScreenState extends State<DirectorySearchScreen> {
  static const Duration _debounceDuration = Duration(milliseconds: 280);

  late final DirectoryRepository _repository;
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  List<ServiceBusinessProfile>? _loaded;
  bool _loading = true;
  bool _loadFailed = false;

  String _text = '';
  BusinessType? _category;
  BaghdadArea? _location;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppDependencies.directoryRepo;
    _category = widget.initialCategory;
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
      _loadFailed = false;
    });
    try {
      final profiles = await _repository.loadAll();
      if (!mounted) return;
      setState(() {
        _loaded = profiles;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
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

  void _onCategoryChanged(BusinessType? value) {
    setState(() => _category = value);
  }

  void _onLocationChanged(BaghdadArea? value) {
    setState(() => _location = value);
  }

  List<ServiceBusinessProfile> get _results {
    final loaded = _loaded ?? const <ServiceBusinessProfile>[];
    if (loaded.isEmpty) return const [];
    return DirectoryQueryEngine.apply(
      loaded,
      DirectoryQuery(text: _text, category: _category, location: _location),
    );
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
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown<BusinessType>(
              label: isArabic ? Ar.directoryFilterCategory : En.directoryFilterCategory,
              value: _category,
              allLabel: isArabic ? Ar.directoryFilterAll : En.directoryFilterAll,
              options: DirectoryCategoryPresentation.orderedTypes,
              optionLabel: (type) =>
                  DirectoryCategoryPresentation.labelFor(type, isArabic: isArabic),
              onChanged: _onCategoryChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _FilterDropdown<BaghdadArea>(
              label: isArabic ? Ar.directoryFilterLocation : En.directoryFilterLocation,
              value: _location,
              allLabel: isArabic ? Ar.directoryFilterAll : En.directoryFilterAll,
              options: _selectableLocations,
              optionLabel: (area) => isArabic ? area.arName : area.enName,
              onChanged: _onLocationChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// User-selectable [BaghdadArea] values. `unknown` is a technical sentinel and
  /// is never a user-facing option. `other` remains selectable.
  static final List<BaghdadArea> _selectableLocations = BaghdadArea.values
      .where((area) => area != BaghdadArea.unknown)
      .toList();

  Widget _buildBody(BuildContext context, bool isArabic) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadFailed) {
      return ErrorStateWidget(
        message: isArabic ? Ar.errorOccurred : En.errorOccurred,
        onRetry: _load,
      );
    }

    final loaded = _loaded ?? const <ServiceBusinessProfile>[];
    if (loaded.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.business_center_outlined,
        message: isArabic ? Ar.directoryEmptyDirectory : En.directoryEmptyDirectory,
      );
    }

    final results = _results;
    if (results.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        message: isArabic ? Ar.directoryNoResults : En.directoryNoResults,
      );
    }

    return ListView.separated(
      padding: AppSpacing.padLg,
      itemCount: results.length,
      separatorBuilder: (_, __) => AppSpacing.gapMd,
      itemBuilder: (context, index) => DirectoryProviderCard(
        profile: results[index],
        onTap: () => _openDetail(context, results[index]),
      ),
    );
  }

  void _openDetail(BuildContext context, ServiceBusinessProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DirectoryProviderDetailScreen(profile: profile),
      ),
    );
  }
}

/// Compact single-select filter dropdown reused for Category and Location.
///
/// `value` of null represents "All" ([Ar.directoryFilterAll] /
/// [En.directoryFilterAll]). Selection applies immediately (no debounce).
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
