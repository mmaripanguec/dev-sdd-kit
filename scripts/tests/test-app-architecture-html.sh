#!/bin/bash
# test-app-architecture-html.sh - Asserts of scripts/app-architecture-html.py
# (application architecture HTML twin, corporate template). Runs with native
# bash 3.2 + python3, no dependencies:
#   ./scripts/tests/test-app-architecture-html.sh
set -u
cd "$(dirname "$0")/../.."

PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); echo "  ok  - $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }
assert_contains() { # description substring text
  case "$3" in *"$2"*) ok "$1" ;; *) fail "$1 (does not contain '$2')" ;; esac
}
assert_not_contains() { # description substring text
  case "$3" in *"$2"*) fail "$1 (contains '$2')" ;; *) ok "$1" ;; esac
}

echo "== existence =="
if [ -f scripts/app-architecture-html.py ]; then ok "scripts/app-architecture-html.py exists"; else fail "scripts/app-architecture-html.py exists"; fi
if [ -f templates/knowledge-architecture-app.html ]; then ok "templates/knowledge-architecture-app.html exists"; else fail "templates/knowledge-architecture-app.html exists"; fi

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

# ---------- fixture: synthetic workspace with a minimal app report ----------
WS="${TMP}/ws"
mkdir -p "${WS}/scripts" "${WS}/templates" "${WS}/knowledge/architecture"
cp scripts/app-architecture-html.py "${WS}/scripts/" 2>/dev/null
cp scripts/generate-architecture.sh "${WS}/scripts/" 2>/dev/null
cp templates/knowledge-architecture-app.html "${WS}/templates/" 2>/dev/null

cat > "${WS}/knowledge/architecture/demo-app.md" <<'EOF'
---
name: architecture-demo-app
standard: "arc42 + C4 + ISO/IEC/IEEE 42010"
generado_desde:
  demo-app: abc1234
verificado: 2026-01-01 (committee reviewed)
---

# AS-IS architecture — application **demo-app**

> **Standard:** arc42 · C4. Seal: `demo-app @abc1234`.

## 1. Introduction

The demo application under documentation.

## 6. Runtime view

```mermaid
flowchart LR
  A[client] --> B[service]
```

| Hop | Verifies |
|---|---|
| 1 | session guard |
EOF

echo "== generation =="
out=$(cd "${WS}" && python3 scripts/app-architecture-html.py demo-app 2>&1); rc=$?
if [ "${rc}" = "0" ]; then ok "generator exits 0"; else fail "generator exits 0 (rc=${rc}: ${out})"; fi
HTML="${WS}/knowledge/architecture/demo-app.html"
if [ -f "${HTML}" ]; then ok "html twin written next to the md"; else fail "html twin written next to the md"; fi
html=$(cat "${HTML}" 2>/dev/null)

echo "== structure (corporate template) =="
assert_contains "header with app title" "demo-app" "${html}"
assert_contains "provenance box present" 'class="provenance"' "${html}"
assert_contains "seal rendered in provenance" "abc1234" "${html}"
assert_contains "verification date rendered" "2026-01-01" "${html}"
assert_contains "mermaid block preserved for render" 'class="mermaid"' "${html}"
assert_contains "markdown table converted" "<table>" "${html}"
assert_contains "dark theme variables present" "prefers-color-scheme: dark" "${html}"
assert_not_contains "no unresolved placeholders" "{{" "${html}"
assert_not_contains "md h1 not duplicated in body" "<h1>AS-IS architecture" "${html}"

echo "== error handling =="
out=$(cd "${WS}" && python3 scripts/app-architecture-html.py missing-app 2>&1); rc=$?
if [ "${rc}" != "0" ]; then ok "missing report fails non-zero"; else fail "missing report fails non-zero"; fi

echo ""
echo "== result: ${PASS} ok, ${FAIL} fail =="
[ "${FAIL}" -eq 0 ] || exit 1
