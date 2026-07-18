#!/usr/bin/env bash
# setup.sh - Clona o actualiza los repositorios del sistema homebanking en repos/.
# Compatible con bash 3.2 (macOS).
#
# Modos de autenticacion (en este orden de preferencia):
#   1) TOKEN via .env  -> cp .env.example .env, completar BITBUCKET_USER y
#      BITBUCKET_TOKEN. Clona por HTTPS inyectando el token con un credential
#      helper efimero: el token NUNCA queda escrito en .git/config ni en las URLs.
#   2) SSH             -> sin .env; requiere llave cargada en Bitbucket.
#   3) HTTPS manual    -> GIT_PROTOCOL=https BITBUCKET_USER=usuario ./scripts/setup.sh
set -euo pipefail
SETUP_VERSION="v5-token"
echo "setup.sh ${SETUP_VERSION}"
cd "$(dirname "$0")/.."
mkdir -p repos

if [ ! -f .env ] && [ -z "${BITBUCKET_TOKEN:-}" ]; then
  echo "AVISO - no existe .env en $(pwd) y no hay BITBUCKET_TOKEN en el entorno."
  echo "        Para modo token:  cp .env.example .env && chmod 600 .env  (y completar)"
fi

# ---------- Cargar .env si existe ----------
if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

# Usuario para GIT: los API tokens de Atlassian CON scopes (ATATT largos)
# exigen el usuario especial x-bitbucket-api-token-auth en git, aunque la API
# REST use el email. Se resuelve automaticamente aqui; BITBUCKET_GIT_USER en
# .env permite forzarlo si hiciera falta.
GIT_USER="${BITBUCKET_GIT_USER:-${BITBUCKET_USER:-}}"
case "${BITBUCKET_TOKEN:-}" in
  ATATT*)
    if [ ${#BITBUCKET_TOKEN} -gt 100 ] && [ -z "${BITBUCKET_GIT_USER:-}" ]; then
      GIT_USER="x-bitbucket-api-token-auth"
    fi ;;
esac
export GIT_USER
CRED_HELPER='!f() { printf "username=%s\npassword=%s\n" "${GIT_USER}" "${BITBUCKET_TOKEN}"; }; f'

# git con credenciales efimeras (limpia helpers del sistema como osxkeychain
# para que no interfieran con credenciales viejas cacheadas)
git_auth() {
  # credential.helper= limpia helpers globales (osxkeychain con creds viejas);
  # el insteadOf identidad (prefijo mas largo gana) anula reescrituras
  # corporativas HTTPS->SSH que harian fallar el modo token.
  git -c credential.helper= \
      -c credential.helper="${CRED_HELPER}" \
      -c url."https://bitbucket.org/example-bank/".insteadOf="https://bitbucket.org/example-bank/" \
      "$@"
}

# ---------- Elegir modo ----------
if [ -n "${BITBUCKET_TOKEN:-}" ]; then
  MODE="token"
  export GIT_TERMINAL_PROMPT=0   # con token invalido: fallar rapido, no colgarse
elif [ "${GIT_PROTOCOL:-ssh}" = "https" ]; then
  MODE="https"
  export GIT_TERMINAL_PROMPT=1
else
  MODE="ssh"
fi
echo ">> Modo de autenticacion: ${MODE}"

USER_PREFIX=""
if [ "${MODE}" = "https" ] && [ -n "${BITBUCKET_USER:-}" ]; then
  USER_PREFIX="${BITBUCKET_USER}@"
fi

build_url() {
  if [ "${MODE}" = "ssh" ]; then
    echo "git@bitbucket.org:example-bank/$1.git"
  else
    echo "https://${USER_PREFIX}bitbucket.org/example-bank/$1.git"
  fi
}

# ---------- Pre-flight ----------
if [ "${MODE}" = "token" ]; then
  if [ -z "${BITBUCKET_USER:-}" ]; then
    echo "ERROR - .env tiene BITBUCKET_TOKEN pero falta BITBUCKET_USER."
    echo "        Ver .env.example: el usuario depende del tipo de token."
    exit 1
  fi
  echo ">> Verificando token contra Bitbucket ..."
  if git_auth ls-remote --heads "$(build_url homebanking-pwa)" > /dev/null 2>&1; then
    echo "   OK - token aceptado"
  else
    echo ""
    echo "ERROR - Bitbucket rechazo el token (o no hay red). Revisa:"
    echo "  1) El par usuario/token es del tipo correcto (ver .env.example):"
    echo "     App Password -> usuario Bitbucket | API token -> email | Access token -> x-token-auth"
    echo "  2) El token tiene permiso 'Repositories: Read' y acceso al workspace example-bank."
    echo "  3) El token no esta vencido/revocado."
    echo ""
    echo "  Diagnostico automatico (identifica la causa exacta, no expone el token):"
    echo "     ./scripts/diag-bitbucket.sh"
    echo "  Prueba manual:"
    echo "     git -c credential.helper= -c credential.helper='!f() { printf \"username=%s\\npassword=%s\\n\" \"\$BITBUCKET_USER\" \"\$BITBUCKET_TOKEN\"; }; f' ls-remote https://bitbucket.org/example-bank/homebanking-pwa.git"
    exit 1
  fi
elif [ "${MODE}" = "ssh" ]; then
  echo ">> Verificando acceso SSH a bitbucket.org ..."
  SSH_OUT="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -T git@bitbucket.org 2>&1 || true)"
  if printf '%s' "${SSH_OUT}" | grep -qi "authenticated"; then
    echo "   OK - llave SSH aceptada"
  else
    echo ""
    echo "ERROR - sin acceso SSH. Respuesta:"
    printf '   %s\n' "${SSH_OUT}"
    echo ""
    echo "Opcion recomendada: usar TOKEN en .env ->  cp .env.example .env  (y completar)"
    echo "O diagnosticar SSH:"
    echo "  a) 'Permission denied' -> ssh-add ~/.ssh/id_ed25519 y registrar la llave en Bitbucket"
    echo "  b) Timeout (VPN/puerto 22 bloqueado) -> en ~/.ssh/config:"
    echo "       Host bitbucket.org"
    echo "         HostName altssh.bitbucket.org"
    echo "         Port 443"
    exit 1
  fi
fi

# ---------- Clonar / actualizar ----------
REPO_NAMES="homebanking-pwa
homebanking-pwa-backend
homebanking-pwa-proxy"

printf '%s\n' "${REPO_NAMES}" | while IFS= read -r name; do
  if [ -z "${name}" ]; then continue; fi
  url="$(build_url "${name}")"

  if [ -d "repos/${name}" ] && [ ! -d "repos/${name}/.git" ]; then
    echo "AVISO - repos/${name} existe pero no es un repo git (clone interrumpido?)."
    echo "        Limpia con:  rm -rf repos/${name}   y vuelve a correr este script."
    continue
  fi

  if [ -d "repos/${name}/.git" ]; then
    echo ">> Actualizando ${name} ..."
    if [ "${MODE}" = "token" ]; then
      git_auth -C "repos/${name}" pull --ff-only
    else
      git -C "repos/${name}" pull --ff-only
    fi
  else
    echo ">> Clonando ${name} (${MODE}) ..."
    if [ "${MODE}" = "token" ]; then
      git_auth clone "${url}" "repos/${name}"
    else
      git clone "${url}" "repos/${name}"
    fi
  fi

  if [ ! -f "repos/${name}/CLAUDE.md" ]; then
    sed "s/{{REPO}}/${name}/g" templates/CLAUDE.repo.md > "repos/${name}/CLAUDE.md"
    echo "   -> CLAUDE.md sembrado en ${name} (completar y commitear en ESE repo)"
  fi
done

echo "OK - Workspace listo. Siguiente: ./scripts/generate-as-is.sh && claude"
