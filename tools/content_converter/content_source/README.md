> **[LEGACY]** This workflow has been superseded by Civilpedia Content Studio + Content AI Pipeline. Keep this file for historical reference only; do not use it for new content production.

# Canonical Encyclopedia Content Source

This folder is the **official tracked content source** for Civilpedia.

## How to use

1. Author content in Google Sheets using `docs/content_template/`.
2. Export each sheet as CSV.
3. Replace the corresponding CSV file in this folder.
4. From `tools/content_converter/`, run:

```bash
dart run bin/convert.dart content_source ../../assets/encyclopedia/catalog.json
```

5. Commit this folder AND `catalog.json` together.

## Files

| File | Description |
|------|-------------|
| topics.csv | One row per topic |
| sections.csv | Sections within each topic |
| blocks.csv | Content blocks within each section |
| checklist_items.csv | Checklist items |
| table_rows.csv | Table row data |
| accept_reject.csv | Accept/reject criteria |
| common_mistakes.csv | Common mistakes |
| equipment_items.csv | Equipment items |

## Warning

Do NOT edit `catalog.json` manually. Always regenerate it from this folder.
