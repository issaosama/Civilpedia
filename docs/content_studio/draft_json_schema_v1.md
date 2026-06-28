# Draft JSON Schema v1.0.0

## Overview

Draft JSON is the new **source-of-truth** format for Civilpedia encyclopedia content. Each topic is a single `.draft.json` file. The schema is designed for human authoring, machine validation, and future export to the app-ready `catalog.json` format.

---

## File Structure

```json
{
  "_meta": { ... },
  "topic": { ... },
  "sections": [ ... ],
  "review": { ... }
}
```

---

## `_meta` — Document Metadata

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schemaVersion` | string | yes | Semver of this schema (e.g. `"1.0.0"`) |
| `version` | integer | yes | Incremental content revision number (starts at 1) |
| `createdAt` | string (ISO-8601) | yes | File creation timestamp |
| `updatedAt` | string (ISO-8601) | yes | Last modification timestamp |
| `createdBy` | string | no | Editor/author identifier (null until accounts exist) |
| `updatedBy` | string | no | Last editor identifier |
| `source` | string | yes | Origin: `"csv-migration"`, `"content-studio"`, or `"manual"` |

---

## `topic` — Topic Data

### Status Enum

| Value | Meaning |
|-------|---------|
| `draft` | In progress, not ready for review |
| `review` | Submitted for review |
| `approved` | Reviewed and approved |
| `published` | Exported to app and live |
| `archived` | Retired / replaced |

### Level Enum

| Value | Meaning |
|-------|---------|
| `basic` | Beginner-friendly |
| `intermediate` | Requires some field experience |
| `advanced` | Detailed technical content |

### Plan Key Enum

| Value | Meaning |
|-------|---------|
| `free` | Available to all users |
| `pro` | Pro subscribers only |

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Unique topic identifier (kebab-case, e.g. `"iraqi-tiles-types"`) |
| `titleAr` | string | yes | Arabic title |
| `titleEn` | string | yes | English title |
| `categoryId` | string | yes | Category identifier (e.g. `"finishing"`, `"concrete"`) |
| `summaryAr` | string | yes | Arabic short summary (1–2 sentences) |
| `summaryEn` | string | yes | English short summary |
| `tags` | string[] | yes | Search/filter tags (Arabic preferred) |
| `relatedTopicIds` | string[] | no | IDs of related topics |
| `level` | string | yes | One of: `basic`, `intermediate`, `advanced` |
| `planKey` | string | yes | One of: `free`, `pro` |
| `status` | string | yes | One of: `draft`, `review`, `approved`, `published`, `archived` |
| `featuredImageUrl` | string | no | Path to featured image (`assets/images/...`) |
| `simpleExplanation` | object | yes | `{ "ar": "...", "en": "..." }` — plain-language summary |
| `beforeWork` | object | yes | `{ "ar": "...", "en": "..." }` — pre-work instructions |
| `duringWork` | object | yes | `{ "ar": "...", "en": "..." }` — execution instructions |
| `afterWork` | object | yes | `{ "ar": "...", "en": "..." }` — post-work instructions |
| `codeNotes` | object | no | `{ "ar": "...", "en": "..." }` — code-related notes |
| `siteNotes` | object | no | `{ "ar": "...", "en": "..." }` — site-practice notes |
| `reportWording` | object | yes | `{ "ar": "...", "en": "..." }` — template wording for daily reports |
| `relatedToolRoutes` | string[] | no | App route paths for related calculators (e.g. `["/calculator/tile"]`) |
| `relatedChecklistIds` | string[] | no | IDs of related checklists |
| `commonMistakes` | array | no | Array of `CommonMistakeItem` objects |
| `acceptRejectItems` | array | no | Array of `AcceptRejectItem` objects |

### CommonMistakeItem

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ar` | string | yes | Arabic description of the mistake |
| `en` | string | yes | English description |
| `severity` | string | no | Severity hint: `"low"`, `"medium"`, `"high"` |

### AcceptRejectItem

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `criteriaAr` | string | yes | Arabic inspection criterion name |
| `criteriaEn` | string | yes | English inspection criterion name |
| `acceptanceLimitAr` | string | yes | Arabic acceptance limit description |
| `acceptanceLimitEn` | string | yes | English acceptance limit description |
| `methodAr` | string | yes | Arabic inspection method |
| `methodEn` | string | yes | English inspection method |
| `isCritical` | boolean | yes | Whether this is a critical (knockout) criterion |
| `reviewRequired` | boolean | yes | Whether the result must be reviewed |
| `planKey` | string | no | Override plan key for this item |
| `codeReference` | string | no | Reference code standard |

---

## `sections` — Content Sections Array

Each section has:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Unique section identifier (kebab-case, e.g. `"tile-application"`) |
| `title` | string | yes | Section title (Arabic) |
| `titleEn` | string | no | Section title (English) |
| `type` | string | yes | Section type (see below) |
| `order` | integer | yes | Display order within the topic (1-based) |
| `blocks` | array | yes | Array of block objects (see below) |

### Section Types

| Value | Meaning |
|-------|---------|
| `general` | Introductory or general information |
| `execution` | Step-by-step execution instructions |
| `inspection` | Inspection and quality control points |
| `safety` | Safety notes and precautions |
| `equipment` | Required tools and equipment |
| `codeReference` | Code/standard references |

---

## `blocks` — Content Blocks

Every block has:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | Block type identifier |
| `order` | integer | yes | Display order within the section (1-based) |

### Supported Block Types

#### `text`

Generic text paragraph. Variants control rendering style.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `content` | object | yes | `{ "ar": "...", "en": "..." }` — localized text content |
| `variant` | string | yes | One of: `paragraph`, `note`, `warning`, `tip` |

#### `execution_step`

A numbered step in a procedure.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `stepNumber` | integer | yes | Step number (sequential) |
| `description` | object | yes | `{ "ar": "...", "en": "..." }` — step description |
| `notes` | object | no | `{ "ar": "...", "en": "..." }` — extra notes / tips |
| `imageUrl` | string | no | Optional image for this step |

#### `safety_note`

A safety warning or precaution.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `message` | object | yes | `{ "ar": "...", "en": "..." }` — safety instruction |
| `severity` | string | yes | One of: `low`, `medium`, `high`, `critical` |

#### `table`

A data table with headers and rows.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `caption` | object | no | `{ "ar": "...", "en": "..." }` — table caption |
| `headers` | string[] | yes | Column headers (Arabic) |
| `headersEn` | string[] | no | Column headers (English) |
| `rows` | array | yes | Array of `{ "cells": [...] }` objects |

#### `checklist`

A checklist with required items.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | object | no | `{ "ar": "...", "en": "..." }` — checklist title |
| `items` | array | yes | Array of `ChecklistItem` objects |

ChecklistItem fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `textAr` | string | yes | Arabic item text |
| `textEn` | string | no | English item text |
| `isRequired` | boolean | no | Whether mandatory (default true) |
| `category` | string | no | Optional grouping |

#### `inspection_point`

An inspection criterion with method and limits.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `criteriaAr` | string | yes | Arabic criterion name |
| `criteriaEn` | string | yes | English criterion name |
| `acceptanceLimitAr` | string | yes | Arabic limit description |
| `acceptanceLimitEn` | string | yes | English limit description |
| `methodAr` | string | yes | Arabic inspection method |
| `methodEn` | string | yes | English inspection method |
| `isCritical` | boolean | yes | Knockout criterion flag |
| `acceptableTolerance` | string | no | Tolerance range description |

#### `code_reference`

A reference to a code or standard.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | string | yes | Standard/code identifier (e.g. `"ASTM C143"`) |
| `title` | object | yes | `{ "ar": "...", "en": "..." }` — title of the standard |
| `section` | string | no | Specific section within the standard |
| `excerpt` | object | no | `{ "ar": "...", "en": "..." }` — short excerpt |

#### `equipment`

A list of required tools/equipment.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `items` | array | yes | Array of `EquipmentItem` objects |

EquipmentItem fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `nameAr` | string | yes | Arabic name |
| `nameEn` | string | no | English name |
| `specification` | string | no | Technical specification |
| `purpose` | string | no | Usage purpose |

#### `image`

An inline image.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `url` | string | yes | Asset path (e.g. `"assets/images/rebar_cover.png"`) |
| `caption` | object | no | `{ "ar": "...", "en": "..." }` — image caption |

---

## `review` — Review Metadata

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `status` | string | yes | One of: `draft`, `in_review`, `changes_requested`, `approved`, `rejected` |
| `reviewedBy` | string | no | Reviewer identifier |
| `reviewedAt` | string (ISO-8601) | no | Review timestamp |
| `reviewNotes` | string | no | Reviewer feedback / change requests |
| `approvalStatus` | string | no | Final approval decision |

---

## Draft JSON vs App-ready JSON

| Aspect | Draft JSON | App-ready JSON (catalog.json) |
|--------|------------|-------------------------------|
| Scope | One file per topic | All topics in one file |
| Structure | Inline sections → blocks | Flat maps keyed by IDs |
| Localization | `{ "ar": ..., "en": ... }` objects | Flat strings (selected at build) |
| Editorial fields | `_meta`, `review`, rich metadata | Minimal data only |
| Read by Flutter app | No (not yet) | Yes (current format) |
| Human editable | Yes | No (machine-optimized) |
| Validation | JSON Schema + custom rules | Validated at converter time |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-06-28 | Initial schema |
