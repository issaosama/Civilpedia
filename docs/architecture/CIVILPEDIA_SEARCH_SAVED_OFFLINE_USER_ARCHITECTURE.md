# CIVILPEDIA — GLOBAL SEARCH · SAVED · OFFLINE · USER MASTER ARCHITECTURE

**Phase:** M7. **Status:** ARCHITECTURE / DOCUMENTATION ONLY — no production code changed.
**Inputs (approved):** M1 `CIVILPEDIA_PRODUCT_ARCHITECTURE.md`, M2 `CIVILPEDIA_SCREEN_MAP.md`, M3 `CIVILPEDIA_NAVIGATION_ARCHITECTURE.md`, M4 `CIVILPEDIA_DATA_OWNERSHIP_AND_DOMAIN_CONTRACTS.md`, M5 `CIVILPEDIA_PROJECTS_ARCHITECTURE.md`, M6 `CIVILPEDIA_DIRECTORY_AND_SERVICES_ARCHITECTURE.md`, plus live inspection of the current Search / Saved / User / Offline / Backup implementation.

> This designs the complete cross-domain architecture for Global Search, Saved/Favorites, Downloads/Offline, User/Profile, Recent Activity, Preferences, Theme/Language, Backup, and the Auth/Identity boundary. These are cross-domain or user-state concerns that connect Civilpedia's major domains **without becoming God services or duplicating source-domain data**. No production change.

---

## 1. Purpose

Design the cross-domain systems (Global Search, Saved/Favorites, Offline, User/Account, Monetization boundary, Theme/Localization, Feature Flags) so they connect Home, Knowledge, Tools, My Projects, and Directory while: (a) never becoming secondary owners of domain entities, (b) never duplicating source-domain data, (c) staying offline-first where appropriate, and (d) being staged for a no-big-bang, data-preserving migration.

---

## 2. Current Baseline (verified)

### 2.1 Search
- `SearchBarWidget` (`lib/core/widgets/search_bar_widget.dart:12`) — shared presentational `TextField`, emits `onChanged`/`onSubmitted`, no logic.
- Home search: `HomeMainScreen.openEncyclopediaSearch` (`home_main_screen.dart:22`) → trims → `context.go('/encyclopedia?q=<encoded>')`. Home only collects the query.
- Encyclopedia: router (`app_router.dart:31-33`) passes `?q=` as `initialQuery` into `EncyclopediaScreen`; `initState` seeds the controller and calls `provider.searchTopics(query)`.
- `EncyclopediaProvider` search is **in-memory filtering only** (`_filteredTopics`, non-debounced), matching `titleAr/titleEn/summary/tags/keyTopics` via `contains`; `searchTopics` does NOT call the repository. **No search persistence** — query survives only in memory or the URL `?q=` param.

### 2.2 Saved / Favorites / Downloads
- `SavedScreen` (`saved_screen.dart:15`) — 2 tabs (Favorites/Downloads). Favorites tab merges (a) encyclopedia favorites via `EncyclopediaFavoritesProvider.savedIds` resolved through `EncyclopediaProvider.resolveTopics` (TopicListCard), and (b) **legacy article favorites** via `HiveHelper.getFavorites()` filtered against static `ArticleRepository.articles`. Downloads tab reads `HiveHelper.getDownloads()`.
- `EncyclopediaFavoritesProvider` (`encyclopedia_favorites_provider.dart:30`) + `HiveEncyclopediaFavoritesStore` — write Hive keys `encyclopediaFavorites`.
- Legacy article favorites/downloads toggled in `ArticleDetailsScreen` via `HiveHelper`.
- `HiveHelper` (`lib/data/local/hive_helper.dart`) — single Hive box `civilpedia`; keys: `favorites`, `encyclopediaFavorites`, `downloads`, and per-article `offline_$articleId` (full `ArticleModel.toJson()` cached on download).
- **No unified Saved model/document exists** — two data worlds (encyclopedia topics + legacy articles) merged presentationally.

### 2.3 User / Profile / Auth
- `ProfileScreen` (`profile_screen.dart:19`) — header from `AuthProvider`; `CivilUserType`/`BaghdadArea` from `UserProfileProvider.profile`; settings (dark-mode switch → `ThemeProvider`); backup export → `AppDependencies.backupService.exportToFile()`.
- `ProfileEditScreen` + `ProfileSetupScreen` (2-step wizard) — persist via `UserProfileProvider.saveProfile`.
- `UserProfileProvider` → `LocalUserProfileRepository` → `LocalUserProfileDataSource` (SharedPreferences `local_user_profile`). Model: `LocalUserProfile` with `anonymousInstallId`, `userType` (`CivilUserType`, 11 values), `baghdadArea`, name/title/company/phone/email/logo, `futureCloudUserId`, `schemaVersion=1`.
- Auth: `AuthProvider` (`auth_provider.dart`) — **in-memory login only**; `AuthRepositoryImpl` (`auth/data/`) persists SharedPreferences `auth_email`/`auth_name`/`register_$email` but is **orphaned (not wired)**. Login does not reliably survive restart in the wired path.
- Splash gating (`splash_screen.dart:33-54`): not-onboarded → `/onboarding`; else load profile; no profile / `generalUser` / `unknown` area → `/profile-setup`; else `/home`.
- Settings surface lives only inside ProfileScreen (no standalone settings route/screen).

### 2.4 Offline
- Packaged encyclopedia catalog: bundled assets `catalog.generated.json` + `catalog.json` (`assets/encyclopedia/`), loaded by `EncyclopediaJsonDataSource` (tolerant parse), **in-memory only** (no Hive copy). Fallback mock `EncyclopediaLocalDataSource`.
- Legacy downloaded articles: Hive `downloads` + `offline_$articleId` full JSON; encyclopedia topics are **not** downloadable.
- `ConnectivityProvider` (`connectivity_provider.dart`) — created in `main.dart`, consumed **only** by Home header dot (cosmetic); nothing branches on connectivity.
- SharedPreferences key map (owners): `isDarkMode`(preferences), `onboardingSeen`, `local_user_profile`(profile), `sb_profiles`(directory seed), `checklist_data`/`checklist_project_$id`/`projects_list`(tools), `auth_email`/`auth_name`/`register_$email`(auth).

### 2.5 Backup
- `BackupService` (`backup_service.dart:37`); `buildBackup()` bundles userProfile, projects, quickChecklist, projectChecklists, preferences, Hive legacy `favorites`/`downloads` id lists. `exportToFile` → `BackupFileService` (`<docs>/backups`, atomic `.tmp` rename). `validateBackup()` version-checks (`backupSchemaVersion` 1..`currentBackupVersion`). `restoreFromBackup()` fully restores only `localUserProfile` + dark mode; **the rest are `TODO(BACKUP-1C)` stubs** (projects, checklists, favorites, downloads — not written).
- Schema: `BackupFile`/`BackupSections` version 1; `SchemaConstants.currentBackupVersion=1`, `currentDataSchemaVersion=1`.

### 2.6 Infrastructure
- `AppDependencies` (static DI) wires encyclopedia, user profile, service business, checklist, project repos + backup. **Not wired:** auth repos, ads.
- Bootstrap `main.dart`: `PreferencesHelper` → `HiveHelper` → `AppDependencies` → providers (Theme, Language, Auth, Connectivity, Encyclopedia, EncyclopediaFavorites, UserProfile).
- `app.dart`: `MaterialApp.router` with **`supportedLocales: [Locale('ar')]`** + `localeResolutionCallback`→`'ar'` — **Arabic is force-default; no English route in Flutter localization** (ad-hoc `tr()` helpers exist per-screen but `LanguageProvider.isArabic` is hardcoded `true`).
- AppShell 5 tabs: Home, Encyclopedia, Tools, Saved, Profile (target 5: Home, Knowledge, Tools, My Projects, Directory).

**Flags (verified, not fixed):**
1. Encyclopedia search is non-debounced, in-memory only, and mixed presentationally with legacy-article favorites in Saved.
2. Saved is two merged worlds (encyclopedia + legacy article); no unified reference model.
3. `AuthRepositoryImpl` is orphaned and duplicated; `AuthProvider` login isn't reliably persisted in the wired path.
4. `BackupService` restore is partial (`TODO(BACKUP-1C)` — M4 debt #10).
5. Arabic is forcibly the only locale; `LanguageProvider` is a stub.
6. Settings live only inside ProfileScreen.
7. `AccessProvider`/plan/FeatureKey layer is declared but not enforced at runtime.

---

## 3. Cross-Domain Principles

Search, Saved, Offline, and User must **NOT** become secondary owners of domain entities:
- Search index contains Topic title **≠** Search owns Topic.
- Saved stores `supplierId` **≠** Saved owns Supplier.
- Offline cache contains Directory card data **≠** Offline owns Directory.
- User activity references Project **≠** User owns Project.

**Source domain remains authoritative.** Cross-domain systems hold indexes/references/preferences/caches only. Restated from M1 §13/§14, M4 §7/§9, M6 §5. A thin workflow/aggregation layer (Home, Global Search, cross-domain services) orchestrates movement; no single domain owns a whole workflow.

---

## 4. Global Search Role

Global Search is the **fastest entry point** into Civilpedia. Scope over time: Knowledge Topic, Article, Tool, Project, Directory Entity, Service, Material/Product.

Search owns: **INDEX / PROJECTION / AGGREGATION**. Search does **not** own the source entities and does **not** own any detail screens (M1 §4/§12; M3 §14). Selecting a result **routes to the owning domain** — no duplicate destination screens in Search.

---

## 5. Search Domain Contracts

Each domain may expose a **search projection** (thin, read-only, ID-keyed). A Global Search layer aggregates them via a `GlobalSearchGateway`:

```
GlobalSearchGateway
├── KnowledgeSearchSource
├── ToolSearchSource
├── ProjectSearchSource
└── DirectorySearchSource
```

Do not make one search service inspect every private repository/storage table; prefer public projection contracts. **Projection means output shapes, not ownership** — a domain's search source may read only that domain's own (public/cache-friendly) index, never another domain's private store (M4 `GlobalSearchGateway`, rule 7). No implementation; contract concept only.

**Search Source Table**

| Domain | Projection | Source Owner | Available Offline? | Failure Isolation | Notes |
|---|---|---|---|---|---|
| Knowledge (Topic/Article) | `KnowledgeSearchProjection` | Knowledge | Yes (bundled catalog + local index) | Isolated (§35) | V1; existing encyclopedia filter is seed |
| Tools | `ToolSearchProjection` | Tools | Yes (local logic/definitions) | Isolated (§35) | V1 |
| Projects | `ProjectSearchProjection` | Projects | Yes (local-first) | Isolated (§35) | V1.5 (M5); not if Projects not production-ready |
| Directory | `DirectorySearchProjection` | Directory | Partial (cache/recent) | Isolated (§35) | V1.5 (M6); cache ≠ ownership |
| Service | `DirectorySearchProjection` (type) | Directory | Partial | Isolated | Part of Directory source |
| Material/Product | `DirectorySearchProjection` (type) | Directory | Partial | Isolated | Part of Directory source |

---

## 6. Search Result Model

Every result conceptually includes:
- `ownerDomain`
- `entityType`
- `entityId`
- `title`
- optional `subtitle`
- optional `icon`/`category`
- ranking metadata
- `canonicalDestination` (owning-domain detail route)

**Never use translated display names as identity** (§30). Selecting a result routes to the owning domain. Search owns no detail screens.

---

## 7. Search Ranking

Do not design a complex ranking algorithm. Principle:
- exact relevance
- semantic/category relevance (where available)
- recency where appropriate
- user context where privacy-safe (§34)
- domain weighting only when justified

**Sponsored content must NOT silently manipulate organic Global Search relevance.** If sponsored search placement exists later, clearly label it and keep it structurally separate from organic ranking (M6 §11–13).

---

## 8. Search Filters

Potential filters (keep simple, cross-domain): All, Knowledge, Tools, Projects, Directory.
- Do not add dozens of filter tabs.
- **Directory-specific filters stay inside Directory**; **Project-specific filters stay inside Projects**.
- Global Search remains cross-domain and simple (M6 §11, M5 §25, M1 §12).

---

## 9. Search History

Decide: recent searches belong to **User/preferences**.
- If supported: `RecentSearch` → **user-owned state** (`ownerDomain`, `query` display, `searchedAt`).
- **Do not persist sensitive project/query content unnecessarily.**
- Privacy rules: search history may be sensitive (§34); keep it bounded, clearable, never shared for ad targeting by default; never include private Project content or raw engineering-document snippets in persisted history.

---

## 10. Search Migration

Current valid flow (keep working during migration): Home query → `/encyclopedia?q=` → `EncyclopediaProvider`.
Staged evolution, no big-bang:
1. **Knowledge-only search** (current encyclopedia filter) — stays functional.
2. **Global Search shell** (new `/search` entry) aggregating Knowledge + Tools (V1).
3. **Add domain sources incrementally** (Projects, Directory in V1.5) — each additive behind its source contract, isolated on failure (§35).
Current in-memory filtering may be lifted into a Knowledge search source exposing ranking metadata — but preserve existing behavior and query routing during transition (M3 §14 §21).

---

## 11. Saved Role

Saved is a **user-state** system that stores **references** to source-domain entities (M1 §13; M4 §9). It is not a top-level domain and not a substitute for Projects (M1 §6/§13; M5 §12/§18).

---

## 12. Saved Reference Model

Target: `SavedItemReference`:
- `id`
- `ownerDomain`
- `entityType`
- `entityId`
- `savedAt`
- optional lightweight display snapshot
- optional offline state/reference

**Do NOT store full domain entities by default.** A full snapshot only when an explicit offline projection is required (§15/§16 Knowledge downloads). These fields mirror M4 `SavedItemsStore` (`entityType/entityId/ownerDomain`) and M6 §17.

**Saved Type Table**

| Entity Type | Owner Domain | Reference ID | Offline Snapshot? | Resolver | Notes |
|---|---|---|---|---|---|
| Knowledge Topic | Knowledge | `topicId` | No (bundled catalog) | `/knowledge/topic/:id` | Encyclopedia favorites today |
| Article | Knowledge | `articleId` | Yes (legacy offline JSON) | `/knowledge/article/:id` | Legacy `favorites` today |
| Directory Entity | Directory | `entityId` | Optional | `/directory/:type/:entityId` | V1.5 (M6) |
| Service | Directory | `entityId` (+service) | Optional | `/directory/:type/:entityId` | V1.5 (M6) |
| Material/Product | Directory | `entityId` | Optional | `/directory/...` | V1.5 (M6) |
| Tool shortcut | Tools | `toolKey` | No | `/tools/...` | Conservative (optional; result→Projects, not Saved) |

**Conservation rule:** do **not** save raw calculation sessions/results into Saved; **project-owned historical results belong in Projects**, not Saved. Saved is not a substitute for Projects (M5 §9/§10/§18).

---

## 13. Current Saved Migration

Current favorites/downloads must **survive migration**.
- Legacy `favorites` (article ids) → `SavedItemReference{ownerDomain=knowledge, entityType=article, entityId}`.
- `encyclopediaFavorites` (topic ids) → `SavedItemReference{ownerDomain=knowledge, entityType=topic, entityId}`.
- `downloads` + `offline_$articleId` → volitional offline state + corresponding article reference (or a distinct download reference), preserving the offline JSON.

Migration pattern (never discard existing favorites): **read legacy → normalize/reference → verify → maintain compatibility → retire legacy storage only later.** Preserve meaning of every stored favorite/download (§29). No deletion.

---

## 14. Saved Resolution

Saved item selected → `SavedItemReference` → **owner-domain resolver** → canonical source-domain detail (M3 §13):
- `topicId` → Knowledge Topic Detail
- `supplierId` → Directory Entity Detail
- `articleId` → Knowledge Article Detail

**No duplicate Saved detail screens.** Resolve through existing owning-domain navigation/data (M3 §13).

---

## 15. Downloads / Offline

Offline must be **explicit and domain-aware**. Different domains have different offline semantics (M1 §14; M4 §21). Avoid one ambiguous boolean "downloaded".

**Offline Semantics Table**

| Domain | Offline Authority | Cache? | Download? | User-Owned? | Notes |
|---|---|---|---|---|---|
| Knowledge | Packaged read-only offline app data (bundled generated catalog); Content Studio is authoring authority | No (packaged app data, not a cache) | Legacy articles only today; User owns download refs, Knowledge owns content | User-owned download refs only | Packaged data ≠ cache §16.1; never editing source |
| Tools | Local logic (calculators/checklists) | N/A (local by nature) | N/A | — | No remote dependency for calculation logic |
| Projects | Local-first **authoritative local data** | No (not a cache; owns local records) | N/A | Yes (projects) | Must remain available offline; remote sync optional/additive |
| Directory | Remote-authoritative (future) | Yes (cached projections/recent/saved) | No full download | Refs | Do NOT promise full offline directory; cache ≠ ownership (M6 §21) |
| Ads | — | Short-lived placement cache only (future) | No | No | Expired/invalid campaign → no ad (M6 §27) |

---

## 16. Domain-Specific Offline Semantics

### 16.1 Offline ownership clarification (approved)
Distinguish **packaged data**, **cache**, **download selections**, and **local-first authority** for each domain:

- **Packaged Knowledge catalog is NOT a cache.** The bundled/generated encyclopedia catalog shipped with the app is **packaged read-only offline application data for the published app version** — not a "cache" in the normal cache semantics. Classification:
  - Content Studio / Draft JSON → **authoring authority**.
  - Exported / generated catalog bundled with app → **packaged read-only offline application data** (read-only, generated output, offline available, replaceable by a future app/content release).
  - It is **NOT** authoring source, editable source, user-owned data, or a temporary cache.
  - A future **runtime cache, if introduced, is a separate concept** from the bundled catalog.
- **Download selection vs downloaded-content ownership.** The User owns the *fact* of a download (the download preference/reference/state metadata). **Knowledge owns** the Knowledge entity/content identity and content semantics. **Offline infrastructure** may store a local offline representation/cache/artifact, but that does **not** make it the authoritative owner of the Knowledge entity. Conceptually:
  ```
  User Download Reference   → references the Knowledge entity
  Knowledge Content         → remains Knowledge-owned
  Offline Stored Representation → local persistence/projection only
  ```
  Do **not** duplicate full Knowledge ownership into User/Saved.
- **Directory offline data** may correctly be described as **cache / cached projection**, because it is a locally retained representation of **remote-authoritative** Directory data. This distinction is preserved.
- **Projects are NOT a cache.** Projects remain **local-first user/business data**; primary local Project persistence is **authoritative for local-only Project records** until future sync architecture is introduced.

### 16.2 Domain semantics
- **Knowledge:** the bundled generated catalog is packaged read-only offline application data (§16.1). Downloaded/saved knowledge may add offline state (User owns download references; Knowledge owns content). **Content Studio remains source authority; offline/data-derived replications do NOT become editing source** (M4 rule 3).
- **Tools:** calculators/checklists logic remain locally usable; typically no remote dependency for calculation logic.
- **Projects:** local-first **authoritative local data**, not cache; must stay available offline; future remote sync optional/additive (§16.1).
- **Directory:** remote-authoritative (target); offline = **cached projections**/recent/saved items; **do NOT promise full offline directory**, and the cache never equals ownership (M6 §21).
- **Ads:** may be cached for short-lived placement continuity **if later justified**; **expired campaign must never remain indefinitely visible offline; no campaign / invalid campaign → no ad** (M6 §27).

### Offline State Model
Avoid one ambiguous boolean "downloaded". Define conceptual states **only where useful**: `availableOffline`, `cached` (for cache-eligible domains such as Directory), `downloaded` (volitional, user-requested), `stale`, `unavailableOffline`. Do not over-engineer — most domains need only a couple of these.

---

## 17. Connectivity Boundary

`ConnectivityProvider` exists and is lifecycle-safe. Connectivity informs UI/state.
**Connectivity must NOT become source-of-truth for whether data exists:**
- offline + cached entity → readable
- online + missing entity → unavailable
- Do not equate network state with content availability (§16).
Connectivity drives presentation hints (e.g. header dot, offline banner) and future sync triggers — never entity existence.

---

## 18. User Area

Target **User Area accessed from Avatar** (not a Bottom Nav slot; M1 §6/§19; M3 §12).
User Area may include: Profile, Edit Profile, Saved, Downloads, Recent Activity, Preferences, Theme, Language, Backup, Account/Auth.
**Do not make User Area a God provider** — it is a navigation/aggregation surface into user-owned state and domain surfaces; it owns no domain entities.

---

## 19. User Ownership

User domain owns (User-owned state, M4 §9):
- profile
- preferences
- theme preference
- language preference
- saved references
- recent activity metadata
- recent searches if retained
- current project selection if approved
- download/offline user selections

User does **NOT** own: Project, Topic, Supplier, Tool, Ad. Only references/preferences (M4 §9; M6 §17).

**User State Ownership Table**

| State | Owner | Persistent? | Cross-device later? | Sensitive? | Notes |
|---|---|---|---|---|---|
| Profile | User | Yes (SharedPreferences `local_user_profile`) | Yes | Medium | `LocalUserProfile` |
| Preferences/settings | User | Yes | Yes | Low | Currently inline in ProfileScreen |
| Theme preference | User | Yes (`isDarkMode`) | Yes | Low | `ThemeProvider` |
| Language preference | User | Not yet (Arabic forced) | Yes | Low | Target §23 |
| Saved references | User | Yes (Hive) | Yes (V2+) | Medium | References, not copies |
| Recent activity metadata | User | Optional | Yes | Medium | Convenience only (§25) |
| Recent searches | User | Optional (bounded) | Yes | Medium | Privacy-bound (§9/§34) |
| Current project selection | User (pref) | Yes | Yes | Low | Pointer only; Project is owner (§26) |
| Downloads/offline selections | User | Yes (Hive `downloads` + offline JSON) | Yes (V2+) | Low | V1 legacy |

---

## 20. Profile

Define practical profile scope — **do not invent social-network-style complexity**.
Potential:
- display name
- professional role (`CivilUserType`)
- specialty
- location (`BaghdadArea` initially; general location later)
- optional profile image
- contact/account state

**Separate public/business identity from private user profile.** Directory business entity **≠** User Profile (M6 §4/§20); never merge them. Existing `CivilUserType`/`BaghdadArea` are profile metadata (M4 §9), not Directory entities.

---

## 21. Auth / Identity

Auth is an **identity/session** concern. **Do not let AuthProvider become application-wide business-state owner.**
Conceptual separation:
- **Identity / Session** → authenticated user ID.
- **User Profile** → user-owned profile/preferences (`LocalUserProfile`).
- Projects policy may consume the identity contract.
- Directory claim/business ownership may consume identity later (M6 §24).

Do not design backend auth implementation. Note current debt: `AuthProvider` (in-memory) vs orphaned `AuthRepositoryImpl` (persistent, unwired) — flag to reconcile in a later phase; do not force guest mode to depend on auth (§22).

---

## 22. Guest Mode

**Recommended product principle:** Civilpedia core **Knowledge + Tools are usable as guest** (no login), because engineering content must not be gated. Projects / cloud sync / cross-device Saved **may** require an account later depending on feature.
- Guest mode remains viable — do not force authentication before engineering content unless a real product reason exists.
- Auth is a session concern, not an entry gate for Knowledge/Tools (§21).

---

## 23. Language

Current: Arabic/English localization resources exist, but app **forces Arabic** (`LanguageProvider` hardcoded `Locale('ar')`; `supportedLocales:[ar]`; ad-hoc `tr()`).
Target architecture: **Arabic-first, RTL-first, English-compatible.**
- Language preference belongs to **User/preferences**.
- **Do NOT remove English fields/resources.**
- Do **not** implement a language switch now (architecture only).

---

## 24. Theme

Theme preference belongs to **User/preferences**.
- Architecture preserves: Light is the current visual target; theme-aware presentation; final Dark polish deferred (M1 §?; current `isDarkMode` toggle exists).
- **No theme logic in feature business models** — theme is a presentation concern, not entity data (M4 §?? — theme is preference, not domain entity).

---

## 25. Recent Activity

Lightweight concept — **not enterprise event sourcing**:
- recently opened Topic
- recently used Tool
- recently opened Project
- recently viewed Directory Entity

Recent Activity is **user convenience metadata**; source domains remain authoritative. It may be a small, bounded, optionally-persisted list per user, surfaced on Home/User Area. No audit infrastructure; no copies of entities (only references + optional lightweight display).

---

## 26. Current Project Preference

M5 deferred "Current Project quick selection" to **V1.5**. Ownership:
- **User/preference state** may store `currentProjectId` (a pointer).
- **Projects remains source owner** — no duplicate Project data.
- If current project is **archived/deleted/unavailable**: **clear or require reselection gracefully** (graceful fallback; never silently point at another project).
- Consistent with M5 §19/§26 (current project selection is user preference, not a second owner).

---

## 27. Backup

Current `BackupService` is partial. **Backup should coordinate domain-export contracts** rather than manually reaching into every private storage forever.

Conceptual:
```
BackupCoordinator
├── UserBackupProjection
├── ProjectsBackupProjection
├── SavedBackupProjection
└── other approved local user-owned data
```
- **Knowledge packaged catalog should not be backed up** as user data — it is packaged read-only offline application data (generated, reproducible by a future content release), **not** a cache and **not** user-owned (§16.1).
- **Directory cache should not necessarily be backed up.**
- **Ads definitely should not be backed up.**

**Backup content principles (user-important, back up):**
- profile/preferences (user-owned)
- Saved / download **references** (user-owned)
- Projects and project-owned records (authoritative local data, not cache)
- local notes / checklist executions / calculation snapshots

**Do NOT back up merely reproducible data:**
- packaged/generated Knowledge catalog (regenerable packaged app data)
- Directory cache (cached projection of remote authority)
- temporary search index
- active ad campaign cache

**Downloaded Knowledge artifacts** (the local offline representation/cache/artifact of Knowledge content) may be **re-acquired** rather than treated as primary backup data, unless future product requirements explicitly say otherwise — because Knowledge content remains Knowledge-owned and the packaged app data is reproducible; the **download reference** (User-owned) is what matters for backup, not the binary artifact itself.

Backup is a cross-domain infrastructure service calling each domain's export contract (M4 §16), not UI-driven ad-hoc code scattered across features (M4 §26 #10; M5 §23).

---

## 28. Backup Restore

Future restore must:
- **validate**
- **version-check**
- restore user-owned records safely
- **preserve IDs/references**
- handle **missing source-domain entities gracefully** (e.g. saved reference to a removed Directory entity → tombstone/removed state, not a silent redirect)

Do not design implementation now. Note the current `TODO(BACKUP-1C)` gaps (projects/checklists/favorites/downloads restore) as known debt to close in a data phase, preserving stored data.

---

## 29. Migration Safety

Existing Saved/Profile/Download data must **not** disappear when the target architecture is introduced. For every current storage, document: current format, current owner, target representation, migration strategy, compatibility period, retirement gate. **No blind key renames/deletes.**

**Current → Target Migration Table**

| Current Storage/Feature | Current Representation | Target Representation | Migration Path | Compatibility Requirement | Removal Gate |
|---|---|---|---|---|---|
| `encyclopediaFavorites` (Hive) | topic id list | `SavedItemReference{knowledge,topic,id}` | map ids → references | Saved topics unresolvable-free | After references verified + Saved works |
| `favorites` (Hive legacy) | article id list | `SavedItemReference{knowledge,article,id}` | map ids → references | All favorites kept | After references verified |
| `downloads` + `offline_$id` (Hive) | id list + full article JSON | download reference + offline snapshot | preserve JSON + reference | Downloads readable offline | After new offline store verified |
| `local_user_profile` (SharedPreferences) | LocalUserProfile JSON | User-owned profile | keep key; read-old-gracefully | Profile preserved | After successor verified (or none) |
| `isDarkMode`, `onboardingSeen` (Prefs) | booleans | User preferences | keep keys; map to preference model | Persisted | After PREFS roll-out verified |
| `projects_list`/`checklist_*` (SharedPreferences) | Projects/tools data | Projects domain (M5) | per M5 migration | No data loss | After Projects verified |
| Backup file (v1) | BackupSections | BackupCoordinator projections | keep v1 readable; version-check | Old backups importable | After restore complete (BACKUP-1C closed) |
| Auth local keys (`auth_email`, `register_*`) | SharedPreferences (orphaned repo) | Auth identity/session | reconcile AuthProvider/Repo; keep readable | Login state preserved across upgrade | After Auth phase |
| Encyclopedia search (in-memory) | provider filter | Knowledge search source | lift into projection | Knowledge search works during transition | After Global Search shell verified |

---

## 30. Stable IDs

Cross-domain reference keys must use **stable source IDs**. **Never store** as identity: Arabic title, English title, screen label, translated route text. This applies to Saved references, Search result identity (`ownerDomain/entityType/entityId`), Recent Activity refs, current project pointer, and backup references (M4 rule 11; M6 §33; M5 §33). Stable keys survive renames and support offline cache + future backend migration.

---

## 31. Feature Flags

Feature flags determine **exposure only**; they **do not own data** (M4 rule 12).
Examples:
- Global Search disabled → current Knowledge search remains.
- Directory disabled → Saved Directory refs may show unavailable **if** the feature is intentionally unavailable (graceful tombstone, not a fake screen).
- Projects disabled → no bottom-nav entry; Saved/activity refs to projects handled gracefully.
**No fake empty screens** (M1 §17 / M3 "NOT READY → NOT EXPOSED"). Dormant `FeatureKey`/`PlanTier` layer exists (declared, not enforced) — it gates visibility, never ownership.

---

## 32. Home Integration

Home consumes lightweight projections:
- recent activity projection (§25)
- Saved / Continue projection
- current project summary
- search entry (Global Search)
- offline status (ConnectivityProvider)

**Home does not import private Saved/Profile/Project storage implementations.** Home is an aggregator, never an owner (M4 §13/§16; M1 §4) — no direct HiveHelper / SharedPreferences access from Home (clean-code requirement). Define lightweight projections only.

---

## 33. Monetization Boundary

Saved / User / Profile / Projects are **not advertising data sources by default** (M6 §28; M4 rule 9).
Do **not** use for ad targeting without future explicit privacy design:
- private saved items
- private project activity
- private notes
- backup data

Directory search context may be a future **safe contextual signal only if privacy-approved** (M4/M6). Ads reference Directory entities, never duplicate; User/Saved/Profile/Projects data is never an implicit targeting source.

---

## 34. Privacy

Define:
- **Search history may be sensitive** — bounded, clearable, never shared by default.
- **Project content is private.**
- **Saved may reveal professional interests.**
- **Backup data is private** (file access controlled).
- **Profile data needs explicit visibility rules** (public vs private).
- **Analytics must avoid raw private content** (no notes/calc inputs/attachments; review/activity minimal).

Do not choose an analytics vendor. Monetization may use only safe context (§33). Cross-domain search/user projections never expose private Project internals (§35).

---

## 35. Error / Failure Isolation

Document (prefer graceful partial functionality; **one failed source must not break the whole system**):

- **Saved reference → deleted Topic** → tombstone/unavailable; allow removal.
- **Saved Directory entity unavailable** → graceful removed state (M6 §34).
- **Current project archived/deleted** → clear/require reselection (§26).
- **Offline item cache missing** → cached-stale/unavailable-offline state; no silent substitute.
- **Corrupt local Saved record** → skip that record, keep others; surface removal option.
- **Backup version unsupported** → clear "unsupported version" message; never destructively restore.
- **Anonymous user attempts account-only action** → prompt/redirect; core Knowledge/Tools still usable (guest mode §22).
- **Global Search domain source fails** → show available domains' results + partial-failure notice (§5/§7); never all-or-nothing.
- **Partial search result availability** → render what resolved; mark unavailable gracefully.

**Global Search failure isolation (important):** if the Directory source fails, Knowledge/Tools/Projects results must still appear where possible. **Avoid all-or-nothing search architecture** (§5/§7).

**Saved failure isolation:** one stale Saved reference must not break the Saved screen — resolve independently, display unavailable/tombstone, allow removal.

**Offline failure isolation:** a stale Directory cache must not corrupt Knowledge/Projects/Tools — keep **domain offline state isolated** (§16), so one domain's offline problem never affects another's.

---

## 36. Bottom Navigation Migration

M3 target: Saved and Profile are **not** permanent bottom-nav destinations. Define **safe user-state migration timing**. Do **not** remove them until:
- **Avatar/User Area exists** and works,
- **Saved access remains easy** (from User Area and/or Knowledge),
- **Profile/settings remain reachable**,
- future **Projects/Directory tabs are ready** (NOT READY → HIDDEN).

No user-access regression. Current 5 tabs (Home, Encyclopedia, Tools, Saved, Profile) stay until those gates pass (M1 §6/§19; M3 §12-13/§20/§29/§35).

---

## 37. V1 / V1.5 / V2+ Roadmap

**V1 (practical):**
- Global Search: **Knowledge + Tools**.
- Saved: preserve current encyclopedia + article favorites; unified presentation if safe; owner-domain references architecture.
- User: Profile, Preferences, Theme, Language architecture, Saved access, Backup visibility/status.
- Offline: packaged Knowledge, local Tools, local Projects, current downloads preserved.

**Do NOT require Directory/Projects Global Search in V1 if those domains are not production-ready.**

**V1.5 (potential):**
- Global Search adds Projects.
- Global Search adds Directory.
- generic Saved references expanded.
- Recent Activity.
- Current Project preference.
- richer offline metadata.

**V2+ (potential):**
- cloud Saved sync
- cross-device preferences
- cloud backup/sync
- smarter search ranking
- search suggestions
- account-based activity
- personalized discovery only with privacy design

**V1 Roadmap Table**

| Capability | V1 | V1.5 | V2+ | Reason |
|---|---|---|---|---|
| Global Search — Knowledge | ✓ | ✓ | ✓ | Core; existing seed |
| Global Search — Tools | ✓ | ✓ | ✓ | Local logic, easy |
| Global Search — Projects | — | ✓ | ✓ | Projects-ready only (M5) |
| Global Search — Directory | — | ✓ | ✓ | Directory-ready only (M6) |
| Saved — preserve favorites | ✓ | ✓ | ✓ | Data safety |
| Saved — unified refs presentation | ✓ | ✓ | ✓ | References architecture |
| Saved — expanded entity types | — | ✓ | ✓ | Directory/tool refs |
| User — Profile | ✓ | ✓ | ✓ | Core |
| Preferences / Theme / Language arch | ✓ | ✓ | ✓ | Architecture now; switch later |
| Backup visibility/status | ✓ | ✓ | ✓ | Surface existing backup |
| Offline — Knowledge/Tools/Projects | ✓ | ✓ | ✓ | Already offline-first |
| Recent Activity | — | ✓ | ✓ | Convenience |
| Current Project preference | — | ✓ | ✓ | M5 V1.5 |
| Richer offline metadata | — | ✓ | ✓ | State model per domain |
| Cloud Saved sync / cross-device | — | — | ✓ | Future infrastructure |
| Cloud backup/sync | — | — | ✓ | Future infrastructure |
| Smarter ranking / suggestions | — | — | ✓ | Backend/alg later |
| Personalized discovery | — | — | ✓ | Privacy design required |

---

## 38. Current → Target Migration

See §10 (search), §13 (saved), §27–28 (backup), §29 (migration safety) and the **Current → Target Migration Table** (§29). High-level staged path, no big-bang:
1. **Preserve** current search, favorites, downloads, profile, backup behavior.
2. **Introduce** the Saved reference model (ownerDomain/type/id) reading legacy — verify.
3. **Introduce** Global Search shell aggregating Knowledge + Tools; keep encyclopedia search working.
4. **Add** Projects/Directory sources when those domains are ready.
5. **Repoint** user area (Avatar) + Saved access; move Profile/Saved off bottom nav only after gates pass.
6. **Reconcile** Auth (identity/session) and **complete** backup restore (BACKUP-1C) preserving all stored data.
Retire legacy storage only after compatibility is proven (§29).

---

## 39. Open Decisions

1. **Global Search shell timing** — when `/search` replaces/extends `/encyclopedia?q=` entry.
2. **Search history retention** — bounded local list vs. none (V1); privacy boundaries.
3. **Saved reference store rollout** — when `ownerDomain/type/id` replaces/legacy-reads `favorites`/`encyclopediaFavorites`/`downloads`.
4. **Downloads model** — volitional download vs. download-as-Saved-reference; offline snapshot depth per domain.
5. **Auth reconciliation** — `AuthProvider` (in-memory) vs orphaned `AuthRepositoryImpl` (persistent); guest-mode/auth contract.
6. **User Area composition** — full-screen list vs. sections; where Preferences/Settings live.
7. **Language switch timeline** — architecture now; actual English RTL/LTR UI later (Arabic-first).
8. **Theme dark polish** — deferred (Light is target); keep theme preference arch.
9. **Recent Activity structure & bounds** — V1.5; what gets recorded, persistence, clearable.
10. **Current Project preference rollout** — V1.5; pointer semantics + graceful clear.
11. **Backup completeness scope** — which projections join backup first (BACKUP-1C closure).
12. **Bottom-nav migration gates** — exact readiness checklist for removing Saved/Profile from the 5 tabs.

---

## 40. Non-Negotiable Rules

1. Source domain is authoritative; Search/Saved/Offline/User hold indexes/references/preferences only (M4 rule 1/2/7/9). 2. Search owns nothing but index/projection/aggregation; owns no detail screens (§4/§6). 3. Saved stores references (`ownerDomain/type/id`), never full copies unless explicit offline projection (§12/§14). 4. Offline cache ≠ ownership; domain offline state isolated (§16/§35). 5. User owns only profile/preferences/saved refs/recent metadata/pointers — never Projects/Knowledge/Directory entities (§19). 6. Never store translated names/labels/routes as identity (§30). 7. Feature flags gate exposure, never ownership; no fake empty screens (§31/M3). 8. Home is aggregator; never imports private storage impls (§32). 9. Monetization never targets from private saved/project/profile/backup data without explicit privacy design (§33). 10. Failure isolation — no all-or-nothing Search/Saved/Offline (§35). 11. Backup excludes generated/cache/ad data and only includes user-important owned data; restore validates + version-checks + preserves IDs (§27–28). 12. Migration preserves current favorites/downloads/profile; no blind key renames/deletes; retire legacy only after verification (§13/§29). 13. Guest mode stays viable — Knowledge/Tools usable without login (§22). 14. Bottom-nav transition gates remove Saved/Profile from nav only after User Area + Saved access + Projects/Directory ready (§36). 15. Theme/language are preferences, not business-model data; English resources preserved (§23/§24). 16. No production/storage/content changes in this phase.

---

## Requirements Traceability (M7)

Confirmed covered: Global Search (§4–8), Knowledge search (§5/§10/§16), Tool search (§5/§16), future Projects/Directory search (§5/§37+§31), Saved/favorites (§11–14), current favorites preservation (§13/§29), downloads (§15–16/§13), offline-first (§15–17), Profile (§20), Auth boundary (§21), Guest mode (§22), Arabic/RTL (§23), English future (§23/§40), theme preference (§24), recent activity (§25), current project preference (§26), backup (§27–28), privacy (§33–34), failure isolation (§35), no duplicated ownership (§3/§12/§19), clean code (§3/§32 — Avoid-list: no giant UserProvider/GlobalSearchRepository, no Saved copies, no Home↔Hive, no UI-built repos, no backup reaching into every storage, no localization identity keys, no scattered SharedPreferences keys, no cross-domain storage imports), no fake unfinished features (§31/M3).

**Verification checklist (all pass):** Search owns no source data (§4); Saved owns references only (§12); Offline cache does not become owner (§16); User does not own Projects/Knowledge/Directory entities (§19); Backup excludes generated/cache data (§27); migration preserves current favorites/downloads/profile (§13/§29); partial search source failure isolated (§35); stale Saved reference survivable (§35); guest mode viable (§22); bottom-nav transition does not remove user access (§36); feature-disabled domains stay hidden (§31).

---

## Material Contradiction Check (M7)

No material contradiction with M1–M6 was found. M7 aligns with: M1 cross-domain/offline/Saved role (§4, §13, §14), M3 User/Saved/Global Search navigation (§12–14) and NOT READY → HIDDEN, M4 User/Saved ownership, `GlobalSearchGateway`/`SavedItemsStore` contracts and dependency matrix, M5 (Projects search projections, current-project as preference), and M6 (Saved references, Directory offline cache, sponsored neutrality). No STOP condition applied; backup ownership is definable without code/schema changes (documented, current PDFs preserved).

---

## Protected / Forbidden (unchanged)

ZERO changes to: `lib/**`, `test/**`, `assets/**`, `draft_jsons/**`, `app_ready_jsons/**`, Content Studio, exporters, schemas, generated catalogs, `pubspec.yaml`, branding, and the approved M1–M6 docs. This phase created exactly one file: `docs/architecture/CIVILPEDIA_SEARCH_SAVED_OFFLINE_USER_ARCHITECTURE.md`.
