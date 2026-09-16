import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app_routes.dart';
import '../core/di/app_dependencies.dart';
import '../core/services/connectivity_provider.dart';
import '../core/services/language_provider.dart';
import '../core/widgets/civil_app_bar.dart';
import '../localization/ar.dart';
import '../localization/en.dart';
import '../features/auth/domain/entities/auth_error.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/widgets/ownership_conflict_view.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/encyclopedia/presentation/screens/categories_screen.dart';
import '../features/encyclopedia/presentation/screens/encyclopedia_screen.dart';
import '../features/encyclopedia/presentation/screens/topic_list_screen.dart';
import '../features/encyclopedia/presentation/screens/topic_detail_screen.dart';
import '../core/navigation/app_shell.dart';
import '../features/auth/domain/auth_return_destination.dart';
import '../features/auth/presentation/auth_refresh_listenable.dart';
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
import '../features/profile/presentation/screens/authenticated_profile_edit_screen.dart';
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

/// V1-R08 — route prefixes that require an authenticated session.
///
/// Covers (2) protected business/cloud families: business applications
/// (list/new/claim/detail all share the `/business/applications` prefix),
/// business profile management (`/business/manage`), staff operations
/// (`/staff/applications`), and the User area profile (`/user/profile`).
/// The core public families (encyclopedia/articles/tools/projects/directory/
/// apps) stay fully usable as a guest.
const List<String> _authRequiredPrefixes = [
  AppRoutes.businessApplications,
  AppRoutes.businessManage,
  AppRoutes.staffApplications,
  AppRoutes.userProfile,
];

bool _requiresAuth(String path) {
  return _authRequiredPrefixes.any((prefix) => path.startsWith(prefix));
}

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
///
/// V1-R08 (Part 2) — a SIGNED-IN user is routed to the authenticated
/// [AuthenticatedProfileEditScreen], which reads the canonical cloud profile
/// itself. Any `state.extra` you just sent is intentionally ignored: the local
/// surrogate is never authoritative for an authenticated session.
///
/// V1-R08 correction (finding 1) — dispatch on the canonical [AuthStatus], not
/// on `isLoggedIn`: while a session restore is unresolved the legacy guest
/// editor must never render (no transient local/private profile exposure), and
/// an active ownership conflict must stay fail-closed (neither editor).
Widget _buildProfileEdit(BuildContext context, GoRouterState state) {
  return _ProfileEditDispatch(state: state);
}

/// V1-R08 correction (findings 1-3, final) — self-healing dispatcher for the
/// profile-edit routes. It WATCHES the canonical [AuthStatus] and ALWAYS renders
/// the correct surface for the current settled state, so no stale seam can
/// remain mounted after a transition — a GoRouter refresh alone does not
/// re-invoke the route builder for an unchanged match.
///
/// Covers every terminal transition:
/// * resolving → authenticated  → [AuthenticatedProfileEditScreen]
/// * resolving → guest          → the legacy W3.4 local-edit contract
/// * resolving → conflict       → the fail-closed [_ProfileEditRouteBlockedScreen]
/// * conflict Retry → guest     → the legacy guest contract (never a blank shell)
class _ProfileEditDispatch extends StatelessWidget {
  const _ProfileEditDispatch({required this.state});

  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final status = auth.status;

    if (status == AuthStatus.authenticated) {
      return const AuthenticatedProfileEditScreen();
    }

    // Fail closed on ANY conflict-bound state while no session is present:
    // stuck (blocked resolution), restore-in-flight (the blocking error is
    // retained) and neutralized (guest + conflict error).
    final conflictBlocked =
        auth.error == AuthError.ownershipConflict && !auth.isLoggedIn;
    if (conflictBlocked) {
      return const _ProfileEditRouteBlockedScreen();
    }

    if (auth.isCleanupBlocked) return const AuthScreen();

    // Any non-guest, non-blocked unsettled state (resolving / authenticating /
    // signOutPending / error) renders the safe resolution surface, never the
    // legacy local editor.
    if (status != AuthStatus.guest) {
      return const _ProfileEditRouteResolvingScreen();
    }

    // Settled guest — the legacy W3.4 local editor may continue.
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
}

/// V1-R08 correction (finding 1/3) — safe state for `/profile/edit` while a
/// session restore is still unresolved. No editor, no local/private flash.
/// Presentational only: [_ProfileEditDispatch] is authoritative about when it
/// can be replaced.
class _ProfileEditRouteResolvingScreen extends StatelessWidget {
  const _ProfileEditRouteResolvingScreen();

  @override
  Widget build(BuildContext context) {
    final tr = (String ar, String en) =>
        context.watch<LanguageProvider>().isArabic ? ar : en;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(Ar.profileEditCloudTitle, En.profileEditCloudTitle)),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              Text(
                tr(Ar.profileCloudLoading, En.profileCloudLoading),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// V1-R08 correction (finding 1/3) — fail-closed state for `/profile/edit`
/// while a second-account ownership conflict is active. Offers only the
/// accepted recovery actions (retry resolution / return to sign-in).
/// Presentational only: [_ProfileEditDispatch] is authoritative and replaces
/// this screen the moment the conflict settles (Retry → clean guest must never
/// leave an empty blocked shell behind).
class _ProfileEditRouteBlockedScreen extends StatelessWidget {
  const _ProfileEditRouteBlockedScreen();

  @override
  Widget build(BuildContext context) {
    final tr = (String ar, String en) =>
        context.watch<LanguageProvider>().isArabic ? ar : en;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(Ar.profileEditCloudTitle, En.profileEditCloudTitle)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: OwnershipConflictView(
              onCleared: () => context.go(AppRoutes.auth),
            ),
          ),
        ),
      ),
    );
  }
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
    connectivityProvider: context.read<ConnectivityProvider>(),
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
    connectivityProvider: context.read<ConnectivityProvider>(),
    seedEntity: (seed != null && seed.id == id) ? seed : null,
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigator,
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  errorBuilder: (context, state) => const NotFoundScreen(),
  // V1-R08 (finding 11) — re-evaluate redirects immediately whenever the
  // session/identity transitions (live session loss, replacement, sign-in).
  refreshListenable: AuthRefreshListenable.instance,
  // V1-R08 — protected-route gate. Signed-out/mid-restore navigations to a
  // protected family are redirected to the session screen with the intended
  // destination preserved as `?return=`, so sign-in can resume it — but only
  // when that destination passes the [AuthReturnDestination] allowlist
  // (finding 12/21). The auth route itself and all public families pass
  // through untouched.
  redirect: (context, state) {
    final path = state.uri.path;
    if (path == AppRoutes.auth || !_requiresAuth(path)) return null;
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) return null;
    final rawReturn = state.uri.toString();
    final allowed = AuthReturnDestination.resolve(rawReturn);
    final returnQuery = allowed == null
        ? ''
        : '?return=${Uri.encodeQueryComponent(allowed)}';
    return '${AppRoutes.auth}$returnQuery';
  },
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
