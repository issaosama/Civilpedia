# Civilpedia Content Template System

## Purpose

The content template system enables civil engineers to author and manage encyclopedia topics for the Civilpedia mobile app without writing any Flutter code or editing JSON manually.

Engineers fill Google Sheets (or CSV files) using the templates in this directory. A Dart CLI converter (`tools/content_converter/`) reads the CSV files and generates `assets/encyclopedia/catalog.json`, which the app loads at runtime.

## Workflow Overview

```
Author (Engineer)  →  Google Sheets / CSV
       ↓
Reviewer (Engineer)  →  verifies accuracy
       ↓
Approver (Senior Engineer)  →  approves
       ↓
Developer  →  dart run bin/convert.dart
       ↓
catalog.json  →  committed to repo
       ↓
App loads content on next build
```

## How It Works

1. Engineers fill the 8 CSV sheets with topic content.
2. The converter reads all 8 files, validates the data, and generates `catalog.json`.
3. The app's encyclopedia screen reads `catalog.json` and renders topics using the editorial template.
4. Adding a new topic requires **only** CSV changes — no Flutter code modifications.

## Folder Structure

```
docs/content_template/
├── README.md                          # This file
├── content_workflow_ar.md             # Workflow guide (Arabic)
├── content_schema_ar.md               # Column-by-column reference (Arabic)
├── reviewer_checklist_ar.md           # Reviewer checklist (Arabic)
├── topics_template.csv                # Blank template
├── sections_template.csv
├── blocks_template.csv
├── checklist_items_template.csv
├── table_rows_template.csv
├── accept_reject_template.csv
├── common_mistakes_template.csv
├── equipment_items_template.csv
└── examples/
    ├── slump_test_example_notes.md
    └── google_sheets_setup_ar.md

tools/content_converter/
├── bin/
│   ├── convert.dart                   # CSV → catalog.json
│   └── export_csvs.dart               # catalog.json → CSV (reverse)
├── lib/                                # Converter library
└── sample/                             # Sample CSV files (3 pilot topics)
```

## Getting Started for Engineers

1. Read `content_workflow_ar.md` to understand the process.
2. Read `content_schema_ar.md` for detailed column explanations.
3. Use the blank `*_template.csv` files to create your content.
4. Fill `topics_template.csv` first (one row per topic), then the related sheets.
5. Submit to reviewer when complete.

## Running the Converter

From `tools/content_converter/`:

```bash
dart pub get
dart run bin/convert.dart sample ../../assets/encyclopedia/catalog.json
```

To regenerate CSVs from an existing catalog (reverse direction):

```bash
dart run bin/export_csvs.dart <output-dir>
```

## Important Notes

- **Column names must remain English** and match the converter exactly.
- **Content values should be in Arabic** (app is Arabic-only).
- `planKey` column is reserved for future monetization — leave empty for now.
- Topics with status `Draft` or `Engineering Review` will pass the converter but should not be shipped.
- Only `Ready for App` topics should be included in production releases.
- After generating `catalog.json`, review the diff before committing.
