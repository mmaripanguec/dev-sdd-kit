#!/usr/bin/env bash
# generate-as-is.sh - Real AS-IS map of the system declared in repos.yaml.
# Detects the stack per repo, extracts endpoints (Express/Nest/Spring/JAX-RS/.NET)
# and derives the cross-repo graph. Compatible with bash 3.2 (macOS).
# The topology (system name, repos, entrypoint, deploy order) ALWAYS comes
# from the repos.yaml registry (see scripts/repo-lib.sh).
# Usage:  ./scripts/generate-as-is.sh          -> regenerates knowledge/as-is/
#         ./scripts/generate-as-is.sh --check  -> exit 1 if there is drift
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh
LANG_WS="$(registry_system lang 2>/dev/null || true)"; LANG_WS="${LANG_WS:-en}"

if [ "${LANG_WS}" = "es" ]; then
  T_GEN="GENERADO"; T_NOEDIT="NO EDITAR A MANO"; T_FROM="desde"; T_ON="el"
  T_REGEN="Regenerar"; T_MAP="Mapa AS-IS del sistema"; T_MODS="modulos y tecnologia (as-is)"
  T_API="superficie de API (as-is)"; T_SYS="vista cross-repo (as-is)"
  T_STRUCT="Estructura"; T_EXT="Servicios externos detectados"; T_DEPS="Dependencias directas"
  T_DATA="Datos"; T_INFRA="Infraestructura y CI"; T_CMDS="Comandos del repo"
  T_OPENAPI="Contratos OpenAPI"; T_NOHTTP="Comunicacion no-HTTP detectada"
  T_ROUTES="Rutas expuestas detectadas"; T_REPOS="Repositorios"
  T_COMM="Comunicacion entre repos"; T_COMMH="Comunicacion entre repos (heuristica: rutas expuestas vs. consumidas)"
else
  T_GEN="GENERATED"; T_NOEDIT="DO NOT EDIT BY HAND"; T_FROM="from"; T_ON="on"
  T_REGEN="Regenerate"; T_MAP="AS-IS map of system"; T_MODS="modules and technology (as-is)"
  T_API="API surface (as-is)"; T_SYS="cross-repo view (as-is)"
  T_STRUCT="Structure"; T_EXT="Detected external services"; T_DEPS="Direct dependencies"
  T_DATA="Data"; T_INFRA="Infrastructure and CI"; T_CMDS="Repo commands"
  T_OPENAPI="OpenAPI contracts"; T_NOHTTP="Detected non-HTTP communication"
  T_ROUTES="Detected exposed routes"; T_REPOS="Repositories"
  T_COMM="Cross-repo communication"; T_COMMH="Cross-repo communication (heuristic: exposed vs. consumed routes)"
fi


OUT="knowledge/as-is"
GEN_VERSION="v8"
FECHA=$(date -u +"%Y-%m-%d %H:%M UTC")

registry_validate || exit 1
SYSTEM_NAME="$(registry_system name)"
ENTRYPOINT="$(registry_system entrypoint)"

# Registry repos present on disk (absent ones are reported, they do not break)
REPO_LIST=""
MISSING_LIST=""
for _name in $(registry_repos); do
  if [ -d "repos/${_name}/.git" ] || { [ "$(registry_get "${_name}" vcs)" = "none" ] && [ -d "repos/${_name}/" ]; }; then
    REPO_LIST="${REPO_LIST} ${_name}"
  else
    MISSING_LIST="${MISSING_LIST} ${_name}"
    echo "WARNING - repos/${_name} is not cloned (./scripts/setup.sh); skipping it from the map."
  fi
done
REPO_COUNT=$(echo ${REPO_LIST} | wc -w | tr -d ' ')

if [ "${1:-}" = "--check" ]; then
  TMP=$(mktemp -d); cp -r "${OUT}" "${TMP}/before" 2>/dev/null || true
  "$0"
  if ! diff -r -I '\[GENERADO' "${TMP}/before" "${OUT}" > /dev/null 2>&1; then
    echo "ERROR - DRIFT: knowledge/as-is/ does not reflect the current code in repos/."
    diff -r -I '\[GENERADO' "${TMP}/before" "${OUT}" 2>/dev/null | head -30 || true
    rm -rf "${OUT}"; cp -r "${TMP}/before" "${OUT}"
    exit 1
  fi
  rm -rf "${OUT}"; cp -r "${TMP}/before" "${OUT}"
  echo "OK - as-is in sync."; exit 0
fi

mkdir -p "${OUT}"

# Source code extensions considered
SRC_FIND='-name *.ts -o -name *.tsx -o -name *.js -o -name *.jsx -o -name *.mjs -o -name *.py -o -name *.go -o -name *.java -o -name *.kt -o -name *.cs -o -name *.php -o -name *.rb -o -name *.scala -o -name *.dart'

# Endpoint pattern (extended): Express/Koa/Fastify, NestJS, Spring, JAX-RS, .NET
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
  if [ -z "${st}" ]; then st="unknown"; fi
  printf '%s' "${st}" | sed 's/ *$//'
}

extract_routes() {
  # Per-repo hook: if scripts/as-is.d/<repo>.sh exists, that extractor rules.
  # Claude Code writes it (skill /as-is-learn) after analyzing the REAL code,
  # instead of relying on generic patterns. Contract: it receives the repo
  # path as $1 and prints one route per line (format /segment[/...]).
  rname=$(basename "$1")
  if [ -x "scripts/as-is.d/${rname}.sh" ]; then
    "scripts/as-is.d/${rname}.sh" "$1" | sort -u | head -60
    return 0
  fi
  # Routes/paths exposed by a repo, normalized to /segment[/...]
  grep -rhoE --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=www --exclude-dir=platforms \
    "${ROUTE_RX}" "$1" 2>/dev/null > /tmp/asis-routes.$$ || true
  grep -rhoE --exclude-dir=node_modules --exclude-dir=.git \
    "@Router +/[A-Za-z0-9/_:.{}*-]{2,}" "$1" 2>/dev/null >> /tmp/asis-routes.$$ || true
  # Routes in code tables/structs:  Path: "/x", Route: "/x", Endpoint: "/x"
  grep -rhoE --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=www \
    "(Path|Prefix|Route|Endpoint|Url|URL)[\"']? *[:=] *[\"']/[A-Za-z0-9/_:.{}*-]{2,}" \
    "$1" 2>/dev/null >> /tmp/asis-routes.$$ || true
  # Routes in configuration:  path:/prefix:/route: in yml/yaml/json/toml
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

# Direct dependencies declared in the repo's manifests (with version).
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

# External services inferred from dependencies and connection schemes in
# config (only the service TYPE; URLs/credentials are never copied).
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
  # Connection schemes in config files (they indicate the service, not the URL)
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

# Repo commands (npm scripts / Makefile targets)
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
  # Signs of NON-HTTP communication that the route graph cannot see
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
  commit=$(stamp_of_repo "${name}")
  branch=$(git -C "${repo}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "snapshot")
  last=$(git -C "${repo}" log -1 --format=%cs 2>/dev/null || echo "-")
  stack=$(detect_stack "${repo}")
  role=$(registry_get "${name}" role)
  files=$(find "${repo}" -path "*/node_modules" -prune -o -path "*/.git" -prune -o -path "*/dist" -prune -o -path "*/www" -prune -o -type f \( ${SRC_FIND} \) -print 2>/dev/null | wc -l | tr -d ' ')
  loc=$(find "${repo}" -path "*/node_modules" -prune -o -path "*/.git" -prune -o -path "*/dist" -prune -o -path "*/www" -prune -o -type f \( ${SRC_FIND} \) -print 2>/dev/null | xargs cat 2>/dev/null | wc -l | tr -d ' ')
  DEPS=$(extract_deps "${repo}")
  SERVICES=$(detect_services "${repo}" "${DEPS}")
  COMMANDS=$(extract_commands "${repo}")
  SVC_CELL=$(printf '%s' "${SERVICES}" | tr ' ' ',')
  SYSTEM_ROWS="${SYSTEM_ROWS}| [${name}](${name}/) | ${role:--} | ${stack} | ${SVC_CELL:--} | \`${commit}\` | ${branch} | ${last} | ${files} | ${loc} |\n"
  STAMP="> [${T_GEN} ${GEN_VERSION}] ${T_FROM} ${name}@\`${commit}\` ${T_ON} ${FECHA} - ${T_NOEDIT}."

  mkdir -p "${OUT}/${name}"

  { echo "# ${name} - ${T_MODS}"; echo "${STAMP}"; echo
    echo "**Detected stack:** ${stack}"
    if [ -n "${role}" ]; then echo "**Declared role (repos.yaml):** ${role}"; fi
    if [ "${files}" = "0" ]; then
      echo ""
      echo "WARNING: 0 source files with the current filters. Possible causes:"
      echo "code in a language not listed, or configuration/artifacts only."
    fi
    echo; echo "## ${T_STRUCT}"; echo '```'
    find "${repo}" -maxdepth 3 -path "*/node_modules" -prune -o -path "*/.git" -prune -o -type d -print 2>/dev/null | sed "s|^${repo}||" | grep -v '^$' | sort | head -60
    echo '```'
    echo; echo "## ${T_EXT}"
    if [ -n "${SERVICES}" ]; then
      for s in ${SERVICES}; do echo "- ${s}"; done
      echo
      echo "_(inferred from dependencies and connection schemes in config;_"
      echo "_they indicate what the repo talks to besides its HTTP routes)_"
    else
      echo "- (none detected)"
    fi
    echo; echo "## ${T_DEPS}"
    if [ -n "${DEPS}" ]; then
      printf '%s\n' "${DEPS}" | head -40 | sed 's/^/- `/;s/$/`/'
      DEPS_TOTAL=$(printf '%s\n' "${DEPS}" | wc -l | tr -d ' ')
      if [ "${DEPS_TOTAL}" -gt 40 ]; then echo "- ... (${DEPS_TOTAL} in total; see the repo's manifests)"; fi
    else
      echo "- (no recognized dependency manifest)"
    fi
    echo; echo "## ${T_DATA}"
    DATA_HITS=""
    for d in migrations migration alembic prisma db/migrate; do
      if [ -d "${repo}/${d}" ]; then
        n_sql=$(find "${repo}/${d}" -type f 2>/dev/null | wc -l | tr -d ' ')
        DATA_HITS="si"; echo "- \`${d}/\` (${n_sql} migration/schema files)"
      fi
    done
    for f in prisma/schema.prisma schema.sql; do
      if [ -f "${repo}/${f}" ]; then DATA_HITS="si"; echo "- \`${f}\`"; fi
    done
    if [ -z "${DATA_HITS}" ]; then echo "- (no migrations/schemas detected)"; fi
    echo; echo "## ${T_INFRA}"
    INFRA_HITS=""
    for f in Dockerfile docker-compose.yml docker-compose.yaml Jenkinsfile \
             bitbucket-pipelines.yml .gitlab-ci.yml serverless.yml; do
      if [ -f "${repo}/${f}" ]; then INFRA_HITS="si"; echo "- \`${f}\`"; fi
    done
    if [ -d "${repo}/.github/workflows" ]; then
      INFRA_HITS="si"
      echo "- \`.github/workflows/\` ($(ls "${repo}/.github/workflows" 2>/dev/null | wc -l | tr -d ' ') workflows)"
    fi
    if [ -z "${INFRA_HITS}" ]; then echo "- (no Dockerfile/CI detected)"; fi
    echo; echo "## ${T_CMDS}"
    if [ -n "${COMMANDS}" ]; then
      printf '%s\n' "${COMMANDS}" | head -20 | sed 's/^/- `/;s/$/`/'
    else
      echo "- (no npm scripts/Makefile detected; see the repo's CLAUDE.md)"
    fi
  } > "${OUT}/${name}/modules.md"

  { echo "# ${name} - ${T_API}"; echo "${STAMP}"; echo
    echo "## ${T_OPENAPI}"
    found=$(find "${repo}" -path "*/node_modules" -prune -o \( -name "openapi*.y*ml" -o -name "openapi*.json" -o -name "swagger*.y*ml" -o -name "swagger*.json" \) -print 2>/dev/null || true)
    if [ -n "${found}" ]; then printf '%s\n' "${found}" | sed "s|^${repo}|- \`|;s|$|\`|"; else echo "- (none - every new API requires a contract first, see rules/api-design.md)"; fi
    rpc=$(detect_rpc "${repo}")
    if [ -n "${rpc}" ]; then
      echo; echo "## ${T_NOHTTP}"
      echo "- ${rpc}"
      echo "  (gRPC and reverse-proxy are not mapped via HTTP routes: if this repo"
      echo "  speaks gRPC or forwards by prefix, the route graph may come out"
      echo "  empty and still be correct. See system.md.)"
    fi
    echo; echo "## ${T_ROUTES}"
    routes=$(extract_routes "${repo}")
    if [ -n "${routes}" ]; then printf '%s\n' "${routes}" | sed 's/^/- `/;s/$/`/'; else echo "- (none with the current patterns)"; fi
  } > "${OUT}/${name}/api-surface.md"
done

# ---------- SYSTEM view ----------
{
  echo "# ${SYSTEM_NAME} - ${T_SYS}"
  echo "> [${T_GEN} ${GEN_VERSION}] ${T_ON} ${FECHA} - ${T_NOEDIT}. ${T_REGEN}: \`./scripts/generate-as-is.sh\`"
  echo
  echo "## ${T_REPOS}"
  echo "| Repo | Role | Stack | External services | Commit | Branch | Last change | Files | Lines |"
  echo "|---|---|---|---|---|---|---|---|---|"
  printf '%b' "${SYSTEM_ROWS}"
  if [ -n "${MISSING_LIST}" ]; then
    echo
    echo "WARNING: registered repos not cloned (run ./scripts/setup.sh):${MISSING_LIST}"
  fi
  echo
  # Deploy order declared in the registry (provider before consumer)
  DEPLOY_LINE=""
  for n in $(registry_repos_by_deploy); do
    DEPLOY_LINE="${DEPLOY_LINE:+${DEPLOY_LINE} -> }${n}"
  done
  echo "**Declared deploy order (repos.yaml):** ${DEPLOY_LINE}"
  echo
  if [ "${REPO_COUNT}" -lt 2 ]; then
    echo "## ${T_COMM}"
    echo "_(single-repository system: the cross-repo graph does not apply)_"
  else
  echo "## ${T_COMMH}"
  echo '```mermaid'
  echo 'graph LR'
  case " ${REPO_LIST} " in
    *" ${ENTRYPOINT} "*) echo "  user((User)) --> ${ENTRYPOINT}" ;;
  esac
  # Precompute exposed routes per repo (for the anti-false-positive filter)
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
        # Anti-false-positive: if rt is a substring of a route EXPOSED by the
        # consumer, the match is its own definition, not consumption.
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
    if [ -n "${rr}" ]; then echo "- ${rn}: ${rr} (communication not visible in the HTTP route graph)"; fi
  done
  echo
  echo "_Heuristic based on route matching. Per-repo detail lives in_"
  echo "_<repo>/api-surface.md. For full precision: OpenAPI contracts per repo._"
  fi
} > "${OUT}/system.md"

# ---------- Index ----------
{
  echo "# ${T_MAP} ${SYSTEM_NAME}"
  echo "> [${T_GEN} ${GEN_VERSION}] ${T_ON} ${FECHA} - ${T_NOEDIT}."
  echo
  echo "- **[system.md](system.md)** - inventory + stack + cross-repo graph"
  for n in ${REPO_LIST}; do
    echo "- **${n}/** - [modules](./${n}/modules.md) - [api-surface](./${n}/api-surface.md)"
  done
  echo
  echo "The as-is says WHAT EXISTS; the ADRs (knowledge/decisions/) WHY;"
  echo "the specs (specs/) WHAT SHOULD EXIST."
} > "${OUT}/INDEX.md"

echo "OK - system as-is regenerated in ${OUT}/"

# Architecture doc (arc42 + C4) as consumable knowledge context (.md + .html).
# Runs after indexing; never blocks the as-is if it fails.
if [ -f scripts/generate-architecture.sh ] && [ -f templates/knowledge-architecture.md ]; then
  ./scripts/generate-architecture.sh || echo "WARN: generate-architecture.sh failed (as-is is OK)"
fi
