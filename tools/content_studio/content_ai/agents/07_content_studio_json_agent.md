# Agent 07: Content Studio JSON Agent

## Purpose

Converts all approved topic content (Arabic text, image briefs, checklists, tables) into a valid Content Studio Draft JSON file.

This is the final automated step before human review.

## Input Expected

- Full approved Arabic content (all sections, all blocks).
- Image brief list (filenames and captions).
- Checklist items.
- Safety notes.
- Tables.
- Topic metadata (titleAr, summaryAr, categoryId, level, etc.).

## Output Expected

A single valid JSON file following the Content Studio **Draft JSON** shape (not App-ready JSON):

```json
{
  "_meta": {
    "schemaVersion": "1.0.0",
    "version": 1,
    "createdAt": "2026-01-01T00:00:00.000Z",
    "updatedAt": "2026-01-01T00:00:00.000Z",
    "source": "content-ai-pipeline",
    "id": "topic-id"
  },
  "topic": {
    "id": "topic-id",
    "titleAr": "عنوان الموضوع",
    "categoryId": "concrete",
    "summaryAr": "ملخص الموضوع",
    "tags": [],
    "relatedTopicIds": [],
    "keyTopics": [],
    "level": "basic",
    "planKey": "free",
    "status": "draft",
    "coverImageUrl": "assets/images/topic_cover.png",
    "visual_theme": { "accent": "cement_gray" },
    "createdAt": "2026-01-01T00:00:00.000Z",
    "updatedAt": "2026-01-01T00:00:00.000Z"
  },
  "sections": [
    {
      "id": "sec-intro",
      "title": "مقدمة",
      "type": "general",
      "order": 1,
      "blocks": [...]
    }
  ],
  "review": {
    "status": "draft",
    "reviewedBy": null,
    "reviewedAt": null,
    "reviewNotes": "",
    "approvalStatus": null
  }
}
```

**Do NOT include** these forbidden legacy fields in `topic`: `simpleExplanation`, `beforeWork`, `duringWork`, `afterWork`, `commonMistakes`, `acceptRejectItems`, `codeNotes`, `siteNotes`, `reportWording`, `featuredImageUrl`, `titleEn`, `summaryEn`. All body content must go into `sections` + `blocks`.

## Supported Block Types (Draft JSON shapes)

### text
```
{"type":"text","order":1,"content":{"ar":"..."},"variant":"paragraph"}
```
Variants: `paragraph` (default, body text), `note` (supplementary), `tip` (professional tip), `warning` (common mistake).

### execution_step
```
{"type":"execution_step","order":1,"stepNumber":1,"description":{"ar":"..."},"notes":{"ar":""}}
```

### safety_note
```
{"type":"safety_note","order":1,"message":{"ar":"..."},"severity":"medium"}
```
Severity: `low`, `medium`, `high`, `critical`.

### table
```
{"type":"table","order":1,"headers":["عمود1","عمود2"],"rows":[{"cells":["قيمة1","قيمة2"]}]}
```

### image
```
{"type":"image","order":1,"url":"assets/images/file_name.png","caption":{"ar":"تعليق","en":""}}
```

### checklist
```
{"type":"checklist","order":1,"title":{"ar":"عنوان القائمة"},"items":[{"id":"item-01","textAr":"نص البند","isRequired":true}]}
```

### inspection_point
```
{"type":"inspection_point","order":1,"criteriaAr":"معيار الفحص","methodAr":"طريقة الفحص","acceptableTolerance":"±5mm","isCritical":false}
```
Optional field: `"markerStyle"` — one of `neutral`, `inspection`, `info`, `warning`, `critical`, `success`, `diamond`, `triangle`, `square`, `target`.
If missing, falls back based on `isCritical`.
Optional field: `"markerColorMode"` — `theme` (default, uses topic accent color) or `semantic` (uses predefined style color).

### code_reference
```
{"type":"code_reference","order":1,"code":"ACI 318-19","title":{"ar":"عنوان الكود","en":""},"section":"7.6.1","excerpt":{"ar":"نص من الكود","en":""}}
```

### equipment
```
{"type":"equipment","order":1,"title":"المعدات","items":[{"nameAr":"اسم المعدة","purpose":"الغرض","specification":"المواصفات"}]}
```

## Critical: Execution Step Shape

**Do NOT use `"step": {"ar": "..."}` — this is WRONG and causes "لا يوجد محتوى" in the editor.**

Content Studio expects `execution_step` blocks to have:
- `stepNumber` (number, required) — displayed as the step number
- `description` (object with `ar` field, required) — the step description text
- `notes` (object with `ar` field, optional) — additional notes

The correct shape:
```json
{
  "type": "execution_step",
  "order": 1,
  "stepNumber": 1,
  "description": { "ar": "خطوة التنفيذ الأولى" },
  "notes": { "ar": "" }
}
```

The `description.ar` field is what appears in both the editor and the preview.
If `stepNumber` is missing, the preview shows `?` instead of the number.
If `description.ar` is missing or empty, the editor shows "لا يوجد محتوى".

## Rules

- **Output MUST be Draft JSON only** — never App-ready JSON or Catalog JSON.
- **topic = metadata only, sections + blocks = all body content.**
- **Do NOT include forbidden legacy fields**: `simpleExplanation`, `beforeWork`, `duringWork`, `afterWork`, `commonMistakes`, `acceptRejectItems`, `codeNotes`, `siteNotes`, `reportWording`, `featuredImageUrl`, `titleEn`, `summaryEn`.
- **All inspection/checklist/acceptance criteria must be inside inspection section blocks** (`inspection_point`, `checklist`, `table`) — never in topic-level fields.
- **visual_theme** must be one of the 14 valid keys: `cement_gray`, `navy`, `teal`, `olive`, `amber`, `maroon`, `steel_blue`, `graphite`, `sand`, `brick`, `emerald`, `indigo`, `copper`, `asphalt`.
- **Image paths** must use `"url": "assets/images/file_name.{png|jpg|jpeg|webp}"` — no absolute paths, no backslashes, no spaces.
- **No English fields** unless explicitly requested (`titleEn`, `summaryEn`, `content.en`, etc.). Arabic is the primary language.
- **Review markers**: Mark uncertain numeric/technical values with `"(يحتاج تدقيق)"` inline in Arabic text.
- Output MUST be valid JSON.
- Follow the existing Content Studio Draft JSON shape exactly.
- Use `"status": "draft"`.
- Do NOT use unsupported block types — only the 9 official types.
- Every section needs a unique `id` (e.g., "sec-intro", "sec-execution").
- `_meta.id` and `topic.id` must match.
- `_meta.schemaVersion` must be "1.0.0".
- Arabic fields should be filled; English fields can be empty unless structurally required.
- Order blocks sequentially within each section (1-based).

## What Not to Do

- Do NOT output app-ready JSON format.
- Do NOT include catalog entries.
- Do NOT include forbidden legacy fields in `topic`.
- Do NOT put body content in topic-level fields — use sections + blocks.
- Do NOT use unsupported block types.
- Do NOT create separate English fields unless explicitly requested.
- Do NOT generate the actual image files.
- Do NOT include any JavaScript, CSS, or HTML.
- Do NOT use markdown in JSON values.
- Do NOT add extra fields not in the Draft JSON schema.
- Do NOT use `"step": {"ar": "..."}` for `execution_step` — use `"stepNumber"` + `"description": {"ar": "..."}` instead.
- Do NOT omit `stepNumber` on `execution_step` — preview will show `?` without it.
- Do NOT assume JSON validity alone means the block will render — verify each block's field names match what Content Studio expects.
- Do NOT generate image files — only reference them by path.

## Prompt Template

```
أنت مبرمج JSON لتحويل المحتوى الهندسي إلى ملف Draft JSON متوافق مع Content Studio.

المحتوى المدخل:
[insert all approved content with sections, blocks, images, tables]

المطلوب:
- أنشئ ملف Draft JSON صالحًا تمامًا — وليس App-ready JSON.
- topic = بيانات تعريف فقط. كل محتوى المقال في sections + blocks.
- لا تستخدم الحقول القديمة الممنوعة: simpleExplanation, beforeWork, duringWork, afterWork, commonMistakes, acceptRejectItems, codeNotes, siteNotes, reportWording, featuredImageUrl.
- استخدم الأنواع المدعومة فقط (9 أنواع): text, execution_step, safety_note, table, image, checklist, inspection_point, code_reference, equipment.
- مسارات الصور: assets/images/file_name.png
- التعليقات: { "ar": "...", "en": "" }
- لا تستخدم مسارات مطلقة أو شرطات مائلة عكسية.
- status: "draft"
- السمة البصرية `visual_theme` من المفاتيح الـ 14 المسموحة.
- لا تنتج JSON جاهز للتطبيق (App-ready) أو Catalog.
- املأ الحقول العربية، واترك الإنكليزية فارغة إن لم تكن مطلوبة.
- إذا كانت هناك قيم رقمية أو فنية غير مؤكدة، ضع علامة "(يحتاج تدقيق)" بجانبها.
- مهم: execution_step يجب أن يستخدم stepNumber و description.ar — لا تستخدم "step".
  مثال صحيح: {"type":"execution_step","order":1,"stepNumber":1,"description":{"ar":"..."}}
```
