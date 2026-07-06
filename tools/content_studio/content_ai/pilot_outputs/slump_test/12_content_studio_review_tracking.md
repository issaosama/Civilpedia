# 12 — Content Studio Review Tracking

## Topic: اختبار الهبوط Slump Test

---

## Promotion Details

| Item | Value |
|------|-------|
| **Source pilot draft** | `tools/content_studio/content_ai/pilot_outputs/slump_test/07_slump_test.draft.json` |
| **Review draft path** | `draft_jsons/slump_test.draft.json` |
| **Promotion date** | 2026-07-06 |
| **Previous draft (placeholder)** | `draft_jsons/slump-test.draft.json` (older, 5 sections, not replaced) |

## Current Status

**✅ Ready for Content Studio owner review**

The draft is valid JSON, uses only supported block types, and has passed both final QA and compatibility checks.

## NOT Ready for Final App Production Until

The following must be resolved before the topic can be exported, cataloged, and committed into production:

### 1. Engineering / Code-Sensitive Values Must Be Verified
All values with "(يحتاج تدقيق)" markings need owner review against the Iraqi Code or project specifications:
- Slump cone dimensions (300/200/100 mm) — in equipment table
- Tamping rod dimensions (16 mm / 600 mm) — in equipment table
- 25 strokes per layer — in procedure and checklist
- 3-7 seconds lift time — in procedure and checklist
- Slump acceptance value ranges (Section 6) — marked in table header
- "15-20 minutes" concrete age limit — in common mistakes

### 2. Required Image Files Must Be Added

| # | Filename | Status | Action Required |
|---|----------|--------|-----------------|
| 1 | `assets/images/concrete_slump_cone.png` | ❌ Missing | Create or source the image |
| 2 | `assets/images/tamping_rod.jpg` | ❌ Missing | Create or source the image |
| 3 | `assets/images/slump_measurement.jpg` | ❌ Missing | Create or source the image (site photo preferred) |
| 4 | `assets/images/slump_types.png` | ❌ Missing | Create or source the image (diagram) |

**Note:** If images cannot be provided in this phase, the image blocks in the draft JSON may be temporarily removed so the draft can still be previewed and the text content reviewed. Re-add image blocks when files are ready.

## Owner Review Checklist

When opening `draft_jsons/slump_test.draft.json` in Content Studio, complete these steps:

- [ ] Open the file in Content Studio (`tools/content_studio/index.html`)
- [ ] Run the built-in validation — confirm no errors
- [ ] Switch to light mode preview and read all sections
- [ ] Switch to dark mode preview and verify readability
- [ ] Review each "(يحتاج تدقيق)" marking and decide:
  - Accept the value as-is (remove the warning)
  - Replace with a verified value from the Iraqi Code or project spec
  - Flag for further engineering review
- [ ] Decide on image blocks:
  - Keep as-is with planned paths (images will be added later)
  - Or temporarily remove image blocks until files exist
- [ ] Make any final editorial wording adjustments
- [ ] Do **NOT** export to App-ready JSON until final approval is given

## Expansion Plan

Once this topic is approved and verified, the following next topics are candidates for the same pipeline:

1. اختبار المكعبات الخرسانية — Concrete Cube Test (pairs naturally with Slump Test)
2. المعالجة — Curing
3. الغطاء الخرساني — Concrete Cover
4. حدادة الأعمدة — Column Reinforcement

## Pipeline Commit History

| Commit | Message | Phase |
|--------|---------|-------|
| `080e4fb` | Add Slump Test AI pilot content package | CONTENT-AI-PILOT-1 |
| `e55fcb9` | Review Slump Test pilot production readiness | CONTENT-AI-PILOT-2 |
| *(this commit)* | Promote Slump Test draft for Content Studio review | CONTENT-AI-PILOT-3 |
