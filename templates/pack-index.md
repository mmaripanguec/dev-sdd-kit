---
name: mapa-sistemas
description: >-
  START HERE. Map of the systems with context in this factory: which
  applications exist, what state each one's context is in and which pack
  to invoke. Use it before any system or repo pack, and whenever you are
  not sure which application the question belongs to.
version: 1.0.0
verificado: {{FECHA}}
---

# System map

**This pack only says where each thing is.** Each system's domain
lives in its own pack.

## The systems

| System | Repos | Context state | Start with |
|---|---:|---|---|
| **{{SISTEMA}}** | {{N_REPOS}} | <✅ documented and verified / ⚠️ partial: what is missing> | `{{PREFIJO}}-sistema` |

## {{SISTEMA}} — `{{PREFIJO}}-sistema` first

<One architecture sentence (A → B → C) + list of per-repo packs.>
Registry: `repos.yaml` · as-is: `knowledge/as-is/system.md`.

## How a system or repo is added

```bash
./scripts/repo-add.sh <url-o-ruta>   # or /repo-add from Claude Code
```
Then `/repo-map <repo>` (per-repo pack) and `/system-map` (system pack +
this index). **Convention**: `<prefijo>-sistema` for the seams,
`<prefijo>-<repo>` per repo. The system pack carries what lives in no
repo; that is why it disappears if only per-repo packs exist.

## Verification status

```bash
scripts/assertions.sh        # is any claim in the packs already false?
scripts/freshness.sh check  # has any pack expired?
```
Today: {{ESTADO_VERIFICACION}}

## What I do NOT know
- <systems or repos that exist but are not registered here>
