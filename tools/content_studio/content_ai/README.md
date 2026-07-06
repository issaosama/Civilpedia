# Content AI Pipeline — Civilpedia

## Purpose

This directory defines a structured **AI content production system** for generating
civil engineering encyclopedia topics for Iraq and the Middle East.

The pipeline uses multiple AI agents with specialized roles, each producing
a specific output that feeds into the next stage.

## Core Principle

**AI-generated content is NOT trusted automatically.**
Every topic must be opened in Content Studio, reviewed by the app owner,
validated, and approved before it becomes app-ready.

## How It Works

```
Topic Selection → AI Agent Pipeline → Draft JSON → Content Studio Review
→ App Owner Approval → Export → Flutter App
```

1. AI agents generate a complete topic package (Arabic text, images briefs,
   checklists, draft JSON).
2. The Final QA Agent reviews the package before it reaches the app owner.
3. The app owner opens the `.draft.json` in Content Studio.
4. The app owner reviews, edits, and approves the content.
5. Approved content is exported to App-ready JSON.
6. The catalog is rebuilt and the topic appears in the Flutter app.

## Target Audience

- Iraqi site engineers
- Supervisors and technicians
- Contractors
- Civil engineering students
- Anyone working on construction sites in Iraq and the Middle East

## Scope

- Civil engineering topics only.
- Content is in Arabic with English technical terms inline when useful.
- Standards references (ACI, ASTM, BS, EN) are used only where relevant and verified.
- Iraqi site practice is prioritized over generic international practice.

## Directory Structure

```
content_ai/
├── README.md                       ← This file
├── STYLE_GUIDE.md                  ← Arabic content writing style guide
├── TOPIC_MASTER_TEMPLATE.md         ← Standard topic structure template
├── WORKFLOW.md                     ← Full 15-step pipeline workflow
├── QA_CHECKLIST.md                 ← Final quality assurance checklist
├── IMAGE_GUIDELINES.md             ← Image format, naming, and brief rules
├── agents/
│   ├── 01_planner_agent.md
│   ├── 02_engineering_writer_agent.md
│   ├── 03_iraq_site_practice_agent.md
│   ├── 04_code_checker_agent.md
│   ├── 05_checklist_agent.md
│   ├── 06_image_brief_agent.md
│   ├── 07_content_studio_json_agent.md
│   ├── 08_final_qa_agent.md
│   └── 09_content_studio_compatibility_agent.md
└── examples/
    └── slump_test_outline_example.md
```

## Agent Overview

| # | Agent | Role |
|---|-------|------|
| 1 | Planner | Creates topic outline and content plan |
| 2 | Engineering Writer | Writes clear Arabic civil engineering content |
| 3 | Iraq Site Practice | Adapts content to Iraqi site reality |
| 4 | Code/Standards Checker | Flags unverified standards values |
| 5 | Checklist | Creates practical site checklist |
| 6 | Image Brief | Defines needed images, captions, descriptions |
| 7 | Content Studio JSON | Converts approved content to .draft.json |
| 8 | Final QA | Reviews full topic package |
| 9 | Content Studio Compatibility | Verifies compatibility with Content Studio and Flutter app |

## What This Pipeline Does NOT Do

- Does NOT generate production encyclopedia topics automatically.
- Does NOT modify Flutter app code.
- Does NOT modify Content Studio logic.
- Does NOT bypass the app owner's review.
- Does NOT generate App-ready JSON directly.
- Does NOT build the catalog.
- Does NOT commit to the repository without human approval.
