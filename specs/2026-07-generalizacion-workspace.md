# Spec: Generalización del workspace — fábrica para CUALQUIER sistema de repos

| Campo | Valor |
|---|---|
| Estado | implementada (rama feature/generalizacion-workspace; pendiente prueba con repos remotos reales) |
| Dominio de negocio | Plataforma interna (developer platform / fábrica digital) |
| Autor / Fecha | Claude (investigación) + mmaripanguec / 2026-07-18 |
| Gate PO/TL | aprobado por mmaripanguec el 2026-07-18 (aprobación del plan de implementación en sesión) |
| Gate DoR | aprobado por mmaripanguec el 2026-07-18 (mismo acto) |
| Gate Arquitectura | aprobado por mmaripanguec el 2026-07-18 (diseño §7 incluido en el plan aprobado) |

## 1. Problema

La fábrica está diseñada como si el sistema homebanking (3 repos fijos de
Example Bank en Bitbucket) fuera el único posible. La intención real del
producto es otra: **el usuario ingresa cualquier repositorio (o conjunto de
repos) y el sistema configura solo la indexación, el análisis y los archivos
de contexto necesarios para empezar a especificar requerimientos vía specs.**

Evidencia del acoplamiento (investigación 2026-07-18, código actual):

| # | Archivo | Acoplamiento |
|---|---|---|
| A1 | `scripts/setup.sh:74,126-128` | Lista fija `homebanking-pwa/-backend/-proxy`; workspace `example-bank` hardcodeado en las URLs; pre-flight prueba contra `homebanking-pwa` |
| A2 | `scripts/setup.sh` (todo) | Solo Bitbucket: tipos de token, usuario especial `x-bitbucket-api-token-auth`, diagnósticos. Sin GitHub/GitLab/ruta local |
| A3 | `scripts/generate-as-is.sh:149,160` | Título "Sistema homebanking"; semilla del grafo `usuario((Usuario)) --> homebanking-pwa` hardcodeada |
| A4 | `CLAUDE.md` | Nombra los 3 repos, roles fijos (pwa/proxy/backend), orden de despliegue backend→proxy→pwa, etiquetas de tarea `[pwa\|proxy\|backend]` |
| A5 | `specs/_template.md:6,48-51` | "Service domain (BIAN)" (bancario); etiquetas y orden de despliegue de los 3 repos fijos |
| A6 | `templates/CLAUDE.repo.md:7` | "qué hace este repo dentro de homebanking" |
| A7 | `.claude/skills/as-is-learn/SKILL.md` | Instrucciones por-repo con los 3 nombres y sus roles hardcodeados |
| A8 | `.env.example` / `bitbucket-pipelines.yml` | Solo credenciales Bitbucket; bot `factory-bot@example.com`; CI solo Bitbucket Pipelines |
| A9 | `.claude/rules/api-design.md`, `security.md`, agentes `requisitos`/`arquitectura`/`analisis` | Vocabulario bancario entretejido con reglas genéricas: BIAN, ISO 20022, "rutas de dinero", idempotencia de pagos, monedas |
| A10 | `README.md` | Documento completo escrito para homebanking/Example Bank |
| A11 | (ausencia) | No existe flujo de ONBOARDING: nada tipo `/repo-add <url>` que clone, registre, siembre contexto e indexe un repo nuevo |
| A12 | (ausencia) | El MCP `codebase-memory` (index_repository, search_graph, trace_path, get_architecture) está disponible pero NINGÚN script/skill lo usa: el as-is se deriva solo con grep heurístico |
| A13 | (ausencia) | No hay registro de repos: la topología (quién es entrypoint, quién provee a quién, orden de despliegue) vive en prosa, no en datos |

## 2. Objetivo

Un usuario apunta la fábrica a uno o más repositorios (URL git de cualquier
proveedor o ruta local) y, con un solo comando, queda listo para
`/spec-create`: repo clonado y registrado, stack detectado, `CLAUDE.md`
sembrado con datos reales, repo indexado en codebase-memory, mapa as-is
generado y skills/agentes funcionando sin referencia alguna a homebanking.

## 3. Fuera de alcance

- Cambiar el ciclo E2E de 9 fases, sus gates o los agentes por fase (se
  parametrizan, no se rediseñan).
- Soporte de monorepos con múltiples sistemas independientes dentro.
- UI gráfica de onboarding; el flujo es CLI + skills.
- Migrar el CI a otro proveedor (se añade plantilla GitHub Actions, pero
  Bitbucket Pipelines sigue siendo el CI del workspace actual).
- Autenticación con proveedores git distintos de GitHub/GitLab/Bitbucket/local.

## 4. Historias de usuario (F1 · INVEST)

### H1 — Registrar un repositorio nuevo
Como desarrollador de la fábrica, quiero ingresar un repo por URL o ruta
local con `/repo-add`, para que el sistema lo clone, lo registre y lo deje
listo para especificar sin configuración manual.
**Criterios de aceptación (Gherkin):**
- CA1.1 Dado un workspace sin repos, cuando ejecuto `/repo-add https://github.com/org/mi-repo.git`, entonces el repo queda clonado en `repos/mi-repo`, registrado en `repos.yaml`, con `CLAUDE.md` sembrado cuyo campo de comandos refleja los scripts reales detectados (p.ej. `package.json`), e indexado en codebase-memory.
- CA1.2 Dado un repo ya registrado, cuando ejecuto `/repo-add` con la misma URL, entonces el sistema actualiza (`pull --ff-only`) en vez de re-clonar y no duplica la entrada del registro.
- CA1.3 Dado una ruta local (`/repo-add ~/proyectos/mi-app`), cuando la ruta es un repo git válido, entonces se registra sin requerir credenciales de red.
- CA1.4 Dado un repo de GitHub, GitLab o Bitbucket privado con credenciales en `.env`, cuando ejecuto el alta, entonces la autenticación usa credential helper efímero y el token nunca queda escrito en `.git/config`, URLs ni logs.

### H2 — Registro de repos como fuente de verdad de la topología
Como orquestador de la fábrica, quiero que la lista de repos, sus roles y
su orden de despliegue vivan en un archivo de datos (`repos.yaml`), para que
scripts, skills, plantillas y agentes se deriven de él en vez de tener
nombres hardcodeados.
**Criterios de aceptación:**
- CA2.1 Dado `repos.yaml` con N repos, cuando corro `./scripts/setup.sh`, entonces clona/actualiza exactamente esos N repos con el proveedor declarado por cada uno.
- CA2.2 Dado el registro, cuando corro `./scripts/generate-as-is.sh`, entonces el título del sistema, la semilla del grafo (repo marcado `entrypoint: true`) y el orden de despliegue salen del registro; con un solo repo, la sección cross-repo se omite con nota explícita.
- CA2.3 Dado el registro, cuando creo una spec, entonces las etiquetas de tarea válidas son los nombres de los repos registrados (`[mi-repo]`), no `[pwa|proxy|backend]`.
- CA2.4 Dado un workspace SIN `repos.yaml` (estado legado), cuando corre cualquier script, entonces falla con mensaje accionable que indica correr `/repo-add` o `scripts/repo-add.sh`.

### H3 — Indexación y análisis automáticos al ingresar el repo
Como desarrollador, quiero que el alta del repo dispare la indexación en
codebase-memory y la generación del as-is, para poder preguntar `/as-is`
y crear specs con contexto real desde el minuto uno.
**Criterios de aceptación:**
- CA3.1 Dado un repo recién agregado, cuando termina `/repo-add`, entonces `index_repository` del MCP codebase-memory corrió sobre él (o, si el MCP no está disponible, el reporte final lo dice explícitamente y el resto del flujo no se bloquea).
- CA3.2 Dado un repo indexado, cuando pregunto por estructura/llamadas/dependencias vía `/as-is`, entonces la skill consulta primero el grafo (search_graph/trace_path/get_architecture) y usa el mapa markdown como respaldo.
- CA3.3 Dado el alta terminada, cuando el grafo cross-repo sale vacío habiendo ≥2 repos, entonces el reporte recomienda `/as-is-learn` (que ahora recibe los nombres de repos del registro, sin nombres fijos).

### H4 — Contexto y reglas sin dominio bancario impuesto
Como usuario que trae un repo NO bancario, quiero que reglas, plantillas y
agentes hablen en términos genéricos con el dominio bancario como perfil
opcional, para que la fábrica no me imponga BIAN/ISO 20022.
**Criterios de aceptación:**
- CA4.1 Dado un workspace generalizado, cuando reviso `.claude/rules/`, entonces lo específicamente bancario (BIAN, ISO 20022, idempotencia de pagos, "rutas de dinero") vive en `rules/domain-banking.md` activable por perfil en `repos.yaml` (`domain: banking`), y las reglas base son genéricas (100% cobertura en auth y rutas críticas declaradas, no "de dinero").
- CA4.2 Dado la plantilla de spec, cuando la instancio, entonces el campo es "Dominio de negocio" (libre) y BIAN aparece solo como sugerencia del perfil bancario.
- CA4.3 Dado CLAUDE.md y README del workspace, cuando los leo, entonces describen la fábrica genérica; homebanking queda como ejemplo/perfil, no como identidad.

## 5. Estimación (F2)

| Historia | Puntos | Complejidad | Supuestos |
|---|---|---|---|
| H2 registro `repos.yaml` + refactor scripts | 8 | Alta — toca setup.sh (auth multi-proveedor) y generate-as-is.sh manteniendo bash 3.2 | El parser YAML se resuelve con python3 (ya es prerequisito) o formato TSV simple |
| H1 `/repo-add` (skill + script) | 5 | Media — orquesta clone+registro+siembra; reusa H2 | — |
| H3 integración codebase-memory | 3 | Media — skill /as-is y /repo-add; MCP ya existe | MCP disponible en la sesión; degradación elegante si no |
| H4 des-bancarización de reglas/plantillas/docs | 3 | Baja — edición de contexto, sin código | — |

Prioridad WSJF: **H2 → H1 → H3 → H4**. H2 desbloquea todo (máxima reducción
de riesgo/esfuerzo); H1 es el valor visible al usuario; H3 multiplica la
calidad del análisis; H4 es pulido de contexto sin dependencias.

## 6. Análisis (F4)

**Reglas de negocio:**
- RN-G1 El registro `repos.yaml` es la única fuente de verdad de la topología; ningún script o skill puede nombrar repos en duro.
- RN-G2 Todo secreto sigue el modelo actual: `.env` local `chmod 600`, credential helper efímero, jamás en URLs/logs/git (sin cambios respecto a hoy).
- RN-G3 El as-is se sigue derivando, nunca redactando; el registro aporta topología declarada (roles, orden), el código aporta el estado real — si contradicen, es drift y se escala.

**Dependencias:** python3 (ya prerequisito, para leer YAML desde bash) ·
MCP codebase-memory (opcional, con degradación) · compatibilidad bash 3.2.

**Casos límite:** repo sin framework detectable (stack "desconocido" y
CLAUDE.md con huecos marcados) · un solo repo (sin grafo cross-repo) ·
URL con credenciales embebidas (rechazar con mensaje) · ruta local que no
es git · repo vacío · nombre de repo duplicado entre proveedores ·
re-onboarding tras borrar `repos/` (registro intacto → solo re-clonar) ·
MCP caído a mitad del alta (CA3.1) · `repos.yaml` corrupto (validar antes
de operar, error accionable).

**Regulatorio:** ninguno nuevo; los perfiles de dominio (banking) portan
sus requisitos regulatorios propios cuando se activan.

## 7. Diseño (F5) — bosquejo para el gate de Arquitectura

**Contrato central — `repos.yaml` (versionado en el workspace):**
```yaml
system:
  name: mi-sistema          # reemplaza "homebanking" en títulos y docs
  entrypoint: mi-frontend   # semilla del grafo (usuario → entrypoint)
repos:
  - name: mi-frontend
    url: https://github.com/org/mi-frontend.git   # o ruta local
    provider: github        # github | gitlab | bitbucket | local
    role: "frontend web del cliente"
    deploy_order: 3         # menor = se despliega antes (proveedor primero)
    domain: generic         # generic | banking | <perfil futuro>
```

**Componentes:**
- `scripts/repo-lib.sh` — funciones compartidas: leer registro (vía python3),
  resolver proveedor/URL/credenciales, credential helper efímero por host.
- `scripts/repo-add.sh <url|ruta> [--role --entrypoint]` — alta idempotente:
  valida, clona, registra, siembra CLAUDE.md con datos detectados.
- `scripts/setup.sh` (refactor) — itera el registro; la lógica Bitbucket
  actual se conserva como el caso `provider: bitbucket`.
- `scripts/generate-as-is.sh` (refactor) — nombre de sistema, semilla y
  orden desde el registro; detectores de stack/rutas quedan igual.
- Skill `/repo-add` — envuelve el script y añade lo que solo Claude puede:
  autocompletar CLAUDE.md leyendo el repo real, invocar `index_repository`,
  correr as-is, sugerir `/as-is-learn` si el grafo queda pobre, y reportar
  "listo para /spec-create".
- Skills `/as-is`, `/as-is-learn`, plantillas y CLAUDE.md — parametrizados
  por el registro (H3/H4).

**ADRs a escribir en la implementación:** ADR-001 registro declarativo de
repos (alternativas: convención por carpetas, config por variables de
entorno) · ADR-002 codebase-memory como índice primario del as-is con
grep como respaldo (alternativas: solo grep, solo MCP).

**Threat model (STRIDE):** aplica — el alta acepta URLs externas
(spoofing/inyección en nombre de repo → sanitizar; el nombre del repo se
usa en rutas de archivos) y credenciales multi-proveedor (information
disclosure → mismo helper efímero actual). Mitigaciones al ADR-001.

**NFRs:** alta de un repo mediano (< 50k LOC) lista en < 5 min incluyendo
indexación; scripts siguen corriendo en bash 3.2 nativo de macOS sin
dependencias nuevas.

## 8. Plan de tareas (F6)

Todas las tareas son del workspace (este repo): etiqueta `[workspace]`.
- [x] T1 [workspace] `repos.yaml` + `scripts/repo-lib.sh` (lectura/validación del registro; tests con bats o shell asserts)
- [x] T2 [workspace] Refactor `setup.sh` sobre el registro, auth por proveedor (github/gitlab/bitbucket/local), conservando diagnósticos Bitbucket
- [x] T3 [workspace] `scripts/repo-add.sh` idempotente (clone/registro/siembra)
- [x] T4 [workspace] Refactor `generate-as-is.sh`: sistema/semilla/orden desde registro; caso 1-repo
- [x] T5 [workspace] Skill `/repo-add` (orquesta script + autocompletar CLAUDE.md + `index_repository` + as-is + reporte)
- [x] T6 [workspace] `/as-is` y `/as-is-learn` parametrizados; `/as-is` consulta el grafo MCP primero
- [x] T7 [workspace] Perfil `rules/domain-banking.md`; reglas base des-bancarizadas; plantilla de spec y `CLAUDE.repo.md` genéricas
- [x] T8 [workspace] CLAUDE.md + README genéricos (homebanking como ejemplo); plantilla GitHub Actions equivalente al pipeline
- [x] T9 [workspace] `.env.example` multi-proveedor + `diag-bitbucket.sh` → `diag-git.sh` por proveedor

Orden de despliegue: no aplica (un solo repo); orden de merge: T1→T2→T3→T4→(T5–T9 en paralelo).

## 9. Certificación (F7)
Pendiente.

## 10. Trazabilidad
Spec → ADR-001, ADR-002 (por escribir) → commits del workspace → n/a CAB (herramienta interna).
