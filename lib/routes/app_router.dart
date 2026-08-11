import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/encyclopedia/presentation/screens/categories_screen.dart';
import '../features/encyclopedia/presentation/screens/encyclopedia_screen.dart';
import '../features/encyclopedia/presentation/screens/topic_list_screen.dart';
import '../features/encyclopedia/presentation/screens/topic_detail_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/home_main_screen.dart';
import '../features/tools/presentation/screens/tools_screen.dart';
import '../features/tools/presentation/screens/calculators/calculator_screen.dart';
import '../features/tools/presentation/screens/checklist/checklist_screen.dart';
import '../features/tools/presentation/screens/calculators/tile_calculator_screen.dart';
import '../features/articles/presentation/screens/articles_screen.dart';
import '../features/articles/presentation/screens/article_details_screen.dart';
import '../features/saved/presentation/saved_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/screens/profile_setup_screen.dart';
import 'not_found_screen.dart';

final GlobalKey<NavigatorState> _rootNavigator = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigator,
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/categories',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/encyclopedia/topics/:categoryId',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => TopicListScreen(
        categoryId: state.pathParameters['categoryId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/encyclopedia',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => EncyclopediaScreen(
        initialQuery: state.uri.queryParameters['q'],
      ),
    ),
    GoRoute(
      path: '/encyclopedia/topic/:topicId',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => TopicDetailScreen(
        topicId: state.pathParameters['topicId'] ?? '',
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeMainScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tools',
              builder: (context, state) => const ToolsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/saved',
              builder: (context, state) => const SavedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/articles/:category',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) {
        return ArticlesScreen(
          category: state.pathParameters['category'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/article/:id',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) {
        return ArticleDetailsScreen(
          articleId: state.pathParameters['id'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/calculator/concrete',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const CalculatorScreen(type: 'concrete'),
    ),
    GoRoute(
      path: '/calculator/steel',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const CalculatorScreen(type: 'steel'),
    ),
    GoRoute(
      path: '/calculator/brick',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const CalculatorScreen(type: 'brick'),
    ),
    GoRoute(
      path: '/calculator/checklist',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const ChecklistScreen(),
    ),
    GoRoute(
      path: '/calculator/tile',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const TileCalculatorScreen(),
    ),
  ],
);
