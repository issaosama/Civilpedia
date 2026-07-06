import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/article_repository.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import 'widgets/ad_carousel_widget.dart';
import 'widgets/quick_tools_section.dart';
import 'widgets/categories_section.dart';
import 'widgets/encyclopedia_section.dart';
import 'widgets/articles_section.dart';

class HomeMainScreen extends StatefulWidget {
  const HomeMainScreen({super.key});

  @override
  State<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends State<HomeMainScreen> {
  bool _isLoading = false;

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final repo = ArticleRepository();
    final auth = context.watch<AuthProvider>();
    final connectivity = context.watch<ConnectivityProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1A1813), const Color(0xFF24221A)]
                      : [const Color(0xFF2A2620), const Color(0xFF3A3530)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              auth.isLoggedIn
                                  ? auth.userName[0].toUpperCase()
                                  : 'Z',
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.isLoggedIn
                                      ? '${tr(Ar.welcome, En.welcome)}، ${auth.userName}'
                                      : tr(Ar.welcome, En.welcome),
                                  style: const TextStyle(
                                    color: Color(0xFFF0ECE2),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      auth.isLoggedIn
                                          ? auth.userEmail
                                          : Ar.appName,
                                      style: TextStyle(
                                        color: const Color(0xFFA8A294).withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      connectivity.isOnline
                                          ? Icons.wifi
                                          : Icons.wifi_off,
                                      size: 14,
                                      color: connectivity.isOnline
                                          ? Colors.greenAccent
                                          : Colors.orange.shade300,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SearchBarWidget(),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.5),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: AdCarouselWidget(),
            ),
            Container(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.5),
            ),
            SectionHeader(title: Ar.quickTools, actionLabel: tr(Ar.viewAll, En.viewAll)),
            const QuickToolsSection(),
            AppSpacing.gapSm,
            SectionHeader(
              title: Ar.categories,
              actionLabel: tr(Ar.viewAll, En.viewAll),
              onAction: () => context.push('/categories'),
            ),
            const CategoriesSection(),
            SectionHeader(
              title: tr(Ar.engineeringEncyclopedia, En.engineeringEncyclopedia),
              actionLabel: tr(Ar.viewAll, En.viewAll),
              onAction: () => context.push('/categories'),
            ),
            const EncyclopediaSection(),
            AppSpacing.gapSm,
            if (_isLoading)
              const ShimmerSection()
            else ...[
              ArticlesSection(
                title: Ar.featuredArticles,
                articles: repo.getFeaturedArticles(),
              ),
              const SizedBox(height: 8),
              ArticlesSection(
                title: Ar.latestArticles,
                articles: repo.getLatestArticles(),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
