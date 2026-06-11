import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../data/repositories/article_repository.dart';
import '../../../../data/local/hive_helper.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final String articleId;

  const ArticleDetailsScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  late bool _isFavorite;
  late bool _isDownloaded;

  @override
  void initState() {
    super.initState();
    _isFavorite = HiveHelper.isFavorite(widget.articleId);
    _isDownloaded = HiveHelper.isDownloaded(widget.articleId);
  }

  void _toggleFavorite() async {
    HapticFeedback.lightImpact();
    await HiveHelper.toggleFavorite(widget.articleId);
    setState(() => _isFavorite = !_isFavorite);
  }

  void _toggleDownload() async {
    HapticFeedback.lightImpact();
    final repo = ArticleRepository();
    final article = repo.getArticleById(widget.articleId);
    await HiveHelper.toggleDownload(widget.articleId, article);
    setState(() => _isDownloaded = !_isDownloaded);
    if (mounted) {
      final isArabic = context.read<LanguageProvider>().isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isDownloaded
              ? (isArabic ? Ar.articleSaved : En.articleSaved)
              : (isArabic ? Ar.articleRemoved : En.articleRemoved)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final repo = ArticleRepository();
    final article = HiveHelper.getOfflineArticle(widget.articleId) ?? repo.getArticleById(widget.articleId);

    if (article == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(Ar.articleDetails)),
        body: Center(child: Text(tr(Ar.articleNotFound, En.articleNotFound))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(Ar.articleDetails),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? Ar.removeFromFavorites : Ar.addToFavorites,
          ),
          IconButton(
            icon: Icon(_isDownloaded ? Icons.download_done : Icons.download),
            onPressed: _toggleDownload,
            tooltip: _isDownloaded ? Ar.downloaded : Ar.download,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          Hero(
            tag: 'article_img_${article.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: article.image,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.category,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            article.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            article.content,
            style: const TextStyle(fontSize: 16, height: 1.8),
          ),
        ],
      ),
    );
  }
}
