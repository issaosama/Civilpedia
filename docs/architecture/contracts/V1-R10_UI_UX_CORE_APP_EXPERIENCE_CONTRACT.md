# CIVILPEDIA V1-R10 — UI/UX & CORE APP EXPERIENCE CONTRACT

PHASE: V1-R10
TITLE: UI/UX & Core App Experience
CONTRACT: V1-R10-CONTRACT-v1
STATUS: FROZEN — ARCHITECT ACCEPTED
CURRENT AUTHORIZED SLICE: V1-R10.4-A — HOME PRODUCTION VISUAL PASS
IMPLEMENTATION_AUTHORIZED: YES — V1-R10.4-A ONLY
MODE: CONTRACT FROZEN — R10.4-A IMPLEMENTATION
R10.1: CLOSED / ACCEPTED
R10.2: CLOSED / ACCEPTED — THEME + SHARED UI FOUNDATION
R10.3: CLOSED / ACCEPTED — APP SHELL, NAVIGATION & GLOBAL STATES
R10.4-A: CURRENT / AUTHORIZED
R10.4-B AND R10.5 THROUGH R10.7: LOCKED

---

## 1. Authority and Purpose

This contract defines the scope, design-system rules, and acceptance criteria
for V1-R10, the final V1 UI/UX / core app experience phase.

V1-R10 is NOT an MVP/prototype polish pass. It is production-grade work that
harmonizes the existing application surfaces before later major feature phases
(V1-R11 through V1-R13).

V1-R10 builds on the closed V1-R09 program and the closed V1-R09Q quality gate.
It does NOT change accepted backend, auth, security, connectivity, or data
authority contracts.

Core principle for R10:

> SCOPE MAY BE LIMITED. QUALITY MAY NOT BE LIMITED.

---

## 2. Baseline

Expected HEAD at contract freeze time:

    HEAD == origin/main == f67ecdc3d443dcc6d9667162afd815f77cf84eac

Pre-existing dirty baseline (MUST NOT be touched, reverted, formatted, or staged
by R10 implementation):

    M test/a5_6_profile_bootstrap_test.dart
    M test/v1_r08_cloud_profile_foundation_test.dart
    M test/v1_r08_profile_edit_screen_widget_test.dart
    ?? OpenCode_Usage_Report.txt

Repository UI/UX baseline established by discovery:

- Feature-first folder layout under `lib/features/`;
- `GoRouter` + `StatefulShellRoute.indexedStack` + custom `AppShell`;
- 5 visible bottom-nav destinations: Home, Encyclopedia, Tools, Projects,
  Directory; Saved and Profile remain routable but not in the bar;
- `MaterialApp.router` with light/dark `ThemeData` built from
  `lib/core/theme/app_theme.dart`;
- Arabic-first RTL, English LTR supported via `LanguageProvider` + locale
  resolution;
- Core tokens exist in `AppColors`, `AppSpacing`, `DesignTokens`,
  `AppTypography`;
- Shared primitives partially exist: `CivilAppBar`, `CivilSurfaceCard`,
  `SectionHeader`, `SearchBarWidget`, `RemoteDataNotice`,
  `TransportStatusBanner`, `AsyncValueWidget`, `ErrorStateWidget`,
  `EmptyStateWidget`;
- No global responsive breakpoint system and limited tablet/desktop adaptation;
- No shared button, chip, list-item, dialog, or bottom-sheet primitive;
- Several screens bypass the shared primitives and build local cards/app bars.

---

## 3. R10 Objectives

1. Consolidate and complete the Civilpedia design system.
2. Make shared UI primitives the default choice for new and refactored screens.
3. Harmonize typography, spacing, radius, elevation, and color usage across all
   core surfaces.
4. Achieve consistent loading, empty, error, offline, and retry presentation.
5. Ensure Arabic RTL and English LTR are both production-ready.
6. Ensure light and dark themes are coherent across all touched surfaces.
7. Establish minimal responsive behavior for phones and, where already supported,
   larger form factors.
8. Meet basic accessibility expectations for touch targets, semantics, text
   scaling, and contrast.
9. Preserve all accepted backend/auth/security/connectivity behavior.
10. Deliver a final visual/UX regression gate before R11.

---

## 4. In-Scope Surfaces

The following existing surfaces are explicitly in scope for harmonization:

- App shell, bottom navigation, and route-level transitions;
- App bars, section headers, search bar, and top-level chrome;
- Cards, list items, chips, buttons, inputs, dialogs, bottom sheets, and
  snackbars used in core journeys;
- Home: header, quick access, quick tools, categories, engineering topics,
  latest articles, ad carousel layout/presentation only;
- Encyclopedia: categories, topic lists, topic detail, content blocks,
  encyclopedia-specific theming;
- Articles: article lists, article detail, offline fallback;
- Search: search field, result tiles, search state surfaces;
- Saved: favorites tabs, downloads tab, directory reference rows;
- Tools: tools grid, calculator screens (concrete/steel/brick/tile), checklist
  screens, project list screen;
- Profile / Auth / User Area: auth screen, profile screen, profile setup/edit,
  user area hub, ownership-conflict surface;
- Business / Staff: my applications, application forms, application detail,
  managed businesses, business profile edit, staff queue, staff review;
- Directory: landing, search, provider cards, provider detail, verification
  badges, sponsored card styling;
- Shared loading, shimmer, empty, error, offline, retry, and notice widgets.

R10 is allowed to refactor the above surfaces for consistency; it is NOT
required to add major new features to them.

Staff presentation is currently located under `lib/features/business/` and
remains presentation-only for R10. R10 does not modify staff permissions,
authorization, or server authority.

---

## 5. Out-of-Scope Surfaces

- New product features (marketplace, RFQ, bids, payments, subscriptions,
  commissions, full monetization, push notifications, CRM, collaboration);
- Backend / Supabase / migrations / RLS / RPC / grants / schema changes;
- Auth/session/security architecture changes;
- Connectivity / offline-first policy changes beyond presentation;
- New state-management framework or routing framework;
- Broad rewrite of screens that are already consistent and stable;
- Speculative desktop/large-screen architecture beyond what the current app
  already targets;
- New third-party UI packages unless explicitly Architect-approved;
- Golden/image tests that are brittle or expensive without clear value;
- V1-R14 production readiness, V1-R15 security audit, V1-R17 full E2E.

---

## 6. Design-System Rules

R10.1 is specification and approval only. It may inspect the current theme,
token sources, logo assets, and application UI, but it MUST NOT modify
production Flutter code. R10.2 is the first slice authorized to implement
accepted R10.1 visual decisions in production.

### 6.1 Tokens (source of truth)

| Token class | Source file |
|-------------|-------------|
| Colors | `lib/core/theme/app_colors.dart` |
| Spacing | `lib/core/theme/spacing.dart` (`AppSpacing`) |
| Radii | `lib/core/theme/design_tokens.dart` (`DesignTokens.radius*`) |
| Elevation / shadows | `lib/core/theme/design_tokens.dart` |
| Durations / curves | `lib/core/theme/design_tokens.dart` |
| Typography | `lib/core/theme/typography.dart` + `ThemeData.textTheme` |

Rules:

- New colors MAY be added to `AppColors` only if a genuine semantic gap exists.
- Hardcoded `Color(...)` literals outside `AppColors` are prohibited in touched
  code, except for platform/third-party brand colors (e.g., Google blue).
- Hardcoded `Colors.white` / `Colors.black` with opacity are prohibited in
  touched code; use theme `ColorScheme` or `AppColors` surface/overlay values.
- Spacing MUST use `AppSpacing` constants or derived multiples, not magic
  numbers.
- Radii MUST use `DesignTokens.radius*` values.
- Elevation MUST use `DesignTokens.elevation*` and `DesignTokens.softShadow` /
  `cardShadow` helpers, not ad-hoc `BoxShadow` lists.
- Durations for UI transitions MUST use `DesignTokens.durationFast` /
  `durationNormal`.

### 6.2 Shared primitives

The generic UI authority is `ThemeData` / `ColorScheme` / `TextTheme` and
Material component themes. Civilpedia-specific shared widgets exist only for:

- repeated composed layouts (e.g., a canonical content row or feature card);
- product semantics (e.g., `RemoteDataNotice`, `TransportStatusBanner`);
- state behavior (e.g., `AsyncValueWidget`);
- accessibility value (e.g., touch-target wrappers, semantics helpers).

R10 MUST NOT create thin wrappers around every Material widget.

R10 MAY introduce or complete a small number of composed primitives where the
existing Material variants do not capture repeated Civilpedia layout, such as:

- a composed list-row or content-row widget that matches the frozen card family;
- a composed status/empty/error surface that wraps `RemoteDataNotice` or
  `EmptyStateWidget` with product copy;
- a composed feature card that is reused across Home/Encyclopedia/Directory.

The exact primitive names are not frozen; the requirement is that R10 reduce
inline duplication without replacing Material.

### 6.3 Card/list consistency

- `CivilSurfaceCard` is the canonical card primitive.
- `CustomCard`, `GlassCard`, and ad-hoc `Card` + `InkWell` duplications SHOULD
  be consolidated where the resulting behavior remains equivalent.
- List rows SHOULD use a shared tile primitive or `CivilSurfaceCard` with a
  consistent internal layout, rather than one-off rows per screen.

### 6.4 App bar consistency

- `CivilAppBar` SHOULD become the default for all non-shell screens.
- Raw `AppBar` usage is allowed only where `CivilAppBar` cannot satisfy a
  feature-specific need, and the exception MUST be documented in the slice
  review.

### 6.5 Brand direction

Final V1 Civilpedia visual identity:

- **Signature brand color:** Civilpedia Amber / Orange (derived from the logo).
  Reference value approximately `#FE9E03` until R10.1 derives the exact
  production token from the highest-quality logo asset.
- **Supporting brand color:** Civilpedia Logo Blue (technical/informational
  authority).
- **Surface system:** warm neutral backgrounds and cards; most UI remains
  neutral so Amber retains impact.
- **Brand roles:**
  - Amber: selected navigation accents, primary high-value CTA, active chips,
    "new" badges, selected/highlighted states, limited signature accents.
  - Blue: technical/informational surfaces, secondary selected UI, links,
    engineering iconography, complementary brand presence.
  - Neutrals: backgrounds, cards, containers, large UI areas.
- Do NOT create an orange-dominated UI.
- Do NOT create a multi-color card system.

Civilpedia identity is also preserved as:

- Arabic-first / RTL product;
- engineering/professional tone;
- rounded cards and restrained shadows;
- clean, minimal, fast, readable;
- no flashy decorative effects.

### 6.5.1 R10.1 visual reference and approval

R10.1 acceptance requires an Architect/user-reviewable visual reference, not
token tables alone. The minimum reference set is:

- Home: final header/chrome, search, hero/banner, quick access, engineering
  tools preview, category/content cards, and bottom navigation;
- Tools launcher: tool cards/grid, with calculators opening on dedicated
  screens rather than inline;
- Dedicated calculator: title, short description, inputs, primary action,
  result, and relevant notes/warnings;
- Dark mode: at least one representative major surface.

The reference MUST demonstrate Logo Amber, supporting Logo Blue, warm neutral
surfaces, restrained brand usage, Arabic RTL, realistic typography hierarchy,
and a consistent card/button/search/navigation family. Explicit Architect and
user approval of this reference was received; R10.1 is CLOSED / ACCEPTED and
R10.2 may begin within its frozen boundary.

### 6.6 Accessibility color rule

R10.1 must validate contrast for every production brand token.

- Do not assume white text over Amber is accessible.
- For light/medium Amber primary buttons, prefer dark/navy/charcoal foreground
  when required for accessible contrast.
- Semantic colors (success, error, warning, information) remain independent of
  the brand Amber.
- The Civilpedia brand Amber must NOT be the sole representation of warning
  state.

### 6.7 Dark mode

Dark mode is first-class and must remain recognizably Civilpedia:

- dark neutral/navy-charcoal backgrounds;
- elevated dark surfaces;
- light readable typography;
- brighter accessible Amber accent;
- supporting Blue where appropriate;
- no pure-black-everywhere approach.

---

## 7. Typography Rules

- Use `Theme.of(context).textTheme` tokens (`display*`, `headline*`, `title*`,
  `body*`, `label*`).
- Do not introduce screen-local font sizes that duplicate existing tokens.
- Cairo is the canonical typeface for both Arabic and English.
- Titles and section headers use semibold/bold weights from the token scale.
- Body text uses regular weight; emphasized inline text uses medium/semibold
  within the same token size.
- Text color MUST come from `ColorScheme` or `AppColors`, never raw `Colors`.

---

## 8. Spacing / Radius / Elevation Rules

- Page horizontal padding: `AppSpacing.lg` (16) as the default; wider gutters on
  large screens via responsive logic where justified.
- Vertical section gaps: `AppSpacing.lg` (16) or `AppSpacing.xl` (20).
- Internal card padding: `AppSpacing.lg` (16) default; `AppSpacing.md` (12) for
  compact list tiles.
- Card radius: `DesignTokens.radiusMd` (18).
- Small component radius: `DesignTokens.radiusSm` (12).
- Pill/search radius: `DesignTokens.radiusSearch` (28).
- Card elevation: `DesignTokens.elevation2` (3) in light; flat + border in dark.
- Direction-aware padding and alignment MUST respect active locale.

---

## 9. Responsive Breakpoints and Layout Behavior

V1-R10 uses adaptive layout classes based on available content width:

- **COMPACT:** < 600 dp (phones);
- **MEDIUM:** 600–839 dp (large phones / small tablets);
- **EXPANDED:** >= 840 dp (tablets and larger).

These are adaptive layout classes, not a promise of a separate desktop product.
Expanded layouts should constrain readable content rather than stretching it
indefinitely.

Rules:

- Use `MediaQuery.sizeOf(context).width` or `LayoutBuilder` for responsive
  decisions; avoid hardcoded `crossAxisCount: 2` that cannot adapt.
- Grids (tools, categories, topics) SHOULD adapt columns at COMPACT / MEDIUM /
  EXPANDED boundaries.
- Side rail / navigation drawer for EXPANDED screens is OPTIONAL and requires
  Architect approval if it changes the shell architecture.
- Text scaling MUST remain readable; do not assume fixed text height.
- Minimum interactive tap target remains 48x48 dp regardless of screen size.

---

## 10. Arabic RTL Requirements

- Arabic is the default locale.
- Flutter `Directionality` MUST derive from the active locale; do not hardcode
  `TextDirection.rtl` except where mixed-script content (e.g., code, numbers,
  emails) requires explicit direction for correctness.
- All user-facing strings MUST exist in both `Ar` and `En` static classes.
- No new visible hardcoded Arabic or English strings are permitted.
- `SearchBarWidget` and similar shared inputs MUST default to the active-locale
  hint (no Arabic-default in English mode).
- Start/end alignment, padding, and row ordering MUST use direction-aware
  widgets (`EdgeInsetsDirectional`, `AlignmentDirectional`, etc.).

---

## 11. English / LTR Readiness Requirements

- English is a supported locale; all new or changed strings require an English
  counterpart.
- LTR layouts must remain coherent after RTL changes; test both directions for
  changed surfaces.
- Logo/brand marks and mixed-content blocks must not clip or overflow in LTR.
- R10 does NOT require translation of the entire engineering content corpus.

---

## 12. Dark / Light Theme Behavior

- Dark mode is first-class; both themes MUST remain coherent across all touched
  surfaces.
- The dark palette uses dark neutral/navy-charcoal backgrounds, elevated dark
  surfaces, light readable typography, brighter accessible Amber accent, and
  supporting Blue where appropriate.
- Use `Theme.of(context).colorScheme` or `AppColors` dark variants; no raw
  `Colors.white` / `Colors.black`.
- Images and icons MUST have appropriate contrast in both modes.
- The active theme follows `ThemeProvider`; manual overrides require Architect
  approval.

---

## 13. Loading, Empty, Error, Offline, and Retry Requirements

- Use `AsyncValueWidget`, `ErrorStateWidget`, `EmptyStateWidget`, and
  `RemoteDataNotice` as the canonical state surfaces.
- Loading: `CircularProgressIndicator` or existing shimmer (`ShimmerArticleCard`,
  `ShimmerCategoryCard`, `ShimmerSection`) where already used.
- Empty: `EmptyStateWidget` with localized message and feature-appropriate icon.
- Error: `RemoteDataNotice` (compact or noData) or `ErrorStateWidget`; never raw
  exceptions, SQLSTATE, stack traces, or backend messages.
- Retry MUST be actionable and localized; do not show retry when the domain
  forbids it.
- Offline: global `TransportStatusBanner` plus feature-level
  `RemoteDataCause.offline` notices where appropriate.
- Preserve known-good data visibility per accepted R09 semantics.

---

## 14. Navigation Consistency

- `GoRouter` + `AppShell` remains the navigation authority.
- Bottom navigation keeps exactly the 5 frozen destinations; Saved and Profile
  remain routable but not visible in the bar.
- All non-shell screens SHOULD use `CivilAppBar` with consistent back-button,
  title, and action behavior.
- Auth redirect behavior (`/business/*`, `/staff/*`, `/user/profile`) is
  preserved.
- Deep links and `NotFoundScreen` behavior are preserved.
- Route transitions follow the existing Cupertino builders.

### 14.1 Preserved animated startup and splash invariant

The accepted cold-launch experience is production-complete and MUST NOT be
redesigned or behaviorally rewritten by routine R10 work:

    Native launch background
    -> blue C assembly
    -> CIVILPEDIA
    -> BUILD • LEARN • CONNECT
    -> short brand hold
    -> yellow triangle edge shimmer
    -> endpoint glint
    -> real application destination

The approximate animation runtime is ~2890 ms. The accepted animation
structure and startup behavior are preserved.

The following startup/routing invariants are also preserved:

- no duplicate/static branded splash before the Flutter animation;
- no legacy fixed 2-second delay;
- startup/bootstrap executes in parallel with the animation;
- routing occurs only when `animationComplete AND startupReady`;
- auth restoration and profile bootstrap are part of startup readiness;
- profile bootstrap starts once;
- no premature or double navigation;
- active deep links/current routes are never overwritten by the splash gate;
- if the active route is no longer `/splash`, the gate only removes the
  overlay and does not force `appRouter.go(...)`;
- onboarding/profile precedence remains preserved;
- background/resume does not replay the full splash;
- the full animation is cold-launch only.

These are preserved accepted behaviors, not new R10 implementation work.

If R10.3 touches app startup, `AppShell`, router integration, auth redirect
surfaces, or splash-adjacent navigation, it MUST preserve every accepted
splash/startup invariant above. Focused regression evidence MUST include the
relevant existing splash/startup routing suites when those seams are touched,
including:

- `test/a5_8_splash_restart_route_test.dart`;
- `test/civilpedia_splash_animation_test.dart`;
- relevant startup/auth/router suites.

These splash tests need not be rerun mechanically for unrelated visual-only
changes.

R10.1 may freeze final Amber and Blue tokens but MUST NOT redesign the accepted
splash animation. Official logo yellow/blue treatment should be preserved.
Any proposed visual change to the splash requires explicit Architect approval
and no R10 visual-token work may change splash timing, startup readiness,
routing, lifecycle, or deep-link behavior.

---

## 15. Form / Input / Button Behavior

- Inputs rely on the themed `InputDecorationTheme` and Material `TextField` /
  `TextFormField` unless a composed primitive adds product-specific layout.
- Buttons rely on themed Material buttons (`ElevatedButton`, `FilledButton`,
  `OutlinedButton`, `TextButton`) unless a composed button adds product-specific
  layout or repeated state handling.
- Form validation errors are localized and presented close to the field.
- Primary actions are visually distinct; destructive actions use error color.
- Disabled states are clearly communicated.
- Haptic feedback on primary actions is preserved.

---

## 16. Dialog / Bottom Sheet / Snackbar Behavior

- Dialogs use the themed `DialogThemeData` shape and consistent padding.
- Bottom sheets and snackbars use Material surfaces shaped by the theme.
- Shared wrappers are allowed only when a repeated Civilpedia layout or action
  pattern exists across multiple features.
- Action button ordering follows the active locale (RTL vs LTR).
- No raw exceptions or backend messages in any of these surfaces.

---

## 17. Accessibility Basics

- Minimum touch target: 48x48 dp for all tappable elements.
- `Semantics` wrappers and `tooltip:` on icon-only buttons are required for new
  or refactored interactive elements.
- Text scaling: layouts must not break at the largest non-extreme font scale
  (up to ~1.3x).
- Contrast: text and icons must remain readable on both themes; R10.1 must
  validate contrast for all production brand tokens.
- Focus: interactive elements must be reachable and visually identifiable where
  the platform supports focus traversal.
- Accessibility improvements MUST NOT expose raw backend text via labels.

---

## 18. Animation Policy

- Animations are subtle and functional only.
- Use `DesignTokens.durationFast` / `durationNormal` and `DesignTokens.curveFast`.
- No decorative/hero/lottie animations that harm speed or usability.
- Entrance animations (fade/slide) are allowed for lists/cards if already used,
  but MUST remain deterministic and not block interaction.

---

## 19. Testing Expectations

- Focused widget tests for each changed surface.
- Navigation/state tests where behavior changes.
- RTL/LTR checks for changed shared primitives and major screens.
- Dark/light checks for changed shared primitives and major screens.
- Responsive width checks where grids/breakpoints change.
- Offline/error/retry checks where state surfaces change.
- Each slice uses focused tests for the changed behavior or surface by default.
- The permanent 19-suite R09Q quality gate runs at meaningful integrated
  checkpoints, particularly after shared or cross-feature infrastructure
  changes when blast radius justifies it.
- The 19-suite gate is mandatory at final R10 closure, and the Architect may
  explicitly require it for an individual slice.
- Broader integrated gate is justified only at the final R10 closure or when a
  slice touches cross-feature shared primitives that could regress multiple
  suites.
- Golden tests are OPTIONAL and surgical; primary verification remains widget /
  state / layout / RTL / theme / responsive tests. Do not create a broad golden
  suite.

---

## 20. R10 Boundaries with Later Phases

R10 normalizes presentation but does not take ownership of later functional
phases:

- **V1-R11 — Projects Production Pass:** R10 may visually normalize project
  screens; R11 remains responsible for project functional/domain completion.
- **V1-R12 — Tools / Calculators Final Engineering QA:** R10 may redesign
  calculator presentation and interaction consistency; R12 remains responsible
  for engineering calculation formulas/semantics. R10 must NOT change
  calculation logic except through the later engineering QA phase.
- **V1-R13 — Encyclopedia / Content Studio Finalization:** R10 may normalize
  surrounding chrome; R13 remains responsible for content coverage, exporter,
  and final content completion. `Editor -> Preview -> Flutter` parity is an
  already-established invariant throughout R10 and must be preserved.

## 21. Tools UX Contract

The Tools screen is a **launcher / discovery** surface.

- Engineering tools appear as cards/grid items.
- Tapping a tool navigates to a dedicated calculator/tool screen.
- Calculators are NOT expanded inline inside the Tools grid.
- Each calculator screen follows a common visual hierarchy:
  - Title
  - Short description
  - Inputs
  - Primary action
  - Result
  - Notes / warnings where relevant
- R10 must NOT change calculator engineering semantics.

## 22. Encyclopedia Parity

Preserve `Editor -> Preview -> Flutter` visual equivalence for encyclopedia
content rendering.

R10 may normalize surrounding chrome (app bars, cards, spacing) but must not
break content-block rendering parity.

## 23. UX Debt Classification

- **SearchBarWidget Arabic hint in English mode:** CORE / TRUST-AFFECTING —
  must be fixed.
- **Lack of shared button/chip/dialog abstractions:** PRODUCTION POLISH — not
  inherently trust-breaking; themed Material is the preferred authority.
- **Raw `Colors.grey` in state widgets:** CORE only if actual readability or
  state understanding is materially broken; otherwise production polish.

## 24. Implementation Slices

R10 is split into the following coherent slices. Slice boundaries are subject
to Architect approval; exact file lists will be refined in per-slice freeze
prompts.

### R10.1 — Visual Direction & Token Freeze

- Purpose: derive/finalize production brand tokens and visual language from the
  highest-quality Civilpedia logo asset.
- Scope: visual specification and approval only; no production Flutter files.
- Must specify: exact Amber token, Blue token(s), neutral palette, light palette,
  dark palette, semantic colors, typography hierarchy, spacing scale, radius
  scale, elevation/shadow policy, icon style principles, button hierarchy, card
  family, search field appearance, chips, input fields, bottom navigation
  appearance, loading/empty/error visual language.
- Acceptance: token palette validated for contrast; the mandatory visual
  reference is established and explicitly approved by the Architect. No
  production implementation is part of R10.1.
- Dependencies: none.
- Preferred implementer: Big Pickle.
- Preferred reviewer: GitHub Copilot Civilpedia Reviewer.

### R10.2 — Theme + Shared UI Foundation

- Purpose: implement frozen tokens through `ThemeData` / `ColorScheme` /
  component themes and add only composed shared widgets where Material alone is
  insufficient.
- Scope: `lib/core/theme/*`, `lib/core/widgets/*` for composed primitives.
- Allowed changes: theme/component theme updates; composed row/card/notice
  primitives that capture repeated Civilpedia layout; compatibility aliases for
  legacy constants where removal would cause unrelated churn.
- Acceptance: existing screens still build; new composed primitives have focused
  widget tests for variants, RTL, and dark/light.
- Dependencies: R10.1 CLOSED / ACCEPTED.
- Preferred implementer: Big Pickle.
- Preferred reviewer: GitHub Copilot Civilpedia Reviewer.

### R10.3 — App Shell, Navigation & Global States

- Purpose: unify chrome, navigation, and global state presentation.
- Scope: `lib/core/navigation/*`, `lib/routes/*`, app bars across non-shell
  screens, global offline banner, auth redirect surfaces.
- Allowed changes: migrate non-shell screens to `CivilAppBar`; polish bottom-nav
  active-state visuals; ensure safe-area / insets consistency; align auth/
  ownership-conflict surfaces with tokens.
- Acceptance: route tests and shell navigation tests still pass; W6.3 branch
  labels and double-back behavior preserved; RTL/LTR app bar actions correct;
  global state banners remain coherent in both themes.
- Dependencies: R10.2 CLOSED / ACCEPTED.
- Preferred implementer: Big Pickle.
- Preferred reviewer: GitHub Copilot Civilpedia Reviewer.

### R10.4 — Core Discovery: Home / Search / Saved

- Purpose: harmonize the primary discovery surfaces.
- Scope: `lib/features/home/*`, `lib/features/search/*`,
  `lib/features/saved/*`.
- Allowed changes: replace local cards/rows with composed theme-aware surfaces;
  fix `SearchBarWidget` locale-aware default hint; align section headers,
  empty/error states; adapt grids to COMPACT/MEDIUM/EXPANDED.
- Acceptance: focused widget tests for home/search/saved changed widgets;
  existing navigation/search tests still pass.
- Dependencies: R10.3 CLOSED / ACCEPTED.
- Preferred implementer: Big Pickle.
- Preferred reviewer: GitHub Copilot Civilpedia Reviewer.

### R10.5 — Cross-Feature Visual Adoption Pass

- Purpose: apply the frozen design language to later-phase-owned surfaces
  without taking their functional ownership.
- Scope: `lib/features/encyclopedia/*`, `lib/features/articles/*`,
  `lib/features/tools/*`, `lib/features/projects/*`,
  `lib/features/directory/*`, `lib/features/business/*` (including Staff
  presentation, presentation only),
  `lib/features/profile/*`, `lib/features/user_area/*`.
- Allowed changes: theme-aware cards/app bars/inputs/buttons/chips; removal of
  local shadow/border duplications; alignment of empty/error states; consistent
  status badges; no formula/security/data-ownership changes.
- Acceptance: each feature's focused/widget tests pass; no calculation or
  server-authority behavior changed.
- Dependencies: R10.4 CLOSED / ACCEPTED.
- Preferred implementer: Big Pickle.
- Preferred reviewer: GitHub Copilot Civilpedia Reviewer or Codex for any
  security-sensitive surface.

### R10.6 — Responsive / RTL-LTR / Accessibility Sweep

- Purpose: close responsive, directional, and accessibility gaps introduced or
  exposed by R10 work.
- Scope: R10-touched surfaces and shared primitives; touch-target, semantics,
  dark/light, text-scaling, and LTR verification for those surfaces.
- Allowed changes: responsive breakpoints in grids; direction-aware padding
  fixes; semantics additions; contrast fixes; small spacing fixes; no broad
  redesign.
- Acceptance: no new HIGH/MEDIUM findings; 19-suite gate green.
- Dependencies: R10.5 CLOSED / ACCEPTED.
- Preferred implementer: Big Pickle.
- Preferred reviewer: GitHub Copilot Civilpedia Reviewer.

### R10.7 — Integrated UX Quality Gate & Formal Closure

- Purpose: run final integrated verification and formally close R10.
- Scope: optional broader integrated widget gate, final diff review, final
  independent review, Architect final review.
- Allowed changes: none except documentation/closure records.
- Acceptance: all prior slices accepted; 19-suite gate green; broader gate green
  if authorized; no unresolved HIGH/MEDIUM findings.
- Dependencies: R10.6 CLOSED / ACCEPTED.
- Preferred implementer: Big Pickle.
- Preferred reviewer: GitHub Copilot Civilpedia Reviewer.

---

## 25. Agent Allocation

- Routine Flutter UI / localization / widget tests / docs: **Big Pickle**.
- Independent review and secondary implementation: **GitHub Copilot Civilpedia
  Reviewer**.
- Medium/large multi-file UI refactor where justified: **Kimi**.
- Backend/security/high-blast-radius defects only: **Codex** (NOT routine R10
  UI work).
- Escalate to ChatGPT Architect whenever a UI improvement would require
  changing accepted auth, security, data ownership, connectivity, or persistence
  contracts.

---

## 26. Anti-Overengineering

R10 MUST NOT introduce:

- a brand-new state-management architecture;
- a new routing framework;
- a giant custom design system unrelated to the existing tokens;
- an unnecessary animation framework;
- unnecessary abstraction layers;
- speculative desktop architecture;
- third-party UI libraries without strong justification;
- broad rewrites of already-good screens.

Prefer refinement and consolidation.

---

## 27. Architect Decisions Resolved

All previously listed Architect questions are resolved by this revision:

1. **Shared primitives vs Material:** Themed Material is the generic UI
   authority; Civilpedia-specific shared widgets are allowed only for repeated
   composed layouts, product semantics, state behavior, or accessibility value.
2. **Breakpoints:** COMPACT (< 600 dp), MEDIUM (600–839 dp), EXPANDED
   (>= 840 dp). Side-rail navigation for EXPANDED is optional and requires
   Architect approval.
3. **Golden tests:** Optional and surgical; primary verification remains widget /
   state / layout / RTL / theme / responsive tests.
4. **English LTR parity:** All R10-touched surfaces must support Arabic RTL and
   English LTR; R10 does not require translation of the entire engineering
   content corpus.
5. **Token migration:** Migrate-when-touched; compatibility aliases may remain
   temporarily when removal would cause broad unrelated churn.

No material contradictions remain unresolved.

---

## 28. Contract Status

STATUS: FROZEN — ARCHITECT ACCEPTED

CURRENT AUTHORIZED SLICE: V1-R10.4-A — HOME PRODUCTION VISUAL PASS

IMPLEMENTATION_AUTHORIZED: YES — V1-R10.4-A ONLY

R10.1: CLOSED / ACCEPTED

R10.2: CLOSED / ACCEPTED — THEME + SHARED UI FOUNDATION

R10.3: CLOSED / ACCEPTED — APP SHELL, NAVIGATION & GLOBAL STATES

R10.4-A: CURRENT / AUTHORIZED

R10.4-B, Search, Saved, broader R10.4 propagation, and R10.5 THROUGH R10.7:
LOCKED. Broader propagation may begin only after the R10.4-A Home baseline is
rendered on an emulator/device, visually inspected, and accepted by the
Architect/user.

### R10.2 closure evidence

- Frozen Amber/Blue/warm-neutral theme implemented.
- Light and dark Material themes implemented.
- Shared primitives aligned.
- `SearchBarWidget` locale defect fixed.
- Shared raw-error exposure corrected.
- Localized Error/Empty/Retry fallback established.
- Focused implementation evidence before correction: 95 PASS / 0 FAIL.
- Correction evidence: 141 PASS / 0 FAIL.
- Independent correction re-review: PASS.
- Findings after correction: HIGH none; MEDIUM none; LOW none.
- Permanent R09Q integrated quality gate: 19/19 mandatory suites PASS, exit
  code 0, with no gate drift.
- No unresolved R10.2 findings remain.

### R10.3 closure evidence

- Implementation: PASS.
- Focused verification: 5 suites, 86 PASS / 0 FAIL.
- Independent review: PASS.
- Findings: HIGH none; MEDIUM none; LOW none.
- Exactly five destinations preserved: Home, Encyclopedia, Tools, Projects,
  and Directory.
- Branch semantics, indexed-stack state retention, and double-back behavior
  preserved.
- Safe-area/inset behavior, responsive shell, RTL/LTR, and light/dark
  presentation verified.
- No router, startup/splash, or Home-composition semantic change.
- No permanent 19-suite gate was required for this narrowly scoped shell-only
  slice.

### R10.4-A authorization boundary

R10.4-A may modify Home presentation and directly required Home-local/shared
presentation pieces only. Authorized goals are:

- Home background and surface hierarchy;
- header, signature search, and hero/featured presentation;
- Quick Access and Engineering Tools preview/launcher presentation;
- categories, section headers, spacing/rhythm, card consistency, and typography;
- RTL/LTR, light/dark, responsive Home composition, and accessibility;
- root-cause correction of known Home fixed-height overflows.

R10.4-A uses the existing R10.2 theme tokens and the frozen Amber
`#FE9E03`, Logo Blue `#0155DA`, Deep Technical Blue `#063284`, and warm-neutral
foundation. It MUST NOT duplicate a hardcoded brand system.

Home remains a single-column phone experience with adaptive medium/expanded
layouts. Amber remains the signature rather than dominating the UI; Blue is
technical/supporting; most surfaces remain neutral. Engineering Tools remains
a preview/launcher and tool taps continue to dedicated tool screens.

R10.4-A MUST NOT change routing architecture, `AppShell` branch semantics,
bottom destination count, startup/splash, deep links, auth, profile bootstrap,
backend/Supabase, calculator formulas, project logic, Encyclopedia rendering
semantics, or R11/R12/R13-owned behavior.

If Home implementation unexpectedly requires semantic router/startup/auth
changes, STOP with:

`R10.4-A SEMANTIC SCOPE EXPANSION — ARCHITECT REVIEW REQUIRED`

### Home visual checkpoint

R10.4-A produces the first real production UI baseline and is not fully
accepted from tests alone. After implementation, the real app MUST run on an
emulator/device, Home MUST be visually inspected, a Light-mode screenshot MUST
be captured, and a Dark-mode screenshot SHOULD be captured where practical.
Architect/user visual approval and any required correction pass precede broader
R10.4 propagation.

Known Home fixed-height overflows are now authorized for root-cause correction;
brittle fixed heights should yield to content-flexible, text-scale-resilient
layout rather than clipping or accidental truncation.

The accepted execution checkpoint remains:

R10.2 foundation -> R10.3 shell -> R10.4-A Home Production Visual Pass ->
emulator/device visual inspection -> Architect/user approval -> broader
propagation.

---

## APPENDIX A — PRODUCTION TRUE-BLACK DARK-MODE GOVERNANCE AMENDMENT

Status: ARCHITECT APPROVED / BINDING

For production V1, this append-only amendment supersedes older contract wording
that describes the dark palette as navy-charcoal. The authoritative dark-mode
surface hierarchy is:

- main canvas: `#000000`;
- primary surfaces: `#121212`;
- secondary surfaces: `#1A1A1A`;
- elevated surfaces: `#262626`.

True-black is the canvas authority, not a mandate to make every surface pure
black. Layered near-black surfaces remain required. Borders remain layered: a
subtle normal border is used where contrast is not the sole cue, while the
stronger boundary used for essential controls must satisfy the frozen `3:1`
non-text contrast requirement against its adjacent control surface.

Civilpedia Amber and Blue remain the signature and technical accents.
Accessibility, focus, semantic-color, light/dark parity, RTL/LTR, and all
protected behavior requirements remain binding. This amendment changes no
routing, shell, auth, startup, backend, Directory business, or Encyclopedia
content authority.

---

## APPENDIX B — V1-R10.4-B IMPLEMENTATION CONTRACT FREEZE

Status: ARCHITECT APPROVED / FROZEN — V1-R10.4-B IMPLEMENTATION FREEZE

This append-only Architect addendum is newer than every prior R10.4 lock wording
in this contract. It supersedes the older "R10.4-B ... LOCKED" and "Search,
Saved ... LOCKED" status lines in sections 28 and the header for the specific
purpose of authorizing the R10.4-B implementation slice defined below. All
prior frozen semantics not explicitly superseded here remain binding.

Architect decision: V1-R10.4-B PRE-IMPLEMENTATION AUDIT = PASS —
V1-R10.4-B IS NOW READY FOR IMPLEMENTATION CONTRACT FREEZE.

Baseline at freeze time: HEAD == origin/main ==
81d6420781459532ec263d6a48dec8760b4ac346

Current roadmap state (preserved):
- R10.4-A: CLOSED / ACCEPTED
- R10.4-B: CURRENT / AUTHORIZED — IMPLEMENTATION NOT STARTED
- R10.5: NOT AUTHORIZED

### B.1 Slice title and purpose

TITLE: V1-R10.4-B — Search + Saved Production Visual Pass

PURPOSE: production-grade presentation harmonization of Search and Saved only.
This is the already-defined remaining R10.4 Core Discovery work.

### B.2 Authorized production boundary

- `lib/features/search/presentation/screens/global_search_screen.dart`
- `lib/features/saved/presentation/saved_screen.dart`
- `lib/localization/ar.dart`
- `lib/localization/en.dart`

### B.3 Conditional shared seam

`lib/features/encyclopedia/presentation/widgets/topic_list_card.dart`

This shared seam is authorized ONLY for:
- Saved topic unsave touch target >= 48x48;
- locale-aware tooltip required by the active UI locale.

No other TopicListCard redesign is authorized.

### B.4 Search frozen semantics

MUST preserve exactly:
- canonical route `/search`;
- root-navigator full-screen behavior;
- Home launch behavior;
- Back restoration behavior;
- query parameters remain ignored;
- Knowledge + Tool result types only;
- Knowledge authority unchanged;
- Tool authority unchanged;
- SearchRouteResolver unchanged;
- 280 ms debounce;
- stale-request generation protection;
- auto-search behavior;
- keyboard submit fallback;
- Knowledge before Tool ordering;
- current source-failure isolation;
- unresolved tool behavior;
- no Saved/favorite action added;
- no new filters/tabs/history/suggestions;
- no Directory/Projects/Articles search integration.

Authorized Search presentation work:
- active-locale AR/EN chrome;
- RTL/LTR-aware affordances;
- responsive readable-width behavior: Compact <600, Medium 600-839, Expanded >=840;
- theme-aware true-black dark presentation (per Appendix A);
- frozen R10 colors/tokens;
- SearchBarWidget reuse;
- CivilAppBar / CivilSurfaceCard reuse where appropriate;
- harmonized initial / no-results / loading presentation;
- accessibility / semantics improvements;
- text-scale resilience.

### B.5 Saved frozen semantics

MUST preserve exactly:
- Encyclopedia topic favorites;
- legacy article favorites;
- Directory provider favorites;
- Downloaded articles;
- persistence/resolution authorities unchanged;
- identity/reference formats;
- ordering;
- stale reference behavior;
- local-first Directory resolution;
- unavailable Directory reference behavior;
- all canonical destination routes;
- Favorites/Downloads two-tab contract;
- shell/device bottom clearance;
- no silent deletion;
- no new Saved entity types;
- no cloud Saved sync;
- no persistence migration;
- no ranking/reordering;
- no Search/filter inside Saved;
- no new inline remove actions for legacy article, Directory, or Download.

Authorized Saved presentation work:
- CivilAppBar;
- active-locale AR/EN chrome;
- coherent neutral/theme-aware row language;
- preserve type-specific semantics;
- responsive readable-width behavior;
- true-black dark parity;
- RTL/LTR correctness;
- compact empty-state geometry;
- consistent spacing/typography;
- >= 48x48 touch targets where directly owned by this slice;
- accessibility / text-scale resilience.

### B.6 Saved error-state guardrail

A distinct localized resolver Error/Retry state is authorized ONLY IF SavedScreen
can distinguish the existing failure using already-available presentation-layer
state WITHOUT changing:
- SavedReferenceResolver contract;
- domain result types;
- persistence semantics;
- data authority;
- Directory resolution semantics.

If implementing Error/Retry requires any domain/data/resolver semantic change:
DEFER IT. Protected semantics may not be modified merely to produce an error
screen.

### B.7 Shared primitives

SAFE TO REUSE WHERE APPROPRIATE:
- SearchBarWidget;
- CivilAppBar;
- CivilSurfaceCard;
- AppColors;
- AppSpacing;
- DesignTokens;
- shellSafeBottomPadding;
- TopicListCard within the exact conditional seam in B.3;
- ArticleImage where existing semantics already fit.

DO NOT:
- force SectionHeader into Search/Saved;
- reuse Home preview layout/card geometry;
- reuse Directory business cards;
- build a giant generic Search/Saved row abstraction;
- introduce a new shared primitive unless Architect review explicitly
  authorizes it.

Expected new shared primitive: NONE.

### B.8 Protected files / areas

DO NOT MODIFY:
- `lib/routes/app_routes.dart`
- `lib/routes/app_router.dart`
- `lib/core/navigation/app_shell.dart`
- `lib/features/search/domain/**`
- `lib/features/search/data/**`
- `lib/features/search/navigation/**`
- `lib/features/saved/domain/**`
- `lib/features/saved/data/**`
- `lib/data/local/hive_helper.dart`
- Encyclopedia repositories/content/generated outputs
- Directory repository/domain/detail logic
- Auth
- Startup
- Backend
- Supabase
- Schema
- RLS
- Migrations
- Article UI / R10.5 work
- Content Studio
- Exporter
- `draft_jsons/**`
- `app_ready_jsons/**`
- `assets/encyclopedia/**`

Protected dirty baseline (untouched):
- `test/a5_6_profile_bootstrap_test.dart`
- `test/v1_r08_cloud_profile_foundation_test.dart`
- `test/v1_r08_profile_edit_screen_widget_test.dart`
- `OpenCode_Usage_Report.txt`
- `artifacts/`

### B.9 Test boundary

Expected focused tests:

Search:
- `test/global_search_screen_test.dart`
- `test/home_search_hook_test.dart`
- `test/search_aggregator_test.dart`
- `test/search_route_resolver_test.dart`

Saved:
- `test/saved_screen_favorites_test.dart`
- `test/w5_6_saved_screen_directory_test.dart`
- `test/encyclopedia_favorites_test.dart`
- `test/saved_reference_resolver_test.dart`
- `test/w5_6_saved_reference_store_test.dart`
- `test/ui_safe_1_screen_regression_test.dart`
- `test/user_area_route_test.dart`

Implementation may update existing presentation/widget tests and add a narrowly
focused feature-local widget test only if necessary. Semantic regression tests
must not be weakened.

### B.10 Acceptance target

SEARCH:
- Arabic RTL;
- English LTR;
- Light;
- Dark;
- Compact;
- Expanded/readable width;
- direction-aware affordance;
- existing lifecycle/route semantics unchanged.

SAVED:
- Arabic RTL;
- English LTR;
- Light;
- Dark;
- Compact;
- Expanded/readable width;
- Favorites/Downloads preserved;
- type semantics preserved;
- >= 48x48 owned touch target;
- bottom clearance preserved.

Manual runtime review is required after the automated implementation gate.

### B.11 Boundaries with later phases (preserved)

- R10.5 remains NOT AUTHORIZED and owns Article visual/presentation work and
  cross-feature visual adoption. Article work is NOT pulled into R10.4-B.
- R10.4-B makes no change to routing, auth/startup/backend, calculator
  formulas, Directory business authority, Encyclopedia SSOT, Search/Saved
  domain semantics, or content authority.

---

## APPENDIX C — V1-R10.5-A ARTICLE PRODUCTION VISUAL PASS FREEZE

Status: ARCHITECT APPROVED / FROZEN — V1-R10.5-A IMPLEMENTATION FREEZE

This append-only Architect addendum authorizes the V1-R10.5-A implementation
slice under the existing V1-R10.5 Cross-Feature Visual Adoption Pass
(section 24, "R10.5"). It supersedes no earlier contract semantics. It only
freezes the R10.5-A Article slice boundary; all prior frozen semantics not
explicitly addressed here remain binding, and R10.5-B and later slices remain
LOCKED.

Architect decision: V1-R10.5 SCOPE PARTITION AUDIT = ACCEPTED.
V1-R10.5-A (Article Production Visual Pass) = FROZEN / READY FOR
IMPLEMENTATION.

Baseline at freeze time: HEAD == origin/main ==
615039945f003770803dac1d2cfebbaf0a04190d

Current roadmap state (preserved):
- R10.4: CLOSED / ACCEPTED
- R10.5: CURRENT / AUTHORIZED — IMPLEMENTATION NOT STARTED (R10.5-A now frozen)
- R10.6: future / locked relative to R10.5
- R10.7: future / locked relative to R10.5

### C.1 Slice title and purpose

TITLE: V1-R10.5-A — Article Production Visual Pass

PURPOSE: production-grade presentation harmonization of the existing legacy
Article feature only. This is PRESENTATION ONLY; no behavior, data, or
content change is authorized.

### C.2 Architect decisions (recorded)

1. TopicCompactCard legacy gradient: LEAVE UNCHANGED in R10.5-A. Do not
   reopen accepted Home presentation.
2. EncyclopediaCardColors / EncyclopediaTopicTheme: DEFER. Do not consolidate
   or migrate the Encyclopedia block-color layer in R10.5-A.
3. Directory: no R10.5-A work.
4. Article / Content Studio: the current legacy Article feature has no
   Content Studio / Encyclopedia SSOT ownership. R10.5-A MUST NOT introduce
   such a dependency.

### C.3 Authorized production boundary

Primary files:
- `lib/features/articles/presentation/screens/articles_screen.dart`
- `lib/features/articles/presentation/screens/all_articles_screen.dart`
- `lib/features/articles/presentation/screens/article_details_screen.dart`

Existing reusable widget:
- `lib/features/articles/presentation/widgets/article_image.dart`

`ArticleImage` should preferably be REUSED UNCHANGED. Edit is NOT authorized
unless implementation proves a directly necessary presentation defect that
cannot be solved from the three screens. If an `ArticleImage` edit becomes
necessary: STOP and request Architect review first.

Localization files (conditional):
- `lib/localization/ar.dart`
- `lib/localization/en.dart`

May be edited ONLY if a genuinely missing Article presentation string
requires active-locale UI copy. Do not add speculative keys.

### C.4 Article Detail — frozen presentation target

Use ONLY existing Article fields. Frozen presentation hierarchy:

1. Minimal `CivilAppBar`: Back; existing favorite action; existing download
   action; no large generic "Article Details" title competing with the
   article title.
2. Existing article image, when present.
3. Existing category: presentation below/adjacent to the image as a
   restrained token-aware chip; do NOT use white-on-Amber; direction-aware
   placement; no hardcoded right positioning.
4. Existing article title: visually dominant; tokenized typography;
   direction-aware alignment.
5. Existing article body: preserve exact existing content; preserve exact
   ordering; typography/spacing only; no rewriting.

DO NOT ADD: reading time; last updated; summary; author; date; metadata row;
table of contents; new CTA; new article fields. No invented information.

### C.5 Article list / All Articles target

Preserve: existing article source; existing ordering; existing navigation;
existing category behavior; existing image; title/content identity.

Presentation may improve: `CivilAppBar`; `CivilSurfaceCard` or appropriate
accepted surface composition; `ArticleImage` reuse; tokenized
spacing/radius/typography; direction-aware chevrons; coherent image geometry;
restrained category treatment; Light/Dark parity; RTL/LTR parity.

DO NOT introduce: new sort; filter; ranking; pagination; search; new
categories; new data source. Do not weaken semantic tests.

### C.6 Protected Article semantics

DO NOT MODIFY:
- `lib/models/article_model.dart`
- `lib/data/repositories/article_repository.dart`
- `lib/data/local/hive_helper.dart`

Article routes (preserved):
- `/articles`
- `/article/:id`
- `/articles/category/:id`

Preserved behavior: favorite behavior; download behavior; Hive persistence;
snackbar semantics; offline/local behavior; Hero identity/tag semantics
unless presentation can keep it unchanged. Do not alter Article IDs or
content.

### C.7 Content Studio / SSOT protection

STRICTLY OUT OF SCOPE:
- `draft_jsons/**`
- `app_ready_jsons/**`
- `assets/encyclopedia/**`
- Content Studio
- Content Studio Preview
- Exporter
- generated catalog/content
- Encyclopedia content block renderers
- article schema/model expansion

Current R10.5-A presentation does NOT require Content Studio changes. Do not
create a relationship between legacy Articles and Content Studio in this
slice.

### C.8 Visual language

Follow frozen R10 visual direction:
- Amber = signature/accent; Blue = technical/support; neutrals = majority.
- Dark: canvas `#000000`; primary surface `#121212`; secondary surface
  `#1A1A1A`; elevated surface `#262626`; approved border hierarchy.

Avoid: white-on-Amber low contrast; raw `Colors.white` / `Colors.black` when
tokens exist; raw `primaryColor` styling; arbitrary shadows; giant category
color palette; hardcoded directional positioning.

Use accepted: `CivilAppBar`; `CivilSurfaceCard` where semantically
appropriate; `AppColors`; `AppSpacing`; `DesignTokens`; `textTheme` /
`AppTypography`; `ArticleImage`.

No new shared primitive is expected.

### C.9 Responsive / accessibility boundary

R10.5-A handles only feature-local presentation resilience: reasonable
Compact layout; no obvious wide-screen stretching; RTL/LTR; Light/Dark;
normal text-scaling resilience; `>= 48x48` owned actions.

Do NOT consume the full R10.6 repository-wide responsive/accessibility
sweep.

### C.10 Test freeze

Inspect existing tests first. Expected useful regressions:
- `test/home_latest_articles_test.dart`
- `test/article_image_test.dart`
- `test/ui_safe_1_screen_regression_test.dart`
- `test/v1_r09q_smoke_journeys_test.dart`

Add focused Article presentation/widget tests for the three affected screens
where necessary. Coverage required: list renders/navigates; All Articles
renders/navigates; Detail hierarchy; existing favorite action; existing
download action; AR/EN presentation where chrome exists; RTL/LTR
directionality; Light/Dark token behavior; category treatment; no invented
metadata; existing Article data preserved.

### C.11 Manual acceptance

Manual runtime / visual review is required before closure, covering: Articles
list; All Articles; Article Detail; Light; Dark; Arabic RTL; English LTR
where applicable; favorite toggle; download action; Home → Article / All
Articles → Detail → Back.

### C.12 Future R10.5 slices (preserved)

- R10.5-A Articles — CURRENT (frozen)
- R10.5-B Tools + Calculators — LOCKED
- R10.5-C Projects — LOCKED
- R10.5-D Profile + User Area — LOCKED
- R10.5-E Business + Staff — LOCKED
- R10.5-F Encyclopedia micro-polish — LOCKED

Do NOT start any later slice from R10.5-A.

### C.13 Protected dirty baseline

- `test/a5_6_profile_bootstrap_test.dart`
- `test/v1_r08_cloud_profile_foundation_test.dart`
- `test/v1_r08_profile_edit_screen_widget_test.dart`
- `OpenCode_Usage_Report.txt`
- `artifacts/`

Do not touch, format, stage, commit, push, restore, reset, or clean.

---

## APPENDIX D — V1-R10.5-A FORMAL CLOSURE + LANGUAGE-SCOPE SYNCHRONIZATION

Status: ARCHITECT APPROVED / RECORDED — V1-R10.5-A CLOSED / ACCEPTED

This append-only addendum records: (1) the formal closure of the V1-R10.5-A
slice frozen in APPENDIX C, (2) the Owner language-scope decision, and
(3) the transition of the current authorized slice to R10.5-B. It changes no
frozen presentation semantics and rewrites no historical record.

Architect decision: PASS — V1-R10.5-A ACCEPTED

Closure baseline: HEAD == origin/main == 4e53d634d1c61f90e8a9cdd939d7fb501c3270ce

### D.1 R10.5-A closure evidence

- implementation completed (3 Article screens presentation pass)
- focused presentation tests: 4 PASS / 0 FAIL
- Article-focused regression gate: 16 PASS / 0 FAIL
- independent post-implementation review: PASS
- HIGH findings: NONE; MEDIUM findings: NONE; LOW findings: 2 non-blocking /
  deferred
- manual runtime visual review: PASS (Light, Dark, Arabic RTL, Article list,
  Article detail)
- favorite / download presentation preserved
- no invented metadata
- Article data / body semantics preserved
- Content Studio / Encyclopedia SSOT untouched

### D.2 Scope / non-change confirmation (V1-R10.5-A)

- ArticleModel unchanged
- ArticleRepository unchanged
- Hive unchanged
- ArticleImage unchanged
- Article routes unchanged
- Content Studio untouched
- Encyclopedia SSOT untouched
- no R10.5-B or later slice implementation performed inside R10.5-A
- no service_role; no new data source; no new provider/state authority

### D.3 Owner language-scope decision (recorded)

Civilpedia V1 user-facing product is ARABIC-ONLY. The user-facing Arabic <-> English
language switch has been cancelled / disabled.

Therefore:
- Arabic RTL is the active V1 user-facing locale requirement.
- English / LTR is NOT a manual runtime acceptance requirement while the
  user-facing language switch remains disabled.
- Do NOT enable an English switch.
- Do NOT treat unavailable user-facing English switching as a defect.
- Existing En localization resources may remain.
- Existing dormant English-support code / tests do NOT need to be removed merely
  because switching is disabled.
- Do NOT perform a broad localization cleanup or delete En keys.
- A future Owner / Architect decision may reactivate English.

This decision supersedes any R10 manual-acceptance wording that requires
English/LTR as an active user-facing V1 path (including the English/LTR wording
in C.11, which applies to the active V1 path only for Arabic RTL).
It does NOT rewrite historical test evidence and does NOT reopen accepted
R10.4 work.

### D.4 Non-blocking deferred content note (image/content mismatch)

- "طبقات الرصف للطرق" currently displays a residential-building image (observed
  during manual QA).
- NOT an R10.5-A presentation defect; R10.5-A explicitly preserved existing
  Article image/data sources.
- Do NOT change the image, ArticleRepository, ArticleModel, or content in this
  scope. Classify for later content/media cleanup only.

### D.5 R10.5-A closure status

V1-R10.5-A — Article Production Visual Pass:

STATUS: CLOSED / ACCEPTED

### D.6 Next slice transition

V1-R10.5-B — Tools + Calculators Presentation Pass:

STATUS: CURRENT / AUTHORIZED — IMPLEMENTATION NOT STARTED

Preserved:
- V1-R10.5-C Projects — LOCKED
- V1-R10.5-D Profile + User Area — LOCKED
- V1-R10.5-E Business + Staff — LOCKED
- V1-R10.5-F Encyclopedia micro-polish — LOCKED
- V1-R10.6 / V1-R10.7 — LOCKED

Implementation of R10.5-B is NOT started by this documentation task.

### D.7 Protected dirty baseline

Do NOT touch:
- test/a5_6_profile_bootstrap_test.dart
- test/v1_r08_cloud_profile_foundation_test.dart
- test/v1_r08_profile_edit_screen_widget_test.dart
- OpenCode_Usage_Report.txt
- artifacts/

### D.8 Git confirmation at closure

- git diff --check: exit 0 (LF/CRLF informational warnings only)
- git status --short: R10.5-A implementation + protected baseline only
- nothing staged / cached
- HEAD == origin/main == 4e53d634d1c61f90e8a9cdd939d7fb501c3270ce

---

## APPENDIX E — V1-R10.5-B TOOLS + CALCULATORS PRESENTATION PASS FREEZE

Status: ARCHITECT APPROVED / FROZEN — V1-R10.5-B IMPLEMENTATION FREEZE

The V1-R10.5-B Pre-Implementation Audit is ACCEPTED. V1-R10.5-B is frozen as a
PRESENTATION-ONLY slice. NO calculator domain/formula changes are authorized.

Owner language scope (preserved):
- V1 user-facing UI = ARABIC-ONLY
- English switch = DISABLED
- English runtime QA = NOT REQUIRED
- Dormant En resources remain untouched

Freeze baseline: HEAD == origin/main ==
78000cd43d18b630a044d8ddd4b2878c5b9915df

### E.1 Exact production boundary (authorized files ONLY)

1. lib/features/tools/presentation/screens/calculators/calculator_screen.dart
2. lib/features/tools/presentation/screens/calculators/tile_calculator_screen.dart
3. lib/features/tools/presentation/widgets/calculator/calculator_primary_button.dart
4. lib/features/tools/presentation/screens/checklist/checklist_screen.dart
5. lib/features/tools/presentation/screens/checklist/checklist_category_detail_screen.dart
6. lib/features/tools/presentation/screens/checklist/widgets/inspection_category_card.dart
7. lib/features/tools/presentation/screens/checklist/widgets/inspection_summary_card.dart

No other production file is authorized.

### E.2 Tools landing (leave unchanged)

lib/features/tools/presentation/screens/tools_screen.dart — LEAVE UNCHANGED.
Reason: already R10-aligned and protected by its existing visual control test
(test/tools_screen_d4a_test.dart). Do NOT perform cleanup merely for
consistency.

### E.3 Calculator domain — strictly protected

DO NOT MODIFY: lib/features/tools/domain/**

Includes all authorities for:
- Concrete calculations
- Steel calculations
- Masonry / Brick calculations
- Tile calculations
- calculator snapshots/presets
- ToolKey
- checklist contracts/domain (including checklist_repository /
  local_checklist_repository / local data sources)

Frozen semantics include: formulas; units; conversions; defaults; validation
semantics; output values; rounding; ceil/floor behavior; density constants;
waste calculations; stock-bar behavior; truck calculations; preset dimensions.
ZERO engineering calculation changes.

### E.4 Routing / navigation — protected

DO NOT MODIFY:
- lib/routes/app_routes.dart
- lib/routes/app_router.dart
- lib/core/navigation/app_shell.dart

Preserve: /tools; /calculator/concrete; /calculator/steel; /calculator/brick;
/calculator/tile; /calculator/checklist; project navigation behavior; shell
ownership.

### E.5 Calculator screen target (calculator_screen.dart)

Presentation changes apply ONLY to the routed Concrete builder, Steel builder,
and Brick / Masonry builder. DO NOT touch the unreachable
`_buildSimpleScreen` fallback.

A. APP BAR: Replace raw full-width Amber AppBar with CivilAppBar. Preserve:
exact title meaning; refresh/reset action; action callback; navigation/back
semantics. No white-on-Amber title/action treatment.

B. INPUT AREAS: Input behavior and controllers remain unchanged. Presentation
may harmonize neutral surfaces, borders, spacing, typography. Do NOT rename
engineering inputs; change unit selectors; change validation; change
controller lifecycle; change keyboard/input semantics.

C. CARDS: Legacy CustomCard may be replaced by CivilSurfaceCard where it is a
presentation-only 1:1 replacement. Do not force conversion if doing so changes
layout semantics.

D. RESULTS: CalculatorResultRow is PROTECTED. Do NOT restructure it. Preserve
all labels/values and Row sibling structure.

E. ERRORS: CalculatorErrorCard is PROTECTED. Do NOT convert it to
CivilSurfaceCard.

F. BOTTOM / GRAND TOTAL SURFACES: May replace raw Colors.white / Colors.black
shadow styling with approved theme surface/border/shadow tokens. Preserve:
hierarchy; data; labels; values; existing structure required by tests.

### E.6 Tile calculator target (tile_calculator_screen.dart)

Authorized: CivilAppBar; presentation-only card harmonization; tokenized
bottom-bar surface/border/shadow; spacing/typography alignment.

STRICTLY PRESERVE: TileQuantityCalculator; TileCalculationSnapshot;
save-to-project behavior; reset behavior; all inputs/units; all outputs;
Key('tile_bottom_bar_value'); Ar.finalTileCount; existing bottom-bar semantic
structure.

### E.7 Calculator primary button (calculator_primary_button.dart)

Required correction: background remains AppColors.primary; foreground becomes
AppColors.textOnAmber. Reason: white-on-Amber fails the frozen contrast
requirement.

Preserve: ElevatedButton; full-width SizedBox behavior; callback behavior;
enabled/disabled semantics; sizing/layout contract.

No other shared calculator widget redesign. Note: only the background is
asserted today (test/calculator_widgets_test.dart), so the foreground change is
test-safe.

### E.8 Checklist screen target (checklist_screen.dart)

Authorized: raw Amber AppBar -> CivilAppBar; direction-aware chevron for Arabic
RTL; presentation-only card/surface harmonization where safe.

Preserve EXACTLY: checklist statuses; item ordering; notes behavior;
debounce/save behavior; persistence; progress math; reset semantics; reset
confirmation; project integration; My Projects navigation; category/content
data.

### E.9 Checklist category detail (checklist_category_detail_screen.dart)

Purpose: checklist-family AppBar consistency ONLY plus directly related
presentation token alignment if necessary. Do NOT change checklist item
behavior; item ordering; notes; statuses; persistence; domain/state logic.

### E.10 Inspection category card (inspection_category_card.dart)

Authorized: make chevron Directionality-aware; presentation-only
CivilSurfaceCard adoption if it is a true 1:1 replacement. Preserve: tap
behavior; labels; icons; progress/status data; callback semantics.

### E.11 Inspection summary card (inspection_summary_card.dart)

Required: reset action touch target >=48x48. Presentation-only surface
harmonization allowed. Preserve: reset callback; confirmation flow; summary
math; labels; status counts; persistence semantics.

### E.12 Leave unchanged / protected

DO NOT MODIFY:
- lib/features/tools/presentation/widgets/project_picker_dialog.dart
- lib/features/tools/presentation/widgets/calculator/calculator_result_row.dart
- lib/features/tools/presentation/widgets/calculator/calculator_error_card.dart
- lib/features/tools/presentation/screens/checklist/widgets/inspection_item_tile.dart
- lib/features/tools/presentation/screens/checklist/widgets/inspection_badge.dart
- lib/features/tools/presentation/screens/checklist/widgets/inspection_notes_field.dart
- lib/features/tools/presentation/screens/checklist/widgets/inspection_progress_card.dart
- lib/features/tools/presentation/screens/checklist/models/**
- lib/features/tools/presentation/screens/checklist/data/inspection_seed_data.dart
- lib/features/tools/presentation/screens/checklist/inspection_localization.dart
- lib/features/tools/presentation/screens/checklist/project_list_screen.dart

Do NOT modify localization files in R10.5-B. Arabic copy already exists for the
active V1 acceptance path.

### E.13 Visual language

Follow frozen R10 direction: Amber = signature/accent only; Blue =
technical/support role; Neutrals = majority. Dark: #000000 canvas; #121212
primary surface; #1A1A1A secondary surface; #262626 elevated surface.

Use existing: CivilAppBar; CivilSurfaceCard; AppColors; AppSpacing;
DesignTokens; textTheme; existing Calculator widgets.

Avoid: white-on-Amber; raw white/black where tokens exist; large raw
primary-color areas; arbitrary shadows; new category/color palettes.
New shared primitive: NOT AUTHORIZED / NOT REQUIRED.

### E.14 Deferred (non-blockers)

Explicitly DEFER: ChoiceChip redesign; broad inline font-size cleanup;
repository-wide responsive framework; broad readable-width enforcement;
unreachable `_buildSimpleScreen`; checklist_repository domain->presentation
import cleanup; MasonryPreset.label ownership cleanup; calculator architecture
refactor; new calculator primitives. These are NOT blockers for R10.5-B.

### E.15 Test freeze

Presentation/widget tests: test/concrete_calculator_widget_test.dart;
test/steel_calculator_widget_test.dart; test/brick_calculator_widget_test.dart;
test/tile_calculator_widget_test.dart; test/calculator_widgets_test.dart;
test/checklist_widget_test.dart; test/tools_screen_d4a_test.dart;
test/project_list_screen_test.dart.

Add: test/v1_r10_5b_calculators_visual_test.dart. New focused visual test
should verify at minimum: CivilAppBar on Concrete/Steel/Brick/Tile/Checklist;
no legacy white-on-Amber full header; CalculatorPrimaryButton foreground ==
AppColors.textOnAmber; RTL direction-aware checklist chevron; reset control
>=48x48; dark theme uses approved token surfaces; critical existing refresh
actions remain.

Pure domain regressions (run unchanged): test/concrete_volume_calculator_test.dart;
test/steel_weight_calculator_test.dart; test/masonry_quantity_calculator_test.dart;
test/tile_quantity_calculator_test.dart; test/checklist_state_test.dart;
test/checklist_persistence_test.dart; test/tool_key_test.dart.

Do NOT weaken existing structural assertions.

### E.16 Critical regression invariants

Preserve: Concrete refresh action; Steel refresh action; Brick refresh action;
Tile refresh action. Tile: Key('tile_bottom_bar_value'); Ar.finalTileCount.
Steel: CalculatorResultRow Row-sibling structure. CalculatorPrimaryButton:
background = AppColors.primary; full-width wrapper preserved.
CalculatorErrorCard: Container / BoxDecoration structure preserved.
Tools landing: existing d4a visual-control expectations remain green.

### E.17 Focused gate

Implementation gate runs with --no-pub. Do NOT run full flutter test, flutter
analyze, flutter pub get, emulator, or Supabase.

Presentation gate:
flutter test --no-pub test/concrete_calculator_widget_test.dart test/steel_calculator_widget_test.dart test/brick_calculator_widget_test.dart test/tile_calculator_widget_test.dart test/calculator_widgets_test.dart test/checklist_widget_test.dart test/tools_screen_d4a_test.dart test/project_list_screen_test.dart test/v1_r10_5b_calculators_visual_test.dart

Domain gate:
flutter test --no-pub test/concrete_volume_calculator_test.dart test/steel_weight_calculator_test.dart test/masonry_quantity_calculator_test.dart test/tile_quantity_calculator_test.dart test/checklist_state_test.dart test/checklist_persistence_test.dart test/tool_key_test.dart

### E.18 Manual acceptance (post-implementation Owner runtime QA)

Concrete: valid result; invalid/error input; unit switch; add element; grand
total; refresh.
Steel: normal calculation; waste/cost/stock; refresh.
Brick: preset; openings; result; refresh.
Tile: preset/custom; box/cost estimate; reset; save-to-project area.
Checklist: categories; category detail; status changes; notes; reset dialog;
My Projects navigation.
Themes: Light; Dark. Direction: Arabic RTL.
English runtime QA: NOT REQUIRED.

### E.19 Later slices (preserved)

- V1-R10.5-C Projects — LOCKED
- V1-R10.5-D Profile + User Area — LOCKED
- V1-R10.5-E Business + Staff — LOCKED
- V1-R10.5-F Encyclopedia micro-polish — LOCKED
- V1-R10.6 / V1-R10.7 — LOCKED

No later-slice implementation from R10.5-B.

### E.20 Protected dirty baseline

Do NOT touch: test/a5_6_profile_bootstrap_test.dart;
test/v1_r08_cloud_profile_foundation_test.dart;
test/v1_r08_profile_edit_screen_widget_test.dart; OpenCode_Usage_Report.txt;
artifacts/. Do not stage, commit, push, restore, reset, or clean.

### E.21 Git confirmation at freeze

- git diff --check: exit 0 (LF/CRLF informational warnings only)
- git status --short: protected dirty baseline only
- nothing staged / cached
- HEAD == origin/main == 78000cd43d18b630a044d8ddd4b2878c5b9915df

---

## APPENDIX F — V1-R10.5-B FORMAL CLOSURE + R10.5-C PHASE TRANSITION

Status: ARCHITECT APPROVED / RECORDED — R10.5-B CLOSED / ACCEPTED

This append-only addendum records the formal closure of V1-R10.5-B and the
phase transition to V1-R10.5-C. It does not rewrite APPENDIX E, the frozen
7-file production boundary, earlier evidence, or any historical status. This
newer addendum supersedes older current-slice wording only where that wording
would otherwise conflict with the live state below.

Architect final acceptance: PASS — R10.5-B ACCEPTED

Closure baseline: HEAD == origin/main ==
`be7a4b322903c8fe8609fa175833b7002e37523d`

Implementation commit: PENDING OWNER COMMIT — implementation remains uncommitted

### F.1 R10.5-B closure evidence

- implementation completed inside the frozen APPENDIX E production boundary;
- presentation gate: 138 PASS / 0 FAIL;
- domain gate: 133 PASS / 0 FAIL;
- independent review: PASS;
- findings: HIGH 0; MEDIUM 0; LOW 1 — accepted/deferred, non-blocking;
- Owner manual visual review: PASS;
- Light / Dark visual review: PASS;
- Arabic RTL visual review: PASS.

### F.2 Accepted deferred LOW finding

The new R10.5-B visual test does not explicitly assert that the Checklist
`CivilAppBar` background differs from `AppColors.primary`.

This finding is accepted and deferred as LOW / NON-BLOCKING. R10.5-B MUST NOT
be reopened solely to address this finding.

### F.3 R10.5-B protected-scope confirmation

The accepted implementation preserved:

- calculator formulas and engineering domain semantics;
- checklist state, progress, reset behavior, and persistence semantics;
- routes and application shell;
- localization resources and active Arabic RTL behavior;
- the Tools landing;
- `ProjectPicker`;
- all R10.5-C and later-slice production implementation.

No localization, domain, data, persistence, routing, shell, or later-slice
production change was accepted as part of this closure.

### F.4 Next-slice transition

V1-R10.5-C — Projects Presentation Pass:

- status: CURRENT / AUTHORIZED FOR FOCUSED PRE-IMPLEMENTATION AUDIT;
- implementation: NOT STARTED;
- implementation authorization: NO — it begins only after the focused audit
  and a subsequent Architect production-boundary freeze;
- the next authorized task is the pre-implementation audit only;
- no production boundary, file list, semantic change, or implementation detail
  is frozen by this transition.

### F.5 R10.5-C high-level protection

- Projects domain, data, and persistence semantics remain protected until the
  focused audit and Architect freeze;
- no R10.5-C production implementation is authorized or performed by this
  closure addendum;
- R10.5-C+ remains untouched by the R10.5-B implementation.

### F.6 Locked later slices

- V1-R10.5-D — Profile + User Area: LOCKED;
- V1-R10.5-E — Business + Staff: LOCKED;
- V1-R10.5-F — Encyclopedia Micro-polish: LOCKED;
- V1-R10.6: LOCKED;
- V1-R10.7: LOCKED.

### F.7 Protected dirty baseline

This documentation closure does not touch, format, stage, commit, push,
restore, reset, or clean:

- `test/a5_6_profile_bootstrap_test.dart`;
- `test/v1_r08_cloud_profile_foundation_test.dart`;
- `test/v1_r08_profile_edit_screen_widget_test.dart`;
- `OpenCode_Usage_Report.txt`;
- `artifacts/`.

---

## APPENDIX G — V1-R10.5-C PROJECTS PRESENTATION PASS FREEZE

Status: ARCHITECT APPROVED / FROZEN — R10.5-C IMPLEMENTATION AUTHORIZED

This append-only addendum records the accepted focused R10.5-C Projects audit
and freezes the implementation contract. It does not rewrite APPENDIX A-F, the
R10.5-B closure, earlier evidence, or any historical status. Where older
current-slice wording would conflict with the live state below, this newer
addendum supersedes it.

Implementation authorization: YES

Risk: MEDIUM

The production boundary is small, but Projects contains persistent data,
destructive actions, checklist association, asynchronous loading, and picker
flows whose existing semantics must remain exact.

This is a presentation-only slice. No domain, data, route, persistence,
storage-key, checklist, calculator, localization, or shared-theme change is
authorized.

Freeze baseline: HEAD == origin/main ==
`de8e6a0212944e0d2f84a0cfec787bf9c83df158`

### G.1 Exact authorized production boundary

Only these two production files are authorized:

1. `lib/features/projects/presentation/project_list_screen.dart`;
2. `lib/features/tools/presentation/widgets/project_picker_dialog.dart`.

Required new focused test:

- `test/v1_r10_5c_projects_visual_test.dart`.

There are no conditional production files. If implementation requires any
other production file, stop with:

`ARCHITECT REVIEW REQUIRED`

Do not add a second implementation, compatibility replacement, new shared
primitive, or adjacent presentation file inside this slice.

### G.2 Projects domain and data protection

DO NOT MODIFY:

- `lib/features/projects/domain/**`;
- `lib/features/projects/data/**`.

Preserve exactly:

- project IDs;
- names;
- timestamps;
- stored schema;
- persisted ordering;
- active/archive filtering;
- create semantics;
- rename semantics;
- archive semantics;
- restore semantics;
- delete semantics;
- repository calls;
- persisted data;
- backward compatibility;
- checklist-project association.

Do not change any domain, repository, caching, serialization, or persistence
behavior. Presentation changes must continue to consume the existing
authorities exactly as they do today.

### G.3 Storage and checklist protection

DO NOT MODIFY:

- `lib/core/storage/app_storage_keys.dart`;
- `lib/features/tools/data/checklist/**`;
- `lib/features/tools/presentation/screens/checklist/project_list_screen.dart`;
- `lib/features/tools/presentation/screens/checklist/checklist_screen.dart`.

The deletion invariant MUST remain exact:
`LocalChecklistRepository.clearProject(project.id)` continues to execute
according to the existing deletion flow before project deletion.

The `ChecklistScreen(project: project)` navigation association MUST remain
exact. No checklist behavior, storage key, project key, cleanup order, or
navigation payload may change.

### G.4 Routing and shell protection

DO NOT MODIFY:

- `lib/routes/app_routes.dart`;
- `lib/routes/app_router.dart`;
- `lib/core/navigation/app_shell.dart`.

No new nested project route, project-detail route, selected/current-project
route state, or navigation architecture is authorized. Existing branch
ownership, route identity, and navigation remain unchanged.

### G.5 Project list screen — app bar

In `lib/features/projects/presentation/project_list_screen.dart`:

- replace the raw `AppBar` with `CivilAppBar`;
- preserve the current title meaning;
- preserve the active/archive title state;
- preserve the existing action, callback, and navigation semantics;
- use the neutral canonical R10 chrome.

No title, action, or navigation semantics may change as part of the visual
alignment.

### G.6 Project list screen — project rows

Adopt `CivilSurfaceCard` where it is a true presentation-only replacement.

Use theme-aware `ColorScheme` and existing tokens for:

- surface;
- outline/border;
- title;
- metadata;
- destructive action presentation.

Light-only static secondary text colors MUST NOT remain in dark mode.

Preserve exactly:

- row tap behavior;
- the exact project object passed to callbacks and navigation;
- title/name;
- timestamp;
- overflow/menu;
- callbacks;
- archive state.

### G.7 Project list screen — readable width

Apply feature-local responsive presentation:

- compact: `< 600`;
- medium: `600-839`;
- expanded: `>= 840`.

Use the frozen R10 gutters and approximately `maxWidth: 760` dp.

Apply the same readable-width treatment consistently to:

- populated state;
- loading state;
- empty state;
- failure/retry state.

Do not introduce a new responsive framework and do not move this concern into
shared infrastructure.

### G.8 Project list screen — loading, empty, and failure states

The existing project load MUST visually distinguish:

- loading;
- valid empty;
- loaded projects;
- failure.

On initial load failure, show a safe Arabic user-facing error presentation with
retry. Do not expose raw exception text.

If a later reload fails after known-good data is already present, preserve the
known-good visible data. Do not replace known-good data with a false empty
state.

This is presentation-state handling only. Do not change repository authority,
persistence, data ordering, or project semantics.

Use existing localization/copy resources if available. Do not modify
localization files. If safe required copy cannot be produced inside the frozen
boundary without localization-file changes, stop with:

`ARCHITECT REVIEW REQUIRED`

### G.9 Create, rename, archive, restore, and delete

Preserve the existing flows exactly and keep the existing Material
`AlertDialog` approach. Do not redesign dialog architecture.

CREATE:

- callback;
- validation;
- save/cancel behavior;
- repository action.

RENAME:

- callback;
- validation;
- existing project identity.

ARCHIVE / RESTORE:

- exact action semantics;
- filtering behavior.

DELETE:

- confirmation;
- destructive callback;
- checklist cleanup;
- project deletion ordering.

Only visual token alignment already owned by the authorized screen may occur.
No semantic change is authorized.

### G.10 Project picker

`lib/features/tools/presentation/widgets/project_picker_dialog.dart` is
explicitly AUTHORIZED in R10.5-C. Its prior R10.5-B protection applied only to
that earlier slice.

Preserve:

- active-project-only filtering;
- persisted project ordering;
- exact selected `Project` object returned;
- no persisted selected/current project;
- dialog navigation and dismiss semantics.

Add presentation states for:

- loading;
- success;
- empty;
- retryable failure.

Guard asynchronous loading safely. Do not expose exception text. Retry must
re-attempt the existing load only.

Use theme-aware typography and colors. Long project names must remain usable
at:

- `390 x 844`;
- Arabic;
- text scale 1.0;
- text scale 1.3.

Scrolling and wrapping may be presentation-adjusted as needed without changing
project selection semantics.

### G.11 Shared primitives

Reuse the existing:

- `CivilAppBar`;
- `CivilSurfaceCard`;
- `AppColors`;
- `AppSpacing`;
- `DesignTokens`;
- `Theme.of(context).colorScheme`;
- existing typography.

A new shared primitive is NOT AUTHORIZED and NOT REQUIRED.

Do not modify shared theme or widget files.

### G.12 Explicitly protected and out of scope

DO NOT MODIFY:

- `lib/features/projects/domain/**`;
- `lib/features/projects/data/**`;
- `lib/routes/app_routes.dart`;
- `lib/routes/app_router.dart`;
- `lib/core/navigation/app_shell.dart`;
- `lib/features/tools/presentation/screens/checklist/project_list_screen.dart`;
- `lib/features/tools/presentation/screens/checklist/checklist_screen.dart`;
- `lib/features/tools/data/checklist/**`;
- `lib/features/tools/presentation/screens/calculators/tile_calculator_screen.dart`;
- `lib/core/storage/app_storage_keys.dart`;
- all localization files;
- all shared theme/widget files.

`ProjectNotesView` and `ProjectCalculationHistoryView` remain
production-unexposed and out of scope.

### G.13 Deferred scope

Explicitly deferred:

- `ProjectNotesView` visual work;
- `ProjectCalculationHistoryView` visual work;
- nested project routes;
- a project-detail route;
- persisted selected/current project;
- shared visual abstractions;
- new localization keys;
- controller-lifecycle refactor;
- domain/data refactor;
- repository/storage cleanup;
- broad R10.6 responsive/accessibility work;
- R10.5-D and later.

### G.14 Required new focused test

Add:

`test/v1_r10_5c_projects_visual_test.dart`

Meaningfully verify:

PROJECT LIST:

- `CivilAppBar`;
- `CivilSurfaceCard`;
- exact project ordering preserved;
- Arabic RTL;
- compact gutter behavior;
- approximately 760 dp maximum width;
- light theme roles;
- dark theme roles;
- active state;
- archived state;
- valid empty state;
- loading state;
- failure state;
- retry;
- known-good data is not replaced by a false empty state after later failure.

PROJECT ASSOCIATION:

- a project row opens `ChecklistScreen` with the exact selected `Project`.

PROJECT PICKER:

- active-only filtering;
- ordering;
- exact `Project` selection;
- loading;
- empty;
- failure;
- retry.

LAYOUT:

- no overflow at `390 x 844`;
- Arabic text scale 1.0;
- Arabic text scale 1.3.

Do not write brittle pixel tests. Do not weaken existing regression tests.

### G.15 Focused test gate

Use `--no-pub`.

First run the new focused visual test:

```
flutter test --no-pub test/v1_r10_5c_projects_visual_test.dart
```

Then run the existing Projects regression gate:

```
flutter test --no-pub test/project_list_screen_test.dart test/w3_4_app_navigation_responsive_test.dart test/w3_5_app_navigation_behavior_test.dart test/w4_1_project_domain_split_test.dart test/w4_2_project_canonicalization_test.dart test/w4_3_project_create_edit_test.dart test/w4_4_archive_restore_test.dart test/w4_5_save_calculation_test.dart test/w4_6_calculation_history_test.dart test/w4_7_notes_test.dart test/w4_8_executions_test.dart test/checklist_persistence_test.dart test/w6_1_projects_route_test.dart test/w6_3_nav_transition_test.dart test/app_storage_keys_test.dart
```

Do NOT run:

- full `flutter test`;
- `flutter analyze`;
- `flutter pub get`;
- emulator;
- Supabase.

### G.16 Owner manual QA boundary

Owner manual QA is VISUAL / UX only.

The Owner should not be required to manually re-test:

- create callback;
- rename callback;
- archive/restore semantics;
- delete semantics;
- persistence;
- checklist-project association;
- picker selection semantics;
- routing,

when those are reliably verified by automated tests and review.

Owner visual acceptance focuses on:

- Projects populated screen;
- Projects archived screen;
- empty/loading/error presentation;
- Project picker;
- Light / Dark;
- Arabic RTL;
- Compact / Medium / Expanded appearance;
- text-scale appearance where visually relevant;
- spacing;
- hierarchy;
- polish;
- overflow and clipping.

### G.17 Language scope

V1 user-facing scope: ARABIC-ONLY.

- English switch: DISABLED;
- English runtime QA: NOT REQUIRED;
- dormant `En` resources: RETAINED and UNCHANGED.

### G.18 AI usage governance

Follow the highest reliable quality with the lowest reasonable AI usage:

- no broad repository audit;
- no full-suite test;
- no redundant reviewer;
- no emulator run;
- no duplicate verification;
- stop when focused evidence is sufficient.

### G.19 Locked later slices

Keep LOCKED:

- V1-R10.5-D — Profile + User Area;
- V1-R10.5-E — Business + Staff;
- V1-R10.5-F — Encyclopedia Micro-polish;
- V1-R10.6;
- V1-R10.7.

### G.20 Git safety

Protected dirty baseline — DO NOT touch:

- `test/a5_6_profile_bootstrap_test.dart`;
- `test/v1_r08_cloud_profile_foundation_test.dart`;
- `test/v1_r08_profile_edit_screen_widget_test.dart`;
- `OpenCode_Usage_Report.txt`;
- `artifacts/`.

Do not stage, commit, push, restore, reset, or clean.

Freeze-time verification:

- `git diff --check`: informational LF/CRLF warnings only on protected files;
- `git status --short`: protected dirty baseline only before this contract edit;
- nothing staged / cached;
- `HEAD == origin/main ==` `de8e6a0212944e0d2f84a0cfec787bf9c83df158`.

This documentation freeze modifies only this authoritative contract file.

---

### G.21 Appendix G test-gate correction / addendum

Status: ARCHITECT APPROVED / RECORDED — TEST MANIFEST CORRECTION ONLY

This is an append-only additive correction under APPENDIX G. It does not
rewrite, delete, or supersede the historical APPENDIX G text, evidence, or
the original G.15 command text as a historical record. It changes only the
executable R10.5-C test manifest.

Correction baseline: HEAD == origin/main ==
`b71856009ac3229c28e4af059ea23cc4c160ddcf`

Implementation state at this correction: the R10.5-C production implementation
is currently UNCOMMITTED and MUST NOT be touched by this documentation
correction.

#### G.21.1 Defect classification

Two test paths frozen into the original G.15 regression gate do not exist in
current HEAD:

- `test/w3_4_app_navigation_responsive_test.dart`;
- `test/w3_5_app_navigation_behavior_test.dart`.

Codex also reports that Git history contains no record of either path.

These two references were stale audit / test-manifest references. This is NOT
a production-code defect.

Do NOT create, restore, or invent replacement tests. No replacement tests are
required merely to preserve obsolete filenames.

#### G.21.2 Removal from the executable gate

The two nonexistent paths are removed from the executable R10.5-C regression
gate:

- `test/w3_4_app_navigation_responsive_test.dart`;
- `test/w3_5_app_navigation_behavior_test.dart`.

The original G.15 command text is retained above as the historical record of
the gate as originally frozen. For execution, this addendum governs.

#### G.21.3 Existing evidence, recorded without change

- New R10.5-C visual test: 11 PASS / 0 FAIL.
- Original frozen regression command: exit code 1 ONLY because the two
  referenced test files were absent.
- All regression files that actually exist in current HEAD: 333 tests passed.

This evidence does NOT yet replace the requirement to run the corrected
authoritative regression command once after this addendum is committed.

#### G.21.4 Corrected authoritative regression gate

```
flutter test --no-pub test/project_list_screen_test.dart test/w4_1_project_domain_split_test.dart test/w4_2_project_canonicalization_test.dart test/w4_3_project_create_edit_test.dart test/w4_4_archive_restore_test.dart test/w4_5_save_calculation_test.dart test/w4_6_calculation_history_test.dart test/w4_7_notes_test.dart test/w4_8_executions_test.dart test/checklist_persistence_test.dart test/w6_1_projects_route_test.dart test/w6_3_nav_transition_test.dart test/app_storage_keys_test.dart
```

All existing project / domain / persistence / routing regressions that exist in
current HEAD remain required. Do not weaken or drop them.

#### G.21.5 Required visual gate — unchanged

```
flutter test --no-pub test/v1_r10_5c_projects_visual_test.dart
```

The new R10.5-C visual test remains required.

#### G.21.6 No scope change

This addendum changes ONLY the test manifest. It does NOT change:

- the production boundary;
- visual requirements;
- project behavior;
- domain / data authority;
- persistence;
- routing;
- checklist association;
- `ProjectPicker` semantics;
- localization;
- manual visual QA scope.

The authorized production boundary remains exactly:

- `lib/features/projects/presentation/project_list_screen.dart`;
- `lib/features/tools/presentation/widgets/project_picker_dialog.dart`.

The required test remains:

- `test/v1_r10_5c_projects_visual_test.dart`.

#### G.21.7 Protected baseline — unchanged

DO NOT TOUCH:

- `test/a5_6_profile_bootstrap_test.dart`;
- `test/v1_r08_cloud_profile_foundation_test.dart`;
- `test/v1_r08_profile_edit_screen_widget_test.dart`;
- `OpenCode_Usage_Report.txt`;
- `artifacts/`.

Also DO NOT touch the current uncommitted R10.5-C production implementation:

- `lib/features/projects/presentation/project_list_screen.dart`;
- `lib/features/tools/presentation/widgets/project_picker_dialog.dart`.

Do not stage, commit, push, restore, reset, or clean.

This documentation correction modifies only this authoritative contract file.

---
