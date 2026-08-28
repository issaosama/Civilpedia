# CIVILPEDIA — MY PROJECTS MASTER ARCHITECTURE

**Phase:** M5. **Status:** ARCHITECTURE / DOCUMENTATION ONLY — no production code changed.
**Inputs (approved):** `CIVILPEDIA_PRODUCT_ARCHITECTURE.md` (M1), `CIVILPEDIA_SCREEN_MAP.md` (M2), `CIVILPEDIA_NAVIGATION_ARCHITECTURE.md` (M3), `CIVILPEDIA_DATA_OWNERSHIP_AND_DOMAIN_CONTRACTS.md` (M4), plus live inspection of the current Partial Projects functionality.

> This designs the complete long-term My Projects domain. It does not rewrite the current functionality — it re-parents ownership and layers on the persistent workspace. No production change, no data migration run, no schema/content change.

---

## 1. Purpose

Design My Projects as the engineer's **persistent working space** inside Civilpedia — integrating Knowledge, Tools, Checklists, Inspections, Directory, Saved, Attachments, and Reports — while respecting M4 ownership so Projects never becomes a God feature and never takes ownership of other domains' data or logic.

---

## 2. Product Role

Target workflow:
```
Engineering problem → Knowledge → Tool / Calculator / Checklist → Result / execution
→ Save to Project → Project record → Notes / Photos / Documents → Supplier/Service → Report / historical record
```
My Projects makes Civilpedia useful **repeatedly** during real engineering/site work: a place where a one-off calculation or checklist becomes a durable, discoverable, documented project history.

---

## 3. Current Projects Baseline (verified)

Real, not new. Currently embedded under the **Tools** feature.

| Component | Path | Reality |
|---|---|---|
| `Project` model | `lib/features/tools/domain/checklist/entities/project.dart` | `{id, name, createdAt, updatedAt, isArchived}` + `copyWith`. Minimal. |
| `ProjectRepository` (interface) | `lib/features/tools/domain/checklist/project_repository.dart` | `loadProjects/createProject/updateProject/archiveProject/deleteProject` |
| `LocalProjectRepository` | `lib/features/tools/data/checklist/local_project_repository.dart` | In-memory cache; SharedPreferences `projects_list`; ID `project_<micros>_<rand>`; no `restore` method |
| `ProjectLocalDataSource` | `lib/features/tools/data/checklist/project_local_data_source.dart` | SharedPreferences key `projects_list` |
| `ProjectListScreen` | `lib/features/tools/presentation/screens/checklist/project_list_screen.dart` | Filters archived out; create/rename/archive/delete (dialog-confirmed); opens `ChecklistScreen(project:)` via `Navigator.push`; delete clears `checklist_project_<id>` first |
| `ChecklistScreen(project:)` | `.../checklist_screen.dart` | Project-scoped checklist input/output via `checklist_project_<projectId>` |
| `ChecklistRepository`/`LocalChecklistRepository` | `.../domain/checklist/`, `.../data/checklist/` | Global `checklist_data` + per-project `checklist_project_<id>` |
| Backup | `lib/core/backup/backup_service.dart` | buildBackup includes projects + projectChecklists; restore partial (`TODO(BACKUP-1C)`) |
| DI | `lib/core/di/app_dependencies.dart` | `_projectRepo`/`_checklistRepo` constructed, fed to `BackupService`; getters otherwise unread; UI self-instantiates duplicates |

**Current lifecycle semantics:** Active (implicit) / Archived (`isArchived=true`) / Deleted (hard delete after confirmation). No unarchive/restore API exists today (one-way archive). The list hides archived projects; there is no archived view. **Target: Restore is a V1 requirement** (§6) so archive is reversible.

**Flags (verified, not fixed):**
1. `Project` is minimal — no code/description/location/client/type/status/dates.
2. No `restoreProject` in the repo interface today (archive is one-way in today's API; `copyWith(isArchived:false)` is possible but unused) — **flagged as a required V1 addition** (§6), exact API is implementation detail.
3. UI constructs `LocalProjectRepository` (project_list_screen.dart:25) and a transient `LocalChecklistRepository` for delete (project_list_screen.dart:108) — duplicate instantiation (M4 §26 #2).
4. Project-scoped checklist key `checklist_project_<id>` is a runtime SharedPreferences literal (M4 §26 #13).
5. `updateProject` exists but only used for rename.

---

## 4. Ownership Boundary (approved M4)

**Tools owns:** calculator definition/formula, tool definition, checklist template, checklist item definition, inspection template, reusable engineering logic.

**Projects owns:** Project, project metadata, saved calculation snapshot, project checklist execution, project inspection record, project notes, project attachment/document metadata, project material records, project-specific supplier/service **references**, project reports, project activity/history.

**Projects must NOT own:** Content Studio topics, calculator formulas, checklist templates, Directory supplier profiles, advertisement campaigns.

---

## 5. Project Entity

Keep V1 practical. Separate **CORE** from **OPTIONAL** fields.

**CORE (V1):**
- `projectId` (stable, synthetic — continue `project_<micros>_<rand>` scheme or a stable UUID; do not renumber existing rows)
- `name`
- `status` (see §6)
- `createdAt`, `updatedAt`
- `archivedAt` (nullable; present only when archived)

**OPTIONAL metadata (later):** optional project code/reference, description, location, client, contractor, consultant, project type, start date, optional completion date. None required for V1; add on product value. Do **not** include every possible construction field.

Keep backward-compatible reading: existing rows lack optional fields → default gracefully.

---

## 6. Project Lifecycle

Conceptual states — be economical:

| State | Needed? | Notes |
|---|---|---|
| Active | ✓ (default) | Current working project |
| Archived | ✓ (exists today) | Soft retention |
| Paused | Optional (defer) | Only add if real need; V1 omits |
| Completed | Optional (defer) | Semantic; can be a `status` tag, not a new engine |
| Deleted | ✓ (hard delete only) | Confirmed destructive action; **not** the normal V1 path |

**Approved V1 lifecycle path (owner decision):**
```
Active project
→ Archive
→ Archived state
→ Restore (back to Active)
```
**Restore is a V1 requirement.** Archive without Restore is not an acceptable complete lifecycle. The exact `restoreProject` implementation API is a future implementation detail — it is **not** an unresolved product decision (see §36).

Operations:
- **Create** — real today.
- **Edit** — rename today; extend to optional metadata later.
- **Archive** — real today.
- **Restore** — **required for V1**; archive is reversible (no hard loss). Missing today's repo interface; the exact API is implementation detail.
- **Delete (hard)** — may remain available, **only** as a carefully confirmed destructive action. Archive/Restore is the normal lifecycle path; Delete is not.

**Soft/archive semantics:** Deletion must not silently destroy project history. **Archive is the primary "remove from active" action, Restore is the return path; hard delete is explicit + confirmed** (today it confirms). Consider treating hard delete as permanently removing the project + its execution records only after an explicit warning. Never a bare unstaged delete. **Do not auto-delete `checklist_project_<id>` unless that is the intended irreversible action, and only with the current explicit confirm.**

---

## 7. Project Workspace

One workspace, not 12 equal tabs. The workspace should answer:
1. What is happening? → Overview
2. What did I calculate/check? → Calculations / Checklists / Inspections
3. What needs attention? → Overview flags (incomplete checklists, failed/failed items)
4. What records/files belong here? → Notes / Attachments (photos/documents)
5. Who/material/service is linked? → Suppliers/Services / Materials

Recommended structure: **One Project Workspace screen with an internal tab/section model** — not a top-level route per subsection. Deep-linkable subsections only for the high-value ones (calculations, checklists, inspections, reports — M3 §10). Frequent actions reachable quickly from Overview.

Prioritize frequent engineering actions (calculate again, complete checklist, add note, add photo) over breadth.

---

## 8. Overview

Overview is a **projection** — it shows, it does not own:
- project name/status
- recent activity (§18)
- recent calculations (§9)
- incomplete checklists (§10) — attention flags
- recent inspection records (§11)
- notes (recent), documents/photos count
- linked suppliers/services
- quick actions (new calculation → Tools save; new checklist; add note; add attachment)

Do not overload; Overview surfaces precomputed/aggregated summaries from the owning sub-records, read via the project domain contract (§25/§31), never by importing other domains' repositories.

---

## 9. Calculation Records

Approved pattern: formula/session → Tools; **Save to Project → Projects stores a historical snapshot**.

Conceptual `ProjectCalculationRecord`:
- `recordId`, `projectId`
- `sourceToolId` (stable ToolKey, typed contract — M4 §16/Knowledge→Tools)
- `sourceToolVersion` / schemaVersion
- `calculationType`
- `inputSnapshot` (the user's inputs)
- `resultSnapshot` (derived result)
- `units`
- optional `title`/`note`
- `createdAt`, optional `createdBy` (when accounts exist)

**Historical rule:** Updating calculator logic later must **not** silently rewrite an old record. Do **not** store the formula implementation inside Project — store the snapshot of inputs → result. Rendering an old record may note it used `tool` v-version but never recompute it from live state.

---

## 10. Checklist Executions

Approved: template → Tools; **execution for a project → Projects**.

Conceptual `ProjectChecklistExecution`:
- `executionId`, `projectId`
- `templateId`, `templateVersion`
- `executedItemSnapshot` (item set + status/notes at execution time — the items are copied as **executed snapshot**, not live references)
- `status`/`result` (e.g. incomplete / passed / failed / with NA)
- `notes`
- `startedAt`/`completedAt`
- optional `attachments`

**Multiple executions allowed** — real site workflows re-run a checklist (e.g. weekly slab inspection). Do **not** model as one permanent boolean state per project. This differs from the current single project-scoped `checklist_project_<id>` state; migration treats the current data as the **first/latest execution of the relevant template**, normalized without loss (§29).

---

## 11. Inspection Records

Pattern: Inspection Template → Tools; **Inspection Record → Projects**.

**Inspection Record vs Checklist Execution:** shared concepts (template of items/steps → executed snapshot with status) but real differences:
- Inspection records often carry **critical/NA semantics, outcomes/acceptance** and may attach to a built element/date more rigorously.
- A checklist execution is a pass/fail/NA working sheet; an inspection record is a more formal, dated, recorded outcome (often reportable).

**Recommendation:** model them on a **common execution core** (shared `item → status/notes snapshot`), but keep **two named record types** (`ProjectChecklistExecution` and `ProjectInspectionRecord`) so their distinct semantics and report outputs are not blurred. Do not force them together merely to reduce files; do not duplicate the shared core either.

Current `InspectionItem/InspectionCategory` (presentation, seeded) are the seed of the Tools-owned template; project data persists only status/notes, which matches execution-snapshot semantics.

---

## 12. Notes

Lightweight project-owned records. Conceptual `ProjectNote`:
- `noteId`, `projectId`
- `text`
- optional `category`/`tag` (e.g. site, client, supplier)
- `createdAt`, `updatedAt`
- optional `linkedRecordId` (e.g. attach a note to a calculation/checklist/inspection)

Avoid building a full document editor — plain/multiline text with optional lightweight tags.

---

## 13. Attachments / Documents / Photos

One coherent attachment concept:

Conceptual `ProjectAttachment`:
- `attachmentId`, `projectId`
- `type` (photo, PDF, document, report)
- local/remote reference (path/URI or future cloud ref)
- `displayName`
- `metadata` (mime, size, dimensions for photos)
- `createdAt`
- optional `linkedRecordId`

Guidance:
- **Do not decide backend/storage vendor now** (M4 §20: local-first, remote sync later).
- **Do not store raw binary inside Project entities** — store a reference/URI; binary lives in a storage layer (future).
- Supports future photos/PDFs/documents/reports uniformly.

---

## 14. Materials

Clarify meaning to avoid duplicating Directory/Product catalog.

- **Directory Product / Material** = external authoritative listing (Directory-owned).
- **ProjectMaterialRecord** = project-specific tracking (Projects-owned): material name/reference, quantity, unit, status, note, optional supplier reference.

Clearly separate **Directory Product** vs **Project Material Record**. A project material may optionally reference a Directory product (`productId`) but is not a copy of the catalog.

---

## 15. Supplier / Service References

Approved: **Directory owns the supplier/service entity; Project stores a reference.**

Conceptual `ProjectSupplierReference` / `ProjectServiceReference`:
- `supplierId`/`serviceId` (Directory ID)
- `linkedAt`
- `note`
- project-specific contact/reference
- `selectedMaterialOrService`

Do **not** copy the full supplier profile. If the supplier disappears from Directory, keep the reference + a graceful unavailable state; project history stays understandable (name/display may be held as a light display snapshot to keep the record readable, but Directory remains authoritative — M4 §22, §14).

---

## 16. Knowledge References

Optionally allow a project to reference useful knowledge (Topic, Article, Code/reference).

Preferred: **source-ID reference** (`topicId`/`articleId`/`codeReferenceId`), **not copied Content Studio JSON**. Conceptual `ProjectKnowledgeReference`:
- `referenceId`, `projectId`
- `entityType` (topic/article/code)
- `entityId`
- `titleSnapshot` (optional, lightweight, for offline/history readability)
- `addedAt`

**Decision:** defer `ProjectKnowledgeReference` beyond V1 unless repository evidence / product need justifies it. It is optional, not core.

---

## 17. Reports

Project Reports are Projects-owned. Conceptual model:

`ProjectReport` (generated artifact) and/or `ReportDefinition + generated artifact`:
- Report inputs are **project-owned historical data**: metadata, calculations, inspections, checklist executions, notes, attachments.
- **A report is generated from project-owned historical snapshots** — it must **not** read mutable current calculator state and rewrite history.
- Conceptual: `ProjectReport { reportId, projectId, defId?, generatedFromVersions, artifactRef, createdAt }`.

Do not generate against live mutable state (M4 §15: report embeds the snapshot it was generated from).

---

## 18. Activity

Lightweight, minimum-useful activity, **not enterprise audit**.

Conceptual `ProjectActivity` record:
- `activityId`, `projectId`
- `type` (e.g. `calculation_saved`, `checklist_completed`, `note_added`, `attachment_added`, `project_edited`)
- `entityType`/`entityId` (optional)
- `summary` (e.g. "Concrete volume calculation saved")
- `createdAt`

Keep it a bounded, append-only local list per project for Overview "recent activity". No audit-infrastructure bloat.

---

## 19. Current Project Selection

Optional **Current / Active Project** (single selection) used by Home, Tools "Save to Project", Quick Actions.

Decision: **recommend a lightweight `currentProjectId` user preference/state** — owned by **User/preferences or Projects selection state**, NOT a second Project owner. It is a pointer, not a new entity (M4 ownership intact).
- No projects → `currentProjectId` null.
- Selecting a project in Projects list sets it (fast default for Save-to-Project).

V1 may omit this; it becomes valuable once Save-to-Project exists. Document that it is preference state.

---

## 20. Save-to-Project Contract

Future flow `Tool Result → Save to Project` — define domain/navigation contract, **no UI**:

- **No projects** → offer Create Project / cancel.
- **One project** → choose current project or simple selector.
- **Multiple projects** → project selector.
- **Current project available** → fast default + ability to change.

Contract: Tools emits a result payload (`sourceToolId`, type, inputSnapshot, resultSnapshot, units, timestamp) through an explicit **`ProjectWorkspaceGateway`** (M4 §16/§18) — Tools must **not** import `LocalProjectRepository` directly. The contract persists only after the user opts in; Tools never writes project persistence unbidden.

---

## 21. Offline / Local Persistence

Current: SharedPreferences local persistence. **Target principle:** the Projects domain should **not depend permanently on SharedPreferences API**.

Define a **repository contract** that allows Local now / Remote sync later **without rewriting UI/domain**:
```
ProjectRepository (interface) → [LocalProjectRepository now | RemoteRepository later]
```
Same for checklist executions, notes, attachments metadata, reports. UI depends on the interface; persistence backend is swappable (M4 §20).

---

## 22. Future Sync

Document conceptual concerns (no sync engine design):
- local project IDs → remote IDs mapping
- conflict resolution (last-write-wins default, field-level where required)
- offline edits (queued)
- attachment upload queue (metadata + binary separately)
- historical records treated as immutable once created

No backend/Firebase schema selected in M4/M5.

---

## 23. Backup

Current `BackupService` includes Projects/Checklists (**partially** — restore gated by `TODO(BACKUP-1C)`; encyclopedia favorites omitted per M4 §26 #10).

Long-term expectation: **Backup should include project-owned records consistently** (projects + checklist executions + inspection records + notes + attachment metadata + reports; references resolve by ID). Avoid domain-specific manual backup logic scattered across UI — backup is a cross-domain infrastructure service calling each domain's repository contract (M4 §16), not UI-driven ad-hoc code.

Classify backup completeness as a **future migration requirement** (M4 §26 #10); not implemented.

---

## 24. Auth / Multi-User Extensibility

Do **not** implement collaboration. Architecture must not prevent future:
- project ownership (`ownerId`)
- project members
- shared project
- roles/permissions

Extensibility points only (no V1 complexity):
- Reserve an optional `ownerId`/`createdBy` field on `Project`/records (nullable).
- Keep `ProjectRepository` identity-agnostic so a future identity contract can scope it (M4 §23 User/Auth boundary).
- Do not add shared-project/roles to V1.

---

## 25. Search / Home Projections

- **Search:** Project search belongs to Projects. Expose a `SearchableProjectProjection` (id, name, status, type, summary) to Global Search. Search does **not** directly query private Project storage (M4 §11/§16).
- **Home:** expose `CurrentProjectSummary` / `RecentProjectActivity` projections to Home. Home must **not** import the Project repository implementation (M4 §12).

Both are read-only projections produced by the Projects domain.

---

## 26. Navigation (approved M3 concept)

```
/projects                 → Project List
/projects/new             → Create/Edit Project
/projects/:projectId      → Project Workspace
/projects/:projectId/...  → deep-linkable subsections (calculations, checklists, inspections, reports)
```
Use **one workspace architecture** (internal tabs) rather than 10 independent root screens. Deep links only for high-value subsections. Do **not** modify the router now.

---

## 27. Feature Visibility / Readiness

Projects is a future target Bottom Navigation domain. Rule: **Not production-ready → hidden.** Do not expose an empty Projects tab.

**Minimum readiness criteria** for My Projects to replace a current Bottom Navigation slot (a future owner decision):
1. Project List + Create/Edit + Overview functional.
2. Save-Calculation works end to end (Tools→Projects contract) OR intentionally scoped without it.
3. Project Checklist Executions normalized from legacy `checklist_project_<id>` (migration verified).
4. Notes functional (V1). Attachments (metadata) only if/when V1.5 is reached — not required for the V1 gate.
5. Legacy stored data migrated or safely readable; no data loss.
6. Search/Home projections present (or clearly deferred).
Until these hold, Projects stays hidden behind its current Tools-entered checklist surface.

---

## 28. V1 / V1.5 / V2 Roadmap

**FINAL APPROVED V1** (owner): Project List; Create Project; Edit Project; Archive Project; Restore Project; Project Overview; Save Calculation to Project; Project Calculation Records/History; Project Checklist Executions (multiple executions of the same checklist); Project Notes.

**FINAL APPROVED V1.5** (owner): Attachments/Photos/Documents; Inspection Records; Materials; Supplier/Service links; Current Project quick selection.

**V2+** (owner): Reports; Knowledge References; Cloud Sync; Collaboration/roles; advanced activity/history as appropriate.

| Capability | V1 | V1.5 | V2+ | Reason |
|---|---|---|---|---|
| Project List | ✓ | ✓ | ✓ | Core |
| Create Project | ✓ | ✓ | ✓ | Core |
| Edit Project | ✓ | ✓ | ✓ | Rename now; optional metadata in V1.5 |
| Archive Project | ✓ | ✓ | ✓ | Soft retention (normal remove-from-active) |
| Restore Project | ✓ | ✓ | ✓ | Requirement — reversible archive (§6) |
| Project Overview (projection) | ✓ | ✓ | ✓ | Workspace anchor |
| Save Calculation to Project | ✓ | ✓ | ✓ | Core save-to-project |
| Project Calculation Records / History | ✓ | ✓ | ✓ | Historical snapshots |
| Project Checklist Executions (multiple) | ✓ | ✓ | ✓ | Normalize current data |
| Project Notes | ✓ | ✓ | ✓ | Lightweight, high value |
| Attachments / Photos / Documents | — | ✓ | ✓ | Storage/file-lifecycle/permissions/backup/sync concerns (owner: V1.5) |
| Inspection Records | — | ✓ | ✓ | Reuse execution core; formal records later |
| Materials | — | ✓ | ✓ | Project tracking |
| Supplier / Service links | — | ✓ | ✓ | Directory integration maturity |
| Current Project quick selection | — | ✓ | ✓ | Value with save-to-project (owner: V1.5) |
| Reports | — | — | ✓ | Depends on records |
| Knowledge References | — | — | ✓ | Optional; defer |
| Cloud sync | — | — | ✓ | Infrastructure later |
| Collaboration / roles | — | — | ✓ | Future extensibility |
| Advanced activity / history | — | — | ✓ | Richer history as appropriate |

---

## 29. Current Data Migration

Must **not be a rewrite** and must **not** follow a big-bang path.

Conceptual migration:
```
Existing Project entity / repository / data
→ stabilize (keep contract)
→ move ownership boundary to Projects (re-parent code, keep behavior)
→ preserve stored data (no key rename/delete)
→ introduce Projects feature (list/workspace/records)
→ migrate navigation (Projects tab only when ready, §27)
→ remove legacy Tools coupling ONLY after verification
```

Steps anchored to facts today:
- `ProjectRepository`/`LocalProjectRepository` already have a clean interface — reuse, re-parent under Projects domain.
- Keep `projects_list` data; add optional fields with defaults (read-old-gracefully).
- Normalize current project checklist state: today `checklist_project_<id>` holds a single status/notes set → becomes the **first/latest `ProjectChecklistExecution`** of the relevant template, preserving status/notes per item. Explicit verify step before retiring the legacy reader.

---

## 30. Persisted Data Safety (non-negotiable)

Current stored keys: `projects_list`, `checklist_project_<id>` (SharedPreferences).

Rules:
- Any migration must **preserve real user data**.
- **Read legacy format → migrate/normalize safely → verify → only later retire legacy key/reader.**
- **Never simply rename/delete storage keys.**
- Keep a reader for the legacy format until all data is verified migrated.
- No silent destruction of project/documents/records.

---

## 31. Public Contracts (only genuinely useful — no explosion)

- `ProjectCatalog` — project list/create/edit/archive/restore.
- `ProjectWorkspaceGateway` — the **only** way Tools writes calculation/checklist/inspection into Projects (§20).
- `ProjectRecordStore` — versioned execution/record repository (by template/type).
- `ProjectSummaryProvider` — projections for Home/Search (§25).
- `ProjectSearchableProjection` — to Global Search.

Tools needs only the explicit Save-to-Project contract; Home needs only projections; Search needs only searchable projections; Directory integration uses stable references (M4 §16/§18). No interface explosion / no wrapping everything.

---

## 32. Versioning

Version/schema metadata required for history-meaningful records; **not** for trivial notes:
- calculation snapshots → `sourceToolVersion`/schemaVersion (§9)
- checklist execution → `templateVersion` (§10)
- inspection record → template version (§11)
- report generation → `generatedFromVersions` (§17)
- attachments/notes/materials → no versioning needed

---

## 33. Error / Recovery States

Prefer explicit, recoverable states; never silently delete data:
- **Project not found** → Project-NotFound with return to list (M3 §22).
- **Archived project** → distinguish from deleted; offer restore or view.
- **Broken supplier reference** → unavailable placeholder, keep reference (§15).
- **Failed attachment** → retry/queued state, never silent loss.
- **Failed save (Save-to-Project)** → preserve the tool session; give user retry/create-project.
- **Legacy data read failure** → keep legacy reader fallback; do not overwrite.
- **Partially migrated project** → continue with safe defaults; flag migrate-incomplete but never delete.

---

## 34. Security / Privacy

Projects may hold private engineering information. Principles:
- Project data is **private by default**.
- No advertising system may inspect project content for targeting unless an explicit future privacy design permits it.
- Directory does **not** read project internals.
- Attachments require controlled access.
- Analytics should avoid capturing sensitive document content (M4 §23 auth boundary; M5 privacy).

No backend implementation.

---

## 35. Monetization Boundary

- **Do not place ads inside sensitive Project records/workspace in a way that disrupts engineering use.**
- My Projects is primarily a productivity/private workspace.
- Any future monetization there is separate and conservative.
- **Default recommendation: no intrusive project-workspace advertising.**

---

## 36. Open Decisions

1. **Project entity field set** — exact CORE vs OPTIONAL metadata; V1 keeps minimal.
2. **Current Project selection** — in V1.5 per owner; confirms quick-selection timing (tied to Save-to-Project).
3. **Inspection vs checklist execution** — confirm common-core + two-record-type model vs merging (recommended: two types, shared core).
4. **Legacy data normalization** — exact mapping of single `checklist_project_<id>` set → multiple executions/timestamping.
5. **Attachment storage** — local path vs cloud ref placeholder until sync phase (relevant at V1.5).
6. **Backup completeness scope** — which project records join backup first.
7. **Readiness gate ordering** — which criteria gate the bottom-nav slot (§27).

**Resolved (no longer open):** Restore is a **V1 lifecycle requirement** (§6). Its exact implementation API is future implementation detail, not a product decision.

---

## 37. Non-Negotiable Rules

1. Clean ownership (Projects owns records, not Tools formulas/templates/Directory/Ads/Knowledge). 2. Tools→Projects writes only via the explicit save contract. 3. Content Studio and engineering content untouched. 4. **Preserve current stored Project data** — migrate safely, never rename/delete keys. 5. Offline-first; persistence backend swappable behind interface. 6. No big-bang rewrite; staged migration with verification. 7. Historical snapshots stay immutable (no silent recompute). 8. Projects not exposed until ready (NOT READY → HIDDEN). 9. No intrusive project-workspace advertising. 10. Home/Search consume projections, never private repos. 11. Directory owns profiles; Projects holds references.

---

## Required Tables

### Project Record Ownership Table

| Record | Owner | Source | Mutable? | Historical Snapshot? | Version Required? | Offline? | Notes |
|---|---|---|---|---|---|---|---|
| Project (core) | Projects | Projects | Yes | No | No | Yes | Local now, sync later |
| Project optional metadata | Projects | Projects | Yes | No | No | Yes | Deferred fields |
| Project note | Projects | Projects | Yes | No | No | Yes | Lightweight |
| Project attachment metadata | Projects | Projects | No | No | No | Yes (ref) | Binary separate |
| Calculation formula | Tools | Tools | No | n/a | Yes (sourceToolVersion) | n/a | Not stored in Project |
| Calculated/saved snapshot | Projects | Projects (from Tools result) | No | Yes | Yes | Yes | Immutable historical |
| Checklist template | Tools | Tools | No | n/a | Yes (templateVersion) | n/a | Not owned by Project |
| Checklist execution | Projects | Projects | Yes (until completed) | Yes (once recorded) | Yes | Yes | Multiple executions ok |
| Inspection template | Tools | Tools | No | n/a | Yes | n/a | |
| Inspection record | Projects | Projects | Yes (until finalized) | Yes (finalized) | Yes | Yes | Two-type model w/ shared core |
| Supplier/service reference | Projects | Directory (ref) | No | Display snapshot optional | No | Yes (ref) | Directory authoritative |
| Directory supplier profile | Directory | Directory | No | — | — | — | Not copied |
| Project material record | Projects | Projects (+optional product ref) | Yes | No | No | Yes | Distinct from Directory product |
| Project knowledge reference | Projects | Knowledge (ref) | No | Display snapshot optional | No | Optional | Deferred beyond V1 |
| Project report | Projects | Projects (from snapshots) | No | Yes | Yes (generatedFromVersions) | Yes | From historical, not live |
| Project activity | Projects | Projects | No | No | No | Yes | Append-only, lightweight |
| Current project selection | User/preferences | selection state | Yes | No | No | Yes | Pointer, not owner |

### V1 Feature Table
*(see §28 — consolidated in the roadmap table above.)*

### Current → Target Migration Table

| Current Component/Data | Current Owner/Location | Target Owner | Migration Strategy | Compatibility Requirement | Removal Gate |
|---|---|---|---|---|---|
| `Project` entity | Tools (`domain/checklist/entities/project.dart`) | Projects | Re-parent code; keep model + contract | Readers keep working | After navigation moved + verification |
| `ProjectRepository`/`LocalProjectRepository` | Tools (`data/checklist/`) | Projects | Reuse interface; move under Projects; keep SharedPreferences | Keep `projects_list` readable | After feature ready + tab exposed |
| `projects_list` data | Tools (SharedPreferences) | Projects | Keep key; read-old-gracefully; add optional fields with defaults | No key rename/delete | After full migration verified |
| `checklist_project_<id>` | Tools (SharedPreferences) | Projects | Normalize into first/latest `ProjectChecklistExecution` preserving status/notes | Keep legacy reader until verified | After execution migration verified |
| `ProjectListScreen` | Tools (reached via Navigator.push from checklist) | Projects (route `/projects`) | Produce as Projects list; add workspace | Old checklist flow still works during transition | After Projects ready + exposed |
| `ChecklistScreen(project:)` | Tools | Tools (produces execution) → Projects (stores record) | Keep checklist UI; route its output through save contract | Global + project checklist behavior preserved | After save contract + normalization |
| Backup projects/checklists | Infrastructure (`BackupService`) | Infrastructure (calls Projects repo) | Complete backup of project records | Existing backups remain importable | After backup completeness migration |

---

## Requirements Traceability (M5)

Confirmed covered: clean ownership (§4), Tools logic protected (§4/§37), Content Studio protected (§37), current stored Project data protected (§29–30), offline-first (§21–22), save-to-project (§20), calculations (§9), checklist executions (§10), inspections (§11), notes (§12), attachments (§13), materials (§14), suppliers/services (§15), reports (§17), Home integration (§25), Search integration (§25), future sync (§22), future collaboration extensibility (§24), privacy (§34), no intrusive advertising (§35), no big-bang rewrite (§29/§37).

---

## Protected / Forbidden (unchanged)

ZERO changes to: `lib/**`, `test/**`, `assets/**`, `draft_jsons/**`, `app_ready_jsons/**`, Content Studio, exporters, schemas, generated catalogs, `pubspec.yaml`, branding, and the approved M1–M4 docs. This phase created exactly one file: `docs/architecture/CIVILPEDIA_PROJECTS_ARCHITECTURE.md`. No material contradiction with M1–M4 was found (M5 is additive; the current stored format is safely migratable, so no STOP condition applied).
