# Spec: Documentación de publicación en GitHub (inglés) con operación interna en español

| Campo | Valor |
|---|---|
| Estado | borrador |
| Tipo de requerimiento | existente `[workspace]` (triage F0: documentación y metadatos de publicación; no toca repos de código) |
| Contexto cargado | README actual, docs/arquitectura.html + docs.sh, convención "artefactos en español" de CLAUDE.md (sesión 2026-07-19) |
| Dominio de negocio | proceso de la fábrica (publicación open source) |
| Autor / Fecha | Claude + Marcos Maripangue / 2026-07-19 |
| Gate PO/TL | aprobado por Marcos Maripangue el 2026-07-19 (respuestas de clarificación: alcance/paquete/licencia/orden) |
| Gate DoR | pendiente |
| Gate Arquitectura | N/A — documentación y metadatos; sin arquitectura de código |

## 1. Problema
El proyecto está listo para publicarse como plantilla en GitHub, pero toda su
documentación de cara al público está en español y no existen los artefactos
estándar del ecosistema open source: README de portada en inglés, LICENSE,
CONTRIBUTING ni plantillas de issues/PR. Un visitante angloparlante no puede
evaluar ni adoptar el proyecto, y sin licencia nadie puede reutilizarlo
legalmente.

## 2. Objetivo
El repositorio queda publicable en GitHub: portada y documentos de
contribución en inglés (el estándar del ecosistema), licencia MIT declarada,
y el documento de arquitectura disponible también en inglés — mientras la
operación interna de la fábrica (skills, reglas, specs, knowledge) permanece
en español según su convención.

## 3. Criterios de éxito
- SC-01 Un visitante angloparlante entiende qué es el proyecto, cómo
  instalarlo y cómo contribuir leyendo solo archivos en inglés (README,
  CONTRIBUTING, architecture.en.html).
- SC-02 El repo cumple el estándar de publicación GitHub: LICENSE (MIT),
  CONTRIBUTING, plantillas de issue/PR — la pestaña "community standards"
  no marca faltantes básicos.
- SC-03 Ningún artefacto interno cambia de idioma: skills, reglas, agentes,
  specs y knowledge siguen en español; la guía operativa española completa
  sigue disponible y enlazada.

## 4. Fuera de alcance
- Traducir la operación interna (skills, reglas, agentes, plantillas de
  spec, knowledge) — rechazado explícitamente en clarificación.
- Crear el repositorio público / push a GitHub (acción humana con
  credenciales; esta spec deja todo listo).
- CODE_OF_CONDUCT y SECURITY.md (candidatos a spec futura si el proyecto
  recibe comunidad).
- Badges de CI/releases (dependen de la URL pública final).

## 5. Clarificaciones
### Sesión 2026-07-19
- P: ¿Alcance del inglés? → R: solo documentación pública (README,
  CONTRIBUTING, LICENSE, .github, HTML de arquitectura EN); la operación
  interna sigue en español (decide: Marcos).
- P: ¿Paquete? → R: completo — README EN + LICENSE + CONTRIBUTING +
  plantillas issues/PR + HTML de arquitectura en inglés (decide: Marcos).
- P: ¿Licencia? → R: MIT (decide: Marcos).
- P: ¿Rama docs-html pendiente? → R: aprobada y mergeada primero; esto va
  en rama propia encima (decide: Marcos).

## 6. Historias de usuario (F1 · INVEST)
### H1 [P1] — Portada pública en inglés
Como visitante de GitHub, quiero un README en inglés con qué es, por qué
existe, arquitectura resumida, quickstart y enlaces, para evaluar el
proyecto en minutos.
**Criterios de aceptación (Gherkin):**
- CA1.1 Dado el repo, cuando abro README.md, entonces está en inglés con:
  qué es / features / arquitectura (enlace al HTML) / quickstart /
  documentación / contributing / license.
- CA1.2 Dado un usuario hispanohablante, cuando busca el detalle operativo,
  entonces la guía española completa existe como docs/guia-operativa.md,
  enlazada desde el README, sin pérdida de contenido.
- CA1.3 Dado que el README se movió, cuando reviso referencias internas
  (instructivo, HTML), entonces apuntan a la guía operativa — cero enlaces
  rotos.

### H2 [P1] — Metadatos de publicación
Como adoptante u colaborador, quiero LICENSE (MIT), CONTRIBUTING.md y
plantillas de issue/PR, para saber qué puedo hacer con el código y cómo
contribuir según el proceso de la fábrica.
**Criterios de aceptación (Gherkin):**
- CA2.1 Dado el repo, cuando reviso la raíz, entonces existe LICENSE con
  texto MIT estándar y copyright 2026.
- CA2.2 Dado CONTRIBUTING.md, cuando lo leo, entonces explica en inglés el
  flujo spec-driven (spec → gates → TDD → convergencia), los tests a correr
  y la convención de commits — reflejando el proceso real, no uno genérico.
- CA2.3 Dado .github/, cuando abro un issue o PR, entonces hay plantillas
  (bug, feature, PR) en inglés; la de PR exige spec vinculada, TDD y suites
  en verde.

### H3 [P2] — Arquitectura navegable en inglés
Como visitante técnico, quiero el documento HTML de arquitectura en inglés,
para entender el modelo sin hablar español.
**Criterios de aceptación (Gherkin):**
- CA3.1 Dado `scripts/docs.sh`, cuando corre, entonces genera AMBOS:
  docs/arquitectura.html (ES) y docs/architecture.en.html (EN) desde sus
  plantillas, con los rótulos generados (cabeceras de tablas, "sin datos")
  en el idioma correspondiente.
- CA3.2 Dado el catálogo derivado (descripciones de skills, reglas RN),
  cuando aparece en la versión EN, entonces se muestra tal cual (español) con
  una nota que explica que el idioma de trabajo de la fábrica es español.
- CA3.3 Dado `--check`, cuando cualquiera de los dos difiere de lo
  recalculado, entonces exit 1; el CI regenera y commitea ambos.

## 7. Estimación (F2)
| Historia | Puntos | Complejidad | Supuestos |
|---|---|---|---|
| H1 README EN + guía ES | 3 | baja-media | mover sin pérdida; enlaces contados |
| H2 LICENSE/CONTRIBUTING/.github | 2 | baja | plantillas estándar adaptadas al proceso |
| H3 HTML EN + docs.sh bilingüe | 5 | media | rótulos parametrizados por idioma |
Prioridad WSJF: H1 → H2 → H3.

## 8. Análisis (F4)
**Reglas de negocio:** la convención de CLAUDE.md se precisa (no se
reemplaza): "artefactos internos en español; documentación pública de
GitHub en inglés". Aplican RN-F2 (docs.sh solo escribe sus salidas) y
RN-F4 ("no data" con causa en la versión EN).
**Dependencias:** ninguna nueva.
**Casos límite:** referencias internas al README movido (CA1.3) · las dos
plantillas HTML divergen en estructura (aceptado: son documentos hermanos,
cada una versionada; el catálogo inyectado es el mismo) · regeneración
parcial (docs.sh siempre genera ambos: nunca queda uno viejo) · caracteres
no ASCII en el catálogo dentro del HTML EN (mismo escape).
**Supuestos:** el nombre público del proyecto es "dev-sdd-kit" (convalida:
Marcos al crear el repo público) · copyright "Marcos Maripangue" (convalida:
Marcos) · el ejemplo homebanking del registro es aceptable como demo en el
repo público (convalida: Marcos antes del push).
**Regulatorio:** N/A.

## 9. Diseño (F5)
**Mecanismo docs.sh bilingüe:** lista de pares (plantilla → salida → idioma);
las cadenas generadas (cabeceras de tabla, "sin datos"/"no data", advertencias)
salen de un diccionario ES/EN en el python. Una sola pasada genera ambos;
`--check` compara ambos. Cero duplicación del recolector.
**Estructura pública:** README.md (EN, portada) · docs/guia-operativa.md
(ES, el README anterior íntegro) · LICENSE · CONTRIBUTING.md ·
.github/ISSUE_TEMPLATE/{bug_report.md,feature_request.md} ·
.github/PULL_REQUEST_TEMPLATE.md · docs/architecture.en.html.
**Threat model:** no aplica (documentación); sin secretos en los nuevos
archivos (regla vigente).
**NFRs:** README < 200 líneas (portada, no manual); ambos HTML < 300 KB.

## 10. Plan de tareas (F6)
- [ ] T1 [workspace] asserts EN en test-docs.sh (ambas salidas, rótulos EN,
      "no data", autocontenido) — EN ROJO
- [ ] T2 [workspace] mover README.md → docs/guia-operativa.md (íntegro) +
      README.md nuevo en inglés + corregir referencias internas
- [ ] T3 [workspace] [P] LICENSE (MIT) + CONTRIBUTING.md + .github/
      (plantillas de issue bug/feature y de PR, en inglés)
- [ ] T4 [workspace] templates/docs-architecture.en.html + docs.sh bilingüe
      hasta verde + docs/architecture.en.html generado
- [ ] T5 [workspace] [P] CI commitea ambos HTML + precisión de la
      convención de idioma en CLAUDE.md + .gitignore (.DS_Store)

## 11. Certificación (F7)
/convergir sin brechas pendientes + veredicto del agente de calidad
(incluye SC-01..03 del §3) + gate QA/PR: __

## 12. Trazabilidad
Origen: pedido de Marcos (2026-07-19) "documentación para publicar en
github… estandariza el lenguaje a inglés", clarificado en §5. Rama:
`feature/github-docs` (sobre el merge de feature/docs-html).
Referencia externa: estándares de comunidad de GitHub; licencia MIT
(misma que github/spec-kit).
