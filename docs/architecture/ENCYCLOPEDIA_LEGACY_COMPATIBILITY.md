# Encyclopedia Legacy Content Compatibility Contract

## 1. Purpose

This document defines the backward-compatibility contract for Civilpedia's
Encyclopedia feature. It exists to protect historical content and to prevent
accidental removal of legacy support during future refactoring or content
normalization work.

Legacy topic fields are still part of the active schema/export/parser/presentation
pipeline. They must not be deleted simply because new content no longer uses
them.

## 2. Current canonical content model

The canonical content model for new topics is:

```
Draft JSON
    topic        (metadata only)
    sections[]   (ordered sections)
      blocks[]   (typed content blocks)
    review
    _meta
```

Content is authored as Draft JSON in Content Studio, exported by the exporter,
compiled into app-ready catalogs, and rendered in Flutter from sections and
blocks.

## 3. Legacy field inventory

The following topic-level fields are considered legacy body fields:

| Field | Type | Current UI usage |
|---|---|---|
| `simpleExplanation` | `LocalizedText` | Hero summary (precedence over `summary`) |
| `beforeWork` | `LocalizedText` | Legacy "Application" section |
| `duringWork` | `LocalizedText` | Legacy "Application" section |
| `afterWork` | `LocalizedText` | Legacy "Application" section |
| `siteNotes` | `LocalizedText` | Legacy "Importance" section |
| `codeNotes` | `LocalizedText` | Legacy "Importance" section |
| `reportWording` | `LocalizedText` | Legacy "Report Wording" section |
| `commonMistakes` | `List<LocalizedText>` | Legacy "Common Mistakes" section |
| `acceptRejectItems` | `List<AcceptRejectItem>` | Legacy "Inspection" section |
| `featuredImageUrl` | `String?` | **Unused** by TopicDetail; superseded by `coverImageUrl` |

All fields are declared in `EngineeringTopic`, parsed by
`encyclopedia_json_datasource.dart`, emitted by both exporters, and rendered as
fallback sections in `TopicDetailScreen`.

## 4. Current fallback behavior

`TopicDetailScreen` renders modern block sections first, in `order`.

After the modern sections, if any legacy metadata is non-empty, the screen
renders the following legacy sections in this order:

1. **Importance** (`siteNotes` + `codeNotes`)
2. **Application / طريقة التنفيذ** (`beforeWork`, `duringWork`, `afterWork`)
3. **Inspection** (`acceptRejectItems`)
4. **Common Mistakes** (`commonMistakes`)
5. **Report Wording** (`reportWording`)

Each legacy section is guarded by its own emptiness check. Empty fields do not
produce empty sections.

## 5. simpleExplanation precedence

The hero summary uses this exact precedence:

1. `topic.simpleExplanation.ar` if `simpleExplanation` is non-null.
2. `topic.summary` if `simpleExplanation` is null.

Future normalization must preserve this precedence until a compatibility
breaker is intentionally scheduled.

## 6. Historical compatibility requirements

Civilpedia must continue to open and render historical Draft JSONs and
historical app-ready catalogs that contain legacy fields.

Removing a legacy field from the entity, parser, exporter, or presentation
layer without a migration path is a breaking change. Any such change must be
approved as part of an explicit normalization phase and must include:

- A migration strategy for historical Drafts.
- Alignment between Content Studio Preview and Flutter.
- Regression tests covering the affected legacy behavior.

## 7. Generated-files rule

Generated files are outputs, not sources:

- `assets/encyclopedia/catalog.generated.json`
- `assets/encyclopedia/catalog.json` (fallback)
- Any future `app_ready_jsons/**` output

They must never be hand-edited as a migration strategy. Any content conversion
must operate through one of the following:

- Draft-level compatibility or normalization.
- Content Studio export transformation.
- A standalone exporter script transformation.
- Runtime compatibility parsing in Flutter.

## 8. Preview ↔ Flutter parity rule

Future normalization must keep Content Studio Preview and Flutter rendering
consistent. A Flutter-only migration that diverges from Preview is not
acceptable.

Until normalization is implemented, Preview continues to render legacy
`simpleExplanation` in the hero and legacy `siteNotes`, `codeNotes`,
`commonMistakes`, and `acceptRejectItems` as trailing sections. Flutter mirrors
that behavior through `TopicDetailScreen`.

## 9. What modern content MUST use

All new content MUST use:

- `sections[]` with typed `blocks[]`.
- Canonical topic metadata fields (`id`, `titleAr`, `summaryAr`, `categoryId`,
  `level`, `planKey`, `status`, `keyTopics`, `coverImageUrl`, `visual_theme`).
- Modern block types: `text`, `execution_step`, `safety_note`, `table`,
  `checklist`, `inspection_point`, `code_reference`, `equipment`, `image`,
  `common_mistakes`, `acceptance_criteria`, `rejection_criteria`.

New Content Studio features must NOT introduce new dependencies on legacy
topic fields.

## 10. What must NOT be deleted

The following must remain intact until a normalization phase explicitly removes
them:

- Legacy fields in `EngineeringTopic`.
- Legacy parsing in `EngineeringTopic.fromJson`.
- Legacy fallback section builders in `TopicDetailScreen`.
- Legacy mappings in `tools/content_studio/js/exporter.js`.
- Legacy mappings in `tools/content_studio/scripts/export_draft.dart`.
- Legacy field detection in `tools/content_studio/js/validation.js`.
- The `LEGACY_BODY_FIELDS` list in `tools/content_studio/js/schema.js`.

## 11. Future normalization direction

The intended future architecture is:

```
Legacy input (Draft / App-ready JSON)
        |
        v
Compatibility Normalizer
        |
        v
Canonical Topic Projection  (sections + blocks only)
        |
        v
Presentation  (Preview + Flutter)
```

The normalizer would convert legacy topic fields into canonical sections and
blocks at export or load time. Once normalization is complete, the Flutter UI
can stop branching on legacy fields and render purely from the canonical
projection.

This must be done consistently across Content Studio Preview, both exporters,
and Flutter parsing. A Flutter-only migration is not acceptable.

## 12. Conditions required before any legacy caller migration

Before removing any legacy caller, the following conditions must be met:

1. A compatibility normalizer exists and is tested.
2. All historical Draft JSONs can be losslessly normalized or are explicitly
   declared obsolete.
3. Content Studio Preview and Flutter rendering are aligned after normalization.
4. Regression tests in `test/encyclopedia_legacy_compatibility_test.dart` are
   updated or replaced with normalized-equivalent tests.
5. Content team has verified the converted output.
6. `@Deprecated` annotations are added to legacy entity fields and the team has
   agreed on a removal timeline.

## 13. Test coverage protecting compatibility

The following behavior is protected by
`test/encyclopedia_legacy_compatibility_test.dart`:

| Behavior | Test |
|---|---|
| `simpleExplanation` precedence over `summary` | `simpleExplanation takes precedence over summary when populated` |
| `summary` fallback when `simpleExplanation` is null | `summary is used as fallback when simpleExplanation is null` |
| `beforeWork/duringWork/afterWork` rendering and order | `legacy before/during/after work renders in the existing order` |
| `siteNotes`/`codeNotes` Importance section | `legacy siteNotes and codeNotes render the importance section` |
| `reportWording` rendering | `legacy report wording remains renderable` |
| `commonMistakes` rendering | `legacy common mistakes remain renderable` |
| `acceptRejectItems` rendering | `legacy accept/reject items remain renderable` |
| Modern-only topic renders without legacy sections | `modern sections and blocks render without legacy fallback sections` |
| Mixed legacy + modern content renders both | `mixed legacy and modern content renders both without deduplication` |
| `featuredImageUrl` entity preservation | `featuredImageUrl is preserved by entity serialization (unused by UI)` |

## 14. Known duplication risk

A topic may contain both modern blocks and legacy fields that express the same
semantic content. Current rendering does not deduplicate. Both the modern block
and the legacy fallback section will appear.

Example:

- A modern `common_mistakes` block AND a legacy `commonMistakes` list will both
  render as "Common Mistakes" content.
- A modern general `text` block AND a legacy `simpleExplanation` will both
  appear in the article.

This is a documented product risk, not a bug to fix in D3C1. Future
normalization must address it.

## 15. featuredImageUrl status

`featuredImageUrl` is a legacy field that is currently unused by
`TopicDetailScreen`. The canonical cover image field is `coverImageUrl`.

`featuredImageUrl` is preserved in the entity and serializers for historical
compatibility. No new code should use it, and no regression test is required
for UI rendering. If a future normalization phase decides to remove it, the
entity preservation test must be updated or removed.

## 16. Change log

| Date | Phase | Change |
|---|---|---|
| 2026-08-25 | D3C1 | Created compatibility contract and regression tests. |
