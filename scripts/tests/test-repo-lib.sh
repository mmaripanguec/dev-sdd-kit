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

echo "== registro valido (fixture de 2 repos) =="
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
assert_eq "orden de despliegue: back primero" "repo-back" \
  "$(registry_repos_by_deploy | head -1)"
unset REGISTRY_FILE

echo "== registro real del workspace (repos.yaml) valida =="
assert_eq "repos.yaml del workspace valida" "0" \
  "$(bash -c '. scripts/repo-lib.sh; registry_validate' >/dev/null 2>&1; echo $?)"

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

echo "== campos nuevos: pack_prefix, vcs, pack =="
R2="${TMP}/packs.yaml"
REGISTRY_FILE="${R2}" bash -c '. scripts/repo-lib.sh; registry_upsert name=mi-app url=/tmp/mi-app provider=local vcs=none pack=xx-app system_name=demo pack_prefix=xx' >/dev/null
assert_eq "pack_prefix persiste" "xx" "$(REGISTRY_FILE=${R2} bash -c '. scripts/repo-lib.sh; registry_system pack_prefix')"
assert_eq "vcs persiste" "none" "$(REGISTRY_FILE=${R2} bash -c '. scripts/repo-lib.sh; registry_get mi-app vcs')"
assert_eq "pack explicito" "xx-app" "$(REGISTRY_FILE=${R2} bash -c '. scripts/repo-lib.sh; pack_name_for_repo mi-app')"
REGISTRY_FILE="${R2}" bash -c '. scripts/repo-lib.sh; registry_upsert name=otra url=/tmp/otra provider=local' >/dev/null
assert_eq "pack derivado prefijo-repo" "xx-otra" "$(REGISTRY_FILE=${R2} bash -c '. scripts/repo-lib.sh; pack_name_for_repo otra')"
OUT=$(REGISTRY_FILE="${R2}" bash -c '. scripts/repo-lib.sh; registry_upsert name=mala url=/tmp/x provider=local vcs=svn >/dev/null; registry_validate' 2>&1)
assert_contains "vcs invalido detectado" "no soportado (git|none)" "${OUT}"

echo "== sello de snapshot =="
mkdir -p "${TMP}/snap/sub" && echo hola > "${TMP}/snap/a.txt" && echo mundo > "${TMP}/snap/sub/b.txt"
H1=$(bash -c '. scripts/repo-lib.sh; huella_snapshot '"${TMP}/snap")
H2=$(bash -c '. scripts/repo-lib.sh; huella_snapshot '"${TMP}/snap")
assert_eq "huella estable" "${H1}" "${H2}"
assert_eq "huella de 12 chars" "12" "${#H1}"
echo cambio >> "${TMP}/snap/a.txt"
H3=$(bash -c '. scripts/repo-lib.sh; huella_snapshot '"${TMP}/snap")
if [ "${H1}" != "${H3}" ]; then ok "huella cambia al cambiar archivos"; else fail "huella cambia al cambiar archivos"; fi

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
