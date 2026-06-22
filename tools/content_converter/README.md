# Content Converter

A Dart CLI tool that converts civil engineering topic content from CSV files into `catalog.json` for the Civilpedia mobile app.

## Usage

```bash
cd tools/content_converter
dart pub get

# Convert CSV directory → catalog.json
dart run bin/convert.dart <input-dir> <output-path>

# Reverse: catalog.json → CSV directory
dart run bin/export_csvs.dart <output-dir>
```

**Default paths** (no arguments):
- `convert.dart` → reads from `sample/`, writes to `../../assets/encyclopedia/catalog.json`
- `export_csvs.dart` → reads `../../assets/encyclopedia/catalog.json`, writes to `sample/`

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
