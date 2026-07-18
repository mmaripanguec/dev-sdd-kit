# Homebanking · Workspace del sistema (multi-repo)

## Qué es
Workspace de la fábrica para el sistema homebanking, compuesto por 3 repositorios
clonados en `repos/` (gitignoreados aquí; cada uno es su propio git):
- `repos/homebanking-pwa` — frontend PWA del cliente
- `repos/homebanking-pwa-proxy` — BFF/gateway entre PWA y backend
- `repos/homebanking-pwa-backend` — servicios de negocio

Este repo (workspace) versiona el CONTEXTO COMPARTIDO del sistema: specs,
knowledge (ADRs, incidentes, reglas, as-is), skills, agentes y harness.
El código vive en los repos; el conocimiento del sistema vive aquí.

## Comandos esenciales
- Preparar workspace: `./scripts/setup.sh` (clona/actualiza los 3 repos)
- Mapa as-is del sistema: `./scripts/generate-as-is.sh` (o /as-is-sync)
- Cada repo tiene sus propios comandos en `repos/<repo>/CLAUDE.md`

## Reglas multi-repo
1. Lanzar Claude Code SIEMPRE desde la raíz del workspace: así carga este
   contexto, y los CLAUDE.md de cada repo cargan solos al trabajar con sus archivos.
2. Los commits de código se hacen DENTRO del repo correspondiente
   (`git -C repos/<repo> …`); los commits de conocimiento, en este workspace.
3. Una feature que cruza repos = UNA spec aquí, con tareas etiquetadas por repo
   en el plan (`- [ ] T1 [pwa] …`, `T2 [proxy] …`, `T3 [backend] …`).
4. El contrato entre repos es la frontera: cambiar una API del proxy o backend
   exige actualizar el contrato (OpenAPI) y ADR si rompe compatibilidad.
5. Orden de despliegue por defecto: backend → proxy → pwa (compatibilidad
   hacia atrás; el consumidor nunca se despliega antes que su proveedor).

## Flujo de trabajo obligatorio
1. Todo cambio no trivial parte de una spec en `specs/` (/spec-create).
2. Fases y gates con /orquestar; NUNCA saltar un gate.
3. Construcción con /implement-task: TDD, un commit por tarea EN SU repo.
4. PROHIBIDO modificar tests para hacerlos pasar.
5. Ante ambigüedad: escalar al gate más cercano, no suponer.

## Mapa AS-IS (estado real derivado del código — nunca editar a mano)
- Índice: `knowledge/as-is/INDEX.md` · sistema completo: `knowledge/as-is/system.md`
- Por repo: `knowledge/as-is/<repo>/` · consultar /as-is; sincronizar /as-is-sync
- El as-is dice QUÉ HAY; los ADRs POR QUÉ; las specs QUÉ DEBERÍA HABER.

## Memoria compartida (leer bajo demanda)
- Specs: `specs/` · ADRs: `knowledge/decisiones/` · Incidentes: `knowledge/incidentes/`
- Reglas: `knowledge/reglas-negocio.md` · DORA: `knowledge/uso.md`
- Estándares: `knowledge/estandares.md`

## Convenciones
- Artefactos en español; identificadores de código en inglés.
- Conventional Commits + referencia a la spec en los 4 repos.
- Toda decisión de arquitectura → ADR. Todo incidente → postmortem sin culpables.
