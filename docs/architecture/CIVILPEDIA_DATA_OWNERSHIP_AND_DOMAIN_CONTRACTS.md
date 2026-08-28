# CIVILPEDIA — DATA OWNERSHIP & DOMAIN CONTRACTS

**Phase:** M4. **Status:** ARCHITECTURE / DOCUMENTATION ONLY — no production code changed.
**Inputs:** `CIVILPEDIA_PRODUCT_ARCHITECTURE.md` (M1), `CIVILPEDIA_SCREEN_MAP.md` (M2), `CIVILPEDIA_NAVIGATION_ARCHITECTURE.md` (M3), plus live repository inspection of the current data layer.

> This is the authoritative ownership model for Civilpedia data and the contracts domains use to interact. It is **target** architecture; current reality (with its debt) is described separately (§3, §26). No production change, no schema/exporter/content change, no implementation.

---

## 1. Purpose

Prevent future architectural failures by making ownership explicit and by defining the contracts through which product domains interact. Specifically guards against:

- Home becoming a God feature (owns everything).
- Projects directly manipulating Tools repositories.
- Directory leaking into Knowledge.
- Saved copying full entities from every domain.
- Search owning data that belongs to other domains.
- UI screens importing repositories from unrelated features.
- raw route strings becoming business/data relationships.
- duplicated ownership of the same entity.
- circular dependencies.

---

## 2. Core Ownership Rules

1. **Every persistent/business entity has exactly ONE authoritative owning domain.**
2. Other domains may: **reference** it, **query** it through a public contract, or hold an explicit **snapshot** when required — but never silently become a secondary owner.
3. Target direction per domain:
   ```
   Domain Owner → Domain API / State Contract → Repository → Data Source
   ```
4. Cross-domain consumers depend on a **stable contract**, not private implementation details.
5. **Offline cache ≠ ownership** — a cached/projected copy does not make the caching domain the owner (§21).
6. **Feature flags control exposure, not data ownership** (§24).
7. **Content Studio ownership is non-negotiable and pre-established** (§4 and mandated below).

---

## 3. Current Data Architecture Baseline (verified)

### Persistent stores in use today
| Store | Usage | Backing |
|---|---|---|
| Hive box `civilpedia` (`AppConstants.hiveBoxName`) | favorites, encyclopediaFavorites, downloads, offline article payloads | Hive (`lib/data/local/hive_helper.dart`) |
| SharedPreferences | dark mode, onboarding, user profile (`local_user_profile`), service businesses (`sb_profiles`), checklist global (`checklist_data`), checklist per-project (`checklist_project_<id>`), projects (`projects_list`) | SharedPreferences |
| Bundled asset | `assets/encyclopedia/catalog.generated.json` (primary) + legacy `catalog.json` (fallback) | read-only parse |

### Domain wiring today (`lib/core/di/app_dependencies.dart`)
- `encyclopediaRepo` (used by `EncyclopediaProvider`), `userProfileRepo` (used by `UserProfileProvider` + `BackupService`), `businessRepo` (**wired but unused**), `checklistRepo`/`projectRepo` (**getters unread; singletons feed only `BackupService`**), `backupService`, `backupFileService`.
- `ArticleRepository` is a **static in-memory global outside DI** still feeding Saved, Tools grid, Home latest-articles, and article screens.
- UI self-instantiates data layer: `LocalChecklistRepository` 3×, `LocalProjectRepository` 2×, `LocalAdDataSource` (in `ad_carousel_widget.dart`), direct `HiveHelper` reads in Saved, direct `ArticleRepository()` in article screens.
- Calculators are **pure** (zero persistence).
- `LocalServiceBusinessRepository` + `ServiceBusinessDataSource` = **wired-but-unused scaffolding** (Directory seed).
- Backup omits encyclopedia favorites and only partially restores (documented `TODO(BACKUP-1C)`).

### Classified debt (details in §26)
SAFE CURRENT / MIGRATE LATER / COMPATIBILITY / ARCHITECTURAL DEBT / BLOCKER(s) — see §26.

---

## 4. Domain Ownership Overview

| Domain | Owns (authoritative) | Does NOT own |
|---|---|---|
| Knowledge | Encyclopedia Topic, Category, Section, Content Block, Article (legacy), knowledge metadata, knowledge favorites | Tool formulas, Projects, Directory entities |
| Tools | Tool/Calculator definition, checklist template + item definitions, inspection template/reusable logic, calculator session/result (before save), global checklist state | Project persistence, Directory entities |
| Projects | Project, project metadata/activity/notes/attachments, project calculation snapshots, project checklist executions, project inspection records, project materials, project-linked supplier refs, project reports | Source Knowledge, Tool definitions/formulas, Directory entities |
| Directory | Directory/Business entity (company, contractor, consultant, office, supplier, technician, shop, service, material/product), verification state, directory categories/type, service areas/location, organic listing | Engineering content, sponsorship/campaign (Monetization owns that) |
| Monetization | Advertisement Campaign, Ad Creative, Placement, Sponsored Listing relationship, sponsorship period/state, impression/click tracking | Directory business entity, Knowledge |
| User | Profile, preferences, recent activity, downloads/offline selections, Saved references | Source-domain entities |
| Search | Index / projection / aggregation only | Source entities |
| Home | Dashboard composition/cache projections only | All source entities |

---

## 5. Knowledge Ownership

- **Authoritative owner:** Knowledge (wrapping the unchanged Content Studio pipeline).
- Owns: `EngineeringTopic`, `CategoryInfo`, `TopicSection`, every `ContentBlock` subtype, `CodeReference`, `LocalizedText`, `AcceptRejectItem`, knowledge favorites relationships.
- The generated catalog and topic app-ready JSONs remain **outputs**; `EncyclopediaJsonDataSource` reads them as an authoritative read-only asset. `EncyclopediaLocalDataSource` is a fallback (mock) — not a real store.
- **ArticleRepository coexistence (no premature merge):** the legacy static `ArticleRepository` is a **CURRENT — CONSOLIDATE LATER / COMPATIBILITY** source alongside the authoritative encyclopedia. Home **categories** already source from `EncyclopediaProvider` (documented in code), but Saved downloads/favorites, Tools registry, and latest-articles still read `ArticleRepository`. Ownership rule: **legacy articles remain Knowledge-owned; the encyclopedia catalog is the declared source of truth for categories/topics.** Consolidation is deferred (M1 open decision #1), not implemented.
- Knowledge must not import Tool/Directory/Project repositories.

---

## 6. Tools Ownership

- **Authoritative owner:** Tools.
- Owns: Tool definition (`ToolModel`), Calculator definition/formula (pure functions: `concrete`, `steel`, `tile`, `masonry`), calculator input/session and **result before save**, checklist **template** + item **definitions**, inspection **template**/reusable inspection logic, and the **global** checklist state (not project-scoped).
- Calculators are pure today (no persistence) — reinforced: the reusable definition/formula is Tools-owned and stateless.
- Model location note: `InspectionItem`/`InspectionCategory` currently live in the **presentation** layer (`.../checklist/models/`) with seed data (`inspection_seed_data.dart`). Target: classification in §19 — template/definition should be domain-owned; presentation models should be views of it. Not rewritten now.
- **Template vs execution** is critical and explicit (§13): Tools owns the reusable template; Projects owns project-specific executions/records.

---

## 7. Projects Ownership

- **Authoritative owner:** Projects (currently embedded under Tools — see §26 debt; the domain, not its physical location, defines ownership).
- Owns: `Project` (+ metadata), project activity, project notes, project attachment/document metadata, project calculation **snapshot/reference**, project checklist **execution**, project inspection **record**, project material record, project-linked supplier/service **reference**, project report.
- **Must NOT own:** source Knowledge topics, Tool definitions/formulas, Directory entities.
- Current persistence: `Project` under `projects_list`; per-project checklist under `checklist_project_<id>` — both SharedPreferences, both physically under `lib/features/tools/data/checklist/`. This is the seed of the Projects domain.

---

## 8. Directory Ownership

- **Authoritative owner:** Directory.
- Owns: Business/Directory entity (one coherent model preferred — `BusinessType` already discriminates supplier, technician, equipmentOwner, engineeringOffice, constructionCompany, buildingOffice, testingLab, surveyor, contractor, materialShop, consultantOffice, other), company/contractor/consultant/office/supplier/technician/shop/service provider/material-product listing, **verification state** (`VerificationStatus`), directory category/type, service areas/location, organic listing data.
- **Do not force unrelated entities into one giant model if semantics differ materially** — in particular Material/Product may diverge from service/company profiles (M3 open decision #5). Preferred default is one generic entity + `BusinessType`; divergence only where materially required.
- Directory must not edit engineering content or own sponsorship.

---

## 9. User / Saved Ownership

- **Authoritative owner:** User.
- Owns: `LocalUserProfile` (+ `CivilUserType`, `BaghdadArea`), preferences, recent-activity metadata, downloads/offline selections, **Saved references**.
- **Saved state references source-domain IDs** — `entityType`, `entityId`, `ownerDomain`, `timestamp`, optional lightweight metadata. It does NOT copy full entities unless an explicit offline snapshot is required.
- Current reality: Saved merges legacy `favorites` + encyclopedia `encyclopediaFavorites` (+ downloads) in one Hive box — consistent in spirit; target keeps reference semantics and resolves through domain-owned navigation/data (M3 §13).

---

## 10. Monetization Ownership

- **Authoritative owner:** Monetization.
- Owns: Advertisement Campaign, Ad Creative, Placement, **Sponsored Listing relationship**, sponsorship period/state, impression/click tracking metadata.
- **Directory owns the business entity; Monetization owns the sponsorship/campaign relationship.** A sponsored supplier is **NOT** a second Supplier entity:
  ```
  Directory Supplier  +  Monetization Sponsorship  =  Sponsored presentation
  ```
- **Do not duplicate supplier data into Ads.** Ads reference the Directory entity.
- Current ads are mock (`LocalAdDataSource` always returns `_mockAds`); this is an ARCHITECTURAL DEBT + a correctness gap vs the "no campaign → no slot/route" rule (M1/M3). Not changed (§26).

---

## 11. Search Ownership

- Global Search is an **Index / Projection / Aggregation**, **not an Entity Owner.**
- Each domain exposes **searchable projections**; Search aggregates them.
- A search result carries enough stable identity to route to the owning domain (M3 §14/§17) — never claims source ownership.
- Search must avoid reaching into every private store directly if a projection contract is preferable.

---

## 12. Home / Dashboard Ownership

- Home owns **presentation/dashboard composition state only** — allowed to cache/project lightweight summaries.
- Home must NOT own: Knowledge, Projects, Tools, Directory, or Advertisement business entities.
- Home consumes **projections** (§18, §20) such as `CurrentProjectSummary`, `RecentKnowledgeItem`, `QuickToolSummary`, `SponsoredPlacement` — never private repositories/models of every domain.
- Current Home does read `ArticleRepository().getLatestArticles()` (legacy global) and builds ad data from a datasource; this is flagged debt (§26), not target behavior.

---

## 13. Template vs Execution Pattern (critical)

| Definition/Template (Tools-owned) | Execution/Record (Projects-owned) |
|---|---|
| Checklist template | Checklist completed for Project X |
| Inspection template / definition | Inspection record performed on Project X |
| Calculator definition/formula | Calculated result before save (Tools/session) → saved to Project (Project-owned snapshot/reference) |
| Inspection category + item definitions | Per-project item status/notes (`checklist_project_<id>`) |

Global (non-project) checklist state stays Tools-owned (quick checklist). Once a checklist/inspection/calculation is attached to a project, the **record/execution** becomes Project-owned (as a snapshot/reference).

---

## 14. Reference vs Snapshot Rules

| Case | Store | Mechanism |
|---|---|---|
| Project Calculation (Save to Project) | Projects | Inputs snapshot + result snapshot + `sourceToolId` (+ `toolVersion`/schemaVersion where needed) + unit + timestamp. Projects does **not** own the calculator formula. |
| Project Knowledge reference | Projects | `topicId` reference + optional **display snapshot** only if required for offline/history. Do NOT duplicate full Content Studio topic JSON without strong reason. |
| Project Supplier | Projects | `supplierId` reference + only project-specific metadata. Directory stays authoritative for the profile. |
| Project checklist execution | Projects | Status/notes snapshot per project key. |
| Saved item | User | `entityType`+`entityId`+`ownerDomain` reference (+ lightweight metadata). |

Prefer **Reference only (A)** as default; use **Immutable snapshot (B)** for historical project calculations/reports that must remain valid if source changes; use **Cached projection (C)** only for Home/Search presentation, never for ownership.

---

## 15. Versioning / Historical Integrity

Do **NOT** implement schema versioning now. Document where snapshot/version semantics may be required:
- **Calculator formula/version changes** → saved project calculation stores `toolVersion` + input/result snapshot so history doesn't silently change.
- **Checklist template updates** → a project inspection record snapshots the executed item set/status so template changes don't rewrite history.
- **Supplier profile changes** → project stores `supplierId` + only project-specific metadata; Directory profile changes don't retroactively rewrite project records (graceful: link may go stale — §22).
- **Topic title/content changes** → saved knowledge reference uses stable `topicId`; optional display snapshot for offline/history, never a full copy by default.
- **Project report generation** → report should embed the snapshot it was generated from (inputs/results) so it remains valid.
- Versioning is a **snapshot/schema-version semantic** to introduce later per domain, from the authoritative source only.

---

## 16. Cross-Domain Contracts

### Knowledge → Tools
- `RelatedToolReference`. Knowledge must **not** own Tool routes.
- Current reality: `relatedToolRoutes` holds raw navigation strings in content. **DO NOT change these now.**
- Future compatibility strategy: `Legacy raw route → compatibility resolver → stable ToolKey / ToolDestination contract`. **Any future content migration MUST originate from Content Studio/Draft source, never generated outputs.**

### Tools → Projects
- `SaveCalculationToProject`, `SaveChecklistExecutionToProject`, `SaveInspectionToProject`.
- Tools must **not** import `LocalProjectRepository` directly as the long-term contract — use a boundary/API (e.g. `ProjectWorkspaceGateway`), not direct repo construction.
- Not implemented.

### Projects → Directory
- Project-linked supplier/service = **reference contract** (`supplierId`, optional display fields). Projects must not own/edit Directory profiles.

### Home → Domains
- Home consumes lightweight projections: `CurrentProjectSummary`, `RecentKnowledgeItem`, `QuickToolSummary`, `SponsoredPlacement`.
- Not private repositories/models from every domain.

### Search → Domains
- Each domain exposes searchable projections; Search aggregates. It does not access every private store directly if avoidable.

### Saved → Domains
- `SavedItem` = `entityType`, `entityId`, `ownerDomain`, `timestamp`, optional lightweight metadata. Resolves through domain-owned navigation/data. No giant polymorphic copied store.

### Monetization → Home / Directory
- Monetization exposes placements; Home renders `SponsoredPlacement` only when a campaign is active; Directory merges organic + sponsored at presentation, referencing Directory entities.

---

## 17. Domain Dependency Matrix

Rows → columns = "row may depend on column". Legend: ✅ ALLOWED, 🔗 CONTRACT-ONLY (public contract/snapshot/reference), ⛔ FORBIDDEN.

| From \ To | Home | Knowledge | Tools | Projects | Directory | User | Search | Monetization |
|---|---|---|---|---|---|---|---|---|
| **Home** | — | 🔗 | 🔗 | 🔗 | 🔗 | 🔗 | 🔗 | 🔗 |
| **Knowledge** | ⛔ | — | 🔗 | ⛔ | ⛔ | ⛔ | 🔗 | ⛔ |
| **Tools** | ⛔ | ⛔ | — | 🔗 (save contract) | ⛔ | ⛔ | 🔗 | ⛔ |
| **Projects** | ⛔ | 🔗 (topic ref) | 🔗 (snapshot) | — | 🔗 (supplier ref) | ⛔ | 🔗 | ⛔ |
| **Directory** | ⛔ | ⛔ | ⛔ | ⛔ | — | ⛔ | 🔗 | 🔗 (sponsorship ref) |
| **User** | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | — | 🔗 | ⛔ |
| **Search** | ⛔ | 🔗 | 🔗 | 🔗 | 🔗 | ⛔ | — | ⛔ |
| **Monetization** | 🔗 (placement) | ⛔ | ⛔ | ⛔ | 🔗 (listing ref) | ⛔ | 🔗 | — |

Key directions called out by the task:
- Home → public projections from domains (🔗).
- Knowledge → Tools via stable reference/contract only (🔗).
- Tools → Projects via save contract only (🔗).
- Projects → Directory via entity reference contract (🔗).
- Search → searchable projections (🔗).
- Monetization → placement/entity references (🔗).
- Directory → Knowledge = ⛔ normally forbidden.
- Ads → engineering content ownership = ⛔ forbidden.

**No circular domain imports.** E.g. Tools→Projects via contract, never Projects→Tools internals; the current Tools-contains-Projects physical layout is debt, not a circular contract.

---

## 18. Public Domain API Concepts

Conceptual public interfaces (NOT code; do not overengineer — only useful boundaries):
- `KnowledgeCatalog` — topics/categories/sections/blocks + knowledge favorites.
- `KnowledgeFavorites` — reference set.
- `ToolCatalog` — tool/calculator definitions.
- `ProjectWorkspaceGateway` — project CRUD + store/read snapshots (the only way Tools write to Projects).
- `DirectoryCatalog` — directory entities by `BusinessType` + search projections.
- `GlobalSearchGateway` — aggregate over per-domain searchable projections.
- `SavedItemsStore` — reference records (`entityType/entityId/ownerDomain`).
- `AdPlacementProvider` — campaign-gated placements; never entity data.

Rule of thumb: create a boundary only where a real cross-domain dependency exists; do not wrap every file (clean architecture ≠ maximum abstraction).

---

## 19. Entity / DTO / View Model / Projection Rules

Conventions (documented only, no rewrite):
- **Domain Entity**: authoritative model owned by the domain (e.g. `EngineeringTopic`, `Project`, `ServiceBusinessProfile`, Tool definition).
- **Data DTO**: serialization shape at the persistence boundary (e.g. `ChecklistItemState`, catalog JSON records). Domain entities should not leak raw JSON DTOs to consumers.
- **Presentation / View Model**: what a screen renders (e.g. `InspectionItem`/`InspectionCategory` views today live in presentation — that is acceptable for presentation, but their **definition/seed** should ultimately be domain-owned).
- **Cross-domain Projection**: a deliberately bounded, read-only summary (e.g. `CurrentProjectSummary`, `RecentKnowledgeItem`, `QuickToolSummary`, `SponsoredPlacement`, search index entries) with stable identity — never the full private entity or raw DTO.

Avoid reusing raw JSON DTOs directly across domains; avoid making presentation models persistent contracts.

---

## 20. Local / Remote Data Ownership

Conceptual authority/sync (backend not designed; no Firebase schema chosen):
- **Knowledge**: packaged/generated offline catalog primary (current); remote sync later optional.
- **Tools**: logic local; saved sessions/results may persist locally.
- **Projects**: local-first now; possible remote sync later.
- **Directory**: likely remote-authoritative with cache/offline projection later.
- **User**: local preferences + future account/cloud data.
- **Ads**: remote campaign authority + cached placements.

**Offline cache is not ownership** (repeated strongly): Home caching a directory card ≠ Home owns Supplier; Search index has Topic title ≠ Search owns Topic; Projects stores supplier display snapshot ≠ Projects owns Supplier.

---

## 21. Offline Rules

- Civilpedia is offline-first where appropriate (M1 §14).
- Distinguish: offline knowledge (bundled catalog), offline calculators (pure/local), locally available project data (local now), saved/downloaded knowledge (Hive), cached directory data (future).
- Any cache/offline projection stores stable IDs and resolves through owner-domain authority when online.

---

## 22. Missing / Deleted Entity Handling

Conceptual graceful behavior (no silent ID reassignment / no silent Home fallback where a better state exists):
- Project references deleted supplier → show unavailable placeholder, keep reference; do not auto-reassign.
- Saved references removed Topic → resolve to domain not-found/empty; keep the record or tombstone it.
- Search index contains stale entity → strip or mark stale on resolution.
- Sponsored campaign references unavailable listing → deactivate the placement without inventing a replacement.
- Consistent with M3 §22 (error/not-found navigation).

---

## 23. Auth / Permission Boundaries

Do not design the full auth model now; classify ownership:
- User/Identity → **User/Auth boundary**.
- Project access permissions → **Projects policy** using the identity contract.
- Directory verification/admin → **Directory/Admin policy**.
- Sponsored campaign authorization → **Monetization/Admin**.
- Do not spread auth decisions into UI widgets; keep them at domain policy boundaries.

---

## 24. Feature Flag Boundaries

- Feature flags control **exposure**, not data ownership.
- Projects disabled → navigation hidden; Projects data architecture still belongs to Projects.
- Directory disabled → navigation hidden; Directory entity ownership unchanged.
- Current access/plan system (`FeatureKey`, `PlanTier`) already models these gates (e.g. `connectListing`, `supplierProfile`, `sponsoredListing`, `maxProjects`). These gates gate visibility, they do not create owners.

---

## 25. Admin Boundary

- Admin is a separate operational surface (M1 §15, M3 §23) — not part of the 5-tab engineer app.
- Admin may **invoke** domain management APIs but must **not become the owner** of Directory entities, Ads, Knowledge, etc. The business domain remains owner; Admin is management/presentation access only.

---

## 26. Current Technical Debt Mapping

Each item classified: **SAFE CURRENT** / **MIGRATE LATER** / **COMPATIBILITY** / **ARCHITECTURAL DEBT** / **BLOCKER BEFORE DOMAIN EXPANSION**. (None fixed in M4.)

| # | Current reality | Classification |
|---|---|---|
| 1 | Projects live under Tools (`lib/features/tools/domain/checklist/entities/project.dart`, data under `lib/features/tools/data/checklist/`) | **MIGRATE LATER** (promote to Projects domain when surfaced; ownership already defined in §7) |
| 2 | `LocalChecklistRepository` instantiated 3×, `LocalProjectRepository` 2× (UI constructs repo+datasource in checklist_screen.dart:38, project_list_screen.dart:25/108) | **ARCHITECTURAL DEBT** (UI builds data layer; duplicate caches) |
| 3 | `AppDependencies.checklistRepo`/`projectRepo` getters unread (singletons feed only `BackupService`) | **ARCHITECTURAL DEBT** (ambiguous DI ownership) |
| 4 | `ArticleRepository` legacy static global overlaps encyclopedia; still feeds Saved, Tools grid, Home latest-articles | **COMPATIBILITY** (Knowledge reconciliation deferred; not a blocker) |
| 5 | Raw `relatedToolRoutes` navigation strings embedded in content; navigated via `context.go(route)` | **ARCHITECTURAL DEBT** — but touching it needs content pipeline; **BLOCKER BEFORE** Knowledge→Tools typed-contract work. Any migration from Content Studio/Draft only. |
| 6 | Home reads `ArticleRepository().getLatestArticles()` + builds ad data from a datasource | **MIGRATE LATER** (Home should consume projections) |
| 7 | `LocalServiceBusinessRepository`/`ServiceBusinessDataSource`/`businessRepo` wired but unused | **ARCHITECTURAL DEBT** (Directory seed; SAFE to ignore until Directory launches, then wire properly) |
| 8 | Saved merges legacy + encyclopedia favorites + downloads in one Hive box | **SAFE CURRENT** (reference semantics consistent; target refactor later) |
| 9 | Mock ads (`LocalAdDataSource` always returns `_mockAds`; UI→datasource bypass in ad_carousel_widget.dart) | **ARCHITECTURAL DEBT + correctness gap** vs "no campaign → no slot/route" (M1 §11, M3 §16). Not a blocker; **BLOCKER BEFORE** real Monetization rollout. |
| 10 | Backup omits encyclopedia favorites; partial restore (`TODO(BACKUP-1C)`) | **ARCHITECTURAL DEBT** (data-integrity gap; not an ownership issue) |
| 11 | AuthProvider in-memory + password strings only; not linked to profile | **SAFE CURRENT** (bounded; User/Auth boundary defined in §23) |
| 12 | InspectionItem/InspectionCategory live in presentation with seed data | **MIGRATE LATER** (template/definition should be domain-owned; §6/§13/§19) |
| 13 | Per-project checklist key `checklist_project_<id>` is a runtime literal (SharedPreferences), not an AppConstants constant | **ARCHITECTURAL DEBT** (hardcoded storage key; recommend centralization when wiring persists) |

**BLOCKERS BEFORE DOMAIN EXPANSION** (the only ones that gate future work): #5 (Knowledge→Tools typed contract, needs Content Studio-led migration) and #9 (real Monetization requires a campaign-gated placement instead of always-on mock ads). Neither blocks M4 (doc-only) and neither is implemented here.

---

## 27. Stable ID Rules

- IDs are **not** based on translated Arabic/English display names.
- IDs stable across title/name edits.
- Route identity and data identity do not depend on localization.
- Source-domain IDs remain authoritative.
- Cross-domain references use IDs/keys, not display text.
- No database-specific ID assumption at domain boundary when avoidable (`Project.id` today is `project_<timestamp>_<rand>` — stable synthetic ID, consistent with this).
- Deep links use stable IDs (M3 §17).

---

## 28. Migration Principles

- Ownership changes are defined by **domain re-parenting**, not by file moves only; the physical location (Projects under Tools) is debt to re-parent later, while ownership per §7 is already correct.
- Cross-domain writes go through explicit contracts before any refactor (Tools→Projects via `ProjectWorkspaceGateway`).
- Content-driven contracts (e.g. `relatedToolRoutes` → typed ToolKey) must migrate **from Content Studio/Draft source**, never generated outputs.
- Backward compatibility preserved via M3 redirect/compat strategy; old storage keys keep behavior during migration.
- Feature flags gate exposure; a domain's data architecture can be built/owned before it is exposed.

---

## 29. Open Decisions

1. **Projects promotion mechanics** — exact `ProjectWorkspaceGateway` API and when Tools' save contracts are introduced (M1 open #3).
2. **Template/definition re-parent** — moving `InspectionItem`/`InspectionCategory` + seed to domain ownership, and whether global quick-checklist stays Tools-owned indefinitely.
3. **ArticleRepository reconciliation** — legacy articles merge into Knowledge/Content Studio or stay a bounded reader (M1 open #1/#2).
4. **Directory generic vs per-type model** — one `BusinessType`-tagged entity (preferred) vs divergent profiles for Material/Product (M3 open #5).
5. **Snapshot granularity** — exact fields for Project calculation/report snapshots (`toolVersion`, inputs, units, timestamp) and when a display snapshot is warranted vs a pure reference.
6. **Storage-key centralization** — moving `checklist_project_<id>`/`projects_list`/`sb_profiles` literals into a constants/contracts layer during wiring.
7. **Backup completeness** — adding encyclopedia favorites + full restore (data-integrity, not ownership).
8. **Auth linkage** — when/if `AuthProvider` binds to `UserProfile`/cloud identity (deferred).

---

## 30. Non-Negotiable Rules

1. One authoritative owner per entity; secondary owners are forbidden. 2. Offline cache never equals ownership. 3. Content Studio remains the sole authoring authority; generated files are outputs; never migrate from generated outputs. 4. No schema/exporter/content changes during architecture phases. 5. Tools→Projects writes only via explicit contracts (never direct repo import). 6. Directory owns business entities; Monetization owns sponsorship; sponsored-entity ≠ second entity. 7. Search is index/projection, never entity owner. 8. Home is aggregator, never data owner. 9. Saved references source IDs, never full copies. 10. No circular domain dependencies. 11. Cross-domain transitions use stable contracts, not private paths/DTOs. 12. Feature flags gate exposure, never ownership. 13. Admin is management access, never an owner. 14. Project history stays meaningful (snapshots) even when source changes. 15. Directory updates never silently rewrite project history. 16. Future backend can be introduced without redefining domain ownership.

---

## Required Ownership Table

| Entity / Data | Authoritative Domain | Source of Truth | May Be Referenced By | May Be Snapshotted By | Persistence Direction | Notes |
|---|---|---|---|---|---|---|
| Topic | Knowledge | Content Studio → generated catalog | User(Saved), Projects, Search, Home | Projects (display snapshot if offline/history needed) | Bundled asset (read) | Never duplicate full JSON by default |
| Article | Knowledge | legacy ArticleRepository (bounded) | Saved, Home, Search | — | Hive refs (favorites/downloads) | Consolidate later; not merged now |
| Tool definition | Tools | Tools domain / ToolModel registry | Knowledge(ref), Home, Search | — | Code/registry | Typed ToolKey contract later |
| Calculator definition/formula | Tools | Tools domain (pure) | Knowledge(ref) | — | Code | Stateless pure functions |
| Calculator result (before save) | Tools/session | Tools | Projects(save) | Projects (on Save) | Session/UI state | Not persisted today |
| Checklist template | Tools | Tools domain | Projects | Projects (executed set) | Code/refs | Template vs execution split |
| Checklist item definition | Tools | Tools domain | Projects | Projects | Code/seed | Re-parent from presentation later |
| Checklist execution (global) | Tools | Tools (quick) | — | — | SharedPreferences `checklist_data` | Non-project |
| Checklist execution (per project) | Projects | Projects | — | — | SharedPreferences `checklist_project_<id>` | Project-owned record |
| Inspection template | Tools | Tools domain | Projects | Projects | Code/seed | Reusable logic |
| Inspection record | Projects | Projects | — | — | per-project store | Project-owned |
| Project | Projects | Projects | Home, Search | — | SharedPreferences `projects_list` | Re-parent from Tools later |
| Project note | Projects | Projects | — | — | projects store | Future |
| Project attachment/doc metadata | Projects | Projects | — | — | projects store | Future |
| Supplier | Directory | Directory | Projects(ref), Search, Home | Projects (display snapshot) | Directory store | Not a second entity |
| Service | Directory | Directory | Projects(ref), Search, Home | — | Directory store | |
| Material/Product | Directory | Directory | Search, Projects | — | Directory store | May need own detail model |
| Saved Item | User | User Saved refs | — | — | Hive (favorites/downloads) | `entityType/id/ownerDomain` refs |
| User Profile | User | User | (auth) | — | SharedPreferences `local_user_profile` | |
| Ad Campaign | Monetization | Monetization | — | — | remote (future) | Campaign-gated placement |
| Sponsored Listing | Monetization | Monetization | Directory(presentation), Home | — | remote (future) | References Directory entity, not duplicate |
| Search Result / Index | Search | per-domain projections | — | — | index | Not entity owner |
| Home Dashboard Projection | Home | aggregates domain projections | — | — | cache/projection only | Never source of truth |

---

## Required Contract Table

| Producer Domain | Consumer Domain | Contract Concept | Data Exposed | Write Allowed? | Ownership Transfer? | Notes |
|---|---|---|---|---|---|---|
| Tools | Projects | SaveCalculationToProject | input+result snapshot, sourceToolId, unit, timestamp | Yes (Projects writes snapshot) | No — Projects owns snapshot, Tools keeps formula | Via ProjectWorkspaceGateway, not direct repo |
| Tools | Projects | SaveChecklistExecutionToProject / SaveInspectionToProject | executed item set + status/notes | Yes | No — Project owns record | Template stays Tools-owned |
| Knowledge | Tools | RelatedToolReference | stable ToolKey(s) | No | No | Legacy raw routes → compat resolver → typed ToolKey (from CS source) |
| Projects | Directory | ProjectSupplierReference | supplierId + optional display fields | No (ref only) | No | Directory authoritative |
| Domains | Search | Searchable projections | id, title, type, ownerDomain, summary | No | No | Search aggregates |
| Domains | Home | Dashboard projections | CurrentProjectSummary, RecentKnowledgeItem, QuickToolSummary, SponsoredPlacement | No | No | Home caches/projects, never owns |
| Saved/User | Domains | SavedItemResolve | entityType+entityId+ownerDomain | No | No | Resolves through owner domain |
| Monetization | Home | SponsoredPlacement | placement + campaign-gated visibility | No | No | No slot/route without active campaign |
| Monetization | Directory | SponsoredListingRef | sponsorship relationship referencing Directory entity | No | No | Not a second entity; Directory owns listing |

---

## Requirements Traceability (M4)

Protected/covered: Content Studio (§5, §30), engineering content (§5), Single Source of Truth (§2, §30), clean code (§2, §19), no duplicated ownership (§2, §30), Projects (§7), Tools (§6), Knowledge (§5), Directory/Services (§8), Ads/Sponsored (§10, §16), Saved (§9), Global Search (§11), Home aggregation (§12), offline-first (§20–21), future backend (§20), feature flags (§24), user/auth boundaries (§23), AI-agent clarity (single authoritative tables §Ownership + §Contracts, + debt classification §26).

---

## Protected / Forbidden (unchanged)

ZERO changes to: `lib/**`, `test/**`, `assets/**`, `draft_jsons/**`, `app_ready_jsons/**`, Content Studio, exporters, schemas, generated catalogs, `pubspec.yaml`, branding. This phase created exactly one file: `docs/architecture/CIVILPEDIA_DATA_OWNERSHIP_AND_DOMAIN_CONTRACTS.md`. M1/M2/M3 docs were **not** modified (no material contradiction found — see §26 for reconciliation notes, which are additive, not corrective).
