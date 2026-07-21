#!/usr/bin/env bash
# repo-add.sh - IDEMPOTENT onboarding of a repository into the factory:
# validates the input, clones (or updates), registers in repos.yaml and seeds
# the repo's CLAUDE.md. Compatible with bash 3.2 (macOS).
#
# Usage:
#   ./scripts/repo-add.sh <git-url | local-path> [options]
# Options:
#   --name <n>          name in repos/ (default: derived from the URL/path)
#   --role "<role>"     what the repo does within the system
#   --domain <d>        generic (default) | banking
#   --deploy-order <n>  lower = deployed earlier (default: last)
#   --entrypoint        marks this repo as the system's entrypoint (as-is graph)
#   --system-name <s>   system name (default: the registry's, or the name of
#                       the first repo if the registry does not exist)
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

usage() { sed -n '/^# Usage:/,/^set -euo/p' "$0" | sed '$d;s/^# \{0,1\}//'; }

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
    *) echo "ERROR - unknown option: $1"; usage; exit 1 ;;
  esac
done

# ---------- Validate the input ----------
# Credentials embedded in the URL: FORBIDDEN (they go in .env; a URL with a
# token would end up written to repos.yaml, .git/config and history).
if printf '%s' "${SRC}" | grep -qE '^[a-z+]+://[^/@]+:[^/@]+@'; then
  echo "ERROR - the URL carries embedded credentials (user:token@host)."
  echo "        Use the clean URL and put the token in .env (see .env.example)."
  exit 1
fi

# Expand ~ and resolve local paths to absolute
case "${SRC}" in
  "~/"*) SRC="${HOME}/${SRC#\~/}" ;;
esac
VCS="git"
if [ -d "${SRC}" ]; then
  SRC="$(cd "${SRC}" && pwd)"
  PROVIDER="local"
  if [ "${SRC}" = "$(pwd)" ]; then
    echo "ERROR - the path is this very workspace; register CODE repos."
    exit 1
  fi
  if ! git -C "${SRC}" rev-parse --git-dir > /dev/null 2>&1; then
    # Export/snapshot without history (typical of code exported from another
    # VCS): registered with vcs: none and LINKED in repos/ instead of cloned.
    # Its provenance stamp will be a file fingerprint (stamp_of_repo).
    VCS="none"
    echo "WARNING - '${SRC}' has no .git: registering it as a SNAPSHOT (vcs: none)."
  fi
else
  PROVIDER="$(provider_for_url "${SRC}")"
  case "${PROVIDER}" in
    local|"")
      echo "ERROR - '${SRC}' is neither an existing local path nor a URL of a"
      echo "        supported provider (github.com, gitlab.*, bitbucket.org)."
      exit 1 ;;
  esac
fi

# Name: derived and sanitized (used as folder path and registry key)
if [ -z "${NAME}" ]; then
  NAME="$(basename "${SRC}")"
  NAME="${NAME%.git}"
fi
NAME="$(printf '%s' "${NAME}" | tr -cd 'A-Za-z0-9._-')"
case "${NAME}" in
  ""|.*|-*)
    echo "ERROR - could not derive a valid name from the source; use --name <name>."
    exit 1 ;;
esac

# ---------- Clone or update (idempotent) ----------
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
    echo ">> repos/${NAME} is already linked to the snapshot."
    NUEVO="no"
  elif [ -e "repos/${NAME}" ]; then
    echo "ERROR - repos/${NAME} already exists and is not the snapshot link."
    echo "        Clean up with:  rm -rf repos/${NAME}   and run the onboarding again."
    exit 1
  else
    echo ">> Linking snapshot ${NAME} -> ${SRC} ..."
    ln -s "${SRC}" "repos/${NAME}"
  fi
else
  if [ -d "repos/${NAME}" ] && [ ! -d "repos/${NAME}/.git" ]; then
    echo "ERROR - repos/${NAME} exists but is not a git repo (interrupted clone?)."
    echo "        Clean up with:  rm -rf repos/${NAME}   and run the onboarding again."
    exit 1
  fi
  if [ -d "repos/${NAME}/.git" ]; then
    echo ">> repos/${NAME} already exists: updating (pull --ff-only) ..."
    run_git -C "repos/${NAME}" pull --ff-only
    NUEVO="no"
  else
    echo ">> Cloning ${NAME} from ${SRC} (${PROVIDER}) ..."
    run_git clone "${SRC}" "repos/${NAME}"
  fi
fi

# ---------- Register in repos.yaml (upsert, no duplicates) ----------
# role may contain spaces: pass the k=v pairs as arguments, without re-split
set -- name="${NAME}" url="${SRC}" provider="${PROVIDER}"
[ "${VCS}" = "none" ] && set -- "$@" vcs=none
[ -n "${ROLE}" ]         && set -- "$@" role="${ROLE}"
[ -n "${DOMAIN}" ]       && set -- "$@" domain="${DOMAIN}"
[ -n "${DEPLOY_ORDER}" ] && set -- "$@" deploy_order="${DEPLOY_ORDER}"
[ -n "${ENTRYPOINT}" ]   && set -- "$@" entrypoint=true
[ -n "${SYSTEM_NAME}" ]  && set -- "$@" system_name="${SYSTEM_NAME}"
RES="$(registry_upsert "$@")"
echo ">> Registry ${REGISTRY_FILE}: ${RES} (${NAME})"
registry_validate || exit 1

# ---------- Seed the repo's CLAUDE.md ----------
if [ "${VCS}" = "none" ]; then
  echo "   (linked snapshot: no CLAUDE.md is written into the source folder;"
  echo "    its context lives in the workspace's /repo-map pack)"
else
  seed_repo_claude_md "${NAME}"
fi

# ---------- Summary ----------
echo ""
echo "OK - '${NAME}' ready (new: ${NUEVO})."
echo "     System: $(registry_system name) | entrypoint: $(registry_system entrypoint)"
echo "Next steps:"
echo "  1) ./scripts/generate-as-is.sh          (as-is map of the system)"
echo "  2) from Claude Code: /repo-add ${NAME}  fills in CLAUDE.md and indexes"
echo "     it in codebase-memory; then /spec-create to specify."
