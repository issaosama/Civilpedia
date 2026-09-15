# Civilpedia Agent Bootstrap

This repository uses a fixed multi-agent operating model.

## Read first

Before substantial work, read:

1. `docs/architecture/CIVILPEDIA_AGENT_OPERATING_MODEL.md`
2. `docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md`
3. the frozen contract for the current phase/slice
4. the latest relevant implementation/review report
5. `git status --short`
6. `git rev-parse HEAD`

The roadmap is the phase/status SSOT. Do not infer CURRENT work from an old conversation.

## Core rules

- Work only on the CURRENT authorized slice.
- If `IMPLEMENTATION_AUTHORIZED` is not YES, do not implement.
- Preserve frozen contracts; append authorized addenda rather than silently rewriting history.
- Root-cause fixes only; no broad refactors unless authorized.
- Do not stage, commit, or push unless the user explicitly authorizes it.
- Never use `git add .` or `git add -A` as the default workflow.
- Preserve pre-existing dirty files unless they are explicitly brought into scope.
- Run focused tests during implementation/review.
- Run a repository-wide suite only at an explicitly authorized integrated gate.
- Do not patch Flutter SDK/cache/global package source.
- No blind automatic mutation retry.
- No `service_role` in Flutter.
- Preserve one production Supabase authority and one AuthProvider.
- Encyclopedia authoring SSOT is `draft_jsons/*.draft.json`; generated outputs are not hand-edited.

## Agent routing

- ChatGPT / GPT-5.6 Sol: architect, contract freeze, acceptance decisions.
- Big Pickle: routine Flutter/UI/tests/docs implementation.
- GitHub Copilot: routine independent review and secondary implementation.
- Kimi coding default / K2.7 Code: medium coding, long-context implementation, reserve reviewer.
- Kimi K3-256k: hard multi-file/refactor/review; K3 1M only when very large context is materially needed.
- Codex: backend, Supabase, RLS, Auth, security, concurrency, ownership, migrations.
- Astra: exceptional architecture/security adjudication.
- User: final Git staging/commit/push owner.

See `docs/architecture/CIVILPEDIA_AGENT_OPERATING_MODEL.md` for the authoritative detail.

## New-session rule

Do not renegotiate the team roles from scratch. Read the operating model and continue from the roadmap/current contract.
