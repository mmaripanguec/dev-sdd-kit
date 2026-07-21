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
- Invoke `index_repository` from the codebase-memory MCP on `repos/<nombre>`
  and verify with `index_status`/`list_projects`.
- If the MCP is unavailable or fails: do NOT block the onboarding; state it
  explicitly in the final report ("indexing pending: run
  /repo-add again or index_repository when the MCP is up").

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
