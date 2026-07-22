#!/bin/bash
# test-codebase-memory.sh - Asserts for scripts/codebase-memory.sh.
# Native bash 3.2, no dependencies:  ./scripts/tests/test-codebase-memory.sh
set -u
cd "$(dirname "$0")/../.."

PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); echo "  ok  - $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }
eq()   { if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 (exp='$2' got='$3')"; fi; }
has()  { case "$3" in *"$2"*) ok "$1" ;; *) fail "$1 (missing '$2')" ;; esac; }
no()   { case "$3" in *"$2"*) fail "$1 (contains '$2')" ;; *) ok "$1" ;; esac; }

echo "== existence =="
if [ -x scripts/codebase-memory.sh ]; then ok "codebase-memory.sh executable"; else fail "codebase-memory.sh executable"; fi

TMP=$(mktemp -d); trap 'rm -rf "${TMP}"' EXIT
WS="${TMP}/ws"; mkdir -p "${WS}/scripts" "${WS}/repos/svc-a"
cp scripts/repo-lib.sh scripts/codebase-memory.sh "${WS}/scripts/"
cat > "${WS}/repos.yaml" <<'EOF'
system:
  name: sys-test
  entrypoint: svc-a
repos:
  - name: svc-a
    url: https://example.com/svc-a.git
    provider: local
    deploy_order: 1
EOF
CM="${WS}/scripts/codebase-memory.sh"

echo "== mode resolution =="
eq "auto with no fleet -> direct"  "direct" "$( cd "${WS}" && ./scripts/codebase-memory.sh mode )"
eq "CBM_MODE=off -> off"           "off"    "$( cd "${WS}" && CBM_MODE=off ./scripts/codebase-memory.sh mode )"
eq "CBM_FLEET_SEED set -> fleet"   "fleet"  "$( cd "${WS}" && CBM_FLEET_SEED='true' ./scripts/codebase-memory.sh mode )"

echo "== index: off =="
OUT=$( cd "${WS}" && CBM_MODE=off ./scripts/codebase-memory.sh index svc-a 2>&1 ); RC=$?
eq "off exits 0" "0" "${RC}"
has "off says disabled" "disabled" "${OUT}"
[ -f "${WS}/.mcp.json" ] && fail "off writes no .mcp.json" || ok "off writes no .mcp.json"

echo "== index: direct (no fleet) =="
OUT=$( cd "${WS}" && ./scripts/codebase-memory.sh index svc-a 2>&1 ); RC=$?
eq "direct exits 0" "0" "${RC}"
has "direct guidance" "direct-engine" "${OUT}"
[ -f "${WS}/.mcp.json" ] && fail "direct writes no .mcp.json" || ok "direct writes no .mcp.json"

echo "== index: fleet (mock seed + wire .mcp.json) =="
OUT=$( cd "${WS}" && CBM_FLEET_SEED='echo seeded {repo}' CBM_FLEET_URL='http://127.0.0.1:8787' \
       CBM_FLEET_TOKEN='testtok' ./scripts/codebase-memory.sh index svc-a 2>&1 ); RC=$?
eq "fleet exits 0" "0" "${RC}"
has "fleet ran seed" "seeded repos/svc-a" "${OUT}"
[ -f "${WS}/.mcp.json" ] && ok "fleet wrote .mcp.json" || fail "fleet wrote .mcp.json"
MCP=$(cat "${WS}/.mcp.json" 2>/dev/null)
has "entry cbm-svc-a"        "cbm-svc-a"       "${MCP}"
has "url has /mcp/ + repos"  "/mcp/"           "${MCP}"
has "project id path dashes" "repos-svc-a"     "${MCP}"
has "bearer token wired"     "Bearer testtok"  "${MCP}"
python3 -c "import json,sys; json.load(open('${WS}/.mcp.json'))" 2>/dev/null && ok "mcp.json is valid JSON" || fail "mcp.json is valid JSON"

echo "== index: fleet seed failure is non-blocking =="
rm -f "${WS}/.mcp.json"
OUT=$( cd "${WS}" && CBM_FLEET_SEED='false' CBM_FLEET_URL='http://x' ./scripts/codebase-memory.sh index svc-a 2>&1 ); RC=$?
eq "failed seed still exits 0" "0" "${RC}"
has "failed seed warns" "Indexing pending" "${OUT}"

echo "== mcp-config for all registered repos =="
rm -f "${WS}/.mcp.json"
OUT=$( cd "${WS}" && CBM_FLEET_URL='http://127.0.0.1:8787' CBM_FLEET_TOKEN='t' ./scripts/codebase-memory.sh mcp-config 2>&1 ); RC=$?
eq "mcp-config exits 0" "0" "${RC}"
has "mcp-config wrote entry" "cbm-svc-a" "$(cat "${WS}/.mcp.json" 2>/dev/null)"

echo
echo "== summary: ${PASS} ok, ${FAIL} fail =="
[ "${FAIL}" = "0" ] || exit 1
