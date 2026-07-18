---
name: implement-task
description: Ejecuta UNA tarea del plan de una spec con protocolo TDD estricto (F6 Construcción). Usar para implementar tareas una a una.
argument-hint: "<ruta-spec> <id-tarea>"
allowed-tools: Read Glob Grep Edit Write Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *)
---

Implementa SOLO la tarea $1 de la spec $0. Protocolo:

1. Arranque del harness: lee harness/claude-progress.md y
   `git log --oneline -10`; ejecuta ./harness/init.sh y verifica con un smoke
   test que el entorno funciona ANTES de tocar nada.
2. Lee la spec completa: la tarea se implementa contra sus criterios de
   aceptación, no contra tu interpretación.
3. TDD: escribe los tests que codifican los criterios → verifica que FALLAN →
   commit de los tests → implementa hasta verde SIN tocar los tests → refactor.
4. Verificación end-to-end de la funcionalidad como lo haría un usuario;
   solo entonces actualiza "passes" en harness/feature_list.json.
   PROHIBIDO editar o borrar descripciones de features de ese archivo.
5. Cierre limpio: lint + typecheck en verde, commit con Conventional Commits
   referenciando la spec, y entrada en harness/claude-progress.md
   (qué se hizo, decisiones, qué sigue).

Si la tarea revela ambigüedad en la spec: DETENTE y escala. No improvises
alcance. Si descubres trabajo no previsto, anótalo como tarea nueva en la
spec en vez de hacerlo ahora.
