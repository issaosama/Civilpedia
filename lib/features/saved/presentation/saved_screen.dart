import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/navigation/shell_content_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_surface_card.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../data/local/hive_helper.dart';
import '../../../data/repositories/article_repository.dart';
import '../../../localization/ar.dart';
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
            _directoryProviders =
                List<CanonicalDirectoryEntity?>.filled(directoryRefs.length, null);
            _favoritesLoaded = true;
          });
          await _resolveDirectoryProviders(directoryRefs, generation);
        })
        .catchError((Object _) {
          if (!mounted || generation != _loadGeneration) return;
          setState(() {
            _favorites = const <SavedItemReference>[];
            _directoryProviders = const [];
            _favoritesLoaded = true;
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
    final providers =
        List<CanonicalDirectoryEntity?>.filled(directoryRefs.length, null);
    final unresolvedIndices = <int>[];

    // Read cache once and publish cached matches immediately.
    final cached = await repo.readCache();
    for (var i = 0; i < directoryRefs.length; i++) {
      final entityId = directoryRefs[i].entityId;
      if (entityId.isEmpty ||
          !CanonicalDirectoryEntity.isValidUuid(entityId)) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(Ar.saved),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: Ar.favorites),
            Tab(text: Ar.downloads),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFavoritesList(), _buildDownloadsList()],
      ),
    );
  }

  Widget _buildFavoritesList() {
    final favoritesProvider = context.watch<EncyclopediaFavoritesProvider>();
    final encyclopediaProvider = context.watch<EncyclopediaProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!favoritesProvider.isLoaded || !_favoritesLoaded) {
      return const Center(child: CircularProgressIndicator());
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              Ar.noFavorites,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.only(
        left: AppConstants.paddingMedium,
        right: AppConstants.paddingMedium,
        top: AppConstants.paddingMedium,
        bottom: shellSafeBottomPadding(context),
      ),
      children: [
        if (hasEncyclopedia) ...[
          _sectionHeader(Ar.engineeringEncyclopedia),
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
          if (hasEncyclopedia) _sectionHeader(Ar.savedArticlesSection),
          for (final article in favoriteArticles) ...[
            CustomCard(
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
          _sectionHeader(Ar.savedEngineeringDirectory),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entityType = provider?.entityType ?? 'other';
    final icon = CanonicalEntityTypePresentation.iconFor(entityType);
    return CivilSurfaceCard(
      onTap: provider == null ? null : () => _openSavedProvider(provider),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 22),
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
                    Ar.savedProviderUnavailable,
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
                    _providerSubtitle(provider),
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

  String _providerSubtitle(CanonicalDirectoryEntity provider) {
    final typeLabel = CanonicalEntityTypePresentation.labelFor(
      provider.entityType,
      isArabic: true,
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
      padding: const EdgeInsets.only(bottom: 10),
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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_outlined,
              size: 64,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              Ar.noDownloads,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        left: AppConstants.paddingMedium,
        right: AppConstants.paddingMedium,
        top: AppConstants.paddingMedium,
        bottom: shellSafeBottomPadding(context),
      ),
      itemCount: articles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final article = articles[index];
        return CustomCard(
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
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}
