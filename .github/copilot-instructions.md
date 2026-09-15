# Civilpedia — GitHub Copilot Repository Instructions

You are working in the Civilpedia production repository.

Before substantial work, read:
- `AGENTS.md`
- `docs/architecture/CIVILPEDIA_AGENT_OPERATING_MODEL.md`
- `docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md`
- the current frozen contract
- the latest relevant implementation/review report

Follow these rules:

- Work only on the CURRENT authorized slice.
- Do not implement when authorization is absent.
- Preserve frozen contracts and accepted invariants.
- Prefer the smallest root-cause change.
- Never stage, commit, or push unless the user explicitly authorizes it.
- Do not use `git add .` or `git add -A` by default.
- Preserve pre-existing dirty files and classify them separately.
- Use focused tests during implementation/review; full suite only at an authorized integrated gate.
- Run Flutter tests sequentially if parallel NativeAssets builds collide.
- Do not modify Flutter SDK/cache/global package sources.
- Do not introduce dependencies, migrations, schema/RLS/storage/Edge/Realtime changes unless the current frozen contract explicitly authorizes them.
- Never put a Supabase `service_role` credential in Flutter.
- Preserve one production Supabase authority and one AuthProvider.
- Do not add blind automatic mutation retry.
- Keep authenticated cloud data authority boundaries fail-closed.
- Never expose raw exceptions, SQLSTATE, stack traces, or backend messages in production UI.
- Support Arabic/English, RTL/LTR, light/dark, and responsive layouts for user-facing changes.
- Encyclopedia SSOT is `draft_jsons/*.draft.json`; generated Encyclopedia outputs are not manually authored.
- Never stage `OpenCode_Usage_Report.txt` unless the user explicitly changes that rule.

For reviews:
- default to READ ONLY;
- do not silently fix findings;
- classify HIGH / MEDIUM / LOW;
- HIGH or MEDIUM blocks acceptance;
- cite exact files/lines and smallest correction boundary;
- do not reopen previously accepted slices without direct evidence.

For implementation:
- do not expand into queued slices;
- run the smallest focused verification that proves the change;
- report exact files changed and Git state.
