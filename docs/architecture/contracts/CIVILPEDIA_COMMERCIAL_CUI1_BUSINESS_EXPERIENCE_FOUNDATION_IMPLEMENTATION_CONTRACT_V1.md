# Civilpedia — CUI-1 Business Experience Foundation Implementation Contract V1

DOCUMENT_STATUS: ACCEPTED — CANONICAL CUI-1 IMPLEMENTATION CONTRACT

FREEZE_STATE: FROZEN — ACCEPTED CUI-1 SLICE DEFINITION ONLY

ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-05

IMPLEMENTATION_AUTHORIZED: NO

DOCUMENT_VERSION: 1

AUDIT_DATE: 2026-10-05 — local completion; started 2026-10-04

DOCUMENTARY_CORRECTION_DATE: 2026-10-05 — historical clarification pass; acceptance was not issued during that pass

MODE: DOCUMENTARY FINALIZATION ONLY — ACCEPTANCE / CONTRACT FREEZE, NO IMPLEMENTATION

PROPOSED_SLICE: CUI-1 — Commercial Business Experience Foundation

CURRENT_COMMERCIAL_SLICE: NONE; M3 CLOSED; M4 NOT AUTHORIZED; M5 NOT AUTHORIZED

UI_CURRENT: R10.5-D — PRE-IMPLEMENTATION AUDIT ONLY; IMPLEMENTATION NO

PROPOSED_VISIBLE_UI_DELTA: YES, ONLY AFTER SEPARATE AUTHORIZATION

PROPOSED_BACKEND / COMMERCIAL_AUTHORITY_DELTA: ZERO

PUBLIC_BACKEND_AUTHORITY_DELTA: ZERO

COMMERCIAL_AUTHORITY_DELTA: ZERO

This accepted/frozen contract defines the CUI-1 public Directory presentation foundation, with a generic management entry and an explicitly informational commercial shell. Architect acceptance applies to the slice definition only; it does not create a commercial Business model, authorize implementation, unlock a UI roadmap slice, or establish publication eligibility. Existing Directory visibility remains the accepted pre-cutover behavior. Polishing that behavior is not commercial launch, M4 classification, or M5 cutover. Separate committed governance authorization and the committed GREEN baseline prerequisite remain mandatory before any production CUI-1 edit.

## 1. Baseline, governance and evidence limits

Repository: `D:\Civilpedia`. HEAD and the local `origin/main` reference both equal `798b2af358735e871463790e746c8f5761fbb989`. Staging is empty. No fetch, remote synchronization, staging, commit or push was performed. Local remote-reference equality is not a new server-side push verification.

Incoming protected state:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/r10_4a/home_dark.png
?? artifacts/r10_4a/home_light.png
```

The only repository artifact created by the original audit was this contract draft, now accepted/frozen by §19. Existing files outside this contract must remain byte-identical to the relevant entry manifest. The original audit evidence directory is `C:\Users\acer\AppData\Local\Temp\civilpedia-cui1-audit-20261004\`.

Controlling sources read:

- `AGENTS.md` and [Agent Operating Model](../CIVILPEDIA_AGENT_OPERATING_MODEL.md).
- [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md), current UI control and final M3 closure/current commercial control. Historical authorizations do not authorize CUI-1.
- [Frozen Commercial Model V1](../CIVILPEDIA_COMMERCIAL_MODEL_V1.md), especially §§28.3–28.4 and the freeze boundary. PAID, VERIFIED and SPONSORED remain distinct. No policy or price changes.
- [R10 UI contract](V1-R10_UI_UX_CORE_APP_EXPERIENCE_CONTRACT.md), including responsive, theme, Arabic, shared primitives and later-slice locks.
- [Accepted M3 contract](CIVILPEDIA_COMMERCIAL_M3_ENTITLEMENT_EVALUATOR_SHADOW_IMPLEMENTATION_CONTRACT_V1.md) and the latest focused M3 independent re-review in the external `civilpedia-m3-rereview-20261004` directory. M3 remains private evaluator/shadow evidence, not Flutter authority.
- [R05 Directory closure](../reports/V1-R05_DIRECTORY_CLOUD_INTEGRATION_CLOSURE.md) and [R06 management closure](../reports/V1-R06_BUSINESS_PROVIDER_PROFILE_MANAGEMENT_CLOSURE.md), checked against current source.

Current Flutter and migration source supplies the audit. SQL files were read as source evidence; no SQL, database, Docker, migration, Supabase or HTTP operation was executed. Historical backend PASS counts are not new CUI-1 evidence. This audit ran only the focused Flutter baseline listed in §14. It did not run the whole repository suite, boot the application for visual inspection, capture screenshots, or certify device/platform behavior.

R10.5-D covers Profile/User Area and R10.5-E covers Business/Staff. Accepted CUI-1 is a separate Commercial UI slice definition limited to Directory presentation; it edits neither family. Its future governance authorization must preserve this boundary and existing UI track controls. The roadmap is not modified by this contract freeze. Neither track's current implementation authorization changes.

## 2. Current UI architecture audit

| Area and current source | Observed architecture | Gap / CUI-1 implication |
| --- | --- | --- |
| `lib/features/directory/presentation/directory_landing_screen.dart` | Nine canonical entity types; taxonomy-only screen with no entity reads/counts; `CivilAppBar`, `CivilSurfaceCard`, shell-safe scrolling | Fixed two-column grid and fixed tile height; responsive polish can preserve taxonomy/order and zero reads |
| `directory_search_screen.dart` in the same directory | Existing refresh controller, cached-first typed states, 280 ms debounce, local query engine, canonical detail navigation; organic cards only | Side-by-side filters on narrow widths; raw region codes and English-first category display; no readable-width cap |
| `lib/features/directory/domain/canonical_directory_entity.dart` | Single public canonical UUID model, typed lifecycle/verification/claim fields and child projections; cloud authoritative, cache stale | This is Directory data, not a paid commercial/publication authority provider |
| `lib/features/directory/data/supabase_directory_read_gateway.dart` | One production PostgREST read projection; entity and joined public children | No new SELECT/RPC needed for the proposed slice. Active-only access is enforced by existing RLS, not a new UI decision |
| `directory_provider_card.dart` | Organic identity/type/region/category summary and Directory verification badge | Light-specific text colors, tight rows and English-first fallbacks need presentation review; no commercial ranking/filter changes |
| `directory_provider_detail_screen.dart` | Resolver validates UUID, treats matching route extra as a hint, resolves cache/cloud, distinguishes fresh/stale/notFound/invalid/unresolved; public detail has local Saved and phone/WhatsApp actions | Generic icon; only first address; no media display; no full locations section; no detail shell-safe bottom padding; light-specific colors; pending seed refresh can show data without an explicit freshness notice |
| `directory_verification_badge.dart` | Five states, text plus icon and semantic label; no ranking or filtering | Fixed small typography/tight row. Keep exact status meaning; no paid verification inference |
| `widgets/directory_sponsored_provider_card.dart` | Resolved placement disclosure wraps a real organic entity card, separate ads icon | Actual tint uses brand colors despite an older warning-tint comment. Presentation seam exists; current search does not compose it |
| `lib/features/directory/application/directory_sponsored_placement_coordinator.dart` | Resolves campaign destination to the real canonical entity; rejects missing disclosure, unsupported destination/reference and read failures | This historical seam is not a current commercial eligibility provider. Do not activate it or alter its resolver |
| `lib/core/di/app_dependencies.dart` | Production campaign source is `EmptyCampaignSource`; canonical cloud Directory repository composed centrally | Keep honest empty advertising source; no demo campaigns, plan-derived ads or alternate backend |
| `lib/features/user_area/presentation/user_area_screen.dart` | Hub routes to Profile, Saved, applications, My businesses and guarded Staff surface; owns no business entities | Preserve frozen hub inventory. Existing My businesses entry is navigation, not proof of ownership |
| `lib/features/profile/presentation/profile_screen.dart` | Auth/profile provider, cloud profile display, separate editing route, guest preferences, conflict handling, settings | User profile role is not business membership or entitlement. Presentation debt belongs to R10.5-D; no CUI-1 profile edits |
| `lib/features/business/presentation/screens/managed_businesses_screen.dart` | Auth-scoped managed list, loading/empty/error/unavailable states; server capabilities gate existing editing | Raw status/type labels and presentation debt are outside this proposal; preserve its accepted read/write and actor-isolation behavior |
| `business_profile_edit_screen.dart` in that screens directory | Existing authorized public-profile mutation workflow, optimistic versioning and public preview | It is an editor, not a safe public owner shell. Public claim status must never navigate directly to this entity's editor |
| `lib/routes/app_routes.dart`, `app_router.dart` | Five shell destinations; Directory/search/detail canonical routes; root `/user`, profile and authenticated business routes | Reuse routes without changing shell, redirects, AuthProvider, return allowlist or route authority |
| Saved store/resolver and `lib/features/saved/presentation/saved_screen.dart` | Local typed Directory references, canonical UUID navigation, unresolved rows retained; Saved uses its own row renderer | Preserve local save semantics and failure behavior; no cloud business action or subscription meaning |

The public model's `lifecycleStatus` accepts `draft`, `active`, `inactive`, `suspended`; it has no `closed` value. Existing source RLS in `00010_rls_authorization_baseline.sql` permits public active entity reads and corresponding child reads. An absent public entity does not disclose a private lifecycle reason. This is static source evidence, not a fresh security/runtime audit.

Categories and regions retain `name_ar` / `name_en`, but their generic parsed names prefer English. Search text currently matches entity name plus generic category name/code; it does not independently search every Arabic name. CUI-1 can localize labels using already-carried fields but must not silently change search predicates, result order or query behavior.

Locations carry region code/bilingual names, address and `isPrimary`. Their public Dart projection lacks location UUID, coordinates and commercial branch identity. The SQL schema has coordinates, but the public read projection does not carry them. Media carries URL and `mediaType`; schema types are `logo`, `cover`, `gallery`. The public projection omits media position, captions, accessibility description, approval/revision and a documented Storage/public-URL contract. Media types exist; safe rich-media ordering and delivery remain dependencies, not invented roles.

## 3. Reusable existing components and seams

Reuse `CivilAppBar`, `CivilSurfaceCard`, `AppSpacing`, `DesignTokens`, `ThemeData.textTheme`, `ColorScheme`, `CanonicalEntityTypePresentation`, `SearchBarWidget`, `EmptyStateWidget`, `RemoteDataNotice`, and `ShellContentInsets` / `shellSafeBottomPadding`. Cairo typography and current true-black dark background/surface tokens are the visual baseline. No global design-system rewrite, new font, package or theme change.

Reuse the organic card, verification badge and existing Sponsored wrapper rather than duplicate entity models. Feature-local helper widgets may remain private in the allowlisted presentation files. Reuse the current refresh/detail controllers, canonical repository, Saved store and injected `DirectoryContactLauncher` without changing their contracts or composition. All query/cache/auth/membership providers remain read-only dependencies of this proposal.

## 4. Missing visual / data dependencies

| Dependency | Current availability | Disposition |
| --- | --- | --- |
| Paid plan, subscription state, benefits, renewal, term prices, usage/quota | Not in public Directory provider; private catalog and M3 evidence are not UI providers | No production field/card or price. Neutral informational shell only |
| Current commercial verification evidence/eligibility and OQ-84 resolution | Existing Directory verification enum only | Preserve labeled Directory status; do not claim commercial gate satisfaction, expiry or endorsement |
| Sponsored production eligibility / finite inventory / delivery | Historical resolver plus empty source; not current commercial provider | Existing wrapper visual QA with explicit test fixtures only; production search remains organic |
| Canonical commercial branches and branch quota/status | Directory locations only | Render Locations, never branch rights/count remaining; defer commercial branches |
| Logo/cover/gallery selection, safe URL/storage and ordering policy | Media type/URL supplied; ordering and delivery contract incomplete | No media loading in CUI-1. Keep type icon as a neutral placeholder, not a fabricated logo |
| Opening hours, map destination/coordinates, reviews, offers, team, certified brands | Not supplied by chosen public projection | Omit; no synthetic labels, ratings, map pin, clock or affiliation |
| Private owner/current-entity capabilities | Existing authenticated membership/RPC family; not public claim status | Generic My businesses navigation only; leave capabilities to existing managed-list flow |
| Closed/terminated commercial lifecycle and publication reasons | No such public lifecycle field/provider | Generic public unavailable state; closed design considered as deferred, not production-renderable |
| Arabic search over separate bilingual fields | Labels available; query semantics narrower | Document limitation; defer engine change to separate scope |
| Draft/governance compatibility with historical static tests | Existing tests pin documentary paths and historical checkpoints | Separate authorized compatibility pass before a future integrated gate; no guard edits now (§17) |

These dependencies do not justify introducing mock authority into the production app. They limit what this first slice can truthfully show.

## 5. Accepted / frozen CUI-1 exact scope

1. Polish the existing Directory landing grid, organic search cards/filters and canonical public detail. Preserve all nine existing entity types; do not reclassify individuals/professionals as paid Businesses. Preserve type order, filters, debounce, result order, refresh ownership and cache semantics.
2. Public profile hierarchy: identity/type, explicitly labeled Directory verification, description, assigned categories, all returned locations, contacts, existing Saved action, and a subdued management/commercial information section. Use “الفئات” for taxonomy rather than implying a detailed service inventory. No invented slogan, performance metric, badge or entity attribute.
3. Show every returned nonempty location using existing order/primary-first parsing, region labels and address. Label the section “المواقع”. “الموقع الرئيسي” requires `isPrimary == true`; never select a primary merely because it is first. Partial rows show available values; a row with no useful visible values is omitted without creating a replacement address. Do not collapse distinct rows by address or manufacture location IDs. No map, branch action, branch quantity or branch quota.
4. Retain current phone and WhatsApp action projection/URI behavior and the injectable launcher. Add a localized presentation failure response for false or thrown launch outcomes without changing launcher infrastructure or inferring a country code. Retain all projected phone actions and existing WhatsApp selection semantics. Display supplied `email`, `website` and `other` contact values as selectable plain text with localized type labels; they gain no new external launch, clipboard button, WebView or scheme handling. Missing/invalid actionable values never create enabled buttons.
5. Keep five Directory verification statuses distinct, with text/icon semantics and wrapping. Detail adds a short explanation that the label is the Directory's recorded verification state and is not a guarantee of quality or a subscription statement. Keep a badge for actual `verified`, never from payment, role, plan or Sponsored appearance. Preserve other status mappings, including verification-suspended versus entity lifecycle-suspended.
6. Polish the existing Sponsored wrapper for clearly separate advertising disclosure/icon/border treatment, using approved theme roles. It must retain the placement's nonempty disclosure text and unmistakable paid-ad labeling. Its CUI-1 screenshots/tests are fixture-driven. Do not import/compose it into production search, change `EmptyCampaignSource`, create campaigns, or claim current commercial eligibility. Verified-only, Sponsored-only and combined fixtures prove independence.
7. Provide a universal “إدارة أعمالي” navigation link in the detail footer to existing `AppRoutes.businessManage`. It refers to the viewer's managed list, not the viewed entity. No entity ID, claim status, owner role assertion, direct editor link or conditional ownership inference. Guests use existing protected-route sign-in/return handling; membership and write capabilities remain in the existing destination.
8. Commercial information shell is a small, noninteractive explanatory block: “الخدمات التجارية” and “لا تعرض هذه الصفحة حالة الاشتراك أو مزايا الخطة.” It shows no plan names, prices, entitlement chips, disabled purchase controls, renewal date, quota, launch promise or fake account state. The management link is separate. Do not advertise a permanently free Business tier or a launch offer.
9. Improve loading/empty/error/unavailable/freshness presentation using existing typed controller outcomes. Show a neutral updating notice while a stale seed/cache awaits authority even when no failure cause exists; retain cause-specific retry on actual failures. Freshness belongs to the Directory read, not commercial entitlement. Authoritative absence must remove cached/seed identity as the controller already requires. No new timers, auto-retry loop, local eligibility calculator or lifecycle rules.
10. Apply Arabic-first copy, theme-safe contrast, directional layout, text scaling, readable widths, owned 48×48 targets and shell-safe final-action visibility. Public detail uses the existing bottom-inset helper; no shell/navigation implementation change.

This is the entire accepted/frozen production slice definition, not permission to implement it. A genuine plan chooser, Business Center, branch manager, media gallery or current-entity management surface requires another contract/provider. The neutral information section is not a placeholder subscription dashboard.

### 5.1. Existing Directory verification versus future Commercial Verification V1

**A — current accepted Directory authority:** CUI-1 may present/polish only the existing supplied Directory `verificationStatus` field/state, retaining its accepted semantics. **B — future Commercial Verification V1 authority:** deferred, not implemented or implied by CUI-1. A presentation improvement to A is never evidence that B exists. No new verification provider or backend field may be added.

The visible verification state comes only from A. Paid plan/tier, ownership, claim, subscription and Sponsored state must never infer it. Verification is not endorsement, Sponsored, paid entitlement or publication authority. Missing/unknown verification must never fall back to positive verification; preserve existing fail-closed parsing/status handling. Cached/stale verification must never be described as newly or currently re-verified. No verification date or commercial validity may be invented from cache, entity timestamps or payment.

### 5.2. Isolated Sponsored presentation boundary

CUI-1 may polish only the existing isolated Sponsored presentation seam. It cannot create Sponsored authority, fabricate production fixtures, enable purchasing, infer Sponsored from plan/tier/verification, expose a new campaign provider, alter search ranking, reorder organic results because of payment or inject Sponsored items into organic ranking. Organic results remain organic. An empty production source must not imply Sponsored availability; retain the current empty source and production search composition.

Sponsored and Verified remain visually and semantically distinct. An unverified Sponsored fixture/item remains visibly unverified. If an accepted existing source supplies an item in a separately authorized future integration, it must be explicitly labeled Sponsored/paid advertising, with localized disclosure and the supplied nonempty placement disclosure retained. This future rule grants no integration, source activation or availability authority to CUI-1; its fixtures remain test-only.

### 5.3. Directory locations / addresses, not commercial Branch entities

All accepted supplied Directory locations may be rendered as locations/addresses only. Do not label them paid Branches, infer branch entitlement/quota or primary commercial branch ownership, enforce Business/Pro/Plus branch limits, or create branch-management UI. A primary-location marker follows only the existing Directory `isPrimary` semantics; it confers no commercial ownership or branch right. Future commercial Branch authority remains deferred.

### 5.4. Neutral commercial information shell

The shell is informational only. Do not duplicate the private commercial catalog into Flutter or hard-code/present purchasable Business/Pro/Plus/Corporate offers, prices, term prices, entitlement benefits, branch/team quotas, Sponsored eligibility or renewal/Grace state. Those fields require a separately accepted public authority/provider in a future slice and are excluded from CUI-1.

No production purchase copy or controls such as Buy, Subscribe, Upgrade, Choose plan or Start paid listing are authorized, including Arabic equivalents. Neutral explanatory/future-facing copy is allowed only when it cannot be mistaken for current purchase availability. The proposed §10 explanation remains noninteractive and is not an account/subscription state.

### 5.5. Generic management entry only

“إدارة أعمالي” is separate from the viewed public entity and routes only to the already-existing `/business/manage` boundary. Existing server-side membership authority decides what the viewer may manage. The public detail screen must never infer management access from claim status, verification, public entity ID, Saved state, Sponsored state or contact data. Do not add routes or providers, pass the viewed entity as management authority, or link to its editor from this generic entry.

### 5.6. Organic discovery invariant

CUI-1 is presentation-only for organic Directory discovery. It cannot modify the search algorithm, ranking, filtering authority, result eligibility, category eligibility, location eligibility or public publication eligibility. Sponsored presentation stays isolated from organic ranking. Localized labels/layout do not alter query identities, predicates, result order or server authority.

### 5.7. Cache / freshness presentation semantics

When the existing controller identifies stale/cache-backed data, preserve the existing stale-data notice and cause-specific behavior. Do not describe verification or business metadata as freshly confirmed. Do not suppress existing data solely because it is stale unless current accepted behavior already does so. Do not invent a commercial freshness timestamp. An updating notice is presentation of existing controller state only; it adds no authority and does not change cache retention, refresh policy or accepted removal on authoritative absence.

## 6. Explicit exclusions and preserved authority

No payments, purchase, upgrade/downgrade, subscription mutations, prices/catalog publication, M4 classification/linking/IQD conversion, M5 cutover, publication mutation or entitlement enforcement. No ownership transfer, invitations, team management, Launch Partner, Founding allocations, Sponsored purchase, commercial admin, staff workflow or new acquisition campaign.

No SQL, migrations, Supabase configuration/RLS/grants/RPCs, backend API, Storage wiring, worker/scheduler, service-role use, persistent publication projection, commercial lifecycle evaluator, M3 kernel/shadow reads, private catalog access or raw `public.plans` exposure. No legacy `planType`, `featured`, `foundingPartner`, claim, profile role or cache flag as authority.

No Profile/User Area/Business editor/Staff redesign, language switch unlock, shell destination changes, navigation rail, global theme change, new design framework, dependency/SDK/cache patch or broad refactor. No generated encyclopedia output changes. No staging/commit/push authorization.

M3 closure and unresolved carry-forward remain unchanged: OQ-84; M4 evidence-backed reconciliation; integer-IQD conversion/rounding; known 00020 lock/authorization integration issue; PRE-M5-PROJECTION-AUTHORITY-GENERATION-RECONCILIATION; future production authority providers/persistent publication projection; M5 cutover. This presentation proposal resolves none.

## 7. Screen and state inventory

| Surface / state | Available evidence | Proposed presentation / authority limit |
| --- | --- | --- |
| Landing populated taxonomy | Fixed canonical nine-type vocabulary | Responsive browse grid, no live density/count assertion |
| Search first load, no cache | Existing controller loading state | Neutral progress; no fabricated cards |
| Search fresh results | Successful current Directory read | Organic cards in existing query order |
| Search authoritative empty | Successful empty response | Honest “لا توجد بيانات متاحة في الدليل حاليًا”; no fake supply or launch-count conclusion |
| Search filtered no match | Existing local query over loaded data | “لا توجد نتائج تطابق البحث”; distinction from empty source |
| Search/detail cached while refreshing | Existing stale + loading | “جاري تحديث بيانات الدليل”; snapshot remains provisional |
| Cached data plus failed refresh | Typed cause and stale entity/data | Existing cause-specific notice/retry; “قد تكون البيانات المعروضة غير محدثة” contextual copy |
| No data + network/timeout/service/unexpected failure | Existing typed no-data state | Existing localized notice/retry; no backend exception text or implied business closure |
| Detail fresh | Canonical successful resolution | Public profile; no paid/publication assertion |
| Invalid UUID | Resolver `invalidId` | Existing invalid-reference state; never accept a local string ID |
| Authoritative detail absence | Resolver `notFound` | “هذه الصفحة غير متاحة في الدليل حاليًا”; no cause, ownership, suspension or closed claim |
| Detail unresolved without authority | Resolver state/cause | Loading or typed error; distinct from proven absence |
| Description/category/location/contact absent | Actual empty/null projection | Section-specific honest absence text; no invented “pending approval” or fake contacts |
| Directory verification five states | Existing enum | Exact localized status with distinct text/icon; `suspended` here describes verification only |
| Entity draft/inactive/suspended | Representable in model/private managed projection, not public active-only read | Considered and deferred as public named states. Existing management states unchanged; public absence stays neutral |
| Commercial closed/terminated | Missing public enum/provider | Deferred; no production or runtime mock state, no 404-to-closed mapping |
| Sponsored none | Current empty source/organic search | No ad slot or label |
| Sponsored-only / verified-only / combined | Explicit widget test placement + canonical entity fixtures | Review wrapper separation only; not evidence of a production campaign |
| Saved unsaved/saved/failure | Existing local Saved store outcome | Local preference action; failure localized; no ownership or paid status |
| Contact absent / unavailable handler / launch exception | Public values + injected launcher outcome | No enabled missing-data action; safe localized failure, no launch success invented |
| Guest management entry | Existing redirect and return allowlist | Sign-in then My businesses; no viewed-entity privilege |
| Member, no memberships, failed membership read, conflict/sign-out | Existing auth-scoped managed flow | Existing destination behavior remains unchanged; no CUI-1 replacement dashboard |
| Plan/commercial shell | Static explanatory copy only | Explicitly non-authoritative; no selected/active/free/expired state |

Named private or missing lifecycle states are design dependencies, not CUI-1 production acceptance requirements. Test fixtures for accepted public rendering must use valid UUIDs and realistic active Directory data. Synthetic negative lifecycle fixtures may prove that the UI does not manufacture paid/lifecycle claims, but must not become a production data source.

## 8. Accepted navigation boundary

Keep `/directory` → `/directory/search` → `/directory/entity/:id`; keep canonical UUID routes and seed-as-hint resolution. Back navigation and deep links remain in the current router. The five shell destinations stay Home, Encyclopedia, Tools, Projects and Directory.

Existing `/user`, `/profile`, `/user/profile`, `/user/profile/edit`, Saved and application routes remain unchanged. New public footer link uses `/business/manage` only. Existing `AuthReturnDestination` explicitly allows that shape; no new return rule is required. `/business/manage/:entityId` is an existing mutation editor and is not the proposed public link. No plan, branch, commercial admin, ownership or new profile route is introduced. Do not hide My businesses behind a preferred user-role field.

## 9. Accepted responsive and visual-system contract

Use available content width in logical dp: Compact <600; Medium 600–839; Expanded ≥840, matching R10. These are existing contract breakpoints, not new global tokens.

| Property | Compact | Medium | Expanded |
| --- | --- | --- | --- |
| Feature gutter | `AppSpacing.lg` = 16 | `AppSpacing.xxl` = 24 | `2 * AppSpacing.lg` = 32 |
| Overall content | Single column | Centered, width ≤1120 | Centered, width ≤1120; no full-width stretched cards |
| Landing | Two columns when labels fit; one at narrow/large-text constraints | Three columns | Four columns |
| Search filters | Stack full-width fields | Wrap into at most two columns | At most three columns within cap |
| Organic result list | One column | One readable column, width ≤760 | One readable column, width ≤760; preserve scan order |
| Detail | Single scroll, full-width sections | Single centered column, width ≤760 | At sufficient inner width: primary text/location column + contact column, with gap24 and contact width280; otherwise one column |
| Actions / badges | Wrap/stack; never truncate meaning | Wrap as required | Wrap as required; no new fixed/sticky panel |

Detail two-column layout requires at least 960 dp inner width, primary column at least 480 dp and a 280 dp contact column; collapse at large text scale if these constraints do not fit. Keep one scroll owner, deterministic reading/focus order and no horizontal scrolling. Description text width ≤760. Card heights grow with content/text scaling; no fixed 140-dp tile constraint that clips labels. Noninteractive badges need readable text, not artificial 48-dp hit areas; all owned interactive controls require at least 48×48 dp.

Apply theme typography and semantic ColorScheme/token roles to owned text, icons, borders, errors and badges. Preserve Cairo, current true-black dark background, surface hierarchy and existing Civilpedia radii. Advertising disclosure uses its own ad icon/wording and boundary; it must not reuse the Verified seal or green success treatment to imply trust. Color alone never carries a state. Theme/brand tokens remain unchanged.

Use `EdgeInsetsDirectional`, `AlignmentDirectional`, locale-driven Directionality and mirrored directional navigation icons. Identity/contact text may be mixed-script; isolate displayed phone/WhatsApp/email/URL tokens in LTR within the RTL layout without transforming persisted values or launch payloads. No conversion to inferred Iraqi country codes. Respect safe areas and use `shellSafeBottomPadding` on every owned shell-hosted final scroll section.

## 10. Arabic-first copy strategy

Arabic is the controlling product copy. Add matching Ar/En static keys following the existing localization architecture; do not unlock a language selector or introduce a localization framework. Preserve existing stable status labels where possible. Both language fixtures must set the actual MaterialApp locale, localization delegates and matching LanguageProvider; provider-only Arabic does not establish RTL or localized Material widgets.

Accepted Arabic-first copy for this frozen slice definition:

| Purpose | Arabic | Meaning / limit |
| --- | --- | --- |
| Categories | الفئات | Taxonomy, not a promised service catalog |
| Locations / primary | المواقع / الموقع الرئيسي | Directory location data, not commercial branch rights |
| No description | لم يُضف وصف | Missing data, not pending approval |
| No locations | لا تتوفر معلومات عن المواقع | No address fabricated |
| No contacts | لا تتوفر معلومات اتصال | No disabled purchase or owner action substituted |
| Verification context | حالة التوثيق المسجّلة في الدليل؛ لا تعني ضمان جودة العمل أو حالة الاشتراك. | Existing Directory record, no commercial verification promise |
| Advertising | إعلان مدفوع | Additional explicit disclosure context; retain supplied placement disclosure |
| Updating | جاري تحديث بيانات الدليل | Existing refresh in flight |
| Snapshot context | قد تكون البيانات المعروضة غير محدثة | No assertion of live entitlement |
| Public unavailable | هذه الصفحة غير متاحة في الدليل حاليًا | No closed/suspended diagnosis |
| Management entry | إدارة أعمالي | Viewer-managed list, not this entity's ownership |
| Commercial shell | الخدمات التجارية / لا تعرض هذه الصفحة حالة الاشتراك أو مزايا الخطة. | Informational only |
| Email / website / other | البريد الإلكتروني / الموقع الإلكتروني / وسيلة اتصال أخرى | Display of supplied data, not validated affiliation |
| Launch failure | تعذر فتح وسيلة الاتصال. | Handler failure, not a false success |

Category display fallback in Arabic: nonempty `nameAr` → `nameEn` → existing generic name → code. Region fallback: nonempty `regionNameAr` → `regionNameEn` → existing regionName → regionCode → localized unspecified. English fixtures reverse bilingual preference. For region filter options, use already-loaded locations to select a label deterministically in existing entity/location order; keep the original code as dropdown value and query identity, falling back to code when no name exists. No query engine, sorting or parser change. Do not silently translate entity names/description/address or change taxonomy/type labels globally.

Avoid “موثوق”, “مضمون”, “الأفضل”, “اشتراك نشط”, “ترقية”, “فرع متاح”, or “إدارة هذا النشاط” without the corresponding authority. No fake benefit countdown, launch date, permanent free commercial listing claim or legal promise. Visual badge copy must distinguish verification suspension from public entity lifecycle.

## 11. Visible-field data-authority mapping

This is the complete proposed visible-field inventory. Any additional visible commercial fact requires an explicit contract addendum and authoritative provider review; absence never means approval.

| Visible field / action | Source / authority | Allowed display and fallback | Forbidden inference |
| --- | --- | --- | --- |
| Canonical identity / detail route | `directory_entities.id` → canonical UUID model | Internal navigation/ref only; no user-facing replacement ID | Phone/name/local profile as identity |
| Name | Public canonical `name` | Supplied plain text; parser rejects missing required name | Fabricated trading name, endorsement or official affiliation |
| Type icon / type label | Public `entityType` + existing canonical presentation vocabulary | Decorative type icon, localized label | All nine types are paid commercial Businesses |
| Description | Public `description` | Plain supplied text or missing-description copy | Certification, commercial quality approval or sanitized claim of truth |
| Category labels | Joined `directory_categories` id/code/nameAr/nameEn | Locale-aware display; original identity/filter/order | Product inventory, launch density, paid category entitlement |
| Region summary / filter label | Joined regions on public locations | Locale-aware name with code fallback; preserve filter code | Area inventory, launch geography eligibility |
| Locations / addresses | Public `locations` | All useful supplied rows; actual address/region | Canonical Branch identity, coordinates or opening hours |
| Primary location marker | Public `isPrimary` | Label only on true | First row proves primary; quota/owner allocation |
| Location quantity | Not proposed as a visible field | No count chip; collection rendered without quota summary | Returned length equals purchased/remaining branch count |
| Phone action | Public contact type/value + existing projection/launcher | Existing tel action and supplied display value | Owner proof, contact verification or payment capability |
| WhatsApp action | Public contact + existing ASCII digit extraction | Existing fixed wa.me action only when extraction nonempty | Country inference, altered number, authoritative delivery |
| Email / website / other contact | Public contact type/value | Selectable plain text, no new launcher | Verified email/domain, dealer status or arbitrary URL execution |
| Saved icon/state | Local `SavedReferenceStore`, canonical typed reference | Local preference outcome/error only | Membership, ownership, subscription or publication approval |
| Directory verification label | Existing accepted Directory `verificationStatus` enum (A in §5.1) | Exact five-state mapping plus context; freshness notice on provisional data; missing/unknown never positive | Paid plan, ownership, claim, subscription, Sponsored, profile role or M3 result confers Verified; stale data is newly re-verified |
| Commercial Verification V1 / validity / expiry | Future authority B in §5.1, not implemented by CUI-1 | Omit | Existing Directory badge implements B, grants paid/publication authority or resolves OQ-84 |
| Sponsored disclosure | Existing resolved `SponsoredPlacement.disclosureLabel` + real canonical entity, when injected into existing wrapper | Fixture-only CUI-1 component review; retain actual label and paid-ad context | Entity/plan/verified flag alone creates ad or eligibility |
| Organic order | Existing canonical query engine | Keep name/id sort and predicates | Paid or verified boost |
| Loading / freshness / error | Existing refresh/detail controller states and typed causes | Honest progress/notice/retry; no backend exception text | Cache/seed becomes new authority; network failure means closed |
| Public unavailable | Authoritative absent result, distinct from failure | Neutral unavailable state | Reason is inactive, suspended, closed or unowned |
| Lifecycle active/private statuses | Existing public Directory source/private managed projection | No added commercial status chip; private screen unchanged | Client publication evaluator, cache-based lifecycle decision |
| My businesses link | Fixed existing route, existing auth guard | Universal navigation to viewer's list | Viewed entity is owned/claimed by viewer |
| Managed role/capability | Existing authenticated `business_memberships` / managed RPC/provider, outside public detail | Existing destination alone handles it | `claimStatus`, preferred profile role, name/email or MEMBER means OWNER |
| Commercial info heading/body | Localized static explanatory text | Explicitly not an account state | Active/free/expired subscription or plan selection |
| Plan/price/term/renewal/benefits/quota/team | No accepted client commercial authority provider | Omit all fields | Private catalog, raw plans, M1b reference rows or shadow result supplies authority |
| Media/logo/cover/gallery | Public URL/mediaType exists, but not used in CUI-1 | Generic type icon; no media fetch or synthetic logo | First media row is approved/ordered brand asset |
| Closed/terminated, publication gate/reason, paid publishability | Missing chosen production provider | Omit named states and reasons | Legacy lifecycle/claim, absence or M3 synthetic ALLOW proves them |
| Reviews/ratings/offers/open hours/team/brand certification/metrics | Not in proposed projection | Omit | Decorative mock fact becomes real business claim |
| Created/updated timestamps | Public timestamps, but not proposed for visible display | No “verified on”/freshness date | Entity updatedAt is verification date, entitlement revision or cache fetch time |

Public row visibility remains server-controlled by the existing accepted Directory authority. CUI-1 neither tightens nor widens it into paid-only commercial publication. Unknown/malformed required rows retain existing fail-closed repository handling; no presentation constructor fallback manufactures a production entity.

## 12. Real-data / mock boundary

Production uses the existing canonical repository and current accepted route/controller composition only. No seed listings, fixture files, demo business account, runtime mock flag, local commercial catalog, network-error demo fallback, or positive placeholder state. Empty database stays empty. Route extra remains a provisional hint resolved by canonical UUID and removed on authoritative absence.

Permitted production placeholders: existing neutral type icon, honest missing-description/location/contact copy and the explicit static commercial information block. They contain no fabricated business fact and do not resemble an active plan/status control.

Test-only canonical entities and placements are allowed through existing injection seams. Use valid UUIDs, separate verified/sponsored scenarios and real typed states. Screenshot fixtures must be prominently identified in the evidence manifest as “بيانات تجريبية للتصميم — غير مرجعية”; do not add such fixtures to the production repository composition. Deferred closed/subscription/branch/team states may be documented as future designs, but not shipped as toggles or production UI branches.

## 13. Frozen future implementation file allowlists

These exact lists are frozen as the accepted future implementation boundaries, not current permission. Every path outside them is read-only unless separately authorized. Contract acceptance/freeze is complete, but implementation remains unauthorized and requires separate explicit committed governance authorization and §14.1's committed GREEN prerequisite. Existing protected dirty files remain excluded even if test failures appear elsewhere. Acceptance/freeze alone authorizes neither the harness corrections nor production implementation.

The separately authorized and committed GREEN baseline prerequisite in §14.1 must be satisfied before ANY production file below may be edited. Contract acceptance/freeze and the proposed file list do not bypass that gate.

Exactly eight frozen production files:

```text
lib/features/directory/presentation/directory_landing_screen.dart
lib/features/directory/presentation/directory_search_screen.dart
lib/features/directory/presentation/directory_provider_card.dart
lib/features/directory/presentation/directory_provider_detail_screen.dart
lib/features/directory/presentation/directory_verification_badge.dart
lib/features/directory/presentation/widgets/directory_sponsored_provider_card.dart
lib/localization/ar.dart
lib/localization/en.dart
```

Private layout/localization helpers remain inside these files. No new production file is required. Localization edits are new narrowly named keys/references for this slice, not global rewrites of shared existing copy.

**STOP rules:** If implementation requires a ninth production file, STOP production work pending separate Architect review/authorization. If a provider/domain/repository change becomes necessary, STOP — that is a new authority/data slice, not CUI-1. No provider, route, DI, theme, backend, SQL, migration or roadmap implementation file may be added to this allowlist. Do not silently broaden it or treat these exclusions as routine implementation choices.

Frozen bounded CUI-1 implementation test additions/edits, after separate authorization and the committed GREEN prerequisite, limited to this slice's assertions:

```text
test/commercial_cui1_business_experience_foundation_widget_test.dart (new)
test/w5_2_directory_landing_test.dart
test/w5_3_directory_search_screen_test.dart
test/w5_4_directory_provider_card_test.dart
test/w5_4_directory_provider_detail_screen_test.dart
test/w5_5_verification_display_test.dart
```

Frozen separate bounded pre-implementation harness-correction boundary — exactly these two test files, requiring its own authorization:

```text
test/w7_2_directory_sponsored_search_screen_test.dart
test/v1_r09_p2_b_directory_ux_test.dart
```

The separate harness pass may repair exactly the known three baseline defects: the canonical-UUID Sponsored navigation fixture and the two Saved locale/harness expectation mismatches (§14). Preserve production behavior and assertion intent; no Saved production change, widened test scope or weakened assertion. If any failure differs from those known three, STOP and re-review. These two files become read-only regressions during subsequent production CUI-1 implementation; their corrections cannot be postponed into it. No test repair is authorized or performed by this documentary pass.

Read-only regression dependencies include canonical models/query/gateway/cache/controllers, membership/editor/auth providers, Saved store/screen/resolver, routes/return resolver, shared widgets/theme/DI, all Supabase files and all commercial static guards. No pubspec/lockfile/tooling change. Visual evidence may be written outside the repository under an explicitly identified temporary directory.

## 14. Test strategy and current focused baseline

Current audit command, `--no-pub`, expanded reporter:

```text
flutter test --no-pub test/w5_2_directory_landing_test.dart test/w5_3_directory_search_screen_test.dart test/w5_4_directory_provider_card_test.dart test/w5_4_directory_provider_detail_screen_test.dart test/w5_5_verification_display_test.dart test/w5_6_directory_provider_detail_save_test.dart test/w5_6_saved_screen_directory_test.dart test/w6_2_directory_route_test.dart test/w7_2_directory_sponsored_placement_coordinator_test.dart test/w7_2_directory_sponsored_search_screen_test.dart test/v1_r05_directory_cloud_integration_test.dart test/v1_r09_p2_b_directory_ux_test.dart --reporter expanded
```

Observed result: **341 PASS / 3 FAIL, exit 1**. Logs: external `focused-ui-baseline.log`. The two failing files rerun sequentially with `--concurrency=1`: **47 PASS / the same 3 FAIL, exit 1**, logged in `baseline-failure-isolation.log`. Counts are actual baseline results, not CUI-1 implementation results.

| Baseline failure | Source explanation and limit | Required future handling |
| --- | --- | --- |
| `w7_2_directory_sponsored_search_screen_test.dart:155`, G sponsored tap | Fixture `p-1` is not a UUID; current canonical detail resolver rejects it. Shared fake factory passes the ID unchanged | Correct canonical fixture narrowly; never relax production UUID validation |
| `v1_r09_p2_b_directory_ux_test.dart:670`, Saved local-first | Harness MaterialApp has no explicit Arabic locale/delegates; Saved reads Localizations locale, while expectations use Ar and only LanguageProvider defaults Arabic | Align harness locale/delegates/provider, then reconfirm pending-refresh publication intent |
| Same file `:713`, failed-refresh Saved retention | Same locale discrepancy explains missing Arabic text; no saved-reference deletion failure was reported | Reconfirm retained reference and safe unavailable row after locale repair; do not rewrite Saved logic |

These source explanations are strong but no fixture was edited or corrective run performed during this audit. Baseline is not green and must not be reported as green. Remaining test cases passed; neither this result nor old R05/R06 closure counts establishes device visual quality.

### 14.1. Mandatory GREEN baseline gate before production edits

The recorded **341 PASS / 3 FAIL**, independently isolated as **47 PASS / the same 3 FAIL**, is NOT an accepted implementation-time red baseline. Before ANY production Flutter file in §13 may be edited, a separately authorized bounded compatibility/harness correction must repair exactly these known defects, preserve production behavior, avoid scope expansion, rerun the complete twelve-file focused baseline command above to GREEN, and be committed by the authorized Git owner before production CUI-1 implementation begins. The isolated two-file rerun alone is not the GREEN gate. If any observed failure differs from the known three, STOP and re-review before attempting a repair.

Required preflight evidence is the separate correction authorization/exact allowlist, GREEN focused-baseline log and exit status, proof of zero production behavior/file changes in that correction, and its committed correction SHA. Any necessary historical documentary/static compatibility remains a separate bounded authorization under §17, not permission to change production code or security/runtime oracles. A later CUI-1 implementation must begin from the resulting committed governance/correction baseline, with the GREEN prerequisite reconfirmed before its first production edit. A red baseline cannot be waived, carried into implementation, or repaired concurrently with production work. This contract correction performs no test repair, compatibility patch, test rerun or Git mutation.

Proposed implementation verification:

- New widget matrix: mandatory §15 viewport/locale/theme/text-scale grid, including 390/600/839/840/1280 logical px at reference DPR 1.0 and scales 1.0/1.3; retain additional stress checks at 320/599/1024/1440 dp and scale 2.0. Assert no overflow, readable content, 48×48 actions, wrapped long identity/status labels, shell obstruction clearance and focus traversal order.
- Real typed states: pending seed refresh, stale-with-cause, fresh, authoritative empty, no match, invalid UUID, proven absence, unresolved error/retry, absent partial fields and repeated locations. No invented lifecycle reasons or status.
- Authority-negative cases: claimed entity + unrelated guest/user never produces current-entity editor; role/plan/legacy featured flags never create paid/verified/Sponsored state; cache hint never becomes ownership; absent commercial provider produces no plan/price/quota/purchase fields; empty campaign source remains organic-only.
- Verification matrix: all five status mappings, Directory context, no green paid-ad seal; separate Verified-only/Sponsored-only/both/neither fixture layouts and retained nonempty disclosure.
- Contacts: exact existing phone/WhatsApp extraction and payload, malformed/no-actionable input, handler false/exception, disposed-screen completion and no raw URI/exception leaks; email/website/other plain text cannot launch arbitrary schemes.
- Navigation/Saved: canonical UUID round trip, wrong/missing seed, authoritative removal, same local typed Saved reference and failure behavior, My businesses auth return, no extra shell destination or direct public edit route.
- Targeted analysis of changed presentation/localization/test files; rerun the twelve baseline files plus new CUI-1 tests. Add existing `app_routes_test.dart`, `user_area_route_test.dart`, `v1_r08_router_auth_test.dart`, `saved_reference_resolver_test.dart` and relevant membership tests as focused read-only regressions where the management link requires them. Do not run protected dirty tests as an acceptance substitute.
- Check exact allowlist, hashes of protected baseline, staged list, HEAD/origin, `git diff --check`, absence of SQL/config/DI/provider changes and fixture isolation. Gate is zero unresolved CUI-1 HIGH/MEDIUM findings and no new focused regression; baseline failures require resolved evidence, not a silent waiver.

No repository-wide integrated suite is authorized here. Backend gates need not run to prove a presentation-only diff; any later integrated gate requires explicit authority and documentary compatibility first. Do not run SQL or regenerate commercial evidence in this audit.

## 15. Visual QA strategy

Before future implementation, Architect reviews this scope, information hierarchy and authority copy. Then the implementer captures feature-only rendered screenshots with an external fixture/evidence manifest; reviewer inspects actual PNGs, not only widget assertions. Do not claim visual QA from source inspection.

### 15.1. Mandatory rendering grid

Use a reference render environment with device pixel ratio **1.0**, so the requested viewport pixel widths below also equal Flutter logical dp; production breakpoint logic remains in logical dp. Record DPR for additional device captures rather than confusing screenshot raster width with layout width.

| Band / boundary | Required viewport width (px at reference DPR 1.0) | Locale / direction | Theme | Text scale |
| --- | --- | --- | --- | --- |
| Compact | 390 | Arabic RTL and English LTR | Light and dark | 1.0 and 1.3 |
| Medium lower boundary | 600 | Arabic RTL and English LTR | Light and dark | 1.0 and 1.3 |
| Medium upper boundary | 839 | Arabic RTL and English LTR | Light and dark | 1.0 and 1.3 |
| Expanded lower boundary | 840 | Arabic RTL and English LTR | Light and dark | 1.0 and 1.3 |
| Expanded desktop | 1280 | Arabic RTL and English LTR | Light and dark | 1.0 and 1.3 |

Capture all **5 widths × 2 locales/directions × 2 themes × 2 scales = 40** representative public-detail renderings. Use one clearly test-only valid-UUID stress fixture with a long business name, long description, multiple categories, multiple supplied locations and missing contacts. Scroll and capture the final owned CTA section as needed to prove no clipped Saved/management affordance; an off-screen scrollable CTA is not evidence of clipping. The fixture must carry no invented commercial field.

Also render landing and organic search at each of the five widths in Arabic RTL, both themes, scale 1.3; add English LTR at 390 and 1280, both themes, scale 1.3. Search fixtures preserve existing organic order and eligibility. Production-composition empty-campaign evidence must remain organic-only; an isolated Sponsored wrapper fixture is not a production search screenshot.

### 15.2. Required state evidence and pass criteria

| State / fixture | Required additional render evidence | Acceptance assertion |
| --- | --- | --- |
| Stale/cache-backed data | 390 and 840; Arabic RTL; light/dark; scale 1.3 | Existing stale notice retained; no fresh verification/business confirmation, invented timestamp or stale-only suppression |
| Five Directory verification states | Each of unverified/pending/verified/rejected/suspended at 390 and 840; Arabic RTL; light/dark; scale 1.3 | Distinct readable text/icon, existing field only, no endorsement/paid/publication meaning |
| Sponsored / Verified independence | Neither, Verified-only, Sponsored-only with unverified entity, and both at 390 and 840; Arabic RTL; light/dark; scale 1.3; repeat four combinations at 1280, English LTR, light/dark, scale 1.3 | Explicit Sponsored disclosure; unverified stays visible; no shared trust seal, organic ranking injection or production fixtures |
| Missing/partial data and contact failures | 390 and 840; Arabic RTL; light/dark; scale 1.3 | Honest description/location/contact absence; no clipped failure message or enabled missing-data action |
| Loading, empty, no-match, error and authoritative unavailable | Representative 390 and 840; Arabic RTL; light/dark; scale 1.3 | Correct typed state and reachable retry/back action; no invented commercial lifecycle reason |

Pass criteria for every required render: **no overflow; no clipped CTA; no horizontal scrolling for normal screen content; minimum interactive target 48×48 dp**. Include long mixed Arabic/Latin text and directionally isolated contact tokens. Verify all supplied locations remain readable and the final section clears shell/device insets. Preserve current true-black dark theme; no global theme edit.

Execution: configure the explicit locale/delegates/provider, viewport/DPR, theme, scale and fixture; settle only the intended controller state (keep stale refresh pending where required); capture initial and scrolled final-action frames; inspect actual renders and log pass/fail per matrix key. Actual screenshots/render evidence are required during implementation review, **not during this documentary correction**. Existing additional widget stress checks at 320/599/1024/1440 dp and scale 2.0 remain supplementary rather than replacing the mandatory grid.

Inspect typography/contrast, first/last action reachability under floating navigation and device insets, keyboard-visible content, pointer hover/focus, tab order and semantic announcements, back navigation, no horizontal overflow, no fixed-height clipping, distinct ads/verification, no phantom branches/plans/owner claims. Use available Android/tablet/desktop targets for screenshots; browser/device-specific handler behavior requires a documented manual check. Platforms not exercised remain explicit limitations.

Future evidence manifest records viewport in logical dp, device pixel ratio, locale/direction, theme, scale, state, fixture IDs, screenshot paths and observed issues. Contrast and accessibility checks use actual rendered colors/text, not semantic-token naming alone. Accessibility/manual review cannot be replaced by goldens. No screenshot baseline regeneration to conceal unresolved findings.

## 16. Risks and acceptance questions

| Risk | Mitigation / Architect decision required |
| --- | --- |
| “Commercial Business” title implies launch or paid publication already exists | Explicitly accept a Directory foundation only; no launch/catalog/provider claim |
| R10.5-D/E overlap | Separate bounded authorization and sequence; no profile/hub/business-editor edits or implicit unlock |
| Cached verification looks current | Display refresh/failure provenance with snapshot; do not read it as commercial approval |
| Private lifecycle leaks via guessed public error reason | Neutral unavailable state; no inferred inactive/suspended/closed reason |
| Locations mistaken for purchased branches | Locations wording, no IDs/count/quota/map rights invented |
| Informational shell becomes subscription dashboard | Fixed neutral copy only; no tiers/buttons/prices or fake account state |
| Sponsored fixtures imply real ad service | No production composition/source change; evidence marked synthetic and eligibility deferred |
| New location/contact text and large scales overflow | Adaptive layout, isolated LTR tokens, no fixed heights, actual visual review |
| Current launcher exception escapes / delayed completion | Narrow detail presentation handling with mounted checks; preserve launcher and URI contracts |
| Label localization implies Arabic search was fixed | Preserve and document query-engine limitation; separate future search authorization |
| Media gives false impression of delivery readiness | Acknowledge existing roles but defer rendering pending URL/storage/order/approval contract |
| Three reproducible baseline failures block the start of production work | Separately authorized bounded correction; full focused baseline GREEN and correction committed before any production edit (§14.1) |
| Historical static guards reject new documentation/future UI diff | Govern exact checkpoint compatibility separately; preserve security/runtime oracles (§17) |

Architect acceptance freezes the exact public scope, generic management link, neutral commercial block, deferred branches/media/lifecycle/paid providers, responsive layout and test-harness disposition. No risk/dependency is resolved merely by freeze. Contract acceptance alone does not authorize execution; changes to the frozen definition require separate explicit Architect review and authorization.

## 17. Recommended sequencing and documentary compatibility

1. Owner-provided Architect acceptance is recorded in §19: this contract is ACCEPTED / FROZEN for the CUI-1 slice definition only, IMPLEMENTATION_AUTHORIZED NO. This is not implementation acceptance or completion. No code changes now.
2. CUI-1 is a separately accepted Commercial UI contract; accepting/freezing it does not authorize implementation. Obtain separate explicit, committed governance authorization before production work, with §14.1's prerequisite completed first. M3 remains CLOSED; M4/M5 remain NOT AUTHORIZED; R10.5-D remains AUDIT-ONLY / IMPLEMENTATION NO. No roadmap change is performed in this pass.
3. If needed, authorize a separate documentary/static compatibility pass for the new CUI-1 record. Current `commercial_m1b_catalog_reference_data_migration_test.dart` expects exactly three approved lib/docs diff paths from its historical baseline and no untracked lib/docs files; this new untracked draft therefore conflicts mechanically with that guard. HARDEN-1 and M3 also retain exact historical roadmap/checkpoint controls. This is a known documentary scope dependency, not a changed backend result. No commercial static gate was rerun or modified here.
4. Such a compatibility pass may inspect the roadmap and the three exact files `test/commercial_harden1_public_plans_exposure_migration_test.dart`, `test/commercial_m1b_catalog_reference_data_migration_test.dart`, `test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart`; any edit requires its own exact Architect-authorized allowlist. Preserve original history and independently fixed expected bytes/checkpoints; do not generate expectations from current files, weaken paths to broad prefixes, remove mutation detection or loosen SQL/security/runtime assertions. This proposal itself authorizes no compatibility edit.
5. Before any production edit, complete the separately authorized bounded compatibility/harness correction: exactly the three known test defects, production behavior unchanged, full focused baseline GREEN and correction committed by the Git owner. STOP/re-review on a different failure. Only after this hard gate and separate committed CUI-1 authorization may implementation preflight reconfirm source/baseline, preserve protected dirty files and begin typography/freshness/detail/contact hierarchy, locations and generic management/info section, cards/search/grid responsiveness, then isolated Sponsored wrapper presentation.
6. Run focused gates and executable §15 visual QA; correct only owned causes within the accepted allowlist. STOP for a ninth production file; STOP for provider/domain/repository work as a new authority/data slice. Routes, DI, theme and backend remain outside CUI-1; no automatic scope-expansion addendum or implementation retry.
7. Independent focused review of UI and authority boundaries, followed by Architect implementation acceptance. User retains staging/commit/push ownership. No M4/M5 unlock or commercial launch follows automatically.

## 18. Contract path and historical audit completion record

Canonical accepted contract path:

```text
docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md
```

The audit covers architecture, reusable components, dependencies, screens/states, exact scope/exclusions, navigation, responsive behavior, Arabic copy, complete visible-field authority mapping, real/mock boundary, allowlist, tests, visual QA, risks and sequencing. This document is the retained audit artifact and now the accepted/frozen CUI-1 implementation contract. The audit and correction records below are historical; current acceptance/freeze status is governed by the header and §19. Implementation remains unauthorized.

Verified final exact `git status --short --untracked-files=all` after adding only this draft:

```text
 M test/a5_6_profile_bootstrap_test.dart
 M test/v1_r08_cloud_profile_foundation_test.dart
 M test/v1_r08_profile_edit_screen_widget_test.dart
?? OpenCode_Usage_Report.txt
?? artifacts/r10_4a/home_dark.png
?? artifacts/r10_4a/home_light.png
?? docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md
```

Final preservation comparison confirmed unchanged HEAD/local origin and empty staging, all 1,199 entry file hashes unchanged with none missing, and exactly one new nonignored file (this draft). `git diff --check` exited 0 on tracked changes; the untracked draft separately has zero trailing-whitespace lines. Existing dirty tests produced Git's existing LF/CRLF advisory only. The external `preservation-final.json` supplies the actual comparison. Recheck these invariants after any later draft revision.

No Flutter implementation, repository test edits, SQL execution, migration, Supabase/database change, roadmap/authorization change, M4/M5 work, staging, commit or push was performed. Focused tests are read-only audit evidence; temporary runner build/cache outputs are not implementation. No implementation is self-authorized by this report.

### 18.1. Architect documentary correction record — 2026-10-05

Historical pre-acceptance correction record retained below. Its then-current DRAFT / NOT FROZEN status is superseded only by the explicit §19 acceptance/freeze record; its constraints and evidence remain intact.

Authority: Owner-provided Architect documentary correction request, direction B — ready after narrow documentary corrections. This is not contract acceptance or freeze. The pass changes only this draft's clauses: §§5.1–5.7 authority/presentation boundaries, §11 verification mapping, §13 separately bounded test/production allowlists and STOP rules, §14.1 committed GREEN prerequisite and matching test strategy, §15 executable visual matrix, §16 baseline risk and §17 sequencing/track separation. The eight-file production allowlist is unchanged. No new architecture, commercial decision or OQ closure is introduced.

Correction evidence resides outside the repository in `C:\Users\acer\AppData\Local\Temp\civilpedia-cui1-documentary-correction-20261005\`, including the before-copy and a 1,200-file entry manifest. Final verification must show only this draft changed, all other 1,199 entry files intact, no new/missing nonignored file, unchanged HEAD/local origin, empty staging, `git diff --check` PASS and a separate untracked-draft whitespace PASS. Repository status remains the exact seven-entry list above because this draft remains untracked.

No Flutter implementation, test repair/rerun, SQL/Supabase/migration work, roadmap authorization/change, staging, commit or push is performed in the documentary correction. Historical baseline evidence remains red; §14.1 records a prerequisite, not a claimed repair. M3 remains CLOSED; M4/M5 NOT AUTHORIZED; R10.5-D AUDIT-ONLY / IMPLEMENTATION NO. CUI-1 remains a separate Commercial UI proposal, DRAFT / NOT FROZEN / IMPLEMENTATION_AUTHORIZED NO. Later acceptance/freeze still requires separate committed governance authorization and the committed GREEN prerequisite before production edits. No self-acceptance is recorded.

## 19. Architect acceptance and contract freeze — 2026-10-05

Authority: Owner-provided Architect acceptance and contract-freeze instruction. Architect decision: **A — CUI-1 CONTRACT READY FOR ARCHITECT ACCEPTANCE**. Acceptance is recorded as **ACCEPTED — 2026-10-05**; freeze applies to the canonical **CUI-1 — Commercial Business Experience Foundation** slice definition only. This records the provided Architect decision, not agent self-acceptance or implementation completion.

The accepted/frozen scope is exactly §5: responsive Directory/public Business identity/detail presentation, supplied locations/addresses, existing contacts, local Saved, existing Directory verification presentation, isolated Sponsored seam, generic “إدارة أعمالي” entry, neutral commercial information shell and Arabic-first responsive presentation. No production behavior is changed by freezing this definition.

Authority separations remain normative:

- Existing Directory Verification ≠ future Commercial Verification V1.
- Sponsored ≠ Verified; Paid ≠ Verified ≠ Sponsored.
- Directory Location ≠ Commercial Branch.
- Saved ≠ Ownership.
- Claim ≠ Management authority; public entity ID ≠ Management authority.
- Commercial information shell ≠ Subscription catalog authority.

All §6 exclusions and §§5.1–5.7 corrections remain frozen and unchanged. Payments, subscription/plan purchase, upgrade/downgrade, entitlement decisions, commercial lifecycle/verification authority, Sponsored purchase/eligibility authority, branch/team quotas, transfers/invitations, Launch Partner/Founding allocation, M4/M5, backend/SQL/migration/provider/domain/repository changes, Profile/User Area/Business editor redesign and Directory ranking/search authority changes remain outside CUI-1. No OQ is closed, price/plan modified, commercial policy created/reinterpreted, route/provider added or backend authority granted.

The §14.1 hard gate remains normative: the historical 341 PASS / 3 FAIL and isolated 47 PASS / 3 FAIL are not an accepted red implementation baseline. Before ANY CUI-1 production edit, separately authorize the bounded harness correction for exactly invalid Sponsored fixture `p-1` and the two Saved Arabic locale/harness expectation mismatches; preserve production behavior, return the COMPLETE focused baseline to GREEN and commit the correction first. Any different failure requires STOP AND RE-REVIEW. This acceptance/freeze does not authorize those corrections by itself and makes no claim that the baseline is repaired.

The exact eight production paths and separated six CUI-1 test paths / two harness-correction test paths in §13 remain unchanged. A ninth production file requires STOP. Any provider/domain/repository change requires STOP and a separate authority/data slice. The executable §15 matrix remains unchanged: widths 390/600/839/840/1280, Arabic RTL/English LTR, light/dark, scales 1.0/1.3, stress/state fixtures and independent Sponsored/Verified combinations; no overflow/clipped CTA/normal-content horizontal scrolling and ≥48×48 interactive targets. Screenshots/render evidence are implementation-review obligations, not freeze evidence.

Track state remains M3 CLOSED; M4 NOT AUTHORIZED; M5 NOT AUTHORIZED; R10.5-D AUDIT-ONLY / IMPLEMENTATION NO. CUI-1 is now an ACCEPTED/FROZEN CONTRACT with IMPLEMENTATION NOT AUTHORIZED. Separate committed governance authorization remains mandatory before production implementation, in addition to the committed GREEN prerequisite. Roadmap unchanged; no authorization, implementation or completion is implied by contract freeze.

This finalization changes only this contract's status/freeze wording and explicit acceptance record. PUBLIC_BACKEND_AUTHORITY_DELTA ZERO; COMMERCIAL_AUTHORITY_DELTA ZERO. External before-copy/preservation evidence resides in `C:\Users\acer\AppData\Local\Temp\civilpedia-cui1-contract-freeze-20261005\`. No Flutter implementation, test repair/rerun, SQL/migration/Supabase work, roadmap edit, staging, commit or push is performed. User retains Git ownership; readiness to commit this contract is not permission for the agent to do so.
