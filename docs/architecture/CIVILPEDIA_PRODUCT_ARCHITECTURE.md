# CIVILPEDIA — MASTER PRODUCT ARCHITECTURE

**Phase:** M1 (Master Product Architecture) + M2 (Complete Screen Map — see `CIVILPEDIA_SCREEN_MAP.md`)
**Status:** ARCHITECTURE / DOCUMENTATION ONLY — no production code was changed.
**Scope:** Long-term product architecture for Civilpedia as a complete daily engineering platform.

> This document is the long-term target architecture. It coexists with the current application. The current app remains exactly as built today; this document defines where it is heading and how the current code maps into that target. See §19 *Current vs Target* and `CIVILPEDIA_SCREEN_MAP.md` for the per-screen mapping.

---

## 1. Product Vision

Civilpedia evolves from an **Engineering Encyclopedia + Tools** application into a **complete daily engineering platform** for civil engineers (Arabic-first, RTL-first).

Today the app is an excellent knowledge + calculators core. The long-term vision keeps that core authoritative and adds surrounding engineering-workflow capabilities on top **without** degrading or coupling the core domains.

Target product identity:

> One coherent engineering platform — knowledge, tools, projects, and engineering commerce — not a collection of unrelated screens.

The platform serves the full engineering problem-solving loop (see §2), from a question on site to a saved, documented, shareable engineering deliverable.

---

## 2. Core User Workflow

The workflow the whole architecture is optimizing for:

```
Engineering Problem
   → Global Search
   → Knowledge (topic / article / standard)
   → Engineering Tool (calculator / checklist / inspection)
   → Calculation / Checklist / Inspection result
   → Save to Project
   → Notes / Photos / Documents (project workspace)
   → Supplier / Service / Technician (when needed)
```

Architectural consequence: the workflow crosses domains, so the architecture must make it **natural without tightly coupling domains**. No single domain owns the whole workflow. Each step is owned by its domain; a thin workflow/aggregation layer (Home, Global Search, cross-domain services) orchestrates movement between them through clear contracts.

The workflow is **not** forced. A user may enter at any point (search directly, open tools, browse knowledge) and exit at any point.

---

## 3. Product Domains

The target top-level domains:

### 1. HOME — الرئيسية
Personal engineering dashboard and entry point.
- Header / user avatar
- Global Search entry
- Hero / Sponsored Banner (conditional)
- Quick Access
- Current Project Snapshot (conditional)
- Site Tools
- Engineering Content Discovery
- Recent Activity
- Saved / Continue
- Optional sponsored engineering offer (conditional)

**Boundary rule:** Home **aggregates**; it must NOT own business logic belonging to other domains. It reads through interfaces/providers owned by each domain. Home must remain fully useful with zero advertisements.

### 2. KNOWLEDGE — المعرفة
- Encyclopedia, Articles, Codes & Standards, References, Execution Methods, Inspection & Acceptance, QA/QC, Safety, Materials, Equipment, Academic / Structural references, Saved knowledge, Offline knowledge.

**CRITICAL BOUNDARY:** The Knowledge domain **wraps and exposes** the existing, authoritative Content Studio pipeline. It does **not** replace or rebuild it. See §7.

### 3. TOOLS — الأدوات
- Calculators, Checklists, Converters, Site Quick Checks, QA/QC utilities, Inspection utilities, Report/Form utilities, and (later) project-linked engineering tools.

Real tools today (already implemented — do not invent more): concrete calculator, steel calculator, masonry/brick calculator, tile calculator, inspection checklist. Future tools may exist in the screen map only if explicitly marked **FUTURE / NOT IMPLEMENTED**.

### 4. MY PROJECTS — مشاريعي
Future major domain. Projects List → Project Workspace (Overview, Project info, Calculations, Checklists, Inspections, Notes, Photos, Documents/Attachments, Saved knowledge, Materials, Suppliers, Services, Reports, Recent activity).

**Critical relationship:** Engineering tool results should eventually be saveable into a selected project (e.g. Concrete Calculator → Calculate → Save to Project → Project X / Calculations; Checklist → Complete → Save to Project / Inspection record). **This behavior is NOT implemented now — it is architected only.** Current scaffold: partial project implementation exists today under the Tools feature (see Findings §19), to be promoted/re-positioned into this domain.

### 5. ENGINEERING DIRECTORY — الدليل الهندسي
First-class product domain for companies, contractors, consultants, engineering offices, suppliers, shops, technicians, services, materials/products, equipment providers. Services is especially important.

Provider profile fields (future): name, company, service/category, location, service areas, description, images, contact methods, working hours, services/products, verification state, sponsorship state.

**Boundary rule:** the Directory is a distinct domain from engineering Knowledge and from Monetization. Organic listings and Sponsored listings remain conceptually distinct (see §11).

---

## 4. Cross-Domain Systems

Capabilities that cut across all domains:

### Global Search
Future scope: Knowledge topic, Article, Tool, Project, Company, Supplier, Technician, Service, Material/Product.

**Principle:** Each domain owns its search implementation/data. A thin Global Search layer **aggregates** domain search results. Avoid one giant search service that knows internal storage of every feature.

```
GlobalSearch
├── KnowledgeSearch  (owned by Knowledge)
├── ToolSearch       (owned by Tools)
├── ProjectSearch    (owned by Projects)
└── DirectorySearch  (owned by Directory)
```

### Saved / Favorites
Saved state may include future entities (Knowledge topic, Article, Tool/result, Directory item). But **each domain remains owner of its entity/data**; a Saved layer stores only references/IDs to source-owner entities. Do NOT create a giant Saved domain that owns copies of every entity.

### Offline
Civilpedia remains offline-first where appropriate. Distinguish:
- offline knowledge (core today — generated catalog is bundled asset)
- offline calculators/tools (they are local by nature today)
- locally available project data (today: local Hive project storage)
- saved/downloaded knowledge (today: favorites + downloads in Hive)
- cached directory data (future, where appropriate)

Backend implementation is **not** designed in this document.

### Theme / Localization
- Arabic-first, RTL-first.
- Future English support remains structurally valid (the app already ships `ar.dart` + `en.dart`; the UI currently forces `ar`).
- Light Mode is the current visual target; new presentation remains theme-aware; final Dark Mode visual polish remains deferred (D9).
- **Do NOT remove English schema/data fields merely because the current UI is Arabic.**

---

## 5. Target Bottom Navigation

Long-term target (5 destinations):

| # | العربية | English (conceptual) |
|---|---------|----------------------|
| 1 | الرئيسية | Home |
| 2 | المعرفة | Knowledge |
| 3 | الأدوات | Tools |
| 4 | مشاريعي | My Projects |
| 5 | الدليل | Directory |

**IMPORTANT:** This is the **target** only. The current AppShell and current Bottom Navigation are **NOT modified** during this phase. The current navigation is 5 tabs — Home, Encyclopedia, Tools, Saved, Profile — see §19 and the Screen Map. The target renames/relocates: Encyclopedia→Knowledge wrapper, Saved→(user area / Knowledge), Profile→user area accessed from avatar, and adds My Projects + Directory as new destinations.

---

## 6. User / Profile Position

Profile should **not** necessarily consume a permanent future Bottom Navigation slot. Long-term access is through the **user avatar/header** (a Home header element or global header).

User area may contain: Profile, Saved, Downloads, Recent Activity, My Projects shortcut, Preferences, Theme, Language, Backup, Settings, Account/Auth state.

**Saved is a USER STATE, not necessarily a top-level domain.**

**Current-state note:** Profile is currently the 5th bottom-nav tab (`/profile`, label `Ar.account`). This is a **CURRENT — MIGRATE / REPOSITION** candidate (Profile moves from bottom-nav to avatar-accessed user area). Do NOT change it now — document current vs target separately.

---

## 7. Knowledge / Content Studio Boundary

The **non-negotiable** authoritative pipeline:

```
Content Studio
→ Draft JSON (draft_jsons/)
→ Export (app_ready_jsons/topics/)  [validated]
→ Generated Catalog (catalog.generated.json)
→ Flutter Data Source (encyclopedia_json_datasource)
→ Repository (encyclopedia_repository_impl)
→ Provider (EncyclopediaProvider)
→ Presentation
```

Rules (current and unchanged):
- Draft JSON / Content Studio is the **editing source**.
- Generated files (catalog.generated.json, topic app-ready JSONs) are **outputs**.
- Never edit generated catalogs as a content source.
- Never migrate content from generated outputs.
- Export does not rewrite editorial meaning.
- Existing Draft JSONs remain backward-compatible.
- Preview ↔ Flutter parity remains required.
- Legacy content compatibility remains protected (`docs/architecture/ENCYCLOPEDIA_LEGACY_COMPATIBILITY.md`).
- No content-field deletion during architecture work.
- No schema/exporter changes during M1/M2.

**The Knowledge domain wraps and exposes this pipeline.** It adds only presentation/interaction organization (bundles, standards grouping, saved/offline knowledge) on top of the authoritative engine — it never re-derives content.

Verified current pipeline facts (from repo inspection):
- `app_ready_jsons/topics/` = 13 topic files; `draft_jsons/` = 15 entries.
- `app_ready_jsons/catalog.generated.json` SHA-256 **matches** `assets/encyclopedia/catalog.generated.json` (hash `A676D9…7F026`). Legacy `assets/encyclopedia/catalog.json` is a separate, non-overwritten asset.
- Catalog `_meta`: format `civilpedia-catalog-generated`, schemaVersion 1, topicCount 13, sectionCount 117, blockCount 539. Categories: `concrete, engineering-basics, finishing, finishing-works, structural-works, waterproofing-finishing`.
- Generated catalog is the **preferred** data source (`_usingGenerated` flag in the datasource), with a tolerant parser + fallback to a local mock datasource.

---

## 8. Tools Domain Boundary

- Tools own calculators, checklists, converters, and inspection/report utilities.
- Calculator domain logic lives in `lib/features/tools/domain/calculators/*` (pure functions — concrete, steel, masonry, tile) and is **testable / UI-independent**.
- Tools **do not directly manipulate Project persistence**. When a "Save to Project" action exists (future), Tools produce a **result** that a cross-domain contract hands to Projects, which stores a reference/snapshot. Tools are not the owner of project data.
- The checklist is project-aware today (can be global or project-scoped) — this is the earliest seed of the Projects relationship and must be understood when promoting the Projects domain.

---

## 9. Projects Domain Boundary

- **Owner of project data**: Projects domain owns Project model, workspace, and persistence references.
- A calculation result is owned by **Tools initially**; when explicitly saved to a project, **Projects stores a reference/snapshot** of it.
- ProjectWorkspace sub-areas (long-term): Overview, Project information, Calculations, Checklists, Inspections, Notes, Photos, Documents/Attachments, Materials, Suppliers, Services, Reports, Recent activity.
- **Do not over-fragment** into unnecessary screens where tabs/sections are more appropriate.
- The Projects domain is distinct from Tools even though today the partial project code lives under `lib/features/tools/domain/project/`. This is a **CURRENT — MIGRATE / REPOSITION** finding.

---

## 10. Directory & Services Domain

A first-class domain for engineering commerce/connection.

Target categories:
- Companies, Contractors, Consultants, Engineering Offices, Suppliers, Shops, Technicians, Services, Materials/Products, Equipment providers.

Example service categories (especially important):
- Laboratory services, Soil testing, Concrete testing, Surveying, Waterproofing, Electrical works, Mechanical works, Finishing, Equipment/machinery, Transportation/supply, Engineering services, Other construction services.

Provider profile (future): name, company, service/category, location, service areas, description, images, contact methods, working hours, services/products, verification state, sponsorship state.

**Prefer a generic reusable directory entity/profile architecture** over dozens of separate screens (one Directory entity type with a `BusinessType` discriminator + rich profile, rather than separate Company/Supplier/Technician screen trees).

**Existing scaffolding (verified):**
- `FeatureKey.connectListing, sponsoredListing, supplierProfile, companyProfile, dashboardAccess` exist in `lib/core/access/*` (plan-gated: e.g. `ProEngineer` allows `connectListing`; higher tiers allow `sponsoredListing`, `supplierProfile`, `companyProfile`, `dashboardAccess`).
- `BusinessType` (supplier, technician, equipmentOwner, engineeringOffice, constructionCompany, buildingOffice, testingLab, surveyor, contractor, materialShop, consultantOffice, other) and `VerificationStatus` (unverified, pending, verified, rejected) exist in `lib/features/profile/domain/service_business_profile.dart`.
- `BaghdadArea` (24 districts) exists in `lib/core/location/baghdad_area.dart`.
- Localization already has `promotedServices` and `featuredCompanies` strings.

The Directory domain must be **organic** by default; sponsorship rides on top (see §11). Do not implement backend now.

---

## 11. Advertising / Monetization Architecture

Monetization is architected from the start as a **cross-domain layer** — never bolted on as random UI.

```
MONETIZATION
├── Home Ads
├── Hero / Sponsored Banners
├── Sponsored Directory Listings
├── Sponsored Services
├── Sponsored Suppliers
├── Sponsored Materials / Products
├── Campaign Management
├── Impression Analytics
├── Click Analytics
└── Feature Flags / Remote Control
```

**Hard rules:**
1. Ads are **NOT** engineering content.
2. Advertising must **never modify or contaminate** Content Studio knowledge.
3. Sponsored content is **clearly identified**.
4. **Organic** directory results and **Sponsored** listings remain **conceptually distinct**.
5. **No fake advertisement placeholders** when no active ad exists.
6. Ad slots must be able to **disappear completely** when no campaign exists.
7. Home must remain useful with **zero** advertisements.
8. Engineering credibility is more important than ad density.

**Model separately** (do not merge): `Organic Listing`, `Sponsored Listing`, `Advertisement Campaign`.

**Current-state observation (flag):** The current Home ad system (`lib/features/home/data/datasources/ad_data_source.dart` → `LocalAdDataSource`, `AdBanner`, `ad_carousel_widget.dart`) **always returns 4 mock/hardcoded ads**. This satisfies an early "ads exist" UI proof but conflicts with rules 5–6 (slots should disappear when no campaign exists; no fake placeholders). Directories `lib/features/ads/*` and `lib/features/admin/*` exist but are **empty scaffolds** (no files). This is a documented **deferred** normalization, not a change to make now.

---

## 12. Search Architecture

- Each domain owns its search implementation/data (see §4 GlobalSearch).
- A Global Search **aggregation layer** collects ranked results from each domain and renders a unified result list with **domain filters**.
- Proper empty/no-result states are required per domain and globally.
- Today only Knowledge has real search (EncyclopediaProvider topic filtering + `?q=` query on the encyclopedia route). Tool search, Directory search, and Project search are future.

---

## 13. Saved / Favorites Ownership

- Saved is a **user preference/state** that stores **references/source-domain IDs**, not copies.
- Each entity's data remains owned by its source domain (Knowledge topic, Article, Tool result, Directory item).
- Today favorites/downloads are Hive-backed references (`EncyclopediaFavoritesProvider`, `HiveHelper`) — consistent with this model.
- A future Saved layer aggregates those references across domains for the user area, but does not become a giant duplicate store.

---

## 14. Offline Strategy

Civilpedia remains **offline-first where appropriate**:
- Offline knowledge — core today (bundled generated catalog asset).
- Offline calculators/tools — calculators are local/pure by design today.
- Locally available project data — local Hive project/checklist storage today.
- Saved/downloaded knowledge — favorites/downloads today.
- Cached directory data — future, where appropriate.

Backend design is deferred; the app must remain fully usable offline now.

---

## 15. Admin Surface

Civilpedia may require a separate **Admin** surface (future) for:
- directory moderation
- supplier/service verification
- sponsored listing management
- ad campaign management
- content moderation (where applicable)
- analytics
- feature flags

**Do NOT mix Admin UI into the main engineer application.** This is a future **Admin Panel / separate application or web surface**.

**Current-state:** `lib/features/admin/*` is an empty directory scaffold. The plan-gated flags that touch admin concepts (`dashboardAccess`, `sponsoredListing`) exist in the access system but there is no admin UI.

---

## 16. Data Ownership Principles

| Entity | Owning Domain | Notes |
|--------|---------------|-------|
| Topic / Article | Knowledge | via Content Studio pipeline |
| Calculation result | Tools (initially) | Projects stores a reference/snapshot when explicitly saved |
| Project | Projects | |
| Checklist / Inspection record | Tools (initially) → Projects reference when saved | |
| Supplier | Directory | |
| Service | Directory | |
| Saved state | User preference referencing source-domain IDs | |
| Advertisement / Campaign / Sponsored | Monetization | |
| LocalUserProfile / auth | User (profile domain) | of the user |

**Do not duplicate ownership.** Cross-domain operations use explicit contracts/services; no circular dependencies; avoid giant God providers/repositories.

---

## 17. Feature Visibility Rules

The architecture may contain future My Projects, Directory, Services, Suppliers, Monetization features — but production navigation must **not expose unfinished/fake features**.

**Rule: NOT READY → HIDDEN.**

Do **NOT** recommend: Coming Soon cards, disabled fake buttons, empty future tabs — unless there is a specific product reason.

**Current-state note:** Home Quick Access is a 4-card grid (Encyclopedia/Tools/Articles/Saved) — no fake Directory entry. This complies. Keep future domains hidden until genuinely implemented.

---

## 18. Non-Negotiable Engineering Rules

Architecture must preserve the current engineering principles:
- Single Source of Truth
- no duplicated logic
- no special cases
- no hardcoded feature data in presentation
- shared primitives only when semantics are genuinely shared; feature-specific UI stays feature-specific
- root-cause fixes over patches
- backwards compatibility
- clean naming
- small responsibility-focused files
- testable boundaries
- no unnecessary abstraction layers

> Clean architecture does NOT mean maximum abstraction.

**Target conceptual layering:**
```
Presentation
↓
Feature/Domain API or State Layer
↓
Repository
↓
Data Source
↓
Local / Remote persistence
```

Boundaries: Home aggregates (not a mega-repository); Tools do not directly manipulate Project persistence; Knowledge does not know Directory implementation; Directory does not edit engineering content; Monetization cannot rewrite engineering knowledge; cross-domain ops use explicit contracts; no circular dependencies; avoid giant God providers/repositories.

---

## 19. Current vs Target Architecture

> All facts below verified by repository inspection (M1). No production code changed.

### Current Bottom Navigation (5 destinations — `lib/core/navigation/app_shell.dart`)
1. `/home` — HomeMainScreen (`Ar.home`)
2. `/encyclopedia` — EncyclopediaScreen (reads `?q=`) (`menu_book`)
3. `/tools` — ToolsScreen (`build`)
4. `/saved` — SavedScreen (`bookmark`)
5. `/profile` — ProfileScreen (`person`, label `Ar.account`)

Routing: `StatefulShellRoute.indexedStack` with 5 branches; root-level routes for `/splash`, `/onboarding`, `/profile-setup`, `/auth`, `/categories`, `/encyclopedia/topics/:categoryId`, `/encyclopedia/topic/:topicId`; leaf routes `/calculator/*`, `/article/{id}`.

### Target Bottom Navigation (5 destinations)
1. Home, 2. Knowledge, 3. Tools, 4. My Projects, 5. Directory (+ Profile → user area via avatar; Saved → user state).

### Mapping summary (detailed per screen in the Screen Map)
| Current concept | Target |
|---|---|
| Home | Home (aggregator) — strengthened |
| Encyclopedia | Knowledge wrapper (keeps Content Studio engine) |
| Articles | Knowledge (legacy article system — see consolidation note below) |
| Tools | Tools |
| Checklist | Tools (project-aware); results → Projects reference |
| Projects (partial, under Tools) | Promote to **My Projects** domain |
| Saved (bottom-nav) | User state (Saved within user area / Knowledge) |
| Profile (bottom-nav) | User area (avatar-accessed) |
| (none) | Directory (new) |
| Home ad carousel (mock) | Monetization layer (normalized; disappears w/o campaign) |

**Consolidation note (future only):** A legacy `ArticleRepository` (static lists: categories, tools, articles) coexists with the authoritative generated Content Studio catalog. Encyclopedic articles overlap with encyclopedia topics. This is a **CURRENT — CONSOLIDATE LATER** candidate (Articles → Knowledge), not an action now.

**Flags found during inspection (documented, not acted on):**
1. `encyclopedia_screen.dart` hardcodes `_categoryOrder = ['concrete','steel','soil','roads','finishing']`, but the generated catalog categories are `concrete, engineering-basics, finishing, finishing-works, structural-works, waterproofing-finishing`. Screen is tolerant of missing categories, but order/fallback differ.
2. Profile screen `tr(String ar, String en) => ar;` — Arabic-only hardcode even though `en.dart` exists.
3. Tool routes stored without leading `/` and prefixed at push-time; a future leading-`/` value would double the slash.
4. Home ad system always returns mock ads (see §11) — deferred normalization.

---

## 20. Open Decisions / Deferred Decisions

Only real, unresolved issues:

1. **Articles consolidation scope** — whether the legacy `ArticleRepository` articles merge into the Knowledge domain / generated catalog, or remain a bounded legacy reader. Deferred (CURRENT — CONSOLIDATE LATER).
2. **Articles ↔ Encyclopedia topic merge** — whether legacy encyclopedic articles become generated-catalog topics (requires content pipeline changes; currently blocked by "no schema/exporter changes during M1/M2").
3. **Projects promotion mechanics** — exact contract by which Tools save results into Projects (result snapshot schema, cross-domain service boundary). Not implemented.
4. **Directory entity unification** — one generic `DirectoryEntry` profile vs. per-type models; `BusinessType` discriminator already exists and points toward one generic architecture (recommended).
5. **Sponsored/organic data model** — final shape of `Organic Listing` / `Sponsored Listing` / `Advertisement Campaign` and their storage; backend deferred.
6. **Global Search ranking** — how domain results are ranked together in one result list; backend/alg deferred.
7. **Nav evolution timing** — when Profile/Saved move off the bottom nav and My Projects + Directory take their slots; must follow the NOT READY → HIDDEN rule.
8. **Category-order reconciliation** — the `encyclopedia_screen` hardcoded order vs generated catalog categories (flag 1). Requires a deliberate decision before a content-only fix.

---

## Requirements Traceability (internal coverage check)

Covered in this architecture:
- Complete app structure — §3, §5, Screen Map.
- Engineering knowledge protection — §7, §18.
- Content Studio preservation — §7.
- Clean code/domain boundaries — §18.
- Home advertisements — §11, §19.
- Sponsored content — §11.
- Engineering services — §10.
- Suppliers/contractors/technicians — §10.
- My Projects — §9.
- Global Search — §4, §12.
- Tools — §8.
- Saved/user state — §4, §6, §13.
- Offline — §4, §14.
- Arabic/RTL — §4.
- Future English — §4.
- Theme awareness — §4.
- Admin separation — §15.
- Feature flags — §11, §15 (plan-gated flags).
- No fake unfinished features — §17.
