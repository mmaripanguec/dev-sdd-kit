#!/bin/bash
# test-repo-tree.sh - Asserts of scripts/repo-tree.sh (derived file-structure
# tree for architecture/context docs). Runs with bash 3.2 + git + python3:
#   ./scripts/tests/test-repo-tree.sh
set -u
cd "$(dirname "$0")/../.."

PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); echo "  ok  - $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }
assert_eq() { # description expected got
  if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 (expected='$2' got='$3')"; fi
}
assert_contains() { # description substring text
  case "$3" in *"$2"*) ok "$1" ;; *) fail "$1 (does not contain '$2')" ;; esac
}
assert_not_contains() { # description substring text
  case "$3" in *"$2"*) fail "$1 (contains '$2')" ;; *) ok "$1" ;; esac
}

echo "== existence =="
if [ -x scripts/repo-tree.sh ]; then ok "scripts/repo-tree.sh exists and is executable"; else fail "scripts/repo-tree.sh exists and is executable"; fi

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

# ---------- fixture: synthetic git repo ----------
R="${TMP}/demo-repo"
mkdir -p "${R}/src/app/pages" "${R}/src/app/services" "${R}/docs" "${R}/node_modules/junk"
echo "x" > "${R}/src/app/pages/a.ts"
echo "x" > "${R}/src/app/pages/b.ts"
echo "x" > "${R}/src/app/services/c.ts"
echo "x" > "${R}/docs/readme.md"
echo "x" > "${R}/root.txt"
echo "x" > "${R}/node_modules/junk/ignored.js"
echo "node_modules/" > "${R}/.gitignore"
git -C "${R}" init -q
git -C "${R}" -c user.email=t@t -c user.name=t add -A
git -C "${R}" -c user.email=t@t -c user.name=t commit -qm fixture

echo "== default output (depth 2) =="
out=$(./scripts/repo-tree.sh "${R}" 2>&1); rc=$?
assert_eq "exits 0 on a git repo" "0" "${rc}"
assert_contains "root line with repo name and total" "demo-repo/" "${out}"
assert_contains "total file count at root (6 tracked)" "6" "${out}"
assert_contains "level-1 dir listed" "src/" "${out}"
assert_contains "level-2 dir listed at depth 2" "app/" "${out}"
assert_contains "per-dir recursive count (src has 3)" "(3)" "${out}"
assert_contains "root file listed" "root.txt" "${out}"
assert_not_contains "gitignored dir excluded" "node_modules" "${out}"
assert_not_contains "level-3 dirs pruned at depth 2" "pages/" "${out}"

echo "== depth argument =="
out1=$(./scripts/repo-tree.sh "${R}" 1 2>&1)
assert_not_contains "depth 1 hides level-2 dirs" "app/" "${out1}"
out3=$(./scripts/repo-tree.sh "${R}" 3 2>&1)
assert_contains "depth 3 shows level-3 dirs" "pages/" "${out3}"
assert_contains "leaf dir count exact (pages has 2)" "(2)" "${out3}"

echo "== determinism =="
again=$(./scripts/repo-tree.sh "${R}" 2>&1)
out=$(./scripts/repo-tree.sh "${R}" 2>&1)
if [ "${again}" = "${out}" ]; then ok "output is deterministic"; else fail "output is deterministic"; fi

echo "== error handling =="
out=$(./scripts/repo-tree.sh "${TMP}/no-such-dir" 2>&1); rc=$?
assert_eq "missing dir fails non-zero" "1" "${rc}"
mkdir -p "${TMP}/not-a-repo"; echo x > "${TMP}/not-a-repo/f.txt"
out=$(./scripts/repo-tree.sh "${TMP}/not-a-repo" 2>&1); rc=$?
assert_eq "non-git dir still works (find fallback, exit 0)" "0" "${rc}"
assert_contains "fallback lists the file" "f.txt" "${out}"

echo ""
echo "== result: ${PASS} ok, ${FAIL} fail =="
[ "${FAIL}" -eq 0 ] || exit 1
