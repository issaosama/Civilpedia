> **[LEGACY]** This workflow has been superseded by Civilpedia Content Studio + Content AI Pipeline. Keep this file for historical reference only; do not use it for new content production.

# Content Converter

A Dart CLI tool that converts civil engineering topic content from CSV files into `catalog.json` for the Civilpedia mobile app.

## Quick Start (Production)

```bash
cd tools/content_converter
dart pub get
dart run bin/convert.dart content_source ../../assets/encyclopedia/catalog.json
```

## Canonical Content Source

The **only** folder used to generate the production `catalog.json` is:

**`tools/content_converter/content_source/`** — contains the 8 canonical CSV files tracked by Git.

## Folder Roles

| Folder | Tracked by Git | Purpose |
|--------|---------------|---------|
| `content_source/` | **Yes** | **Official canonical source** — the 8 CSVs used to generate `catalog.json`. This is the single source of truth for production content. |
| `from_google_sheet/` | **No** (`.gitignore`) | Temporary local export folder for testing or ad-hoc Google Sheet exports. Never commit. |
| `sample/` | **Yes** | Developer sample/test data. Contains 3 pilot topics for converter development and testing. **Do not generate production `catalog.json` from this folder.** |
| `assets/encyclopedia/catalog.json` | **Yes** | Generated app output — the JSON catalog consumed by the Flutter app. |

## Workflow

```
[Google Sheet — Engineering Workspace]  →  Export CSVs
         ↓
[content_source/ folder]  ←  Place the exported CSV files here
         ↓
[Converter]  (dart run bin/convert.dart content_source ...)
         ↓
[catalog.json]  ←  Generated, review diff, commit
         ↓
[Flutter App]  ←  Loads catalog.json at runtime
```

### Step-by-step

1. **Author content** in Google Sheets using the templates at `docs/content_template/`.
2. **Export each sheet as CSV** and place the 8 CSV files into `tools/content_converter/content_source/`.
3. **Run the converter** from `tools/content_converter/`:
   ```bash
   dart run bin/convert.dart content_source ../../assets/encyclopedia/catalog.json
   ```
4. **Review** the output `catalog.json` changes with `git diff`.
5. **Commit** `content_source/` changes AND `catalog.json` together.

> ⚠ **WARNING**: Always verify the input folder. Running with `sample/` will overwrite `catalog.json` with sample/developer data. Production catalog must be generated from `content_source/`.

## CLI Reference

```bash
dart run bin/convert.dart <input-dir> <output-path>

# Examples:
dart run bin/convert.dart content_source ../../assets/encyclopedia/catalog.json   # Production
dart run bin/convert.dart sample ../../assets/encyclopedia/catalog.json           # Developer test
dart run bin/convert.dart from_google_sheet ../../assets/encyclopedia/catalog.json # Ad-hoc
```

**Default paths** (no arguments):
- `input-dir` defaults to `sample/`
- `output-path` defaults to `../../assets/encyclopedia/catalog.json`

Available reverse tool:
```bash
dart run bin/export_csvs.dart <output-dir>
```

## Input: 8 CSV Files

| File | Description |
|------|-------------|
| `topics.csv` | One row per encyclopedia topic |
| `sections.csv` | Sections within each topic |
| `blocks.csv` | Content blocks within each section |
| `checklist_items.csv` | Checklist items (linked to checklist blocks) |
| `table_rows.csv` | Table row data (linked to table blocks) |
| `accept_reject.csv` | Accept/reject criteria per topic |
| `common_mistakes.csv` | Common mistakes per topic |
| `equipment_items.csv` | Equipment items (linked to equipment blocks) |

## Validation

The converter performs automatic validation before building:

- **Errors** — prevent catalog generation (must be fixed first)
  - Missing required fields
  - Invalid enum values (level, status, type, category, severity, etc.)
  - Orphan references (section without topic, block without section)
- **Warnings** — do not block generation but should be reviewed
  - Empty optional fields
  - Draft/review status on topics that lack `[DRAFT - REVIEW REQUIRED]` tags
  - Duplicate references

## Content Authoring

Engineers should use the templates in `docs/content_template/` to author content in Google Sheets, then export CSV files for this converter.

See `docs/content_template/README.md` for the full workflow.
