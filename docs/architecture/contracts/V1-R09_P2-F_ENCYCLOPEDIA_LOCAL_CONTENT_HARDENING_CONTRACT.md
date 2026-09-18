# CIVILPEDIA V1-R09 PART 2 — P2-F ENCYCLOPEDIA LOCAL-CONTENT ERROR HARDENING CONTRACT

PHASE: V1-R09 Part 2
SLICE: P2-F — Encyclopedia Local-Content Error Hardening
CONTRACT: V1-R09-P2-F-CONTRACT-v1
STATUS: FROZEN
ARCHITECT DECISION: FROZEN (per completed P2-F architecture inspection report)
IMPLEMENTATION_AUTHORIZED: NO — authorized only after Architect checkpoint

## 1. Authority and Purpose

This contract persists the accepted, Architect-ratified P2-F architecture
inspection proposal for Encyclopedia local-content error hardening. It is the
authoritative implementation boundary for V1-R09 Part 2 slice P2-F.

It layers on V1-R09-CONTRACT-v1 and on the closed P2-A / P2-B / P2-C / P2-D /
P2-E slices. Everything in the parent and prior-slice contracts that is not
changed here remains in force. P2-F is a LOCAL-CONTENT hardening slice; it does
not alter remote-data, connectivity, authentication, identity, ownership, or
account-bound guarantees.

This freeze persists semantics ONLY. No production code, test, content, or
generated output is modified by this freeze.

## 2. Non-Goals

P2-F is local-content error hardening. It is NOT:

- remote-data hardening;
- search redesign;
- Content Studio rewrite;
- exporter rewrite;
- generic offline architecture;
- granular block-sync engine;
- R10 redesign;
- content-authoring cleanup.

SCOPE MAY BE LIMITED. QUALITY MAY NOT BE LIMITED.

## 3. Authoritative Runtime Content Source

Production runtime Encyclopedia authority is ONLY:

    assets/encyclopedia/catalog.generated.json

No production fallback to:

    assets/encyclopedia/catalog.json

(the legacy 3-topic catalog) or to:

    EncyclopediaLocalDataSource mock content.

The legacy catalog may remain physically present for
historical/compatibility purposes but MUST NOT become production runtime
authority or silent fallback. EncyclopediaLocalDataSource may remain as
explicit dev/test infrastructure but MUST NOT silently feed production UI.

No content substitution may masquerade as success.

## 4. SSOT

Preserve:

    draft_jsons/*.draft.json
    = authoring SSOT (authoritative source)

Derived:

    app_ready_jsons/topics/*.topic.json
    app_ready_jsons/catalog.generated.json
    assets/encyclopedia/catalog.generated.json
    = packaged derived copy

Generated/derived production content must never be manually edited as the
implementation fix. If generated output is wrong, fix the SSOT/export path.

## 5. Local Failure Taxonomy

Freeze the minimal typed local-content failure taxonomy:

    EncyclopediaContentFailureKind {
      assetUnavailable,
      malformedContent,
      unexpected
    }

Exact class/exception wrapper naming may follow current Dart conventions, but
the three semantic variants above are frozen.

No `offline`, `network`, `timeout`, or `serviceUnavailable` in the Encyclopedia
local-content taxonomy.

Normal non-failure states remain separate and are NOT failures:

- authoritative empty;
- searchNoResults;
- topicNotFound.

## 6. Asset Unavailable

`assetUnavailable` means the authoritative generated packaged asset cannot be
read/opened/loaded. Examples: asset missing; asset bundle cannot load the asset;
equivalent local packaged-resource unavailability.

It MUST NOT trigger:

- legacy catalog fallback;
- mock fallback;
- ConnectivityProvider;
- network/offline presentation;
- reconnect behavior.

## 7. Malformed Content

`malformedContent` includes:

- invalid JSON;
- invalid root/top-level shape;
- required metadata absent/invalid;
- unsupported schema version;
- wrong generated-catalog format;
- malformed required topic;
- malformed required section;
- malformed required block;
- unsupported block type;
- invalid required block payload;
- parse skip in authoritative generated content;
- canonical metadata/count inconsistency.

No partial authoritative publication.

Any CatalogParseSkip from the production generated catalog makes the entire
catalog load `malformedContent`. Do NOT silently drop malformed
rows/sections/blocks. Do NOT expose raw parser text to users.

## 8. Meta Gate

The authoritative generated catalog MUST require:

    _meta.format == "civilpedia-catalog-generated"
    _meta.schemaVersion == 1

Declared topicCount / sectionCount / blockCount must match the successfully
accepted authoritative catalog contents.

`generatedAt` / `source` metadata remain diagnostic/advisory and are not
authority gates.

Missing/wrong mandatory metadata => `malformedContent`.

## 9. Block Semantics

Use the actual currently supported typed block set from repository truth
(`lib/features/encyclopedia/presentation/widgets/content_block_widget.dart`
exhaustive switch over 12 types: text, execution_step, inspection_point,
safety_note, code_reference, checklist, table, equipment, image,
common_mistakes, acceptance_criteria, rejection_criteria). Do NOT add new block
types.

Unknown block type => `malformedContent`.

Malformed required payload for a supported block => `malformedContent`.

No silent block skip.

Existing runtime image loading failure handled by the existing
`ImageUnavailableFallback` / `image_block_widget.dart` remains a PRESENTATION
media failure and does NOT make the entire catalog malformed merely because an
image asset failed to render.

## 10. Empty / Search / Not Found

Freeze:

- valid catalog with zero topics => authoritative empty;
- valid category with zero matching topics => authoritative empty;
- search with zero results => searchNoResults;
- valid route/topic ID not present in authoritative catalog => topicNotFound.

These are controlled product states, not local-content failures. No fabricated
article/topic.

## 11. Strict Complete Authoritative Load

The production generated catalog is fail-closed for
structural/content integrity. Do NOT publish a partial topic set, partial
section set, or partial block set when required authoritative content parsing
reports a malformed row/block.

Runtime defensive parsing may collect diagnostic skip information internally,
but any production skip prevents authoritative catalog success.

## 12. Known-Good Preservation / Identity

Freeze identity-safe known-good behavior.

FULL CATALOG: if a known-good authoritative catalog is already loaded and a
same-authority reload fails locally: preserve known-good catalog; record/show
local content read failure non-destructively; do NOT replace it with
legacy/mock data.

DETAIL — same Topic ID: known-good detail + reload failure => same-topic
known-good may remain visible with controlled local failure state.

DETAIL — different Topic ID: Topic A active -> request Topic B -> B fails.
MUST NOT present Topic A as Topic B. The provider must track sufficient
requested/current identity to enforce this. No cross-topic stale masquerading.

## 13. Retry / Recovery

Manual retry is allowed only for actual local load failure.

Retry means re-attempting the SAME authoritative generated asset/read lane.

Retry MUST NOT: use legacy catalog; use mock catalog; use network; invoke
ConnectivityProvider; auto-loop; poll; run from timers; auto-trigger on
reconnect.

Malformed content may remain unrecoverable until app/package update; retry UI
must not promise recovery.

Normal states (empty, searchNoResults, topicNotFound) do NOT become generic
retryable errors.

## 14. Error Presentation

No raw `e.toString()`, FormatException text, JSON/parser diagnostics,
asset-loader exception text, stack traces, or filesystem/internal asset paths
may reach normal user-facing UI.

Use localized controlled copy. No technical wording such as "JSON malformed"
for normal users.

Development logging may retain diagnostic cause according to project logging
conventions.

## 15. Presentation Primitives

RemoteDataNotice is NOT appropriate for this local-content path.

Do NOT use RemoteDataNotice, ConnectivityProvider, ReconnectGenerationGate, or
TransportStatusBanner for P2-F local failures.

Reuse existing ErrorStateWidget, EmptyStateWidget, and AsyncValueWidget where
semantically correct.

A minimal Encyclopedia-local notice/widget may be added ONLY if needed for
known-good content + local reload failure. Do NOT create a second design
system.

## 16. Localization

Add only genuinely missing symmetric AR/EN keys for P2-F local-content errors.

Requirements: Arabic RTL; English LTR; no hard-coded Arabic-only P2-F error
copy; no hard-coded English-only P2-F error copy.

Existing unrelated Encyclopedia localization debt is OUT OF SCOPE. Specifically
defer unless implementation proves unavoidable: canonical search matcher
cleanup; general search hint redesign; copy/share/report snackbar cleanup;
unrelated historical Arabic-hardcoded strings.

## 17. Search Matcher

The existing keyTopics-vs-tags divergence between Encyclopedia local search and
global search is acknowledged but OUT OF SCOPE for P2-F. Do NOT change search
matching semantics in this phase. P2-F hardens failure behavior only.

## 18. Exporter / Tooling Scope

Do NOT perform exporter/tooling overhaul in P2-F. Do NOT modify
`build_catalog.dart` or `compare_catalogs.dart` merely to implement runtime
hardening. Exporter payload/reference-validation improvements are deferred to
the Encyclopedia/Content Studio finalization work (V1-R13) unless a separate
Architect decision promotes them earlier.

P2-F MUST, however, add deterministic regression evidence that:

    app_ready_jsons/catalog.generated.json

and

    assets/encyclopedia/catalog.generated.json

are synchronized/equivalent for the committed production content.

Also verify the packaged production generated catalog passes required `_meta`
validation, contains zero parse skips, and is authoritative-load valid.

Do NOT manually patch either generated file to satisfy the test.

## 19. No Section-Granular Retry

Do NOT introduce per-section/per-block retry architecture. P2-F uses
authoritative catalog/detail integrity semantics. No new partial section state
machine. No speculative granular recovery model.

## 20. Routing

Preserve current routing architecture:

    /encyclopedia/topics/:categoryId
    /encyclopedia/topic/:topicId

Existing valid-but-absent topic ID => topicNotFound. Missing route patterns
handled by GoRouter remain routing responsibility. No new route authority. No
fabricated fallback topic.

## 21. Image Failure

Preserve existing controlled ImageUnavailableFallback behavior. A runtime image
render/load failure does not automatically invalidate the catalog if the block
itself parsed correctly. Do not redesign media loading.

## 22. Backend / Connectivity Freeze

No backend change. Do NOT modify Supabase, migrations, RLS, grants, RPC, Edge,
Realtime, or service_role. Migration 00022 remains absent. No
ConnectivityProvider, ReconnectGenerationGate, TransportStatusBanner, or
RemoteOperationPolicy timeout required for local bundled Encyclopedia content.

## 23. Implementation Partition

Freeze P2-F as ONE implementation slice.

- Implementation: Big Pickle
- Independent reviewer: GitHub Copilot Civilpedia Reviewer
- Escalate to GPT-5.6 Sol High only for a genuine architecture/lifecycle
  conflict.

Do NOT create F1/F2 by habit. Implementation is authorized only after the
Architect checkpoint (see STATUS above).

## 24. File Boundary

Persisted exact file boundary from repository truth. Only the files actually
required may be touched in implementation.

FOUNDATION MODIFY:
- `lib/features/encyclopedia/data/datasources/encyclopedia_json_datasource.dart`
  - meta gate enforcement (format/schemaVersion/counts);
  - typed local-content failure classification (assetUnavailable /
    malformedContent / unexpected);
  - any production CatalogParseSkip => malformedContent (no silent skip);
  - production lane loads `assets/encyclopedia/catalog.generated.json` only;
    no generated->legacy fallback in the production authority path.
- `lib/features/encyclopedia/data/repositories/encyclopedia_repository_impl.dart`
  - remove legacy/mock runtime fallback from the production authority path;
  - propagate typed local-content failures (no `catch (_)` success
    masquerade).
- `lib/features/encyclopedia/presentation/providers/encyclopedia_provider.dart`
  - typed local-content failure state (no raw `e.toString()` to UI);
  - known-good preservation (full catalog and same-topic detail);
  - requested/current identity enforcement (no cross-topic stale
    masquerading);
  - manual retry that reattempts the authoritative generated lane only.

PRESENTATION MODIFY (affected Encyclopedia list/category/detail surfaces only
where needed for controlled local errors / known-good preservation):
- `lib/features/encyclopedia/presentation/screens/encyclopedia_screen.dart`
- `lib/features/encyclopedia/presentation/screens/categories_screen.dart`
- `lib/features/encyclopedia/presentation/screens/topic_list_screen.dart`
- `lib/features/encyclopedia/presentation/screens/topic_detail_screen.dart`
- conditional only where required:
  `lib/features/home/presentation/widgets/engineering_topics_section.dart`
  `lib/features/home/presentation/widgets/categories_section.dart`
  `lib/features/saved/presentation/saved_screen.dart`

PRESENTATION ADD (at most one thin Encyclopedia-local content notice; only if
needed for known-good content + local reload failure):
- `lib/features/encyclopedia/presentation/widgets/` (exact name decided at
  implementation; must reuse existing ErrorStateWidget/EmptyStateWidget/
  AsyncValueWidget primitives and the existing design system)

LOCALIZATION MODIFY (only for genuinely missing P2-F strings):
- `lib/localization/ar.dart`
- `lib/localization/en.dart`

TEST MODIFY (existing regression suites where old legacy/mock runtime fallback
behavior intentionally changes):
- `test/encyclopedia_catalog_parser_test.dart`

TEST ADD (focused P2-F hardening/widget/sync tests as needed):
- `test/v1_r09_p2_f_encyclopedia_local_content_hardening_test.dart`
  (candidate single-file name; may be split only with justification)

Do NOT include: unrelated search architecture; content authoring edits;
generated production content edits; backend; P2-G; R10 design work.

## 25. Required Test Matrix

Freeze deterministic evidence for:

AUTHORITATIVE SOURCE:
- production loads generated catalog only;
- no legacy runtime fallback;
- no mock runtime fallback.

ASSET FAILURE:
- generated asset unavailable => assetUnavailable => controlled localized UI =>
  no mock/legacy content.

MALFORMED (each => malformedContent => zero partial authoritative
publication):
- invalid JSON;
- invalid top-level shape;
- missing/wrong `_meta.format`;
- unsupported schemaVersion;
- metadata count mismatch;
- malformed topic;
- malformed section;
- malformed block;
- unknown block type;
- invalid required block payload;
- any parser skip.

NORMAL STATES:
- valid empty catalog remains empty, not failure;
- empty category remains empty;
- search no results remains normal;
- nonexistent topic remains topicNotFound.

RAW ERROR SAFETY:
- raw exception text not rendered;
- no parser/JSON/backend-like diagnostic text in normal UI.

KNOWN-GOOD:
- same-authority catalog reload failure preserves known-good;
- same-topic reload failure may preserve same-topic known-good;
- Topic A -> Topic B failure never renders A as B.

RETRY:
- manual retry reattempts generated source only;
- no legacy/mock fallback;
- no auto retry;
- no connectivity-triggered retry.

IMAGE:
- existing image failure fallback remains controlled.

LOCALIZATION:
- P2-F error copy works AR and EN;
- RTL/LTR;
- no hard-coded counterpart-language leak.

SYNC GATE:
- `app_ready_jsons/catalog.generated.json` equals
  `assets/encyclopedia/catalog.generated.json`;
- packaged catalog passes production strict validation with zero skips.

HISTORICAL:
- relevant existing Encyclopedia parser/detail/list/favorites/search-route/block
  regression suites remain green except tests intentionally updated for removal
  of legacy/mock runtime fallback.

## 26. Implementation & Verification Protocol

- Per the operating model, run focused tests during implementation/review.
- A repository-wide suite runs only at an explicitly authorized integrated
  gate.
- No blind automatic mutation retry; no Flutter SDK/cache/global package source
  patching.
- Root-cause fixes only; no broad refactors unless authorized.
- Do not stage, commit, or push unless the user explicitly authorizes it; never
  use `git add .` / `git add -A`.

## 27. Git Safety

After any P2-F implementation run (and after this docs-only freeze run):

    git diff --check
    git status --short
    git diff --name-only
    git diff --cached --name-only
    git rev-parse HEAD
    git rev-parse origin/main

Expected invariants:

- HEAD == origin/main == a495b0ae0f14277a774c626037931e3402a1f672 until a
  separately authorized implementation commit;
- nothing staged, committed, or pushed unless explicitly authorized;
- baseline dirty paths untouched:
  `test/a5_6_profile_bootstrap_test.dart`,
  `test/v1_r08_cloud_profile_foundation_test.dart`,
  `test/v1_r08_profile_edit_screen_widget_test.dart`,
  `OpenCode_Usage_Report.txt`.

## 28. Closure Criteria

P2-F may not be marked implemented or closed by this freeze. P2-F can only be
reported as ready after: typed taxonomy implemented; meta gate enforced; zero
production skip tolerance; known-good/identity safety proven; localized
presentation proven AR/EN RTL/LTR; deterministic sync/regression evidence
green; independent Copilot Reviewer acceptance recorded.

## Appendix A — Inspection Evidence (accepted)

- Runtime authority asset:
  `assets/encyclopedia/catalog.generated.json` (13 topics / 117 sections /
  539 blocks / 6 categories; `_meta` format `civilpedia-catalog-generated`,
  schemaVersion 1).
- Currently byte-identical to
  `app_ready_jsons/catalog.generated.json` (SHA256
  A676D9BEC655E381428B9C28FF3070C9F9EC4D3AB22B1C2C778315E9DEF7F026, verified).
- Legacy `assets/encyclopedia/catalog.json` = 3 topics (dev/compat only).
- `EncyclopediaJsonDataSource._ensureLoaded` currently tries generated then
  legacy, then rethrows; `parseCatalogJson` records `CatalogParseSkip` for
  malformed rows and only debug-logs them.
- `EncyclopediaRepositoryImpl` currently falls back to
  `EncyclopediaLocalDataSource` (mock, 7 topics) on ANY datasource exception
  (`test/encyclopedia_catalog_parser_test.dart` "catastrophic fallback
  preserved" documents current behavior to be intentionally changed).
- `EncyclopediaProvider` currently records `error = e.toString()` and, on
  detail-load error, retains prior `currentTopic`/`currentSections`/
  `blocksBySection` (identity risk addressed by §12).
- Parser/regression test `test/encyclopedia_catalog_parser_test.dart`
  currently asserts committed production catalogs parse with zero skips
  (13/117/539/6) — evidence the current assets satisfy strict load.
- No ConnectivityProvider / network / Supabase dependency exists in the
  Encyclopedia feature.

## Appendix B — Roadmap Live State (as updated by this freeze)

    V1-R09:  CURRENT
    P2-A:    CLOSED
    P2-B:    CLOSED
    P2-C:    CLOSED
    P2-D:    CLOSED
    P2-E:    CLOSED
    P2-F:    CURRENT — CONTRACT FROZEN (implementation NOT started)
    P2-G:    LOCKED
    R09Q:    QUEUED
    R10:     QUEUED

P2-F is NOT marked implemented by this freeze.