#!/usr/bin/env bash
# setup.sh - Clones or updates in repos/ ALL repositories declared in
# repos.yaml (the only source of truth for the topology; see repo-lib.sh).
# Compatible with bash 3.2 (macOS).
#
# Authentication per provider (token via .env; see .env.example):
#   bitbucket -> BITBUCKET_USER + BITBUCKET_TOKEN (App Password / API token /
#                Access token; scoped ATATT tokens automatically use the
#                special user x-bitbucket-api-token-auth for git)
#   github    -> GITHUB_TOKEN   (PAT; optional user GITHUB_USER)
#   gitlab    -> GITLAB_TOKEN   (PAT; optional user GITLAB_USER)
#   local     -> no credentials (clones from the declared path)
# ssh URLs (git@host:...) use the loaded SSH key; https URLs without token
# prompt for credentials interactively.
# Tokens are injected with an EPHEMERAL credential helper: they never end up
# in .git/config, URLs or shell history.
set -euo pipefail
SETUP_VERSION="v6-registry"
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

echo "setup.sh ${SETUP_VERSION}"
load_env
registry_validate || exit 1
mkdir -p repos

SYSTEM_NAME="$(registry_system name)"
echo ">> System: ${SYSTEM_NAME} ($(registry_repos | wc -l | tr -d ' ') repos in ${REGISTRY_FILE})"

# ---------- Pre-flight: one check per provider/mode ----------
CHECKED=""   # list of "provider:mode" already checked

preflight() {
  prov="$1"; url="$2"
  host="$(host_of_url "${url}")"
  case "${url}" in
    git@*|ssh://*) mode="ssh" ;;
    *) if [ -n "$(token_for "${prov}")" ]; then mode="token"; else mode="https-manual"; fi ;;
  esac
  case " ${CHECKED} " in *" ${prov}:${mode} "*) return 0 ;; esac
  CHECKED="${CHECKED} ${prov}:${mode}"

  if [ "${mode}" = "ssh" ]; then
    echo ">> Checking SSH access to ${host} ..."
    SSH_OUT="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -T "git@${host}" 2>&1 || true)"
    if printf '%s' "${SSH_OUT}" | grep -qiE "authenticated|welcome|successful"; then
      echo "   OK - SSH key accepted"
    else
      echo ""
      echo "ERROR - no SSH access to ${host}. Response:"
      printf '   %s\n' "${SSH_OUT}"
      echo ""
      echo "Recommended option: use a TOKEN in .env ->  cp .env.example .env  (and fill it in)"
      echo "Or diagnose SSH:"
      echo "  a) 'Permission denied' -> ssh-add ~/.ssh/id_ed25519 and register the key on ${host}"
      echo "  b) Timeout (VPN/port 22 blocked) -> in ~/.ssh/config use the provider's"
      echo "     alternative SSH host over 443 (bitbucket: altssh.bitbucket.org)"
      return 1
    fi
  elif [ "${mode}" = "token" ]; then
    if [ "${prov}" = "bitbucket" ] && [ -z "${BITBUCKET_USER:-}" ]; then
      echo "ERROR - BITBUCKET_TOKEN is set but BITBUCKET_USER is missing in .env."
      echo "        See .env.example: the user depends on the token type."
      return 1
    fi
    echo ">> Checking ${prov} token against ${host} ..."
    if GIT_TERMINAL_PROMPT=0 git_auth "${prov}" "${host}" ls-remote --heads "${url}" > /dev/null 2>&1; then
      echo "   OK - token accepted"
    else
      echo ""
      echo "ERROR - ${prov} rejected the token (or there is no network). Check:"
      echo "  1) $(token_var_for "${prov}") in .env is valid, not expired/revoked."
      echo "  2) The token has repository read permission and access to the project."
      if [ "${prov}" = "bitbucket" ]; then
        echo "  3) The user/token pair is of the right type (see .env.example):"
        echo "     App Password -> Bitbucket user | API token -> email | Access token -> x-token-auth"
        echo ""
        echo "  Automatic diagnosis (pinpoints the exact cause, does not expose the token):"
        echo "     ./scripts/diag-bitbucket.sh"
      fi
      return 1
    fi
  else
    echo "WARNING - no $(token_var_for "${prov}") in .env: git will prompt for"
    echo "          credentials interactively for ${prov} https repos."
  fi
}

# ---------- Clone / update ----------
for name in $(registry_repos); do
  url="$(registry_get "${name}" url)"
  prov="$(registry_get "${name}" provider)"
  vcs="$(registry_get "${name}" vcs)"

  # Snapshot without history: only ensure the link; no pull is possible.
  if [ "${vcs}" = "none" ]; then
    if [ -L "repos/${name}" ] || [ -d "repos/${name}" ]; then
      echo ">> ${name}: snapshot linked (no update possible)"
    elif [ -d "${url}" ]; then
      echo ">> Linking snapshot ${name} -> ${url} ..."
      ln -s "${url}" "repos/${name}"
    else
      echo "ERROR - ${name}: snapshot path '${url}' does not exist."
      exit 1
    fi
    continue
  fi

  if [ -d "repos/${name}" ] && [ ! -d "repos/${name}/.git" ]; then
    echo "WARNING - repos/${name} exists but is not a git repo (interrupted clone?)."
    echo "          Clean up with:  rm -rf repos/${name}   and run this script again."
    continue
  fi

  # git mode for THIS repo
  if [ "${prov}" = "local" ]; then
    if [ ! -d "${url}/.git" ] && ! git -C "${url}" rev-parse --git-dir >/dev/null 2>&1; then
      echo "ERROR - ${name}: local path '${url}' is not a git repo."
      exit 1
    fi
    GIT="git"
  else
    preflight "${prov}" "${url}" || exit 1
    case "${url}" in
      git@*|ssh://*) GIT="git" ;;
      *) if [ -n "$(token_for "${prov}")" ]; then
           GIT="token"; export GIT_TERMINAL_PROMPT=0   # invalid token: fail fast
         else
           GIT="git"; export GIT_TERMINAL_PROMPT=1
         fi ;;
    esac
  fi

  run_git() {
    if [ "${GIT}" = "token" ]; then
      git_auth "${prov}" "$(host_of_url "${url}")" "$@"
    else
      git "$@"
    fi
  }

  if [ -d "repos/${name}/.git" ]; then
    echo ">> Updating ${name} ..."
    run_git -C "repos/${name}" pull --ff-only
  else
    echo ">> Cloning ${name} (${prov}) ..."
    run_git clone "${url}" "repos/${name}"
  fi

  # Fallback: /repo-add seeds and fills in the CLAUDE.md; this covers repos
  # cloned directly by setup.sh on new machines.
  seed_repo_claude_md "${name}"
done

echo "OK - Workspace ready. Next: ./scripts/generate-as-is.sh && claude"
