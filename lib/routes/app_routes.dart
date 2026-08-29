/// Canonical route identities for the current Civilpedia surface.
///
/// F0.1 scope: this contract is **behavior-preserving**. Every path constant
/// below is byte-for-byte identical to the production route used today. No
/// migration, no redirects, no hierarchy change, and no change to Bottom
/// Navigation.
///
/// Future target routes (`/knowledge`, `/projects`, `/directory`, `/user`,
/// `/search`, ...) are intentionally **not** declared here. They are
/// introduced only when their own implementation phase begins. This contract
/// models current canonical identities first; see M8 §27 (resolved).
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

  // --- Shell destinations (values mirror kShellDestinations in app_shell) ---
  static const String home = '/home';
  static const String encyclopedia = '/encyclopedia';
  static const String tools = '/tools';
  static const String saved = '/saved';
  static const String profile = '/profile';

  // --- Global Search (W2.3) ---
  // Root-level, full-screen route ABOVE the StatefulShellRoute. It is NOT a
  // bottom-navigation shell destination and must never enter kShellDestinations.
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
