# CIVILPEDIA — MASTER NAVIGATION ARCHITECTURE

**Phase:** M3 (Master Navigation Architecture). **Status:** ARCHITECTURE / DOCUMENTATION ONLY — no router or app code changed.
**Inputs:** `CIVILPEDIA_PRODUCT_ARCHITECTURE.md` (M1), `CIVILPEDIA_SCREEN_MAP.md` (M2), plus live repository inspection of the current GoRouter and all navigation call sites.

> This document defines the **target** navigation architecture and how the **current** app moves to it. The current production navigation is unchanged. Architecture first, router implementation later.

---

## 1. Purpose

Design the complete navigation architecture for the approved target product (Home · Knowledge · Tools · My Projects · Directory), including route ownership, nested navigation, deep links, cross-domain transitions, conditional visibility, and the safe migration path — **without writing any router code**.

---

## 2. Current Navigation Baseline (verified from repository)

- Engine: **GoRouter** (`lib/routes/app_router.dart`, `appRouter`), single `rootNavigator`, `initialLocation: '/splash'`, `errorBuilder` → `NotFoundScreen`.
- Shell: `lib/core/navigation/app_shell.dart` — `StatefulShellRoute.indexedStack` with **5 branches** built from `kShellDestinations` (order = branch index contract). AppShell owns only nav chrome + double-back-to-exit.
- Current 5 destinations: `/home` (Ar.home), `/encyclopedia` (Ar.encyclopedia), `/tools` (Ar.tools), `/saved` (Ar.saved), `/profile` (Ar.account).
- Root-level routes: `/splash`, `/onboarding`, `/profile-setup`, `/auth`, `/categories`, `/encyclopedia/topics/:categoryId`, `/encyclopedia/topic/:topicId`, `/articles`, `/articles/:category`, `/article/:id`, `/calculator/concrete`, `/calculator/steel`, `/calculator/brick`, `/calculator/checklist`, `/calculator/tile`. All detail routes use `parentNavigatorKey: _rootNavigator` (they present over the shell).

### Current Route Inventory

| Route | Owning current feature | How reached | GoRouter / bypass | Current status | Target domain | Migration recommendation |
|---|---|---|---|---|---|---|
| `/splash` | Splash | initialLocation | GoRouter (go) | ACTIVE | System/bootstrap | KEEP (bootstraps onboarding/profile-setup/home decision |
| `/onboarding` | Onboarding | splash `go` | GoRouter (`context.go`) | ACTIVE | System | KEEP |
| `/profile-setup` | Profile | onboarding/splash `go` | GoRouter | ACTIVE | User Area | MIGRATE LATER (user area) |
| `/auth` | Auth | profile `context.go('/auth')` | GoRouter | ACTIVE | User Area | MIGRATE LATER |
| `/home` | Home | shell branch | GoRouter (shell) | ACTIVE | Home | KEEP |
| `/encyclopedia` | Encyclopedia | shell branch (+ `?q=`) | GoRouter | ACTIVE | Knowledge | MIGRATE LATER (Encyclopedia→Knowledge wrapper, §8) |
| `/tools` | Tools | shell branch | GoRouter | ACTIVE | Tools | KEEP |
| `/saved` | Saved | shell branch | GoRouter | ACTIVE | User state | MIGRATE LATER (user area / Knowledge), §13 |
| `/profile` | Profile | shell branch | GoRouter | ACTIVE | User Area (avatar) | MIGRATE LATER (§12) |
| `/categories` | Encyclopedia | home `context.push('/categories')` | GoRouter | ACTIVE | Knowledge | MIGRATE LATER (nested under Knowledge) |
| `/encyclopedia/topics/:categoryId` | Encyclopedia | encyclopedia/categories/home `context.push` | GoRouter | ACTIVE | Knowledge | MIGRATE LATER (nested) |
| `/encyclopedia/topic/:topicId` | Encyclopedia | topic list/home/widgets/saved `context.push` | GoRouter | ACTIVE | Knowledge | MIGRATE LATER (nested) |
| `/articles` | Articles | home/quick-access `context.push('/articles')` | GoRouter | ACTIVE | Knowledge | MIGRATE LATER (legacy articles → Knowledge, not merged now) |
| `/articles/:category` | Articles | **no producer found** | GoRouter | **VERIFIED DEAD / latent** | Knowledge | DEPRECATE LATER — see §22 note |
| `/article/:id` | Articles | articles lists / home latest / saved `context.push` | GoRouter | ACTIVE | Knowledge | MIGRATE LATER (legacy reader) |
| `/calculator/concrete` | Tools | quick_tools / tools grid / topic `relatedToolRoutes` | GoRouter | ACTIVE | Tools | KEEP (but §9 route contract) |
| `/calculator/steel` | Tools | tools grid / related tools | GoRouter | ACTIVE | Tools | KEEP |
| `/calculator/brick` | Tools | tools grid | GoRouter | ACTIVE | Tools | KEEP (registered as `brick`; content TAB = masonry) |
| `/calculator/checklist` | Tools | tools grid | GoRouter | ACTIVE | Tools | KEEP |
| `/calculator/tile` | Tools | tools grid / related tools | GoRouter | ACTIVE | Tools | KEEP |
| `Navigation.push(ProfileEditScreen)` | Profile | profile rows `Navigator.push(MaterialPageRoute)` (profile_screen.dart:444,464) | **Navigator.push bypass** | ACTIVE | User Area | MIGRATE LATER (typed route; profile edit is a full screen) |
| `Navigation.push(ChecklistCategoryDetailScreen)` | Tools | checklist category (checklist_screen.dart:198) | **Navigator.push bypass** | ACTIVE | Tools | MIGRATE LATER (typed nested route) |
| `Navigation.push(ProjectListScreen)` | Tools/Projects | checklist project selector (checklist_screen.dart:272) | **Navigator.push bypass** | ACTIVE | Projects | MIGRATE LATER (into Projects domain, §10) |
| `Navigation.push(ChecklistScreen(project:))` | Tools/Projects | project list row (project_list_screen.dart:194) | **Navigator.push bypass** | ACTIVE | Projects | MIGRATE LATER (project-scoped checklist, §10) |
| Not-Found | System | errorBuilder | GoRouter | ACTIVE | System | KEEP |

**Navigation debt (classified, NOT fixed):**
- **Navigator.push bypasses** (5 raw `MaterialPageRoute` leak points above) — MIGRATE LATER to typed routes.
- **Projects screens live under Tools** (`checklist_screen.dart:272`, `project_list_screen.dart:194`) — MIGRATE LATER to Projects domain (§10).
- **`/articles/:category` has no producer** — VERIFIED DEAD / latent (DEPRECATE LATER; owner decision).
- **Tool routes stored without leading `/`** (`'calculator/concrete'` etc. in `ArticleRepository.tools`; prefixed at push-time as `'/${tool.route}'`) — if a future value adds `/`, the slash doubles. Recommendation only: normalize to a typed route contract (§18).
- **`relatedToolRoutes` = raw route strings embedded in content/topic data** and navigated via `context.go(route)` in `topic_detail_screen.dart:954`; also a local `toolNames` map there carries **mojibake (garbled Arabic)** translated labels. OWNER DECISION + DEFERRED: content should reference typed tool keys, not raw paths (§9, §18).

---

## 3. Target Navigation Model

- **5 stable domain roots**: `/home`, `/knowledge`, `/tools`, `/projects`, `/directory`.
- Each domain owns an internal, **nested** route tree — no top-level route for every internal screen.
- Detail screens live below their owning domain.
- Cross-domain movement goes through **stable public route contracts** only.
- User access is via avatar (User Area), not a Bottom Navigation slot. Saved is user state.

---

## 4. Target Bottom Navigation

Target 5 destinations (Travel: current **Home | Encyclopedia | Tools | Saved | Profile** → target **Home | Knowledge | Tools | My Projects | Directory**).

| # | العربية | Target route | Notes |
|---|---|---|---|
| 1 | الرئيسية | `/home` | unchanged root |
| 2 | المعرفة | `/knowledge` | wraps Encyclopedia (Content Studio engine intact) |
| 3 | الأدوات | `/tools` | unchanged root |
| 4 | مشاريعي | `/projects` | FUTURE — added only when ready |
| 5 | الدليل | `/directory` | FUTURE — added only when ready |

Rule: **NOT READY → NOT EXPOSED.** Projects and Directory only occupy slots when their feature readiness flags are ON. No fake tabs, no Coming Soon.

---

## 5. Domain Route Ownership

Every route has **exactly one** owning domain:

| Concept | Owning Domain |
|---|---|
| Topic detail | Knowledge |
| Article detail | Knowledge |
| Concrete / Steel / Masonry / Tile calculator, Checklist, Inspection | Tools |
| Project dashboard & workspace | Projects |
| Supplier / Service / Material / Company profile | Directory |
| Global Search results | Cross-domain Search (aggregator) |
| Edit profile, preferences, backup | User Area |
| Advertisement destination | Monetization (constrained, §16) |

No ambiguous ownership. Cross-domain navigation is via public contracts (§15).

---

## 6. Route Hierarchy / Tree

```
/home                          Home (aggregator; links only, owns no domain screens)
   Home Dashboard
   → /knowledge (quick access)
   → /tools (site tools)
   → /articles (legacy)       [during migration; later /knowledge/articles]
   → /encyclopedia?q=...      (global search entry — see §14)
   → /projects/:projectId     [CONDITIONAL snapshot]
   → sponsored destination    [CONDITIONAL campaign]

/knowledge                    Knowledge (umbrella; wraps Content Studio)
   → /knowledge/encyclopedia (current /encyclopedia content preserved)
   → /knowledge/encyclopedia/categories  (was /categories)
   → /knowledge/topics/:categoryId       (was /encyclopedia/topics/:categoryId)
   → /knowledge/topic/:topicId           (was /encyclopedia/topic/:topicId)
   → /knowledge/articles        (legacy articles; not merged yet)
   → /knowledge/article/:id     (was /article/:id)
   → /knowledge/codes          [FUTURE]
   → /knowledge/references     [FUTURE]

/tools                        Tools
   → /tools/calculators/concrete   (was /calculator/concrete)
   → /tools/calculators/steel      (was /calculator/steel)
   → /tools/calculators/masonry    (normalize `brick`→`masonry` on migration)
   → /tools/calculators/tile       (was /calculator/tile)
   → /tools/checklists             (was /calculator/checklist)
   → /tools/checklists/:categoryId (replaces Navigator.push detail)
   → /tools/converters            [FUTURE]
   → /tools/quick-checks          [FUTURE]

/projects                     My Projects (FUTURE — hidden until ready)
   → /projects (list)
   → /projects/new
   → /projects/:projectId (workspace)
   → /projects/:projectId/overview
   → /projects/:projectId/calculations
   → /projects/:projectId/inspections
   → /projects/:projectId/checklists
   → /projects/:projectId/notes
   → /projects/:projectId/documents
   → /projects/:projectId/materials
   → /projects/:projectId/suppliers
   → /projects/:projectId/reports
   (deep-linkable subsection concept; see §10 decision A/B/C)

/directory                    Directory (FUTURE — hidden until ready)
   → /directory (landing / search)
   → /directory/:type                (one generic type param)
   → /directory/:type/:entityId      (entity detail)
   (material/product may need separate route model — §11 decision)

/user (via avatar, not bottom-nav)   User Area
   → /user/profile           (was /profile)
   → /user/profile/edit      (replaces Navigator.push ProfileEditScreen)
   → /user/saved             (was /saved)
   → /user/downloads
   → /user/activity
   → /user/preferences
   → /user/theme
   → /user/language
   → /user/backup
   → /user/account           (was /auth)

/search (cross-domain)       Global Search
   → /search?q=...&type=...  (aggregated; result routes to owning domain)

Bootstrap (root, not in shell): /splash → /onboarding → /profile-setup → (home | user)
```

Notes:
- Exact route strings are recommendations; the **ownership and nesting** are the contract. Actual names may shift if strong reason.
- Internal screens are NOT top-level routes.
- Choose tabs/sections over over-fragmentation (§10).

---

## 7. Home Navigation

Home is an **aggregator** — it links to ready domains, owns no domain screens.
- Quick Access → Knowledge, Tools, Articles (later Knowledge/Articles), Saved/User area.
- Site Tools → Tools detail.
- Engineering Pick → Knowledge detail.
- Current Project Snapshot → `/projects/:projectId` (CONDITIONAL — user has projects AND Projects ready).
- Sponsored Banner → approved campaign destination (§16, CONDITIONAL).
- Global Search entry → `/search` (or the current search-as-encyclopedia-`?q=` behavior until Search is a real aggregate).

Home must remain fully functional with zero ads and no Projects/Directory.

---

## 8. Knowledge Navigation

Knowledge becomes the umbrella domain; the **encyclopedia engine stays authoritative and rides unchanged underneath** (§24).
- Target hierarchy: Knowledge Landing → Encyclopedia / Articles / (future) Codes & Standards / References.
- Current `/encyclopedia*` routes remain functional during migration (compat, §21).
- **Do NOT prematurely merge Articles and Encyclopedia.** Keep them as separate children under Knowledge until a deliberate consolidation decision (M1 open decision #1).

---

## 9. Tools Navigation

- Calculators/checklists/converters/QA/QC all owned by Tools.
- Normalize `calculator/brick` → `calculator/masonry` **on migration** (content label is masonry), via a compat redirect (§21).
- **Recommendation (not implementation):** replace raw route strings in `ArticleRepository.tools`/`relatedToolRoutes` with a **typed route-reference contract** (e.g. an enum `ToolRoute`) so no feature guesses a private path and content never embeds raw `/calculator/*` strings. `relatedToolRoutes` in content should become typed tool keys, resolved at presentation — never `context.go(rawStringMaybeGarbled)` (see debt note, §2, §18).

---

## 10. Projects Navigation

Target concepts:
```
/projects                    → Project List
/projects/:projectId         → Project Workspace
/projects/:projectId/...     → subsection deep links
```
Decision — workspace layout: choose **B (workspace tabs) + minimal deep links** (combination, not 10 route roots).
- Primary UI: one Project Workspace screen with tabs (Overview / Calculations / Inspections / Checklists / Notes / Documents / Materials / Suppliers / Reports / Activity).
- Deep-linkable subsections to support linking/saving.
- **Recommended:** a small set of stable subsection routes (`/projects/:projectId/checklists`, `/calculations`, `/inspections`, `/reports`) rather than a route per tab; Notes/Documents/Materials/Suppliers/Activity stay tab-state within the workspace (no route explosion).
- `ChecklistScreen`/`ProjectListScreen` currently reached via `Navigator.push` under Tools migrate into `/projects/*` (§2 debt, §13 mapping in screen map M2).

---

## 11. Directory Navigation

Prefer **one reusable directory navigation model** over independent route trees per type:
```
/directory                → landing / search / filters
/directory/:type          → category listing (supplier, contractor, consultant, technician, company, service, shop, material, ...)
/directory/:type/:entityId → entity detail
```
- `:type` is a stable BusinessType-style key (already scaffolded via `BusinessType`), not a translated label.
- Search/filter is preserved via query/state **without route explosion** — no `/directory/service/consultant/...` pyramid.
- **Material/Product detail:** if its entity model diverges from service/company profiles, give it a dedicated detail route (`/directory/material/:id`) but keep it under Directory ownership (§5). Decision documented; deferred.
- Organic vs Sponsored distinction is a **data/query concern**, not different routes (§16): `/directory/:type` returns organic + sponsored segments, visually distinct.

---

## 12. User / Profile Navigation

Long-term access: **Header Avatar → User Area** (not a Bottom Nav slot).
- **Full screens:** Profile, Edit Profile, Backup, Preferences, Settings — they carry real forms; do **not** use modals for these.
- Theme/Language toggles may be inline within Preferences or lightweight sheets — avoid overusing modals.
- Edit Profile replaces the current `Navigator.push(ProfileEditScreen)` bypass with `/user/profile/edit` (§2 debt).
- `/auth` lives under User area (`/user/account`); `/profile-setup` remains a bootstrap **full-screen** route (pre-shell onboarding), not part of the shell.

---

## 13. Saved Navigation

- Saved stores **references to owner-domain IDs** — never duplicate detail routes.
- Saved Topic → `/knowledge/topic/:id`; Saved Article → `/knowledge/article/:id`; (future) Saved Supplier → `/directory/:type/:entityId`; (future) Saved Tool result → Tools/Projects.
- Current `/saved` opens in the shell today; on migration it becomes a **user-state surface** reached from User area (`/user/saved`) and/or Knowledge "Saved knowledge". It never re-implements detail routing.

---

## 14. Global Search Navigation

- Entry: Home/Header Search → Global Search.
- Search aggregates per-domain results: Knowledge, Article, Tool, Project, Company, Supplier, Technician, Service, Material/Product.
- **Selecting a result routes to the item's owning domain detail** — Search does not own destination screens.
- Today's "search" is encyclopedia topic filtering via `/encyclopedia?q=` (knowledge-only). The target `/search` is the aggregate; transitional behavior keeps the current encyclopedia search working (§21).

---

## 15. Cross-Domain Navigation Contracts

Explicit, stable public contracts (no arbitrary private paths):
- Knowledge Topic → related Tool: via typed `ToolRoute` keys (§9), renders Tools detail.
- Tool Result → Save to Project: Tools emits a result; a **cross-domain save contract** hands it to Projects, which stores a reference/snapshot (§Projects boundary, M1). Not implemented.
- Project → linked Supplier/Service: Project workspace links to Directory details via Directory's public entity route (§11).
- Global Search result → owning domain detail (§14).
- Home → entry points into any ready domain (§7).
- Ad destination → Monetization-constrained target (§16).

Any transition not in this list must be reviewed before adding; features must not construct another domain's private route path.

---

## 16. Advertisement Destination Rules

Encouraged **allowed** destination types:
- INTERNAL: Directory entity, Service profile, Material/Product, Sponsored supplier, approved internal promo page.
- EXTERNAL: verified external URL **only if** product policy later permits; gated.
Blocked: ads must **never** masquerade as Knowledge content; an ad must not route to an engineering Topic in a way implying editorial endorsement unless explicitly designed and labeled.
- **No campaign → no route → no visible slot.** Ad slots disappear when no campaign is active (M1 §11 rule).
- Ad destinations are authored as **constrained campaign entities** (allowed-destination allowlist), not free-form URL strings.

---

## 17. Deep-Link Architecture

Future deep-linkable entities: Knowledge Topic, Article, Tool, Project, Directory Entity, Service, Material/Product.
Requirements:
- **Stable IDs, not display names** (Arabic/English labels never enter URLs).
- Entity rename must not break links; paths don't depend on translated text.
- Deep links resolve to owning domain (M3 ownership, §5).
- Auth/permission-gated content redirects safely (no content leak).
- Unavailable/deleted entity → explicit not-found/empty state, not silent Home (§22).

Conceptual deep links (examples):
```
/knowledge/topic/<topicId>
/knowledge/article/<id>
/tools/calculators/<type>
/projects/<projectId>/checklists
/directory/<type>/<entityId>
```
No URL handling implemented.

---

## 18. Route Naming / IDs

- Prefer **stable semantic route names** over scattered string literals.
- Recommendation: a **centralized typed navigation/route contract** (e.g. named route constants or a lightweight `AppRoutes`/`ToolRoute` layer) — but **without a heavy framework**. Goal: no feature guesses another feature's private path.
- `:id` params must be canonical IDs; avoid raw internal strings in content/registry. `relatedToolRoutes` and `tool.route` migration to typed keys is the primary target (§9).

---

## 19. Conditional Feature Navigation

- Feature flag OFF → destination **hidden**, not visible-disabled.
- Projects/Directory enter the Bottom Navigation **only** when ready (§4, §20).
- Conditional visibility: project snapshot (user has projects + Projects ready), ad slots (campaign active), saved/downloads empty states (already present today).
- The migration phases in §20 sequence which destinations become visible and when.

---

## 20. Current → Target Transition Plan (no big bang)

Recommended safe sequence (each phase is independently shippable and reversible; NOTHING is scheduled now):

| Phase | Change | Condition |
|---|---|---|
| **NAV-0** | Current production navigation unchanged | — |
| **NAV-1** | Encyclopedia evolves into Knowledge: add `/knowledge` root as a wrapper that surfaces Encyclopedia content (existing `/encyclopedia*` routes temporarily compat-registered or the `/knowledge` branch hosts the same screens). Old routes redirect. | When Knowledge umbrella is designed enough to host Encyclopedia + Articles children |
| **NAV-2** | Profile moves to avatar when User Area is ready; `/profile` tab removed, `/user/profile` becomes avatar target. | User Area feature ready |
| **NAV-3** | Saved moves into User/Knowledge access; `/saved` tab removed, reachable from user area / Knowledge saved. | After User Area; Saved becomes user state |
| **NAV-4** | Projects enters a Bottom Navigation slot **only when Projects is ready** — replaces the freed slot (post NAV-2/3) not a 6th tab. | Projects feature flag ON |
| **NAV-5** | Directory enters Bottom Navigation **only when ready** — replaces the next freed slot. | Directory feature flag ON |
| **NAV-6** | Global Search aggregate + constrained ad navigation. | Search/monetization ready |

A staged sequence avoids a "big bang" rewrite. Each removal of a legacy tab/route pairs with its compat redirect (§21).

---

## 21. Backward Compatibility

- Old route → **redirect/compat layer → canonical route** where justified (GoRouter redirect).
- Do NOT delete old routes in M3.
- Specific cases: `/encyclopedia/topic/:id` → `/knowledge/topic/:id`; `/article/:id` → `/knowledge/article/:id`; `/calculator/brick` → `/tools/calculators/masonry`; `/categories` → `/knowledge/encyclopedia/categories`; `/calculator/checklist` → `/tools/checklists`.
- Preserve old behavior for callers that still reference old paths during migration: Home, Saved, tools registry, articles, tests, deep-link assumptions, content-related fields (e.g. `relatedToolRoutes`).
- Content fields that embed legacy `/calculator/*` strings should be consumed through the typed contract during migration (owner decision; §9, §18).

---

## 22. Error / Not-Found Navigation

Documented behavior per case (avoid silent Home fallback where a meaningful state is better):
- **Invalid/deleted ID** → owning-domain not-found/empty surface.
- **Disabled feature** → destination not exposed at all (flag OFF, §19); if deep-linked, a "not available" state (not a blank tab).
- **Missing project** → Project-NotFound with option to return to project list.
- **Missing directory entity** → Directory empty/not-found state.
- **Unauthorized** → safe redirect to auth with return-path (no content leak).
- **Malformed deep link** → global `NotFoundScreen` (as today via errorBuilder), with a clear "back" not an automatic fake Home bounce.
- `/articles/:category` (no producer): if kept, treat like a real route with an empty/articles state; if not used, DEPRECATE LATER — **OWNER DECISION** (it currently routes to `ArticlesScreen`, which nothing reaches).

---

## 23. Admin Navigation Separation

- Admin/business ops (**campaign admin, directory moderation, verification management, feature-flag admin**) do **NOT** live inside the 5-tab engineer AppShell.
- Documented concept only: a separate **Admin Surface** (separate app or web) with its own navigation (moderation queue, verification, campaign management, analytics, feature flags). No routes in the engineer app.
- Existing empty scaffold `lib/features/admin/*` supports this future split; keep it separate.

---

## 24. Content Studio Protection

- No navigation decision turns generated content into route ownership/source of truth.
- Knowledge navigation **consumes IDs** exposed by the established encyclopedia pipeline; it never re-derives content.
- Authoritative pipeline unchanged: Content Studio → Draft JSON → Export → App Ready JSON → Generated Catalog → Data Source → Repository → Provider → Presentation.
- Generated files remain outputs; no content/schema/export changes; no route strings added to generated content as navigational facts (typed keys instead).

---

## 25. Open Decisions

1. **Knowledge route prefix** — exact canonical naming (`/knowledge/*` vs preserving `/encyclopedia/*` with a Knowledge wrapper). Migration detail.
2. **`calculator/brick` → `calculator/masonry`** rename timing and redirect (content label is masonry).
3. **`/articles/:category`** — reachable or deprecate (currently no producer, routes to `ArticlesScreen`). OWNER DECISION.
4. **Workspace subsection routes** — exact subset of `/projects/:id/*` deep links (recommend checks/calculations/inspections/reports) vs all tabs.
5. **Directory `:type` set + material/product** separate detail route decision.
6. **Typed route-contract shape** — how far to centralize (`AppRoutes` constants vs enum `ToolRoute`), avoiding over-engineering while removing path guessing.
7. **`relatedToolRoutes` / `tool.route`** — migrating content-embedded raw paths to typed keys (touches content pipeline consumers; DEFERRED, touches generated content so requires separate approval).
8. **Mojibake in `_buildRelatedToolsSection` labels** (`topic_detail_screen.dart` `toolNames` map shows garbled Arabic) — separate content/UI fix, not navigation; flagged for ownership.

---

## 26. Non-Negotiable Navigation Rules

1. One owning domain per route. 2. NOT READY → NOT EXPOSED (no fake tabs). 3. Nested detail routes under their domain, no top-level route per internal screen. 4. Profile/Saved leave the Bottom Navigation on migration (avatar + user state). 5. Cross-domain transitions through stable public contracts only. 6. Ads never masquerade as Knowledge and never route to editorial-endorsed Topics unless explicitly designed/labeled; no campaign → no slot/route. 7. Deep links use stable IDs, never translated labels. 8. Old routes gain compat redirects, never instant removal during migration. 9. Generated content is never route/source-of-truth. 10. Content Studio stays authoritative. 11. Avoid a big-bang navigation rewrite (staged NAV-0…6). 12. No No-OP god router/services; keep boundaries testable.

---

## Requirements Traceability (M3)

Covered: top-level nav (§3–4), route ownership (§5), nested nav (§6), deep-links (§17), internal/detail nav (§6), conditional visibility (§19), user/profile access (§12), search entry/results (§14), project nav (§10), directory nav (§11), ad destination rules (§16), current-inventory + Navigator.push bypasses (§2), transition plan (§20), backward compat (§21), error/empty nav (§22), admin separation (§23), Content Studio protection (§24), route IDs/typed contract (§18), feature flags (§19), no-fake-unfinished-features (§4, §19, §26).

---

## Protected / Forbidden (unchanged)

ZERO production changes. This phase created exactly one file: `docs/architecture/CIVILPEDIA_NAVIGATION_ARCHITECTURE.md`. No changes to `lib/**`, `test/**`, `assets/**`, `draft_jsons/**`, `app_ready_jsons/**`, Content Studio, exporters, schemas, generated catalogs, `pubspec.yaml`, or branding. M1/M2 docs were not modified (no contradiction requiring correction).
