# Workspace de la fábrica · Sistema declarado en repos.yaml

## Qué es
Workspace de la fábrica digital para desarrollar y mantener CUALQUIER sistema
de uno o más repositorios de código. La topología (qué repos componen el
sistema, su proveedor git, roles, entrypoint y orden de despliegue) vive en
`repos.yaml` — la ÚNICA fuente de verdad; ningún script o skill nombra repos
en duro. Los repos se clonan en `repos/` (gitignoreados aquí; cada uno es su
propio git).

Este repo (workspace) versiona el CONTEXTO COMPARTIDO del sistema: specs,
knowledge (ADRs, incidentes, reglas, as-is), skills, agentes y harness.
El código vive en los repos; el conocimiento del sistema vive aquí.
Sistema actual de ejemplo: homebanking (3 repos Bitbucket; ver repos.yaml).

## Comandos esenciales
- Ingresar un repo al sistema: `/repo-add <url-o-ruta>` (clona, registra,
  siembra CLAUDE.md, indexa en codebase-memory y genera el as-is) —
  script equivalente: `./scripts/repo-add.sh <url-o-ruta>`
- Contexto profundo (packs cargables): `/repo-map <repo>` genera el pack
  del repo (`.claude/skills/<prefijo>-<repo>`) y `/system-map` el pack de
  sistema + índice `mapa-sistemas`. Verificación: `scripts/afirmaciones.sh`
  y `scripts/frescura.sh comprobar`
- Preparar workspace en una máquina nueva: `./scripts/setup.sh`
  (clona/actualiza TODOS los repos del registro; credenciales: .env.example)
- Mapa as-is del sistema: `./scripts/generate-as-is.sh` (o /as-is-sync)
- Cada repo tiene sus propios comandos en `repos/<repo>/CLAUDE.md`

## Reglas multi-repo
1. Lanzar Claude Code SIEMPRE desde la raíz del workspace: así carga este
   contexto, y los CLAUDE.md de cada repo cargan solos al trabajar con sus archivos.
2. Los commits de código se hacen DENTRO del repo correspondiente
   (`git -C repos/<repo> …`); los commits de conocimiento, en este workspace.
3. Una feature que cruza repos = UNA spec aquí, con tareas etiquetadas por el
   nombre del repo registrado (`- [ ] T1 [<repo>] …`; `[workspace]` para
   cambios de contexto).
4. El contrato entre repos es la frontera: cambiar una API que otro repo
   consume exige actualizar el contrato (OpenAPI) y ADR si rompe compatibilidad.
5. Orden de despliegue: el `deploy_order` del registro (menor primero;
   el consumidor nunca se despliega antes que su proveedor).
6. Perfiles de dominio: un repo con `domain: banking` en el registro activa
   además `.claude/rules/domain-banking.md`.

## Flujo de trabajo obligatorio
0. Todo requerimiento arranca con el TRIAGE (F0 de /spec-create):
   ¿aplicativo existente o aplicación nueva? Se cargan los packs de
   contexto vigentes de los repos afectados; dependencias sin contexto →
   PREGUNTAR su repositorio (nunca asumir); inconsistencias → PREGUNTAR.
1. Todo cambio no trivial parte de una spec en `specs/` (/spec-create).
   Ambigüedades: /clarificar (máx. 5 preguntas; respuestas trazadas en la
   sección Clarificaciones de la spec; marcadores [NECESITA CLARIFICACIÓN]
   pendientes bloquean la DoR).
2. Fases y gates con /orquestar; NUNCA saltar un gate. Antes de los gates
   DoR y Arquitectura: /consistencia con veredicto APTO PARA GATE (el
   criterio de bloqueo lo define esa skill; no lo dupliques aquí).
3. Construcción con /implement-task: TDD, un commit por tarea EN SU repo.
4. PROHIBIDO modificar tests para hacerlos pasar.
5. Al cerrar F6: /convergir compara el código real contra la spec y añade
   las brechas como tareas (append-only) antes del veredicto de calidad.
6. Ante ambigüedad: escalar al gate más cercano, no suponer.

## Mapa AS-IS (estado real derivado del código — nunca editar a mano)
- Índice: `knowledge/as-is/INDEX.md` · sistema completo: `knowledge/as-is/system.md`
- Por repo: `knowledge/as-is/<repo>/` · consultar /as-is; sincronizar /as-is-sync
- Estructura fina (funciones, llamadas, impacto): grafo del MCP
  codebase-memory (repos indexados por /repo-add)
- Interpretación de arquitectura: packs de contexto (skills
  `mapa-sistemas` → `<prefijo>-sistema` → `<prefijo>-<repo>`), con
  evidencia archivo:línea, sello `generado_desde` y aserciones ejecutables
- El as-is dice QUÉ HAY; los packs CÓMO ESTÁ ARMADO; los ADRs POR QUÉ;
  las specs QUÉ DEBERÍA HABER.

## Memoria compartida (leer bajo demanda)
- Specs: `specs/` · ADRs: `knowledge/decisiones/` · Incidentes: `knowledge/incidentes/`
- Reglas: `knowledge/reglas-negocio.md` · DORA: `knowledge/uso.md`
- Estándares: `knowledge/estandares.md`

## Convenciones
- Artefactos en español; identificadores de código en inglés.
- Conventional Commits + referencia a la spec, en el workspace y en cada repo.
- Toda decisión de arquitectura → ADR. Todo incidente → postmortem sin culpables.
