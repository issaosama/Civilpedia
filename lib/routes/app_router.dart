import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
import '../features/profile/presentation/screens/profile_edit_screen.dart';
import '../features/projects/presentation/project_list_screen.dart';
import '../features/profile/domain/user_profile.dart';
import '../features/profile/presentation/providers/user_profile_provider.dart';
import '../features/search/presentation/screens/global_search_screen.dart';
import '../features/user_area/presentation/user_area_screen.dart';
import '../features/directory/presentation/directory_landing_screen.dart';
import '../features/directory/presentation/directory_search_screen.dart';
import '../features/profile/domain/service_business_profile.dart';
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
  AppRoutes.projects: (_, __) => const ProjectListScreen(),
  AppRoutes.directory: _buildDirectoryLanding,
};

/// Nested routes for shell branches. W6.3 hosts the Directory search engine as
/// a child of the `/directory` branch so a Landing → Search push renders on the
/// branch navigator (bottom navigation stays visible) and direct
/// `/directory/search` deep links land inside the shell.
final Map<String, List<RouteBase>> _shellBranchNestedRoutes = {
  AppRoutes.directory: [
    GoRoute(path: AppRoutes.directorySearchSegment, builder: _buildDirectorySearch),
  ],
};

/// W3.3 — Profile-edit destination. The canonical push passes the current
/// [LocalUserProfile] via `state.extra`. For direct dispatch without a valid
/// extra, falls back to the authoritative [UserProfileProvider]; if no profile
/// exists, the router error contract (NotFoundScreen) applies instead of an
/// uncontrolled `state.extra as ...` crash.
Widget _buildProfileEdit(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  if (extra is LocalUserProfile) {
    return ProfileEditScreen(profile: extra);
  }
  final profile = context.read<UserProfileProvider>().profile;
  if (profile != null) {
    return ProfileEditScreen(profile: profile);
  }
  return const NotFoundScreen();
}

/// W6.2 — canonical Directory Landing builder (W6.3 shell branch root).
///
/// Hosts the real [DirectoryLandingScreen]. Wire its existing
/// [DirectoryLandingScreen.onCategorySelected] seam to a GoRouter push of
/// [AppRoutes.directorySearch], carrying the selected [BusinessType] via
/// `state.extra`. The smallest transport is used — no query-string
/// serialization, no navigation DTO. Bottom clearance is handled by the screen
/// itself: it detects the AppShell ancestor (via [ShellContentInsets]) and
/// applies the closed UI-SAFE-1 contract, so no numeric obstruction is passed
/// through the standalone padding seam.
Widget _buildDirectoryLanding(BuildContext context, GoRouterState state) {
  return DirectoryLandingScreen(
    onCategorySelected: (type) => context.push(
      AppRoutes.directorySearch,
      extra: type,
    ),
  );
}

/// W6.2 — canonical Directory Search builder (W6.3 branch-nested child).
///
/// Hosts the real [DirectorySearchScreen]. Resolves the selected [BusinessType]
/// from `state.extra` when supplied; direct navigation with no extra opens
/// browse mode ([DirectorySearchScreen.initialCategory] null). Bottom clearance
/// is handled by the screen itself: it detects the AppShell ancestor and
/// applies the closed UI-SAFE-1 contract.
Widget _buildDirectorySearch(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  return DirectorySearchScreen(
    initialCategory: extra is BusinessType ? extra : null,
  );
}

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
      path: AppRoutes.saved,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const SavedScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const ProfileScreen(),
      routes: [
        GoRoute(
          path: AppRoutes.profileEditSegment,
          parentNavigatorKey: _rootNavigator,
          builder: _buildProfileEdit,
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.user,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const UserAreaScreen(),
      routes: [
        GoRoute(
          path: AppRoutes.userProfileSegment,
          parentNavigatorKey: _rootNavigator,
          builder: (context, state) =>
              ProfileScreen(profileEditRoute: AppRoutes.userProfileEdit),
          routes: [
            GoRoute(
              path: AppRoutes.profileEditSegment,
              parentNavigatorKey: _rootNavigator,
              builder: _buildProfileEdit,
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.userSavedSegment,
          parentNavigatorKey: _rootNavigator,
          builder: (context, state) => const SavedScreen(initialTabIndex: 0),
        ),
        GoRoute(
          // Downloads tab index within SavedScreen (0 = Favorites, 1 = Downloads).
          path: AppRoutes.userDownloadsSegment,
          parentNavigatorKey: _rootNavigator,
          builder: (context, state) => const SavedScreen(initialTabIndex: 1),
        ),
      ],
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
                routes:
                    _shellBranchNestedRoutes[destination.route] ??
                    const <RouteBase>[],
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
