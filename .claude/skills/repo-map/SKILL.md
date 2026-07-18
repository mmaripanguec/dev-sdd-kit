---
name: repo-map
description: Genera o actualiza el PACK DE CONTEXTO de un repositorio (skill cargable .claude/skills/<prefijo>-<repo>) — arquitectura, mecanismos centrales, dependencias y trampas con evidencia archivo:línea — y siembra sus aserciones. Usar cuando pidan "mapear un repo", "generar el contexto del repo", cuando /spec-create detecte un repo sin pack o con pack caduco, o después de /repo-add.
argument-hint: "<nombre-repo-del-registro> [foco opcional]"
allowed-tools: Read Glob Grep Write Edit Bash(./scripts/generate-as-is.sh *) Bash(./scripts/frescura.sh *) Bash(./scripts/afirmaciones.sh *) Bash(git -C *) Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *) Bash(grep *) Bash(find *) Bash(wc *)
---

Genera el pack de contexto del repo $ARGUMENTS como skill cargable:
`.claude/skills/$(pack_name_for_repo <repo>)/SKILL.md` (nombre =
`<pack_prefix>-<repo>`, o el campo `pack` del registro). El objetivo: que
cualquier agente que reciba un requerimiento sobre este aplicativo cargue
el pack y trabaje con el modelo mental correcto sin releer el repo.

## 1. Insumos (del más barato al más caro)
1. Registro (repos.yaml): rol, dominio, vcs; sello actual con
   `. scripts/repo-lib.sh && stamp_of_repo <repo>`.
2. Hechos del as-is: `knowledge/as-is/<repo>/{modules,api-surface}.md`
   (regenerar si el sello no coincide).
3. Grafo MCP codebase-memory si está indexado (get_architecture,
   search_graph, trace_path). Si no responde, sigue sin él y decláralo en
   "Qué NO sé".
4. Lectura dirigida del código: entrypoint, wiring, rutas, capa de datos,
   clientes externos. Lee lo necesario para respaldar cada afirmación.

## 2. Escribir el pack
- Plantilla: `templates/pack-repo.md` (reemplaza TODOS los placeholders
  `{{...}}` y `<...>`; frontmatter con `generado_desde: <repo>: <sello>` y
  `verificado:` con la fecha de hoy).
- La DESCRIPCIÓN del frontmatter es el gatillo de carga: nómbrala con el
  aplicativo, sus temas y preguntas típicas.
- Reglas duras: sin evidencia `archivo:línea` una afirmación no entra al
  cuerpo (va a "Qué NO sé"); las secciones "Trampas" y "Qué NO sé" nunca
  quedan vacías (si no hay trampas aún, di qué error sería fácil cometer);
  presupuesto ~150 líneas — el detalle desborda a `references/` dentro de
  la carpeta del pack.
- Secretos: PROHIBIDO copiar tokens, URLs con credenciales o datos de
  clientes al pack.

## 3. Aserciones y verificación
- Siembra/actualiza `scripts/afirmaciones.d/<sistema>.sh` con 3+ aserciones
  de las afirmaciones más importantes del pack (formato del README de esa
  carpeta) y corre `scripts/afirmaciones.sh <sistema>` — debe quedar en verde.
- Corre `scripts/frescura.sh comprobar <pack>` — debe salir vigente.
- Si al verificar detectas una INCONSISTENCIA (el código contradice el
  registro, un ADR o un pack existente): DETENTE Y PREGUNTA al humano.
  No la normalices en silencio.

## 4. Cierre
- Actualiza el índice `mapa-sistemas` si cambió el estado del contexto
  (o pide /system-map si el pack de sistema no existe).
- Commit: `docs(packs): pack <pack> @<sello>`.
- Resumen final: modelo mental en 3 líneas + trampas + qué quedó fuera.
