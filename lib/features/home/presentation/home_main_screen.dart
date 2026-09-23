import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/shell_content_insets.dart';
import '../../../core/widgets/search_bar_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../../../features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../data/datasources/ad_data_source.dart';
import '../data/home_content_source.dart';
import 'widgets/ad_carousel_widget.dart';
import 'widgets/categories_section.dart';
import 'widgets/engineering_topics_section.dart';
import 'widgets/engineering_directory_section.dart';
import 'widgets/home_header.dart';
import 'widgets/latest_articles_section.dart';
import 'widgets/quick_tools_section.dart';

/// Activates the Encyclopedia shell branch with [query] already applied.
///
/// Retained for the encyclopedia-internal `/encyclopedia?q=` flow. Home's own
/// search no longer uses this path since W2.4; see [openHomeSearch].
void openEncyclopediaSearch(BuildContext context, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return;
  context.go('/encyclopedia?q=${Uri.encodeComponent(trimmed)}');
}

/// Acts as a single Home search entry point (W1.2/W2.4).
///
/// Expresses USER INTENT ("open Home search") rather than a specific
/// destination, so Home presentation does not couple to any search screen. The
/// current (W2.4) implementation PUSHES the root Global Search screen at
/// `/search`; the user types the query only once, inside Global Search, so
/// nothing is entered or forwarded from Home.
void openHomeSearch(BuildContext context) {
  context.push(AppRoutes.search);
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String ar, String en) => isArabic ? ar : en;
    final bottomSpacer = shellSafeBottomPadding(context);
    final amberAction = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HomeHeader(),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        0,
                        16,
                        4,
                      ),
                      child: SearchBarWidget(
                        compact: true,
                        lightSurface: true,
                        hintText: tr(
                          Ar.homeEngineeringSearchHint,
                          En.homeEngineeringSearchHint,
                        ),
                        readOnly: true,
                        onTap: () => openHomeSearch(context),
                      ),
                    ),
                    AdCarouselWidget(
                      dataSource: kDebugMode
                          ? MockAdDataSource()
                          : LocalAdDataSource(),
                    ),
                    SectionHeader(
                      homeAccent: true,
                      title: tr(Ar.siteTools, En.siteTools),
                    ),
                    const QuickToolsSection(),
                    const SizedBox(height: 8),
                    const EngineeringDirectorySection(),
                    const SizedBox(height: 8),
                    SectionHeader(
                      homeAccent: true,
                      title: tr(
                        Ar.exploreEngineeringContent,
                        En.exploreEngineeringContent,
                      ),
                      actionLabel: tr(Ar.viewAll, En.viewAll),
                      actionColor: amberAction,
                      onAction: () => context.push('/categories'),
                    ),
                    const CategoriesSection(),
                    const SizedBox(height: 8),
                    SectionHeader(
                      homeAccent: true,
                      title: tr(Ar.engineeringTopics, En.engineeringTopics),
                      actionLabel: tr(Ar.viewAll, En.viewAll),
                      actionColor: amberAction,
                      onAction: () => context.go('/encyclopedia'),
                    ),
                    const EngineeringTopicsSection(),
                    const SizedBox(height: 8),
                    SectionHeader(
                      homeAccent: true,
                      title: tr(Ar.latestArticles, En.latestArticles),
                      actionLabel: tr(Ar.viewAll, En.viewAll),
                      actionColor: amberAction,
                      onAction: () => context.push('/articles'),
                    ),
                    LatestArticlesSection(
                      articles: const HomeContentSource().latestArticles,
                    ),
                    SizedBox(height: bottomSpacer),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
