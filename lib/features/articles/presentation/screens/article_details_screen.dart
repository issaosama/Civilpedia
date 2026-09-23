import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../data/local/hive_helper.dart';
import '../../../../data/repositories/article_repository.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../widgets/article_image.dart';

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
          content: Text(
            _isDownloaded
                ? (isArabic ? Ar.articleSaved : En.articleSaved)
                : (isArabic ? Ar.articleRemoved : En.articleRemoved),
          ),
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
    final article =
        HiveHelper.getOfflineArticle(widget.articleId) ??
        repo.getArticleById(widget.articleId);

    if (article == null) {
      return Scaffold(
        appBar: CivilAppBar(
          title: Text(tr(Ar.articleDetails, En.articleDetails)),
        ),
        body: Center(child: Text(tr(Ar.articleNotFound, En.articleNotFound))),
      );
    }

    return Scaffold(
      appBar: CivilAppBar(
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite
                ? tr(Ar.removeFromFavorites, En.removeFromFavorites)
                : tr(Ar.addToFavorites, En.addToFavorites),
          ),
          IconButton(
            icon: Icon(_isDownloaded ? Icons.download_done : Icons.download),
            onPressed: _toggleDownload,
            tooltip: _isDownloaded
                ? tr(Ar.downloaded, En.downloaded)
                : tr(Ar.download, En.download),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = constraints.maxWidth < 600
              ? AppSpacing.lg
              : constraints.maxWidth < 840
              ? AppSpacing.xxl
              : AppSpacing.xxl + AppSpacing.sm;
          final contentWidth = (constraints.maxWidth - gutter * 2)
              .clamp(0, 760)
              .toDouble();
          final imageHeight = constraints.maxWidth < 600 ? 210.0 : 280.0;

          return Align(
            alignment: AlignmentDirectional.topCenter,
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                children: [
                  Hero(
                    tag: 'article_img_${article.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMd,
                      ),
                      child: ArticleImage(
                        imageUrl: article.image,
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  AppSpacing.gapLg,
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _CategoryChip(
                      label: article.category,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                  AppSpacing.gapMd,
                  Text(
                    article.title,
                    textAlign: TextAlign.start,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  AppSpacing.gapLg,
                  Text(
                    article.content,
                    textAlign: TextAlign.start,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.8),
                  ),
                  AppSpacing.gapXl,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarningSoft : AppColors.brandAmberSoft,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(
          color: isDark ? AppColors.darkWarning : AppColors.brandAmber,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: isDark
              ? AppColors.darkBrandAmber
              : AppColors.brandAmberPressed,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
