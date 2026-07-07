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
- [ ] Cover image meets 16:9 aspect ratio (recommended 1600×900, minimum 1200×675).
- [ ] Article images meet preferred 4:3 ratio (1200×900) or alternative 16:9 (1200×675).
- [ ] Diagrams use 4:3 ratio (1200×900) with clean labels and high contrast.
- [ ] Tall process images (3:4, 900×1200) used only when essential.

## Cover Image

- [ ] Content Studio's "اختيار صورة" button in topic metadata opens a file picker, sanitizes filename (lowercase, no spaces, no special chars), prepends `assets/images/`, and sets `coverImageUrl`.
- [ ] `coverImageUrl` is optional — no error if empty.
- [ ] If `coverImageUrl` is present, path starts with `assets/images/`.
- [ ] Cover image format is png, jpg, jpeg, or webp.
- [ ] Cover image path has no absolute paths, no backslashes, no spaces.
- [ ] Cover image is distinct from section image blocks (topic-level field).
- [ ] Missing cover image file does not crash preview or app.
- [ ] Cover image important content is centered (edges may be cropped in 16:9).
- [ ] No text or critical detail near cover image edges.

## Tables

- [ ] Tables are readable and simple (max 5-6 columns).
- [ ] Headers are in Arabic.
- [ ] Tables have at least one row of data.
- [ ] No merged cells or complex formatting.

## Checklists and Steps

- [ ] Execution steps are actionable and in order.
- [ ] Execution steps use the correct Content Studio shape:
  - `stepNumber` (number) — required, or preview shows `?`
  - `description.ar` (string) — required, or editor shows "لا يوجد محتوى"
  - Do NOT use `"step": {"ar": "..."}` — this field is ignored by Content Studio
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

## Mandatory Visual QA (Renderability)

These checks must be done by opening the draft in Content Studio and visually inspecting it.
JSON validity alone is NOT sufficient — a block can be valid JSON but render as empty.

- [ ] **Open the draft in Content Studio** (`index.html` → File → Open).
- [ ] **Expand every section** and confirm every block shows visible content.
- [ ] No block should display **"لا يوجد محتوى"** in the editor.
- [ ] **Switch to preview** and confirm no block shows **"?"** as a placeholder.
- [ ] Verify every `execution_step` block shows its step number and description text.
- [ ] Verify every `safety_note` block shows its message.
- [ ] Verify every `text` block shows its content.
- [ ] Verify every `table` block shows headers and row data.
- [ ] Verify every `image` block shows a path (even if the file is missing).
- [ ] Confirm that a supported block type alone is not enough — the correct field names must be present.

## Export

- [ ] Export App-ready JSON completes successfully.
- [ ] Exported JSON has the correct shape (topic + sections + blocks).

## Flutter App

- [ ] Topic displays correctly in the Flutter app.
- [ ] All blocks render properly.
- [ ] Images load from assets.
- [ ] Dark mode rendering is correct.
- [ ] Cover image displays at 16:9 crop in Flutter hero section.
- [ ] Article images display with contain fit (full image visible, no cropping).
- [ ] Content Studio cover preview matches Flutter cover display (same crop, same border-radius).
- [ ] Content Studio article preview matches Flutter article image display (same fit behavior).

## Safety and Legal

- [ ] Safety notes are accurate and not misleading.
- [ ] No fabricated code clauses.
- [ ] No unsafe recommendations.
- [ ] Content is appropriate for the target audience (engineers, supervisors, contractors, students).
