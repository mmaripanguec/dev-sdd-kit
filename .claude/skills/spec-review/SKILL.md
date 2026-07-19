---
name: spec-review
description: Valida una spec contra la Definition of Ready de la fábrica. Usar antes del gate DoR o cuando pidan "revisar spec".
argument-hint: "<ruta-de-la-spec>"
allowed-tools: Read Glob Grep
---

Revisa la spec $ARGUMENTS contra esta Definition of Ready. Por cada punto:
CUMPLE / NO CUMPLE + evidencia (cita la línea) o qué falta.

## DoR de la fábrica
1. Problema y objetivo en lenguaje de negocio, sin solución técnica implícita.
2. Historias cumplen INVEST; ninguna estimada > 8 puntos sin dividir.
3. TODO criterio de aceptación es Gherkin verificable (resultado observable
   y medible; nada de "debe ser robusto/rápido/amigable").
4. Fuera de alcance explícito y no vacío.
5. Casos límite enumerados (nulos, concurrencia, errores de terceros, permisos).
6. Reglas de negocio numeradas y consistentes con knowledge/reglas-negocio.md.
7. Dependencias y supuestos listados; los bloqueantes marcados.
8. Requisitos regulatorios/datos personales identificados si aplican.
9. NFRs con números (SLO, latencia, volumen), no adjetivos.
10. Sin secretos, credenciales ni datos reales de clientes en el documento.
11. Sin marcadores `[NECESITA CLARIFICACIÓN]` pendientes (resolver con
    /clarificar; las decisiones constan en la sección Clarificaciones).
12. Criterios de éxito SC-xx medibles y agnósticos de tecnología (umbral y
    plazo; certificables en F7 y contrastables con knowledge/uso.md).
13. Historias priorizadas [P1]/[P2]/[P3]; las P1 por sí solas constituyen un
    MVP viable e independientemente testeable.

Complemento: la consistencia CRUZADA con reglas de negocio, ADRs, as-is y
plan de tareas la audita /consistencia; recomiéndala si aún no se corrió.

Veredicto final: LISTA PARA DoR / REQUIERE CAMBIOS (lista priorizada).
No edites la spec: reporta; los cambios los aplica el ciclo crear-revisar-mejorar.
