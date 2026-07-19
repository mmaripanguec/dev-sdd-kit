# Spec: Documentación HTML derivada de la fábrica (arquitectura, técnica, modelo y uso)

| Campo | Valor |
|---|---|
| Estado | borrador |
| Tipo de requerimiento | existente `[workspace]` (triage F0: documentación de la fábrica; los repos del sistema no participan) |
| Contexto cargado | repos.yaml, .claude/skills+agents+rules, knowledge/, README, docs/instructivo (sesión 2026-07-19) |
| Dominio de negocio | proceso de la fábrica (documentación) |
| Autor / Fecha | Claude + Marcos Maripangue / 2026-07-19 |
| Gate PO/TL | aprobado por Marcos Maripangue el 2026-07-19 (historias H1-H4 y prioridades tal como presentadas) |
| Gate DoR | pendiente |
| Gate Arquitectura | N/A — documentación del workspace; sin arquitectura de código de sistema |

## 1. Problema
La documentación de la fábrica vive dispersa en markdown (README de 13
secciones, instructivo, CLAUDE.md, reglas, skills) y no existe una vista
integral navegable. Un desarrollador nuevo o un stakeholder no técnico no
tiene un documento único con la arquitectura, la especificación técnica, el
modelo de artefactos y la guía de uso. Además, cualquier documento redactado
a mano envejecería: hoy la fábrica tiene 13 skills, 7 agentes y 6 reglas que
cambian con cada spec.

## 2. Objetivo
Existe `docs/arquitectura.html`: un documento autocontenido, navegable y
SIEMPRE fiel al estado real de la fábrica, porque se deriva del código con
un script (patrón as-is/DORA) — arquitectura, especificación técnica, modelo
de artefactos y guía de uso en un solo archivo versionado.

## 3. Criterios de éxito
- SC-01 Un desarrollador nuevo entiende la fábrica y ejecuta su primer
  comando usando solo el HTML (sin leer el código): onboarding autocontenido.
- SC-02 El catálogo del HTML (skills, agentes, reglas, RN, topología, DORA)
  nunca difiere del código: se regenera con un comando y `--check` detecta
  drift en CI.
- SC-03 El archivo abre sin red (cero dependencias externas) en cualquier
  navegador moderno.

## 4. Fuera de alcance
- Documentar el sistema homebanking (requiere repos clonados; cuando existan
  packs/as-is reales, será otra spec).
- Lineamientos UX de las aplicaciones del sistema (la "usabilidad" pedida es
  la guía de uso de la fábrica — clarificado).
- Publicación como página web externa (Artifact/hosting); el HTML es local y
  versionado. Puede publicarse después sin cambios.
- Reescribir README/instructivo: siguen siendo la fuente markdown; solo se
  enlaza el HTML.

## 5. Clarificaciones
### Sesión 2026-07-19
- P: ¿Qué se documenta? → R: la fábrica dev-sdd-kit (el sistema homebanking
  queda para cuando haya repos clonados) (decide: Marcos).
- P: ¿Entrega? → R: `docs/*.html` autocontenido y versionado en el repo
  (decide: Marcos).
- P: ¿Mantenimiento? → R: derivado por script con sello [GENERADO], patrón
  as-is/DORA — RN-F4 aplica a la documentación (decide: Marcos).
- P: ¿"Usabilidad"? → R: guía de uso de la fábrica (onboarding, comandos por
  escenario, gates, problemas frecuentes) (decide: Marcos).

## 6. Historias de usuario (F1 · INVEST)
### H1 [P1] — Generador derivado con catálogo vivo
Como mantenedor de la fábrica, quiero que `scripts/docs.sh` genere el HTML
leyendo las fuentes reales (repos.yaml, skills, agentes, reglas, RN, specs,
bloque DORA), para que la documentación nunca mienta ni envejezca.
**Criterios de aceptación (Gherkin):**
- CA1.1 Dado el workspace, cuando corro `scripts/docs.sh`, entonces
  `docs/arquitectura.html` contiene el catálogo derivado: cada skill con su
  descripción (del frontmatter), cada agente, cada regla, las RN vigentes,
  la topología del registro y la tabla DORA vigente.
- CA1.2 Dado que agrego o edito una skill, cuando regenero, entonces el
  catálogo la refleja sin tocar el script (cero listas en duro — RN-G1).
- CA1.3 Dado el HTML generado, cuando corro `scripts/docs.sh --check`,
  entonces exit 0 si está en sincronía y exit 1 si hay drift.
- CA1.4 Dado un elemento sin fuente (p.ej. registro vacío), cuando genero,
  entonces la sección declara "sin datos" y la causa (RN-F4) — nunca inventa.

### H2 [P1] — Arquitectura y modelo navegables
Como desarrollador nuevo, quiero ver el ciclo F0–F9 con sus gates, las capas
de conocimiento (as-is / packs / ADRs / specs) y el modelo de artefactos con
su trazabilidad (spec → ADR → commits → CAB → postmortem), para formar el
modelo mental sin leer 10 archivos.
**Criterios de aceptación (Gherkin):**
- CA2.1 Dado el HTML, cuando lo abro, entonces hay navegación por secciones
  (arquitectura · especificación técnica · modelo · guía de uso) con índice.
- CA2.2 Dado el ciclo F0–F9, cuando lo consulto, entonces cada fase muestra
  quién la ejecuta (skill/agente), qué produce y qué gate humano la cierra
  — consistente con /orquestar (misma fuente).
- CA2.3 Dado SC-03, cuando abro el archivo sin red, entonces renderiza
  completo (CSS inline, diagramas SVG/HTML propios, sin CDN).

### H3 [P2] — Guía de uso (usabilidad de la fábrica)
Como desarrollador que adopta la fábrica, quiero una guía por escenario
(instalar, dar de alta un repo, crear una spec, implementar, operar) con los
comandos exactos y los problemas frecuentes, para ser productivo sin ayuda.
**Criterios de aceptación (Gherkin):**
- CA3.1 Dado el HTML, cuando abro la guía, entonces cada escenario lista sus
  comandos en orden con qué esperar de cada uno (derivado de README §
  instalación e instructivo — sin duplicar prosa a mano: se extraen del
  markdown fuente).
- CA3.2 Dado un gate humano, cuando aparece en la guía, entonces queda claro
  qué aprueba el humano y qué tiene prohibido el agente (permisos).

### H4 [P2] — Documentación existente actualizada e integrada
Como usuario del workspace, quiero que la documentación existente enlace el
HTML y que el CI lo mantenga fresco, para que haya una sola puerta de
entrada.
**Criterios de aceptación (Gherkin):**
- CA4.1 Dado el README, cuando lo leo, entonces referencia
  `docs/arquitectura.html` y el comando que lo regenera.
- CA4.2 Dado el pipeline de CI, cuando corre el paso de sincronización,
  entonces regenera también el HTML y lo commitea si cambió (mismo bloque
  que as-is/DORA).

## 7. Estimación (F2)
| Historia | Puntos | Complejidad | Supuestos |
|---|---|---|---|
| H1 generador + tests | 5 | media | frontmatter YAML parseable con el python ya usado |
| H2 plantilla arquitectura/modelo | 3 | baja-media | diagramas como HTML/SVG simple, no mermaid runtime |
| H3 guía de uso | 2 | baja | README/instructivo como fuente extraíble |
| H4 integración README + CI | 1 | baja | mismo patrón del pipeline |
Prioridad WSJF: H1 → H2 → H3 → H4 (sin generador no hay nada; la guía
aporta valor pero depende de la estructura).

## 8. Análisis (F4)
**Reglas de negocio:** aplican RN-G1 (nada en duro: el catálogo se deriva),
RN-F2 (el script solo escribe `docs/arquitectura.html`) y RN-F4 (todo dato
declara fuente o "sin datos"). Regla nueva: ninguna.
**Dependencias:** python3 + bash 3.2 (ya requeridos). Ninguna librería
nueva (HTML/CSS generado a mano; prohibido CDN por SC-03).
**Casos límite:** skill sin description en frontmatter (se lista con
advertencia) · registro vacío (topología "sin datos") · bloque DORA ausente
en uso.md (sección declara la causa) · caracteres especiales de markdown en
descripciones (escapar HTML) · regeneración sin cambios (idempotente; la
fecha del sello no cuenta como drift, patrón dora.sh) · HTML abierto en
file:// sin red (todo inline).
**Supuestos:** español como idioma único (convención del workspace) ·
tema claro y oscuro vía CSS `prefers-color-scheme` (sin JS obligatorio) ·
el HTML no contiene secretos porque sus fuentes ya están vetadas de
secretos (RN de security.md).
**Regulatorio:** N/A (documentación interna, sin datos personales).

## 9. Diseño (F5)
**Contratos:** N/A. **ADRs:** decisión en esta spec: documento derivado
híbrido — prosa estable (arquitectura, modelo, guía) vive como plantilla en
`templates/docs-arquitectura.html` con placeholders `{{...}}`; el script
inyecta el catálogo vivo (skills, agentes, reglas, RN, topología, DORA,
índice de specs). Así la prosa se versiona y revisa como texto, y los datos
nunca envejecen.
**Mecanismo:** `scripts/docs.sh [--check]` (bash 3.2 + python3): recolecta
frontmatter de `.claude/skills/*/SKILL.md` y `.claude/agents/*.md`, títulos
de `.claude/rules/*.md`, tabla RN de knowledge/reglas-negocio.md, bloque
DORA de uso.md, registro vía repo-lib.sh e índice de `specs/*.md` (nombre +
estado) → renderiza la plantilla → `docs/arquitectura.html` con sello
`[GENERADO v1] <fecha> · scripts/docs.sh` (solo fecha: incluir el commit
del propio workspace sería autorreferente — commitear el HTML lo cambiaría).
`--check` compara ignorando el sello (patrón dora.sh).
**Threat model (STRIDE):** no aplica — genera un archivo local desde
fuentes internas; sin credenciales ni red.
**NFRs:** generación < 5 s; archivo < 300 KB; sin dependencias externas;
legible en móvil (CSS responsive simple).

## 10. Plan de tareas (F6)
- [ ] T1 [workspace] tests primero (TDD): `scripts/tests/test-docs.sh` —
      fixtures y asserts de CA1.1–CA1.4 (catálogo derivado, cero listas en
      duro, --check, "sin datos"), CA2.3 (sin URLs externas) — EN ROJO
- [ ] T2 [workspace] `templates/docs-arquitectura.html` (prosa estable:
      arquitectura F0–F9, capas de conocimiento, modelo de artefactos con
      trazabilidad, guía de uso por escenario) con placeholders
- [ ] T3 [workspace] `scripts/docs.sh` hasta verde sin tocar tests +
      `docs/arquitectura.html` generado y versionado
- [ ] T4 [workspace] [P] README enlaza el HTML + CI regenera en el bloque
      de sincronización (CA4.1–CA4.2)

## 11. Certificación (F7)
/convergir sin brechas pendientes + veredicto del agente de calidad
(incluye SC-01..03 del §3) + gate QA/PR: __

## 12. Trazabilidad
Origen: pedido de Marcos (2026-07-19): "actualizar la documentación, generar
archivo html con la arquitectura y especificación técnica, modelo y
usabilidad", clarificado en §5. Rama: `feature/docs-html`.
Patrones reutilizados: scripts/dora.sh (marcadores/sello/--check),
scripts/generate-as-is.sh (derivación), repo-lib.sh (registro).
