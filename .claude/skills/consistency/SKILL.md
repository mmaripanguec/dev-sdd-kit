---
name: consistency
description: Análisis read-only de consistencia cruzada entre una spec y el resto de artefactos de la fábrica (reglas de negocio, ADRs, as-is, reglas .claude/rules, plan de tareas). Usar antes del gate DoR y del gate de Arquitectura, o cuando pidan "analizar consistencia" de una spec.
argument-hint: "<ruta-de-la-spec>"
allowed-tools: Read Glob Grep
---

Analiza la consistencia de la spec $ARGUMENTS contra el conocimiento de la
fábrica. ESTRICTAMENTE READ-ONLY: no edites ningún artefacto; solo informa.

## Modelo semántico (construir primero)
1. Inventario de la spec: historias (Hx, prioridad), CA en Gherkin, SC-xx,
   RN-xx citadas, tareas del plan (Tx con etiqueta de repo).
2. Artefactos de contraste: `knowledge/reglas-negocio.md`,
   `knowledge/decisiones/` (ADRs vigentes), `knowledge/as-is/` (INDEX y repos
   afectados), `.claude/rules/*.md` (incluido el perfil de dominio si el repo
   lo declara en repos.yaml), packs de contexto de los repos afectados.

## Seis pases de detección
- **A · Duplicación**: historias/CA/SC que repiten lo mismo con otras palabras.
- **B · Ambigüedad**: adjetivos no medibles ("rápido, robusto, escalable,
  intuitivo, seguro" sin número), pronombres sin referente, marcadores
  `[NECESITA CLARIFICACIÓN]` pendientes.
- **C · Subespecificación**: historia sin CA, CA sin resultado observable,
  SC sin umbral, dependencia mencionada sin registrar en repos.yaml.
- **D · Alineación con reglas**: contradicciones con `.claude/rules/*` o con
  `knowledge/reglas-negocio.md` (RN citada que no existe, o vigente que la
  spec viola). **Todo conflicto de este pase es CRITICAL automáticamente.**
- **E · Cobertura**: requisitos (CA/SC) sin tarea en el plan y tareas sin
  requisito que las justifique — en AMBAS direcciones. Etiquetas de REPO de
  tarea que no son repos registrados ni `[workspace]` (el marcador `[P]` de
  paralelismo y las prioridades `[P1]`/`[P2]`/`[P3]` de historias no son
  etiquetas de repo; no los marques). Si la spec aún no tiene plan, omite el
  pase y decláralo.
- **F · Contradicciones**: spec vs as-is (afirma algo que el código
  contradice), spec vs ADR vigente, drift terminológico (misma entidad con
  dos nombres), tareas cuyo orden viola `deploy_order`.

## Informe (máximo 50 hallazgos)
| ID | Pase | Severidad | Ubicación | Hallazgo | Recomendación |
Severidades: CRITICAL (bloquea gate) / HIGH / MEDIUM / LOW. Después una tabla
de cobertura CA/SC ↔ tareas. Veredicto final:
- **APTO PARA GATE** — sin CRITICAL ni HIGH sin justificar.
- **NO PASAR AL GATE** — hay CRITICAL (o HIGH no justificados); lista
  priorizada de correcciones. Los cambios los aplica el ciclo
  crear-revisar-mejorar, nunca esta skill.
