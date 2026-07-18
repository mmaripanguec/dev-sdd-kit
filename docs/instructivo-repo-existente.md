# Instructivo · De un repo existente a su primer requerimiento

Paso a paso para incorporar un repositorio EXISTENTE a la fábrica y dejarlo
listo para especificar e implementar requerimientos. Tiempo estimado:
10–20 min de máquina + lo que tome la generación de contexto.

> Convención: los comandos `$` van en la terminal; los comandos `/` se
> escriben dentro de una sesión de Claude Code abierta en la RAÍZ del
> workspace (`claude` desde esta carpeta — verifica con `/context`).

---

## Paso -1 · ¿Dónde comienza todo? Instanciar la fábrica (una vez por sistema)

La fábrica se distribuye como **repo plantilla**: cada sistema trabaja en su
propio CLON de la plantilla (su "workspace de sistema"). Mientras la
plantilla esté local, la lógica es la misma — `git clone` acepta rutas:

```bash
# <plantilla> = URL del repo base cuando se publique, o su ruta local hoy
$ git clone <plantilla> mi-sistema-workspace
$ cd mi-sistema-workspace
$ git remote rename origin upstream        # la plantilla queda como upstream
$ git remote add origin <remoto-propio>    # (opcional) repo de contexto del sistema

$ ./scripts/init-sistema.sh mi-sistema --pack-prefix ms
```

`init-sistema.sh` limpia los datos de ejemplo que trae la plantilla
(registro, specs, as-is, packs), crea el `repos.yaml` esqueleto con el
nombre del sistema y el prefijo de sus packs, el marcador `.instancia`
(protege contra reseteos accidentales: repetirlo exige `--force`) y el
commit inicial. El PRODUCTO (scripts, skills, reglas, agentes, plantillas)
queda intacto.

**Mejoras futuras de la fábrica** llegan a la instancia con git puro:
`git pull upstream main` — producto e instancia viven en archivos
distintos, así que el merge no toca tus specs ni tu conocimiento.

> Si vas a trabajar sobre el workspace-plantilla mismo (como este), sáltate
> este paso: ya estás dentro de una instancia.

## Paso 0 · Prerrequisitos (una sola vez por máquina)

1. git ≥ 2.30, bash (el nativo de macOS sirve) y python3 (`xcode-select --install`).
2. Claude Code instalado y el workspace clonado/abierto.
3. **Solo si el repo es privado**, credenciales del proveedor:
   ```bash
   $ cp .env.example .env && chmod 600 .env
   ```
   Editar `.env` y completar según el proveedor del repo:
   - GitHub → `GITHUB_TOKEN` (PAT con lectura de contenidos)
   - GitLab → `GITLAB_TOKEN` (scope `read_repository`)
   - Bitbucket → `BITBUCKET_USER` + `BITBUCKET_TOKEN` (el usuario depende
     del tipo de token: ver la tabla dentro de `.env.example`; ante dudas
     `$ ./scripts/diag-bitbucket.sh`)
   - Ruta local o carpeta exportada sin `.git` → no necesita credenciales.

## Paso 1 · Ingresar el repo (alta + registro)

Opción recomendada — desde Claude Code (hace además los pasos 2 y 3 solo):
```
/repo-add https://github.com/mi-org/mi-app.git --role "API de pedidos" --entrypoint
```
Opción manual — solo el alta, desde terminal:
```bash
$ ./scripts/repo-add.sh https://github.com/mi-org/mi-app.git --role "API de pedidos" --entrypoint
```
Acepta URL https/ssh de GitHub/GitLab/Bitbucket, una ruta local con git, o
una **carpeta exportada sin `.git`** (queda registrada como snapshot).

Flags útiles: `--role "<qué hace>"` · `--entrypoint` (si es el repo por el
que entra el usuario) · `--deploy-order N` (menor = se despliega antes) ·
`--domain banking` (activa el perfil bancario) · `--system-name <sistema>`
y repetir el paso por cada repo si el sistema tiene varios.

**Qué esperar**: el repo clonado/enlazado en `repos/<nombre>`, la entrada
en `repos.yaml`, y un `CLAUDE.md` sembrado en el repo. Repetir el comando
es seguro: actualiza en vez de duplicar (`pull --ff-only`).

Verificación:
```bash
$ cat repos.yaml
$ ./scripts/tests/test-repo-lib.sh   # opcional: la librería en verde
```

## Paso 2 · Hechos: mapa as-is

Si usaste `/repo-add`, ya está hecho. Manual:
```bash
$ ./scripts/generate-as-is.sh
```
**Qué esperar** en `knowledge/as-is/`: `system.md` (tabla de repos con rol,
stack y servicios externos + grafo cross-repo si hay ≥2 repos) y por repo
`modules.md` (estructura, dependencias con versión, servicios externos,
datos, infraestructura, comandos) y `api-surface.md` (rutas detectadas).

- ¿El grafo cross-repo salió vacío teniendo ≥2 repos? → `/as-is-learn`
  (escribe extractores exactos con evidencia del código).
- Commitear: `git add repos.yaml knowledge/as-is && git commit -m "chore(repos): alta de <repo> + as-is"`.

## Paso 3 · Contexto profundo: el pack del repo

```
/repo-map mi-app
```
Genera `.claude/skills/<prefijo>-mi-app/SKILL.md`: el pack de contexto que
los agentes cargarán automáticamente cuando un requerimiento mencione este
aplicativo (arquitectura, mecanismos centrales, trampas — todo con
evidencia `archivo:línea`), y siembra sus aserciones en
`scripts/afirmaciones.d/<sistema>.sh`.

Si el sistema tiene **2 o más repos** con pack, genera también las uniones:
```
/system-map
```
(crea `<prefijo>-sistema` — el modelo mental del sistema — y el índice
`mapa-sistemas`).

Verificación mecánica (ambas deben quedar en verde):
```bash
$ ./scripts/afirmaciones.sh          # ¿alguna afirmación de los packs es falsa?
$ ./scripts/frescura.sh comprobar    # ¿algún pack caducó respecto del código?
```

## Paso 4 · Especificar el requerimiento

```
/spec-create mejora-notificaciones "los clientes deben recibir aviso push al pagar"
```
La skill arranca con el **triage F0** — para un repo existente el flujo es:
1. Clasifica el requerimiento como "aplicativo existente [mi-app]" y carga
   los packs vigentes (los del paso 3).
2. **Dependencias**: si detecta que el aplicativo depende de otro sistema
   sin contexto, **te va a preguntar cuál es su repositorio** — respóndele
   con la URL/ruta (la dará de alta con los pasos 1–3) o dile que queda
   fuera de alcance. Ante inconsistencias también pregunta: decide tú.
3. Sigue el ciclo F1–F5 con sus gates humanos: historias INVEST → tu
   aprobación (PO/TL) → estimación → refinamiento hasta DoR → análisis →
   diseño (contratos, C4, ADRs) → gate de Arquitectura.

**Qué esperar**: `specs/<AAAA-MM>-mejora-notificaciones.md` con las tareas
etiquetadas `[mi-app]` y los gates registrados (quién/cuándo).

## Paso 5 · Construir e integrar

```
/harness-init specs/<AAAA-MM>-mejora-notificaciones.md   # solo features grandes/multi-sesión
/implement-task specs/<AAAA-MM>-mejora-notificaciones.md T1
```
Una tarea = un commit con TDD **dentro de `repos/mi-app`**. Repetir por
tarea. Luego certificación (agente `calidad`) y gate QA/PR.

Para recorrer TODO el ciclo con gates de una vez (solo humanos):
```
/orquestar specs/<AAAA-MM>-mejora-notificaciones.md
```

## Paso 6 · Mantener el contexto vivo

- El mapa as-is se regenera solo (hook al editar `repos/` + CI); a mano:
  `/as-is-sync`.
- Tras cambios estructurales del repo: `$ ./scripts/frescura.sh comprobar`
  → si un pack sale OBSOLETO, regenerarlo (`/repo-map mi-app`) y re-sellar.
- Si corriges un error de un pack: la corrección **debe** volverse aserción
  en `scripts/afirmaciones.d/<sistema>.sh` (así no vuelve).

---

## Problemas frecuentes

| Síntoma | Causa / arreglo |
|---|---|
| `ERROR - la URL trae credenciales embebidas` | Usa la URL limpia; el token va en `.env`, nunca en la URL |
| `ERROR - Bitbucket rechazo el token` | Par usuario/tipo de token equivocado → `$ ./scripts/diag-bitbucket.sh` |
| `AVISO - '<ruta>' no tiene .git: se registra como SNAPSHOT` | Normal para carpetas exportadas: se enlaza sin clonar y se sella por huella |
| `ERROR - no existe repos.yaml` | Aún no hay repos: ejecutar el Paso 1 |
| El grafo cross-repo sale vacío | `/as-is-learn` para escribir extractores exactos por repo |
| `/as-is` responde con datos viejos | `/as-is-sync` (o `$ ./scripts/generate-as-is.sh`) y commitear |
| Un pack contradice el código | `$ ./scripts/afirmaciones.sh` para ver qué afirmación es falsa → corregir el pack + actualizar la aserción |
