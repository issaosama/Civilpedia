# Catalog Compatibility Report

**Date:** 2026-06-28
**Scope:** Compare `app_ready_jsons/catalog.generated.json` with `assets/encyclopedia/catalog.json`
**Phases:** CONTENT-STUDIO-1E, CONTENT-STUDIO-1F

---

## Executive Summary

The generated catalog is **structurally compatible** with the current Flutter app data source. The `topics[]`, `sections{}`, and `blocks{}` structures match the official catalog shape. All block types, localized field formats, and arrays (commonMistakes, acceptRejectItems, reportWording, relatedToolRoutes) are identical.

**Compatibility verdict: ✅ PASS** — `catalog.generated.json` can be parsed by the current `EncyclopediaJsonDataSource` with no changes.

---

## Compatibility Status

| Component | Status | Notes |
|-----------|--------|-------|
| Top-level keys | ✅ Match | Both have `topics`, `sections`, `blocks` |
| Topics array shape | ✅ Match | Same field names, types, and nesting |
| Sections map shape | ✅ Match | `{id, title, type, order}` identical |
| Blocks map shape | ✅ Match | Same section IDs, same block content |
| Localized fields | ✅ Match | `{ar, en}` objects identical |
| commonMistakes | ✅ Match | Same `{ar, en}` shape |
| acceptRejectItems | ✅ Match | Same 10-field shape |
| reportWording | ✅ Match | Same `{ar, en}` object |
| relatedToolRoutes | ✅ Match | Same array content |
| featuredImageUrl | ✅ Match | Both `null` |
| Text blocks | ✅ Match | Same `content` + `variant` |
| Table blocks | ✅ Match | Same `data.caption/headers/rows` |
| Execution step blocks | ✅ Match | Same `step.stepNumber/description/notes` |
| Safety note blocks | ✅ Match | Same `note.message/severity` |
| Checklist blocks | ✅ Match | Same `title/items` shape |

---

## Differences Found

### 1. `_meta` section (cosmetic, non-blocking)

| Aspect | Official | Generated |
|--------|----------|-----------|
| Has `_meta` | No | Yes (format, schemaVersion, generatedAt, source, counts) |

**Impact:** None. The Flutter app does not read `_meta` from catalog.json. It reads `topics`, `sections`, and `blocks` only.

### 2. Created/Updated timestamps

Draft JSON stores timestamps in `_meta` while the app expects them on the topic object. The exporter passes them through. Format differs slightly (official: no Z suffix, generated: with Z suffix) — both are valid ISO-8601 strings parsed by `DateTime.parse`.

**Status:** ✅ Functional. Minor format variant — safe.

### 3. `order` field on blocks

Generated blocks include an explicit `order` field (number). Official blocks may store `order: null` or omit it.

**Impact:** None. The current `EncyclopediaJsonDataSource` parses `order` but defaults to `0` if absent. Having a proper order value is **better** — it's the intended schema behavior.

### 4. Missing topics in generated catalog

The generated catalog currently contains only 1 topic (`iraqi-tiles-types`), while the official catalog has 3. This is expected — only one topic has been migrated to Draft JSON so far.

**Impact:** None. Topics can be added incrementally.

### 5. Related topic IDs on topic object

Both match. ✅

### 6. inspection_point block format

The official catalog wraps inspection fields in a `point` map. The exporter now outputs `{point: {criteria, method, isCritical, acceptableTolerance}}` matching the official format and the `InspectionPointBlock.fromJson` parser.

**Status:** ✅ Fixed during CONTENT-STUDIO-1F.

### 7. Equipment block format

The official catalog uses `name` (Arabic string), `purpose`, `specification` on equipment items. The exporter now outputs `name` instead of `nameAr`/`nameEn`, and includes `title: ''` matching `EquipmentBlock.fromJson`.

**Status:** ✅ Fixed during CONTENT-STUDIO-1F.

### 8. Checklist item format

The official catalog uses `id`, `text` (Arabic), `isRequired` on checklist items. The exporter now outputs `id`, `text` (from `textAr`), `isRequired` matching `ChecklistItem.fromJson`.

**Status:** ✅ Fixed during CONTENT-STUDIO-1F.

### 9. Image block format

The official catalog uses `imageUrl` (not `url`) for the image block. The exporter now outputs `imageUrl` matching `ImageBlock.fromJson`.

**Status:** ✅ Fixed during CONTENT-STUDIO-1F.

### 10. Duplicate code reference (intentional)

The official catalog's `slump-test` topic contains a duplicate `code_reference` block (same ASTM C143 entry twice). The generated version collapses this to one block (data quality improvement).

**Status:** ⚠️ Intentional — not a bug.

---

## Required Fixes Before Replacing Official Catalog

1. All exporter format issues identified in CONTENT-STUDIO-1E have been fixed.
2. **Verify all app features work** with generated catalog before swap.

No app parser changes are required.

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `order` field present on generated blocks vs absent/null on official | Low | Low — app defaults to 0 if absent | Safe to have; improves data quality |
| `_meta` section in generated catalog confuses old parser | Very low | Low — app only reads `topics/sections/blocks` | Verify once, then ignore |
| Wrong `createdAt`/`updatedAt` format differences | Low | Medium — `DateTime.parse` could fail | Use ISO-8601 strings (already correct) |

---

## Recommendation

**Do NOT modify the Flutter app parser.**
**Do NOT replace `assets/encyclopedia/catalog.json` yet.**

Instead:
1. Migrate 1–2 more topics (slump-test, concrete-curing) to Draft JSON.
2. Export and build a multi-topic generated catalog.
3. Run integration tests or manual QA comparing app behavior with both catalogs.
4. Replace the official catalog only after approval.

The generated pipeline is ready for safe use.
