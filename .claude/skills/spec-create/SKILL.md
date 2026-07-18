---
name: spec-create
description: Genera una spec de feature por capas (F1-F5) usando la plantilla de la fábrica. Usar cuando alguien pida "crear spec", "especificar feature" o describa funcionalidad nueva antes de implementarla.
argument-hint: "<nombre-feature> [descripción breve]"
allowed-tools: Read Glob Grep Write
---

## Contexto
- Specs existentes: !`ls specs/ 2>/dev/null`
- Reglas de negocio vigentes: ver knowledge/reglas-negocio.md

## Tarea
Crea `specs/$(date +%Y-%m)-$0.md` a partir de [specs/_template.md](../../../specs/_template.md):

1. Delega la redacción de historias al subagente `requisitos` (fase 1).
2. Con las historias aprobadas por PO/TL, delega estimación al subagente
   `estimacion` (fase 2).
3. Itera refinamiento con /spec-review hasta cumplir la DoR (fase 3).
4. Delega análisis (reglas, dependencias, casos límite) al subagente
   `analisis` (fase 4).
5. Delega diseño (contratos, C4, ADRs) al subagente `arquitectura` (fase 5).

En cada gate humano: DETENTE, presenta el resumen del agente y espera
aprobación explícita. Registra en la spec quién aprobó y cuándo.
No escribas código. No modifiques archivos fuera de specs/ y knowledge/.
