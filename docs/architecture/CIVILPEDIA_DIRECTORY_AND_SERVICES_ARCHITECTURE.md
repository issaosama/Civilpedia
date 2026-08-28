# CIVILPEDIA — ENGINEERING DIRECTORY & SERVICES MASTER ARCHITECTURE

**Phase:** M6. **Status:** ARCHITECTURE / DOCUMENTATION ONLY — no production code changed.
**Inputs (approved):** M1 `CIVILPEDIA_PRODUCT_ARCHITECTURE.md`, M2 `CIVILPEDIA_SCREEN_MAP.md`, M3 `CIVILPEDIA_NAVIGATION_ARCHITECTURE.md`, M4 `CIVILPEDIA_DATA_OWNERSHIP_AND_DOMAIN_CONTRACTS.md`, M5 `CIVILPEDIA_PROJECTS_ARCHITECTURE.md`, plus live inspection of the current ServiceBusiness / access / ads / Saved / location scaffolding.

> This designs the complete long-term Engineering Directory & Services domain as a practical construction-industry discovery layer. It does not rewrite or delete current scaffolding; it re-parents ownership and layers the Directory domain on top. No production change, no data migration run.

---

## 1. Purpose

Design the Engineering Directory & Services domain as a practical construction-industry discovery layer for engineers, contractors, consultants, suppliers, technicians, companies, shops, service providers, construction materials/products, and equipment providers — integrating cleanly with Home, My Projects, Global Search, User/Saved, and Monetization/Sponsored listings, without contaminating engineering Knowledge or duplicating ownership.

---

## 2. Product Role

The Directory is not a generic phone book. It helps an engineer answer practical questions: Where is a concrete testing laboratory? Who supplies ready-mix concrete? Who performs waterproofing? Where is a surveyor? Which suppliers sell a particular material? Which companies provide equipment? Which contractor operates in my area?

Target workflow:
```
Engineering Need
→ Directory Search / Category
→ Relevant Providers
→ Provider Profile
→ Contact / Save / Link to Project
```
The Directory is **discovery / contact first** — not e-commerce, not marketplace transaction routing.

---

## 3. Current Repository Baseline (verified)

The Directory is a **future / planned domain**. There is no live Directory screen, route, or bottom-nav entry today. What exists is seed scaffolding, primarily under the Profile feature.

| Component | Path | Reality / State |
|---|---|---|
| `ServiceBusinessProfile` | `lib/features/profile/domain/service_business_profile.dart` | Domain entity: `id, name, type, categories, subCategories, baghdadArea, address, phones, whatsapp, description, verificationStatus, featured, foundingPartner, createdAt, updatedAt, futureOwnerUserId, planType, schemaVersion`. `BusinessType` discriminator (12 values). `VerificationStatus {unverified, pending, verified, rejected}`. Has `featured`/`foundingPartner` flags + `planType` (monetization/plan concepts embedded). |
| `ServiceBusinessRepository` | `.../domain/service_business_repository.dart` | Interface: `loadAll/loadById/save/delete/clearAll`. |
| `LocalServiceBusinessRepository` | `.../data/local_service_business_repository.dart` | SharedPreferences-backed. |
| `ServiceBusinessDataSource` | `.../data/service_business_data_source.dart` | SharedPreferences key `sb_profiles`. |
| DI wiring | `lib/core/di/app_dependencies.dart:32,55,79` | `_businessDataSource` + `_businessRepo = LocalServiceBusinessRepository(...)`; getter `businessRepo`. **Wired but not consumed by any screen** (M4 §26 #7: ARCHITECTURAL DEBT — Directory seed). |
| `SafetyBusiness` models NOT present | — | No `company` / `equipment` / `shop` profile models exist yet. |
| `BusinessType` | `service_business_profile.dart:4` | `supplier, technician, equipmentOwner, engineeringOffice, constructionCompany, buildingOffice, testingLab, surveyor, contractor, materialShop, consultantOffice, other` with stable `key`s and `fromKey`. |
| `VerificationStatus` | `service_business_profile.dart:55` | `unverified, pending, verified, rejected`. |
| `BaghdadArea` | `lib/core/location/baghdad_area.dart` | Enum, 24 Baghdad districts + `unknown`/`other`; `enName` + `arName` display. Used in `UserProfile` and `ServiceBusinessProfile`. Baghdad-only today. |
| `FeatureKey` | `lib/core/access/feature_key.dart` | `connectListing, sponsoredListing, supplierProfile, companyProfile, dashboardAccess` (+ non-directory keys). |
| `PlanType` / `PlanTier` | `lib/core/access/` | `free, proEngineer, supplier, company, owner, admin, moderator, support` tiers mapping `FeatureKey→FeatureAccess` (Allowed/Blocked/Limited). `connectListing`=allowed from ProEngineer; `sponsoredListing`/`supplierProfile`/`companyProfile`/`dashboardAccess` vary. These are **visibility gates**, not data owners (M4 §26 #9). |
| Home ads | `lib/features/home/data/datasources/ad_data_source.dart`, `.../models/ad_banner.dart`, `.../widgets/ad_carousel_widget.dart` | `LocalAdDataSource.fetchActiveAds()` **always returns `_mockAds`** (4 hardcoded Arabic ads). `AdBanner` model standalone (id/image/action/title/subtitle/badge). AdCarouselWidget self-constructs `LocalAdDataSource` (UI→data direct). **M4: BLOCKER before real monetization** — no campaign → no slot rule violated (§27). |
| Saved | `lib/features/saved/presentation/saved_screen.dart` | Legacy Saved: 2 tabs (Favorites / Downloads), merges legacy `favorites` + `encyclopediaFavorites` + downloads via Hive. **No generic `SavedItemsStore` with `ownerDomain/entityType/entityId` yet** — that is the M4 target reference model. |
| AppShell | `lib/core/navigation/app_shell.dart` | Current 5 tabs: Home, Encyclopedia, Tools, Saved, Profile. Target (Home, Knowledge, Tools, My Projects, Directory) documented but Directory branch NOT added; comment explicitly says "do not extend it preemptively." |
| Navigation | router (go_router) | No `/directory` routes registered. |

**Flags (verified, not fixed):**
1. `businessRepo` wire-up + `ServiceBusiness` storage exist but are **unused** (M4 §26 #7).
2. `ServiceBusinessProfile` embeds **monetization/plan concepts** (`featured`, `foundingPartner`, `planType`) inside a Directory-owned entity — to be re-parented/decoupled from the Directory **core** entity (§13/§25/§26), while preserved for migration.
3. Home ad carousel **always returns mock ads** (M4 BLOCKER, §27) — do not modify now.
4. Saved is legacy favorites/downloads, not yet the generic reference store; the `ownerDomain/entityType/entityId` contract is target.
5. Location is Baghdad-only enum; target is Country → Governorate → City/Area with stable IDs (§10).

---

## 4. Ownership Boundary (approved M4)

**Directory owns:** Directory Entity / Business; Supplier; Contractor; Consultant; Engineering Office; Technician; Shop; Service Provider; Material/Product listing; Equipment provider; verification state; service areas/location; organic listing profile data; directory categories/type.

**Monetization owns:** sponsorship state, campaign, sponsored placement, paid promotion, impression/click tracking metadata.

**Critical rule (approved M4 §10):**
```
Directory Supplier  +  Monetization Sponsorship  =  Sponsored presentation
```
A Sponsored Supplier is **NOT** a duplicate Supplier entity. Monetization must not duplicate supplier data; Ads reference the Directory entity.

**Must NOT own (Directory):** engineering Knowledge content (Content Studio), Tool formulas/templates, Project data, Saved (User-owned), monetization campaigns.

---

## 5. Directory Entity Model

**Recommendation: one reusable base entity `DirectoryEntity` with a `BusinessType` discriminator**, plus small type-specific extensions only where materially required. Avoid both a 60-nullable-field God entity and a dozen near-identical models.

### Core `DirectoryEntity` fields (Directory-owned)
- `id` (stable, non-display, §33)
- `displayName`
- `type` (`BusinessType` stable key, §6)
- `description`
- `logo`/`imageRef`
- `phones` / `whatsapp` / `email` / `website` / social links
- `locationRef` (country/governorate/city/area, §10)
- `serviceAreas` (list of location refs / area keys)
- `verificationStatus` (§14)
- `workingHours`
- `categories` / `tags`
- `createdAt`, `updatedAt`, `schemaVersion`

### Type-specific extensions (small, only where needed)
- **Supplier/Shop/MaterialVendor** → optional `productCatalog` refs (§8)
- **TestingLab/Surveyor/ConsultantOffice/EngineeringOffice** → optional `services` (§7) + optional `certificates/credentials`
- **EquipmentProvider** → optional `equipmentCatalog` refs (§7)
- **Contractor/Company** → optional `projectTypes` / `companyProfile` extension
Keep extensions as optional sub-objects, not required columns on every row. **Do not force Material/Product into the service/company profile if semantics diverge materially** — Material/Product may get its own fused detail model (§8, M4 open #4 / M3 open #5), but stays Directory-owned.

Prefer shared profile primitives (contact block, location block, verification badge, services block) reused across types rather than per-type duplicate widgets.

---

## 6. Business Types

**Stable type keys are the identity — never display labels.** Arabic/English labels may change; keys must not.

Current `BusinessType` keys (preserve, treat as stable):
`supplier`, `technician`, `equipment_owner`, `engineering_office`, `construction_company`, `building_office`, `testing_lab`, `surveyor`, `contractor`, `material_shop`, `consultant_office`, `other`.

Target stable type key alignment (map current → target concept; add missing keys as new stable values, never rename display reuses):

| Target Concept | Preferred Stable Key | Relation to current key |
|---|---|---|
| company | `company` | new (general company / companyProfile) |
| contractor | `contractor` | keep |
| consultant | `consultant` / `consultant_office` | keep `consultant_office` (stable) |
| engineering office | `engineering_office` | keep |
| supplier | `supplier` | keep |
| shop | `shop` / `material_shop` | keep `material_shop`; add generic `shop` if needed |
| technician | `technician` | keep |
| service provider | `service_provider` | new general; specific via services taxonomy |
| laboratory | `testing_lab` | keep |
| equipment provider | `equipment_provider` | align from `equipment_owner` (keep `equipment_owner` stable + add `equipment_provider` only if clearly needed — avoid gratuitous renames) |
| material vendor | `material_shop` / `material_vendor` | keep `material_shop`; `material_vendor` only if semantics diverge |

**Rule:** defining new keys > renaming existing ones that are already persisted (e.g. `equipment_owner`, `material_shop`, `consultant_office` are already stable in `ServiceBusinessProfile`). Never change a key's spelling once it appears in persisted JSON. Label lookup (Arabic/English) is separate from the key.

**Business Type Table**

| Stable Type Key | Arabic Label (display only) | Concept | Type-specific Data Needed? | Notes |
|---|---|---|---|---|
| `supplier` | مورّد | Sells/provides materials or components | Optional product refs | Keep stable |
| `technician` | فني | Skilled technician/installer | Services, working hours | Keep stable |
| `equipment_owner` | مالك معدات | Owns/rents equipment or machinery | Equipment catalog | Keep stable (stable key; label is display only) |
| `engineering_office` | مكتب هندسي | Engineering office | Services, credentials | Keep stable |
| `construction_company` | شركة إنشاءات | General construction company | Project types | Keep stable |
| `building_office` | مكتب بناء | Building contractor/office | Project types | Keep stable |
| `testing_lab` | مختبر فحص | Testing/laboratory services | Services (testing taxonomy) | Keep stable |
| `surveyor` | مساح | Land/site surveying | Services | Keep stable |
| `contractor` | مقاول | Contractor | Project types, service areas | Keep stable |
| `material_shop` | محل مواد | Construction materials shop | Product refs | Keep stable |
| `consultant_office` | مكتب استشاري | Consultant | Services, credentials | Keep stable |
| `other` | أخرى | Fallback | — | Keep stable |

---

## 7. Services Taxonomy

Services are a major Directory dimension. **Ownership/configuration only** — not content-hardcoded inside presentation widgets. Services are a **configuration concept** owned by the Directory domain (a service taxonomy), referenced by entities and searchable projections. Do not duplicate the taxonomy in each profile widget.

Example service groups (configuration seed, not dataclass commitment):
- **Testing / Laboratory:** soil testing, concrete testing, asphalt testing, material testing, field laboratory.
- **Surveying:** land surveying, setting out, leveling, quantity/site survey support.
- **Construction Works:** waterproofing, electrical, mechanical, HVAC, plumbing, finishing, painting, gypsum, flooring, façade, insulation.
- **Equipment:** cranes, excavators, loaders, generators, pumps, scaffolding, formwork rental.
- **Engineering Services:** structural design, architectural design, supervision, quantity surveying, laboratory consultancy, BIM/CAD services.

Architecture: stable **service keys** (never Arabic/English label as ID), grouped into service categories; an entity references services by stable key. Full taxonomy depth is a V1.5 concern (V1 ships a shallow, curated set; §31). Deep taxonomy is content configuration — the same class of "managed taxonomy" as location (§10) and category — owned by Directory and managed by its operational surface (§23), kept fully separate from Content Studio (§35).

---

## 8. Materials / Products

**Separate Directory Product / Material Listing (Directory-owned) from Project Material Record (Projects-owned).** Never merge them.

A Directory product/material listing may represent: cement, steel, blocks, waterproofing materials, tiles, insulation, admixtures, pipes, electrical products, finishing products.

**Determine the model — recommendation (hybrid C, folded into the generic entity):**
- **Option A** — child of Supplier only: too rigid; a product can be offered by many suppliers.
- **Option B** — independent Directory listing linked to suppliers: powerful but heavier; adds a second top-level entity kind early.
- **Option C (recommended)** — hybrid: a product/material may be expressed either (a) inline as an entity-level offering/tag on the supplier/shop/equipment provider profile (lightweight, enough for V1 discovery), OR (b) promoted to a **Directory-owned product listing** with stable `productId` once product depth is justified (V1.5). Directory product listing is never a Project material record.

**Do NOT create e-commerce architecture.** Civilpedia Directory is discovery/contact first: product listings carry a name/description/image/reference + who offers it + contact — no cart, pricing engine, payment, or order model. Pricing/stock (if ever) is out of scope for V1.

---

## 9. Provider Profile

One strong **reusable profile experience** (`DirectoryEntityProfile`), not per-type screens (M2: prefer generic Directory entity/profile + `BusinessType`).

Potential sections:
- identity/header (logo, name, type, verification badge)
- verification state (§14)
- category/type
- description
- contact actions (§16)
- location / service areas (§10)
- services (§7)
- products/materials (§8)
- work gallery (optional media)
- working hours
- certificates/credentials (where appropriate)
- related providers
- save (§17)
- link to project (§18)

**Mandatory vs optional (avoid clutter):**
- Mandatory (V1): identity/name, type, verification display, at least one contact action, location/service-area (or explicit "not specified").
- Optional: gallery, working hours, certificates, products, related providers.
Do not show placeholder clutter for missing optional fields; a clean profile with fewer sections.

**Sponsored presentation must not appear as an engineering-quality signal** — no "sponsored" badge near "verified" (§13/§14).

---

## 10. Location Model

Civilpedia is initially Iraq-focused; `BaghdadArea` exists but **must not permanently hardcode the whole system to Baghdad**.

Target hierarchy: **Country → Governorate → City / District / Area**.

- **Stable location IDs** (e.g. `iq` country, governorate key, city/area key) **separate from translated display names** (Arabic/English lookup is display-only, like business type keys and service keys).
- `Country` is a first-class concept so expansion to all Iraq governorates (and beyond) is non-breaking.
- Define a small `LocationRef` / `GovernorateRef` (country → governorate → city/area) contract. `BaghdadArea` may remain a **legacy/back-compat** representation, mapped into the general model without forcing Baghdad as a system-wide cap.
- Future **"Near Me"** consumes the location contracts — do not design map/backend now.
- Profiled location = principal location + service areas (list of location refs).

Do not design map/backend implementation. Location is a managed taxonomy owned by Directory (same class as services/categories), configurable via the operational surface (§23).

---

## 11. Search / Filters

Directory search supports useful engineering filters (V1: a practical subset; §31):
- entity name
- service
- product/material
- business type
- governorate/city/area (location filter)
- verified (filter on verification — a **quality** filter, OK)
- service area

**Sponsored status must NOT become a semantic relevance filter.** Users never filter "sponsored" as a category, and paid placement is never folded into relevance filtering.

Ranking principle:
```
relevance first → then clearly-labeled sponsored insertion per product rules
```
Document organic ranking vs sponsored insertion (§12, §13). Do not design the ranking algorithm in detail.

---

## 12. Organic Ranking

## 13. Sponsored Placement

**This is critical — the Organic vs Sponsored contract.**

**Organic Listing:** normal Directory entity. Ranked by relevance, category, location, and quality/verification signals where appropriate (e.g. verified shown appropriately — but verification ≠ rank-bank; ranking detail deferred). Owner: Directory.

**Sponsored Listing:** the **same** Directory entity. An additional Monetization relationship contributes: campaign, placement, start/end, sponsorship type, disclosure label. Owner: Monetization.

Sponsored content **must be visually labeled** (a clear, user-facing disclosure like "Sponsored" / "مُموّل") and must **never alter the underlying Directory entity** to pretend it is inherently "better." Never mutate entity score/verification to justify paid placement.

**Organic vs Sponsored Table**

| Aspect | Organic | Sponsored |
|---|---|---|
| Directory entity | Yes (same entity) | Yes (same entity — no duplicate) |
| Ranking | relevance/category/location/quality signals | insertion by paid campaign per product rules |
| Source of truth for profile data | Directory | Directory (profile data unchanged) |
| Sponsor relationship | — | Monetization (campaign, placement, period) |
| Owner | Directory | Monetization (relationship); Directory (entity) |
| User disclosure | — | Labeled "Sponsored" / equivalent |
| Verification implication | None (may be verified or not) | **None** — sponsorship never implies verification |

Sponsored status is **never** an engineering verification signal (§14). Relevance is separate from placement (§11).

---

## 14. Verification

`VerificationStatus` belongs to Directory. Define the conceptual **target lifecycle** capable of representing **five states** (be economical — do not over-design transitions):

- **Unverified** = listing exists but has not entered/finished verification.
- **Pending** = verification request is under review.
- **Verified** = verification approved.
- **Rejected** = verification application/evidence was rejected.
- **Suspended** = a previously active/visible/verified listing has been administratively restricted or suspended.

### Rejected ≠ Suspended (lifecycle semantics differ)
- `rejected` describes the **verification decision**: the claim/evidence was **not** accepted, so the listing is not verified.
- `suspended` describes **administrative restriction of an otherwise (previously) active/visible/verified listing** — it was live, then restricted/moderation action was taken.
They are **not** synonyms and must **not** be treated as a direct rename. The current production seed enum is `{unverified, pending, verified, rejected}`; the target adds `suspended` as an additional distinct state — nothing is relabeled.

### Backward compatibility (persisted values must stay meaningful)
Existing persisted `VerificationStatus` values in `sb_profiles` (`unverified`, `pending`, `verified`, `rejected`) **must remain readable** and must **not** be silently remapped — in particular **never silently map `rejected → suspended`**. Any future model migration must follow the standard safepath:
```
read legacy status
→ preserve meaning
→ normalize only through an explicit migration
→ verify persisted data
→ retire legacy representation only after compatibility is proven
```
No stored value may silently change meaning.

**Verification ≠ Sponsored.** A business can be:
- Verified + Organic
- Verified + Sponsored
- Unverified + Organic
- (Unverified + Sponsored is possible but must be clearly disclosed — sponsorship never implies verification; a sponsored unverified listing still shows "unverified" status. A rejected or suspended listing likewise remains rejected/suspended regardless of any sponsorship.)

This distinction is **explicit** in architecture: verification badge is Directory-owned and means the entity/its claims passed Directory's own checks; sponsored badge is Monetization-owned and means a paid placement. They render distinctly and never imply one another.

Do not overbuild: no review-sourced verification, no credentials vault in V1. A simple owned status + optional admin-managed evidence reference (§23). `verificationStatus` remains genuinely Directory-owned in the seed (§3/§25).

---

## 15. Reviews / Ratings

**Be conservative.** Ratings/reviews carry moderation, fraud, abuse, legal/reputational, and fake-review risks.

**Recommendation: V1 has NO public ratings/reviews** unless strong justification appears.
- Defer to later: structured feedback / **verified reviews** (only from users with confirmed interactions/verified purchases/engagements).
- Never seed fake reviews.
- If later added, they must be Directory-owned or a domain-extensible review service — not monetizable placement, and not spoiled by ads.

Document as deferred (§31 V2+).

---

## 16. Contact Actions

Provider profile may offer: call, WhatsApp, website, directions/map, email.

Architecture treats these as **user actions**, not separate entity ownership. The entity holds contact **references** (phones, whatsapp, email, website) — Directory-owned data — and the profile offers actions over them.

- Analytics may record **safe engagement events** (contact click) — never content.
- **Do not expose private user/project information to the provider automatically.** A contact action is the user initiating contact; it does not push the user's private project data to the provider without explicit user action.

---

## 17. Saved

Users can save Directory entities. **Saved stores a reference only:**
```
ownerDomain = directory
entityType
entityId
timestamp
(optional lightweight metadata for display)
```
No copied full provider profile unless an **explicit offline projection** is required (§21). This matches M4 `SavedItemsStore` (`entityType/entityId/ownerDomain`) and the approved generic Saved contract; Directory entity remains authoritative. Saved is **User-owned** (M4 §9).

When a saved Directory entity is removed/suspended, Saved shows a graceful unavailable/removed state (§34) rather than a silent redirect to another entity.

---

## 18. Projects Integration

Approved (M4 §15 / M5): Projects stores **ProjectSupplierReference / ProjectServiceReference**; **Directory remains authoritative**.

Future flow:
```
Directory Provider
→ Add / Link to Project
→ choose Project
→ Projects stores reference + project-specific note if needed
```
- Directory must **NOT import `LocalProjectRepository`** — Directory depends only on a contract concept (reference-aware linking), never a Project data source.
- Projects may hold a lightweight **display snapshot** (name) to keep history readable, but Directory is authoritative; stale links render gracefully (§34).
- No project attachment/document data is referenced by Directory; Directory never reads Project internals (§28).

---

## 19. Home Integration

Home may consume **lightweight Directory projections**:
- useful nearby/provider recommendations (later)
- sponsored engineering placement (§27)
- recently viewed/saved Directory item

Home as **aggregator, not owner** (M4): Home never imports Directory repositories; it consumes read-only projections/cards. Do not turn Home into a business repository or Directory data owner. Home must remain complete with zero Directory and zero ads (§27).

---

## 20. Global Search

Directory exposes **searchable projections** to Global Search.
Search result identity must include:
```
ownerDomain
entityType
entityId
```
Selecting a result → **canonical Directory detail route** (`/directory/:type/:entityId`, §30).

Global Search aggregates per-domain projections (M4 `GlobalSearchGateway`); Directory does not own Search, Search does not own Directory entities. Search is index/projection, never entity owner (M4 §7 / rule 7).

---

## 21. Offline / Caching

Directory is likely **remote-authoritative eventually**. Offline strategy is **cache-oriented**:
```
Remote source
→ Directory repository
→ local cache / projection
```
- **Offline cached entity ≠ local ownership.** Cache is a projection of the Directory store, not a second owner.
- Reasonable offline fallback (do not promise complete offline Directory):
  - recently viewed
  - saved (references + light display snapshot where explicitly needed)
  - cached category/search results
- Do not design the backend; define the repository/cache contract (§22).

---

## 22. Future Backend

**Do NOT design Firebase collections or database tables.** Define only domain requirements:
- remote authoritative directory data
- moderation / verification
- search indexing
- location filtering
- media storage
- sponsorship linkage
- caching

Backend technology comes later. Directory repository contract (interface) allows Local now / Remote later without rewriting Domain/UI (offline-first, persistence swappable — M4 §20/§21).

---

## 23. Admin / Moderation

Directory requires a separate **operational/admin** surface (future).
Potential Admin capabilities:
- entity creation/edit
- business claim requests (§24)
- verification
- category management
- service taxonomy
- location taxonomy
- moderation
- suspension
- sponsorship-management integration

**Admin surface does NOT own Directory entities.** Directory remains the domain owner; Admin is management/presentation access only (M4 rule 13). Admin may invoke domain management APIs but never becomes owner of Directory entities, Ads, or Knowledge.

---

## 24. Business Claiming

Future: Business Owner → Claim Listing. **Not V1.**
```
Claim request
→ verification workflow
→ account linked to Directory entity
```
Documented as future architecture only (§31 V2+). `futureOwnerUserId` already exists on `ServiceBusinessProfile` as a seed field — preserve it; the claiming workflow itself is future.

---

## 25. Feature Access / Plans

Current: `FeatureKey` (`connectListing, sponsoredListing, supplierProfile, companyProfile, dashboardAccess`), `PlanTier`, `PlanType`, with `featured`/`foundingPartner`/`planType` on `ServiceBusinessProfile`.

**Do NOT automatically preserve the existing plan model as final.** Classify:

- **Useful seed:** the concept of feature *gates* (`FeatureKey`) controlling visibility — consistent with M4 (gates gate visibility, they do not create owners). `verificationStatus` is genuinely Directory-owned.
- **Premature/needs re-parenting:** plan/monetization fields (`featured`, `foundingPartner`, `planType`) embedded inside the Directory core entity model; `sponsoredListing`/`supplierProfile`/`companyProfile`/`dashboardAccess` are **Monetization/visibility** gates, not Directory-core data.

**Reconfirmed (compatibility stance):** seed fields `featured`, `foundingPartner`, `planType` are **NOT** Directory identity/verification fields. `verificationStatus` is the sole Directory-owned status dimension. `featured`/`foundingPartner`/`planType` must **not** automatically become core Directory identity or verification fields; they remain **migration/compatibility concerns** until Monetization/Business-plan architecture is finalized — never repurposed as verification or ranking authority (§13/§26/§36).

**Directory architecture must work without requiring paid plans in V1.** V1 Directory is fully usable with zero paid/plan coupling. Monetization can be added incrementally (§26). Decouple the Directory **core entity** from sponsorship/plan state in the long-term model (sponsorship lives on Monetization; access gates gate visibility), while preserving current stored fields for migration (§36).

---

## 26. Monetization

Architect future revenue without harming trust. Potentials:
- sponsored Directory listing
- promoted service
- sponsored material/product
- Home campaign
- supplier/company enhanced profile
- business dashboard later

**Avoid pay-to-rank disguised as organic relevance.** Always separate:
```
Organic Relevance   (Directory)
from
Paid Placement      (Monetization)
```
Sponsored suppliers reference the Directory entity (never duplicate). Monetization owns campaign/placement/period/state; Directory owns the entity and organic ranking (§12/§13).

---

## 27. Home Advertising Contract

Current Home carousel always returns mock ads (`LocalAdDataSource` → `_mockAds`). **M4: BLOCKER before real monetization.**

Document the **future contract** (do NOT modify current mock ads now):
```
AdPlacementRequest
→ Monetization
→ active eligible campaign(s)
→ SponsoredPlacement projection
```
- **No eligible campaign → no ad → no reserved blank slot.**
- **Home must remain visually complete with zero ads.**
- Sponsored content is labeled and references real Directory entities (never mock/duplicate).
- Ads must not be the semantic ranking of Directory results (§11–13).

Preserve current mock ads and `AdCarouselWidget` behavior (do not change in M6); classify the always-return-mock behavior as the known BLOCKER to resolve before production monetization, not fix now.

---

## 28. Privacy

- Directory must **not access private Project content** (notes, calculations, attachments, engineering records).
- Monetization must **not inspect private Project data for ad targeting** without a future explicit privacy architecture.
- Targeting should initially use safe context only:
  - Directory category
  - general app placement
  - coarse user-selected location
  - explicit search context if privacy-approved
  - **Not** private engineering documents/sessions.
- Contact actions never auto-expose private user/project info to providers (§16).

---

## 29. Analytics

Potential events: listing impression, sponsored impression, profile view, contact click, save, link-to-project.
Analytics must **distinguish organic impression vs sponsored impression** (a sponsored impression is tracked as sponsored, never inflated as organic).
Do not design the analytics vendor. No private engineering content in analytics payloads.

---

## 30. Navigation

Preserve M3:
```
/directory                → landing / search / filters
/directory/:type          → category listing
/directory/:type/:entityId → entity detail
```
- **Avoid a route tree per business type.** One generic Directory navigation model.
- `:type` is a **stable BusinessType-style key**, not a translated label.
- Search/filters preserved via query/state — no `/directory/service/consultant/...` pyramid.
- **Material/Product detail** may get a dedicated route (`/directory/material/:id`) only if its entity model materially diverges (deferred — M3 open #5); otherwise uses the generic detail route. Real in the docs; not change the router now.
- Organic vs Sponsored is a **data/query concern, not different routes** (§13): `/directory/:type` returns organic + sponsored segments, visually distinct.
- Directory enters the Bottom Navigation **only when ready** (NOT READY → NOT EXPOSED, M3 §4/§20); the current 5 tabs untouched until an owner phase.

---

## 31. V1 / V1.5 / V2+ Roadmap

**V1 (small, buildable cleanly) — recommended:**
- Directory Landing
- Business/Provider categories
- Search
- Location/category filtering (baghdad-first, via general location contract)
- Provider Listing
- Provider Detail/Profile (generic, §9)
- Contact actions
- Verification display
- Save provider (reference via Saved contract)

**V1 deliberately excludes:** reviews, claiming, business dashboard, sponsored listings required for launch, e-commerce, messaging, booking. Sponsored infrastructure may remain **architectural only** and launch later (§13/§26/§27).

**V1.5 (potential):** deeper services taxonomy, materials/products (option C, §8), project linking (§18), richer location filters, sponsored listings, enhanced provider media/profile.

**V2+ (potential, not commitments):** business claiming (§24), business dashboard, provider analytics, promoted products, RFQ/request quotation (§32), verified reviews (§15), richer maps/geolocation.

**V1 Roadmap Table**

| Capability | V1 | V1.5 | V2+ | Reason |
|---|---|---|---|---|
| Directory Landing | ✓ | ✓ | ✓ | Core entry |
| Categories | ✓ | ✓ | ✓ | Browse |
| Search | ✓ | ✓ | ✓ | Discovery |
| Location/category filters | ✓ | ✓ | ✓ | Baghdad-first via general contract |
| Provider Listing | ✓ | ✓ | ✓ | Core |
| Provider Detail/Profile (generic) | ✓ | ✓ | ✓ | One reusable profile |
| Contact actions | ✓ | ✓ | ✓ | Discovery/contact-first |
| Verification display | ✓ | ✓ | ✓ | Trust |
| Save provider | ✓ | ✓ | ✓ | Reference via Saved |
| Services taxonomy (deeper) | — | ✓ | ✓ | Adds discovery depth |
| Materials/Products (option C) | — | ✓ | ✓ | Product depth |
| Project linking | — | ✓ | ✓ | Cross-domain value (M5) |
| Richer location filters | — | ✓ | ✓ | Expansion breadth |
| Sponsored listings | — (arch only) | ✓ | ✓ | Revenue; labeled |
| Enhanced media/profile | — | ✓ | ✓ | Richer profiles |
| Business claiming | — | — | ✓ | Ownership workflow |
| Business dashboard | — | — | ✓ | Provider portal |
| Provider analytics | — | — | ✓ | Insight |
| Promoted products | — | — | ✓ | Revenue depth |
| RFQ / request quotation | — | — | ✓ | Powerful later (§32) |
| Verified reviews | — | — | ✓ | Trust; moderation-heavy |
| Richer maps/geolocation | — | — | ✓ | Location fullness |
| Ratings/reviews (general) | — | — | ✓ | Deferred (§15) |

---

## 32. RFQ Future

Long-term: Engineer → select material/service → request quotation from providers. Potentially powerful. **Classify as V2+ / optional.** Do not let RFQ complexity enter Directory V1. Document the concept for later (providers by service/area, structured request, response without e-commerce plumbing); defer entirely.

---

## 33. IDs / Identity

IDs must:
- be **stable**
- **not use translated display names**
- **survive renames**
- **support offline cache** (§21)
- **support future backend migration** (§22)
Business type keys and service keys and location IDs must also be stable (§6/§7/§10).
Do not use route strings as entity identity. `ServiceBusinessProfile.id` is the entity id today; keep stable ID semantics, never rename to match a display name.

---

## 34. Error / Edge States

Document (do not silently redirect to another entity):
- **Unavailable provider** → Directory not-found/removed state.
- **Removed/suspended listing** → profile shows suspended/removed; not replaced.
- **Stale offline listing** (remote changed/removed) → cached stale marker with refreshed-on-next-sync; not silently swapped.
- **Broken saved reference** (saved entity gone) → graceful unavailable in Saved (§17).
- **Campaign points to unavailable entity** → sponsored placement suppressed; no blank slot / no broken promo (§13/§27).
- **Invalid location** → location filter not-found / country-governorate-city fallback, never wrong-entity.
- **Provider has no contact information** → profile renders without contact actions; no placeholder spam.
- **Unverified business** → unverified state shown; never "verified" by default.
Always present an explicit, recoverable state; never silently substitute a different entity (§5/M4 rule 11).

---

## 35. Content Studio Separation

**Directory content is NOT engineering Knowledge content.**
- Do **not** put supplier profiles, service listings, advertisements, or business promotions inside Encyclopedia Draft JSON / Content Studio pipeline.
- Content Studio engineering pipeline remains **completely separate**.
- If Directory eventually needs its own admin/content management, it gets its **own domain-specific operational system** (§23) — never routed through Content Studio.
- No Directory change during M6 touches Content Studio, exporters, schemas, or generated catalogs.

---

## 36. Current → Target Migration

Design evolution without rewrite.

```
ServiceBusiness scaffolding
→ evaluate usefulness (it is the correct seed: generic entity + BusinessType)
→ preserve compatible concepts (id, type keys, verification, baghdad location)
→ introduce Directory domain (DirectoryEntity + services/location/categories taxonomies)
→ move/wrap implementation (re-parent ownership; do not delete)
→ verify (data + behavior preserved, references resolve)
→ retire obsolete scaffolding ONLY later (e.g. unwired businessRepo path after Directory wired)
```

Preserve:
- `BusinessType` stable keys + `fromKey` mapping.
- `VerificationStatus` values.
- `BaghdadArea` representation (as back-compat into Country→Governorate→City/Area).
- `ServiceBusinessProfile` stored data (`sb_profiles`) — migrate/read-old-gracefully, never drop.
- Decouple plan/monetization fields (`featured`/`foundingPartner`/`planType`) from the Directory **core** entity when introducing the domain; keep reading legacy until verified.

**Current → Target Migration Table**

| Current Code/Model | Current State | Target Role | Migration Strategy | Removal Gate |
|---|---|---|---|---|
| `ServiceBusinessProfile` | Unwired seed (SharedPreferences) | Directory `DirectoryEntity` core | Reuse fields to seed entity; map id/type/verification/location; add general location + taxonomies | After Directory wired + data verified |
| `BusinessType` (12 keys) | Seed discriminator | Stable entity discriminator | Preserve keys/`fromKey` | No removal planned (stable) |
| `VerificationStatus` | Seed enum (`unverified,pending,verified,rejected`) | Directory-owned verification; add `suspended` as a distinct state | Preserve all legacy values; **never remap `rejected→suspended`**; normalize only via explicit migration, verify, then retire | Retire only after replacement + compatibility verified (§14) |
| `BaghdadArea` | Enum, Baghdad-only | Back-compat → Country/Gov/City/Area | Map into general location contract; keep legacy reader | After location migration verified |
| `LocalServiceBusinessRepository` + `ServiceBusinessDataSource` + `businessRepo` | Wired but unused (M4 debt #7) | Directory repository path | Wire into Directory feature; reuse contract | After Directory launch + feature verified |
| `FeatureKey` plan gates | Visibility gates | Gates (not owners) | Keep gate semantics; do not couple into core Directory | Never remove gate concept; regions reviewed at monetization |
| Plan fields (`featured`/`foundingPartner`/`planType`) in entity | Embedded in entity | Monetization/visibility, decoupled from core entity | Re-parent/read-legacy; preserve stored values | After Monetization architecture phase |
| Home mock ads (`LocalAdDataSource`) | Always-return mock (BLOCKER) | Future AdPlacementProvider (Monetization) | Keep; integrate behind contract later (§27) | After real monetization phase (not M6) |
| Saved (legacy favorites/downloads) | Legacy tabs | Generic Saved reference store | Introduce ownerDomain/entityType/entityId | After references store verified |

---

## 37. Open Decisions

1. **Directory entity unification** — confirm one generic `DirectoryEntity` + `BusinessType` (M4 open #4 / M3 open #5; recommended generic + small extensions). Material/Product may diverge into own detail model — decision deferred.
2. **BusinessType key set** — final alignment: reuse existing stable keys vs. add `company`/`shop`/`service_provider`; never rename persisted keys.
3. **Location model scope** — exact Country→Governorate→City/Area ref shape and how `BaghdadArea` maps (V1 keeps Baghdad-first via general contract).
4. **Services taxonomy depth** — curated shallow seed in V1 vs. deeper taxonomy content in V1.5; ownership/config location.
5. **Materials/Products model** — confirm Option C (inline profile offering, promoted product listing later) vs. independent listing now.
6. **Saved generic store rollout** — when `ownerDomain/entityType/entityId` reference store replaces/extends legacy favorites/downloads.
7. **Sponsored launch timing** — sponsored listings architecture-only in V1; launch gated by Monetization phase.
8. **Home ad contract migration** — when the always-mock `LocalAdDataSource` is replaced by the campaign-gated `AdPlacementProvider` (BLOCKER owner decision).
9. **Admin surface existence** — Directory operational/admin surfacing timing (§23).
10. **Verification evidence depth** — how much evidence/review an admin keeps per verified entity in V1.

---

## 38. Non-Negotiable Rules

1. One authoritative owner per entity; secondary owners are forbidden (M4 rule 1).
2. Directory owns business entities/verification/organic listing; Monetization owns sponsorship/campaign; **sponsored ≠ second entity** (M4 rule 6). 3. Verification ≠ Sponsored; sponsored never implies verification (§14). 4. Directory is discovery/contact first; **no e-commerce** (§8). 5. Directory stays separate from Content Studio (§35). 6. Home is aggregator, never owner; Home complete with zero ads (§27). 7. Projects store only references; Directory authoritative (§18). 8. Search aggregates projections; never owner (§20). 9. Saved references IDs; never full copies unless explicit offline projection (§17). 10. Offline cache ≠ ownership (§21). 11. Backend designed as requirements only (no Firebase/tables) (§22). 12. Admin is management access, never owner (§23). 13. No per-type screen/route tree duplication (§9/§30). 14. Stable keys/IDs never equal translated display labels (§6/§7/§33). 15. Do not silently redirect to another entity on error (§34). 16. Unfinished monetization remains hidden; sponsored listings labeled (§13/§27). 17. Current scaffolding preserved, not deleted; retire only after verification (§36). 18. No production/storage/content changes in this phase.

---

## Requirements Traceability (M6)

Confirmed covered: companies (§5/§6/§9), contractors (§6/§9), consultants (§6/§9), engineering offices (§6/§9), suppliers (§5–§18), shops (§6), technicians (§6), services (§7/§9), materials/products (§8), equipment (§7), location (§10), search (§11), filters (§11/§31), verification (§14), save (§17), Projects integration (§18), Home integration (§19/§27), Global Search (§20), organic listings (§12), sponsored listings (§13/§26), Home advertising (§27), privacy (§28), analytics (§29), offline caching (§21), admin/moderation (§23), future monetization (§26), RFQ future (§32), Content Studio separation (§35), no code duplication (§5/§9/§36), no fake unfinished features (§3/§27/§31/M3 rule).

**Verification checklist (all pass):** every Directory entity has one owner (§4); sponsored state does not duplicate entities (§13); verification ≠ sponsorship (§14); Home does not own Directory (§19); Projects store only references (§18); Search only aggregates projections (§20); Directory separate from Content Studio (§35); V1 small and buildable (§31); unfinished monetization hidden (§27/§31); architecture supports Iraq-wide expansion (§10/§6); no route/type depends on Arabic display labels (§30/§33).

---

## Material Contradiction Check (M6)

No material contradiction with M1–M5 was found. M6 is additive and aligns with: M4 Directory ownership (§8), Monetization ownership (§10), the generic-entity preference, the no-duplicate-sponsorship rule, the mock-ad BLOCKER classification (§26), and M3 Directory navigation + NOT READY → NOT EXPOSED. No STOP condition applied.

---

## Protected / Forbidden (unchanged)

ZERO changes to: `lib/**`, `test/**`, `assets/**`, `draft_jsons/**`, `app_ready_jsons/**`, Content Studio, exporters, schemas, generated catalogs, `pubspec.yaml`, branding, and the approved M1–M5 docs. This phase created exactly one file: `docs/architecture/CIVILPEDIA_DIRECTORY_AND_SERVICES_ARCHITECTURE.md`.
