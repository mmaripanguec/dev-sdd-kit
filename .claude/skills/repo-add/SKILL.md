---
name: repo-add
description: Onboards a repository into the factory (git URL or local path): clones, registers in repos.yaml, fills its CLAUDE.md with real data, indexes it in codebase-memory and regenerates the as-is map. Use when asked to "add/onboard a repo" or "set up analysis for a repository".
argument-hint: "<url-or-path> [--role \"role\"] [--entrypoint] [--domain banking] [--system-name s]"
allowed-tools: Read Glob Grep Edit Write Bash(./scripts/repo-add.sh *) Bash(./scripts/generate-as-is.sh *) Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *)
---

Goal: leave repo $ARGUMENTS READY TO SPECIFY (/spec-create)
in a single pass. The repos.yaml registry is the single source of truth for
the topology: never hardcode repo names in scripts or skills.

## 1. Registration in the registry
- Run `./scripts/repo-add.sh $ARGUMENTS` (clones/updates, registers in
  repos.yaml, seeds CLAUDE.md). If it fails, diagnose with the script's
  message (credentials → .env, see .env.example) and stop: do not
  improvise the registration by hand.
- If the user did not provide `--role`, infer it from the repo (README,
  package.json, structure) and update the field with
  `./scripts/repo-add.sh <origen> --role "<rol deducido>"` (it is idempotent).

## 2. Fill the repo's CLAUDE.md with REAL data
Read the freshly cloned repo (README, package.json/Makefile/pom.xml/etc.) and
replace every `<completar>` in `repos/<nombre>/CLAUDE.md` that you can
back with evidence: real install/dev/test/lint commands, role,
visible conventions. Whatever lacks evidence stays marked
`<completar>` — do not invent commands. Remember: that file is committed IN
THAT repo, not in the workspace.

## 3. Index in codebase-memory (code graph)
- Two deployment modes exist (see `docs/codebase-memory-setup.md`):
  - **Direct engine:** invoke `index_repository` from the codebase-memory MCP on
    `repos/<name>` and verify with `index_status`/`list_projects`.
  - **Fleet / Postgres facade (read-only):** the MCP exposes only read tools;
    `index_repository` is NOT available and returns
    `-32601 ... no equivalent in the fleet graph`. This is EXPECTED — do not
    treat it as a hard failure. When the fleet is configured in `.env`
    (`CBM_FLEET_SEED`, `CBM_FLEET_URL`, `CBM_FLEET_TOKEN`), `repo-add.sh` already
    ran `scripts/codebase-memory.sh index <name>`, which **seeds the repo and
    wires `.mcp.json` automatically** — just confirm its output. Otherwise seed
    manually (`run_local.py seed --repo repos/<name>`) and point `.mcp.json` at
    the project. Details in `docs/codebase-memory-setup.md`.
- If indexing cannot be completed here (MCP down, facade without a seed path):
  do NOT block the onboarding; state it explicitly in the final report
  ("indexing pending: seed via the fleet or run `index_repository` when the
  direct engine is available"). The as-is map and packs still work from grep.

## 4. As-is map
- Run `./scripts/generate-as-is.sh` and review the result.
- If there are ≥2 registered repos and the cross-repo graph came out empty or
  incomplete, recommend `/as-is-learn` (writes exact per-repo extractors
  with evidence from the code).
- Commit `repos.yaml` + `knowledge/as-is/` in the workspace:
  `chore(repos): alta de <nombre> + mapa as-is`.

## 5. Final report (output contract)
Summarize: registered name and role, detected stack, MCP indexing status,
as-is map status (with or without graph), and close with the next steps:
"ready for `/spec-create <feature>`", `/repo-map <repo>` for the deep
architecture map, and `/as-is <pregunta>` to explore.
