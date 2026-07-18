#!/usr/bin/env bash
# generate-as-is.sh - Mapa AS-IS real del sistema declarado en repos.yaml.
# Detecta stack por repo, extrae endpoints (Express/Nest/Spring/JAX-RS/.NET) y
# deriva el grafo cross-repo. Compatible con bash 3.2 (macOS).
# La topologia (nombre del sistema, repos, entrypoint, orden de despliegue)
# sale SIEMPRE del registro repos.yaml (ver scripts/repo-lib.sh).
# Uso:  ./scripts/generate-as-is.sh          -> regenera knowledge/as-is/
#       ./scripts/generate-as-is.sh --check  -> exit 1 si hay drift
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

OUT="knowledge/as-is"
GEN_VERSION="v8"
FECHA=$(date -u +"%Y-%m-%d %H:%M UTC")

registry_validate || exit 1
SYSTEM_NAME="$(registry_system name)"
ENTRYPOINT="$(registry_system entrypoint)"

# Repos del registro presentes en disco (los ausentes se reportan, no rompen)
REPO_LIST=""
MISSING_LIST=""
for _name in $(registry_repos); do
  if [ -d "repos/${_name}/.git" ]; then
    REPO_LIST="${REPO_LIST} ${_name}"
  else
    MISSING_LIST="${MISSING_LIST} ${_name}"
    echo "AVISO - repos/${_name} no esta clonado (./scripts/setup.sh); se omite del mapa."
  fi
done
REPO_COUNT=$(echo ${REPO_LIST} | wc -w | tr -d ' ')

if [ "${1:-}" = "--check" ]; then
  TMP=$(mktemp -d); cp -r "${OUT}" "${TMP}/before" 2>/dev/null || true
  "$0"
  if ! diff -r -I '\[GENERADO' "${TMP}/before" "${OUT}" > /dev/null 2>&1; then
    echo "ERROR - DRIFT: knowledge/as-is/ no refleja el codigo actual de repos/."
    diff -r -I '\[GENERADO' "${TMP}/before" "${OUT}" 2>/dev/null | head -30 || true
    rm -rf "${OUT}"; cp -r "${TMP}/before" "${OUT}"
    exit 1
  fi
  rm -rf "${OUT}"; cp -r "${TMP}/before" "${OUT}"
  echo "OK - as-is sincronizado."; exit 0
fi

mkdir -p "${OUT}"

# Extensiones de codigo fuente consideradas
SRC_FIND='-name *.ts -o -name *.tsx -o -name *.js -o -name *.jsx -o -name *.mjs -o -name *.py -o -name *.go -o -name *.java -o -name *.kt -o -name *.cs -o -name *.php -o -name *.rb -o -name *.scala -o -name *.dart'

# Patron de endpoints (extendido): Express/Koa/Fastify, NestJS, Spring, JAX-RS, .NET
ROUTE_RX="(\.| )(get|post|put|patch|delete|all|use)\(['\"]/[A-Za-z0-9/_:.{}-]{2,}|@(Get|Post|Put|Patch|Delete|All|Controller)\(['\"][A-Za-z0-9/_:.{}-]{2,}|@(Get|Post|Put|Patch|Delete|Request)Mapping\(( *value *= *)?\"/[A-Za-z0-9/_:.{}-]{2,}|@Path\(\"/[A-Za-z0-9/_:.{}-]{2,}|\[Http(Get|Post|Put|Delete|Patch)\(\"|\[Route\(\"[A-Za-z0-9/_:.{}-]{2,}|\.(Get|Post|Put|Patch|Delete|Head|GET|POST|PUT|PATCH|DELETE|Handle|HandleFunc|Group|Route|Mount|PathPrefix|Any|Static)\(\"/[A-Za-z0-9/_:.{}*-]{2,}|\.(Path|Prefix)\(\"/[A-Za-z0-9/_:.{}*-]{2,}|http\.Method(Get|Post|Put|Patch|Delete), *\"/[A-Za-z0-9/_:.{}*-]{2,}"

detect_stack() {
  r="$1"; st=""
  if [ -f "${r}/package.json" ]; then
    deps=$(tr -d ' \n' < "${r}/package.json" | head -c 6000)
    for fw in "@angular/core|angular" "@ionic|ionic" "react-native|react-native" "\"react\"|react" "\"next\"|next" "\"vue\"|vue" "\"express\"|express" "@nestjs/core|nestjs" "\"fastify\"|fastify" "\"koa\"|koa" "@capacitor|capacitor" "cordova|cordova"; do
      pat="${fw%%|*}"; label="${fw##*|}"
      case "${deps}" in *"${pat}"*) st="${st}${label} " ;; esac
    done
    if [ -z "${st}" ]; then st="node "; fi
  fi
  if [ -f "${r}/pom.xml" ]; then st="${st}java-maven "; fi
  if ls "${r}"/build.gradle* >/dev/null 2>&1; then st="${st}java-gradle "; fi
  if [ -f "${r}/requirements.txt" ] || [ -f "${r}/pyproject.toml" ]; then st="${st}python "; fi
  if [ -f "${r}/go.mod" ]; then st="${st}go "; fi
  if [ -f "${r}/composer.json" ]; then st="${st}php "; fi
  if [ -f "${r}/Gemfile" ]; then st="${st}ruby "; fi
  if ls "${r}"/*.csproj >/dev/null 2>&1 || ls "${r}"/*/*.csproj >/dev/null 2>&1; then st="${st}dotnet "; fi
  if [ -z "${st}" ]; then st="desconocido"; fi
  printf '%s' "${st}" | sed 's/ *$//'
}

extract_routes() {
  # Hook por repo: si existe scripts/as-is.d/<repo>.sh, ese extractor manda.
  # Lo escribe Claude Code (skill /as-is-learn) tras analizar el codigo REAL,
  # en vez de depender de patrones genericos. Contrato: recibe la ruta del
  # repo como $1 e imprime una ruta por linea (formato /segmento[/...]).
  rname=$(basename "$1")
  if [ -x "scripts/as-is.d/${rname}.sh" ]; then
    "scripts/as-is.d/${rname}.sh" "$1" | sort -u | head -60
    return 0
  fi
  # Rutas/paths expuestos por un repo, normalizados a /segmento[/...]
  grep -rhoE --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=www --exclude-dir=platforms \
    "${ROUTE_RX}" "$1" 2>/dev/null > /tmp/asis-routes.$$ || true
  grep -rhoE --exclude-dir=node_modules --exclude-dir=.git \
    "@Router +/[A-Za-z0-9/_:.{}*-]{2,}" "$1" 2>/dev/null >> /tmp/asis-routes.$$ || true
  # Rutas en tablas/structs de codigo:  Path: "/x", Route: "/x", Endpoint: "/x"
  grep -rhoE --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=www \
    "(Path|Prefix|Route|Endpoint|Url|URL)[\"']? *[:=] *[\"']/[A-Za-z0-9/_:.{}*-]{2,}" \
    "$1" 2>/dev/null >> /tmp/asis-routes.$$ || true
  # Rutas en configuracion:  path:/prefix:/route: en yml/yaml/json/toml
  find "$1" -path "*/node_modules" -prune -o -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.toml" \) -print 2>/dev/null \
    | grep -vE "(package(-lock)?\.json|tsconfig|angular\.json)" | head -40 \
    | while IFS= read -r cf; do
        grep -hoE "(path|prefix|route|endpoint|url)[\"']? *: *[\"']?/[A-Za-z0-9/_:.{}*-]{2,}" "${cf}" 2>/dev/null || true
      done >> /tmp/asis-routes.$$ || true
  cat /tmp/asis-routes.$$ \
    | grep -oE "/[A-Za-z0-9][A-Za-z0-9/_:.{}*-]{3,}" \
    | grep -vE "^/(api|v[0-9]+|app|src|dist|build|assets|public|static|img|images|css|js|fonts|index|main|health|status)$" \
    | sort -u | head -60 || true
  rm -f /tmp/asis-routes.$$
}

# Dependencias directas declaradas en los manifiestos del repo (con version).
extract_deps() {
  r="$1"
  if [ -f "${r}/package.json" ]; then
    python3 - "${r}/package.json" <<'PY' 2>/dev/null || true
import json, sys
d = json.load(open(sys.argv[1]))
for key, tag in (("dependencies", "runtime"), ("devDependencies", "dev")):
    for name, ver in sorted((d.get(key) or {}).items()):
        print(f"{name} {ver} [{tag}]")
PY
  fi
  if [ -f "${r}/requirements.txt" ]; then
    grep -vE '^[[:space:]]*(#|$)' "${r}/requirements.txt" | head -40
  fi
  if [ -f "${r}/pyproject.toml" ]; then
    awk '/^\[.*dependencies.*\]/{f=1;next}/^\[/{f=0}f' "${r}/pyproject.toml" \
      | grep -oE '"[^"]+"' | tr -d '"' | head -40
  fi
  if [ -f "${r}/go.mod" ]; then
    awk '/^require \(/{f=1;next}/^\)/{f=0} f && $1!=""{print $1" "$2}' "${r}/go.mod" | head -40
  fi
  if [ -f "${r}/pom.xml" ]; then
    grep -oE '<artifactId>[^<]+</artifactId>' "${r}/pom.xml" \
      | sed 's/<[^>]*>//g' | sort -u | head -40
  fi
  if [ -f "${r}/Gemfile" ]; then
    grep -E "^gem " "${r}/Gemfile" | sed "s/^gem //;s/[\"',]//g" | head -40
  fi
  if [ -f "${r}/composer.json" ]; then
    python3 - "${r}/composer.json" <<'PY' 2>/dev/null || true
import json, sys
d = json.load(open(sys.argv[1]))
for name, ver in sorted((d.get("require") or {}).items()):
    print(f"{name} {ver}")
PY
  fi
}

# Servicios externos inferidos de dependencias y esquemas de conexion en
# config (solo el TIPO de servicio; jamas se copian URLs/credenciales).
detect_services() {
  r="$1"; deps="$2"; svc=""
  add_svc() { case " ${svc} " in *" $1 "*) : ;; *) svc="${svc}${svc:+ }$1" ;; esac; }
  for pair in "pg:PostgreSQL" "postgres:PostgreSQL" "psycopg:PostgreSQL" \
              "mysql:MySQL" "mariadb:MySQL" "mongoose:MongoDB" "mongodb:MongoDB" \
              "pymongo:MongoDB" "redis:Redis" "ioredis:Redis" \
              "kafkajs:Kafka" "kafka:Kafka" "amqplib:RabbitMQ" "pika:RabbitMQ" \
              "elasticsearch:Elasticsearch" "sqlalchemy:SQL-DB" "sequelize:SQL-DB" \
              "typeorm:SQL-DB" "prisma:SQL-DB" "knex:SQL-DB" \
              "axios:HTTP-saliente" "node-fetch:HTTP-saliente" "got:HTTP-saliente" \
              "requests:HTTP-saliente" "httpx:HTTP-saliente" \
              "aws-sdk:AWS" "boto3:AWS" "@aws-sdk:AWS" "@google-cloud:GCP" \
              "@azure:Azure" "firebase:Firebase" "stripe:Stripe" \
              "nodemailer:Email" "celery:Cola-de-tareas" "bull:Cola-Redis"; do
    dep="${pair%%:*}"; label="${pair##*:}"
    if printf '%s\n' "${deps}" | grep -qiE "^${dep}([ @/]|$)"; then add_svc "${label}"; fi
  done
  # Esquemas de conexion en archivos de config (indican el servicio, no la URL)
  SCHEMES=$(grep -rhoE --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
      --include="*.yml" --include="*.yaml" --include="*.env.example" --include="*.properties" --include="*.toml" \
      "(postgres|postgresql|mysql|mongodb|redis|amqp|kafka)://" "${r}" 2>/dev/null | sort -u || true)
  for sch in ${SCHEMES}; do
    case "${sch}" in
      postgres*|postgresql*) add_svc "PostgreSQL" ;;
      mysql*)   add_svc "MySQL" ;;
      mongodb*) add_svc "MongoDB" ;;
      redis*)   add_svc "Redis" ;;
      amqp*)    add_svc "RabbitMQ" ;;
      kafka*)   add_svc "Kafka" ;;
    esac
  done
  printf '%s' "${svc}"
}

# Comandos del repo (scripts npm / targets de Makefile)
extract_commands() {
  r="$1"
  if [ -f "${r}/package.json" ]; then
    python3 - "${r}/package.json" <<'PY' 2>/dev/null || true
import json, sys
for name, cmd in sorted((json.load(open(sys.argv[1])).get("scripts") or {}).items()):
    print(f"npm run {name}  ->  {cmd}")
PY
  fi
  if [ -f "${r}/Makefile" ]; then
    grep -oE '^[A-Za-z0-9_.-]+:' "${r}/Makefile" | sed 's/:$/  (make)/' | head -20
  fi
}

detect_rpc() {
  # Señales de comunicacion NO-HTTP que el grafo de rutas no puede ver
  r="$1"; notes=""
  protos=$(find "${r}" -name "*.proto" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${protos}" != "0" ]; then notes="${notes}gRPC(${protos} .proto) "; fi
  if grep -rql --include="*.go" "google.golang.org/grpc" "${r}" 2>/dev/null | head -1 > /dev/null; then
    case "${notes}" in *gRPC*) : ;; *) notes="${notes}grpc-client " ;; esac
  fi
  if grep -rql --include="*.go" "httputil.NewSingleHostReverseProxy\|httputil.ReverseProxy" "${r}" 2>/dev/null | head -1 > /dev/null; then
    notes="${notes}reverse-proxy "
  fi
  printf '%s' "${notes}" | sed 's/ *$//'
}

SYSTEM_ROWS=""
for name in ${REPO_LIST}; do
  repo="repos/${name}/"
  commit=$(git -C "${repo}" rev-parse --short HEAD 2>/dev/null || echo "?")
  branch=$(git -C "${repo}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
  last=$(git -C "${repo}" log -1 --format=%cs 2>/dev/null || echo "?")
  stack=$(detect_stack "${repo}")
  role=$(registry_get "${name}" role)
  files=$(find "${repo}" -path "*/node_modules" -prune -o -path "*/.git" -prune -o -path "*/dist" -prune -o -path "*/www" -prune -o -type f \( ${SRC_FIND} \) -print 2>/dev/null | wc -l | tr -d ' ')
  loc=$(find "${repo}" -path "*/node_modules" -prune -o -path "*/.git" -prune -o -path "*/dist" -prune -o -path "*/www" -prune -o -type f \( ${SRC_FIND} \) -print 2>/dev/null | xargs cat 2>/dev/null | wc -l | tr -d ' ')
  DEPS=$(extract_deps "${repo}")
  SERVICES=$(detect_services "${repo}" "${DEPS}")
  COMMANDS=$(extract_commands "${repo}")
  SVC_CELL=$(printf '%s' "${SERVICES}" | tr ' ' ',')
  SYSTEM_ROWS="${SYSTEM_ROWS}| [${name}](${name}/) | ${role:--} | ${stack} | ${SVC_CELL:--} | \`${commit}\` | ${branch} | ${last} | ${files} | ${loc} |\n"
  STAMP="> [GENERADO ${GEN_VERSION}] desde ${name}@\`${commit}\` el ${FECHA} - NO EDITAR A MANO."

  mkdir -p "${OUT}/${name}"

  { echo "# ${name} - modulos y tecnologia (as-is)"; echo "${STAMP}"; echo
    echo "**Stack detectado:** ${stack}"
    if [ -n "${role}" ]; then echo "**Rol declarado (repos.yaml):** ${role}"; fi
    if [ "${files}" = "0" ]; then
      echo ""
      echo "AVISO: 0 archivos fuente con los filtros actuales. Posibles causas:"
      echo "codigo en un lenguaje no listado, o solo configuracion/artefactos."
    fi
    echo; echo "## Estructura"; echo '```'
    find "${repo}" -maxdepth 3 -path "*/node_modules" -prune -o -path "*/.git" -prune -o -type d -print 2>/dev/null | sed "s|^${repo}||" | grep -v '^$' | sort | head -60
    echo '```'
    echo; echo "## Servicios externos detectados"
    if [ -n "${SERVICES}" ]; then
      for s in ${SERVICES}; do echo "- ${s}"; done
      echo
      echo "_(inferidos de dependencias y esquemas de conexion en config;_"
      echo "_indican con que habla el repo ademas de sus rutas HTTP)_"
    else
      echo "- (ninguno detectado)"
    fi
    echo; echo "## Dependencias directas"
    if [ -n "${DEPS}" ]; then
      printf '%s\n' "${DEPS}" | head -40 | sed 's/^/- `/;s/$/`/'
      DEPS_TOTAL=$(printf '%s\n' "${DEPS}" | wc -l | tr -d ' ')
      if [ "${DEPS_TOTAL}" -gt 40 ]; then echo "- ... (${DEPS_TOTAL} en total; ver manifiestos del repo)"; fi
    else
      echo "- (sin manifiesto de dependencias reconocido)"
    fi
    echo; echo "## Datos"
    DATA_HITS=""
    for d in migrations migration alembic prisma db/migrate; do
      if [ -d "${repo}/${d}" ]; then
        n_sql=$(find "${repo}/${d}" -type f 2>/dev/null | wc -l | tr -d ' ')
        DATA_HITS="si"; echo "- \`${d}/\` (${n_sql} archivos de migracion/esquema)"
      fi
    done
    for f in prisma/schema.prisma schema.sql; do
      if [ -f "${repo}/${f}" ]; then DATA_HITS="si"; echo "- \`${f}\`"; fi
    done
    if [ -z "${DATA_HITS}" ]; then echo "- (sin migraciones/esquemas detectados)"; fi
    echo; echo "## Infraestructura y CI"
    INFRA_HITS=""
    for f in Dockerfile docker-compose.yml docker-compose.yaml Jenkinsfile \
             bitbucket-pipelines.yml .gitlab-ci.yml serverless.yml; do
      if [ -f "${repo}/${f}" ]; then INFRA_HITS="si"; echo "- \`${f}\`"; fi
    done
    if [ -d "${repo}/.github/workflows" ]; then
      INFRA_HITS="si"
      echo "- \`.github/workflows/\` ($(ls "${repo}/.github/workflows" 2>/dev/null | wc -l | tr -d ' ') workflows)"
    fi
    if [ -z "${INFRA_HITS}" ]; then echo "- (sin Dockerfile/CI detectados)"; fi
    echo; echo "## Comandos del repo"
    if [ -n "${COMMANDS}" ]; then
      printf '%s\n' "${COMMANDS}" | head -20 | sed 's/^/- `/;s/$/`/'
    else
      echo "- (sin scripts npm/Makefile detectados; ver CLAUDE.md del repo)"
    fi
  } > "${OUT}/${name}/modules.md"

  { echo "# ${name} - superficie de API (as-is)"; echo "${STAMP}"; echo
    echo "## Contratos OpenAPI"
    found=$(find "${repo}" -path "*/node_modules" -prune -o \( -name "openapi*.y*ml" -o -name "openapi*.json" -o -name "swagger*.y*ml" -o -name "swagger*.json" \) -print 2>/dev/null || true)
    if [ -n "${found}" ]; then printf '%s\n' "${found}" | sed "s|^${repo}|- \`|;s|$|\`|"; else echo "- (ninguno - toda API nueva exige contrato primero, ver rules/api-design.md)"; fi
    rpc=$(detect_rpc "${repo}")
    if [ -n "${rpc}" ]; then
      echo; echo "## Comunicacion no-HTTP detectada"
      echo "- ${rpc}"
      echo "  (gRPC y reverse-proxy no se mapean por rutas HTTP: si este repo"
      echo "  habla gRPC o reenvia por prefijo, el grafo de rutas puede salir"
      echo "  vacio siendo correcto. Ver system.md.)"
    fi
    echo; echo "## Rutas expuestas detectadas"
    routes=$(extract_routes "${repo}")
    if [ -n "${routes}" ]; then printf '%s\n' "${routes}" | sed 's/^/- `/;s/$/`/'; else echo "- (ninguna con los patrones actuales)"; fi
  } > "${OUT}/${name}/api-surface.md"
done

# ---------- Vista de SISTEMA ----------
{
  echo "# Sistema ${SYSTEM_NAME} - vista cross-repo (as-is)"
  echo "> [GENERADO ${GEN_VERSION}] el ${FECHA} - NO EDITAR A MANO. Regenerar: \`./scripts/generate-as-is.sh\`"
  echo
  echo "## Repositorios"
  echo "| Repo | Rol | Stack | Servicios externos | Commit | Rama | Ultimo cambio | Archivos | Lineas |"
  echo "|---|---|---|---|---|---|---|---|---|"
  printf '%b' "${SYSTEM_ROWS}"
  if [ -n "${MISSING_LIST}" ]; then
    echo
    echo "AVISO: repos registrados sin clonar (correr ./scripts/setup.sh):${MISSING_LIST}"
  fi
  echo
  # Orden de despliegue declarado en el registro (proveedor antes que consumidor)
  DEPLOY_LINE=""
  for n in $(registry_repos_by_deploy); do
    DEPLOY_LINE="${DEPLOY_LINE:+${DEPLOY_LINE} -> }${n}"
  done
  echo "**Orden de despliegue declarado (repos.yaml):** ${DEPLOY_LINE}"
  echo
  if [ "${REPO_COUNT}" -lt 2 ]; then
    echo "## Comunicacion entre repos"
    echo "_(sistema de un solo repositorio: no aplica grafo cross-repo)_"
  else
  echo "## Comunicacion entre repos (heuristica: rutas expuestas vs. consumidas)"
  echo '```mermaid'
  echo 'graph LR'
  if [ -n "${ENTRYPOINT}" ] && [ -d "repos/${ENTRYPOINT}/.git" ]; then
    echo "  usuario((Usuario)) --> ${ENTRYPOINT}"
  fi
  # Precalcular rutas expuestas por repo (para el filtro anti-falsos-positivos)
  RDIR=$(mktemp -d)
  for name in ${REPO_LIST}; do
    extract_routes "repos/${name}/" > "${RDIR}/${name}"
  done
  for pname in ${REPO_LIST}; do
    routes=$(cat "${RDIR}/${pname}")
    if [ -z "${routes}" ]; then continue; fi
    for cname in ${REPO_LIST}; do
      if [ "${cname}" = "${pname}" ]; then continue; fi
      hits=""; n=0
      for rt in ${routes}; do
        if [ ${#rt} -lt 5 ]; then continue; fi
        # Anti-falso-positivo: si rt es subcadena de una ruta EXPUESTA por el
        # consumidor, la coincidencia es su propia definicion, no consumo.
        if grep -qF -- "${rt}" "${RDIR}/${cname}" 2>/dev/null; then continue; fi
        if grep -rq --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=www -F "${rt}" "repos/${cname}/" 2>/dev/null; then
          hits="${hits:+${hits},}${rt}"
          n=$((n+1)); if [ "${n}" -ge 3 ]; then break; fi
        fi
      done
      if [ -n "${hits}" ]; then echo "  ${cname} -->|${hits}| ${pname}"; fi
    done
  done
  rm -rf "${RDIR}"
  echo '```'
  for rn in ${REPO_LIST}; do
    rr=$(detect_rpc "repos/${rn}/")
    if [ -n "${rr}" ]; then echo "- ${rn}: ${rr} (comunicacion no visible en el grafo de rutas HTTP)"; fi
  done
  echo
  echo "_Heuristica por coincidencia de rutas. El detalle por repo esta en_"
  echo "_<repo>/api-surface.md. Para precision total: contratos OpenAPI por repo._"
  fi
} > "${OUT}/system.md"

# ---------- Indice ----------
{
  echo "# Mapa AS-IS del sistema ${SYSTEM_NAME}"
  echo "> [GENERADO ${GEN_VERSION}] el ${FECHA} - NO EDITAR A MANO."
  echo
  echo "- **[system.md](system.md)** - inventario + stack + grafo cross-repo"
  for n in ${REPO_LIST}; do
    echo "- **${n}/** - [modules](./${n}/modules.md) - [api-surface](./${n}/api-surface.md)"
  done
  echo
  echo "El as-is dice QUE HAY; los ADRs (knowledge/decisiones/) POR QUE;"
  echo "las specs (specs/) QUE DEBERIA HABER."
} > "${OUT}/INDEX.md"

echo "OK - as-is del sistema regenerado en ${OUT}/"
