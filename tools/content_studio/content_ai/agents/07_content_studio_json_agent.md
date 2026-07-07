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

A single valid JSON file following the Content Studio Draft JSON shape:

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
    "titleEn": "",
    "categoryId": "concrete",
    "summaryAr": "ملخص الموضوع",
    "summaryEn": "",
    "tags": [],
    "relatedTopicIds": [],
    "level": "basic",
    "planKey": "free",
    "status": "draft",
    "featuredImageUrl": "",
    "coverImageUrl": "assets/images/topic_cover.png",  <!-- Set via Content Studio's "اختيار صورة" picker button in topic metadata -->
    "simpleExplanation": {
      "ar": ""
    }
  },
  "sections": [
    {
      "id": "sec-intro",
      "title": "مقدمة",
      "titleEn": "",
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

## Supported Block Types

| Type | JSON shape |
|---|---|
| `text` | `{"type":"text","order":1,"content":{"ar":"..."},"variant":"paragraph"}` |
| `execution_step` | `{"type":"execution_step","order":1,"stepNumber":1,"description":{"ar":"..."},"notes":{"ar":""}}` |
| `safety_note` | `{"type":"safety_note","order":1,"message":{"ar":"..."},"severity":"medium"}` |
| `table` | `{"type":"table","order":1,"headers":["عمود1","عمود2"],"rows":[{"cells":["قيمة1","قيمة2"]}]}` |
| `image` | `{"type":"image","order":1,"url":"assets/images/file_name.png","caption":{"ar":"تعليق","en":""}}` |

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

- Output MUST be valid JSON.
- Follow the existing Content Studio Draft JSON shape exactly (see `templates/arabic_topic_template.draft.json`).
- Use `"status": "draft"` — do NOT output app-ready JSON.
- Image blocks must use `"url": "assets/images/file_name.png"`.
- Captions: `"caption": { "ar": "...", "en": "" }`.
- Do NOT use absolute paths or backslashes.
- Do NOT use unsupported block types.
- Every section needs a unique `id` (e.g., "sec-intro", "sec-execution").
- `_meta.id` and `topic.id` must match.
- `_meta.schemaVersion` must be "1.0.0".
- Arabic fields should be filled; English fields can be empty unless structurally required.
- Order blocks sequentially within each section.
- Add `"titleEn": ""` for sections even if empty.

## What Not to Do

- Do NOT output app-ready JSON format.
- Do NOT include catalog entries.
- Do NOT generate the actual image files.
- Do NOT include any JavaScript, CSS, or HTML.
- Do NOT use markdown in JSON values.
- Do NOT use unsupported block types.
- Do NOT add extra fields not in the Draft JSON schema.
- Do NOT use `"step": {"ar": "..."}` for `execution_step` — use `"stepNumber"` + `"description": {"ar": "..."}` instead.
- Do NOT omit `stepNumber` on `execution_step` — preview will show `?` without it.
- Do NOT assume JSON validity alone means the block will render — verify each block's field names match what Content Studio expects.

## Prompt Template

```
أنت مبرمج JSON لتحويل المحتوى الهندسي إلى ملف Draft JSON متوافق مع Content Studio.

المحتوى المدخل:
[insert all approved content with sections, blocks, images, tables]

المطلوب:
- أنشئ ملف JSON صالحًا تمامًا وفق هيكل Content Studio Draft JSON.
- استخدم الأنواع المدعومة فقط: text, execution_step, safety_note, table, image.
- مسارات الصور: assets/images/file_name.png
- التعليقات: { "ar": "...", "en": "" }
- لا تستخدم مسارات مطلقة أو شرطات مائلة عكسية.
- status: "draft"
- لا تنتج JSON جاهز للتطبيق (App-ready).
- املأ الحقول العربية، واترك الإنكليزية فارغة إن لم تكن مطلوبة.
- مهم: execution_step يجب أن يستخدم stepNumber و description.ar — لا تستخدم "step".
  مثال صحيح: {"type":"execution_step","order":1,"stepNumber":1,"description":{"ar":"..."}}
```
