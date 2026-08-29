import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../../../features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../data/datasources/ad_data_source.dart';
import '../data/home_content_source.dart';
import 'widgets/ad_carousel_widget.dart';
import 'widgets/categories_section.dart';
import 'widgets/engineering_topics_section.dart';
import 'widgets/home_header.dart';
import 'widgets/latest_articles_section.dart';
import 'widgets/quick_access_section.dart';
import 'widgets/quick_tools_section.dart';

/// Activates the Encyclopedia shell branch with [query] already applied.
/// Home only collects the query; Encyclopedia owns the search logic.
void openEncyclopediaSearch(BuildContext context, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return;
  context.go('/encyclopedia?q=${Uri.encodeComponent(trimmed)}');
}

/// Real pull-to-refresh for Home data. Completes only when the Encyclopedia
/// reload finishes; there is no synthetic delay or fake success.
Future<void> refreshHomeData(BuildContext context) async {
  HapticFeedback.mediumImpact();
  await context.read<EncyclopediaProvider>().loadAllTopics();
}

class HomeMainScreen extends StatefulWidget {
  const HomeMainScreen({super.key});

  @override
  State<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends State<HomeMainScreen> {
  Future<void> _onRefresh() => refreshHomeData(context);

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const HomeHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SearchBarWidget(
                lightSurface: true,
                hintText: Ar.homeEngineeringSearchHint,
                onSubmitted: (query) => openEncyclopediaSearch(context, query),
              ),
            ),
            AdCarouselWidget(
              dataSource: kDebugMode ? MockAdDataSource() : LocalAdDataSource(),
            ),
            SectionHeader(title: Ar.quickAccess),
            const QuickAccessSection(),
            const SizedBox(height: 6),
            SectionHeader(title: Ar.siteTools),
            const QuickToolsSection(),
            const SizedBox(height: 6),
            SectionHeader(
              title: Ar.exploreEngineeringContent,
              actionLabel: tr(Ar.viewAll, En.viewAll),
              onAction: () => context.push('/categories'),
            ),
            const CategoriesSection(),
            const SizedBox(height: 6),
            SectionHeader(
              title: Ar.engineeringTopics,
              actionLabel: tr(Ar.viewAll, En.viewAll),
              onAction: () => context.go('/encyclopedia'),
            ),
            const EngineeringTopicsSection(),
            const SizedBox(height: 6),
            SectionHeader(
              title: Ar.latestArticles,
              actionLabel: tr(Ar.viewAll, En.viewAll),
              onAction: () => context.push('/articles'),
            ),
            LatestArticlesSection(
              articles: const HomeContentSource().latestArticles,
            ),
            SizedBox(height: bottomPadding + 24),
          ],
        ),
      ),
    );
  }
}
