# CIVILPEDIA — IMPLEMENTATION READINESS & GAP ANALYSIS
## (M8 Roadmap)

**Phase:** M8 — Architecture / Planning ONLY
**Status:** Draft for owner review (NOT committed)
**Scope:** Converts approved M1–M7 architecture into a practical, atomic implementation roadmap.
**Constraint:** No production code changes. Only this document is created/edited.

---

## 1. PURPOSE

M1–M7 agreed *where* Civilpedia must go. M8 agrees *how to get there without breaking what works*.

> ### ★ MASTER PLANNING COMPLETION
> **M1–M8 now constitute the approved Civilpedia Master Architecture and Implementation Roadmap.**
> **General Master Planning is COMPLETE.**
> Future architecture work should be **feature/phase-specific only** unless implementation exposes a real contradiction.
> **Execution model from now on:** Phase ID → implementation prompt → implementation → tests → visual QA when UI changes → architect review → atomic commit.
> **No M9 or another generic Master Planning phase will be added.**

The roadmap answers:

- What already exists and should be **KEPT**?
- What should be **WRAPPED** behind cleaner contracts?
- What should be **MIGRATED** gradually?
- What genuinely needs to be **ADDED**?
- What should remain **COMPATIBILITY / DEPRECATED LATER**?
- What must **NOT be touched yet**?
- What are the genuine **BLOCKERS** before each target domain can launch?
- In what **order** should implementation happen to minimize risk, rework, and AI-agent context cost?

The non-negotiable evolution rule (fixed in stone):

> **NO BIG-BANG REWRITE.**
> Current working implementation → introduce contract/target boundary → migrate ONE consumer at a time → verify → preserve compatibility → retire old path ONLY after proof.
> NEVER: delete old system → rebuild target → hope migration works.

---

## 2. APPROVED ARCHITECTURE BASELINE

Authoritative (read-only) source documents:

| Doc | Focus |
|-----|-------|
| M1 `CIVILPEDIA_PRODUCT_ARCHITECTURE.md` | Product vision, pillars, user areas, roles, WIP status |
| M2 `CIVILPEDIA_SCREEN_MAP.md` | Screen map, navigation model, branches |
| M3 `CIVILPEDIA_NAVIGATION_ARCHITECTURE.md` | GoRouter strategy, bottom-nav target, route contracts |
| M4 `CIVILPEDIA_DATA_OWNERSHIP_AND_DOMAIN_CONTRACTS.md` | Domain ownership, contracts, 2 known blockers |
| M5 `CIVILPEDIA_PROJECTS_ARCHITECTURE.md` | Projects V1/V1.5, restore V1, calc records, checklist executions |
| M6 `CIVILPEDIA_DIRECTORY_AND_SERVICES_ARCHITECTURE.md` | Directory V1, 5-state VerificationStatus, `sb_profiles` compat |
| M7 `CIVILPEDIA_SEARCH_SAVED_OFFLINE_USER_ARCHITECTURE.md` | Global Search V1, Saved/User, Offline ownership, Backup |

Also present: `ENCYCLOPEDIA_LEGACY_COMPATIBILITY.md` (content/compat reference for the encyclopedia; treated as read-only guidance, not a domain arch doc).

**Ownership invariants carried forward (must not be violated by any phase):**
- Tools owns formulas + templates.
- Projects owns records/snapshots/notes (NOT a cache; local-first authoritative).
- Directory owns business entities + verification (offline = cache/projection only).
- Monetization owns sponsorship/campaign; **sponsored ≠ second entity**.
- User owns profile/preferences/saved refs/recent-activity metadata/pointers — never Projects/Topics/Suppliers/Tools/Ads.
- Knowledge/Tools content is owned by the content pipeline / Tools — never duplicated into User/Saved.

**Approved hidden-until-ready rule:** Projects / Directory / Global Search stay hidden until their minimal V1 exists. No fake tabs, empty screens, or "Coming Soon".

---

## 3. CURRENT CODEBASE SNAPSHOT

Verified against the live repository (this is the ground truth M8 classifies).

### 3.1 App shell & navigation
- **GoRouter** in `lib/routes/app_router.dart` (~130+ lines) declares top-level routes and a 5-destination **ShellRoute** (the current Bottom Navigation branches).
- Top-level routes: `/splash`, `/onboarding`, `/profile-setup`, `/auth`, `/categories`, `/encyclopedia/topics/:categoryId`, `/encyclopedia/topic/:topicId`, the 5 shell destinations, `/articles`, `/articles/:category`, `/article/:id`, and `/calculator/{concrete,steel,brick,checklist,tile}`.
- **Route strings are duplicated across raw string literals** in call sites (`context.push('/article/${id}')`, `context.go('/encyclopedia')`, etc.).
- **`Navigator.push` bypasses** (imperative, outside GoRouter) exist at: `profile_screen.dart:444,464` (Profile edit), `checklist/project_list_screen.dart:194`, `checklist_screen.dart:198,272`.
- `not_found_screen.dart` falls back to `context.go('/home')`.

### 3.2 Home
- `home_main_screen.dart` composes: search bar, categories, quick access, quick tools, engineering topics, latest articles.
- Search routes to `/encyclopedia?q=` (existing flow, **not** a global aggregator).
- **Ads: `LocalAdDataSource` always returns mock ads** (BLOCKER − M4 §27 documents the target `AdPlacementRequest → Monetization → active campaign → SponsoredPlacement`).
- **Global Search not implemented** beyond encyclopedia query forwarding.
- **No Project projection** on Home yet.
- Home layout still has approved future polish work (D9 dark etc.) — out of scope to redesign.

### 3.3 Knowledge / Encyclopedia
- Content pipeline (Content Studio → convert/export → generated catalog) is strong and **KEEP / DO NOT TOUCH**.
- Category, TopicList, TopicDetail, Articles exist and work. `ArticleRepository` is **legacy/static** content (categories, tools, articles hardcoded) living alongside the newer encyclopedia pipeline.
- Saved/favorites integrated via Hive box `civilpedia` keys `favorites` + `encyclopediaFavorites`.
- **`relatedToolRoutes`** = raw route strings in `EngineeringTopic` content, rendered by `context.go(route)` in `topic_detail_screen.dart:949–954`. **BLOCKER (M4)**. Tool route strings also hardcoded in `ArticleRepository` `ToolModel.route`.
- **Arabic currently forced** (BLOCKER group; `tr(ar,en)` helper pattern used throughout; LanguageProvider exists but the app-localized strings default to Arabic).

### 3.4 Tools
- Calculators: concrete, steel, brick, tile — strong, working, canonical shared primitives (`ConcreteVolumeCalculator`, `SteelWeightCalculator`, `MasonryQuantityCalculator`). **KEEP**.
- Checklist: `checklist_data` key; `checklist_project_<id>` per-project key; multiple-execution capable; inspection cards.
- Registry: tools list in `ArticleRepository.tools` with `route` strings pushed via `/${tool.route}`; also `quick_tools_section` / `tools_screen` consume this.
- **Projects currently nested under Tools** (checklist `project_list_screen.dart`, project-based checklist) — **MIGRATE later**, keep working meanwhile.
- **Save-to-project / Calculation Records / Notes are NOT implemented** (ADD).

### 3.5 Projects (seed)
- Project entity + repository exist as a **seed** nested under Tools (`checklist/project_list_screen.dart`).
- SharedPreferences keys: `projects_list`, `checklist_data`, `checklist_project_<id>`.
- Backup interplay: BackupService must preserve these keys (see §12).
- Restore lifecycle (Archive/Restore) is **V1-approved but not present** in seed (ADD).
- Attachments/Photos/Documents **deferred to V1.5** (per M5).

### 3.6 Directory (seed)
- `ServiceBusinessProfile`, `BusinessType` (12), `VerificationStatus{unverified,pending,verified,rejected}`, `BaghdadArea` (24) exist.
- SharedPreferences key `sb_profiles` (single-key JSON store).
- `FeatureKey` / `plan_tier` / `plan_type` scaffolding gates `connectListing`, `sponsoredListing`, `supplierProfile`, `companyProfile`, `dashboardAccess`.
- DI wiring: `businessRepo` wired but **unused**; auth repos **not wired**.
- **No Directory UI** (no listing, detail, contact, verification display, save provider). Entire Directory is presently HIDDEN (correct).
- M6 requires **5-state VerificationStatus** (`+suspended`) and `rejected ≠ suspended` — code still has 4 states (migration/compat work needed).
- Directory seed currently **plan-coupled** to monetization scaffolding (`sponsoredListing`, etc.) — must be de-coupled for V1 (BLOCKER/debt).

### 3.7 User / Saved / Offline
- Saved screen (`saved_screen.dart`) 2-tab (Favorites/Downloads) — works today; multi-store model (`favorites`, `encyclopediaFavorites`, `downloads`, `offline_$id`).
- Hive box `civilpedia` (`hive_helper.dart`).
- SharedPreferences `local_user_profile`, `isDarkMode`, `onboardingSeen`, `auth_email`/`auth_name`/`register_$email`.
- `ThemeProvider`, `LanguageProvider`, `AuthProvider`, `BackupService`, `ConnectivityProvider` exist.
- **BackupService partial restore (`TODO(BACKUP-1C)`)** — BLOCKER for offline/backup expansion.
- Profile currently a **Bottom Navigation branch**; target = avatar/User Area (future).

### 3.8 Design system
- `lib/core/theme/...` + shared primitives (AppColors/DesignTokens/AppSpacing) exist and are the **canonical vocabulary**.
- **`CustomCard` is an active legacy/duplicate** (22 usages across calculators, saved, articles, tools) coexisting with the design system.
- Duplicate category styling across Home/Encyclopedia sections.
- Remaining presentation/visual debt noted in M1.

### 3.9 Tests
- Existing unit + widget tests (topic_detail_d3b, app_shell, home_categories, home_latest_articles, etc.). Baseline must be preserved.

---

## 4. GAP CLASSIFICATION METHOD

Every current major component is placed into **exactly one primary action**:

| Action | Meaning | Typical trigger |
|--------|---------|-----------------|
| **KEEP** | Valid enough; leave working | Strong, stable, canonical |
| **WRAP** | Keep impl; expose via clearer domain contract later | Correct logic, leaky access |
| **MIGRATE** | Responsibility/ownership moves gradually, behavior preserved | Under wrong domain fold |
| **ADD** | Missing capability the target architecture requires | No impl exists |
| **CONSOLIDATE LATER** | Overlap exists; not safe/needed to merge before rollout | Duplicate but harmless |
| **DEPRECATE LATER** | Keep verified old path during compat window, retire after proof | Legacy, still used |
| **DO NOT TOUCH YET** | Refactor risk > benefit now | Sensitive/unnecessary |

**BLOCKER rule:** use `BLOCKER` **only** when a target domain's launch genuinely depends on resolving it. Everything else is debt/deferred — do **not** overclassify.

---

## 5. HOME GAP ANALYSIS

**Role (M1):** aggregator surface, not a data owner.

| Dimension | Status | Notes |
|-----------|--------|-------|
| Product readiness | PARTIAL | Serves current 5-branch app; not yet aggregator |
| Data readiness | PARTIAL | Consumes some legacy/static data (`ArticleRepository`) |
| Repository/ds readiness | PARTIAL | Mixed legacy + encyclopedia datasource |
| Navigation readiness | PARTIAL | Search→`/encyclopedia?q=`; target `/search` global search |
| UI readiness | PARTIAL | Layout valid; final polish deferred |
| Persistence/migration | N/A | Home stores nothing |
| Testing | READY | home_categories, home_latest_articles tests exist |
| Offline | PARTIAL | Live refresh; packaged knowledge offline |
| Privacy/security | N/A | |
| Admin/backend | N/A | |

**Must happen before Home serves the final platform:**
1. Global Search V1 exists at `/search` → Home search delegates to it (WRAP not rewrite).
2. Ads: mock always-on → **no campaign ⇒ no ad ⇒ no blank slot** (§13).
3. Project projection added only after Projects V1 exists (not before).
4. Legacy `ArticleRepository` usage on Home becomes read-compatible-backed or folded into the encyclopedia provider (CONSOLIDATE later; not a Home-blocker).

**Do NOT redesign Home UI.**

**Action:** WRAP / MIGRATE (search + data source), ADD (aggregator projection).

---

## 6. KNOWLEDGE GAP ANALYSIS

**Role (M1/M4):** Knowledge owns content; pipeline is sacred.

**Knowledge umbrella (approved):** Knowledge remains the approved **TARGET** domain. Current Encyclopedia remains **production-valid**. Do **NOT** require an immediate `/encyclopedia → /knowledge` migration. Approved order: **logical/domain alignment → required public contracts/projections → later navigation migration → compatibility redirects → eventual legacy retirement**. W1 must NOT become an Encyclopedia rewrite.

| Dimension | Status | Notes |
|-----------|--------|-------|
| Product readiness | READY | Core encyclopedia strong |
| Data/domain readiness | READY | Content pipeline healthy |
| Repository/ds readiness | PARTIAL | Legacy `ArticleRepository` coexists |
| Navigation | READY | Topic/Category/Article routes fine |
| UI readiness | READY | |
| Persistence/migration | PARTIAL | favorites/encyclopediaFavorites dual-store |
| Testing | READY | topic_detail_d3b, etc. |
| Offline | READY | packaged knowledge |
| Privacy/security | N/A | |
| Admin/backend | N/A | |

**What is strong and MUST NOT be rewritten:** the Content Studio pipeline, generated catalog, encyclopedia provider stack, canonical calculators' primitives, Topic/Category/Article screens.

**Gaps:**
- `relatedToolRoutes` raw-string content linkage (BLOCKER, deferred via Content Studio migration gate §15bis).
- Legacy `ArticleRepository` duplication → CONSOLIDATE LATER / DEPRECATE LATER.
- Dual Saved store → §11.

**Action:** KEEP (pipeline/screens), CONSOLIDATE LATER (legacy repo), DEFER (content studio gate).

---

## 7. TOOLS GAP ANALYSIS

**Role (M4):** Tools owns formulas + templates. Calculators are canonical primitives (KEEP).

| Dimension | Status | Notes |
|-----------|--------|-------|
| Product readiness | READY | Calculators + checklist work |
| Data/domain readiness | READY | Formulas canonical |
| Repository/ds readiness | PARTIAL | Tool registry = raw route strings in `ArticleRepository`; pushes via `/${tool.route}` |
| Navigation | PARTIAL | 5 calculator routes; raw strings; some `Navigator.push` bypasses in checklist |
| UI readiness | PARTIAL | Heavy `CustomCard` usage (visual debt only) |
| Persistence/migration | PARTIAL | `checklist_data`, `checklist_project_<id>` |
| Testing | READY | Calculator primitives testable |
| Offline | PARTIAL | Local tools fine offline |
| Privacy/security | N/A | |
| Admin/backend | N/A | |

**Do NOT require calculator visual migration before platform work** unless technically necessary. Calculators stay.

**Gaps (V1):** Save Calculation payload → Projects records (ADD); Calculation History (ADD); Notes (ADD); tool identity contract (typed `ToolKey`) to replace raw route strings (WRAP/MIGRATE, staged); Projects-under-Tools migration (MIGRATE later, keep working).

**Action:** KEEP (calculators, primitives), WRAP (tool identity/registry → `ToolKey`), MIGRATE (Projects out), ADD (save-to-project).

---

## 8. PROJECTS V1 GAP ANALYSIS

**V1 approved scope (M5):** Project List, Create, Edit, Archive, Restore, Overview, Save Calculation, Calculation History, Checklist Executions (multiple), Notes.
**V1.5 (deferred):** Attachments, Inspections, Materials, Supplier/Service links, Current Project selection.

| V1 item | Current | Gap | Action |
|---------|---------|-----|--------|
| Project List | Seed under Tools (`project_list_screen.dart`) | Split from Tools; own nav entry later | MIGRATE |
| Create | Seed (list add) present | Formalize entity+validation | WRAP |
| Edit | Seed partial | Formalize | WRAP |
| Archive | MISSING | ADD V1 | ADD |
| Restore | **MISSING** (V1-approved restore lifecycle) | ADD with legacy storage compat | ADD |
| Overview | MISSING beyond list | ADD | ADD |
| Save Calculation | MISSING | Snapshot contract M4/M5 | ADD (dep: calc snapshot contract) |
| Calculation History | MISSING | ADD | ADD |
| Checklist Executions | Seed per-project (multi) | Keep; formalize records | KEEP → WRAP |
| Notes | MISSING | ADD (user-owned record) | ADD |
| Attachments/Photos/Docs | — | V1.5, DO NOT build now | DEFER |

**Migration gates (keys):** `projects_list`, `checklist_project_<id>` → **READ-COMPAT FIRST**, then DUAL-READ/WRITE, then Projects-domain canonical owner. `checklist_data` stays Tools-owned (generic checklist); `checklist_project_<id>` becomes project-owned record.

**Status of dimensions:** product PARTIAL→READY (scope defined), data PARTIAL (seed), repo PARTIAL, nav MISSING (hidden until ready), UI PARTIAL, persistence PARTIAL (migration needed), testing PARTIAL, offline READY (local-first), privacy N/A, backend N/A.

**Action:** MIGRATE + ADD. Hidden until V1 minimal path complete.

---

## 9. DIRECTORY V1 GAP ANALYSIS

**V1 approved (M6):** Landing, Categories, Search, location/category filter, provider listing, provider detail, contact, verification display, save provider.

| V1 item | Current | Gap | Action |
|---------|---------|-----|--------|
| Landing | MISSING | ADD | ADD |
| Categories | `BusinessType` (12) exists | Build category UI | ADD |
| Search | MISSING | ADD (Directory-local) | ADD |
| Location/category filter | `BaghdadArea` (24) exists | Build filter UI | ADD |
| Provider listing | MISSING UI | ADD | ADD |
| Provider detail | MISSING | ADD | ADD |
| Contact | MISSING | ADD | ADD |
| Verification display | `VerificationStatus` 4-state | Extend to 5-state M6; display | MIGRATE + ADD |
| Save provider | MISSING (User-owned ref) | ADD via Saved reference | ADD |

**Seed usefulness (M6):** `ServiceBusinessProfile`, `BusinessType`, `BaghdadArea`, `sb_profiles` single-key store are **useful seeds** — WRAP behind a Directory repository, do not discard.

**Critical de-coupling (M6 BLOCKER):** Directory seed is **plan-coupled** (`FeatureKey.sponsoredListing`, `planType`) to Monetization. For V1 Directory must be buildable **without** gated/sponsored scaffolding; sponsorship/featured become **non-core compat/migration-only** until Monetization is finalized.

**Must remain hidden until Directory production-ready:** all Directory UI (no fake/empty screens). Search/Global Search hides Directory until its V1 search exists.

**Action:** WRAP + ADD + MIGRATE (5-state), de-couple from plan scaffolding. Hidden until ready.

---

## 10. GLOBAL SEARCH GAP ANALYSIS

**V1 scope (M7):** Knowledge + Tools **only**. Do NOT wait for Projects/Directory search.

**Navigation (approved):** Global Search is a dedicated full-screen at **`/search`** — it is **NOT a Bottom Navigation tab**. Entry: Home / Header / approved future entry points → `/search`; result selection → owning domain's canonical destination; back → originating navigation context. **Search owns no detail screens.**

| Dimension | Status | Notes |
|-----------|--------|-------|
| Product readiness | PARTIAL | Home search→encyclopedia only |
| Data/domain readiness | MISSING | No aggregated result model |
| Repository/ds readiness | PARTIAL | Good per-domain sources to reuse |
| Navigation | MISSING | No search route/shell (`/search`) |
| UI | MISSING | Reuse presentational `SearchBarWidget` |
| Persistence/migration | N/A | Index is a search-internal cache, not owner |
| Testing | MISSING | Aggregator + result model + failure isolation tests |
| Offline | PARTIAL | Local Knowledge index |
| Privacy/security | N/A | |
| Admin/backend | N/A | |

**Reusable:** presentational `SearchBarWidget`, existing Knowledge/Tools lookup logic, Hive-backed local index infra.
**Missing:** aggregator shell, unified `SearchResult` model (typed `SearchResultType/route`), route resolver, per-domain failure isolation (one failing domain must not break global search).

**Action:** ADD (aggregator V1 at `/search`), WRAP (reuse existing search). Independent of Projects/Directory. Not a Bottom Navigation tab.

---

## 11. SAVED / USER GAP ANALYSIS

**Role (M7):** User owns Saved references, profile, preferences, recent-activity metadata/pointers — never domain entities.

**Navigation (approved):** Final target = **Avatar → `/user`** — `/user` is a full **User Area / hub** screen (NOT a modal/bottom-sheet). Nested routes are intentional, e.g. `/user/profile`, `/user/profile/edit`, `/user/saved`, `/user/downloads`, `/user/preferences`, `/user/theme`, `/user/language`, `/user/backup`, `/user/account`. Do NOT make a modal/bottom-sheet the primary User Area navigation.

| Item | Current | Gap | Action |
|------|---------|-----|--------|
| Saved screen | 2-tab (Favorites/Downloads) | Multi-store model; works | WRAP → canonical Saved reference resolver |
| Encyclopedia favorites | Hive key | Merge/route to canonical | CONSOLIDATE LATER |
| Legacy favorites/downloads | Hive keys | Preserve compat, migrate | READ-COMPAT FIRST |
| Profile | Bottom-nav branch (profile_screen) | Keep working; target Avatar→`/user` later | KEEP → WRAP |
| Preferences | Profile screen (edit) | Navigate via `Navigator.push` (bypass) → route it | MIGRATE/WRAP |
| Theme/Language | Providers exist | Keep | KEEP |
| Backup | BackupService | Partial restore blocker | FIX (see §12) |

**Migration gates before Saved/Profile can leave Bottom Navigation:**
- Canonical single Saved-reference resolver exists.
- Old keys (`favorites`, `encyclopediaFavorites`, `downloads`) read-compat + migrate; **never rename/delete**.
- User Area (Avatar→`/user`) exists to absorb profile.
- Saved clearly reachable elsewhere (via `/user/saved`, `/user/downloads`) and migration verified.

**Action:** WRAP (Saved resolver), KEEP (providers), CONSOLIDATE LATER (dual stores).

---

## 12. OFFLINE / BACKUP GAP ANALYSIS

**Role (M7):** User owns profile/preferences/Saved refs/Project records. Packaged Knowledge = app data (not cache, not user data). Directory offline = cache/projection. Ad cache = nothing.

| Item | Current | Gap | Action |
|------|---------|-----|--------|
| Packaged Knowledge | Available offline | Correct classification in docs only | KEEP (no change) |
| Local Tools (calculators/checklist) | Local | Works | KEEP |
| Projects local-first | Seed keys | Ensure backup preserves records | MIGRATE/backup |
| Downloads | `downloads` key | Reference vs artifact | WRAP |
| **Backup completeness** | BackupService | **Partial restore `TODO(BACKUP-1C)`** | **FIX before project/user data expands** |
| Restore | Partial | Complete restore + version/validation | ADD |
| Migration | Partial | Versioned migration | ADD |

**Blockers that must be fixed before Project/User data expands:** full (non-partial) Backup restore, backup versioning, and deterministic backup/restore of `projects_list`, `checklist_project_<id>`, `local_user_profile`, Saved refs, preferences. Downloaded Knowledge artifacts **re-acquired** rather than primary backup data (M7). Search index, Directory cache, ad cache are NOT backed up.

**Action:** FIX (backup restore completeness) + ADD (versioning). This is a WAVE-0 foundation, not deferred.

---

## 13. MONETIZATION / ADS GAP ANALYSIS

**Rule (M4/M6):** `no campaign ⇒ no ad ⇒ no blank slot`. Home is complete with zero ads.

| Item | Current | Gap | Action |
|------|---------|-----|--------|
| Ads | `LocalAdDataSource` always mock | Remove always-mock; return none when no campaign | **FIX/REMOVE mock** (BLOCKER) |
| Ad UI | Ad slot present | Slot renders only when campaign exists | WRAP |
| Campaign contract | M6 documented `AdPlacementRequest→Monetization→SponsoredPlacement` | Not implemented (fine — future) | DEFER |
| Directory sponsorship | Seed plan-coupled | Must NOT gate Directory V1 | DE-COUPLE |

**Exact readiness blocker before real monetization:** `LocalAdDataSource` must stop fabricating ads and return **no placement** when no active campaign exists. Everything Monetization (campaigns, sponsored placements, paywall/plan architecture) is **speculative and deferred** (DO NOT TOUCH YET). Directory V1 must not depend on it.

**Action:** FIX (mock ads) now as foundation; DEFER all real monetization.

---

## 14. FORMAL BLOCKER REGISTER

Only genuinely-blocks-launch items. Everything else is debt (see §15).

| ID | Domain(s) | Problem | Evidence | Blocks | Risk | Must Fix Before | Recommended Phase |
|----|-----------|---------|---------|--------|------|-----------------|-------------------|
| B-01 | Knowledge / Tools | `relatedToolRoutes` are raw route strings in content, rendered via `context.go(route)` | `engineering_topic.dart:46`, `topic_detail_screen.dart:949–954`, `ArticleRepository` `ToolModel.route` | **Retirement of raw navigation/content routes** (typed route contract must supersede them) | Link rot on renamed routes; breakage | **Raw route retirement** (NOT Global Search V1 — a Flutter-side resolver already unblocks V1) | W2 resolver; raw-route retirement via Content Studio migration gate |
| B-02 | Monetization | `LocalAdDataSource` always returns mock ads | `home/data/datasources/ad_data_source.dart` | **REAL Monetization** (campaign-gated placements) | Fake ads shown; blank-slot rule broken | **Real Monetization** (NOT other Home/platform work) | W0 (remove always-mock) |
| B-03 | Offline / Backup / Projects | Backup restore partially implemented | `backup_service.dart` `TODO(BACKUP-1C)` | **My Projects V1 becoming production-ready** (new persistent project history must not expand while restore incomplete) | Silent data loss on restore | **My Projects V1 production-readiness** | W0 (foundation) |
| B-04 | Directory | Seed is plan-coupled to Monetization scaffolding | `FeatureKey.sponsoredListing`, `planType` on seed; M6 non-core note | **Directory V1 production launch** | Directory blocked by unrealized monetization | **Directory V1 production launch** | W0 (de-couple contract) |
| B-05 | Directory | `VerificationStatus` still 4-state, no `rejected≠suspended` | `service_business_profile.dart` | **Directory persistence/model migration** (safe 5-state storage evolution) | Wrong semantics / non-migratable store | **Directory persistence/model migration** (NOT Directory V1 UI) | W0 (contract) |

> **Scope precision (owner-confirmed):** each blocker is paired to its exact gating boundary and is explicitly **not** a blocker for unrelated work:
> - B-01 gates only the *retirement* of raw routes — Global Search V1 ships via a Flutter-side resolver.
> - B-02 gates only *real Monetization* — other Home/platform work proceeds regardless.
> - B-03 gates only *My Projects V1 production-readiness* (persistent history must not expand under a broken restore) — other work unaffected.
> - B-04 gates only *Directory V1 production launch*.
> - B-05 gates only *Directory persistence/model migration*, not Directory V1 UI (UI may be built against a forward-compatible model).

> **Note on B-04/B-05:** M6 allows Directory to remain completely hidden until production-ready; these are true launch blockers only when Directory V1 is being built. B-04 de-coupling is de-risked by doing contract groundwork in W0 without touching Directory UI.

---

## 15. TECHNICAL DEBT TRIAGE

Classify all M1–M7 debt.

| Debt | Class | Notes |
|------|-------|-------|
| `LocalAdDataSource` always-mock | **FIX BEFORE EXPANSION** | Blocker B-02 (gates real Monetization only) |
| Partial Backup restore | **FIX BEFORE EXPANSION** | Blocker B-03 (gates My Projects V1 production-readiness only) |
| `Navigator.push` bypasses (profile:444,464; project_list:194; checklist:198,272) | FIX WHEN TOUCHING FEATURE | Route them when editing those screens; not standalone |
| Raw route strings in call sites | FIX WHEN TOUCHING FEATURE | Route contract W0; audits as touched |
| `relatedToolRoutes` raw content | **CONTENT STUDIO GATE** | See §15 note; not direct file edit |
| Tool registry raw route strings (`ArticleRepository`) | FIX WHEN TOUCHING FEATURE | `ToolKey` contract |
| `CustomCard` duplicate vocabulary | DEFER | Visual debt; migrate when screens touched; not blocker |
| Duplicate category styling | DEFER | Presentation debt |
| `AuthRepositoryImpl` orphan (auth repos not wired) | FIX WHEN TOUCHING FEATURE | Wire or leave documented |
| `businessRepo` wired but unused | FIX WHEN TOUCHING FEATURE | Consume in Directory V1 |
| Empty scaffolds / hidden screens | KEEP HIDDEN | Do not fill with fakes |
| Forced Arabic | FIX WHEN TOUCHING FEATURE / KEEP | Default Arabic; LanguageProvider exists; not a launch blocker |
| `ArticleRepository` legacy static content | CONSOLIDATE LATER / DEPRECATE LATER | Read-compat; retire after proof |
| `favorites`/`encyclopediaFavorites` dual Saved store | CONSOLIDATE LATER | Canonical Saved resolver then migrate |
| Theme aliases | DEFER | Cosmetic |
| Directory plan-coupling | **FIX BEFORE EXPANSION (Directory)** | Blocker B-04 |

**Be conservative:** each blocker gates only its precise boundary — B-02/before real Monetization, B-03/before My Projects V1 production-readiness, B-04/before Directory V1 production launch, B-05/before Directory persistence/model migration, B-01/before raw-route retirement. Everything else rides along with feature work or is deferred.

---

## 15bis. CONTENT STUDIO MIGRATION GATE (relatedToolRoutes)

**Explicit timing decision (approved migration order):**
1. Current raw `relatedToolRoutes` (unchanged for now)
2. → **Flutter compatibility resolver** (compat layer; ships in W2 so Global Search V1 can launch)
3. → stable **`ToolKey` / `ToolDestination` contract**
4. → consumers migrate to the **typed identity**
5. → dedicated future **Content Studio migration** (schema/editor/export support)
6. → **Draft-source migration**
7. → **export** → **Preview/Flutter verification**
8. → **raw route retirement**

**Rules:**
- **Generated catalogs are NEVER migration sources.**
- **Content Studio migration is NOT required for Global Search V1.**
- This is the safest, lowest-risk path: B-01 remains a blocker for raw-route retirement only, not for Global Search V1.

**Full Content Studio migration path (only if typed `ToolKey` is ever required in content):**
Content Studio authoring/source → schema/editor/export support → compat parser/resolver → Draft migration → export → Flutter consumption → verify Preview/Flutter → **only then** retire raw `relatedToolRoutes`.

**Recommendation:** For V1, **defer** the Content Studio schema change. Use a thin Flutter-side route resolver so no content damage. Revisit only if typed tool identity in content becomes a hard requirement.

---

## 16. PERSISTED DATA MIGRATION MATRIX

| Current Data (key) | Target Owner | Compatibility Strategy | Migration Timing | Retirement Gate | Data-Loss Risk |
|--------------------|--------------|------------------------|------------------|-----------------|---------------|
| `projects_list` | Projects | READ-COMPAT FIRST → DUAL-READ/WRITE → Projects canonical | W4 (with Projects owner) | After Projects V1 proven | LOW if dual-write kept |
| `checklist_data` | Tools | KEEP (Tools-owned generic checklist) | — | — | NONE |
| `checklist_project_<id>` | Projects (project-owned records) | DUAL-READ/WRITE during Project migration | W4 | After Project records canonical | LOW |
| `favorites` (Hive) | Saved (User) | READ-COMPAT + merge to canonical Saved ref | W3 | After canonical resolver proven | LOW |
| `encyclopediaFavorites` (Hive) | Saved (User) | Same as favorites | W3 | After canonical resolver proven | LOW |
| `downloads` (Hive) | Saved/Offline (User ref) | READ-COMPAT; artifact vs ref split | W3 | After ref resolver | LOW |
| `offline_<articleId>` (Hive) | Offline (User ref + artifact) | READ-COMPAT; re-acquire semantics | W3 | After ref model | LOW |
| `local_user_profile` (SP) | User | KEEP | — | — | NONE |
| `auth_email`/`auth_name`/`register_<email>` | Auth/User | KEEP | — | — | NONE |
| `isDarkMode`, `onboardingSeen` (SP) | User prefs | KEEP | — | — | NONE |
| `sb_profiles` (SP) | Directory (single-key JSON) | **Legacy/V0**: read V0 → preserve meaning → introduce version-aware representation → compat/dual-read-write → verify persisted data → retire old representation only later | W5.1 (wrap) | After Directory repo proven | MEDIUM if schema versioning missed |
| Backup versions | User/Cross-domain | ADD versioning | W0 | — | MEDIUM if unversioned |

**No destructive migrations anywhere.** Every split is read-compatible → dual-read/write → canonical, with old key retirement only after proof and explicit gate.

---

## 17. ROUTE MIGRATION MATRIX

| Current Route | Target Route | Compat Requirement | When Target Canonical | When Old Redirects | When Old Removed |
|---------------|--------------|--------------------|----------------------|--------------------|------------------|
| `/categories` | `/encyclopedia/categories` (umbrella) | Redirect only | After Knowledge umbrella stable | Algebraic/redirect once new live | After redirect proven |
| `/articles` , `/articles/:category`, `/article/:id` | `/encyclopedia/...` if umbrella adopted | Keep both | When umbrella nav adopted | During transition | After proof |
| `/encyclopedia/topics/:categoryId` , `/encyclopedia/topic/:topicId` | KEEP (canonical) | — | Now | — | — |
| `/calculator/{...}` | `/tools/{toolKey}` | Redirect + registry `ToolKey` | After Tools identity contract | During transition | After Tools nav stable |
| `context.go(route)` from `relatedToolRoutes` | typed resolver → target route | Compat resolver; never direct generated-edit | Only via Content Studio gate if adopted | — | After gate |
| Shell 5 branches | Target Bottom Navigation (Projects/Directory/User Area via Avatar) | Sequential; each only when ready | Wave-by-wave | Old branch hidden, not removed | New nav replaces |
| `/search` (new) | Global Search full screen — **NOT a Bottom Navigation tab**; reached from Home/Header | Add route + aggregator | W2 | — | — | Home search unchanged |

**Rule:** never immediately delete a route. Add target, redirect, verify (tests + QA), then retire old. No navigation big-bang.

---

## 18. DEPENDENCY GRAPH

```
[W0 Foundation: route contract, storage-key owner, backup foundation, tool identity, honest ads]
   │
   ├─► [W1 Knowledge/Home alignment] ───────────┐
   │                                            │
   ├─► [W2 Global Search V1 (Knowledge+Tools)]  ├──► (uses Knowledge/Tools sources)
   │                                            │
   ├─► [W3 User Area / Saved migration] ────────┤
   │                                            │
   ├─► [W4 My Projects V1] ── (needs calc snapshot contract; backup) ─► [W6 Nav transition]
   │                                                                          ▲
   ├─► [W5 Directory V1] ─── (needs de-coupled seed + 5-state) ──────────────┤
   │                                                                          │
   └─► [W7 Monetization] ───────── (after Directory + honest ads) ───────────┘
```

**Principle:** a domain's Bottom Navigation entry is added only after its minimal V1 function exists. **W3 → W4 run sequentially** (user/owner decision): complete W3 (verify → commit) before beginning W4. No parallel start; this does **not** create a domain-ownership dependency between User and Projects.

---

## 19. IMPLEMENTATION WAVES

### WAVE 0 — PLATFORM SAFETY / CONTRACT FOUNDATIONS
Only changes that de-risk later work. Small, atomic, green every commit.
- **F0.x** Single canonical route contract (typed route names; keep current behavior, no rewrites).
- **F0.x** Storage-key centralization (single owner map; no behavior change).
- **F0.x** Backup foundation: full restore + versioning (fixes B-03).
- **F0.x** Honest ads: `LocalAdDataSource` returns none without a campaign (fixes B-02).
- **F0.x** `ToolKey` contract for tools identity (without changing current routes — enable later resolver).
- **F0.x** Directory de-coupling + 5-state `VerificationStatus` contract groundwork (fixes B-04/B-05) *without Directory UI*.

> **Not** automatic cleanup: only required de-risking. Do not bundle cosmetic refactors.

### WAVE 1 — KNOWLEDGE / HOME PLATFORM ALIGNMENT (REQUIRED but MINIMAL)
Confirmed REQUIRED but kept minimal. Allowed **only when genuinely needed**:
- public Knowledge projections/contracts
- Knowledge umbrella preparation (logical/domain alignment)
- Home aggregation boundaries

**Explicitly NOT included** in W1: Encyclopedia rewrite, content redesign, deep Article/Encyclopedia consolidation, calculator redesign, unnecessary UI polish. W1 must NOT become an Encyclopedia rewrite. Protect the strong Content Studio pipeline and encyclopedia screens. Any Home data-source normalization and global-search delegation happens after W2 exists.

### WAVE 2 — GLOBAL SEARCH V1 (Knowledge + Tools)
- Dedicated full screen at `/search` (NOT a Bottom Navigation tab). Aggregator shell, unified `SearchResult` model + type, route resolver, per-domain failure isolation, `SearchBarWidget` reuse.
- Result selection → owning domain canonical destination; back → originating context. Search owns no detail screens.
- Ship a **Flutter-side compatible route resolver** so B-01 does not gate launch.

### WAVE 3 — USER AREA / SAVED MIGRATION
- Canonical Saved-reference resolver; merge `favorites`/`encyclopediaFavorites` read-compat; build the **Avatar → `/user`** User Area (hub, full screen, nested routes), NOT a bottom-sheet/modal. Profile still reachable.
- **Execution order (owner decision):** complete W3 → verify → commit → **then** begin W4. No W3+W4 parallel initial start.

### WAVE 4 — MY PROJECTS V1
- Begins **after** W3 completes and commits. Migrate Projects out of Tools; build V1 minimal scope incrementally (List→Create/Edit→Archive/Restore→Overview→Save Calculator→History→Notes→Checklist executions). Backup preserves records.

### WAVE 5 — DIRECTORY V1
- Only after Project/Directory boundaries ready. Landing→Categories→Search→Filters→Listing→Detail→Contact→Verification→Save Provider. Keep hidden until complete.

### WAVE 6 — TARGET NAVIGATION TRANSITION
- Switch Bottom Navigation progressively: add Projects when ready, Directory when ready, User Area when ready, preserve Saved reachability. Hide—do not break—legacy branches.

### WAVE 7 — MONETIZATION
- Honest ads already in place. Campaign gating + sponsored Directory integration only after Directory is live.

---

## 20. ATOMIC PHASE ROADMAP

Naming: `W<wave>.<n>` (or `F0.x` for foundation). Each phase is a **single-session, verifiable, atomic commit**.

### WAVE 0
| Phase | Goal | Depends | Data Mig? | UI? | Tests | Visual QA? | Commit Bound | Notes |
|-------|------|---------|-----------|-----|-------|------------|--------------|-------|
| F0.1 | Introduce canonical route-name contract (typed, keep current routing) | — | No | No | Yes | No | Single | Foundation for all nav |
| F0.2 | Centralize storage-key ownership map | — | No | No | Yes | No | Single | Single owner of all keys |
| F0.3 | Backup: full restore + versioning | F0.2 | Yes (version reads) | No | Yes | No | Single | Fixes B-03 |
| F0.4 | Honest ads: mock→none without campaign | — | No | Minor (hide empty slot) | Yes | Yes (visual) | Single | Fixes B-02 |
| F0.5 | `ToolKey` identity contract (no route change) | F0.1 | No | No | Yes | No | Single | Unlocks resolver |
| F0.6 | Directory de-couple + 5-state contract groundwork | F0.2 | No (compat) | No | Yes | No | Single | Fixes B-04/B-05 without UI |

### WAVE 1
| Phase | Goal | Depends | Data Mig? | UI? | Tests | Visual QA? | Commit Bound | Notes |
|-------|------|---------|-----------|-----|-------|------------|--------------|-------|
| W1.1 | Home data-source normalization (read-compat) | F0.2 | No | No | Yes | No | Single | Protect pipeline |
| W1.2 | Home search delegation groundwork | F0.1 | No | Minor | Yes | Yes | Single | Prepare global search hook |

### WAVE 2 (Global Search V1)
| Phase | Goal | Depends | Data Mig? | UI? | Tests | Visual QA? | Commit Bound | Notes |
|-------|------|---------|-----------|-----|-------|------------|--------------|-------|
| W2.1 | `SearchResult` model + type + route resolver | F0.5,F0.1 | No | No | Yes | No | Single | Compat resolver now |
| W2.2 | Aggregator service (Knowledge+Tools) w/ failure isolation | W2.1 | No | No | Yes | No | Single | Per-domain isolation |
| W2.3 | Global Search screen + SearchBarWidget reuse | W2.2 | No | Yes | Yes | Yes | Single | Launch V1 |
| W2.4 | Home search routes to global search (WRAP) | W2.3 | No | Minor | Yes | Yes | Single | Delegate |

### WAVE 3 (User/Saved)
| Phase | Goal | Depends | Data Mig? | UI? | Tests | Visual QA? | Commit Bound | Notes |
|-------|------|---------|-----------|-----|-------|------------|--------------|-------|
| W3.1 | Canonical Saved-reference resolver | F0.2 | READ-COMPAT | No | Yes | No | Single | Merges dual stores read-only |
| W3.2 | Saved screen uses resolver | W3.1 | No | Minor | Yes | Yes | Single | Behavior preserved |
| W3.3 | Route profile edit (remove Navigator.push bypass) | F0.1 | No | No | Yes | No | Single | Prep avatar area |
| W3.4 | Avatar → `/user` User Area shell (full hub, nested `/user/*` routes; profile still reachable) | W3.3 | No | Yes | Yes | Yes | Single | Future nav replacement; not a modal/bottom-sheet |

### WAVE 4 (Projects V1)
| Phase | Goal | Depends | Data Mig? | UI? | Tests | Visual QA? | Commit Bound | Notes |
|-------|------|---------|-----------|-----|-------|------------|--------------|-------|
| W4.1 | Projects domain split from Tools (dual-read/write keys) | F0.2 | DUAL | Minor | Yes | No | Single | B-03 already fixed |
| W4.2 | Project entity + repo canonicalization | W4.1 | No | No | Yes | No | Single | |
| W4.3 | Create/Edit formalized | W4.2 | No | Minor | Yes | yes | Single | |
| W4.4 | Archive + Restore lifecycle w/ legacy storage compat | W4.2 | DUAL | Minor | Yes | Yes | Single | V1 requirement |
| W4.5 | Save Calculation payload (snapshot contract) | W4.2 | No | Yes | Yes | Yes | Single | Dep: calc snapshot |
| W4.6 | Calculation History | W4.5 | No | Yes | Yes | Yes | Single | |
| W4.7 | Notes (user-owned records) | W4.2 | No | Yes | Yes | Yes | Single | |
| W4.8 | Checklist executions → project records (dual-write) | W4.2 | DUAL | Minor | Yes | No | Single | `checklist_project_<id>` |

### WAVE 5 (Directory V1)
| Phase | Goal | Depends | Data Mig? | UI? | Tests | Visual QA? | Commit Bound | Notes |
|-------|------|---------|-----------|-----|-------|------------|--------------|-------|
| W5.1 | Directory repository over `sb_profiles` (wrap, no UI) | F0.6,F0.2 | READ-COMPAT | No | Yes | No | Single | Consume `businessRepo` |
| W5.2 | Landing + Categories | W5.1 | No | Yes | Yes | Yes | Single | |
| W5.3 | Search + location/category filter | W5.1 | No | Yes | Yes | Yes | Single | Directory-local |
| W5.4 | Provider listing + detail + contact | W5.3 | No | Yes | Yes | Yes | Single | |
| W5.5 | Verification display (5-state) | F0.6,W5.1 | No | Yes | Yes | Yes | Single | |
| W5.6 | Save provider (User-owned Saved ref) | W3.1,W5.1 | No | Yes | Yes | Yes | Single | |

### WAVE 6 (Nav transition)
| Phase | Goal | Depends | Data Mig? | UI? | Tests | Visual QA? | Commit Bound | Notes |
|-------|------|---------|-----------|-----|-------|------------|--------------|-------|
| W6.1 | Add Projects nav entry (hidden until V1 complete) | W4.8 | No | Minor | Yes | Yes | Single | |
| W6.2 | Add Directory nav entry | W5.6 | No | Minor | Yes | Yes | Single | |
| W6.3 | Add Avatar→`/user` User Area entry; Saved remains reachable (`/user/saved`, `/user/downloads`) | W3.4 | No | Minor | Yes | Yes | Single | Profile tab hidden, `/user/*` canonical |
| W6.4 | Route Home/Header search entry → `/search` (Global Search is a full screen, NOT a bottom-nav tab) | W2.4 | No | Minor | Yes | Yes | Single | |

### WAVE 7 (Monetization)
| Phase | Goal | Depends | Data Mig? | UI? | Tests | Visual QA? | Commit Bound | Notes |
|-------|------|---------|-----------|-----|-------|------------|--------------|-------|
| W7.1 | Campaign contract + `AdPlacementRequest` | F0.4 | No | No | Yes | No | Single | Honest ads already |
| W7.2 | Sponsored Directory placement (sponsored ≠ second entity) | W5.6,W7.1 | No | Yes | Yes | Yes | Single | |
| W7.3 | Plan/paywall gating (only if required) | W7.2 | No | Yes | Yes | Yes | Single | Speculative/deferred |

**Phase-size rule honored:** every phase is a single session's work, greeneable, with explicit stop condition and commit boundary.

---

## 21. AI CONTEXT EFFICIENCY

Changes that structurally reduce future implementation-agent ambiguity (correctness first, never token-chasing):
- **F0.1 single canonical route contract** — one place to resolve any route, kills scattered raw strings.
- **F0.2 single storage-key owner** — one map answers "who owns this key".
- **F0.5 `ToolKey` identity** — removes tool route ambiguity across Tools/Home/Search.
- **W3.1 canonical Saved-reference resolver** — one way to resolve any Saved entity.
- **W4.2 canonical Project repository ownership** — unique record/snapshot owner.
- **Removing direct UI data-source construction** (foundation) — screens depend on providers, not datasources.
- **Domain public projections** — Home/Search consume projections, not raw legacy stores.

These let a future agent answer "where does X live / how is Y resolved" from a single contract instead of spelunking.

---

## 22. TEST STRATEGY

Per wave/layer (preserve existing baseline; never require heavy integration infra where unit/widget suffice):

| Layer | Where | Key scenario |
|-------|-------|--------------|
| Pure domain | calculators primitives, Project entity, `SearchResult`, `VerificationStatus` | invariant + edge cases |
| Repository/data migration | Projects dual-read/write, Saved merge, `sb_profiles` wrap, Backup restore | read old→write new→verify; versioning |
| Provider/state | Home, Saved, Search aggregate, Theme/Language | state transitions |
| Widget | SearchBar, Saved, Project forms, ads slot | render + interactions |
| Navigation | route contract, redirects, shell transition | target reachable; old redirects; no big-bang |
| Offline | packaged knowledge, downloads, local Projects | offline read + local-first |
| Compatibility | `favorites`/`encyclopediaFavorites`, `projects_list`, `sb_profiles` | old data still readable |
| Smoke | post-W6 nav | all gate features reachable, none broken |
| Visual QA | any UI phase | manual gate (mark Y in roadmap) |

---

## 23. RELEASE / NAVIGATION READINESS GATES

| Target Feature | Launch Gate | Required Tests | Migration Gate | Navigation Gate | Fallback |
|----------------|-------------|----------------|----------------|-----------------|----------|
| My Projects V1 (nav) | W4.8 all V1 items green | domain+repo+migration+widget+visualQA | `projects_list`/`checklist_project_<id>` dual-write verified | W6.1 | Hidden; Tools still works |
| Directory V1 (nav) | W5.6 all V1 items green; 5-state verified; de-coupled | repo+migration+widget+visualQA | `sb_profiles` wrapped, no loss | W6.2 | Hidden |
| User/Profile removal | Avatar → `/user` User Area ready (W3.4, nested `/user/profile`, `/user/profile/edit`) | widget+navigation | Saved resolver verified | W6.3 (Avatar→`/user`; `/profile` tab hidden) | Profile branch persist |
| Saved removal | Saved clearly reachable via `/user/saved` + `/user/downloads`, migration verified | migration+widget | favorites/enccyFav merged | W6.3 | Saved reachable via User Area |
| Global Search (release) | W2.4 green; failure isolation | aggregator+model+widget | N/A | `/search` full screen reachable from Home/Header (not a bottom-nav tab) | Home search unchanged |
| Monetization/Ads | W7 green; honest ads already (F0.4) | repo+widget+visualQA | N/A | W7 | No ad = no slot |

---

## 24. DO NOT TOUCH YET

Explicit areas worth leaving alone until implementation requires them:
- Final D9 Dark Mode polish (cosmetic).
- Deep Article/Encyclopedia `ArticleRepository` consolidation (CONSOLIDATE LATER).
- Content Studio schema/editor/generated catalog internals (DO NOT touch; only via §15bis gate).
- `relatedToolRoutes` generated-content rewrite (defer; use Flutter resolver).
- RFQ, provider reviews, cloud sync, collaboration (future/out of scope).
- Speculative plan/paywall/Monetization architecture beyond the honest-ads foundation and Directory de-coupling.
- Calculator visual redesign (KEEP working).
- Migration of `checklist_data` (Tools-owned, stays).

---

## 25. LEGACY RETIREMENT RULES

- Never delete a legacy path before its successor is **proven** (tests + QA) and **read-compatible**.
- Retire old storage keys only after dual-write is stable and a migration gate is crossed.
- Never immediately remove a route; redirect first, verify, then remove.
- `ArticleRepository` / legacy datasources retire only after their consumers (Home, Search) read from canonical sources.
- Generated content is **never** a migration source or an edit target.
- Hidden unfinished features stay hidden; no fake/empty screens.

---

## 26. FIRST RECOMMENDED IMPLEMENTATION PHASE

**Confirmed (owner decision): `F0.1 — Introduce a canonical route-name contract (typed; keep current routing behavior unchanged)` IS the first implementation phase.**

F0.1 must remain, and will be implemented later (NOT now):
- **behavior-preserving** — no route migration, no UI change, no Content Studio change
- **low-risk**, **fully testable**, **atomic**

Rationale:
- **Low risk / atomic / fully testable:** no data, no UI behavior change; pure contract introduction with tests.
- **Useful immediately:** kills scattered raw route strings, the #1 ambiguity source flagged throughout M1–M7.
- **Unlocks later phases:** F0.5 `ToolKey`, W1.2/W2 global-search delegation, W3.3 routed profile edit, W6 nav all consume the contract.
- **No content damage:** Content Studio/generated files untouched.
- **Not a huge refactor:** introduce the contract and migrate call sites incrementally behind green tests, per the non-negotiable evolution rule.

**Not My Projects first:** Projects V1 (W4) genuinely depends on W0 foundations (storage-key owner F0.2, backup F0.3, tool identity F0.5) and is a larger multi-phase build. F0.1 is the correct smallest safe first step.
**Not implemented now:** F0.1 is confirmed as the first *future implementation* phase; M8 performs no implementation.

---

## 27. OPEN DECISIONS

The previously listed items are **RESOLVED** (see the sections cited):

| # | Former Open Decision | Status | Resolution |
|---|----------------------|--------|------------|
| 1 | Global Search V1 navigation shape | **RESOLVED** | Dedicated full screen `/search`; NOT a Bottom Navigation tab (§10, §19-W2) |
| 2 | Route resolver vs Content Studio timing | **RESOLVED** | Flutter compat resolver in W2; CS schema deferred (§15bis) |
| 3 | Umbrella Knowledge routes | **RESOLVED** | Knowledge is target domain; no immediate `/encyclopedia → /knowledge` rewrite; ordered migration (§6) |
| 4 | User Area navigation style | **RESOLVED** | Avatar → `/user` full hub (nested routes); not a modal/bottom-sheet (§11) |
| 5 | `sb_profiles` versioning strategy | **RESOLVED** | Treat as Legacy/V0; read → preserve → version-aware → dual-read/write → verify → retire later (§16) |
| 6 | Wave 1 necessity/scope | **RESOLVED** | W1 REQUIRED but MINIMAL; excludes rewrite/consolidation/polish (§19-W1) |
| 7 | W3/W4 parallelism | **RESOLVED** | W3 → verify → commit → W4; sequential, not parallel initially (§18, §19-W3/W4) |

**Remaining genuinely-open decisions (implementation/product — not resolved by M8):**
1. Exact intermediate route names under the knowledge umbrella if/when `/encyclopedia → /knowledge` reorg is scheduled (deferred by §6).
2. Whether the Directory V1 repository wraps `sb_profiles` in-place (dual-read/write in-place) vs migrates to a new versioned store up-front — both staged in W5.1; choose during implementation.
3. Monetization model specifics (campaign sources, sponsorship pricing, plan/paywall tiers) — deferred to W7; speculative.
4. Home layout polish details (D9 dark, aggregation widget placement) — deferred; finalized when Home aggregator work starts.

> If no genuine open decision remains for a specific area, it is resolved and not reopened without a real contradiction from implementation.

---

## 28. NON-NEGOTIABLE EXECUTION RULES

1. **NO BIG-BANG REWRITE** — ever. Contract → migrate one consumer → verify → retire old.
2. **No destructive migrations** — read-compat → dual-read/write → canonical only.
3. **No immediate route/storage deletion** — redirect/dual-write first, retire after proof.
4. **Content Studio schema/generated files are never edited directly.**
5. **Unfinished features stay hidden** — no fake tabs, empty screens, or "Coming Soon".
6. **BLOCKERS are launch-dependent only** — don't inflate; debt is debt.
7. **A domain enters Bottom Navigation only when its minimal V1 + gates are green.**
8. **Every phase is atomic, testable, visual-QA'd (if UI), single-commit.**
9. **Honest ads always** — no campaign ⇒ no ad ⇒ no blank slot.
10. **Ownership invariants (M4/M7) are never violated** — User never owns domain entities; Directory offline stays cache.
11. **AI context efficiency is a means, not a goal** — correctness first; never refactor purely for token savings.
12. **Small commits, green tests, visual QA gates** throughout.

---

## APPENDIX — MASTER GAP TABLE (Domain × Dimension Aggregate)

| Domain/System | Current State | Target State | Gap | Action | Priority | Blocker? | Dependencies | Notes |
|---------------|---------------|--------------|-----|--------|----------|----------|--------------|-------|
| Home | Aggregator-in-waiting | Full aggregator | Global search, honest ads, project projection, legacy data | WRAP/MIGRATE/ADD | M | — (B-02 gates real Monetization only) | W2, W4, F0.4 | No UI redesign |
| Knowledge | Strong, working | Canonical, protected | relatedToolRoutes, legacy repo, dual Saved | KEEP/CONSOLIDATE/DEFER | H(keep) | B-01 (gates raw-route retirement only) | Content Studio gate | Pipeline sacred |
| Tools | Strong calculators | Canonical primitives, ToolKey | tool identity, save-to-project, Projects under Tools | KEEP/WRAP/MIGRATE/ADD | M | B-01 (resolver) | F0.5, W4.5 | No calc redesign |
| Projects V1 | Seed under Tools | Full V1 | restore, calc history, notes, archive, ownership | MIGRATE/ADD | H | B-03 (gates production-readiness only) | W0, W4 chain | Hidden until ready |
| Directory V1 | Seed (no UI) | Full V1 | all UI, 5-state, de-couple, save | WRAP/ADD/MIGRATE | H | B-04 (launch), B-05 (persistence/model only) | W0, W5 chain | Hidden until ready; B-05 does not gate UI |
| Global Search V1 | Not implemented | Knowledge+Tools aggregator | model, aggregator, resolver, isolation | ADD/WRAP | H | — (B-01 resolver enables) | W2 chain | Independent of Projects/Dir |
| Saved/User | Works (multi-store), profile branch | Canonical Saved ref + User Area | resolver, merge, avatar | WRAP/CONSOLIDATE/KEEP | M | — | W3 chain | Preserve reachability |
| Offline/Backup | Partial | Complete + versioned | full restore, versioning | FIX/ADD | H | B-03 (gates Project prod-readiness) | W0 | Re-acquire knowledge artifacts |
| Monetization/Ads | Mock ads, plan-coupled seed | Honest ads + sponsored | remove mock, campaign contract, de-couple Dir | FIX/DEFER | M | B-02 (gates real Monetization only) | F0.4, W7 | No ad without campaign |

---

*End of M8. Roadmap-only. Deliberately avoids big-bang, protects Content Studio + working systems, and gives every future domain explicit launch gates so implementation prompts can be generated directly from phase IDs (F0.x, W1.x–W7.x).*
