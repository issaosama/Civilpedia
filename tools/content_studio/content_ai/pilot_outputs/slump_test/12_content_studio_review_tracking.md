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

The draft is valid JSON, uses only supported block types, has passed both final QA and compatibility checks, and has the correct `execution_step` field names (`stepNumber` + `description.ar`) — no "لا يوجد محتوى" in editor and no "?" in preview.

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

**Important:** Verify that execution_step blocks render correctly (this was broken in PILOT-1 and fixed in PILOT-4):
- [ ] Expand the execution section ("طريقة الاختبار")
- [ ] Confirm each step shows visible text (not "لا يوجد محتوى")
- [ ] Switch to preview and confirm each step shows a number and description (not "?")

Then proceed with full review:

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

## Execution Step Fix (CONTENT-AI-PILOT-4)

The `execution_step` blocks in both drafts were using `"step": {"ar": "..."}` which Content Studio does not support. This caused:
- **Editor**: "لا يوجد محتوى" (empty render)
- **Preview**: `?` placeholder instead of step number

**Fix applied** (0639adc): Changed all 6 blocks to use `"stepNumber"` (number) + `"description": {"ar": "..."}`.
Both draft files (`draft_jsons/slump_test.draft.json` and `07_slump_test.draft.json`) were updated.

Agent docs (`07_content_studio_json_agent.md`, `09_content_studio_compatibility_agent.md`) and `QA_CHECKLIST.md` now include explicit warnings about this requirement.

## Pipeline Commit History

| Commit | Message | Phase |
|--------|---------|-------|
| `080e4fb` | Add Slump Test AI pilot content package | CONTENT-AI-PILOT-1 |
| `e55fcb9` | Review Slump Test pilot production readiness | CONTENT-AI-PILOT-2 |
| `651da13` | Promote Slump Test draft for Content Studio review | CONTENT-AI-PILOT-3 |
| `0639adc` | Fix execution_step blocks + update agent docs | CONTENT-AI-PILOT-4 |
