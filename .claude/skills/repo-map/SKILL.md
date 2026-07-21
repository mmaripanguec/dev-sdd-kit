---
name: repo-map
description: Generates or updates a repository's CONTEXT PACK (loadable skill .claude/skills/<prefijo>-<repo>) — architecture, core mechanisms, dependencies and pitfalls with file:line evidence — and seeds its assertions. Use when asked to "map a repo", "generate the repo's context", when /spec-create detects a repo without a pack or with a stale pack, or after /repo-add.
argument-hint: "<registry-repo-name> [optional focus]"
allowed-tools: Read Glob Grep Write Edit Bash(./scripts/generate-as-is.sh *) Bash(./scripts/freshness.sh *) Bash(./scripts/assertions.sh *) Bash(git -C *) Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *) Bash(grep *) Bash(find *) Bash(wc *)
---

Generate the context pack for repo $ARGUMENTS as a loadable skill:
`.claude/skills/$(pack_name_for_repo <repo>)/SKILL.md` (name =
`<pack_prefix>-<repo>`, or the registry's `pack` field). The goal: any
agent that receives a requirement about this application loads the pack
and works with the correct mental model without rereading the repo.

## 1. Inputs (from cheapest to most expensive)
1. Registry (repos.yaml): role, domain, vcs; current seal with
   `. scripts/repo-lib.sh && stamp_of_repo <repo>`.
2. As-is facts: `knowledge/as-is/<repo>/{modules,api-surface}.md`
   (regenerate if the seal does not match).
3. codebase-memory MCP graph if indexed (get_architecture,
   search_graph, trace_path). If it does not respond, continue without it and
   declare it in "What I DON'T know".
4. Targeted reading of the code: entrypoint, wiring, routes, data layer,
   external clients. Read what is needed to back each claim.

## 2. Write the pack
- Template: `templates/pack-repo.md` (replace ALL `{{...}}` and `<...>`
  placeholders; frontmatter with `generado_desde: <repo>: <sello>` and
  `verificado:` with today's date).
- The frontmatter DESCRIPTION is the load trigger: name it with the
  application, its topics and typical questions.
- Hard rules: without `file:line` evidence a claim does not enter the
  body (it goes to "What I DON'T know"); the "Pitfalls" and "What I DON'T
  know" sections are never left empty (if there are no pitfalls yet, say
  which mistake would be easy to make);
  budget ~150 lines — detail overflows into `references/` inside
  the pack's folder.
- Secrets: FORBIDDEN to copy tokens, URLs with credentials or customer
  data into the pack.

## 3. Assertions and verification
- Seed/update `scripts/assertions.d/<sistema>.sh` with 3+ assertions
  from the pack's most important claims (format per that folder's README)
  and run `scripts/assertions.sh <sistema>` — it must end up green.
- Run `scripts/freshness.sh check <pack>` — it must come out current.
- If while verifying you detect an INCONSISTENCY (the code contradicts the
  registry, an ADR or an existing pack): STOP AND ASK the human.
  Do not normalize it silently.

## 4. Closure
- Update the `mapa-sistemas` index if the context state changed
  (or request /system-map if the system pack does not exist).
- Commit: `docs(packs): pack <pack> @<sello>`.
- Final summary: mental model in 3 lines + pitfalls + what was left out.
