#!/bin/bash
# test-repo-lib.sh - Asserts de scripts/repo-lib.sh (CA2.1, CA2.4, CA1.2 parcial).
# Corre con el bash 3.2 nativo de macOS, sin dependencias nuevas:
#   ./scripts/tests/test-repo-lib.sh
set -u
cd "$(dirname "$0")/../.."

PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); echo "  ok  - $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }
assert_eq() { # descripcion esperado obtenido
  if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 (esperado='$2' obtenido='$3')"; fi
}
assert_contains() { # descripcion subcadena texto
  case "$3" in *"$2"*) ok "$1" ;; *) fail "$1 (no contiene '$2')" ;; esac
}

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

echo "== registro valido (repos.yaml del workspace) =="
. scripts/repo-lib.sh
assert_eq "validate OK" "0" "$(registry_validate >/dev/null; echo $?)"
assert_eq "system.name" "homebanking" "$(registry_system name)"
assert_eq "entrypoint" "homebanking-pwa" "$(registry_system entrypoint)"
assert_eq "3 repos" "3" "$(registry_repos | wc -l | tr -d ' ')"
assert_eq "get provider" "bitbucket" "$(registry_get homebanking-pwa provider)"
assert_eq "orden de despliegue: backend primero" "homebanking-pwa-backend" \
  "$(registry_repos_by_deploy | head -1)"

echo "== registro ausente (CA2.4: error accionable) =="
OUT=$(REGISTRY_FILE="${TMP}/no-existe.yaml" bash -c '. scripts/repo-lib.sh; registry_validate' 2>&1)
assert_eq "exit != 0" "1" "$(REGISTRY_FILE=${TMP}/no-existe.yaml bash -c '. scripts/repo-lib.sh; registry_validate' >/dev/null 2>&1; echo $?)"
assert_contains "menciona repo-add" "repo-add" "${OUT}"

echo "== registro corrupto: campo obligatorio ausente y provider invalido =="
cat > "${TMP}/malo.yaml" <<'EOF'
system:
  name: sistema-x
repos:
  - name: repo-sin-url
    provider: cvs
EOF
OUT=$(REGISTRY_FILE="${TMP}/malo.yaml" bash -c '. scripts/repo-lib.sh; registry_validate' 2>&1)
assert_contains "reporta url faltante" "falta el campo obligatorio 'url'" "${OUT}"
assert_contains "reporta provider no soportado" "no soportado" "${OUT}"

echo "== upsert: crear registro desde cero =="
R="${TMP}/nuevo.yaml"
OUT=$(REGISTRY_FILE="${R}" bash -c '. scripts/repo-lib.sh; registry_upsert name=mi-app url=/tmp/mi-app provider=local role="app de prueba"')
assert_eq "alta reportada" "added" "${OUT}"
assert_eq "system.name derivado" "mi-app" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_system name')"
assert_eq "primer repo = entrypoint" "mi-app" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_system entrypoint')"
assert_eq "registro nuevo valida" "0" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_validate' >/dev/null 2>&1; echo $?)"

echo "== upsert: idempotencia (CA1.2) y deploy_order autoincremental =="
OUT=$(REGISTRY_FILE="${R}" bash -c '. scripts/repo-lib.sh; registry_upsert name=mi-app url=/tmp/mi-app provider=local role="rol nuevo"')
assert_eq "re-alta actualiza, no duplica" "updated" "${OUT}"
assert_eq "sigue habiendo 1 repo" "1" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_repos' | wc -l | tr -d ' ')"
assert_eq "role actualizado" "rol nuevo" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_get mi-app role')"
REGISTRY_FILE="${R}" bash -c '. scripts/repo-lib.sh; registry_upsert name=mi-api url=/tmp/mi-api provider=local' >/dev/null
assert_eq "deploy_order autoincrementa" "2" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_get mi-api deploy_order')"
assert_eq "entrypoint no cambia al agregar" "mi-app" "$(REGISTRY_FILE=${R} bash -c '. scripts/repo-lib.sh; registry_system entrypoint')"

echo "== helpers de proveedor =="
assert_eq "github por host" "github" "$(provider_for_url https://github.com/org/x.git)"
assert_eq "bitbucket por host" "bitbucket" "$(provider_for_url git@bitbucket.org:ws/x.git)"
assert_eq "gitlab por host" "gitlab" "$(provider_for_url https://gitlab.miempresa.com/g/x.git)"
assert_eq "ruta local" "local" "$(provider_for_url /Users/yo/proyectos/x)"
assert_eq "host de https" "github.com" "$(host_of_url https://github.com/org/x.git)"
assert_eq "host de ssh" "bitbucket.org" "$(host_of_url git@bitbucket.org:ws/x.git)"
assert_eq "usuario git github default" "x-access-token" "$(git_user_for github)"
assert_eq "usuario git gitlab default" "oauth2" "$(git_user_for gitlab)"

echo
echo "Resultado: ${PASS} ok, ${FAIL} fallos"
[ "${FAIL}" -eq 0 ]
