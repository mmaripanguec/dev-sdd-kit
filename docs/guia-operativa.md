# Workspace · Fábrica Digital Multi-Repo

> Guía operativa completa (español — idioma de trabajo de la fábrica).
> Portada pública del proyecto en inglés: [README.md](../README.md).

Workspace de la fábrica digital para **desarrollar y mantener cualquier
sistema** de uno o más repositorios de código. El usuario ingresa un repo
(URL git o ruta local) y la fábrica configura sola su clonado, registro,
contexto, indexación y análisis, dejándolo listo para especificar
requerimientos vía specs.

| Pieza | Rol |
|---|---|
| `repos.yaml` | **Registro del sistema**: qué repos lo componen, proveedor git, rol, entrypoint, orden de despliegue y perfil de dominio. Única fuente de verdad de la topología |
| `repos/<nombre>/` | Los repos de código del sistema (gitignoreados aquí; cada uno es su propio git) |
| este workspace | **Contexto compartido del sistema**: specs, conocimiento (ADRs, incidentes, reglas, mapa as-is), skills, agentes y harness para Claude Code |

**Principio multi-repo:** el código vive en cada repo; el conocimiento del
sistema vive aquí. Ningún repo individual puede contener el contexto del
conjunto — la arquitectura real solo es visible desde arriba.

El sistema (repos, proveedores, roles, orden de deploy) se declara en
`repos.yaml`, creado al instanciar la plantilla con
`./scripts/init-system.sh` y poblado con `/repo-add`.

---

## Tabla de contenidos

1. [Requisitos previos](#1-requisitos-previos)
2. [Instalación paso a paso](#2-instalación-paso-a-paso)
3. [Autenticación con Bitbucket](#3-autenticación-con-bitbucket)
4. [Estructura completa del proyecto](#4-estructura-completa-del-proyecto)
5. [Uso diario](#5-uso-diario)
6. [El ciclo E2E de 9 fases y sus gates](#6-el-ciclo-e2e-de-9-fases-y-sus-gates)
7. [Mapa AS-IS: el estado real del sistema](#7-mapa-as-is-el-estado-real-del-sistema)
8. [Memoria compartida](#8-memoria-compartida)
9. [CI/CD: Bitbucket Pipelines](#9-cicd-bitbucket-pipelines)
10. [Solución de problemas](#10-solución-de-problemas)
11. [Gobernanza del contexto](#11-gobernanza-del-contexto)
12. [Estándares aplicados](#12-estándares-aplicados)
13. [Principios no negociables](#13-principios-no-negociables)

---

## 1. Requisitos previos

- **git** ≥ 2.30 (`git --version`)
- **bash** — los scripts son compatibles con el bash 3.2 nativo de macOS; no
  requieren instalar nada con Homebrew
- **python3** — viene con macOS (Command Line Tools); lo usa el hook de
  sincronización del as-is
- **Claude Code** — `npm install -g @anthropic-ai/claude-code` (ver
  https://code.claude.com/docs)
- Para repos privados: token o llave SSH del proveedor git correspondiente
  (GitHub / GitLab / Bitbucket; ver §3)

---

## 2. Instalación paso a paso

> **Guía paso a paso completa** (repo existente → contexto → primer
> requerimiento): [docs/instructivo-repo-existente.md](docs/instructivo-repo-existente.md)
> **Documento integral navegable** (arquitectura, especificación técnica,
> modelo y guía de uso): [docs/arquitectura.html](docs/arquitectura.html) —
> derivado del código; regenerar con `./scripts/docs.sh` (el CI también lo hace).

### Opción 0 — ¿Dónde comienza todo? Instanciar la plantilla

Este repo es la **plantilla de la fábrica**. Cada sistema trabaja en su
propio clon (funciona igual con URL remota o ruta local):

```bash
git clone <plantilla> mi-sistema-workspace && cd mi-sistema-workspace
git remote rename origin upstream          # updates de la fábrica: git pull upstream main
./scripts/init-sistema.sh mi-sistema --pack-prefix ms
```

`init-sistema.sh` deja la instancia limpia (sin los datos de ejemplo) con
su `repos.yaml` esqueleto, el marcador `.instancia` y el commit inicial.
Producto (scripts/skills/reglas) e instancia (registro/specs/knowledge/
packs) viven en archivos distintos: las mejoras de la plantilla se traen
con `git pull upstream main` sin tocar tu contexto.

### Opción A — Sistema nuevo: ingresar repos uno a uno (onboarding)

```bash
# 1. Clonar (o crear) el workspace y entrar
cd <workspace>

# 2. Si el repo es privado: credenciales del proveedor en .env (ver §3)
cp .env.example .env && chmod 600 .env

# 3. Ingresar cada repo del sistema (URL git o ruta local)
./scripts/repo-add.sh https://github.com/mi-org/mi-frontend.git --role "frontend web" --entrypoint
./scripts/repo-add.sh git@gitlab.com:mi-org/mi-api.git --role "API de negocio" --deploy-order 1
#    Clona en repos/, registra en repos.yaml y siembra CLAUDE.md en el repo.
#    Desde Claude Code es aún mejor: `/repo-add <url>` además completa el
#    CLAUDE.md con datos reales e indexa el repo en codebase-memory
#    (dos modos: motor directo o fachada de flota/Postgres — ver §10 y
#     docs/codebase-memory-setup.md; el onboarding no se bloquea si falla).

# 4. Generar el mapa as-is + el documento de arquitectura, y commitear
./scripts/generate-as-is.sh   # genera knowledge/as-is/ y knowledge/architecture/
git add repos.yaml knowledge/as-is knowledge/architecture && git commit -m "chore(repos): sistema inicial"

# 5. Abrir Claude Code SIEMPRE desde la raíz del workspace
claude          # verificar contexto cargado con /context
```

### Opción B — Sistema ya registrado: preparar una máquina nueva

```bash
cp .env.example .env && chmod 600 .env    # credenciales según proveedores del registro
./scripts/setup.sh                        # clona/actualiza TODOS los repos de repos.yaml
./scripts/generate-as-is.sh
claude
```

Segunda vez y siguientes: `./scripts/setup.sh` actualiza los repos con
`pull --ff-only`; no re-clona. Ambos scripts validan credenciales ANTES de
clonar y diagnostican si fallan.

---

## 3. Autenticación por proveedor git

Cada repo declara su `provider` en `repos.yaml` (`github | gitlab |
bitbucket | local`) y los scripts resuelven las credenciales desde `.env`:

| Proveedor | Variables en `.env` | Notas |
|---|---|---|
| GitHub | `GITHUB_TOKEN` (+ `GITHUB_USER` opcional) | PAT con lectura de contenidos; usuario default `x-access-token` |
| GitLab | `GITLAB_TOKEN` (+ `GITLAB_USER` opcional) | PAT con scope `read_repository`; usuario default `oauth2` |
| Bitbucket | `BITBUCKET_USER` + `BITBUCKET_TOKEN` | El usuario depende del tipo de token — detalle abajo |
| local | — | Clona desde la ruta declarada, sin credenciales |

En todos los casos el token se inyecta con *credential helper* efímero:
**nunca queda escrito** en `.git/config`, en URLs ni en el historial. Las
URLs `git@…` usan la llave SSH cargada (pre-flight con diagnóstico).

### Bitbucket en detalle

`setup.sh` elige el modo automáticamente, en este orden:

| Modo | Cuándo se activa | Cómo funciona |
|---|---|---|
| **Token (recomendado)** | Existe `BITBUCKET_TOKEN` en `.env` o en el entorno | HTTPS con *credential helper* efímero: el token se inyecta al vuelo y **nunca queda escrito** en `.git/config`, en las URLs de los remotes ni en el historial de shell |
| **SSH** | No hay token | `git@bitbucket.org:...` con pre-flight de 8s que diagnostica llave/red antes de intentar clonar |
| **HTTPS manual** | `GIT_PROTOCOL=https BITBUCKET_USER=usuario ./scripts/setup.sh` | git pide el App Password interactivamente |

### El tipo de token determina el usuario

Este es el error más común. En `.env`:

| Tipo de token | `BITBUCKET_USER` | Dónde se crea |
|---|---|---|
| App Password | Tu usuario Bitbucket (ej. `mmaripanguec`) | bitbucket.org → Personal settings → App passwords |
| API token de Atlassian (sin scopes) | Tu **email** de la cuenta | id.atlassian.com → Security → API tokens |
| API token **con scopes** (~190+ chars) | Email para la API; **para git**: `x-bitbucket-api-token-auth` (setup.sh v5 lo aplica solo) | id.atlassian.com → Security → API tokens → with scopes; requiere scopes Account:Read + Repositories:Read |
| Access Token de repo/proyecto/workspace | Literalmente `x-token-auth` | Repository/Workspace settings → Access tokens |

Permiso mínimo del token: **Repositories: Read** (Write solo si harás push).
Tu contraseña normal de Bitbucket **no sirve** para git desde 2022.

Verificación manual del token (mismo mecanismo que usa el script):

```bash
set -a; . ./.env; set +a
git -c credential.helper= \
    -c credential.helper='!f() { printf "username=%s\npassword=%s\n" "$BITBUCKET_USER" "$BITBUCKET_TOKEN"; }; f' \
    ls-remote https://bitbucket.org/<workspace-bitbucket>/<repo>.git | head -3
```

---

## 4. Estructura completa del proyecto

```text
<workspace>/                         # ══ Repo del CONTEXTO (este) ══
│
├── README.md                        # Este documento
├── CLAUDE.md                        # Contexto del SISTEMA (carga en toda sesión)
├── CLAUDE.local.md                  # (opcional, gitignoreado) notas personales
├── repos.yaml                       # ══ REGISTRO del sistema: única fuente de
│                                    #    verdad de la topología (repos, roles,
│                                    #    entrypoint, deploy_order, dominio)
├── .env.example                     # Plantilla de credenciales → copiar a .env
├── .gitignore                       # ignora .env, repos/*/, flags temporales
├── bitbucket-pipelines.yml          # CI: sincronización del mapa as-is (§9)
│
├── .claude/                         # ══ Configuración compartida de Claude Code ══
│   ├── settings.json                # Permisos (enforcement de gates) + hooks as-is
│   ├── rules/                       # Reglas modulares (las con `paths` cargan por ruta)
│   │   ├── code-style.md            #   Google Style Guides · eng-practices
│   │   ├── testing.md               #   TDD · pirámide de tests · ISO 25010
│   │   ├── security.md              #   NIST SSDF/800-218A · Microsoft SDL · OWASP
│   │   ├── api-design.md            #   Service domains · Google AIP
│   │   ├── domain-banking.md        #   Perfil OPCIONAL (repos con domain: banking)
│   │   └── observability.md         #   Google SRE: señales doradas, SLOs
│   ├── skills/                      # Workflows invocables con /comando (§5)
│   │   ├── repo-add/                #   Onboarding de un repo al sistema
│   │   ├── spec-create/  spec-review/  implement-task/
│   │   ├── harness-init/ orquestar/
│   │   └── as-is/  as-is-sync/  as-is-learn/
│   └── agents/                      # Subagentes por fase del ciclo E2E (§6)
│       ├── requirements.md  estimation.md  analysis.md  architecture.md
│       ├── quality.md  release.md  operations.md
│
├── specs/                           # ══ Fuente de verdad del QUÉ ══
│   └── _template.md                 # Plantilla (tareas etiquetadas [<repo-registrado>])
│
├── knowledge/                       # ══ Memoria compartida del sistema ══
│   ├── standards.md                # Mapa estándar → archivo donde se aplica
│   ├── business-rules.md            # Reglas de dominio numeradas (RN-xx)
│   ├── usage.md                       # Métricas DORA · estimado vs. real · adopción
│   ├── decisiones/                  # ADRs (Nygard) + expedientes CAB
│   ├── incidentes/                  # Postmortems sin culpables (Google SRE)
│   ├── as-is/                       # ══ Estado REAL derivado del código (§7) ══
│   │   ├── INDEX.md                 #   Índice con sellos de commit por repo
│   │   ├── system.md                #   Inventario + grafo cross-repo
│   │   └── <repo>/                  #   modules.md · api-surface.md por repo
│   └── architecture/                # ══ Doc de arquitectura arc42+C4 (§7) ══
│       ├── <sistema>.md · .html     #   Generado (contexto para agentes)
│       └── <sistema>.narrative.md   #   Análisis curado (lo escribe /system-map)
│
├── harness/                         # Soporte multi-sesión (init.sh, feature_list, bitácora)
│
├── scripts/
│   ├── repo-lib.sh                  # Librería del registro (parseo, validación, auth)
│   ├── repo-add.sh                  # Alta idempotente de un repo en el sistema
│   ├── setup.sh                     # Clona/actualiza TODOS los repos del registro
│   ├── generate-as-is.sh            # Mapa as-is del sistema · --check
│   ├── generate-architecture.sh     # Doc de arquitectura arc42+C4 (.md + .html)
│   ├── dora.sh                      # Métricas DORA en knowledge/usage.md · --check
│   ├── docs.sh                      # docs/arquitectura.html derivado · --check
│   └── tests/                       # 4 suites bash 3.2 (repo-lib · dora · docs · architecture)
│
├── templates/
│   ├── CLAUDE.repo.md               # Plantilla que repo-add/setup siembran por repo
│   ├── knowledge-architecture.md · .html · .narrative.md  # Doc de arquitectura
│   └── skill-architecture.md        # Skill de contexto <prefijo>-architecture
│
└── repos/                           # ══ Los repos del sistema (gitignorados) ══
    └── <nombre>/                    #    su propio git · su propio CLAUDE.md
```

**Regla de commits:** el código se commitea **dentro del repo correspondiente**
(`git -C repos/<repo> …`); el conocimiento (specs, ADRs, as-is, incidentes) se
commitea **en este workspace**.

---

## 5. Uso diario

| Comando | Qué hace | Quién invoca |
|---|---|---|
| `/repo-add <url-o-ruta>` | Ingresa un repo al sistema: clona, registra en repos.yaml, completa su CLAUDE.md con datos reales, lo indexa en codebase-memory y regenera el as-is. Deja el repo listo para `/spec-create` | Humano o Claude |
| `/repo-map <repo>` | Genera el **pack de contexto** del repo (skill cargable `<prefijo>-<repo>`): arquitectura, mecanismos, trampas — con evidencia archivo:línea, sello y aserciones. Es el contexto que los agentes cargan al especificar sobre ese aplicativo | Humano o Claude |
| `/system-map` | Pack de sistema (`<prefijo>-sistema`: modelo mental y uniones entre repos) + índice `mapa-sistemas`. Verificación: `scripts/assertions.sh` y `scripts/freshness.sh` | Humano o Claude |
| `/as-is <pregunta>` | Responde sobre el estado real del sistema (módulos, quién llama a quién, endpoints) usando el grafo de código indexado + el mapa persistido; advierte si el mapa está desactualizado | Humano o Claude |
| `/as-is-sync` | Regenera el mapa, resume el cambio en lenguaje de arquitectura y **escala si detecta drift arquitectónico** | Humano o Claude |
| `/spec-create <nombre>` | Construye una spec por capas (F1–F5) con parada en cada gate | Humano o Claude |
| `/spec-review <ruta>` | Audita la spec contra la Definition of Ready (13 puntos) | Humano o Claude |
| `/clarify <spec\|tema>` | Resuelve ambigüedades con preguntas estructuradas (máx. 5) y registra las respuestas en la sección Clarificaciones de la spec | Humano o Claude |
| `/consistency <ruta>` | Análisis read-only de consistencia cruzada spec↔reglas↔ADRs↔as-is↔plan (6 pases, severidades); CRITICAL bloquea el gate | Humano o Claude |
| `/converge <ruta>` | Compara el código real contra la spec al cerrar F6 y añade las brechas como tareas de convergencia (append-only) | Humano o Claude |
| `/implement-task <spec> <T#>` | Una tarea del plan, con TDD estricto, en el repo que indique la etiqueta `[pwa|proxy|backend]` | Humano o Claude |
| `/harness-init <spec>` | Prepara harness multi-sesión (feature_list, init.sh, bitácora) | Humano o Claude |
| `/orchestrate <spec>` | Ciclo E2E completo con gates registrados | **Solo humano** |

Ejemplos de sesión:

```
/as-is ¿qué endpoints del backend consume el proxy?
/spec-create transferencias-3ds
/orchestrate specs/2026-07-transferencias-3ds.md
```

Una feature que cruza repos = **una sola spec** en el workspace, con tareas
etiquetadas por repo. Orden de despliegue por defecto: **backend → proxy → pwa**
(el consumidor nunca se despliega antes que su proveedor).

---

## 6. El ciclo E2E de 9 fases y sus gates

```
F1 Requerimiento → F2 Estimación → F3 Refinamiento → F4 Análisis → F5 Diseño
      [PO/TL]                          [DoR]                      [Arquitectura]
→ F6 Construcción → F7 Certificación → F8 Paso a producción → F9 Operación
                        [QA/PR]           [Comité CAB]          [DevOps/SRE]
```

| Fase | Agente | Produce | Gate |
|---|---|---|---|
| F1 Requerimiento | `requirements` (INVEST + Gherkin) | Historias en la spec | PO / TL |
| F2 Estimación | `estimation` (Fibonacci + WSJF) | Puntos + prioridad | — |
| F3 Refinamiento | loop `/spec-review` | Spec "aprobada" | DoR |
| F4 Análisis | `analysis` | Reglas, dependencias, casos límite | — |
| F5 Diseño | `architecture` (C4 + ADR + STRIDE) | Contratos + ADRs | Arquitectura |
| F6 Construcción | `/implement-task` + harness | Commits por tarea | — |
| F7 Certificación | `quality` (ISO 25010 + OWASP) | Veredicto trazable | QA / PR |
| F8 Producción | `release` (ITIL + SBOM) | Expediente de riesgo | Comité CAB |
| F9 Operación | `operations` (SRE) | Postmortems + DORA | DevOps / SRE |

Los gates se implementan en tres capas: instrucción al orquestador (prohibido
saltarlos; registra quién/cuándo/commit), control de invocación
(`disable-model-invocation` en skills con efectos) y **enforcement técnico**:
`settings.json` niega a los agentes kubectl, terraform, clouds, push a main y
lectura de secretos. *Un gate solo en prosa es una sugerencia; respaldado por
permisos es una barrera.*

---

## 7. Mapa AS-IS: el estado real del sistema

Principio: **el as-is se deriva, no se redacta.** `knowledge/as-is/` solo lo
escribe `scripts/generate-as-is.sh`; cada archivo lleva el sello
`[GENERADO] desde <repo>@<commit> el <fecha>`.

Vistas generadas: `system.md` (inventario de repos con commit/rama/tamaño +
**grafo de comunicación cross-repo**, derivado cruzando las rutas que cada repo
expone contra las que los demás consumen) y por repo `modules.md` /
`api-surface.md`.

Sincronía en tres capas:

1. **Hook de sesión** — al editar código en `repos/` se marca un flag; al cerrar
   el turno, Claude Code regenera el mapa automáticamente.
2. **CI** — el pipeline sincroniza el mapa en cada merge a main y por schedule
   diario (§9). `generate-as-is.sh --check` devuelve exit 1 si hay drift.
3. **Estado vivo** — `/as-is` compara el HEAD de cada repo contra el sello del
   mapa y advierte si está viejo antes de responder.

La distinción que gobierna todo: el **as-is** dice *qué hay*; los **ADRs** dicen
*por qué*; las **specs** dicen *qué debería haber*. La brecha entre ellos es
trabajo pendiente o drift arquitectónico — y `/as-is-sync` la escala al gate de
Arquitectura en vez de normalizarla.

### Documento de arquitectura (arc42 + C4) — contexto para agentes

Además del as-is crudo, la fábrica **genera un documento de arquitectura
consolidado** en `knowledge/architecture/<sistema>.md` (y su gemelo `.html` con
diagramas C4 en Mermaid). Lo produce `scripts/generate-architecture.sh`, que se
ejecuta al final de `generate-as-is.sh` — es decir, **tras cada indexación con
`/repo-add`**. Combina un análisis **curado** por sistema
(`knowledge/architecture/<sistema>.narrative.md`, que escribe `/system-map`,
sembrado desde `templates/knowledge-architecture.narrative.md`) con **datos
derivados** del código (topología, dependencias, conteos, sellos). Los templates
del documento (`.md`/`.html`) viven en `templates/knowledge-architecture.*`.

`/system-map` además crea el skill de contexto `<prefijo>-architecture`
(desde `templates/skill-architecture.md`), que los agentes cargan al consultar
por el sistema o cualquiera de sus repos. Sigue una **política "documentación
primero"**: se responde desde el documento y los context packs; el **código
solo se consulta ante dudas no documentadas** que el humano no pueda resolver —
y entonces se actualiza la narrativa, se regenera el documento y se añade una
aserción. Así el contexto se mantiene sin re-indexar ni releer el código en cada
consulta.

> Producción: reemplazar los detectores genéricos (grep) por la herramienta del
> stack — dependency-cruiser/madge (JS·TS), pydeps (Python), ArchUnit (Java) —
> y derivar el grafo cross-repo de los contratos OpenAPI cuando existan.

---

## 8. Memoria compartida

| Contenido | Dónde | Escribe | Lee |
|---|---|---|---|
| Requisitos | `specs/` | F1–F4 | Todas las fases |
| Decisiones | `knowledge/decisions/` | F5, F8 | F6, F7, specs futuras |
| Incidentes | `knowledge/incidents/` | F9 | F1 y F4 futuras |
| Uso/DORA | `knowledge/usage.md` | F9 | F1, F2, F8 |
| Reglas de negocio | `knowledge/business-rules.md` | F4 + gobernanza | Todas |
| Estado real | `knowledge/as-is/` | Solo el generador | F5 y consultas |
| Arquitectura (arc42+C4) | `knowledge/architecture/` | Generador + `/system-map` (narrativa) | Agentes y consultas de arquitectura |

Trazabilidad completa: spec → ADRs → commits (en su repo) → expediente CAB →
postmortem → de vuelta a la spec. **Si no está en git, no existe.**

---

## 9. CI/CD: Bitbucket Pipelines

`bitbucket-pipelines.yml` define el paso `sync-as-is`: clona los repos del
registro con `setup.sh` (modo token), regenera el mapa y commitea si cambió.
Si el workspace vive en GitHub, `templates/github-actions-as-is.yml` es el
workflow equivalente (copiarlo a `.github/workflows/`).

Configuración (una vez):

1. Repository settings → **Repository variables**: crear `BITBUCKET_USER` y
   `BITBUCKET_TOKEN` (marcar **Secured**). Mismos valores que el `.env` local.
2. Repository → Pipelines → **Schedules**: programar `custom: as-is-sync`
   diario, para capturar cambios de los repos aunque nadie toque el workspace.

Disparadores: manual (`custom: as-is-sync`), cada merge a `main` del workspace,
y el schedule.

---

## 10. Solución de problemas

**`setup.sh: line NN: name…: unbound variable` (macOS)**
Estás corriendo una versión antigua del script con bash 3.2 (el nativo de macOS,
que parsea mal `$variable` pegada a caracteres como `…`). Actualiza
`scripts/setup.sh` a la versión actual del repo: usa `${var}` con llaves y solo
ASCII, corre con el bash nativo sin instalar nada.

**El clone se queda colgado sin mensaje**
Era el modo HTTPS esperando credenciales que nunca llegaban. La versión actual
no puede colgarse: valida las credenciales ANTES de clonar (pre-flight) y con
token usa `GIT_TERMINAL_PROMPT=0` (falla rápido con mensaje en vez de esperar).
Si venías de un Ctrl+C, limpia el clone a medias: `rm -rf repos/<repo>` — el
script además lo detecta y te lo indica.

**La API acepta el token (HTTP 200) pero git falla con "Authentication failed"**
Firma clásica de un API token **con scopes**: git exige el usuario
`x-bitbucket-api-token-auth` (setup.sh v5 lo resuelve solo). Si aun así falla,
el token no incluye los scopes de git: recrearlo sin scopes, o con
Account:Read + Repositories:Read. Diagnóstico: `./scripts/diag-bitbucket.sh`
prueba ambas variantes automáticamente.

**`ERROR - Bitbucket rechazo el token`**
Casi siempre es mismatch tipo de token ↔ usuario (ver tabla en §3). Revisa
también: permiso `Repositories: Read`, acceso al workspace Bitbucket del repo,
token no vencido. El mensaje de error incluye el comando de prueba manual.

**SSH: `Permission denied (publickey)`**
`ssh-add ~/.ssh/id_ed25519` (o `id_rsa`) y verifica que la llave pública esté en
bitbucket.org → Personal settings → SSH keys.

**SSH: timeout / colgado (típico en red o VPN corporativa que bloquea puerto 22)**
Usa SSH por 443 agregando a `~/.ssh/config`:
```
Host bitbucket.org
  HostName altssh.bitbucket.org
  Port 443
```
O directamente el modo token (§3), que va por HTTPS/443.

**Cloné un repo por HTTPS y ahora quiero SSH (o viceversa)**
`git -C repos/<repo> remote set-url origin <nueva-url>` — o borra `repos/` y
corre `./scripts/setup.sh` de nuevo.

**El hook as-is no regenera el mapa**
Requiere `python3` en el PATH (viene con los Command Line Tools de macOS:
`xcode-select --install`). El hook falla en silencio si falta, por diseño: nunca
bloquea tu sesión.

**Indexar en codebase-memory falla con `-32601 ... no equivalent in the fleet graph`**
No es un error real: tu MCP es una **fachada de flota/Postgres** de solo lectura
que no expone `index_repository`. El onboarding no se bloquea (el as-is, los
packs y el documento de arquitectura se derivan igual). Indexa por el flujo de
*seed* de la flota y apunta un `.mcp.json` del workspace (gitignored) al
proyecto sembrado. Guía completa: `docs/codebase-memory-setup.md`.

**`/as-is` responde con datos viejos**
El sello del mapa ≠ HEAD de los repos. Corre `/as-is-sync` (o
`./scripts/generate-as-is.sh`) y commitea.

**Claude no carga el contexto esperado**
Verifica que lanzaste `claude` desde la **raíz del workspace** y corre `/context`
para ver exactamente qué archivos cargaron.

---

## 11. Gobernanza del contexto

1. **El contexto es código**: cambios a CLAUDE.md, reglas, skills y agentes
   entran por PR con revisión.
2. **Promoción**: lo aprendido en `CLAUDE.local.md` o auto-memory que sirva a
   todos → PR al contexto compartido. Regla práctica: si corriges a Claude dos
   veces sobre lo mismo, escríbelo.
3. **Revisión trimestral**: eliminar reglas obsoletas o contradictorias.
4. **Verificación**: `/context` (qué cargó) y `/doctor` (recortes sugeridos).
5. **Escala**: para más sistemas, empaquetar `.claude/` como plugin interno;
   para toda la organización, CLAUDE.md gestionado por IT (managed policy).
6. **Documentación primero (arquitectura)**: `knowledge/architecture/<sistema>.md`
   y los context packs son la fuente de contexto de los agentes; no se re-indexa
   ni relee el código para lo ya documentado. El código se consulta solo ante
   vacíos no documentados, y el hallazgo se devuelve al documento + una aserción.

---

## 12. Estándares aplicados

Mapa completo estándar → archivo en `knowledge/standards.md`. Resumen:
Anthropic (Claude Code, effective harnesses) · NIST SP 800-218/218A y AI RMF ·
OWASP Top 10/ASVS · Microsoft SDL · BIAN Service Landscape · Google AIP, Style
Guides, eng-practices y SRE · DORA four keys · INVEST/Gherkin · WSJF ·
ISO/IEC 25010 · C4 · ADR (Nygard) · ITIL 4 change enablement · SBOM ·
Developer Velocity (McKinsey) · SPACE · platform engineering (Gartner).

---

## 13. Principios no negociables

1. Ninguna feature sin spec aprobada (DoR). **La spec es la fuente de verdad.**
2. Ningún gate humano se salta; toda aprobación queda registrada (quién/cuándo/commit).
3. Los tests no se modifican para pasar; se arregla la implementación.
4. Todo artefacto de conocimiento se commitea: **si no está en git, no existe.**
5. Los agentes escalan la incertidumbre; no la resuelven adivinando.
6. **El as-is se deriva, no se redacta**; el CI mantiene el mapa honesto.
7. Los gates se respaldan con permisos, no solo con instrucciones.
8. Los secretos nunca tocan git: `.env` local con `chmod 600`, variables
   *Secured* en CI, credential helper efímero (jamás tokens en URLs).
9. Los postmortems no tienen culpables — y cada incidente deja un test o una regla.
