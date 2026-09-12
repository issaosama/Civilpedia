import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app_routes.dart';
import '../core/di/app_dependencies.dart';
import '../core/widgets/civil_app_bar.dart';
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
import '../features/directory/domain/canonical_directory_entity.dart';
import '../features/directory/domain/cloud_directory_repository.dart';
import '../features/directory/presentation/directory_provider_detail_screen.dart';
import '../features/business/presentation/screens/my_applications_screen.dart';
import '../features/business/presentation/screens/application_detail_screen.dart';
import '../features/business/presentation/screens/application_new_form_screen.dart';
import '../features/business/presentation/screens/application_claim_form_screen.dart';
import '../features/business/presentation/screens/managed_businesses_screen.dart';
import '../features/business/presentation/screens/business_profile_edit_screen.dart';
import '../features/business/presentation/screens/staff_application_queue_screen.dart';
import '../features/business/presentation/screens/staff_application_review_screen.dart';
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
/// `/directory/search` deep links land inside the shell. V1-R05 adds the
/// canonical entity-detail route `/directory/entity/:id`.
final Map<String, List<RouteBase>> _shellBranchNestedRoutes = {
  AppRoutes.directory: [
    GoRoute(path: AppRoutes.directorySearchSegment, builder: _buildDirectorySearch),
    GoRoute(path: '${AppRoutes.directoryEntitySegment}/:id', builder: _buildDirectoryEntityDetail),
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
/// V1-R05 adapted: category selection carries a canonical entity-type string
/// instead of the legacy [BusinessType]. Bottom clearance is handled by the
/// screen itself via the AppShell ancestor (ShellContentInsets).
Widget _buildDirectoryLanding(BuildContext context, GoRouterState state) {
  return DirectoryLandingScreen(
    onCategorySelected: (entityType) => context.push(
      AppRoutes.directorySearch,
      extra: entityType,
    ),
  );
}

/// W6.2 — canonical Directory Search builder (W6.3 branch-nested child).
///
/// V1-R05 adapted: resolves a canonical entity-type string from `state.extra`
/// when supplied; direct navigation with no extra opens browse mode.
Widget _buildDirectorySearch(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  return DirectorySearchScreen(
    initialEntityType: extra is String ? extra : null,
  );
}

/// V1-R05 — canonical Directory entity-detail builder.
///
/// The destination ALWAYS resolves through the canonical
/// [CloudDirectoryRepository]/cache keyed by `directory_entities.id`
/// ([DirectoryProviderDetailResolver]). A whole entity carried via
/// `state.extra` is used ONLY as a non-authoritative first-frame presentation
/// hint (fast paint); the route never treats it as the authoritative detail
/// state. Unknown/unresolvable ids render the unavailable state.
Widget _buildDirectoryEntityDetail(BuildContext context, GoRouterState state) {
  final id = state.pathParameters['id'] ?? '';
  final extra = state.extra;
  final seed = extra is CanonicalDirectoryEntity ? extra : null;
  return DirectoryProviderDetailResolver(
    entityId: id,
    repository: AppDependencies.directoryRepo,
    seedEntity: (seed != null && seed.id == id) ? seed : null,
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
    // V1-R04 — Business Applications (root routes above the shell; not bottom-
    // nav destinations, not staff navigation).
    GoRoute(
      path: AppRoutes.businessApplications,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const MyApplicationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessApplicationsNew,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const ApplicationNewFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessApplicationsClaim,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const ApplicationClaimFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessApplicationDetailPattern,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => ApplicationDetailScreen(
        applicationId: state.pathParameters['applicationId'] ?? '',
      ),
    ),
    // V1-R06 — Business Profile Management (root routes above the shell).
    GoRoute(
      path: AppRoutes.businessManage,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const ManagedBusinessesScreen(),
    ),
    GoRoute(
      path: AppRoutes.businessManageDetailPattern,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => BusinessProfileEditScreen(
        entityId: state.pathParameters['entityId'] ?? '',
      ),
    ),
    // V1-R07 — Staff Operations (root routes above the shell).
    GoRoute(
      path: AppRoutes.staffApplications,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => const StaffApplicationQueueScreen(),
    ),
    GoRoute(
      path: AppRoutes.staffApplicationDetailPattern,
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => StaffApplicationReviewScreen(
        applicationId: state.pathParameters['applicationId'] ?? '',
      ),
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
