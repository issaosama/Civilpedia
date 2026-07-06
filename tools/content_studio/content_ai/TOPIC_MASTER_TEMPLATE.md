# Topic Master Template

Each Civilpedia topic follows this standard structure.

## Recommended Topic Structure

```
1. Topic Title           — العنوان بالعربية
2. Short Summary         — summaryAr (2-3 جمل)
3. Simple Explanation    — simpleExplanation.ar
4. Why It Matters on Site  — أهمية الموضوع في الموقع
5. Required Tools/Equipment — الأدوات والمعدات المطلوبة
6. Execution or Inspection Steps — خطوات التنفيذ أو الفحص
7. Acceptance / Rejection Criteria — معايير القبول والرفض
8. Common Mistakes       — الأخطاء الشائعة
9. Safety Notes          — ملاحظات السلامة
10. Practical Checklist  — قائمة فحص عملية
11. Tables (if useful)   — جداول مقارنة أو قيم مرجعية
12. Image Briefs         — وصف الصور المطلوبة
13. Notes Needing Verification — نقاط تحتاج تدقيق هندسي
14. Final QA Checklist   — قائمة فحص المراجعة النهائية
```

## Mapping to Content Studio Block Types

| Template Section | Content Studio Block Type | Notes |
|---|---|---|
| Topic Title | topic.titleAr | Field in topic metadata |
| Short Summary | topic.summaryAr | Field in topic metadata |
| Simple Explanation | topic.simpleExplanation.ar | Field in topic metadata |
| Why It Matters on Site | text | type: "text", variant: "paragraph" |
| Required Tools/Equipment | text + table | List as text or table block |
| Execution Steps | execution_step | type: "execution_step" |
| Acceptance / Rejection | text | Can use acceptRejectItems pattern |
| Common Mistakes | text | type: "text", variant: "paragraph" |
| Safety Notes | safety_note | type: "safety_note" |
| Practical Checklist | text | Bullet list as text block |
| Tables | table | type: "table" |
| Image Briefs | image | type: "image" (url + caption) |
| Notes Needing Verification | text | Mark clearly with "(يحتاج تدقيق)" |

## Block Type Reference

| Block Type | JSON `type` | Description |
|---|---|---|
| Text | `"text"` | Free text paragraph, variant: "paragraph" |
| Execution Step | `"execution_step"` | Single step in a procedure |
| Safety Note | `"safety_note"` | Safety alert, severity: "low"/"medium"/"high" |
| Table | `"table"` | Tabular data with headers and rows |
| Image | `"image"` | Image block with url and caption |

## Minimal Required Fields

- `topic.titleAr` — Arabic title
- `topic.categoryId` — Category (e.g. "concrete", "steel", "general")
- `topic.summaryAr` — Arabic summary
- `topic.level` — "basic", "intermediate", or "advanced"
- `topic.status` — Must be "draft"
- At least one section with at least one block
- `review.status` — "draft"

## Section Type Options

| Type | Usage |
|---|---|
| `general` | General explanatory content |
| `execution` | Execution or construction steps |
| `inspection` | Inspection or testing content |
| `safety` | Safety-related content |
| `equipment` | Tools and equipment lists |
| `code_reference` | Standards and code references |
