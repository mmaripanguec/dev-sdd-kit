---
name: {{PREFIJO}}-sistema
description: >-
  START HERE for anything about {{SISTEMA}}. Mental model, map of the
  repos and the seams between them (what lives in no repo).
  Use it before any {{PREFIJO}}-<repo> pack, and whenever architecture,
  design, impact analysis or changes that cross components are requested.
version: 1.0.0
generado_desde:
  {{REPO_1}}: {{SELLO_1}}
verificado: {{FECHA}}
---

# {{SISTEMA}} — the system

**This pack contains what lives in NO repo: the seams.** The per-repo packs
have the detail; here is what can only be seen by looking at two or more at
once. Read it first.

## The repos

| Pack | Repo | What it is |
|---|---|---|
| `{{PREFIJO}}-<repo>` | `<repo>` | <one sentence: what it really is> |

## ⭐ The mental model
> **<THE system's central claim: the one that changes how everything
> else is understood.>**

<Elaboration with the complete evidence chain (`repo/file:line` at
every link). Include "the mistakes made by whoever does not know it".>

## ⭐ <Seams and cross-repo findings>
<How the repos REALLY communicate (not the theoretical diagram): fan-out,
contracts, queues, shared session... with evidence at both ends.>

## Pitfalls — do not fall for these
| False claim | Reality |
|---|---|
| <what this pack or the team believed before and was false> | <reality + evidence> |

## How to work
**Order**: this pack → the pack of the repo you touch → graph/as-is → read code.

| You need | Pack |
|---|---|
| <topic> | `{{PREFIJO}}-<repo>` |

### Mechanical verification — do not rely on my judgment
```bash
scripts/afirmaciones.sh {{SISTEMA}}   # is any claim already false?
scripts/frescura.sh comprobar         # has any pack expired?
```
**Rule**: every mechanically checkable correction ends up in
`scripts/afirmaciones.d/{{SISTEMA}}.sh`. Otherwise, it comes back.

## What I do NOT know
- <explicit limits of the system knowledge; inferences flagged>

**This pack does not prove its own completeness.** If you know the system and
something feels off, the pack is probably wrong, not you.
