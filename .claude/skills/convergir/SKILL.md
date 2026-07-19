---
name: convergir
description: Cierra la brecha funcional código↔spec al terminar la construcción (F6/F7) — evalúa el código real contra las historias y criterios de la spec y AÑADE el trabajo restante como tareas de convergencia. Usar antes de la certificación F7 o cuando pidan "convergir la spec" / "qué falta de la spec".
argument-hint: "<ruta-de-la-spec>"
allowed-tools: Read Glob Grep Edit Bash(git -C:*) Bash(scripts/*)
---

Converge la spec $ARGUMENTS contra el código real de los repos afectados.
NO es una herramienta de diff de git: evalúa el ESTADO ACTUAL del código
contra lo que la spec promete, sin mirar historial ni ramas.

## Paso 1 — Contexto
Lee la spec completa (historias con CA, SC-xx, plan de tareas) e identifica
los repos afectados por las etiquetas de tarea. Carga el as-is de esos repos
(`knowledge/as-is/<repo>/`) y usa el grafo MCP codebase-memory
(search_graph/trace_path) si responde; si no, Grep directo en `repos/<repo>`
— degradación elegante, decláralo en el informe.

## Paso 2 — Evaluación historia por historia
Para cada CA (y cada SC verificable en código): busca la evidencia real y
clasifica con `archivo:línea`:
- **SATISFECHO** — implementado y con test que lo cubre.
- **PARCIAL** — implementado sin test, o cubre solo parte del CA.
- **AUSENTE** — no hay implementación.
Los CA de historias explícitamente fuera de alcance o P3 no arrancadas se
listan como NO INICIADO (no son brecha si el plan no los marcaba hechos).

## Paso 3 — Registrar (append-only)
- Si hay brechas (PARCIAL/AUSENTE con tarea marcada `[x]`, o CA sin tarea):
  AÑADE al final del plan de tareas de la spec la subsección
  `### Convergencia (<fecha de hoy>)` con una tarea nueva por brecha,
  etiquetada con su repo y referenciando el CA (`- [ ] TC1 [<repo>] cubrir
  CA2.3: …`). **NUNCA reescribas, edites ni borres tareas existentes** — si
  no hay brechas, el plan queda byte a byte igual y el informe lo declara.
- Re-ejecución idempotente: antes de añadir, revisa las convergencias
  previas; una brecha ya registrada y aún abierta no se duplica.

## Informe final
Tabla CA/SC → estado → evidencia; resumen de brechas añadidas (o "sin
brechas"); recordatorio de que las tareas TC se ejecutan con /implement-task
(TDD) antes del veredicto del agente de calidad. No toques código ni tests:
esta skill solo lee código y escribe en la sección de plan de la spec.
