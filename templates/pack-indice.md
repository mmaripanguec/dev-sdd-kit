---
name: mapa-sistemas
description: >-
  EMPIEZA POR AQUÍ. Mapa de los sistemas con contexto en esta fábrica: qué
  aplicativos hay, en qué estado está el contexto de cada uno y qué pack
  invocar. Úsalo antes que cualquier pack de sistema o repo, y siempre que
  no tengas claro a qué aplicativo pertenece lo que te preguntan.
version: 1.0.0
verificado: {{FECHA}}
---

# Mapa de sistemas

**Este pack solo dice dónde está cada cosa.** El dominio de cada sistema
vive en su propio pack.

## Los sistemas

| Sistema | Repos | Estado del contexto | Empieza por |
|---|---:|---|---|
| **{{SISTEMA}}** | {{N_REPOS}} | <✅ documentado y verificado / ⚠️ parcial: qué falta> | `{{PREFIJO}}-sistema` |

## {{SISTEMA}} — `{{PREFIJO}}-sistema` primero

<Una frase de arquitectura (A → B → C) + lista de packs por repo.>
Registro: `repos.yaml` · as-is: `knowledge/as-is/system.md`.

## Cómo se añade un sistema o repo

```bash
./scripts/repo-add.sh <url-o-ruta>   # o /repo-add desde Claude Code
```
Luego `/repo-map <repo>` (pack por repo) y `/system-map` (pack de sistema +
este índice). **Convención**: `<prefijo>-sistema` para las uniones,
`<prefijo>-<repo>` por repo. El pack de sistema lleva lo que no vive en
ningún repo; por eso desaparece si solo hay packs por repo.

## Estado de la verificación

```bash
scripts/afirmaciones.sh        # ¿alguna afirmación de los packs ya es falsa?
scripts/frescura.sh comprobar  # ¿caducó algún pack?
```
Hoy: {{ESTADO_VERIFICACION}}

## Qué NO sé
- <sistemas o repos que existen pero no están registrados aquí>
