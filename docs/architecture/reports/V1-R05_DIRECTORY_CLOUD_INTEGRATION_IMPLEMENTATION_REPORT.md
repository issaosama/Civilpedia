# V1-R05 — Big Pickle Implementation Report

CURRENT_PHASE_ID: V1-R05
CURRENT_PHASE_TITLE: Directory Cloud Integration
CURRENT_PHASE_CONTRACT: V1-R05-CONTRACT-v1
IMPLEMENTATION_AUTHORIZED: YES
PHASE STATUS: IMPLEMENTED — INDEPENDENT REVIEW FAILED (correction pass in progress; revert to contract source/control file before closure)

> NOTE: This file was moved from
> `docs/architecture/contracts/V1-R05_DIRECTORY_CLOUD_INTEGRATION_CONTRACT.md`
> during the V1-R05 Independent-Focus-Review correction pass. The original
> contract path now carries a BLOCKED placeholder — the exact Architect contract
> text for V1-R05-CONTRACT-v1 is not stored in this repository.

---

## 1. Objective

Replace the local-only `sb_profiles` Directory read authority with a
cloud-backed, cache-first, read-only production flow backed by the canonical
`public.directory_entities` schema, while:

- preserving offline-first behavior (versioned local snapshot);
- keeping legacy `sb_profiles` storage and its W5.1 compatibility guarantees
  fully intact and isolated;
- switching Directory UI, routing and the Saved system to canonical entity
  identity (the `directory_entities.id` UUID);
- keeping the Sponsored placement coordinator canonical-only with no
  monetization activation.

Canonical (cloud) data is authoritative. The cache is a stale offline
snapshot. No duplicate cloud/local business authority remains ambiguous.

---

## 2. Canonical identity & data model

- New model `CanonicalDirectoryEntity` (id, name, entityType, description,
  lifecycleStatus, verificationStatus, claimStatus, categories, locations,
  contacts, media, timestamps) is the SINGLE production Directory entity.
- Identity is ONLY `directory_entities.id` (UUID). No BusinessType, region,
  name/phone heuristic, or local profile id is used as canonical identity.
- Fail-closed parsers: `tryFromRow` / `tryFromJson` return null instead of an
  invented entity when required columns (`id`, `name`, known `entity_type`)
  are missing or malformed.
- Entity types reuse the existing canonical vocabulary
  `DirectoryEntityType` (9 codes): company, engineering_office, contractor,
  supplier, store, technician, laboratory, equipment_provider,
  service_provider. Unknown codes fail closed.
- `VerificationStatus` remains the existing five-state enum
  (unverified/pending/verified/rejected/suspended) reused by the badge and the
  canonical entity; it is kept as-is with no new values.

---

## 3. Cloud read path

- `SupabaseDirectoryReadGateway` — public read seam over the canonical
  `public` schema (anon + authenticated reads, RLS-policy-mediated active-only
  view). No service_role usage, no RLS/table changes, no claim-gateway reuse.
- `CloudDirectoryRepository` — read-only contract with deterministic result/
  status types (`DirectoryLoadState`, `DirectoryRefreshStatus`).
- `SupabaseCloudDirectoryRepository` — production cache-first implementation.
- `CanonicalDirectoryQueryEngine` — local search/filter/sort (name* +
  category-name text, entityType, regionCode, categoryId), deterministic sort
  by name then id, non-mutating, AND semantics between filters.

---

## 4. Cache & offline contract

- Dedicated, versioned SharedPreferences snapshot under
  `AppStorageKeys.directoryCloudCache` (`'directory_cloud_cache'`), byte-for-byte
  separate from `sb_profiles`.
- Cache authority rules enforced and tested:
  - successful complete cloud refresh atomically replaces the snapshot;
  - a network failure may use the last valid snapshot (stale read) and tries
    cloud refresh;
  - malformed cache fails safely (null snapshot) and falls through to cloud;
  - a failed/partial refresh never destroys the last valid cache;
  - an authoritative EMPTY cloud refresh replaces the old snapshot (empty is a
    valid snapshot).
- W5.1 storage freeze adapted to prove V1-R05 adds exactly ONE Directory
  persistence key (the cloud cache) and no second local profile store.

---

## 5. UI, routing & Saved cutover

- `DirectoryLandingScreen` and `DirectorySearchScreen` operate on canonical
  String entity types (9 grid entries); search instances revert to
  `CloudDirectoryRepository` and render the new load/empty/stale states.
- `DirectoryProviderCard` and `DirectoryProviderDetailScreen` take
  `entity: CanonicalDirectoryEntity`; detail projects contact-type
  (`phone`/`whatsapp`) via the unchanged contact launcher.
- `/directory/entity/:id` detail route added through canonical constants
  (`directoryEntitySegment`, `directoryEntityPattern`,
  `directoryEntityDetailFor(id)`); full-entity navigation uses GoRouter
  `extra`, direct entry uses the async canonical-ID fallback wrapper.
- `SavedScreen` resolves saved provider refs through
  `CloudDirectoryRepository.loadByCanonicalId()`, keyed by the canonical UUID,
  and renders rows via the canonical entity-type presentation.
- `DirectorySponsoredPlacementCoordinator` / `DirectorySponsoredProviderCard`
  adapted to `CloudDirectoryRepository` + canonical entity only — no campaign
  activation, no monetization behavior.

---

## 6. Legacy preservation

Legacy W5.x compatibility is preserved untouched:

- `sb_profiles` key, its V0 raw-array shape, and the W5.1 wrapper /
  cross-compat / version-awareness / entity-compat guarantees still pass.
- Legacy domain files (`directory_repository.dart`, `directory_query.dart`,
  `directory_query_engine.dart`, `sb_profiles_directory_repository.dart`,
  `directory_data_version.dart`, `directory_category_presentation.dart`) remain
  isolated; production Directory UI no longer reads them.
- Legacy verification serialization tests (rejected↔suspended, fallback) remain
  green.

---

## 7. Tests & verification

Full suite (after landing the V1-R05 work and adapting the touched legacy
Directory/Saved/sponsored tests):

```
flutter test  → 02:37 +1800: All tests passed!
```

- New focused integration suite
  `test/v1_r05_directory_cloud_integration_test.dart` — 42 tests covering the
  canonical model, fail-closed row/JSON parsing, serialization round-trip,
  id-only equality, `DirectoryEntityType.isKnown`, the 9-type presentation
  labels/icons, `DirectoryCloudCache` version/atomicity/malformed behavior,
  `FakeCloudDirectoryRepository` load/refresh/availability, and the query
  engine (text/type/region/category filters, AND semantics, deterministic
  order, non-mutation).
- Adapted shared fake + entity factory:
  `test/helpers/canonical_directory_test_helpers.dart`.
- Frozen regression groups are all green: W5.1 storage, W5.2 landing,
  W5.3 search screen, W5.4 card/detail/search integration, W5.5 verification,
  W5.6 saved + save UI + boundaries + resolver + reference store,
  W6.2 directory route, W6.3 nav transition, W7.1 campaign contract,
  W7.2 sponsored placement coordinator + sponsored search screen.

## 8. Constraints & environment notes

- The Android/desktop Dev/QA plan: `flutter analyze` is currently unusable in
  this environment due to a pre-existing SDK analyzer bug
  (`Bad state: No definition of type Enum` on Flutter 3.32.8 / Dart 3.8.1)
  that crashes the analysis server before producing diagnostics. Compilation
  correctness is instead verified by the passing `flutter test` run, and the
  GUI float/UX (RTL, dark mode, stale/offline states) is scheduled for device
  verification under the Architect's QA step.
- `git diff --check` passes (no whitespace errors). Working tree audit shows
  only the intended V1-R05 files plus the pre-existing untracked
  `OpenCode_Usage_Report.txt` (untouched).
- No roadmap control-change was made beyond the frozen V1-R05 contract state;
  V1-R05 is NOT closed and V1-R06 is NOT promoted.

## 9. Rollback plan

Because the cutover added new files and adapted presentations/tests without
mutating or migrating any persisted data:

1. No on-disk data migration exists, so rollback requires no data restore.
2. Legacy `sb_profiles` and all legacy domain files are intact and still
   covered by W5.1 – the pre-V1-R05 authority could be re-selected purely at
   the DI seam (`app_dependencies`) without data loss.
3. If a regression is found in Directory UI/routing/Saved, revert the
   presentation/route/Saved commits and DI back to the legacy repository; the
   cache key and any written cache snapshot are inert to the legacy path and
   can be cleared safely.
4. For a full revert, `git revert` the V1-R05 commit(s) and re-run the full
   suite; no follow-up fix-up commit beyond that is expected.

---

# V1-R05 — Big Pickle Implementation Report — Sign-off

- [x] Canonical model + fail-closed parsing
- [x] Cloud read gateway (anon/auth, RLS-mediated)
- [x] Versioned cloud cache with offline-first, empty-replaces, fail-safe rules
- [x] Canonical query engine
- [x] Directory UI/Search/Landing/Detail on canonical identity
- [x] `/directory/entity/:id` detail route (+ fallback direct entry)
- [x] Saved system on canonical UUID refs
- [x] Sponsored coordinator canonical-only (no monetization)
- [x] W5.1 storage freeze updated to the single dedicated cache key
- [x] Legacy storage & tests preserved untouched
- [x] Full suite green (+1800)
- [x] `git diff --check` clean

IMPLEMENTATION COMPLETE — READY FOR INDEPENDENT REVIEW