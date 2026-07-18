#!/usr/bin/env bash
# setup.sh - Clona o actualiza en repos/ TODOS los repositorios declarados en
# repos.yaml (la unica fuente de verdad de la topologia; ver repo-lib.sh).
# Compatible con bash 3.2 (macOS).
#
# Autenticacion por proveedor (token via .env; ver .env.example):
#   bitbucket -> BITBUCKET_USER + BITBUCKET_TOKEN (App Password / API token /
#                Access token; los ATATT con scopes usan solos el usuario
#                x-bitbucket-api-token-auth para git)
#   github    -> GITHUB_TOKEN   (PAT; usuario opcional GITHUB_USER)
#   gitlab    -> GITLAB_TOKEN   (PAT; usuario opcional GITLAB_USER)
#   local     -> sin credenciales (clona desde la ruta declarada)
# URLs ssh (git@host:...) usan la llave SSH cargada; URLs https sin token
# piden credenciales interactivamente.
# Los tokens se inyectan con credential helper EFIMERO: nunca quedan en
# .git/config, URLs ni historial de shell.
set -euo pipefail
SETUP_VERSION="v6-registry"
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

echo "setup.sh ${SETUP_VERSION}"
load_env
registry_validate || exit 1
mkdir -p repos

SYSTEM_NAME="$(registry_system name)"
echo ">> Sistema: ${SYSTEM_NAME} ($(registry_repos | wc -l | tr -d ' ') repos en ${REGISTRY_FILE})"

# ---------- Pre-flight: una verificacion por proveedor/modo ----------
CHECKED=""   # lista "provider:modo" ya verificados

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
    echo ">> Verificando acceso SSH a ${host} ..."
    SSH_OUT="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -T "git@${host}" 2>&1 || true)"
    if printf '%s' "${SSH_OUT}" | grep -qiE "authenticated|welcome|successful"; then
      echo "   OK - llave SSH aceptada"
    else
      echo ""
      echo "ERROR - sin acceso SSH a ${host}. Respuesta:"
      printf '   %s\n' "${SSH_OUT}"
      echo ""
      echo "Opcion recomendada: usar TOKEN en .env ->  cp .env.example .env  (y completar)"
      echo "O diagnosticar SSH:"
      echo "  a) 'Permission denied' -> ssh-add ~/.ssh/id_ed25519 y registrar la llave en ${host}"
      echo "  b) Timeout (VPN/puerto 22 bloqueado) -> en ~/.ssh/config usar el host"
      echo "     SSH alternativo por 443 del proveedor (bitbucket: altssh.bitbucket.org)"
      return 1
    fi
  elif [ "${mode}" = "token" ]; then
    if [ "${prov}" = "bitbucket" ] && [ -z "${BITBUCKET_USER:-}" ]; then
      echo "ERROR - hay BITBUCKET_TOKEN pero falta BITBUCKET_USER en .env."
      echo "        Ver .env.example: el usuario depende del tipo de token."
      return 1
    fi
    echo ">> Verificando token de ${prov} contra ${host} ..."
    if GIT_TERMINAL_PROMPT=0 git_auth "${prov}" "${host}" ls-remote --heads "${url}" > /dev/null 2>&1; then
      echo "   OK - token aceptado"
    else
      echo ""
      echo "ERROR - ${prov} rechazo el token (o no hay red). Revisa:"
      echo "  1) $(token_var_for "${prov}") en .env es valido, no vencido/revocado."
      echo "  2) El token tiene permiso de lectura de repositorios y acceso al proyecto."
      if [ "${prov}" = "bitbucket" ]; then
        echo "  3) El par usuario/token es del tipo correcto (ver .env.example):"
        echo "     App Password -> usuario Bitbucket | API token -> email | Access token -> x-token-auth"
        echo ""
        echo "  Diagnostico automatico (identifica la causa exacta, no expone el token):"
        echo "     ./scripts/diag-bitbucket.sh"
      fi
      return 1
    fi
  else
    echo "AVISO - sin $(token_var_for "${prov}") en .env: git pedira credenciales"
    echo "        interactivamente para los repos https de ${prov}."
  fi
}

# ---------- Clonar / actualizar ----------
for name in $(registry_repos); do
  url="$(registry_get "${name}" url)"
  prov="$(registry_get "${name}" provider)"
  vcs="$(registry_get "${name}" vcs)"

  # Snapshot sin historia: solo asegurar el enlace; no hay pull posible.
  if [ "${vcs}" = "none" ]; then
    if [ -L "repos/${name}" ] || [ -d "repos/${name}" ]; then
      echo ">> ${name}: snapshot enlazado (sin actualizacion posible)"
    elif [ -d "${url}" ]; then
      echo ">> Enlazando snapshot ${name} -> ${url} ..."
      ln -s "${url}" "repos/${name}"
    else
      echo "ERROR - ${name}: la ruta del snapshot '${url}' no existe."
      exit 1
    fi
    continue
  fi

  if [ -d "repos/${name}" ] && [ ! -d "repos/${name}/.git" ]; then
    echo "AVISO - repos/${name} existe pero no es un repo git (clone interrumpido?)."
    echo "        Limpia con:  rm -rf repos/${name}   y vuelve a correr este script."
    continue
  fi

  # Modo de git para ESTE repo
  if [ "${prov}" = "local" ]; then
    if [ ! -d "${url}/.git" ] && ! git -C "${url}" rev-parse --git-dir >/dev/null 2>&1; then
      echo "ERROR - ${name}: la ruta local '${url}' no es un repo git."
      exit 1
    fi
    GIT="git"
  else
    preflight "${prov}" "${url}" || exit 1
    case "${url}" in
      git@*|ssh://*) GIT="git" ;;
      *) if [ -n "$(token_for "${prov}")" ]; then
           GIT="token"; export GIT_TERMINAL_PROMPT=0   # token invalido: fallar rapido
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
    echo ">> Actualizando ${name} ..."
    run_git -C "repos/${name}" pull --ff-only
  else
    echo ">> Clonando ${name} (${prov}) ..."
    run_git clone "${url}" "repos/${name}"
  fi

  # Respaldo: /repo-add siembra y completa el CLAUDE.md; esto cubre repos
  # clonados directamente por setup.sh en maquinas nuevas.
  seed_repo_claude_md "${name}"
done

echo "OK - Workspace listo. Siguiente: ./scripts/generate-as-is.sh && claude"
