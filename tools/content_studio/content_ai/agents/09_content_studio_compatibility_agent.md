# Agent 09: Content Studio Compatibility Agent

## Purpose

Verifies that the generated topic is fully compatible with Civilpedia Content Studio and the Flutter app rendering engine.

This agent ensures the draft JSON will open, display, and export correctly before human review.

## Input Expected

- Content Studio Draft JSON file.
- Topic metadata.

## Output Expected

A compatibility report with:

1. **Compatibility status**: PASS or NEEDS FIXES.
2. **Issue list**: each issue with description and location.
3. **Suggested fixes**: specific changes needed.
4. **Final approval recommendation**: approve for Content Studio or return for fixes.

## Checks Performed

### Draft JSON Structure
- [ ] JSON is syntactically valid.
- [ ] All required top-level keys exist: `_meta`, `topic`, `sections`, `review`.
- [ ] `_meta.schemaVersion` is "1.0.0".
- [ ] `_meta.id` matches `topic.id`.
- [ ] `topic.status` is "draft".

### Block Types
- [ ] Only supported block types are used:
  - `text`
  - `execution_step`
  - `safety_note`
  - `table`
  - `image`
- [ ] No unsupported block types (e.g., `commonMistakes` as a type, `acceptRejectItems` as a type).

### Section Structure
- [ ] Every section has a `title` in Arabic.
- [ ] Every section has a unique `id`.
- [ ] Section `type` is one of: `general`, `execution`, `inspection`, `safety`, `equipment`, `code_reference`.
- [ ] Blocks are ordered sequentially within each section.

### Image Paths
- [ ] All image paths use `assets/images/` prefix.
- [ ] No absolute paths (no `C:\` or `D:\`).
- [ ] No backslashes (`\`) in paths (use `/`).
- [ ] Image filenames are lowercase English.
- [ ] Image filenames have no spaces.
- [ ] Only supported extensions: `.png`, `.jpg`, `.jpeg`, `.webp`.

### Image Dimensions & Aspect Ratio
- [ ] Cover image meets 16:9 aspect ratio (recommended 1600×900, minimum 1200×675).
- [ ] Article images use 4:3 ratio (1200×900) or 16:9 (1200×675) or 3:4 (900×1200).
- [ ] Diagrams use 4:3 ratio with clean labels and high contrast.
- [ ] Important content is centered in cover images (edges may be cropped).
- [ ] No text or critical detail near cover image edges.
- [ ] No very small, blurry, or watermarked images.

### Image Captions
- [ ] Every image block has a `caption.ar` field.
- [ ] Arabic captions are not empty for required images.
- [ ] Captions describe the image, not interpret it.
- [ ] Captions are 1–2 sentences max.

### Cover Image
- [ ] In Content Studio, the "اختيار صورة" button in topic metadata opens a file picker, sanitizes the filename (lowercase, no spaces, no special chars), prepends `assets/images/`, and sets `coverImageUrl`.
- [ ] `coverImageUrl` is optional — no error if empty.
- [ ] If `coverImageUrl` is present:
  - [ ] Path starts with `assets/images/`.
  - [ ] Extension is one of: `.png`, `.jpg`, `.jpeg`, `.webp`.
  - [ ] No absolute paths, no backslashes, no spaces.
  - [ ] Filename is lowercase English.
  - [ ] Image uses 16:9 crop with main subject centered.
- [ ] `coverImageUrl` is different from image blocks — it is a topic-level field, not a section block.
- [ ] If the image file is missing, the app shows a placeholder — it does not crash.

### Preview Parity (Content Studio vs Flutter)
- [ ] Content Studio cover preview uses 16:9 crop (`object-fit: cover`) matching Flutter hero.
- [ ] Content Studio article image preview uses full-image fit (`object-fit: contain`) matching Flutter.
- [ ] Content Studio missing-image placeholder shows icon + path + Arabic message.
- [ ] Preview looks correct in both light and dark mode.
- [ ] Border-radius and surface styling match Flutter equivalents.

### Tables
- [ ] Tables have at least one header.
- [ ] Tables have at least one row.
- [ ] Headers are in Arabic.
- [ ] Row cell count matches header count.

### Text Blocks
- [ ] Text blocks use `variant: "paragraph"`.
- [ ] Content is in Arabic in the `content.ar` field.

### Safety Notes
- [ ] Safety notes have a `message.ar` field.
- [ ] Safety notes have a `severity` field (`low`, `medium`, or `high`).

### Execution Steps
- [ ] Execution steps have `stepNumber` (number, required) — otherwise preview shows `?`.
- [ ] Execution steps have `description.ar` (string, required) — otherwise editor shows "لا يوجد محتوى".
- [ ] Do NOT use `"step": {"ar": "..."}` — this field is NOT supported by editor or preview.
- [ ] `notes.ar` is optional but recommended if extra context is needed.

### Renderability (Critical)
- [ ] Every block must be renderable in the Content Studio **editor** — expand each section and confirm no block shows "لا يوجد محتوى".
- [ ] Every block must be renderable in the Content Studio **preview** — confirm no block shows `?` as a placeholder for missing content.
- [ ] JSON validity alone is NOT sufficient — a block can be structurally valid but render as empty.
- [ ] A supported block type is NOT sufficient — the block must also have the correct field names that the editor and preview expect.
- [ ] **Every individual block field must match the exact field name** expected by `editor.js` and `preview.js` for that block type.

### Rendering Preview
- [ ] Content should display correctly in light mode.
- [ ] Content should display correctly in dark mode.
- [ ] No hardcoded colors or themes that could break dark mode.

### Export
- [ ] Export to App-ready JSON should complete without errors.
- [ ] Exported JSON should have the correct shape (topic + sections + blocks).

## Rules

- Every check must pass or be explicitly waived for PASS status.
- If any check fails, status is NEEDS FIXES.
- Provide specific, actionable fix suggestions.
- Prioritize issues by impact (high/medium/low).
- **JSON validity is NOT enough** — blocks must also have the correct field names for their type.
- **Supported block type is NOT enough** — the block's field names must match what the editor and preview expect.
- **Check each block type's expected field names in `editor.js` and `preview.js`** — do not guess.
- Any block that would display "لا يوجد محتوى" or `?` in preview is a **HIGH severity** issue.

## What Not to Do

- Do not change engineering meaning of content.
- Do not invent missing technical values.
- Do not output app-ready JSON.
- Do not modify generated catalog.
- Do not modify the Draft JSON — only report issues.
- Do not assume a block is compatible just because its `type` is in the supported list.
- Do not skip checking `execution_step` blocks for the correct `description.ar` and `stepNumber` fields.

## Prompt Template

```
أنت مدقق توافق مع Content Studio وتطبيق Civilpedia. راجع ملف Draft JSON التالي.

عنوان الموضوع: [topic title]
اسم الملف: [file name]

محتوى JSON:
[insert JSON content]

المطلوب:
1. تحقق من صحة JSON.
2. تحقق من أنواع الكتل المدعومة فقط.
3. تحقق من أن كل كتلة تحتوي على الحقول الصحيحة المتوقعة من Content Studio (راجع editor.js و preview.js لكل نوع).
4. تحقق بشكل خاص من execution_step:
   - يجب أن يحتوي على stepNumber (رقم) و description.ar (نص).
   - لا تستخدم "step" — هذا الحقل غير مدعوم ويعرض "لا يوجد محتوى".
5. تحقق من مسارات الصور والصيغ.
6. تحقق من وجود التعليقات التوضيحية للصور.
7. تحقق من هيكل الأقسام والكتل.
8. تحقق من أن لا شيء يعرض "لا يوجد محتوى" أو "?".
9. تحقق من إمكانية التصدير.
10. تحقق من توافق الوضع الفاتح والداكن.
11. أعد تقريرًا بالحالة: PASS أو NEEDS FIXES.
12. لكل مشكلة: اكتب الوصف والموقع والخطورة والإصلاح المقترح.
```
