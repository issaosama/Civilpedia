# Content Studio — Civilpedia Content System

## Current Decision

Civilpedia's content authoring is transitioning from Excel/Google Sheets/CSV to **Draft JSON** as the new source of truth. This enables:

- Human-readable, editable files per topic
- Structured metadata for review/approval workflows
- Future support for accounts, roles, and cloud databases (Supabase/Firebase)
- Clean separation between authoring format and app delivery format

The CSV converter and existing `content_source/` CSVs remain as a **legacy import path**. New topics should use Draft JSON via Content Studio.

## Folder Roles

```
docs/content_studio/
├── README.md                  ← This file
├── draft_json_schema_v1.md    ← Technical schema specification (English)
├── draft_json_schema_ar.md    ← Schema guide (Arabic)

draft_jsons/
├── iraqi-tiles-types.draft.json  ← Golden topic example

tools/content_studio/          ← (future) HTML Content Studio Lite
```

### `docs/content_studio/`

Documentation for the schema, content guidelines, and architectural decisions.

### `draft_jsons/`

Canonical Draft JSON files — one per topic. These are the **source of truth** for all new and migrated content. Each file follows `draft_json_schema_v1.md`.

### `tools/content_studio/` (future)

Browser-based Content Studio Lite for editing Draft JSON files. Planned as a single HTML file with no dependencies and no build step.

## Next Phases

| Phase | Description |
|-------|-------------|
| **CONTENT-STUDIO-1B** | Build Content Studio Lite HTML prototype |
| **CONTENT-STUDIO-1C** | Build export pipeline: Draft JSON → app-ready JSON |
| **CONTENT-STUDIO-1D** | Migrate 2–3 topics from CSV to Draft JSON |
