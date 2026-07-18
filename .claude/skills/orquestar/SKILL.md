---
name: orquestar
description: Recorre el ciclo E2E de 9 fases para una feature, delegando en los agentes por fase y deteniéndose en cada gate humano. Solo invocable por humanos.
disable-model-invocation: true
argument-hint: "<spec o descripción de la feature>"
---

Ejecuta el ciclo E2E para: $ARGUMENTS

## Reglas globales del orquestador
- Secuencial: avanza fase por fase; NUNCA saltes un gate humano.
- Tras cada fase: escribe el artefacto en specs/ o knowledge/ y commitea
  antes de avanzar (un fallo a mitad de flujo no pierde fases previas).
- Escalate: ante ambigüedad, contradicción o verificación imposible,
  detente y pregunta al humano del gate más cercano. No supongas.
- Rendición de cuentas: registra en el artefacto de cada gate quién aprobó,
  cuándo y sobre qué versión (commit).

## Secuencia
F0 Triage          → PASO 0 de /spec-create: ¿aplicativo existente o
                     aplicación nueva? · cargar packs de contexto vigentes ·
                     dependencias sin contexto => PREGUNTAR (repo, alta,
                     pack), nunca asumir · inconsistencia => PREGUNTAR
F1 Requerimiento   → subagente requisitos   → historias INVEST      → GATE PO/TL
F2 Estimación      → subagente estimacion   → puntos + WSJF
F3 Refinamiento    → loop /spec-review + correcciones hasta DoR     → GATE DoR
F4 Análisis        → subagente analisis     → reglas, deps, límites
F5 Diseño          → subagente arquitectura → contratos, C4, ADRs   → GATE Arquitectura
F6 Construcción    → /harness-init si es multi-sesión; luego
                     /implement-task por cada tarea del plan (TDD)
F7 Certificación   → subagente calidad      → veredicto trazable    → GATE QA/PR
F8 Producción      → subagente publicacion  → expediente de riesgo  → GATE Comité CAB
F9 Operación       → subagente operacion    → monitoreo, postmortem → GATE DevOps/SRE

Al terminar F9: verifica que el ciclo cerró — postmortems e incidentes
alimentaron knowledge/, y la spec quedó en estado "implementada" con su
trazabilidad completa (spec → ADR → commits → expediente → operación).
