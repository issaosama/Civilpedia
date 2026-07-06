# Content AI Pipeline — Workflow

## Full 15-Step Workflow

### Phase 1: Planning

**Step 1 — Topic Selection**  
App owner selects a civil engineering topic to produce.  
Input: Topic name in Arabic.  
Output: Topic ID and brief description.

**Step 2 — Planner Agent**  
Creates a detailed topic outline and content plan.  
Agent: `agents/01_planner_agent.md`  
Output: Outline with sections, key points, and content structure.

### Phase 2: Content Generation

**Step 3 — Engineering Writer Agent**  
Writes full Arabic civil engineering content following the STYLE_GUIDE.  
Agent: `agents/02_engineering_writer_agent.md`  
Output: Arabic text for all sections.

**Step 4 — Iraq Site Practice Agent**  
Reviews and adapts content for Iraqi construction site reality.  
Agent: `agents/03_iraq_site_practice_agent.md`  
Output: Critiqued content with Iraqi site notes.

**Step 5 — Code/Standards Checker Agent**  
Flags any values, numbers, or standards references that require verification.  
Agent: `agents/04_code_checker_agent.md`  
Output: List of flagged values needing verification.

**Step 6 — Checklist Agent**  
Creates practical site checklist and acceptance/rejection criteria.  
Agent: `agents/05_checklist_agent.md`  
Output: Structured checklists.

### Phase 3: Media and Format

**Step 7 — Image Brief Agent**  
Defines needed images, filenames, captions, and visual descriptions.  
Agent: `agents/06_image_brief_agent.md`  
Output: Image brief list following IMAGE_GUIDELINES.md.

**Step 8 — Content Studio JSON Agent**  
Converts all approved content into a Content Studio Draft JSON file.  
Agent: `agents/07_content_studio_json_agent.md`  
Output: `topic-name.draft.json`

### Phase 4: Quality Assurance

**Step 9 — Final QA Agent**  
Reviews the full topic package before it reaches the app owner.  
Agent: `agents/08_final_qa_agent.md`  
Output: QA report and pass/fail status.

**Step 10 — Content Studio Compatibility Agent**  
Verifies the draft JSON is compatible with Content Studio and Flutter app rendering.  
Agent: `agents/09_content_studio_compatibility_agent.md`  
Output: Compatibility status (PASS / NEEDS FIXES) with issue list.

### Phase 5: Review and Approval

**Step 11 — App Owner Opens Draft in Content Studio**  
The `.draft.json` file is loaded into Content Studio for visual review.  
Tool: `tools/content_studio/index.html`

**Step 12 — App Owner Reviews and Edits**  
The owner reads, modifies, and validates the content in Content Studio.  
Validation: Content Studio built-in validation engine.

**Step 13 — Export App-Ready JSON**  
After approval, the topic is exported as App-ready JSON.  
Tool: Content Studio file menu → Export.

### Phase 6: Integration

**Step 14 — Build Catalog**  
The catalog is rebuilt to include the new topic.  
Tool: `tools/content_studio/scripts/build_catalog_from_topics.js`

**Step 15 — Test in Flutter App**  
The topic is verified in the Flutter app in both light and dark mode.  
Command: `flutter run` (or `flutter build`)

### Distribution

After all checks pass, the new topic files are committed:
- `draft_jsons/topic-name.draft.json`
- `app_ready_jsons/topic-name.json`
- Updated catalog file
- Any new asset images

## Pipeline Diagram

```
Topic Selection
      │
      ▼
┌─────────────────┐
│  Planner Agent  │  Step 2
└────────┬────────┘
         ▼
┌─────────────────────┐
│ Engineering Writer  │  Step 3
└────────┬────────────┘
         ▼
┌─────────────────────────┐
│ Iraq Site Practice      │  Step 4
└────────┬────────────────┘
         ▼
┌──────────────────────┐
│ Code/Standards Check │  Step 5
└────────┬─────────────┘
         ▼
┌──────────────────┐
│ Checklist Agent  │  Step 6
└────────┬─────────┘
         ▼
┌─────────────────────┐
│ Image Brief Agent   │  Step 7
└────────┬────────────┘
         ▼
┌──────────────────────────┐
│ CS JSON Agent            │  Step 8
└────────┬─────────────────┘
         ▼
┌──────────────────────────────┐
│ Final QA Agent               │  Step 9
│ Compatibility Agent          │  Step 10
└────────┬─────────────────────┘
         ▼
┌───────────────────────────┐
│ App Owner Review (CS)     │  Steps 11-13
└────────┬──────────────────┘
         ▼
┌──────────────────┐
│ Build + Test     │  Steps 14-15
└──────────────────┘
```

## Quality Gates

| Gate | Check | Blocking? |
|---|---|---|
| Content Studio Validation | No errors in validation engine | Yes |
| Final QA Report | All items pass | Yes |
| Compatibility Check | Status = PASS | Yes |
| App Owner Review | Owner approves | Yes |
| Flutter App Test | Displays correctly | Yes |
