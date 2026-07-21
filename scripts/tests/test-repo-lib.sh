#!/bin/bash
# test-repo-lib.sh - Asserts for scripts/repo-lib.sh (CA2.1, CA2.4, partial CA1.2).
# Runs with macOS's native bash 3.2, no new dependencies:
#   ./scripts/tests/test-repo-lib.sh
set -u
cd "$(dirname "$0")/../.."

PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); echo "  ok  - $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }
assert_eq() { # description expected actual
  if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 (expected='$2' actual='$3')"; fi
}
assert_contains() { # description substring text
  case "$3" in *"$2"*) ok "$1" ;; *) fail "$1 (does not contain '$2')" ;; esac
}

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

echo "== valid registry (2-repo fixture) =="
cat > "${TMP}/valido.yaml" <<'EOF'
system:
  name: sistema-demo
  entrypoint: repo-front
repos:
  - name: repo-back
    url: https://bitbucket.org/mi-ws/repo-back.git
    provider: bitbucket
    role: "servicios de negocio"
    deploy_order: 1
  - name: repo-front
    url: https://github.com/mi-org/repo-front.git
    provider: github
    role: "frontend"
    deploy_order: 2
    domain: banking
EOF
export REGISTRY_FILE="${TMP}/valido.yaml"
. scripts/repo-lib.sh
assert_eq "validate OK" "0" "$(registry_validate >/dev/null; echo $?)"
assert_eq "system.name" "sistema-demo" "$(registry_system name)"
assert_eq "entrypoint" "repo-front" "$(registry_system entrypoint)"
assert_eq "2 repos" "2" "$(registry_repos | wc -l | tr -d ' ')"
assert_eq "get provider" "github" "$(registry_get repo-front provider)"
assert_eq "get domain" "banking" "$(registry_get repo-front domain)"
assert_eq "deploy order: back first" "repo-back" \
  "$(registry_repos_by_deploy | head -1)"
unset REGISTRY_FILE

echo "== real workspace registry (repos.yaml) validates =="
if [ -f repos.yaml ]; then
  assert_eq "workspace repos.yaml validates" "0" \
    "$(bash -c '. scripts/repo-lib.sh; registry_validate' >/dev/null 2>&1; echo $?)"
else
  ok "workspace repos.yaml validates (absent: template state, created by init-system.sh)"
fi

echo "== missing registry (CA2.4: actionable error) =="
OUT=$(REGISTRY_FILE="${TMP}/no-existe.yaml" bash -c '. scripts/repo-lib.sh; registry_validate' 2>&1)
assert_eq "exit != 0" "1" "$(REGISTRY_FILE=${TMP}/no-existe.yaml bash -c '. scripts/repo-lib.sh; registry_validate' >/dev/null 2>&1; echo $?)"
assert_contains "mentions repo-add" "repo-add" "${OUT}"

echo "== corrupt registry: missing required field and invalid provider =="
cat > "${TMP}/malo.yaml" <<'EOF'
system:
  name: sistema-x
repos:
  - name: repo-sin-url
    provider: cvs
EOF
OUT=$(REGISTRY_FILE="${TMP}/malo.yaml" bash -c '. scripts/repo-lib.sh; registry_validate' 2>&1)
assert_contains "reports missing url" "missing required field 'url'" "${OUT}"
assert_contains "reports unsupported provider" "not supported" "${OUT}"

echo "== upsert: create registry from scratch =="
R="${TMP}/nuevo.yaml"
OUT=$(REGISTRY_FILE="${R}" bash -c '. scripts/repo-lib.sh; registry_upsert name=mi-app url=/tmp/mi-app provider=local role="app de prueba"')
assert_eq "addition reported" "added" "${OUT}"
assert_eq "system.name derived" "mi-app" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_system name')"
assert_eq "first repo = entrypoint" "mi-app" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_system entrypoint')"
assert_eq "new registry validates" "0" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_validate' >/dev/null 2>&1; echo $?)"

echo "== upsert: idempotence (CA1.2) and auto-incremented deploy_order =="
OUT=$(REGISTRY_FILE="${R}" bash -c '. scripts/repo-lib.sh; registry_upsert name=mi-app url=/tmp/mi-app provider=local role="rol nuevo"')
assert_eq "re-adding updates, does not duplicate" "updated" "${OUT}"
assert_eq "still exactly 1 repo" "1" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_repos' | wc -l | tr -d ' ')"
assert_eq "role updated" "rol nuevo" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_get mi-app role')"
REGISTRY_FILE="${R}" bash -c '. scripts/repo-lib.sh; registry_upsert name=mi-api url=/tmp/mi-api provider=local' >/dev/null
assert_eq "deploy_order auto-increments" "2" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_get mi-api deploy_order')"
assert_eq "entrypoint unchanged when adding" "mi-app" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_system entrypoint')"

echo "== new fields: pack_prefix, vcs, pack =="
R2="${TMP}/packs.yaml"
REGISTRY_FILE="${R2}" bash -c '. scripts/repo-lib.sh; registry_upsert name=mi-app url=/tmp/mi-app provider=local vcs=none pack=xx-app system_name=demo pack_prefix=xx' >/dev/null
assert_eq "pack_prefix persists" "xx" "$(REGISTRY_FILE=${R2} bash -c '. scripts/repo-lib.sh; registry_system pack_prefix')"
assert_eq "vcs persists" "none" "$(REGISTRY_FILE=${R2} bash -c '. scripts/repo-lib.sh; registry_get mi-app vcs')"
assert_eq "explicit pack" "xx-app" "$(REGISTRY_FILE=${R2} bash -c '. scripts/repo-lib.sh; pack_name_for_repo mi-app')"
REGISTRY_FILE="${R2}" bash -c '. scripts/repo-lib.sh; registry_upsert name=otra url=/tmp/otra provider=local' >/dev/null
assert_eq "pack derived prefix-repo" "xx-otra" "$(REGISTRY_FILE=${R2} bash -c '. scripts/repo-lib.sh; pack_name_for_repo otra')"
OUT=$(REGISTRY_FILE="${R2}" bash -c '. scripts/repo-lib.sh; registry_upsert name=mala url=/tmp/x provider=local vcs=svn >/dev/null; registry_validate' 2>&1)
assert_contains "invalid vcs detected" "not supported (git|none)" "${OUT}"

echo "== snapshot stamp =="
mkdir -p "${TMP}/snap/sub" && echo hola > "${TMP}/snap/a.txt" && echo mundo > "${TMP}/snap/sub/b.txt"
H1=$(bash -c '. scripts/repo-lib.sh; huella_snapshot '"${TMP}/snap")
H2=$(bash -c '. scripts/repo-lib.sh; huella_snapshot '"${TMP}/snap")
assert_eq "stable fingerprint" "${H1}" "${H2}"
assert_eq "12-char fingerprint" "12" "${#H1}"
echo cambio >> "${TMP}/snap/a.txt"
H3=$(bash -c '. scripts/repo-lib.sh; huella_snapshot '"${TMP}/snap")
if [ "${H1}" != "${H3}" ]; then ok "fingerprint changes when files change"; else fail "fingerprint changes when files change"; fi

echo "== provider helpers =="
assert_eq "github by host" "github" "$(provider_for_url https://github.com/org/x.git)"
assert_eq "bitbucket by host" "bitbucket" "$(provider_for_url git@bitbucket.org:ws/x.git)"
assert_eq "gitlab by host" "gitlab" "$(provider_for_url https://gitlab.miempresa.com/g/x.git)"
assert_eq "local path" "local" "$(provider_for_url /Users/yo/proyectos/x)"
assert_eq "host of https" "github.com" "$(host_of_url https://github.com/org/x.git)"
assert_eq "host of ssh" "bitbucket.org" "$(host_of_url git@bitbucket.org:ws/x.git)"
assert_eq "default github git user" "x-access-token" "$(git_user_for github)"
assert_eq "default gitlab git user" "oauth2" "$(git_user_for gitlab)"


echo "== regression: upsert over skeleton registry (empty repos:) =="
R3="${TMP}/esqueleto.yaml"
printf 'system:\n  name: nuevo\n  pack_prefix: nv\nrepos:\n' > "${R3}"
OUT=$(REGISTRY_FILE="${R3}" bash -c '. scripts/repo-lib.sh; registry_upsert name=uno url=/tmp/uno provider=local')
assert_eq "addition over skeleton" "added" "${OUT}"
assert_eq "keeps pack_prefix" "nv" "$(REGISTRY_FILE=${R3} bash -c '. scripts/repo-lib.sh; registry_system pack_prefix')"
assert_eq "keeps system name" "nuevo" "$(REGISTRY_FILE=${R3} bash -c '. scripts/repo-lib.sh; registry_system name')"
echo
echo "Result: ${PASS} ok, ${FAIL} failures"
[ "${FAIL}" -eq 0 ]
