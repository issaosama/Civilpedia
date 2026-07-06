# Quality Assurance Checklist

Use this checklist to review every generated topic before the app owner opens it in Content Studio.

## Content Quality

- [ ] Content is technically reasonable and accurate.
- [ ] No unsupported exact values (loads, strengths, dimensions) are presented as fact without verification.
- [ ] Any code/standard references (ACI, ASTM, BS, EN, Iraqi Code) that are unverified are clearly marked with "(يحتاج تدقيق)".
- [ ] Iraqi site practice notes are practical and specific, not generic.
- [ ] All paragraphs are short and direct — no academic filler.
- [ ] Arabic text is clear and professional.
- [ ] English technical terms are used inline only where useful for clarity.

## Structure

- [ ] All sections have clear Arabic titles.
- [ ] The topic has a summary (summaryAr).
- [ ] The topic has a simple explanation (simpleExplanation.ar).
- [ ] Sections follow a logical flow.
- [ ] Block types are used appropriately (text for paragraphs, execution_step for steps, safety_note for safety, table for data, image for visuals).

## Images

- [ ] Every image has an Arabic caption.
- [ ] Image paths use `assets/images/` prefix.
- [ ] Image filenames are lowercase English, no spaces, no special characters.
- [ ] Image filenames use underscores for word separation.
- [ ] Image formats are png, jpg, jpeg, or webp only.
- [ ] No absolute paths (no C:\ or D:\).
- [ ] No backslashes in paths (use /).
- [ ] No unsupported formats (heic, svg, bmp, tiff, avif).
- [ ] Image briefs exist for every image referenced.

## Tables

- [ ] Tables are readable and simple (max 5-6 columns).
- [ ] Headers are in Arabic.
- [ ] Tables have at least one row of data.
- [ ] No merged cells or complex formatting.

## Checklists and Steps

- [ ] Execution steps are actionable and in order.
- [ ] Checklist items are practical for site use.
- [ ] Acceptance/rejection criteria are clear.

## Draft JSON

- [ ] JSON is valid (no syntax errors).
- [ ] All required top-level fields are present (_meta, topic, sections, review).
- [ ] All required topic fields are present.
- [ ] No unsupported block types are used.
- [ ] All IDs are unique (section IDs, topic ID).
- [ ] _meta schemaVersion matches "1.0.0".

## Content Studio Compatibility

- [ ] Draft opens in Content Studio without errors.
- [ ] Validation engine shows no errors (warnings about empty fields are acceptable).
- [ ] Preview looks good in light mode.
- [ ] Preview looks good in dark mode.

## Export

- [ ] Export App-ready JSON completes successfully.
- [ ] Exported JSON has the correct shape (topic + sections + blocks).

## Flutter App

- [ ] Topic displays correctly in the Flutter app.
- [ ] All blocks render properly.
- [ ] Images load from assets.
- [ ] Dark mode rendering is correct.

## Safety and Legal

- [ ] Safety notes are accurate and not misleading.
- [ ] No fabricated code clauses.
- [ ] No unsafe recommendations.
- [ ] Content is appropriate for the target audience (engineers, supervisors, contractors, students).
