---
name: system-map
description: Genera o actualiza el PACK DE SISTEMA (<prefijo>-sistema, las uniones y el modelo mental que no viven en ningún repo) y el índice mapa-sistemas. Usar cuando el sistema tenga ≥2 repos con packs, cuando pidan "el mapa del sistema"/"cómo se conectan los repos", o cuando /spec-create detecte que falta el pack de sistema.
argument-hint: "[foco opcional]"
allowed-tools: Read Glob Grep Write Edit Bash(./scripts/generate-as-is.sh *) Bash(./scripts/frescura.sh *) Bash(./scripts/afirmaciones.sh *) Bash(git -C *) Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *) Bash(grep *) Bash(find *) Bash(wc *)
---

Genera `.claude/skills/<prefijo>-sistema/SKILL.md` (prefijo =
`registry_pack_prefix` de repo-lib) y actualiza el índice
`.claude/skills/mapa-sistemas/SKILL.md`. El pack de sistema lleva **lo que
no vive en ningún repo**: el modelo mental y las uniones.

## 1. Insumos
1. Registro completo (repos.yaml) + sellos actuales (`stamp_of_repo`).
2. as-is del sistema: `knowledge/as-is/system.md` (grafo cross-repo) — 
   regenerar si está viejo.
3. Los packs por repo existentes (`<prefijo>-*`): las uniones nacen de
   cruzar sus dos extremos. Si falta el pack de un repo central, genera
   primero ese con /repo-map (o pregunta al humano si priorizar).
4. Verificación de cada unión EN AMBOS EXTREMOS del código: una flecha
   afirmada por un solo lado es hipótesis, no hecho.

## 2. Escribir el pack de sistema
- Plantilla: `templates/pack-sistema.md`; frontmatter `generado_desde:` con
  TODOS los repos y sus sellos; `verificado:` hoy.
- El ⭐ modelo mental es LA afirmación que cambia cómo se entiende el
  sistema (con su cadena de evidencia cross-repo). Si aún no hay una,
  dilo honestamente: "todavía no encuentro la afirmación central".
- "Trampas" y "Qué NO sé" nunca vacías. Presupuesto ~150 líneas;
  detalle a `references/`.

## 3. Índice mapa-sistemas
- Plantilla: `templates/pack-indice.md`: tabla de sistemas con estado del
  contexto REAL (qué packs existen, cuáles vigentes — usa
  `scripts/frescura.sh comprobar` y `scripts/afirmaciones.sh`), por dónde
  empezar, y "Qué NO sé".

## 4. Aserciones, verificación y cierre
- Cada unión importante → aserción en `scripts/afirmaciones.d/<sistema>.sh`
  (idealmente una por extremo). Correr la suite: verde obligatorio.
- `scripts/frescura.sh comprobar` en verde para los packs tocados.
- INCONSISTENCIAS (el grafo del as-is contradice un pack, una unión no se
  confirma en el otro extremo, un ADR queda desmentido): DETENTE Y
  PREGUNTA. Nunca normalices en silencio.
- Commit: `docs(packs): pack de sistema <prefijo>-sistema + indice`.
- Resumen final: modelo mental + mapa de flechas verificadas + qué falta.
