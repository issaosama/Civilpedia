# Content Studio Lite — V1 Prototype

A browser-based authoring tool for Civilpedia Draft JSON files.

## What It Is

Content Studio Lite is a **local-only** HTML/JS tool for creating and editing Civilpedia encyclopedia content in the new Draft JSON format. No backend, no build step, no package manager — just open and use.

## How to Run

### Option 1 — Open directly (may have limitations)
Open `index.html` in any modern browser.

> Note: Some browsers (Chrome) restrict `fetch` for local files. If editing/download don't work, use Option 2.

### Option 2 — Local HTTP server (recommended)
```bash
cd tools/content_studio
python -m http.server 8080
```
Then open: http://localhost:8080

## How to Use

1. Click **📂 Load Draft JSON** and select a `.draft.json` file from `draft_jsons/`.
2. Edit topic metadata in the form fields on the left.
3. Browse sections and blocks in the **الأقسام والكتل** section below.
4. Click **✅ Validate** to check the draft against the schema.
5. Click **👁️ تحديث المعاينة** to refresh the preview panel on the right.
6. Click **⬇️ Download Draft JSON** to save the updated draft file.
7. Click **📦 Export App-ready JSON** to export an app-compatible topic JSON.
   - Export is blocked if validation has errors.
   - Warnings are displayed but export proceeds.
   - The exported file can be placed in `app_ready_jsons/topics/`.
8. **Build combined catalog**: After exporting topic files, run the build script to generate `catalog.generated.json`:
   ```bash
   dart run tools/content_studio/scripts/build_catalog.dart
   ```

## V1 Features

- Load any `.draft.json` file via file picker
- Edit topic metadata: id, titleAr, titleEn, categoryId, summaryAr, summaryEn, level, planKey, status, reportWording, _meta fields, review.status
- Browse sections (ordered) with block counts
- View block cards with type labels and Arabic content preview
- Validate against Draft JSON schema v1.0.0
- Preview the article as rendered content (text, tables, steps, safety notes, checklists, mistakes, accept/reject items)
- Download edited draft as formatted JSON
- Export app-ready JSON: converts Draft JSON to a format compatible with the Flutter app content model
  - Flattens bilingual fields to Arabic-only
  - Restructures blocks for app consumption
  - Blocked if validation has errors
  - Warning banner if validation has warnings

## What V1 Does NOT Support (Yet)

- Adding / removing sections
- Adding / removing blocks
- Editing block content inline (metadata only)
- Table editing (cell values)
- Drag-and-drop reordering
- Image upload
- Multiple language toggles
- Full WYSIWYG editor
- Undo/redo
- Saving to disk automatically (manual download only)

## File Structure

```
tools/content_studio/
├── index.html         ← Main page
├── README.md          ← This file
├── css/
│   └── style.css      ← Styling
├── js/
│   ├── schema.js      ← Schema constants and enums
│   ├── draft.js       ← Draft data model
│   ├── validation.js  ← Schema validation engine
│   ├── preview.js     ← Preview renderer
│   ├── exporter.js    ← Draft JSON → app-ready JSON converter
│   └── app.js         ← Main app logic
└── scripts/
    ├── README.md                        ← Build script docs
    ├── build_catalog.dart               ← Dart: combine topic files → catalog
    └── build_catalog_from_topics.js      ← Node.js equivalent (reference)
```

## Future Phases

- CONTENT-STUDIO-1C: Export Draft JSON → app-ready JSON (✓)
- CONTENT-STUDIO-1D: Migrate 2–3 topics from CSV to Draft JSON
- CONTENT-STUDIO-1E: Load exported topic files into the Flutter app
- CONTENT-STUDIO-2A: Inline block editing
- CONTENT-STUDIO-2B: Section/block add/remove/reorder
- CONTENT-STUDIO-2C: Table editor
- CONTENT-STUDIO-3A: Image upload support
- CONTENT-STUDIO-3B: Auth-ready wiring (createdBy, reviewedBy fields)
