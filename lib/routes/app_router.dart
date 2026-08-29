import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/encyclopedia/presentation/screens/categories_screen.dart';
import '../features/encyclopedia/presentation/screens/encyclopedia_screen.dart';
import '../features/encyclopedia/presentation/screens/topic_list_screen.dart';
import '../features/encyclopedia/presentation/screens/topic_detail_screen.dart';
import '../core/navigation/app_shell.dart';
import '../features/home/presentation/home_main_screen.dart';
import '../features/tools/presentation/screens/tools_screen.dart';
import '../features/tools/presentation/screens/calculators/calculator_screen.dart';
import '../features/tools/presentation/screens/checklist/checklist_screen.dart';
import '../features/tools/presentation/screens/calculators/tile_calculator_screen.dart';
import '../features/articles/presentation/screens/all_articles_screen.dart';
import '../features/articles/presentation/screens/articles_screen.dart';
import '../features/articles/presentation/screens/article_details_screen.dart';
import '../features/saved/presentation/saved_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/screens/profile_setup_screen.dart';
import '../features/search/presentation/screens/global_search_screen.dart';
import 'not_found_screen.dart';

final GlobalKey<NavigatorState> _rootNavigator = GlobalKey<NavigatorState>();

/// Screen builders for each shell branch, keyed by the branch route declared
/// in [kShellDestinations]. Branch order and indices live only in that list;
/// this map only resolves a destination to its content screen.
final Map<String, GoRouterWidgetBuilder> _shellBranchBuilders = {
  AppRoutes.home: (_, __) => const HomeMainScreen(),
  AppRoutes.encyclopedia: (_, state) =>
      EncyclopediaScreen(initialQuery: state.uri.queryParameters['q']),
  AppRoutes.tools: (_, __) => const ToolsScreen(),
  AppRoutes.saved: (_, __) => const SavedScreen(),
  AppRoutes.profile: (_, __) => const ProfileScreen(),
};

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigator,
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: AppRoutes.categories,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: AppRoutes.search,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const GlobalSearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.topicListPattern,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) =>
          TopicListScreen(categoryId: state.pathParameters['categoryId'] ?? ''),
    ),
    GoRoute(
      path: AppRoutes.topicDetailPattern,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) =>
          TopicDetailScreen(topicId: state.pathParameters['topicId'] ?? ''),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        for (final destination in kShellDestinations)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: destination.route,
                builder: _shellBranchBuilders[destination.route]!,
              ),
            ],
          ),
      ],
    ),
    GoRoute(
      path: AppRoutes.articles,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const AllArticlesScreen(),
    ),
    GoRoute(
      path: AppRoutes.articlesByCategoryPattern,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) {
        return ArticlesScreen(category: state.pathParameters['category'] ?? '');
      },
    ),
    GoRoute(
      path: AppRoutes.articlePattern,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) {
        return ArticleDetailsScreen(
          articleId: state.pathParameters['id'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.calculatorConcrete,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const CalculatorScreen(type: 'concrete'),
    ),
    GoRoute(
      path: AppRoutes.calculatorSteel,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const CalculatorScreen(type: 'steel'),
    ),
    GoRoute(
      path: AppRoutes.calculatorBrick,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const CalculatorScreen(type: 'brick'),
    ),
    GoRoute(
      path: AppRoutes.calculatorChecklist,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const ChecklistScreen(),
    ),
    GoRoute(
      path: AppRoutes.calculatorTile,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const TileCalculatorScreen(),
    ),
  ],
);
