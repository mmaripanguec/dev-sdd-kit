---
name: system-map
description: Generates or updates the SYSTEM PACK (<prefijo>-sistema, the junctions and the mental model that live in no repo) and the mapa-sistemas index. Use when the system has ≥2 repos with packs, when asked for "the system map"/"how the repos connect", or when /spec-create detects the system pack is missing.
argument-hint: "[foco opcional]"
allowed-tools: Read Glob Grep Write Edit Bash(./scripts/generate-as-is.sh *) Bash(./scripts/generate-architecture.sh *) Bash(./scripts/freshness.sh *) Bash(./scripts/assertions.sh *) Bash(git -C *) Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *) Bash(grep *) Bash(find *) Bash(wc *)
---

Generate `.claude/skills/<prefijo>-sistema/SKILL.md` (prefix =
`registry_pack_prefix` from repo-lib) and update the index
`.claude/skills/mapa-sistemas/SKILL.md`. The system pack carries **what
lives in no repo**: the mental model and the junctions.

## 1. Inputs
1. Full registry (repos.yaml) + current seals (`stamp_of_repo`).
2. System as-is: `knowledge/as-is/system.md` (cross-repo graph) —
   regenerate if it is old.
3. The existing per-repo packs (`<prefijo>-*`): the junctions are born from
   crossing their two ends. If the pack of a central repo is missing, generate
   that one first with /repo-map (or ask the human whether to prioritize).
4. Verification of each junction AT BOTH ENDS of the code: an arrow
   asserted by only one side is a hypothesis, not a fact.

## 2. Write the system pack
- Template: `templates/pack-system.md`; frontmatter `generado_desde:` with
  ALL repos and their seals; `verificado:` today.
- The ⭐ mental model is THE claim that changes how the system is
  understood (with its cross-repo evidence chain). If there is not one yet,
  say so honestly: "I have not yet found the central claim".
- "Pitfalls" and "What I DON'T know" never empty. Budget ~150 lines;
  detail goes to `references/`.

## 3. mapa-sistemas index
- Template: `templates/pack-index.md`: table of systems with the REAL
  context state (which packs exist, which are current — use
  `scripts/freshness.sh check` and `scripts/assertions.sh`), where
  to start, and "What I DON'T know".

## 4. AS-IS architecture document (knowledge, arc42 + C4)
- Author/refresh the curated narrative in
  `knowledge/architecture/<system>.narrative.md` (seed it from
  `templates/knowledge-architecture.narrative.md` on first run): mental model,
  seams, endpoints, decisions, risks — the analysis that lives in no repo. The
  derived data (topology, dependencies, metrics) is injected by the generator.
- Generate both formats: `./scripts/generate-architecture.sh` writes
  `knowledge/architecture/<system>.{md,html}`.
- Create the context skill `<prefix>-architecture` from
  `templates/skill-architecture.md` (fill `{{PREFIX}}`, `{{SYSTEM}}`,
  `{{REPO_TRIGGERS}}` = the system's repo names/aliases, `{{SEALS_FRONTMATTER}}`,
  `{{FECHA}}`) so agents load the document as context on those triggers and do
  NOT re-index or re-read code for what is already documented.

## 5. Assertions, verification and closure
- Each important junction → assertion in `scripts/assertions.d/<sistema>.sh`
  (ideally one per end). Run the suite: green is mandatory.
- `scripts/freshness.sh check` green for the touched packs.
- INCONSISTENCIES (the as-is graph contradicts a pack, a junction is not
  confirmed at the other end, an ADR is refuted): STOP AND
  ASK. Never normalize silently.
- Commit: `docs(packs): pack de sistema <prefijo>-sistema + indice`.
- Final summary: mental model + map of verified arrows + what is missing.
