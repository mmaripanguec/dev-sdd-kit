# Factory workspace · System declared in repos.yaml

## What it is
Workspace of the digital factory to develop and maintain ANY system made of
one or more code repositories. The topology (which repos make up the
system, their git provider, roles, entrypoint and deploy order) lives in
`repos.yaml` — the single source of truth; no script or skill hardcodes
repo names. Repos are cloned into `repos/` (gitignored here; each one is
its own git).

This repo (the workspace) versions the system's SHARED CONTEXT: specs,
knowledge (ADRs, incidents, rules, as-is), skills, agents and harness.
Code lives in the repos; system knowledge lives here.
Current example system: homebanking (3 Bitbucket repos; see repos.yaml).

## Essential commands
- Onboard a repo into the system: `/repo-add <url-or-path>` (clones, registers,
  seeds CLAUDE.md, indexes it in codebase-memory and generates the as-is) —
  equivalent script: `./scripts/repo-add.sh <url-or-path>`
- Deep context (loadable packs): `/repo-map <repo>` generates the repo's
  pack (`.claude/skills/<prefijo>-<repo>`) and `/system-map` the system
  pack + the `mapa-sistemas` index. Verification: `scripts/afirmaciones.sh`
  and `scripts/frescura.sh comprobar`
- Prepare the workspace on a new machine: `./scripts/setup.sh`
  (clones/updates ALL repos in the registry; credentials: .env.example)
- System as-is map: `./scripts/generate-as-is.sh` (or /as-is-sync)
- Each repo has its own commands in `repos/<repo>/CLAUDE.md`

## Multi-repo rules
1. ALWAYS launch Claude Code from the workspace root: that way this context
   loads, and each repo's CLAUDE.md loads on its own when working with its files.
2. Code commits are made INSIDE the corresponding repo
   (`git -C repos/<repo> …`); knowledge commits, in this workspace.
3. A feature that crosses repos = ONE spec here, with tasks tagged with the
   registered repo name (`- [ ] T1 [<repo>] …`; `[workspace]` for
   context changes).
4. The contract between repos is the boundary: changing an API that another
   repo consumes requires updating the contract (OpenAPI) and an ADR if it
   breaks compatibility.
5. Deploy order: the registry's `deploy_order` (lowest first;
   a consumer is never deployed before its provider).
6. Domain profiles: a repo with `domain: banking` in the registry additionally
   activates `.claude/rules/domain-banking.md`.

## Mandatory workflow
0. Every requirement starts with the TRIAGE (F0 of /spec-create):
   existing application or new application? The current context packs of
   the affected repos are loaded; dependencies without context →
   ASK for their repository (never assume); inconsistencies → ASK.
1. Every non-trivial change starts from a spec in `specs/` (/spec-create).
   Ambiguities: /clarify (max. 5 questions; answers traced in the spec's
   Clarifications section; pending [NEEDS CLARIFICATION] markers
   block the DoR).
2. Phases and gates with /orchestrate; NEVER skip a gate. Before the
   DoR and Architecture gates: /consistency with a FIT FOR GATE verdict (the
   blocking criterion is defined by that skill; do not duplicate it here).
3. Construction with /implement-task: TDD, one commit per task IN ITS repo.
4. Modifying tests to make them pass is FORBIDDEN.
5. When closing F6: /converge compares the real code against the spec and
   appends the gaps as tasks (append-only) before the quality verdict.
6. When facing ambiguity: escalate to the nearest gate, never assume.

## AS-IS map (real state derived from the code — never edit by hand)
- Index: `knowledge/as-is/INDEX.md` · full system: `knowledge/as-is/system.md`
- Per repo: `knowledge/as-is/<repo>/` · query with /as-is; sync with /as-is-sync
- Fine-grained structure (functions, calls, impact): the codebase-memory
  MCP graph (repos indexed by /repo-add)
- Architecture interpretation: context packs (skills
  `mapa-sistemas` → `<prefijo>-sistema` → `<prefijo>-<repo>`), with
  file:line evidence, `generado_desde` seal and executable assertions
- The as-is says WHAT EXISTS; the packs HOW IT IS PUT TOGETHER; the ADRs WHY;
  the specs WHAT SHOULD EXIST.

## Shared memory (read on demand)
- Specs: `specs/` · ADRs: `knowledge/decisiones/` · Incidents: `knowledge/incidentes/`
- Rules: `knowledge/reglas-negocio.md` · DORA: `knowledge/uso.md`
- Standards: `knowledge/estandares.md`

## Conventions
- Working language of the workspace: the registry's `system.lang`
  (this instance: es) — specs, knowledge and user interactions are written
  in that language and kept consistent. The NAMES of commands, skills and
  code identifiers are ALWAYS English. PUBLIC GitHub documentation (README,
  CONTRIBUTING, LICENSE, .github, docs/architecture.en.html) in English.
- Conventional Commits + spec reference, in the workspace and in each repo.
- Every architecture decision → ADR. Every incident → blameless postmortem.
