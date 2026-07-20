# Spec: Comandos en inglés e idioma de trabajo configurable

| Campo | Valor |
|---|---|
| Estado | borrador |
| Tipo de requerimiento | existente `[workspace]` (estándar de idioma de la fábrica) |
| Contexto cargado | inventario de skills/scripts; demo del asistente; convención de idioma vigente |
| Autor / Fecha | Claude + Marcos Maripangue / 2026-07-19 |
| Gate PO/TL | aprobado por Marcos Maripangue el 2026-07-19 (directiva: comandos siempre en inglés; preguntar idioma de trabajo; demo y spec del demo en inglés) |
| Gate DoR | pendiente |
| Gate Arquitectura | N/A |

## 1. Problema
La fábrica mezcla idiomas en su superficie de comandos: 10 skills en inglés
y 4 en español (/clarificar, /consistencia, /convergir, /orquestar), y el
script de arranque se llama init-sistema.sh. Además el idioma de los
artefactos está fijado por convención (español) en vez de ser una elección
del equipo al instanciar, y el demo público (spec + interacción) está en
español — limita la audiencia global.

## 2. Objetivo
Los NOMBRES de comandos (skills y scripts de cara al usuario) son siempre
inglés; el idioma de TRABAJO (artefactos e interacciones) se pregunta al
instanciar el workspace y queda registrado en el registro (system.lang),
manteniéndose consistente después; el demo completo (spec de ejemplo,
interacción, SVG, walkthrough) queda en inglés como estándar público.

## 3. Criterios de éxito
- SC-01 Cero skills con nombre en español; toda referencia viva actualizada
  (skills, CLAUDE.md, README, plantillas HTML, walkthrough).
- SC-02 `init-system.sh` pregunta el idioma (en/es) si es interactivo,
  acepta `--lang`, y lo persiste en `repos.yaml → system.lang`; el nombre
  viejo (init-sistema.sh) sigue funcionando como wrapper.
- SC-03 El demo es 100% inglés: spec de ejemplo, comandos, preguntas al
  usuario, interacción del asistente y SVG — re-ejecutado de verdad.

## 4. Fuera de alcance
- Traducir la prosa interna de skills/reglas/knowledge de ESTE workspace
  (su idioma de trabajo es español; el estándar aplica a nombres y al demo).
- Renombrar scripts internos no expuestos en el demo (afirmaciones.sh,
  frescura.sh, generate-as-is.sh) — candidatos a spec futura.
- Actualizar specs históricas aprobadas (registran los nombres de su época).

## 5. Clarificaciones
### Sesión 2026-07-19
- P: ¿alcance del inglés obligatorio? → R: nombres de comandos + todo el
  demo público; los artefactos siguen el idioma elegido por workspace
  (decide: Marcos).

## 6. Historias de usuario (F1 · INVEST)
### H1 [P1] — Comandos en inglés
Como usuario global de la plantilla, quiero que todos los comandos tengan
nombre en inglés, para adoptarla sin barrera de idioma.
- CA1.1 /clarificar→/clarify · /consistencia→/consistency ·
  /convergir→/converge · /orquestar→/orchestrate, con toda referencia viva
  actualizada y sin nombres viejos activos.
- CA1.2 init-system.sh es el nombre oficial; init-sistema.sh delega en él.

### H2 [P1] — Idioma de trabajo elegido y persistido
Como equipo que instancia la fábrica, quiero elegir en/es al inicio y que
la fábrica lo respete en specs e interacciones.
- CA2.1 `init-system.sh <nombre> [--lang en|es]` (pregunta si TTY sin flag;
  default en) escribe `system.lang`.
- CA2.2 CLAUDE.md instruye: artefactos e interacciones en el idioma del
  registro; los identificadores y comandos siempre en inglés.

### H3 [P1] — Demo íntegramente en inglés
Como visitante del repo público, quiero el demo (spec, código del ejemplo,
interacción y SVG) en inglés.
- CA3.1 La spec de ejemplo es specs/2026-07-customer-assistant-adk.md (EN).
- CA3.2 El asistente demo opera en inglés (FAQ, avisos, CLI `assistant.*`)
  y la sesión se re-ejecuta REAL para capturar las salidas.
- CA3.3 SVG y walkthrough muestran la pregunta de idioma y la interacción
  en inglés, con la pausa de validación humana.

## 7-9. Estimación · Análisis · Diseño (resumen)
8 puntos. Riesgo principal: referencias rotas → mitigado con grep de
verificación (cero referencias vivas a nombres viejos). `system.lang` entra
a SYSTEM_FIELDS de repo-lib (parse + upsert). Wrapper de compatibilidad
para init-sistema.sh (docs en español siguen válidas).

## 10. Plan de tareas (F6)
- [x] T1 [workspace] renombrar 4 skills + actualizar referencias vivas
- [x] T2 [workspace] repo-lib system.lang + init-system.sh (pregunta/--lang)
      + wrapper init-sistema.sh + CLAUDE.md
- [x] T3 [workspace] spec demo EN (reemplaza a la ES) + README/links
- [x] T4 [workspace] demo app en inglés + re-ejecución real + SVG +
      walkthrough
- [x] T5 [workspace] sincronizar copia pública + regenerar docs + suites

## 11. Certificación (F7)
Convergencia (2026-07-19): CA1.1 ✓ (4 skills renombradas; grep sin
referencias vivas a nombres viejos fuera de specs históricas y prosa
española legítima); CA1.2 ✓ (init-system.sh oficial + wrapper probado en
clon limpio); CA2.1 ✓ (--lang validado en/es, pregunta con TTY, system.lang
persistido — verificado en ambas vías); CA2.2 ✓ (CLAUDE.md); CA3.1–CA3.3 ✓
(spec EN, app demo re-ejecutada REAL en inglés en ~/Documents/demo-assistant
— tests 5/5 rojo→verde, sesión capturada con aprobación humana
'APPROVED by mmaripanguec', SVG con pregunta de idioma, tarjetas de
artefactos HITL y pausa de validación). Suites: docs 42/42 · dora 17/17 ·
repo-lib 40/40. Gate QA/PR humano: __

## 12. Trazabilidad
Origen: directiva de Marcos (2026-07-19) sobre estándar de idioma para
alcance global. Rama: feature/english-standard.
