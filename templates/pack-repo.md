---
name: {{PACK}}
description: >-
  <what this repo is in one sentence and when to use this pack: topics,
  modules and questions it answers — this description is the TRIGGER that
  makes an agent load it when a requirement mentions the application>.
  Read the {{PREFIJO}}-sistema pack FIRST: the mental model and the seams live there.
version: 1.0.0
generado_desde:
  {{REPO}}: {{SELLO}}
verificado: {{FECHA}}
---

> **Read `{{PREFIJO}}-sistema` first.** <If another pack corrected something
> this repo declares incorrectly, the correction goes here at the top.>

# {{REPO}} — <real name / what it is>

<What it is, what it is NOT, stack and version — with `file:line` evidence.>

## Startup and structure
<Process entrypoint, wiring/route registration, real modules — with
`file:line`. Not the folder tree (that lives in the as-is): the HOW.>

## ⭐ <The repo's core mechanism>
<The finding that is hardest to discover by reading, with its complete
step-by-step evidence chain (`file:line` at every link).>

## <Sections by topic>
<Endpoints, data, integrations, per-environment config... only what an
agent needs to work WITHOUT re-reading the whole repo.>

## Pitfalls — do not fall for these
| False claim | Reality |
|---|---|
| <mistake someone who has not read the code would make, or that this pack made before> | <reality, with evidence> |

## What I do NOT know
- <explicit limits: what was not explored, what is inference and not fact>

**This pack does not prove its own completeness.** If you know the repo and
something feels off, the pack is probably wrong, not you: fix it and turn
the correction into an assertion (`scripts/afirmaciones.d/{{SISTEMA}}.sh`).
