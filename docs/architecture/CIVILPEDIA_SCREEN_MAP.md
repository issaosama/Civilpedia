# CIVILPEDIA — COMPLETE SCREEN MAP

**Phase:** M2 (Complete Screen Map). Companion to `CIVILPEDIA_PRODUCT_ARCHITECTURE.md`.
**Status:** ARCHITECTURE / DOCUMENTATION ONLY — no production code was changed, no routes changed.
**Scope:** Every current and proposed screen/major surface mapped into the target architecture.

---

## Classification Legend

| Class | Meaning |
|-------|---------|
| **CURRENT — KEEP** | Existing screen whose conceptual responsibility remains valid. |
| **CURRENT — MIGRATE / REPOSITION** | Existing screen remains useful but belongs elsewhere in the target structure. |
| **CURRENT — CONSOLIDATE LATER** | Existing screens whose responsibilities overlap and may eventually be unified (not implemented now). |
| **FUTURE — NEW** | Required for the complete platform but not implemented. |
| **INTERNAL / DETAIL** | Not a Bottom Navigation destination (e.g. Topic Detail, Calculator Detail, Project Detail). |
| **CONDITIONAL** | Visible only when real data/feature/campaign exists. |
| **DEFERRED / OPTIONAL** | Potential future idea, not required for core platform. |

Every row carries: **Domain · Screen · Current/Future · Current route · Target parent · Classification · Primary responsibility · Data owner · Dependencies · Visibility rule · Notes/migration**.

---

## A. Current Screen Inventory

Verified from repository inspection (`lib/routes/app_router.dart`, `lib/core/navigation/app_shell.dart`, `lib/features/**/presentation/screens/**`).

| # | Domain (current) | Screen | Route | Notes |
|---|--------|--------|-------|-------|
| A1 | Home | Home Main Dashboard | `/home` (shell) | Slivers: HomeHeader, SearchBar, AdCarousel, QuickAccess, QuickTools, Categories, EngineeringTopics, LatestArticles. |
| A2 | Encyclopedia | Encyclopedia Landing | `/encyclopedia` (shell, reads `?q=`) | Category list; hardcoded `_categoryOrder`. |
| A3 | Encyclopedia | Categories (full catalog) | `/categories` (root) | Phase B catalog-driven. |
| A4 | Encyclopedia | Topic List | `/encyclopedia/topics/:categoryId` | |
| A5 | Encyclopedia | Topic Detail | `/encyclopedia/topic/:topicId` | |
| A6 | Articles | All Articles | (via Home/Articles) | Legacy. |
| A7 | Articles | Article List | (via Home/Saved) | Legacy. |
| A8 | Articles | Article Detail | `/article/{id}` | Favorites/downloads via HiveHelper. |
| A9 | Tools | Tools Landing | `/tools` (shell) | Intro card + grid of `ArticleRepository.tools`. |
| A10 | Tools | Concrete Calculator | `/calculator/concrete` | |
| A11 | Tools | Steel Calculator | `/calculator/steel` | |
| A12 | Tools | Masonry/Brick Calculator | `/calculator/masonry` | |
| A13 | Tools | Tile Calculator | `/calculator/tile` | |
| A14 | Tools | Checklist Root | `/calculator/checklist` | Category list; project-aware. |
| A15 | Tools | Checklist Category Detail | (leaf under checklist) | Items + notes/status. |
| A16 | Tools | Project List (checklist projects) | (leaf) | Lists projects for scoping checklists. |
| A17 | Saved | Saved Screen | `/saved` (shell) | Favorites + downloads (Hive). |
| A18 | Profile | Profile Screen | `/profile` (shell, label `Ar.account`) | Avatar-accessed migration candidate. |
| A19 | Profile | Profile Setup | `/profile-setup` (root) | Stepper, CivilUserType, BaghdadArea. |
| A20 | Profile | Profile Edit | (leaf) | |
| A21 | Auth | Auth Screen | `/auth` (root) | Login/register tabs. |
| A22 | Splash | Splash Screen | `/splash` (root) | Navigates onboarding vs profile-setup. |
| A23 | Onboarding | Onboarding | `/onboarding` (root) | |
| A24 | Routing | Not Found | (error) | |

---

## B. Target Screen Tree

The target bottom navigation: **Home · Knowledge · Tools · My Projects · Directory** (Profile → user area; Saved → user state). Any target screen boxed `(future)` is NOT implemented and must remain HIDDEN per §17 of the Product Architecture.

```
HOME (الرئيسية)
├── Home Dashboard (aggregator)
│   ├── Header / user avatar (→ User area)
│   ├── Global Search entry (→ Global Search)
│   ├── Hero / Sponsored Banner            [CONDITIONAL — ad campaign]
│   ├── Quick Access
│   ├── Current Project Snapshot           [CONDITIONAL — user has projects]
│   ├── Site Tools (→ Tools)
│   ├── Engineering Content Discovery (→ Knowledge)
│   ├── Latest / Saved / Recent
│   └── Optional Sponsored Engineering Offer [CONDITIONAL — campaign]

KNOWLEDGE (المعرفة)  [wraps Content Studio; see boundary §7]
├── Knowledge Landing
├── Encyclopedia categories (existing)
├── Topic list (existing)
├── Topic detail (existing)                [INTERNAL/DETAIL]
├── Articles (legacy)                      [CONSOLIDATE LATER]
├── Article detail (legacy)                [INTERNAL/DETAIL]
├── Codes & Standards grouping             [FUTURE — NEW]
├── Saved knowledge                        [user state]
└── Downloads / offline knowledge          [user state]

TOOLS (الأدوات)
├── Tools Landing (existing)
├── Calculator categories (if needed)
├── Concrete calculator (existing)         [INTERNAL/DETAIL]
├── Steel calculator (existing)            [INTERNAL/DETAIL]
├── Masonry calculator (existing)          [INTERNAL/DETAIL]
├── Tile calculator (existing)             [INTERNAL/DETAIL]
├── Converters                             [FUTURE — NEW (verified real gap, no fake tool)]
├── Site Quick Checks                      [FUTURE — NEW]
├── Checklist root (existing)
├── Checklist category detail (existing)   [INTERNAL/DETAIL]
└── Inspection record → saved to Project   [FUTURE — NEW flow]

MY PROJECTS (مشاريعي)  (future, NOT exposed yet)
├── Project List                           [FUTURE — NEW]
├── Create / Edit Project                  [FUTURE — NEW]
├── Project Dashboard / Overview           [FUTURE — NEW]
├── Project Calculations                   [FUTURE — NEW]
├── Project Inspections                    [FUTURE — NEW]
├── Project Checklists                     [FUTURE — NEW]
├── Project Notes                          [FUTURE — NEW]
├── Project Attachments / Documents        [FUTURE — NEW]
├── Project Materials                      [FUTURE — NEW]
├── Project Suppliers / Services           [FUTURE — NEW]
└── Project Reports                        [FUTURE — NEW]
  (Current partial project code under Tools is the seed; prefer tabs/sections over over-fragmentation.)

DIRECTORY (الدليل الهندسي)  (future, NOT exposed yet)
├── Directory Landing                      [FUTURE — NEW]
├── Search / filter                        [FUTURE — NEW]
├── Category listing                       [FUTURE — NEW]
└── Generic Directory entity/profile       [FUTURE — NEW]  ← preferred over per-type screens
   (Companies, Contractors, Consultants, Offices, Suppliers, Shops, Technicians,
    Services, Materials/Products — one generic profile, `BusinessType` discriminator)
    ├── Supplier profile                   [FUTURE — NEW]
    ├── Service listing / detail           [FUTURE — NEW]
    └── Organic vs Sponsored listing       [FUTURE — NEW; distinct models]

USER AREA (avatar-accessed, not a bottom-nav slot; Profile/Saved migrate here)
├── Profile / Edit Profile                 (migrate from bottom nav)
├── Saved                                  (user state)
├── Downloads
├── Recent Activity
├── My Projects shortcut
├── Preferences
├── Language
├── Theme
├── Backup
└── Account / Auth

GLOBAL SEARCH
├── Global Search (aggregator)             [FUTURE — NEW]
├── Search Results with domain filters     [FUTURE — NEW]
└── Empty / no-result states               [FUTURE — NEW]

MONETIZATION / ADMIN (separate surface, NOT in user navigation)
├── Home ad slots                          (CONDITIONAL — campaign)
├── Sponsored listings                     [FUTURE]
└── Admin Panel (separate app/web)         [FUTURE — separate surface]
```

---

## C. Current → Target Mapping

| Current (A#) | Target parent | Classification | Primary responsibility | Data owner | Dependencies | Visibility | Notes / migration |
|---|---|---|---|---|---|---|---|
| Home Dashboard (A1) | Home | **CURRENT — KEEP** | Personal dashboard aggregator | Home (aggregates via domain providers) | Providers for each aggregator; Connectivity | Always | Add conditional ad/project-snapshot slots later; Home must not own domain logic. |
| Encyclopedia Landing (A2) | Knowledge | **CURRENT — MIGRATE / REPOSITION** | Knowledge entry | Knowledge (Content Studio) | EncyclopediaProvider | Always | Becomes Knowledge Landing; resolve `_categoryOrder` vs generated categories (flag 1). |
| Categories (A3) | Knowledge | **CURRENT — KEEP** | Full category tree | Knowledge | EncyclopediaProvider | Always | Catalog-driven (Phase B). |
| Topic List (A4) | Knowledge | **CURRENT — KEEP** | Topics of a category | Knowledge | EncyclopediaProvider | Always | |
| Topic Detail (A5) | Knowledge | **INTERNAL / DETAIL** | Render topic sections/blocks | Knowledge | content pipeline; topic theme | Always | |
| All/Article List (A6/A7) | Knowledge | **CURRENT — CONSOLIDATE LATER** | Legacy article browse | Articles (legacy) | ArticleRepository | Always today | Overlaps encyclopedia → consolidate into Knowledge later. |
| Article Detail (A8) | Knowledge | **INTERNAL / DETAIL** | Render legacy article | Articles | HiveHelper faves/downloads | Always | Keep legacy reader; parity to Content Studio. |
| Tools Landing (A9) | Tools | **CURRENT — KEEP** | Tools entry | Tools | ArticleRepository.tools | Always | Source should move off ArticleRepository → Tools catalog later (consolidation). |
| Concrete (A10) | Tools | **INTERNAL / DETAIL** | Concrete volume calc | Tools | calculator domain | Always | Pure domain logic; Save-to-Project gate later. |
| Steel (A11) | Tools | **INTERNAL / DETAIL** | Steel weight calc | Tools | calculator domain | Always | |
| Masonry (A12) | Tools | **INTERNAL / DETAIL** | Masonry/brick calc | Tools | calculator domain | Always | |
| Tile (A13) | Tools | **INTERNAL / DETAIL** | Tile quantity calc | Tools | calculator domain | Always | |
| Checklist Root (A14) | Tools | **INTERNAL / DETAIL** | Checklist categories | Tools | checklist repo (global) | Always | Results → Projects reference later. |
| Checklist Category Detail (A15) | Tools | **INTERNAL / DETAIL** | Items + notes/status | Tools | checklist repo | Always | |
| Project List (A16) | My Projects | **CURRENT — MIGRATE / REPOSITION** | Project list for checklist scoping | Projects | LocalProjectRepository | Always today (hidden in target until Projects exposed) | Seed of My Projects domain. |
| Saved (A17) | User area | **CURRENT — MIGRATE / REPOSITION** | Saved/downloads references | User state (refs to source domains) | HiveHelper | Re-enter via user area | Move off bottom nav → user area. |
| Profile (A18) | User area | **CURRENT — MIGRATE / REPOSITION** | User profile display | User | UserProfileProvider | Avatar-accessed | Arabic-only `tr` hardcode (flag 2). |
| Profile Setup (A19) | User area | **CURRENT — KEEP** | Onboarding profile capture | User | LocalUserProfile | On first launch | |
| Profile Edit (A20) | User area | **INTERNAL / DETAIL** | Edit profile | User | UserProfileProvider | Always | |
| Auth (A21) | User area | **CURRENT — KEEP** | Login/register | User | AuthProvider | When needed | |
| Splash (A22) | (system) | **CURRENT — KEEP** | Bootstrap/navigate | — | Providers | Always | |
| Onboarding (A23) | (system) | **CURRENT — KEEP** | First-run intro | — | PreferencesHelper | First run | |
| Not Found (A24) | (system) | **CURRENT — KEEP** | Error route | — | — | On bad route | |

---

## D. New Future Screens

All **FUTURE — NEW** (NOT implemented; must remain hidden until ready per NOT READY → HIDDEN).

| Domain | Screen | Target parent | Primary responsibility | Data owner | Visibility |
|---|---|---|---|---|---|
| Knowledge | Codes & Standards grouping | Knowledge | group code references/standards | Knowledge | Hidden until content supports it |
| Tools | Converters | Tools | unit/quantity converters (real, verified gap) | Tools | Hidden until implemented |
| Tools | Site Quick Checks | Tools | quick on-site QA/QC checks | Tools | Hidden |
| Tools | Inspection-record → Project save flow | Tools→Projects | persist inspection to a project | Tools→Projects contract | Hidden |
| Projects | Project List | My Projects | list/open projects | Projects | Hidden |
| Projects | Create / Edit Project | My Projects | project CRUD | Projects | Hidden |
| Projects | Project Dashboard | My Projects | workspace overview/tabs | Projects | Hidden |
| Projects | Project Calculations | My Projects | saved calc results | Projects (snapshots) | Hidden |
| Projects | Project Inspections | My Projects | inspection records | Projects | Hidden |
| Projects | Project Checklists | My Projects | project-scoped checklists | Projects | Hidden |
| Projects | Project Notes / Attachments / Materials / Suppliers / Reports | My Projects | workspace sub-areas | Projects | Hidden |
| Directory | Directory Landing | Directory | directory entry | Directory | Hidden |
| Directory | Search / filter | Directory | find providers/services | Directory | Hidden |
| Directory | Category listing | Directory | browse by category | Directory | Hidden |
| Directory | Generic Directory profile (incl. Supplier/Service/Material listing) | Directory | provider/service profile | Directory | Hidden |
| Search | Global Search | Global | aggregate domain results | each domain (aggregator thin) | Hidden |
| Search | Search Results + filters | Global | grouped/ranked results | each domain | Hidden |
| Monetization | Home ad slots (real campaigns) | Home | sponsored slots | Monetization/campaign | CONDITIONAL — campaign active |
| Admin | Admin Panel (separate app/web) | Admin (not in user nav) | moderation/verification/campaigns/analytics/flags | Admin | Separate surface |

---

## E. Internal Detail Screens

Not bottom-navigation destinations:
- Topic Detail (A5)
- Article Detail (A8)
- Concrete / Steel / Masonry / Tile calculators (A10–A13)
- Checklist Root & Category Detail (A14–A15) — could be reached from Tools
- Profile Edit (A20)
- Directory profile (future), Project detail (future), Calculator detail (future)

---

## F. Conditional Screens

Visible only when real data/feature/campaign exists:
- Hero / Sponsored Banner — only with an active ad campaign (rule: disappears with no campaign).
- Optional Sponsored Engineering Offer — only with active campaign.
- Current Project Snapshot — only when the user has projects (and My Projects is exposed).
- Saved / Downloads views — only when items exist (empty states already present today).
- Sponsored Directory listings — only when a sponsored listing/campaign exists (organic always shows).

---

## G. Screens NOT Recommended

Avoid bloat; do NOT add:
- Coming Soon cards / disabled fake buttons / empty future tabs for My Projects, Directory, Services, Suppliers, Ads, or Admin (violates NOT READY → HIDDEN).
- Per-type Directory screen trees (Company screen, Supplier screen, Technician screen …) — prefer one generic Directory entity/profile with a `BusinessType` discriminator (already scaffolded in `service_business_profile.dart`).
- Admin management screens inside user navigation — keep Admin as a separate surface.
- Campaign/admin management in normal navigation — document separately (future Admin Panel).

---

## H. Potential Consolidation Opportunities (future only — NOT implemented now)

1. **Articles → Knowledge**: legacy `ArticleRepository` articles/encyclopedic articles merge into the Knowledge domain (Content Studio pipeline) or a bounded legacy reader. **CURRENT — CONSOLIDATE LATER.**
2. **Tools source of truth**: `ArticleRepository.tools` currently feeds the Tools landing grid; a Tools-owned catalog would decouple Tools from the legacy Articles repository. **CONSOLIDATE LATER.**
3. **Project code into My Projects**: partial project code under `lib/features/tools/domain/project/` + `project_list_screen.dart` should reposition into the Projects domain when Projects is surfaced. **MIGRATE / REPOSITION** (deferred).
4. **Profile/Saved to user area**: relocate out of the bottom nav into avatar-accessed user area. **MIGRATE / REPOSITION** (deferred).
5. **Ad system normalization**: replace always-on mock ads with campaign-driven slots that can disappear. **DEFERRED** (monetization normalization — see Product Architecture §11).
6. **Category-order reconciliation**: `_categoryOrder` hardcode vs generated catalog categories. **Requires deliberate decision** (flag 1).
7. **Duplicate-value token consolidation** (`mainText`/`textPrimary`, `surface`/`surfaceWarm`, etc.) — belongs to Master Architecture / design-system normalization, not this phase.

---

## Requirements Traceability

Covered: complete app structure (B), every current major screen (A), every future domain with a clear owner (D, Product Architecture §3), no circular ownership (each screen has one data owner), current (A/C) vs target (B) clearly distinguished, advertising/engineering content strictly separated (§11 + above), Content Studio authoritative (§7), unfinished future domains hidden (§17), no production change.

---

## Protected / Forbidden (unchanged)

ZERO changes were made to: `lib/**`, `test/**`, `assets/encyclopedia/**`, `draft_jsons/**`, `app_ready_jsons/**`, Content Studio source, exporters, schemas, `catalog.generated.json`, `branding/**`, router, AppShell, providers, repositories, `pubspec.yaml`, and content. Only these two documentation files were created:
- `docs/architecture/CIVILPEDIA_PRODUCT_ARCHITECTURE.md`
- `docs/architecture/CIVILPEDIA_SCREEN_MAP.md`
