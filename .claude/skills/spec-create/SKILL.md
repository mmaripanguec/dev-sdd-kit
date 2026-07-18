---
name: spec-create
description: Genera una spec de feature por capas (F1-F5) usando la plantilla de la fábrica. Usar cuando alguien pida "crear spec", "especificar feature" o describa funcionalidad nueva antes de implementarla.
argument-hint: "<nombre-feature> [descripción breve]"
allowed-tools: Read Glob Grep Write
---

## Contexto
- Specs existentes: !`ls specs/ 2>/dev/null`
- Repos registrados: !`. scripts/repo-lib.sh 2>/dev/null && registry_repos | tr '\n' ' '`
- Reglas de negocio vigentes: ver knowledge/reglas-negocio.md

## PASO 0 — Triage del requerimiento (OBLIGATORIO antes de F1)

**0.1 Clasificar** contra repos.yaml y el índice `mapa-sistemas`:
- **A · Aplicativo EXISTENTE**: el requerimiento toca repos registrados.
  Identifica CUÁLES y regístralo en la spec (campo "Tipo de requerimiento").
- **B · Aplicación NUEVA**: no existe repo. La spec lo declara; el stack y
  la arquitectura se deciden en F5, y el plan de tareas parte con una T0 de
  creación (crear repo → /repo-add → scaffolding → as-is y pack al nacer).
- **Mixto**: combinación; aplica ambos protocolos.
- Si no puedes clasificar con certeza: PREGUNTA al usuario. No asumas.

**0.2 Cargar contexto (escenario A)**: por cada repo afectado, carga su
pack (`<prefijo>-<repo>`) y el pack de sistema (`<prefijo>-sistema`).
- ¿No existe el pack? → génera con /repo-map (o /system-map) ANTES de F1.
- ¿Existe? → valida vigencia: `scripts/frescura.sh comprobar <pack>` y
  `scripts/afirmaciones.sh <sistema>`. Caduco → regenerar antes de seguir.

**0.3 Dependencias — preguntar, NUNCA asumir**: si las historias, el as-is
o los packs revelan que el aplicativo depende de otro sistema/servicio:
- ¿Está registrado en repos.yaml? NO → **DETENTE Y PREGUNTA** al usuario
  cuál es su repositorio (URL/ruta) o si queda explícitamente fuera de
  alcance. Con la respuesta: /repo-add + /repo-map de la dependencia.
- SÍ → valida que su pack exista y esté vigente (como en 0.2).
- Cualquier INCONSISTENCIA (pack contradice código o registro, aserción
  falsa, dependencia declarada que no aparece en el código o viceversa):
  **SIEMPRE PREGUNTA**; nunca normalices en silencio.

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
