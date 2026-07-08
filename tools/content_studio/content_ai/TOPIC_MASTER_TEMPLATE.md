# Topic Master Template

## Content Contract Overview

**Critical principle:** `topic` = metadata only. `sections` + `blocks` = all body content.

Big Pickle must output **Draft JSON** only (the format Content Studio reads/writes).  
**Do NOT output App-ready JSON** (the format the Flutter app consumes — that is produced by the exporter).  

Draft JSON structure:
```
{
  "_meta":     { /* schema version, timestamps, source info */ },
  "topic":     { /* metadata only — id, titleAr, categoryId, level, etc. */ },
  "sections":  [ /* all body content lives here */ ],
  "review":    { /* review status for Content Studio workflow */ }
}
```

## Official Topic Metadata Fields (topic = metadata only)

### Identification
| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string (kebab-case) | Yes | e.g., `concrete-slump-test` |
| `titleAr` | string | Yes | Arabic title |
| `titleEn` | string | No | Optional — only when explicitly requested |
| `categoryId` | string | Yes | e.g., `concrete`, `steel`, `general` |
| `summaryAr` | string | Yes | 2-3 sentence Arabic summary |

### Classification
| Field | Type | Required | Notes |
|---|---|---|---|
| `level` | `"basic" \| "intermediate" \| "advanced"` | Yes | |
| `planKey` | `"free" \| "pro"` | Yes | |
| `tags` | string[] | No | Max 10 |
| `keyTopics` | string[] | No | Max 20 |

### Relationships
| Field | Type | Required | Notes |
|---|---|---|---|
| `relatedTopicIds` | string[] | No | Cross-topic links |
| `relatedToolRoutes` | string[] | No | App tool routes |
| `relatedChecklistIds` | string[] | No | Checklist references |

### Media
| Field | Type | Required | Notes |
|---|---|---|---|
| `coverImageUrl` | string | No | Must start with `assets/images/` |
| `visual_theme` | object | No | `{"accent": "key"}` — one of 14 keys, defaults to `cement_gray` |

### Audit
| Field | Type | Required | Notes |
|---|---|---|---|
| `createdAt` | ISO 8601 string | Yes | |
| `updatedAt` | ISO 8601 string | Yes | |

### Content Studio Internal
| Field | Type | Required | Notes |
|---|---|---|---|
| `status` | `"draft"` | Yes | Always `"draft"` for new topics |

### Forbidden Topic-Level Body Fields

These fields **must NOT** appear in new topics. Any content that would have gone here must be placed in `sections` + `blocks`:

| Forbidden Field | Correct Location |
|---|---|
| `simpleExplanation` | `general` section / `text` block (variant: "paragraph") |
| `beforeWork` | `execution` section / `execution_step` or `text` blocks |
| `duringWork` | `execution` section / `execution_step` or `text` blocks |
| `afterWork` | `execution` section / `execution_step` or `text` blocks |
| `commonMistakes` | `general` section / `text` blocks (variant: "warning") |
| `acceptRejectItems` | `inspection` section / `inspection_point` blocks |
| `codeNotes` | `codeReference` section / `code_reference` blocks |
| `siteNotes` | `general` section / `text` block (variant: "note") |
| `reportWording` | `general` section / `text` block (variant: "paragraph") |
| `featuredImageUrl` | Use `coverImageUrl` or `image` block inside a section |

## Visual Theme (visual_theme)

`topic.visual_theme` must be an object: `{"accent": "key"}`. If unset, defaults to `cement_gray`.

Allowed 14 keys (snake_case only):

| Key | Arabic Label |
|---|---|
| `cement_gray` | افتراضي / رصاصي أسمنتي |
| `navy` | كحلي هندسي |
| `teal` | بترولي |
| `olive` | زيتي |
| `amber` | كهرماني ترابي |
| `maroon` | عنابي |
| `steel_blue` | أزرق فولاذي |
| `graphite` | جرافيتي |
| `sand` | رملي |
| `brick` | طوبي |
| `emerald` | زمردي |
| `indigo` | نيلي |
| `copper` | نحاسي |
| `asphalt` | أسفلتي |

## Section Types

6 official section types. Each section has: `id` (unique), `title` (Arabic), `type`, `order` (1-based), `blocks[]`.

| Type | Purpose | Arabic Label |
|---|---|---|
| `general` | Introductions, explanations, notes, common mistakes | معلومات عامة |
| `execution` | Step-by-step work procedures | خطوات التنفيذ |
| `inspection` | Quality control, inspection points, checklists | الفحص والتفتيش |
| `safety` | Safety notes and warnings | إجراءات السلامة |
| `equipment` | Required tools and equipment | المعدات والأجهزة |
| `codeReference` | Standards, codes, specifications | المراجع والكودات |

## Block Types — Draft JSON Shape

9 official block types. Each block has: `type`, `order` (1-based within section), and type-specific fields.

### text
```
{ "type": "text", "order": 1, "content": { "ar": "نص عربي" }, "variant": "paragraph" }
```
Variants: `paragraph` (body text), `note` (supplementary), `tip` (professional tip), `warning` (mistake/caution).

### execution_step
```
{ "type": "execution_step", "order": 1, "stepNumber": 1, "description": { "ar": "..." }, "notes": { "ar": "" } }
```
Do NOT use `"step": {"ar": "..."}` — this is unsupported and shows "لا يوجد محتوى".

### safety_note
```
{ "type": "safety_note", "order": 1, "message": { "ar": "..." }, "severity": "medium" }
```
Severity: `low`, `medium`, `high`, `critical`.

### table
```
{ "type": "table", "order": 1, "headers": ["عمود1", "عمود2"], "rows": [{ "cells": ["قيمة1", "قيمة2"] }] }
```

### image
```
{ "type": "image", "order": 1, "url": "assets/images/file_name.png", "caption": { "ar": "تعليق", "en": "" } }
```
URL must start with `assets/images/`. Supported: `.png`, `.jpg`, `.jpeg`, `.webp`.

### checklist
```
{ "type": "checklist", "order": 1, "title": { "ar": "عنوان القائمة" }, "items": [{ "id": "item-01", "textAr": "نص البند", "isRequired": true }] }
```

### inspection_point
```
{ "type": "inspection_point", "order": 1, "criteriaAr": "معيار الفحص", "methodAr": "طريقة الفحص", "acceptableTolerance": "±5mm", "isCritical": false }
```
Optional `markerStyle` field — one of: `neutral`, `inspection`, `info`, `warning`, `critical`, `success`.
If missing, falls back to `critical` (when `isCritical: true`) or `inspection` (when `isCritical: false`).

### code_reference
```
{ "type": "code_reference", "order": 1, "code": "ACI 318-19", "title": { "ar": "عنوان الكود", "en": "" }, "section": "7.6.1", "excerpt": { "ar": "نص من الكود", "en": "" } }
```

### equipment
```
{ "type": "equipment", "order": 1, "title": "المعدات", "items": [{ "nameAr": "اسم المعدة", "purpose": "الغرض", "specification": "المواصفات" }] }
```

## Draft JSON vs App-Ready JSON — Key Differences

Big Pickle generates **Draft JSON** only. The exporter converts to App-ready JSON.

| Aspect | Draft JSON (output of Big Pickle) | App-ready JSON (output of exporter) |
|---|---|---|
| `summaryAr` | Used in topic | Renamed to `summary` |
| `text.content` | `{ar, en}` object | Flat string `content` (Arabic only) |
| `execution_step` | `stepNumber`, `description:{ar,en}` | Nested `step{stepNumber, description}` |
| `safety_note` | `message:{ar,en}`, `severity` | Nested `note{message, severity}` |
| `image` | `url`, `caption:{ar,en}` | `imageUrl`, flat `caption` |
| `_meta` | Present | Stripped |
| `review` | Present | Stripped |
| `sections[].blocks` | Nested inside section | Flat `blocks{sectionId: [...]}` |

## Recommended Topic Structure (content outline)

```
1. Definition & Importance   → general section / text block (variant: paragraph)
2. Required Tools/Equipment  → equipment section / equipment blocks
3. Execution Steps           → execution section / execution_step blocks
4. Inspection & Acceptance   → inspection section / inspection_point + checklist blocks
5. Common Mistakes           → general section / text blocks (variant: warning)
6. Safety Notes              → safety section / safety_note blocks
7. Code References           → codeReference section / code_reference blocks
8. Site Notes                → general section / text blocks (variant: note)
9. Tables (if useful)        → table blocks in appropriate section
10. Images                   → image blocks in appropriate sections
```

Each topic should have at least 1 section with at least 1 block. There is no maximum, but keep focused.

## Minimal Required Fields

- `_meta.schemaVersion` — must be `"1.0.0"`
- `_meta.id` — must match `topic.id`
- `topic.id` — unique kebab-case ID
- `topic.titleAr` — Arabic title
- `topic.categoryId` — category slug
- `topic.summaryAr` — Arabic summary
- `topic.level` — one of: `"basic"`, `"intermediate"`, `"advanced"`
- `topic.planKey` — one of: `"free"`, `"pro"`
- `topic.status` — must be `"draft"`
- At least one section with at least one block
- `review.status` — must be `"draft"`
