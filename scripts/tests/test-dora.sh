#!/bin/bash
# test-dora.sh - Asserts de scripts/dora.sh (CA1.1-CA1.4, CA2.1 de
# specs/2026-07-metricas-dora.md). Corre con bash 3.2 nativo, sin
# dependencias nuevas:
#   ./scripts/tests/test-dora.sh
set -u
cd "$(dirname "$0")/../.."
WORKSPACE=$(pwd)

PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); echo "  ok  - $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }
assert_eq() { # descripcion esperado obtenido
  if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 (esperado='$2' obtenido='$3')"; fi
}
assert_contains() { # descripcion subcadena texto
  case "$3" in *"$2"*) ok "$1" ;; *) fail "$1 (no contiene '$2')" ;; esac
}
assert_not_contains() { # descripcion subcadena texto
  case "$3" in *"$2"*) fail "$1 (contiene '$2')" ;; *) ok "$1" ;; esac
}

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

# Fecha ISO hace N dias (via python3, mismo precedente que repo-lib.sh)
days_ago() { python3 -c "from datetime import datetime,timedelta;print((datetime.now()-timedelta(days=$1)).strftime('%Y-%m-%dT12:00:00'))"; }
date_ago() { python3 -c "from datetime import datetime,timedelta;print((datetime.now()-timedelta(days=$1)).strftime('%Y-%m-%d'))"; }

# Commit con fecha controlada en el repo del cwd
commit_at() { # dias-atras mensaje
  local d; d=$(days_ago "$1")
  echo "$1-$2" >> archivo.txt
  git add archivo.txt
  GIT_AUTHOR_DATE="$d" GIT_COMMITTER_DATE="$d" git commit -qm "$2"
}

# ---------- fixture: workspace sintetico con 1 repo clonado ----------
WS="${TMP}/ws"
mkdir -p "${WS}/repos" "${WS}/knowledge/incidents" "${WS}/scripts"
cp scripts/repo-lib.sh "${WS}/scripts/"
cat > "${WS}/repos.yaml" <<'EOF'
system:
  name: sistema-test
  entrypoint: repo-a
repos:
  - name: repo-a
    url: https://example.com/repo-a.git
    provider: local
    role: "backend"
    deploy_order: 1
  - name: repo-b
    url: https://example.com/repo-b.git
    provider: local
    role: "frontend"
    deploy_order: 2
EOF

cat > "${WS}/knowledge/usage.md" <<'EOF'
# Uso y desempeño de la fábrica

## Métricas DORA (por trimestre)
<!-- DORA:BEGIN -->
(pendiente de generación)
<!-- DORA:END -->

## Estimado vs. real (alimenta a F2)
| Spec | Puntos estimados | Resultado | Aprendizaje |
|---|---|---|---|
| specs/demo.md | 5 | 8 reales | subestimamos integración |
EOF

# repo-a: 2 merges a main dentro del período (hace 10 y 5 días),
# cada rama con su primer commit 2 días antes del merge (lead time 2d)
(
  cd "${WS}/repos" && git init -q repo-a && cd repo-a
  git checkout -qb main
  commit_at 30 base
  git checkout -qb f1
  commit_at 12 f1-trabajo
  git checkout -q main
  d=$(days_ago 10); GIT_AUTHOR_DATE="$d" GIT_COMMITTER_DATE="$d" git merge -q --no-ff f1 -m "merge f1"
  git checkout -qb f2
  commit_at 7 f2-trabajo
  git checkout -q main
  d=$(days_ago 5); GIT_AUTHOR_DATE="$d" GIT_COMMITTER_DATE="$d" git merge -q --no-ff f2 -m "merge f2"
) >/dev/null 2>&1
# repo-b: registrado pero NO clonado (frecuencia parcial, se declara)

# 1 postmortem en el período con MTTR
cat > "${WS}/knowledge/incidents/INC-0001.md" <<EOF
# Postmortem: caída demo (INC-0001)
- **Fecha / Duración / Severidad:** $(date_ago 4) / 45m / SEV2
- **MTTR:** 45m
EOF

echo "== CA1.3: sin script aun no hay nada que probar — existencia =="
if [ -x scripts/dora.sh ]; then ok "scripts/dora.sh existe y es ejecutable"; else fail "scripts/dora.sh existe y es ejecutable"; fi

echo "== CA1.1/CA1.2: metricas derivadas de git y postmortems =="
./scripts/dora.sh --root "${WS}" >/dev/null 2>&1
GEN=$(sed -n '/<!-- DORA:BEGIN -->/,/<!-- DORA:END -->/p' "${WS}/knowledge/usage.md")
assert_contains "sello GENERATED presente (lang en)"  "[GENERATED"       "$GEN"
assert_contains "frecuencia: 2 deployments (repo-a)" "2 deployments"    "$GEN"
assert_contains "lead time mediano 2d"               "median 2d"        "$GEN"
assert_contains "CFR 50% (1 incidente / 2 deploys)"  "50%"              "$GEN"
assert_contains "MTTR mediano 45m"                   "median 45m"       "$GEN"
assert_contains "repo-b sin clonar declarado"        "repo-b"           "$GEN"

echo "== CA1.4: secciones manuales intactas =="
MANUAL_ANTES="| specs/demo.md | 5 | 8 reales | subestimamos integración |"
assert_contains "tabla manual estimado-vs-real intacta" "$MANUAL_ANTES" "$(cat "${WS}/knowledge/usage.md")"
FUERA=$(sed '/<!-- DORA:BEGIN -->/,/<!-- DORA:END -->/d' "${WS}/knowledge/usage.md")
assert_contains "titulo manual intacto fuera del bloque" "## Estimado vs. real" "$FUERA"

echo "== idempotencia: segunda corrida identica =="
COPIA1=$(cat "${WS}/knowledge/usage.md")
./scripts/dora.sh --root "${WS}" >/dev/null 2>&1
assert_eq "recorrer sin cambios no altera usage.md" "$COPIA1" "$(cat "${WS}/knowledge/usage.md")"

echo "== --check: limpio=0, drift=1 =="
./scripts/dora.sh --root "${WS}" --check >/dev/null 2>&1
assert_eq "check en sincronia devuelve 0" "0" "$?"
sed -i.bak 's/45m/99m/' "${WS}/knowledge/usage.md" && rm -f "${WS}/knowledge/usage.md.bak"
./scripts/dora.sh --root "${WS}" --check >/dev/null 2>&1
assert_eq "check con drift devuelve 1" "1" "$?"
./scripts/dora.sh --root "${WS}" >/dev/null 2>&1   # restaurar

echo "== CA2.1: nuevo postmortem actualiza CFR y MTTR =="
cat > "${WS}/knowledge/incidents/INC-0002.md" <<EOF
# Postmortem: degradación demo (INC-0002)
- **Fecha / Duración / Severidad:** $(date_ago 2) / 95m / SEV3
- **MTTR:** 95m
EOF
./scripts/dora.sh --root "${WS}" >/dev/null 2>&1
GEN2=$(sed -n '/<!-- DORA:BEGIN -->/,/<!-- DORA:END -->/p' "${WS}/knowledge/usage.md")
assert_contains "CFR sube a 100% (2 incidentes / 2 deploys)" "100%" "$GEN2"
assert_contains "MTTR mediano recalculado (70m)"             "median 70m"  "$GEN2"

echo "== CA1.3: workspace sin repos clonados declara sin datos =="
WS2="${TMP}/ws2"
mkdir -p "${WS2}/repos" "${WS2}/knowledge/incidents" "${WS2}/scripts"
cp scripts/repo-lib.sh "${WS2}/scripts/"
cp "${WS}/repos.yaml" "${WS2}/repos.yaml"
sed -n '1,7p' "${WS}/knowledge/usage.md" > /dev/null # noop
cat > "${WS2}/knowledge/usage.md" <<'EOF'
# Uso
<!-- DORA:BEGIN -->
<!-- DORA:END -->
EOF
./scripts/dora.sh --root "${WS2}" >/dev/null 2>&1
GEN3=$(sed -n '/<!-- DORA:BEGIN -->/,/<!-- DORA:END -->/p' "${WS2}/knowledge/usage.md")
assert_contains "declara no data"              "no data"    "$GEN3"
assert_contains "explica la causa (not cloned)" "cloned"    "$GEN3"
assert_not_contains "no inventa un MTTR"        "MTTR: 45"  "$GEN3"

echo ""
echo "RESULTADO: ${PASS} ok, ${FAIL} fallos"
[ "${FAIL}" -eq 0 ]
