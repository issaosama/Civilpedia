import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../data/local/hive_helper.dart';
import '../../../data/repositories/article_repository.dart';
import '../../../localization/ar.dart';
import '../../articles/presentation/widgets/article_image.dart';
import '../../encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import '../../encyclopedia/presentation/providers/encyclopedia_provider.dart';
import '../../encyclopedia/presentation/widgets/topic_list_card.dart';
import '../data/hive_saved_reference_resolver.dart';
import '../domain/saved_item_reference.dart';
import '../domain/saved_reference_resolver.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key, this.favoritesResolver});

  /// W3.2 — canonical Saved-reference resolver used as the Favorites identity
  /// source. Defaults to the production Hive-backed resolver
  /// ([hiveSavedReferenceResolver]).
  final SavedReferenceResolver? favoritesResolver;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final SavedReferenceResolver _resolver;

  List<SavedItemReference> _favorites = const [];
  bool _favoritesLoaded = false;
  int _loadGeneration = 0;
  EncyclopediaFavoritesProvider? _favoritesProvider;

  @override
  void initState() {
    super.initState();
    _resolver = widget.favoritesResolver ?? hiveSavedReferenceResolver();
    _tabController = TabController(length: 2, vsync: this);
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
    _resolver.resolve().then((refs) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _favorites = refs;
        _favoritesLoaded = true;
      });
    }).catchError((Object _) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _favorites = const <SavedItemReference>[];
        _favoritesLoaded = true;
      });
    });
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
        children: [
          _buildFavoritesList(),
          _buildDownloadsList(),
        ],
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

    if (!hasEncyclopedia && !hasLegacy) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(Ar.noFavorites, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
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
                    child: Text(article.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDownloadsList() {
    final downloadedIds = HiveHelper.getDownloads();
    final articles = ArticleRepository.articles.where((a) => downloadedIds.contains(a.id)).toList();

    if (articles.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_outlined, size: 64, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(Ar.noDownloads, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
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
                child: Text(article.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ],
          ),
        );
      },
    );
  }
}
