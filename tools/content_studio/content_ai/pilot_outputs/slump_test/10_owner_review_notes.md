# 10 — App Owner Review Notes

## Topic: اختبار الهبوط — Slump Test

---

## Items the App Owner Must Personally Verify

### High Priority — Engineering Values

| # | Value | Location | Current Status | Action Required |
|---|-------|----------|----------------|-----------------|
| 1 | Cone dimensions: 300mm height, 200mm base, 100mm top | sec-tools table | Marked for verification | Confirm against ASTM C143 or project standard. These are standard dimensions but must match the contract specification. |
| 2 | Tamping rod: 16mm diameter, 600mm length | sec-tools table | Marked for verification | Confirm against project standard. |
| 3 | 25 strokes per layer | sec-procedure step 3, sec-checklist | Marked for verification | ASTM C143 specifies 25 strokes; some standards differ. Confirm per project specification. |
| 4 | Lift time: 3-7 seconds | sec-procedure step 5, sec-checklist | Marked for verification | ASTM C143 specifies 5 ± 2 seconds. Confirm. |
| 5 | Slump acceptance value table | sec-acceptance-values table | Marked for verification | **Critical.** These values must be verified against the Iraqi Code or the specific project design specifications. They are generic and may not match every project. |
| 6 | "15-20 دقيقة" time limit for fresh concrete | sec-common-mistakes | Marked for verification | Confirm against project specification. Some specs allow 30 minutes for ready-mix. |

### Medium Priority — Content Quality

| # | Item | Notes |
|---|------|-------|
| 7 | Checklist completeness | The checklist covers the key points but consider if any project-specific steps are missing. |
| 8 | Iraqi site notes accuracy | Review the heat, water addition, and pumping notes for relevance to your specific project context. |
| 9 | Safety notes adequacy | Ensure the 5 safety notes cover the safety requirements of your site. Add respiratory protection if needed. |
| 10 | Language and tone | Read through all Arabic text. Ensure the tone matches Civilpedia's editorial standards. |

---

## Image Files Still Required

The draft references 4 images. These files do NOT exist yet and must be created or sourced before publication:

| # | Filename | Status | Suggested Source |
|---|----------|--------|-----------------|
| 1 | `assets/images/concrete_slump_cone.png` | ❌ Not available | AI-generated diagram or technical illustration |
| 2 | `assets/images/tamping_rod.jpg` | ❌ Not available | Original site photo or technical diagram |
| 3 | `assets/images/slump_measurement.jpg` | ❌ Not available | Original site photo (preferred) |
| 4 | `assets/images/slump_types.png` | ❌ Not available | Simple technical diagram |

**Action:** Obtain or create these images, add them to `assets/images/`, and verify the paths match.

---

## Suggested Wording Improvements

| Location | Current Text | Suggested Improvement | Priority |
|----------|-------------|----------------------|----------|
| sec-definition | "...النتيجة تعبر عن قوام الخرسانة Consistency وقابليتها للتشغيل Workability" | Consider splitting this into a separate sentence for clarity: "النتيجة تعبر عن قوام الخرسانة Consistency. هذا القياس يعطي مؤشرًا على قابلية تشغيل الخرسانة Workability." | Low |
| sec-common-mistakes | (single text block with 7 items) | Consider splitting into 2-3 shorter text blocks grouped by theme (preparation errors, execution errors, reading errors) | Low |

---

## Verification Workflow

When you open the draft in Content Studio:

1. **Load** `07_slump_test.draft.json` in Content Studio (`index.html`).
2. **Run validation** — confirm no errors appear.
3. **Preview in light mode** — read through all sections.
4. **Toggle to dark mode** — verify readability.
5. **Edit** any text that needs adjustment.
6. **Verify the flagged values** — remove "(يحتاج تدقيق)" markings once verified, or replace with confirmed values.
7. **Add image files** to `assets/images/` and update paths if needed.
8. **Approve and export** App-ready JSON.
9. **Build catalog** and test in Flutter app.

---

## Recommendation

**✅ Ready for Content Studio review.** No blocking issues remain.

All code-sensitive values are clearly marked for verification. The final QA and compatibility checks both pass. The owner should focus their review time on:

1. The slump acceptance values (Section 6) — most critical engineering decision.
2. Image file creation/sourcing.
3. Overall content quality and tone.
