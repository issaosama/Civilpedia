/// Canonical route identities for the current Civilpedia surface.
///
/// F0.1 scope: this contract is **behavior-preserving**. Every path constant
/// below is byte-for-byte identical to the production route used today. No
/// migration, no redirects, no hierarchy change, and no change to Bottom
/// Navigation.
///
/// Future target routes (`/knowledge`) are intentionally **not** declared here.
/// They are introduced only when their own implementation phase begins. This
/// contract models current canonical identities first; see M8 §27 (resolved).
/// `/projects` was declared in W6.1 as the canonical Projects V1 route and
/// became the visible Projects shell branch in W6.3. `/directory` and
/// `/directory/search` were declared in W6.2 as the canonical Directory routes
/// and became the visible Directory shell branch (with a nested search child)
/// in W6.3.
///
/// Distinction: a **route identity/name** (e.g. `home`) is different from a
/// **route path** (e.g. `/home`). This contract exposes canonical path
/// constants (the form GoRouter matches and callers navigate to) plus small
/// helpers for the few parameterized routes.
///
/// Non-goals: no localization dependence, no display strings as identity, no
/// dependency on feature UI widgets, no Content Studio coupling, no
/// over-engineered navigation framework.
library;

/// Canonical route contract. Instances are not creatable; all members are
/// static consts / static helpers.
abstract final class AppRoutes {
  AppRoutes._();

  // --- Bootstrap / auth ---
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String profileSetup = '/profile-setup';
  static const String auth = '/auth';

  // --- Knowledge / encyclopedia ---
  static const String categories = '/categories';
  static const String topicListPattern = '/encyclopedia/topics/:categoryId';
  static const String topicDetailPattern = '/encyclopedia/topic/:topicId';

  // --- Articles ---
  static const String articles = '/articles';
  static const String articlesByCategoryPattern = '/articles/:category';
  static const String articlePattern = '/article/:id';

  // --- Projects (W6.1 → W6.3) ---
  /// Canonical Projects V1 list route.
  ///
  /// W6.1 established this as the permanent GoRouter route for the canonical
  /// [ProjectListScreen] (navigation-ready, no visible launcher). W6.3 makes it
  /// the `/projects` StatefulShellBranch root: it IS a Bottom Navigation
  /// destination at kShellDestinations index 3. The legacy
  /// `Tools → Checklist → My Projects` entry remains valid too.
  static const String projects = '/projects';

  // --- Directory (W6.2 → W6.3) ---
  /// Canonical Directory [DirectoryLandingScreen] route.
  ///
  /// W6.2 established the canonical `/directory` root flow (navigation-ready,
  /// no visible launcher). W6.3 makes it the `/directory` StatefulShellBranch
  /// root: it IS a Bottom Navigation destination at kShellDestinations index 4.
  static const String directory = '/directory';

  /// Relative search segment nested under the `/directory` branch. Canonical
  /// segment authority so the router never repeats a raw literal (`/directory/search`
  /// is composed from [directory] + [directorySearchSegment]).
  static const String directorySearchSegment = 'search';

  /// Canonical Directory search route.
  ///
  /// Renders the real [DirectorySearchScreen]. Reached from `/directory` with
  /// the selected [BusinessType] carried via `state.extra`; direct navigation
  /// with no category opens browse mode (initialCategory null). Since W6.3 this
  /// is a branch-nested child of the `/directory` StatefulShellBranch (shell
  /// chrome stays visible); it is never a `kShellDestinations` entry itself.
  static const String directorySearch = '$directory/$directorySearchSegment';

  // --- Shell destinations (values mirror kShellDestinations in app_shell) ---
  // W6.3: the visible shell is /home · /encyclopedia · /tools · /projects ·
  // /directory. /saved and /profile left the visible bar but remain directly
  // routable root compatibility routes (never deleted).
  static const String home = '/home';
  static const String encyclopedia = '/encyclopedia';
  static const String tools = '/tools';
  static const String saved = '/saved';
  static const String profile = '/profile';

  // --- Profile (W3.3 → W6.3) ---
  /// Relative Profile-edit segment. Since W6.3 `/profile` is a root
  /// compatibility route and this segment is nested under it; `/user/profile/edit`
  /// is the canonical User Area variant. Canonical authority for the segment so
  /// the router never repeats a raw literal (`/profile/edit` is composed from
  /// [profile] + [profileEditSegment]).
  static const String profileEditSegment = 'edit';

  /// Routed Profile-edit destination for the legacy `/profile` compatibility
  /// route. W6.3 moved `/profile` out of the Bottom Navigation shell into a
  /// root route; this edit destination renders above the root navigator (no
  /// shell chrome), preserving direct `/profile/edit` navigation. Never a
  /// `kShellDestinations` entry.
  static const String profileEdit = '$profile/$profileEditSegment';

  // --- User Area (W3.4) ---
  /// Root of the full-screen User Area hub.
  ///
  /// W3.4 built the User Area target surface (hub + nested `/user/*` routes);
  /// W6.3 wires the visible Avatar→`/user` navigation entry (Home header).
  /// This is a top-level root route — NOT a Bottom Navigation slot, NOT a
  /// StatefulShell branch, never a modal/bottom-sheet (M8 §11). It must never
  /// enter `kShellDestinations`.
  static const String user = '/user';

  /// Relative Profile segment nested under `/user` (canonical segment
  /// authority — children of `/user` register with this, never the full path).
  static const String userProfileSegment = 'profile';

  /// Relative Saved segment nested under `/user`.
  static const String userSavedSegment = 'saved';

  /// Relative Downloads segment nested under `/user`.
  static const String userDownloadsSegment = 'downloads';

  /// Full navigable paths (for dispatch via push/go). Nested routers register
  /// the relative segment constants above; these composed paths are the
  /// canonical navigation targets.
  static const String userProfile = '$user/$userProfileSegment';
  static const String userProfileEdit = '$userProfile/$profileEditSegment';
  static const String userSaved = '$user/$userSavedSegment';
  static const String userDownloads = '$user/$userDownloadsSegment';

  // --- Global Search (W2.3) ---
  // Root-level, full-screen route ABOVE the StatefulShellRoute. It is NOT a
  // bottom-navigation shell destination and must never enter kShellDestinations.
  // The canonical route takes no query parameters: the query is typed only
  // inside Global Search.
  static const String search = '/search';

  // --- Tools / calculators ---
  // NOTE: the current `ArticleRepository`/`ToolModel` registry stores these
  // tool identities WITHOUT the leading slash (e.g. `calculator/concrete`) and
  // callers prefix `"/"`. That representation is left unchanged in F0.1; the
  // canonical paths here are the GoRouter/navigation form. The registry
  // mismatch is resolved in F0.5 (ToolKey).
  static const String calculatorConcrete = '/calculator/concrete';
  static const String calculatorSteel = '/calculator/steel';
  static const String calculatorBrick = '/calculator/brick';
  static const String calculatorChecklist = '/calculator/checklist';
  static const String calculatorTile = '/calculator/tile';

  /// Navigable path for a topic list by [categoryId].
  ///
  /// No URL encoding is applied: current callers interpolate the id verbatim,
  /// and F0.1 must not change existing URL behavior. If encoding is required
  /// later, add it in the phase that changes the behavior.
  static String topicListFor(String categoryId) =>
      '/encyclopedia/topics/$categoryId';

  /// Navigable path for a topic detail by [topicId]. See [topicListFor].
  static String topicDetailFor(String topicId) =>
      '/encyclopedia/topic/$topicId';

  /// Navigable path for an article by [id]. See [topicListFor].
  static String articleFor(String id) => '/article/$id';

  /// Navigable path for the (currently latent) articles-by-category route.
  /// See [topicListFor].
  static String articlesFor(String category) => '/articles/$category';
}
