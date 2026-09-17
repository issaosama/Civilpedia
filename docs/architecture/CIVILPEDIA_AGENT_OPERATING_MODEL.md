# Civilpedia — Agent Operating Model

**Status:** Canonical repository SSOT for AI-agent roles and escalation  
**Purpose:** Prevent role drift across chats, IDEs, agents, and future sessions.  
**Rule:** If a chat-memory summary, ad-hoc prompt, or an agent's preference conflicts with this file, this file wins unless the user explicitly updates it.

## 1. Mandatory bootstrap order

Before planning or implementing substantial Civilpedia work, read in this order:

1. `docs/architecture/CIVILPEDIA_AGENT_OPERATING_MODEL.md` — role and escalation SSOT.
2. `docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md` — current phase/status SSOT.
3. The frozen contract for the current phase/slice.
4. The latest implementation/review report relevant to that slice.
5. `git status --short` and `git rev-parse HEAD`.

Never infer the current phase from old chat history when the roadmap is available.

## 2. Ownership model

### ChatGPT / GPT-5.6 Sol — Architect
Primary responsibility:
- architecture;
- phase/slice planning;
- contract freeze;
- scope boundary;
- prompt engineering;
- review interpretation;
- acceptance/closure decisions;
- model/agent routing.

Default review effort: **Medium**.  
Escalate to **High** for cross-cutting architecture, difficult race conditions, authority/identity issues, or major integrated gates.  
Do not use higher effort merely to repeat a review that already passed with sufficient evidence.

### Big Pickle — Routine Flutter Implementer
Use for:
- widgets and UI integration;
- localization;
- theme/RTL/responsive fixes;
- routine provider/controller work after the contract is frozen;
- deterministic tests;
- docs-only corrections;
- small root-cause bug fixes.

Do not use as the primary authority for security-sensitive auth/RLS/concurrency design.

### GitHub Copilot Agent — Routine Independent Reviewer + Secondary Implementer
Use for:
- read-only diff/source review;
- contract-boundary checks;
- focused test verification;
- small/medium implementation;
- test maintenance;
- PR-based isolated work.

Preferred first reviewer for routine slices when independence is useful and no security-sensitive adjudication is needed.

Repository Copilot must follow `.github/copilot-instructions.md` and the custom agents under `.github/agents/`.

### Kimi current coding default (`kimi-for-coding`)
Use the currently mapped model behind Kimi Code's `kimi-for-coding` ID for:
- routine-to-medium implementation;
- long-context code reading;
- medium multi-file changes;
- independent review;
- reserve capacity when Codex/Sol usage should be conserved.

As of 2026-09-15, official Kimi Code maps `kimi-for-coding` to **K2.8 Preview**. Re-check provider/model mapping if this file becomes old.

### Kimi K2.7 Code
Use for:
- long-horizon coding;
- medium multi-file implementation;
- codebase exploration;
- test-heavy work;
- secondary independent review;
- reserve implementation capacity.

It is an efficient coding specialist and should be preferred over K3 for ordinary coding when its quality is sufficient.

### Kimi K3 / K3-256k
K3 is a flagship coding and reasoning model even though its name does not contain the word `Code`.

Use **K3-256k** for:
- difficult multi-file refactors;
- large codebase reasoning that fits within 256k;
- stronger independent review;
- hard implementation where K2.x is insufficient.

Use **K3 (1M)** only when:
- more than 256k context is materially useful;
- a very large codebase/doc set must stay in one context;
- the task is unusually difficult and the extra quota/cost is justified.

Do not use K3 as the default routine reviewer or routine implementer.

### Codex — Critical Engineering Specialist
Reserve Codex for:
- Supabase/backend authority;
- Auth/session/recovery;
- RLS/security;
- concurrency and race conditions;
- migrations/schema;
- ownership/identity boundaries;
- architecture-sensitive implementations;
- difficult production bugs with high blast radius.

Codex should not be consumed for routine UI, localization, basic test maintenance, or ordinary docs work.

### Astra — Exceptional Architecture/Security Adjudicator
Use only for:
- unresolved contradictions in frozen contracts;
- high-risk identity/session/security design;
- ambiguous security/concurrency failures after ordinary review;
- exceptional independent adjudication where the strongest precision is justified.

Default: **High**.  
Use **Extra High** only for truly hard contradictions or security/identity state-machine problems.

### User — Git Owner
The user owns final:
- staging;
- commit;
- push;
- branch/merge decisions.

Agents must not stage, commit, or push unless the user explicitly authorizes it.

## 3. Default routing matrix

| Task | First choice | Escalation |
|---|---|---|
| Simple Flutter UI / localization / theme / RTL | Big Pickle | Copilot / Kimi coding default |
| Small deterministic bug fix | Big Pickle | Kimi coding default |
| Routine independent review | GitHub Copilot Reviewer | Sol Medium |
| Medium implementation across several files | Kimi coding default / K2.7 Code | Sol High or K3-256k |
| Large codebase exploration/refactor | K3-256k | K3 1M / Sol High |
| Directory/cache/data-flow implementation after freeze | Kimi coding default / K2.7 Code | Sol High / Codex if authority-sensitive |
| Backend/Supabase/RLS/Auth | Codex | Astra High |
| Concurrency/session/ownership race | Codex | Astra High/Extra High |
| Contract freeze / architecture plan | Sol High | Astra only if contradiction remains |
| Final ordinary slice review | Copilot Reviewer or Sol Medium | Sol High if findings are ambiguous |
| Final security-sensitive gate | Sol High / Codex | Astra High |
| Docs-only closure | Big Pickle / Copilot | none unless inconsistency appears |

## 4. Escalation policy

Use the cheapest/fastest competent agent first. Escalate because of **risk or demonstrated difficulty**, not because a stronger model exists.

Escalate when one or more applies:
- architecture crosses multiple domains;
- auth/security/identity/ownership is involved;
- a race or concurrency defect is plausible;
- the same focused correction fails twice;
- reviewers disagree on a material invariant;
- production data authority is unclear;
- schema/RLS/migration change is proposed;
- a high-blast-radius regression appears.

Do not escalate when:
- a routine review is green;
- the task is docs-only;
- the change is visual/localization-only;
- a focused test baseline is simply stale;
- the stronger model would only repeat already-valid evidence.

## 5. Review policy

- Implementer and reviewer should be independent where practical.
- Routine reviews default to Copilot Reviewer or Sol Medium.
- A PASS with adequate source inspection and focused green tests does not need to be repeated on a stronger model just for reassurance.
- HIGH or MEDIUM findings block acceptance.
- LOW findings may be non-blocking when they do not affect behavior or evidence.
- Never silently fix code during a read-only review.

## 6. Test policy

- Implementer: focused tests only.
- Reviewer: focused tests only unless the frozen gate explicitly authorizes a full suite.
- Full repository suite: only at broad integrated phase/slice gates when shared architecture changed enough to justify it.
- Do not rerun a full suite repeatedly without a code change or a new authorized gate.
- Run Flutter test processes sequentially when the environment shows NativeAssets/build-artifact collisions.
- Do not patch Flutter SDK/cache/global package sources to make project tests pass.

## 7. Git policy

Default agent rule:
- `git diff --check`
- `git status --short`
- inspect exact changed paths
- no `git add .`
- no `git add -A`
- no stage/commit/push unless user explicitly authorizes.

Never stage `OpenCode_Usage_Report.txt` unless the user explicitly changes that policy.

Pre-existing dirty files must be classified and preserved, not reformatted or reverted automatically.

## 8. Architecture protection

Preserve unless a frozen contract explicitly changes them:
- one production Supabase client/initialization authority;
- one production AuthProvider;
- accepted auth/recovery authority model;
- no `service_role` in Flutter;
- no blind automatic mutation retry;
- local-first behavior where designed;
- authenticated profile/business/staff data authority rules;
- roadmap status discipline: `CLOSED | CURRENT | QUEUED | POST_V1`.

## 9. Encyclopedia SSOT

The Encyclopedia single source of truth is:

`draft_jsons/*.draft.json`
→ exporter
→ app-ready/generated outputs
→ Flutter Encyclopedia

Never manually patch generated Encyclopedia outputs as an authoring workflow.

## 10. Session handoff rule

At the beginning of any new Civilpedia conversation or agent session:

> Read the Agent Operating Model, roadmap, current frozen contract, latest relevant report, and Git status before proposing work. Do not renegotiate the team roles from scratch.

The repository, not chat memory, is the durable source of truth.

## 11. Model-lineup maintenance

Model products change. Keep the **roles and risk tiers** stable even when model names change.

When a provider materially changes its lineup:
1. verify the official model mapping/cost/quota;
2. update only the relevant model note/routing row;
3. do not rewrite project architecture or role principles unnecessarily.

Last model-lineup verification: **2026-09-15**.

## 12. Risk-based agent ceremony

Match ceremony to risk. Do not lower quality — reduce only unnecessary process
overhead where the risk is low.

High-risk work gets strong contract/review ceremony:

- examples: Auth; Supabase authority; RLS/security; ownership; concurrency;
  lifecycle; migrations; high-blast-radius architecture;
- preferred workflow:
  Contract → strong implementation agent/model → independent focused review →
  formal closure.

Routine lower-risk work uses proportionate ceremony:

- examples: visual polish; ordinary Flutter presentation; localized UI fixes;
  encyclopedia cards; routine component work;
- preferred workflow:
  efficient implementer → focused deterministic tests → routine independent
  review.

The roadmap's cross-cutting governance (continuous security, continuous
integration/E2E smoke gates, CI evidence baseline, Supabase shift-left,
observability, V1 non-goals) applies to every phase from the Post-R09 Quality
Gate onward.
