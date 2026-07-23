#!/bin/bash
# test-architecture.sh - Asserts for scripts/generate-architecture.sh.
# Runs on native bash 3.2, no dependencies:
#   ./scripts/tests/test-architecture.sh
set -u
cd "$(dirname "$0")/../.."

PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); echo "  ok  - $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }
assert_contains()     { case "$3" in *"$2"*) ok "$1" ;; *) fail "$1 (missing '$2')" ;; esac; }
assert_not_contains() { case "$3" in *"$2"*) fail "$1 (contains '$2')" ;; *) ok "$1" ;; esac; }

echo "== existence =="
if [ -x scripts/generate-architecture.sh ]; then ok "generate-architecture.sh is executable"; else fail "generate-architecture.sh is executable"; fi
[ -f templates/knowledge-architecture.md ]        && ok "template .md present"        || fail "template .md present"
[ -f templates/knowledge-architecture.html ]      && ok "template .html present"      || fail "template .html present"
[ -f templates/knowledge-architecture.narrative.md ] && ok "narrative template present" || fail "narrative template present"

TMP=$(mktemp -d); trap 'rm -rf "${TMP}"' EXIT
WS="${TMP}/ws"
mkdir -p "${WS}/scripts" "${WS}/templates" "${WS}/knowledge" "${WS}/repos/svc-a"
cp scripts/repo-lib.sh scripts/generate-architecture.sh "${WS}/scripts/"
cp templates/knowledge-architecture.md templates/knowledge-architecture.html \
   templates/knowledge-architecture.narrative.md "${WS}/templates/"

cat > "${WS}/repos.yaml" <<'EOF'
system:
  name: sys-test
  entrypoint: svc-a
  pack_prefix: st
repos:
  - name: svc-a
    url: https://example.com/svc-a.git
    provider: local
    role: "test backend service"
    deploy_order: 1
    domain: generic
EOF

cat > "${WS}/repos/svc-a/go.mod" <<'EOF'
module example.com/svc-a

go 1.21

require github.com/gorilla/mux v1.8.0
EOF

echo "== generation =="
( cd "${WS}" && ./scripts/generate-architecture.sh ) > "${TMP}/out.log" 2>&1
RC=$?
[ "${RC}" = "0" ] && ok "generator exits 0" || fail "generator exits 0 (log: $(cat "${TMP}/out.log"))"
[ -f "${WS}/knowledge/architecture/sys-test.md" ]   && ok ".md written"  || fail ".md written"
[ -f "${WS}/knowledge/architecture/sys-test.html" ] && ok ".html written" || fail ".html written"

MD=$(cat "${WS}/knowledge/architecture/sys-test.md" 2>/dev/null)
HTML=$(cat "${WS}/knowledge/architecture/sys-test.html" 2>/dev/null)

echo "== content (arc42 + C4 + derived) =="
assert_contains "arc42 mentioned"                 "arc42"                       "${MD}"
assert_contains "C4 mentioned"                     "C4"                          "${MD}"
assert_contains "section 1 heading"                "## 1. Introduction and goals" "${MD}"
assert_contains "derived repos table header"       "| Repo | Role | Stack"       "${MD}"
assert_contains "derived stack (Go)"               "Go 1.21"                     "${MD}"
assert_contains "derived dependency from go.mod"   "github.com/gorilla/mux"      "${MD}"
assert_contains "seal frontmatter present"         "generado_desde"             "${MD}"
assert_contains "docs-first policy present"        "Do NOT re-index"            "${MD}"
assert_contains "42010 viewpoints metadata"        "viewpoints:"                "${MD}"
assert_contains "Zachman W5H coverage metadata"    "zachman_coverage:"          "${MD}"
assert_contains "Information view section"          "Information view"           "${MD}"
assert_contains "Integration & APIs view section"  "Integration & APIs view"    "${MD}"
assert_contains "Operational view section"         "Operational view"           "${MD}"
assert_contains "Traceability matrix annex"        "Traceability matrix"        "${MD}"

echo "== no unresolved tokens/markers =="
assert_not_contains "no unresolved {{ tokens"       "{{"                          "${MD}"
assert_not_contains "no NARRATIVE markers left"     "NARRATIVE:"                  "${MD}"

echo "== html output =="
assert_contains "html has h1"                       "<h1>"                        "${HTML}"
assert_contains "html carries system name"          "sys-test"                    "${HTML}"
assert_not_contains "no unresolved html tokens"     "{{CONTENT}}"                 "${HTML}"

echo
echo "== summary: ${PASS} ok, ${FAIL} fail =="
[ "${FAIL}" = "0" ] || exit 1
