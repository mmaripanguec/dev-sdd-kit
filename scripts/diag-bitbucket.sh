#!/usr/bin/env bash
# diag-bitbucket.sh - Diagnostica por que Bitbucket rechaza las credenciales.
# Seguro de compartir: NUNCA imprime el token (solo prefijo y largo).
# Compatible con bash 3.2 (macOS).
set -uo pipefail
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

echo "=== Diagnostico Bitbucket ==="

# Objetivo de las pruebas: el PRIMER repo con provider bitbucket del registro
BB_URL=""
for _n in $(registry_repos 2>/dev/null); do
  if [ "$(registry_get "${_n}" provider)" = "bitbucket" ]; then
    BB_URL="$(registry_get "${_n}" url)"
    break
  fi
done
if [ -z "${BB_URL}" ]; then
  echo "No hay repos con provider: bitbucket en repos.yaml - nada que diagnosticar."
  echo "(este script aplica SOLO a Bitbucket; github/gitlab usan token simple en .env)"
  exit 0
fi
# workspace/slug del repo, p.ej. mi-workspace/mi-repo
BB_SLUG="${BB_URL#*bitbucket.org}"
BB_SLUG="${BB_SLUG#[:/]}"
BB_SLUG="${BB_SLUG%.git}"
BB_WS="${BB_SLUG%%/*}"

# ---------- 1. .env ----------
if [ ! -f .env ]; then
  echo "[1] .env: NO EXISTE en $(pwd)  ->  cp .env.example .env && chmod 600 .env"
  exit 1
fi
echo "[1] .env: existe"

CR_COUNT=$(grep -c "$(printf '\r')" .env 2>/dev/null || true)
if [ -z "${CR_COUNT}" ]; then CR_COUNT=0; fi
if [ "${CR_COUNT}" != "0" ]; then
  echo "    PROBLEMA: .env tiene retornos de carro (\\r) - tipico al pegar desde"
  echo "    Windows/HTML. Eso corrompe el token de forma invisible. Arreglo:"
  echo "       perl -pi -e 's/\\r//g' .env"
  exit 1
fi

set -a; . ./.env; set +a

USER_VAL="${BITBUCKET_USER:-}"
TOKEN_VAL="${BITBUCKET_TOKEN:-}"
if [ -z "${USER_VAL}" ] || [ -z "${TOKEN_VAL}" ]; then
  echo "    PROBLEMA: falta BITBUCKET_USER o BITBUCKET_TOKEN en .env"
  exit 1
fi

# Espacios accidentales al inicio/fin del token
TRIMMED=$(printf '%s' "${TOKEN_VAL}" | sed 's/^ *//;s/ *$//')
if [ "${TRIMMED}" != "${TOKEN_VAL}" ]; then
  echo "    PROBLEMA: el token tiene espacios al inicio o final. Corrigelo en .env"
  exit 1
fi

PREFIX=$(printf '%s' "${TOKEN_VAL}" | cut -c1-5)
LEN=${#TOKEN_VAL}
echo "    BITBUCKET_USER=${USER_VAL}"
echo "    BITBUCKET_TOKEN=${PREFIX}... (largo ${LEN}, no se muestra completo)"

# ---------- 2. Coherencia tipo de token <-> usuario (heuristica por prefijo) ----------
echo "[2] Tipo de token (heuristica por prefijo):"
case "${PREFIX}" in
  ATATT)
    echo "    -> parece API TOKEN de Atlassian: el usuario debe ser tu EMAIL de la cuenta."
    case "${USER_VAL}" in
      *@*) echo "       usuario contiene @ : coherente" ;;
      *)   echo "       PROBLEMA PROBABLE: usuario '${USER_VAL}' no es un email."
           echo "       En .env pon BITBUCKET_USER=tu_email_de_atlassian" ;;
    esac ;;
  ATCTT)
    echo "    -> parece ACCESS TOKEN de repo/proyecto/workspace: usuario = x-token-auth."
    if [ "${USER_VAL}" != "x-token-auth" ]; then
      echo "       PROBLEMA PROBABLE: en .env pon BITBUCKET_USER=x-token-auth"
    else
      echo "       coherente"
    fi ;;
  ATBB*)
    echo "    -> parece APP PASSWORD: usuario = tu usuario Bitbucket (no el email)." ;;
  *)
    echo "    -> prefijo no reconocido (${PREFIX}); continuo con las pruebas de red." ;;
esac

# ---------- 3. Red y autenticacion contra la API ----------
echo "[3] Prueba de red + auth (repo ${BB_SLUG}):"
HTTP=$(curl -sS -o /tmp/bb-diag.json -w "%{http_code}" --connect-timeout 10 \
  --user "${USER_VAL}:${TOKEN_VAL}" \
  "https://api.bitbucket.org/2.0/repositories/${BB_SLUG}" 2>/tmp/bb-diag.err || echo "000")

case "${HTTP}" in
  200)
    echo "    HTTP 200 - credenciales VALIDAS y con acceso al repo." ;;
  401)
    echo "    HTTP 401 - Bitbucket NO reconoce el par usuario/token."
    echo "    Causas: usuario del tipo equivocado (ver [2]), token mal copiado,"
    echo "    o token revocado. Regenera el token y pega de nuevo con cuidado." ;;
  403)
    echo "    HTTP 403 - el token ES valido pero SIN PERMISO sobre este repo."
    echo "    Falta scope 'Repositories: Read' o tu cuenta no tiene acceso al"
    echo "    workspace ${BB_WS} / a este repo. Pide acceso al admin." ;;
  404)
    echo "    HTTP 404 - autenticado pero el repo no es visible con esas credenciales"
    echo "    (Bitbucket devuelve 404 para repos privados sin acceso)."
    echo "    Pide al admin acceso de lectura a ${BB_SLUG}." ;;
  000)
    echo "    SIN CONEXION a api.bitbucket.org - problema de red/VPN/proxy:"
    sed 's/^/      /' /tmp/bb-diag.err 2>/dev/null | head -3
    echo "    Si tu red corporativa usa proxy HTTPS, configura:"
    echo "      export HTTPS_PROXY=http://proxy.tuempresa:puerto" ;;
  *)
    echo "    HTTP ${HTTP} - respuesta inesperada:"
    head -c 300 /tmp/bb-diag.json 2>/dev/null; echo "" ;;
esac

# ---------- 4. Configuracion local de git que puede interferir ----------
echo "[4] git --version: $(git --version)"
echo "    Config relevante (credential / insteadOf / proxy):"
GIT_CFG=$(git config --show-origin --get-regexp '^(credential|url\..*insteadof|http\.proxy|https\.proxy|http\.https)' 2>/dev/null || true)
if [ -n "${GIT_CFG}" ]; then
  printf '%s\n' "${GIT_CFG}" | sed 's/^/      /'
  if printf '%s' "${GIT_CFG}" | grep -qi 'insteadof'; then
    echo "    ATENCION: hay reescrituras de URL (insteadOf). Si alguna convierte"
    echo "    https://bitbucket.org/... en git@... , git termina yendo por SSH"
    echo "    aunque le pases HTTPS - y por eso la API acepta pero git falla."
  fi
else
  echo "      (ninguna - limpio)"
fi

# ---------- 5. Prueba final con git, MOSTRANDO el error real ----------
if [ "${HTTP}" = "200" ]; then
  echo "[5] Prueba git ls-remote (mismo mecanismo de setup.sh):"
  export BITBUCKET_USER="${USER_VAL}" BITBUCKET_TOKEN="${TOKEN_VAL}"
  GIT_ERR=$(GIT_TERMINAL_PROMPT=0 git \
      -c credential.helper= \
      -c credential.helper='!f() { printf "username=%s\npassword=%s\n" "${BITBUCKET_USER}" "${BITBUCKET_TOKEN}"; }; f' \
      -c url."https://bitbucket.org/${BB_WS}/".insteadOf="https://bitbucket.org/${BB_WS}/" \
      ls-remote --heads "https://bitbucket.org/${BB_SLUG}.git" 2>&1 > /dev/null) || true
  if [ -z "${GIT_ERR}" ]; then
    echo "    OK - git autentica. Ya puedes correr ./scripts/setup.sh"
  else
    # Token ATATT largo (con scopes): git exige el usuario magico
    # x-bitbucket-api-token-auth en lugar del email. Reintento automatico.
    if [ "${PREFIX}" = "ATATT" ]; then
      echo "    Fallo con usuario '${USER_VAL}'. Reintentando con el usuario especial"
      echo "    de git para API tokens con scopes: x-bitbucket-api-token-auth ..."
      GIT_ERR2=$(GIT_TERMINAL_PROMPT=0 git \
          -c credential.helper= \
          -c credential.helper='!f() { printf "username=%s\npassword=%s\n" "x-bitbucket-api-token-auth" "${BITBUCKET_TOKEN}"; }; f' \
          -c url."https://bitbucket.org/${BB_WS}/".insteadOf="https://bitbucket.org/${BB_WS}/" \
          ls-remote --heads "https://bitbucket.org/${BB_SLUG}.git" 2>&1 > /dev/null) || true
      if [ -z "${GIT_ERR2}" ]; then
        echo ""
        echo "    RESUELTO: git autentica con el usuario especial."
        echo "    ARREGLO -> en .env cambia:  BITBUCKET_USER=x-bitbucket-api-token-auth"
        echo "    (la API REST seguira aceptando el token; setup.sh v5 ya usa el"
        echo "     usuario correcto para cada cosa automaticamente)"
        exit 0
      fi
      echo "    Tambien fallo con x-bitbucket-api-token-auth."
      echo ""
      echo "    CAUSA MAS PROBABLE: el token con scopes NO incluye los scopes de git."
      echo "    Arreglo (elige uno):"
      echo "      a) Crear un API token SIN scopes (id.atlassian.com > Security >"
      echo "         API tokens > 'Create API token' simple) - funciona como antes."
      echo "      b) Crear uno CON scopes seleccionando el producto Bitbucket e"
      echo "         incluyendo al menos: Account:Read + Repositories:Read (Write"
      echo "         si haras push)."
    fi
    echo "    git fallo. Error real (sin token):"
    printf '%s\n' "${GIT_ERR}" | sed "s/${TOKEN_VAL}/***TOKEN***/g" | sed 's/^/      /' | head -8
    echo ""
    echo "    Interpretacion:"
    echo "      - 'Permission denied (publickey)' -> un insteadOf de [4] esta"
    echo "        reescribiendo HTTPS a SSH. Arreglo: borrar esa regla o dejar que"
    echo "        setup.sh la neutralice (version v4, ya incluida)."
    echo "      - 'Authentication failed' -> un helper global (osxkeychain) con"
    echo "        credenciales viejas gana. Limpia la entrada de bitbucket.org en"
    echo "        Acceso a Llaveros (Keychain Access) o: "
    echo "          printf 'protocol=https\nhost=bitbucket.org\n' | git credential-osxkeychain erase"
    echo "      - 'Could not resolve host' / timeout -> proxy solo-git: revisa"
    echo "        http.proxy en [4]."
  fi
fi
rm -f /tmp/bb-diag.json /tmp/bb-diag.err
echo "=== Fin del diagnostico ==="
