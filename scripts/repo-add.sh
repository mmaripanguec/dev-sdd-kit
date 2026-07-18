#!/usr/bin/env bash
# repo-add.sh - Alta IDEMPOTENTE de un repositorio en la fabrica:
# valida la entrada, clona (o actualiza), registra en repos.yaml y siembra
# el CLAUDE.md del repo. Compatible con bash 3.2 (macOS).
#
# Uso:
#   ./scripts/repo-add.sh <url-git | ruta-local> [opciones]
# Opciones:
#   --name <n>          nombre en repos/ (default: derivado de la URL/ruta)
#   --role "<rol>"      que hace el repo dentro del sistema
#   --domain <d>        generic (default) | banking
#   --deploy-order <n>  menor = se despliega antes (default: al final)
#   --entrypoint        marca este repo como entrada del sistema (grafo as-is)
#   --system-name <s>   nombre del sistema (default: el del registro, o el
#                       nombre del primer repo si el registro no existe)
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

usage() { sed -n '/^# Uso:/,/^set -euo/p' "$0" | sed '$d;s/^# \{0,1\}//'; }

SRC="${1:-}"
if [ -z "${SRC}" ] || [ "${SRC}" = "-h" ] || [ "${SRC}" = "--help" ]; then
  usage; exit 1
fi
shift

NAME=""; ROLE=""; DOMAIN=""; DEPLOY_ORDER=""; ENTRYPOINT=""; SYSTEM_NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    --name)         NAME="$2"; shift 2 ;;
    --role)         ROLE="$2"; shift 2 ;;
    --domain)       DOMAIN="$2"; shift 2 ;;
    --deploy-order) DEPLOY_ORDER="$2"; shift 2 ;;
    --entrypoint)   ENTRYPOINT="true"; shift ;;
    --system-name)  SYSTEM_NAME="$2"; shift 2 ;;
    *) echo "ERROR - opcion desconocida: $1"; usage; exit 1 ;;
  esac
done

# ---------- Validar la entrada ----------
# Credenciales embebidas en la URL: PROHIBIDO (van en .env; una URL con token
# terminaria escrita en repos.yaml, .git/config y el historial).
if printf '%s' "${SRC}" | grep -qE '^[a-z+]+://[^/@]+:[^/@]+@'; then
  echo "ERROR - la URL trae credenciales embebidas (usuario:token@host)."
  echo "        Usa la URL limpia y pon el token en .env (ver .env.example)."
  exit 1
fi

# Expandir ~ y resolver rutas locales a absolutas
case "${SRC}" in
  "~/"*) SRC="${HOME}/${SRC#\~/}" ;;
esac
VCS="git"
if [ -d "${SRC}" ]; then
  SRC="$(cd "${SRC}" && pwd)"
  PROVIDER="local"
  if [ "${SRC}" = "$(pwd)" ]; then
    echo "ERROR - la ruta es este mismo workspace; registra repos de CODIGO."
    exit 1
  fi
  if ! git -C "${SRC}" rev-parse --git-dir > /dev/null 2>&1; then
    # Export/snapshot sin historia (tipico de codigo exportado de otro VCS):
    # se registra con vcs: none y se ENLAZA en repos/ en vez de clonar.
    # Su sello de procedencia sera una huella de archivos (stamp_of_repo).
    VCS="none"
    echo "AVISO - '${SRC}' no tiene .git: se registra como SNAPSHOT (vcs: none)."
  fi
else
  PROVIDER="$(provider_for_url "${SRC}")"
  case "${PROVIDER}" in
    local|"")
      echo "ERROR - '${SRC}' no es una ruta local existente ni una URL de un"
      echo "        proveedor soportado (github.com, gitlab.*, bitbucket.org)."
      exit 1 ;;
  esac
fi

# Nombre: derivado y sanitizado (se usa como ruta de carpeta y clave del registro)
if [ -z "${NAME}" ]; then
  NAME="$(basename "${SRC}")"
  NAME="${NAME%.git}"
fi
NAME="$(printf '%s' "${NAME}" | tr -cd 'A-Za-z0-9._-')"
case "${NAME}" in
  ""|.*|-*)
    echo "ERROR - no pude derivar un nombre valido del origen; usa --name <nombre>."
    exit 1 ;;
esac

# ---------- Clonar o actualizar (idempotente) ----------
load_env
mkdir -p repos
HOST="$(host_of_url "${SRC}")"
NUEVO="si"

run_git() {
  if [ "${PROVIDER}" != "local" ] && [ -n "$(token_for "${PROVIDER}")" ]; then
    GIT_TERMINAL_PROMPT=0 git_auth "${PROVIDER}" "${HOST}" "$@"
  else
    git "$@"
  fi
}

if [ "${VCS}" = "none" ]; then
  if [ -L "repos/${NAME}" ]; then
    echo ">> repos/${NAME} ya esta enlazado al snapshot."
    NUEVO="no"
  elif [ -e "repos/${NAME}" ]; then
    echo "ERROR - repos/${NAME} ya existe y no es el enlace al snapshot."
    echo "        Limpia con:  rm -rf repos/${NAME}   y vuelve a correr el alta."
    exit 1
  else
    echo ">> Enlazando snapshot ${NAME} -> ${SRC} ..."
    ln -s "${SRC}" "repos/${NAME}"
  fi
else
  if [ -d "repos/${NAME}" ] && [ ! -d "repos/${NAME}/.git" ]; then
    echo "ERROR - repos/${NAME} existe pero no es un repo git (clone interrumpido?)."
    echo "        Limpia con:  rm -rf repos/${NAME}   y vuelve a correr el alta."
    exit 1
  fi
  if [ -d "repos/${NAME}/.git" ]; then
    echo ">> repos/${NAME} ya existe: actualizando (pull --ff-only) ..."
    run_git -C "repos/${NAME}" pull --ff-only
    NUEVO="no"
  else
    echo ">> Clonando ${NAME} desde ${SRC} (${PROVIDER}) ..."
    run_git clone "${SRC}" "repos/${NAME}"
  fi
fi

# ---------- Registrar en repos.yaml (upsert, sin duplicar) ----------
# role puede traer espacios: pasar los k=v como argumentos, sin re-split
set -- name="${NAME}" url="${SRC}" provider="${PROVIDER}"
[ "${VCS}" = "none" ] && set -- "$@" vcs=none
[ -n "${ROLE}" ]         && set -- "$@" role="${ROLE}"
[ -n "${DOMAIN}" ]       && set -- "$@" domain="${DOMAIN}"
[ -n "${DEPLOY_ORDER}" ] && set -- "$@" deploy_order="${DEPLOY_ORDER}"
[ -n "${ENTRYPOINT}" ]   && set -- "$@" entrypoint=true
[ -n "${SYSTEM_NAME}" ]  && set -- "$@" system_name="${SYSTEM_NAME}"
RES="$(registry_upsert "$@")"
echo ">> Registro ${REGISTRY_FILE}: ${RES} (${NAME})"
registry_validate || exit 1

# ---------- Sembrar CLAUDE.md del repo ----------
if [ "${VCS}" = "none" ]; then
  echo "   (snapshot enlazado: no se escribe CLAUDE.md en la carpeta origen;"
  echo "    su contexto vive en el pack /repo-map del workspace)"
else
  seed_repo_claude_md "${NAME}"
fi

# ---------- Resumen ----------
echo ""
echo "OK - '${NAME}' listo (nuevo: ${NUEVO})."
echo "     Sistema: $(registry_system name) | entrypoint: $(registry_system entrypoint)"
echo "Siguientes pasos:"
echo "  1) ./scripts/generate-as-is.sh          (mapa as-is del sistema)"
echo "  2) desde Claude Code: /repo-add ${NAME}  completa CLAUDE.md e indexa"
echo "     en codebase-memory; luego /spec-create para especificar."
