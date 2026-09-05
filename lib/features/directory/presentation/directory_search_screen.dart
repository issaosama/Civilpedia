import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/location/baghdad_area.dart';
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
import '../../monetization/domain/services/campaign_source.dart';
import '../../profile/domain/service_business_profile.dart';
import '../application/directory_sponsored_placement_coordinator.dart';
import '../domain/directory_query.dart';
import '../domain/directory_query_engine.dart';
import '../domain/directory_repository.dart';
import 'directory_category_presentation.dart';
import 'directory_provider_card.dart';
import 'directory_provider_detail_screen.dart';
import 'widgets/directory_sponsored_provider_card.dart';

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
///
/// W7.2 — adds ONE optional, clearly disclosed sponsored provider slot ABOVE the
/// organic results. Organic results remain exactly as [DirectoryQueryEngine]
/// produces them (sponsorship-blind). Sponsored resolution runs in parallel and
/// fails closed: with no active eligible campaign, an unconfigured (honest-empty)
/// campaign source, or any resolution failure, NO sponsored slot is rendered and
/// no blank space is left. The listing card itself stays organic-neutral — the
/// sponsored disclosure lives on the wrapper, not the card.
class DirectorySearchScreen extends StatefulWidget {
  /// Pre-selected [BusinessType] to start with, used by the W5.2
  /// [DirectoryLandingScreen.onCategorySelected] seam. Null starts in browse
  /// mode (all categories).
  final BusinessType? initialCategory;

  /// Repository to load profiles from. Defaults to the canonical W5.1
  /// [AppDependencies.directoryRepo]. Tests inject a fake.
  final DirectoryRepository? repository;

  /// W7.2 — Campaign source for the sponsored search slot. Production default is
  /// the honest-empty [AppDependencies.campaignSource]; tests inject a fake.
  /// When absent, an unconfigured build renders no sponsored content.
  final CampaignSource? campaignSource;

  /// W7.2 — Injected clock for deterministic sponsored eligibility evaluation.
  /// Defaults to [DateTime.now]. Tests inject a fixed time.
  final DateTime Function()? now;

  /// Bottom scroll clearance for the result list.
  ///
  /// Mirrors the W5.2 shell-independent seam: this screen must NOT know the
  /// AppShell floating-nav geometry (bar height, margin, safe offsets). When
  /// hosted STANDALONE (W5.3 default), the final bottom clearance is
  /// `bottomContentPadding + device bottom SafeArea inset`. When hosted inside
  /// the AppShell (W6.3), the screen detects the shell ancestor and instead
  /// applies the closed UI-SAFE-1 contract via [shellSafeBottomPadding], so the
  /// shell obstruction and device inset are never summed.
  final double bottomContentPadding;

  const DirectorySearchScreen({
    super.key,
    this.initialCategory,
    this.repository,
    this.campaignSource,
    this.now,
    this.bottomContentPadding = AppSpacing.huge,
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

  DirectorySponsoredPlacement? _sponsored;

  /// Monotonic guard so an older sponsored resolution never overwrites a newer
  /// one if the screen reloads, and no stale sponsored update is applied after
  /// the load that owns it has been superseded (W7.2 §19 async safety).
  int _sponsoredRequest = 0;

  String _text = '';
  BusinessType? _category;
  BaghdadArea? _location;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AppDependencies.directoryRepo;
    _category = widget.initialCategory;
    _load();
    _loadSponsored();
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

  /// W7.2 — Resolves the single sponsored slot in PARALLEL to organic loading.
  ///
  /// Fails closed: a source error yields no sponsored content and never affects
  /// organic results. A stale resolution (superseded reload or post-disposal) is
  /// dropped via [mounted] + [_sponsoredRequest].
  Future<void> _loadSponsored() async {
    final requestToken = ++_sponsoredRequest;
    final coordinator = DirectorySponsoredPlacementCoordinator(
      campaignSource: widget.campaignSource ?? AppDependencies.campaignSource,
      directoryRepository: _repository,
    );
    DirectorySponsoredPlacement? result;
    try {
      result = await coordinator.resolveFirstRenderable(
        at: (widget.now ?? DateTime.now)(),
      );
    } catch (_) {
      result = null;
    }
    if (!mounted || requestToken != _sponsoredRequest) return;
    setState(() => _sponsored = result);
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
    final results = _results;
    final sponsored = _sponsored;
    final showSponsored = sponsored != null;

    // The sponsored slot renders INDEPENDENTLY of organic results (W7.2 §P):
    // a sponsored provider need not match the current organic query, category,
    // or location filter. Only when there is NO sponsored content do we fall
    // through to the organic-only empty states.
    if (results.isEmpty && !showSponsored) {
      return EmptyStateWidget(
        icon: loaded.isEmpty ? Icons.business_center_outlined : Icons.search_off,
        message: isArabic
            ? (loaded.isEmpty ? Ar.directoryEmptyDirectory : Ar.directoryNoResults)
            : (loaded.isEmpty ? En.directoryEmptyDirectory : En.directoryNoResults),
      );
    }

    // W6.3 UI-SAFE-1 — explicit dual-host clean bottom clearance (identical to
    // DirectoryLandingScreen): shell-hosted uses the closed MAX contract,
    // standalone preserves the W5 bottomContentPadding + deviceInset seam.
    final isShellHosted = ShellContentInsets.maybeOf(context) != null;
    final effectiveBottomPadding = isShellHosted
        ? shellSafeBottomPadding(context)
        : widget.bottomContentPadding + MediaQuery.paddingOf(context).bottom;

    // Assemble the scroll body: optional sponsored slot FIRST (clearly
    // disclosed), then organic results in their untouched DirectoryQueryEngine
    // order. Both share one scroll body/insets — no fixed-position overlay.
    final itemWidgets = <Widget>[];
    if (showSponsored) {
      itemWidgets.add(
        DirectorySponsoredProviderCard(
          placement: sponsored.placement,
          profile: sponsored.profile,
          onTap: () => _openDetail(context, sponsored.profile),
        ),
      );
    }
    for (final profile in results) {
      itemWidgets.add(
        DirectoryProviderCard(
          profile: profile,
          onTap: () => _openDetail(context, profile),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: effectiveBottomPadding,
      ),
      itemCount: itemWidgets.length,
      separatorBuilder: (_, __) => AppSpacing.gapMd,
      itemBuilder: (context, index) => itemWidgets[index],
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
