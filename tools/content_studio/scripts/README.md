# Catalog Build Scripts

Scripts that combine individual topic JSON files into a single catalog file for the Flutter app.

## Prerequisites

- Dart SDK (for `build_catalog.dart`)
- Or Node.js (for `build_catalog_from_topics.js`)

## How to Run

### Using Dart (recommended)

```bash
cd tools/content_studio/scripts
dart run build_catalog.dart
```

### Using Node.js

```bash
cd tools/content_studio/scripts
node build_catalog_from_topics.js
```

## What It Does

1. Reads all files from `app_ready_jsons/topics/*.topic.json`
2. Validates each file (topic.id, sections, blocks, table headers)
3. Combines them into `app_ready_jsons/catalog.generated.json`
4. Does **not** modify `assets/encyclopedia/catalog.json`

## Output Structure

- `_meta` — generation metadata (timestamp, source, counts)
- `topics[]` — array of topic objects (one per input file)
- `sections{}` — map of topicId → section array
- `blocks{}` — map of sectionId → block array

## Validation

The script will abort with errors if:
- A topic file is missing required keys (topic, sections, blocks)
- `topic.id` is missing or empty
- Duplicate topic IDs are found
- Duplicate section IDs are found
- A table block has missing or empty headers

Warnings (non-fatal) are printed for:
- Checklist with empty items
- Missing optional fields
- Blocks referencing unknown section IDs
- Missing English text fields
