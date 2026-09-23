import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/navigation/shell_content_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_app_bar.dart';
import '../../../core/widgets/civil_surface_card.dart';
import '../../../data/local/hive_helper.dart';
import '../../../data/repositories/article_repository.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../../routes/app_routes.dart';
import '../../articles/presentation/widgets/article_image.dart';
import '../../directory/domain/canonical_directory_entity.dart';
import '../../directory/domain/cloud_directory_repository.dart';
import '../../directory/presentation/canonical_entity_type_presentation.dart';
import '../../encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import '../../encyclopedia/presentation/providers/encyclopedia_provider.dart';
import '../../encyclopedia/presentation/widgets/topic_list_card.dart';
import '../../saved/domain/saved_reference_store.dart';
import '../data/hive_saved_reference_resolver.dart';
import '../domain/saved_item_reference.dart';
import '../domain/saved_reference_resolver.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({
    super.key,
    this.favoritesResolver,
    this.directoryRepository,
    this.savedReferenceStore,
    this.initialTabIndex = 0,
  });

  /// W3.2 — canonical Saved-reference resolver used as the Favorites identity
  /// source. Defaults to the production Hive-backed resolver
  /// ([hiveSavedReferenceResolver]).
  final SavedReferenceResolver? favoritesResolver;

  /// V1-R05 — Directory-domain repository used to resolve saved provider
  /// references through canonical `directory_entities.id`. Defaults to
  /// [AppDependencies.directoryRepo]; tests inject a fake.
  final CloudDirectoryRepository? directoryRepository;

  /// Canonical User-owned Saved store.
  ///
  /// W5.6 — forwarded to the [DirectoryProviderDetailScreen] pushed from a
  /// saved Directory row so its bookmark stays consistent. Defaults to
  /// [AppDependencies.savedReferenceStore]; tests inject a fake in-memory store
  /// to avoid real persistent writes.
  final SavedReferenceStore? savedReferenceStore;

  /// W3.4 — tab selected when the screen is first built. `0` = Favorites,
  /// `1` = Downloads. Applied through `TabController.initialIndex` (created
  /// once in initState), so existing callers stay untouched and default to
  /// Favorites. The `/user/downloads` route uses `1` so the Downloads tab is
  /// genuinely selected on arrival rather than after a post-frame jump.
  final int initialTabIndex;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final SavedReferenceResolver _resolver;

  /// Optional injected Directory repository override. When null the effective
  /// repo is resolved lazily ([AppDependencies.directoryRepo]) only when a
  /// directory ref must be resolved — never eagerly at initState, so contexts
  /// that never need the Directory backend (e.g. Knowledge-only Favorites)
  /// stay lightweight and never touch the lazy singleton.

  List<SavedItemReference> _favorites = const [];
  bool _favoritesLoaded = false;
  bool _favoritesLoadFailed = false;
  int _loadGeneration = 0;
  EncyclopediaFavoritesProvider? _favoritesProvider;

  /// Resolved Directory providers, in reference/source order. Null entries mark
  /// provider refs whose entity can no longer be resolved (shown unavailable).
  List<CanonicalDirectoryEntity?> _directoryProviders = const [];

  @override
  void initState() {
    super.initState();
    _resolver = widget.favoritesResolver ?? hiveSavedReferenceResolver();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex < 0
          ? 0
          : (widget.initialTabIndex > 1 ? 1 : widget.initialTabIndex),
    );
    _tabController.addListener(_onTabChanged);
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final encyclopediaProvider = context.read<EncyclopediaProvider>();
      if (encyclopediaProvider.allTopics.isEmpty &&
          !encyclopediaProvider.isLoading) {
        encyclopediaProvider.loadAllTopics();
      }
      _favoritesProvider = context.read<EncyclopediaFavoritesProvider>();
      _favoritesProvider!.addListener(_onFavoritesChanged);
    });
  }

  @override
  void dispose() {
    _favoritesProvider?.removeListener(_onFavoritesChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 0 && !_tabController.indexIsChanging) {
      _loadFavorites();
    }
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    _loadFavorites();
  }

  void _loadFavorites() {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    _resolver
        .resolve()
        .then((refs) async {
          if (!mounted || generation != _loadGeneration) return;
          // Publish local Saved refs immediately; do not block the whole screen
          // on Directory cloud resolution. Directory refs are represented as
          // unavailable rows until cache/cloud resolution supplies entities.
          final directoryRefs = _directoryRefs(refs);
          setState(() {
            _favorites = refs;
            _directoryProviders = List<CanonicalDirectoryEntity?>.filled(
              directoryRefs.length,
              null,
            );
            _favoritesLoaded = true;
            _favoritesLoadFailed = false;
          });
          await _resolveDirectoryProviders(directoryRefs, generation);
        })
        .catchError((Object _) {
          if (!mounted || generation != _loadGeneration) return;
          setState(() {
            _favorites = const <SavedItemReference>[];
            _directoryProviders = const [];
            _favoritesLoaded = true;
            _favoritesLoadFailed = true;
          });
        });
  }

  List<SavedItemReference> _directoryRefs(List<SavedItemReference> refs) {
    final directoryRefs = <SavedItemReference>[];
    for (final ref in refs) {
      if (ref.ownerDomain != SavedReferenceOwners.directory) continue;
      if (ref.entityType != SavedReferenceEntityTypes.provider) continue;
      directoryRefs.add(ref);
    }
    return directoryRefs;
  }

  /// V1-R09 P2-B2 — resolves saved Directory provider refs locally first,
  /// then joins exactly ONE complete repository refresh for any IDs not found
  /// in cache. Never deletes Saved refs, never makes sequential remote calls,
  /// and never installs a reconnect listener.
  Future<void> _resolveDirectoryProviders(
    List<SavedItemReference> directoryRefs,
    int generation,
  ) async {
    if (directoryRefs.isEmpty) return;

    final repo = widget.directoryRepository ?? AppDependencies.directoryRepo;
    final providers = List<CanonicalDirectoryEntity?>.filled(
      directoryRefs.length,
      null,
    );
    final unresolvedIndices = <int>[];

    // Read cache once and publish cached matches immediately.
    final cached = await repo.readCache();
    for (var i = 0; i < directoryRefs.length; i++) {
      final entityId = directoryRefs[i].entityId;
      if (entityId.isEmpty || !CanonicalDirectoryEntity.isValidUuid(entityId)) {
        continue;
      }
      final entity = cached?.byId(entityId);
      if (entity != null) {
        providers[i] = entity;
      } else {
        unresolvedIndices.add(i);
      }
    }

    if (!mounted || generation != _loadGeneration) return;
    setState(() => _directoryProviders = providers);

    if (unresolvedIndices.isEmpty) return;

    // One complete refresh for all unresolved IDs.
    final refreshResult = await repo.refresh();
    if (!mounted || generation != _loadGeneration) return;

    if (refreshResult.succeeded) {
      for (final idx in unresolvedIndices) {
        final entityId = directoryRefs[idx].entityId;
        providers[idx] = _findById(refreshResult.entities, entityId);
      }
    }
    // On failure, unresolved entries remain null (unavailable) without deleting
    // the Saved reference.

    setState(() => _directoryProviders = providers);
  }

  static CanonicalDirectoryEntity? _findById(
    List<CanonicalDirectoryEntity> entities,
    String id,
  ) {
    for (final entity in entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: CivilAppBar(
        title: Text(isArabic ? Ar.saved : En.saved),
        showDivider: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isArabic ? Ar.favorites : En.favorites),
            Tab(text: isArabic ? Ar.downloads : En.downloads),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _responsiveTab(_buildFavoritesList()),
          _responsiveTab(_buildDownloadsList()),
        ],
      ),
    );
  }

  Widget _responsiveTab(Widget child) {
    return LayoutBuilder(
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
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList() {
    final favoritesProvider = context.watch<EncyclopediaFavoritesProvider>();
    final encyclopediaProvider = context.watch<EncyclopediaProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!favoritesProvider.isLoaded || !_favoritesLoaded) {
      return _buildLoadingState();
    }

    if (_favoritesLoadFailed) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      return _buildStateView(
        icon: Icons.error_outline_rounded,
        message: isArabic ? Ar.savedLoadError : En.savedLoadError,
        iconColor: Theme.of(context).colorScheme.error,
        actionLabel: isArabic ? Ar.retry : En.retry,
        onAction: () {
          setState(() {
            _favoritesLoaded = false;
            _favoritesLoadFailed = false;
          });
          _loadFavorites();
        },
      );
    }

    final topicIds = <String>[];
    final articleIds = <String>[];
    for (final reference in _favorites) {
      if (reference.ownerDomain != SavedReferenceOwners.knowledge) continue;
      if (reference.entityType == SavedReferenceEntityTypes.topic) {
        topicIds.add(reference.entityId);
      } else if (reference.entityType == SavedReferenceEntityTypes.article) {
        articleIds.add(reference.entityId);
      }
    }

    final encyclopediaTopics = encyclopediaProvider.resolveTopics(topicIds);
    final canonicalArticleIds = articleIds.toSet();
    final favoriteArticles = ArticleRepository.articles
        .where((article) => canonicalArticleIds.contains(article.id))
        .toList();

    final hasEncyclopedia = encyclopediaTopics.isNotEmpty;
    final hasLegacy = favoriteArticles.isNotEmpty;
    final hasDirectory = _directoryProviders.isNotEmpty;

    if (!hasEncyclopedia && !hasLegacy && !hasDirectory) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      return _buildStateView(
        icon: Icons.favorite_border,
        message: isArabic ? Ar.noFavorites : En.noFavorites,
      );
    }

    return ListView(
      padding: EdgeInsets.only(
        top: AppConstants.paddingMedium,
        bottom: shellSafeBottomPadding(context),
      ),
      children: [
        if (hasEncyclopedia) ...[
          _sectionHeader(
            Localizations.localeOf(context).languageCode == 'ar'
                ? Ar.engineeringEncyclopedia
                : En.engineeringEncyclopedia,
          ),
          for (final topic in encyclopediaTopics) ...[
            TopicListCard(
              topic: topic,
              isDark: isDark,
              onTap: () => context.push('/encyclopedia/topic/${topic.id}'),
              onRemove: () => favoritesProvider.remove(topic.id),
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (hasLegacy) ...[
          if (hasEncyclopedia)
            _sectionHeader(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? Ar.savedArticlesSection
                  : En.savedArticlesSection,
            ),
          for (final article in favoriteArticles) ...[
            CivilSurfaceCard(
              hasBorder: true,
              onTap: () => context.push('/article/${article.id}'),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppConstants.cardRadius,
                    ),
                    child: ArticleImage(
                      imageUrl: article.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      article.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (hasDirectory) ...[
          _sectionHeader(
            Localizations.localeOf(context).languageCode == 'ar'
                ? Ar.savedEngineeringDirectory
                : En.savedEngineeringDirectory,
          ),
          for (final provider in _directoryProviders) ...[
            _buildDirectoryRow(provider),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  /// V1-R05 — smallest reusable presentation of one saved Directory provider.
  ///
  /// Resolved entity: name + localized canonical entity type + region summary
  /// (when meaningful) + a Directory identity icon, opening the provider detail
  /// on tap. Unavailable (null) entity: a non-navigating "Provider
  /// unavailable" row. Directory identity icon is always shown. No
  /// verification/ranking/sponsored/plan signals, and no saved button inside
  /// the already-Saved list.
  Widget _buildDirectoryRow(CanonicalDirectoryEntity? provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final entityType = provider?.entityType ?? 'other';
    final icon = CanonicalEntityTypePresentation.iconFor(entityType);
    final iconSurface = isDark
        ? AppColors.darkInfoSoft
        : AppColors.brandBlueSoft;
    final iconColor = isDark ? AppColors.darkBrandBlue : AppColors.brandBlue;
    return CivilSurfaceCard(
      hasBorder: true,
      onTap: provider == null ? null : () => _openSavedProvider(provider),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconSurface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider != null)
                  Text(
                    provider.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    isArabic
                        ? Ar.savedProviderUnavailable
                        : En.savedProviderUnavailable,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                if (provider != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _providerSubtitle(provider, isArabic: isArabic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _providerSubtitle(
    CanonicalDirectoryEntity provider, {
    required bool isArabic,
  }) {
    final typeLabel = CanonicalEntityTypePresentation.labelFor(
      provider.entityType,
      isArabic: isArabic,
    );
    final locationLabel = provider.locations.isNotEmpty
        ? provider.locations.first.regionName
        : null;
    if (locationLabel == null || locationLabel.isEmpty) return typeLabel;
    return '$typeLabel · $locationLabel';
  }

  Future<void> _openSavedProvider(CanonicalDirectoryEntity provider) async {
    // Navigate through the canonical `/directory/entity/:id` route: the saved
    // reference is re-resolved against the canonical repository/cache at the
    // destination. The whole entity is only a non-authoritative first-frame
    // hint, never the authoritative detail state.
    await context.push(
      AppRoutes.directoryEntityDetailFor(provider.id),
      extra: provider,
    );
    if (mounted) _loadFavorites();
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.xs,
        bottom: AppSpacing.md,
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDownloadsList() {
    final downloadedIds = HiveHelper.getDownloads();
    final articles = ArticleRepository.articles
        .where((a) => downloadedIds.contains(a.id))
        .toList();

    if (articles.isEmpty) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      return _buildStateView(
        icon: Icons.download_outlined,
        message: isArabic ? Ar.noDownloads : En.noDownloads,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        top: AppConstants.paddingMedium,
        bottom: shellSafeBottomPadding(context),
      ),
      itemCount: articles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final article = articles[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return CivilSurfaceCard(
          hasBorder: true,
          onTap: () => context.push('/article/${article.id}'),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                child: ArticleImage(
                  imageUrl: article.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  article.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Icon(
                Icons.check_circle,
                color: isDark ? AppColors.darkSuccess : AppColors.success,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    return Semantics(
      label: isArabic ? Ar.loading : En.loading,
      liveRegion: true,
      child: Center(
        child: SizedBox.square(
          dimension: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStateView({
    required IconData icon,
    required String message,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurfaceVariant;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl + AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
              ),
              child: Icon(icon, size: 28, color: effectiveIconColor),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
