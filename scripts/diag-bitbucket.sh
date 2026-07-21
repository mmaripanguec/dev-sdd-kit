#!/usr/bin/env bash
# diag-bitbucket.sh - Diagnoses why Bitbucket rejects the credentials.
# Safe to share: it NEVER prints the token (only prefix and length).
# Compatible with bash 3.2 (macOS).
set -uo pipefail
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

echo "=== Bitbucket diagnosis ==="

# Test target: the FIRST repo with provider bitbucket in the registry
BB_URL=""
for _n in $(registry_repos 2>/dev/null); do
  if [ "$(registry_get "${_n}" provider)" = "bitbucket" ]; then
    BB_URL="$(registry_get "${_n}" url)"
    break
  fi
done
if [ -z "${BB_URL}" ]; then
  echo "No repos with provider: bitbucket in repos.yaml - nothing to diagnose."
  echo "(this script applies ONLY to Bitbucket; github/gitlab use a simple token in .env)"
  exit 0
fi
# workspace/slug of the repo, e.g. my-workspace/my-repo
BB_SLUG="${BB_URL#*bitbucket.org}"
BB_SLUG="${BB_SLUG#[:/]}"
BB_SLUG="${BB_SLUG%.git}"
BB_WS="${BB_SLUG%%/*}"

# ---------- 1. .env ----------
if [ ! -f .env ]; then
  echo "[1] .env: DOES NOT EXIST in $(pwd)  ->  cp .env.example .env && chmod 600 .env"
  exit 1
fi
echo "[1] .env: exists"

CR_COUNT=$(grep -c "$(printf '\r')" .env 2>/dev/null || true)
if [ -z "${CR_COUNT}" ]; then CR_COUNT=0; fi
if [ "${CR_COUNT}" != "0" ]; then
  echo "    PROBLEM: .env has carriage returns (\\r) - typical when pasting from"
  echo "    Windows/HTML. That corrupts the token invisibly. Fix:"
  echo "       perl -pi -e 's/\\r//g' .env"
  exit 1
fi

set -a; . ./.env; set +a

USER_VAL="${BITBUCKET_USER:-}"
TOKEN_VAL="${BITBUCKET_TOKEN:-}"
if [ -z "${USER_VAL}" ] || [ -z "${TOKEN_VAL}" ]; then
  echo "    PROBLEM: BITBUCKET_USER or BITBUCKET_TOKEN missing in .env"
  exit 1
fi

# Accidental leading/trailing spaces in the token
TRIMMED=$(printf '%s' "${TOKEN_VAL}" | sed 's/^ *//;s/ *$//')
if [ "${TRIMMED}" != "${TOKEN_VAL}" ]; then
  echo "    PROBLEM: the token has leading or trailing spaces. Fix it in .env"
  exit 1
fi

PREFIX=$(printf '%s' "${TOKEN_VAL}" | cut -c1-5)
LEN=${#TOKEN_VAL}
echo "    BITBUCKET_USER=${USER_VAL}"
echo "    BITBUCKET_TOKEN=${PREFIX}... (length ${LEN}, not shown in full)"

# ---------- 2. Consistency token type <-> user (heuristic by prefix) ----------
echo "[2] Token type (heuristic by prefix):"
case "${PREFIX}" in
  ATATT)
    echo "    -> looks like an Atlassian API TOKEN: the user must be your account EMAIL."
    case "${USER_VAL}" in
      *@*) echo "       user contains @ : consistent" ;;
      *)   echo "       LIKELY PROBLEM: user '${USER_VAL}' is not an email."
           echo "       In .env set BITBUCKET_USER=your_atlassian_email" ;;
    esac ;;
  ATCTT)
    echo "    -> looks like a repo/project/workspace ACCESS TOKEN: user = x-token-auth."
    if [ "${USER_VAL}" != "x-token-auth" ]; then
      echo "       LIKELY PROBLEM: in .env set BITBUCKET_USER=x-token-auth"
    else
      echo "       consistent"
    fi ;;
  ATBB*)
    echo "    -> looks like an APP PASSWORD: user = your Bitbucket username (not the email)." ;;
  *)
    echo "    -> unrecognized prefix (${PREFIX}); continuing with the network tests." ;;
esac

# ---------- 3. Network and authentication against the API ----------
echo "[3] Network + auth test (repo ${BB_SLUG}):"
HTTP=$(curl -sS -o /tmp/bb-diag.json -w "%{http_code}" --connect-timeout 10 \
  --user "${USER_VAL}:${TOKEN_VAL}" \
  "https://api.bitbucket.org/2.0/repositories/${BB_SLUG}" 2>/tmp/bb-diag.err || echo "000")

case "${HTTP}" in
  200)
    echo "    HTTP 200 - credentials VALID and with access to the repo." ;;
  401)
    echo "    HTTP 401 - Bitbucket does NOT recognize the user/token pair."
    echo "    Causes: user of the wrong type (see [2]), badly copied token,"
    echo "    or revoked token. Regenerate the token and paste it again carefully." ;;
  403)
    echo "    HTTP 403 - the token IS valid but has NO PERMISSION on this repo."
    echo "    Missing 'Repositories: Read' scope or your account has no access to"
    echo "    the ${BB_WS} workspace / this repo. Ask the admin for access." ;;
  404)
    echo "    HTTP 404 - authenticated but the repo is not visible with those credentials"
    echo "    (Bitbucket returns 404 for private repos without access)."
    echo "    Ask the admin for read access to ${BB_SLUG}." ;;
  000)
    echo "    NO CONNECTION to api.bitbucket.org - network/VPN/proxy problem:"
    sed 's/^/      /' /tmp/bb-diag.err 2>/dev/null | head -3
    echo "    If your corporate network uses an HTTPS proxy, configure:"
    echo "      export HTTPS_PROXY=http://proxy.yourcompany:port" ;;
  *)
    echo "    HTTP ${HTTP} - unexpected response:"
    head -c 300 /tmp/bb-diag.json 2>/dev/null; echo "" ;;
esac

# ---------- 4. Local git configuration that may interfere ----------
echo "[4] git --version: $(git --version)"
echo "    Relevant config (credential / insteadOf / proxy):"
GIT_CFG=$(git config --show-origin --get-regexp '^(credential|url\..*insteadof|http\.proxy|https\.proxy|http\.https)' 2>/dev/null || true)
if [ -n "${GIT_CFG}" ]; then
  printf '%s\n' "${GIT_CFG}" | sed 's/^/      /'
  if printf '%s' "${GIT_CFG}" | grep -qi 'insteadof'; then
    echo "    ATTENTION: there are URL rewrites (insteadOf). If any of them turns"
    echo "    https://bitbucket.org/... into git@... , git ends up going over SSH"
    echo "    even when you pass HTTPS - hence the API accepts but git fails."
  fi
else
  echo "      (none - clean)"
fi

# ---------- 5. Final test with git, SHOWING the real error ----------
if [ "${HTTP}" = "200" ]; then
  echo "[5] git ls-remote test (same mechanism as setup.sh):"
  export BITBUCKET_USER="${USER_VAL}" BITBUCKET_TOKEN="${TOKEN_VAL}"
  GIT_ERR=$(GIT_TERMINAL_PROMPT=0 git \
      -c credential.helper= \
      -c credential.helper='!f() { printf "username=%s\npassword=%s\n" "${BITBUCKET_USER}" "${BITBUCKET_TOKEN}"; }; f' \
      -c url."https://bitbucket.org/${BB_WS}/".insteadOf="https://bitbucket.org/${BB_WS}/" \
      ls-remote --heads "https://bitbucket.org/${BB_SLUG}.git" 2>&1 > /dev/null) || true
  if [ -z "${GIT_ERR}" ]; then
    echo "    OK - git authenticates. You can now run ./scripts/setup.sh"
  else
    # Long ATATT token (with scopes): git requires the magic user
    # x-bitbucket-api-token-auth instead of the email. Automatic retry.
    if [ "${PREFIX}" = "ATATT" ]; then
      echo "    Failed with user '${USER_VAL}'. Retrying with the special git"
      echo "    user for scoped API tokens: x-bitbucket-api-token-auth ..."
      GIT_ERR2=$(GIT_TERMINAL_PROMPT=0 git \
          -c credential.helper= \
          -c credential.helper='!f() { printf "username=%s\npassword=%s\n" "x-bitbucket-api-token-auth" "${BITBUCKET_TOKEN}"; }; f' \
          -c url."https://bitbucket.org/${BB_WS}/".insteadOf="https://bitbucket.org/${BB_WS}/" \
          ls-remote --heads "https://bitbucket.org/${BB_SLUG}.git" 2>&1 > /dev/null) || true
      if [ -z "${GIT_ERR2}" ]; then
        echo ""
        echo "    SOLVED: git authenticates with the special user."
        echo "    FIX -> in .env change:  BITBUCKET_USER=x-bitbucket-api-token-auth"
        echo "    (the REST API will keep accepting the token; setup.sh v5 already"
        echo "     uses the right user for each thing automatically)"
        exit 0
      fi
      echo "    Also failed with x-bitbucket-api-token-auth."
      echo ""
      echo "    MOST LIKELY CAUSE: the scoped token does NOT include the git scopes."
      echo "    Fix (choose one):"
      echo "      a) Create an API token WITHOUT scopes (id.atlassian.com > Security >"
      echo "         API tokens > simple 'Create API token') - works as before."
      echo "      b) Create one WITH scopes selecting the Bitbucket product and"
      echo "         including at least: Account:Read + Repositories:Read (Write"
      echo "         if you will push)."
    fi
    echo "    git failed. Real error (token redacted):"
    printf '%s\n' "${GIT_ERR}" | sed "s/${TOKEN_VAL}/***TOKEN***/g" | sed 's/^/      /' | head -8
    echo ""
    echo "    Interpretation:"
    echo "      - 'Permission denied (publickey)' -> an insteadOf from [4] is"
    echo "        rewriting HTTPS to SSH. Fix: delete that rule or let setup.sh"
    echo "        neutralize it (version v4, already included)."
    echo "      - 'Authentication failed' -> a global helper (osxkeychain) with"
    echo "        stale credentials wins. Clear the bitbucket.org entry in"
    echo "        Keychain Access or: "
    echo "          printf 'protocol=https\nhost=bitbucket.org\n' | git credential-osxkeychain erase"
    echo "      - 'Could not resolve host' / timeout -> git-only proxy: check"
    echo "        http.proxy in [4]."
  fi
fi
rm -f /tmp/bb-diag.json /tmp/bb-diag.err
echo "=== End of diagnosis ==="
