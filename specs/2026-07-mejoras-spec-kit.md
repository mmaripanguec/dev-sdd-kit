# Spec: Adopción de mecánicas de calidad de GitHub Spec Kit

| Campo | Valor |
|---|---|
| Estado | implementada |
| Tipo de requerimiento | existente `[workspace]` (triage F0: solo contexto/skills; no toca repos de código) |
| Contexto cargado | análisis comparativo dev-sdd-kit vs github/spec-kit (sesión 2026-07-19) |
| Dominio de negocio | proceso de la fábrica (SDD) |
| Autor / Fecha | Claude + Marcos Maripangue / 2026-07-19 |
| Gate PO/TL | aprobado por Marcos Maripangue el 2026-07-19 (instrucción en sesión: "implementa en otra rama") |
| Gate DoR | aprobado por Marcos Maripangue el 2026-07-19 (revisión del diff completo de la rama en sesión: "o.k avanzar aprobado") |
| Gate Arquitectura | N/A — no altera arquitectura de código; solo skills y plantillas del workspace |

## 1. Problema
El análisis comparativo con github/spec-kit (122k⭐, v0.13.0) y las referencias
mundiales (DORA 2025, McKinsey State of AI 2025, Anthropic, Thoughtworks Radar
vol. 33/34) confirmaron tres debilidades de la fábrica que spec-kit resuelve bien:
1. **Clarificación reactiva y no trazable**: el kit pregunta ad-hoc ("detente y
   pregunta") pero las respuestas se pierden en la conversación; no quedan en la spec.
2. **Sin análisis de consistencia entre artefactos**: /spec-review valida una spec
   aislada contra la DoR; nadie valida spec ↔ reglas-negocio ↔ ADRs ↔ as-is ↔ plan
   de tareas de forma cruzada.
3. **Drift funcional código↔spec sin cierre**: as-is/frescura detectan drift
   ESTRUCTURAL, pero nada compara la funcionalidad implementada contra la spec al
   terminar F6 (la única spec previa quedó con F7 "Pendiente").
Además, la spec no exige criterios de éxito de negocio medibles separados de los
CA técnicos, ni prioriza historias para entrega incremental (MVP).

## 2. Objetivo
La fábrica incorpora las cuatro mecánicas de calidad de spec-kit que cubren sus
debilidades detectadas — clarificación estructurada, análisis de consistencia,
convergencia funcional y criterios de éxito medibles con priorización de
historias — sin renunciar a sus fortalezas (TDD obligatorio, gates con permisos,
multi-repo, contexto verificable).

## 2.1 Criterios de éxito
- SC-01 Toda spec nueva registra sus decisiones de clarificación en el
  documento (0 decisiones perdidas en conversación).
- SC-02 El 100% de las specs que llegan a los gates DoR/Arquitectura lo hacen
  con veredicto APTO PARA GATE de /consistencia.
- SC-03 Ninguna spec cierra F6 sin informe de /convergir (se elimina el
  estado "F7 Pendiente" sin evidencia, como quedó la spec de generalización).

## 3. Fuera de alcance
- Tests opcionales (retroceso de spec-kit; el TDD sigue siendo obligatorio).
- Constitución auto-evaluada por el LLM como gate (nuestros gates humanos con
  permisos son más fuertes).
- CLI de distribución tipo `specify` / extensiones / presets / bundles.
- Numeración `NNN-` de specs y branching automático por feature.
- Integración tasks→issues (Jira); queda como candidata para una spec futura.
- Cambios en los repos de código del sistema.

## 4. Historias de usuario (F1 · INVEST)
### H1 [P1] — Clarificación estructurada y trazable
Como PO/TL, quiero que las ambigüedades de un requerimiento se resuelvan con
preguntas estructuradas ANTES de F1 y queden registradas en la spec, para que
las decisiones no se pierdan en la conversación.
**Criterios de aceptación (Gherkin):**
- CA1.1 Dado un requerimiento ambiguo, cuando ejecuto /clarificar, entonces
  recibo como máximo 5 preguntas priorizadas (alcance > seguridad/privacidad >
  UX > detalle técnico) con opciones tabuladas.
- CA1.2 Dado que respondo las preguntas, cuando termina la sesión, entonces la
  spec contiene una sección `## Clarificaciones` con sesión fechada y cada
  respuesta integrada en la sección correspondiente.
- CA1.3 Dado un punto ambiguo no resuelto, cuando se redacta la spec, entonces
  queda marcado `[NECESITA CLARIFICACIÓN: …]` (máximo 3 marcadores) y la DoR
  no se cumple mientras exista alguno.

### H2 [P1] — Análisis de consistencia entre artefactos
Como revisor del gate DoR/Arquitectura, quiero un análisis automático de
consistencia entre spec, reglas de negocio, ADRs, as-is y plan de tareas, para
detectar contradicciones y huecos de cobertura antes de aprobar.
**Criterios de aceptación (Gherkin):**
- CA2.1 Dado una spec con plan de tareas, cuando ejecuto /consistencia, entonces
  recibo un informe read-only con hallazgos clasificados en 6 pases
  (duplicación, ambigüedad, subespecificación, alineación con reglas,
  cobertura requisito↔tarea, contradicciones) y severidad CRITICAL/HIGH/MEDIUM/LOW.
- CA2.2 Dado un conflicto con una regla de `.claude/rules/` o de
  `knowledge/reglas-negocio.md`, cuando se genera el informe, entonces el
  hallazgo es CRITICAL automáticamente.
- CA2.3 Dado el informe, cuando hay hallazgos CRITICAL, entonces el veredicto
  es NO PASAR AL GATE y la skill no edita ningún artefacto.

### H3 [P2] — Convergencia funcional código↔spec
Como agente de calidad (F7), quiero comparar el código real contra la spec al
cerrar la construcción, para que el trabajo restante quede visible como tareas
y no como drift silencioso.
**Criterios de aceptación (Gherkin):**
- CA3.1 Dado una spec con tareas marcadas hechas, cuando ejecuto /convergir,
  entonces cada historia/CA se evalúa contra el código real (evidencia
  archivo:línea) con estado SATISFECHO / PARCIAL / AUSENTE.
- CA3.2 Dado trabajo faltante, cuando termina la evaluación, entonces se AÑADE
  una sección `### Convergencia (fecha)` al plan de tareas — append-only,
  nunca reescribe ni borra tareas existentes.
- CA3.3 Dado que todo está satisfecho, cuando termina la evaluación, entonces
  el plan de tareas queda byte a byte sin cambios y el informe lo declara.

### H4 [P2] — Criterios de éxito medibles y entrega incremental
Como PO, quiero criterios de éxito de negocio (SC-xx) medibles y agnósticos de
tecnología, e historias priorizadas P1/P2/P3 independientemente testeables,
para certificar contra resultados y poder entregar un MVP con solo las P1.
**Criterios de aceptación (Gherkin):**
- CA4.1 Dado la plantilla de spec, cuando creo una spec nueva, entonces existe
  la sección `Criterios de éxito` con SC-xx medibles, separada de las historias.
- CA4.2 Dado las historias, cuando se redactan, entonces cada una lleva
  prioridad [P1]/[P2]/[P3] y las P1 por sí solas constituyen un MVP viable.
- CA4.3 Dado el plan de tareas, cuando dos tareas no comparten archivos ni
  dependencias, entonces pueden marcarse `[P]` (paralelizables).

## 5. Estimación (F2)
| Historia | Puntos | Complejidad | Supuestos |
|---|---|---|---|
| H1 clarificar + marcadores | 3 | baja | patrón probado en spec-kit |
| H2 consistencia | 5 | media | 6 pases adaptados a artefactos de la fábrica |
| H3 convergir | 3 | baja-media | reutiliza as-is + grafo MCP para evidencia |
| H4 plantilla + DoR | 2 | baja | solo edición de plantilla y skill existente |
Prioridad WSJF: H1 → H4 → H2 → H3 (H1/H4 desbloquean specs mejores desde ya;
H2 protege los gates; H3 rinde al cerrar la próxima construcción).

## 6. Análisis (F4)
**Reglas de negocio:** RN-F1 el proceso es proporcional al riesgo (el triage F0
decide si /clarificar aplica); RN-F2 ninguna skill nueva edita artefactos que
no le pertenecen (/consistencia y /spec-review son read-only; /convergir solo
añade al plan de la spec); RN-F3 un marcador `[NECESITA CLARIFICACIÓN]`
pendiente bloquea la DoR.
**Dependencias:** ninguna externa; todo es workspace. El grafo MCP
codebase-memory es opcional para /convergir (degradación elegante como /as-is).
**Casos límite:** spec sin sección de clarificaciones (skill la crea) · más de
3 ambigüedades (priorizar por impacto, el resto se asume y documenta en
Supuestos) · /convergir sobre spec sin tareas hechas (informa, no añade) ·
/consistencia sobre spec sin plan (pase E se omite y se declara) · re-ejecución
de /convergir (idempotente: no duplica tareas ya añadidas).
**Regulatorio:** N/A (sin datos personales; artefactos internos).

## 7. Diseño (F5)
**Contratos:** N/A (sin API). **ADRs:** decisión registrada en esta spec:
adoptar mecánicas spec-kit manteniendo spec-anchored + gates con permisos
(consenso Thoughtworks Radar vol. 33/34, DORA 2025, McKinsey 2025).
**Threat model (STRIDE):** no aplica — skills read-only o append-only sobre
artefactos de texto, sin credenciales ni superficies nuevas.
**NFRs:** /consistencia y /convergir terminan en una sola pasada de lectura;
informes ≤ 50 hallazgos (límite de spec-kit) priorizados por severidad.

## 8. Plan de tareas (F6)
- [x] T1 [workspace] actualizar `specs/_template.md`: sección Clarificaciones,
      marcadores [NECESITA CLARIFICACIÓN], sección Criterios de éxito (SC-xx),
      prioridades [P1]/[P2]/[P3] en historias, marcador [P] en tareas
- [x] T2 [workspace] skill `/clarificar` (.claude/skills/clarificar)
- [x] T3 [workspace] skill `/consistencia` (.claude/skills/consistencia)
- [x] T4 [workspace] skill `/convergir` (.claude/skills/convergir)
- [x] T5 [workspace] actualizar `/spec-review`: DoR incorpora marcadores
      pendientes, SC-xx medibles e historias priorizadas
- [x] T6 [workspace] integrar en `/orquestar` (F0, F3, F5 y F7), en
      `/spec-create` (triage 0.4 y cierre de F3) y en `CLAUDE.md` + README

## 9. Certificación (F7)
Verificación técnica ejecutada el 2026-07-19 en `feature/mejoras-spec-kit`:
- Las 3 skills cargan: frontmatter válido y registradas por el harness en
  la sesión (clarificar, consistencia, convergir disponibles como /comando),
  con permisos de mínimo privilegio (Read Glob Grep [+Edit solo la spec]).
- `specs/_template.md` contiene las 5 incorporaciones (marcadores,
  Clarificaciones, Criterios de éxito, prioridades, convergencia en prosa).
- `/orquestar` referencia las 3 skills (clarificar en F0; consistencia en
  F3 y F5; convergir en F7) y `/spec-create` las incorpora (0.4 y F3).
- Revisión multi-agente independiente (26 agentes, 2026-07-19): 10 hallazgos
  confirmados, corregidos en esta misma rama (permisos, criterio de gate
  único, marcador [P], placeholder de plantilla, destinos de supuestos,
  integración en spec-create y honestidad de esta sección).
- MVP = historias P1 (H1 clarificación + H2 consistencia); H3/H4 son P2.
- RN-F1..F3 son reglas de proceso nuevas, candidatas a promoverse a
  knowledge/reglas-negocio.md al aprobarse el PR.
Veredicto del agente: la verificación técnica pasa.
Gate QA/PR: aprobado por Marcos Maripangue el 2026-07-19, tras revisar el
diff completo de la rama (10 commits, 10 archivos) y el informe de la
revisión multi-agente con sus correcciones aplicadas. Con esta aprobación
RN-F1..F3 quedan promovidas a knowledge/reglas-negocio.md.

## 10. Trazabilidad
Origen: análisis comparativo dev-sdd-kit vs github/spec-kit + referencias
mundiales (sesión 2026-07-19). Respaldo previo:
`~/Documents/backups/dev-sdd-kit-backup-2026-07-19.tar.gz` y
`dev-sdd-kit-2026-07-19.bundle`. Rama: `feature/mejoras-spec-kit`.
Fuentes clave: github.com/github/spec-kit (spec-driven.md, templates/commands/) ·
dora.dev/dora-report-2025 · mckinsey.com "The State of AI 2025" ·
martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html ·
thoughtworks.com/radar (spec-driven development, Assess).
