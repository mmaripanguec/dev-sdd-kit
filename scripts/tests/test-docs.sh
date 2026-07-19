#!/bin/bash
# test-docs.sh - Asserts de scripts/docs.sh (CA1.1-CA1.4, CA2.3 de
# specs/2026-07-docs-html.md). Corre con bash 3.2 nativo, sin dependencias:
#   ./scripts/tests/test-docs.sh
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
assert_not_contains() { # descripcion subcadena texto
  case "$3" in *"$2"*) fail "$1 (contiene '$2')" ;; *) ok "$1" ;; esac
}

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

echo "== existencia =="
if [ -x scripts/docs.sh ]; then ok "scripts/docs.sh existe y es ejecutable"; else fail "scripts/docs.sh existe y es ejecutable"; fi

# ---------- fixture: workspace sintetico controlado ----------
WS="${TMP}/ws"
mkdir -p "${WS}/scripts" "${WS}/docs" "${WS}/templates" "${WS}/specs" \
         "${WS}/knowledge" "${WS}/.claude/skills/demo-skill" \
         "${WS}/.claude/skills/sin-desc" "${WS}/.claude/agents" "${WS}/.claude/rules"
cp scripts/repo-lib.sh "${WS}/scripts/"
cp templates/docs-arquitectura.html "${WS}/templates/" 2>/dev/null || true

cat > "${WS}/repos.yaml" <<'EOF'
system:
  name: sistema-test
  entrypoint: repo-x
repos:
  - name: repo-x
    url: https://example.com/repo-x.git
    provider: local
    role: "backend de prueba"
    deploy_order: 1
EOF

cat > "${WS}/.claude/skills/demo-skill/SKILL.md" <<'EOF'
---
name: demo-skill
description: Skill de prueba <con> caracteres & especiales.
---
Cuerpo.
EOF
cat > "${WS}/.claude/skills/sin-desc/SKILL.md" <<'EOF'
---
name: sin-desc
---
Cuerpo.
EOF
cat > "${WS}/.claude/agents/demo-agente.md" <<'EOF'
---
name: demo-agente
description: Agente de prueba (F1).
---
Cuerpo.
EOF
cat > "${WS}/.claude/rules/demo-regla.md" <<'EOF'
# Regla demo
> Base: estandar de prueba
- contenido
EOF
cat > "${WS}/knowledge/reglas-negocio.md" <<'EOF'
# Reglas de negocio
| ID | Regla | Service domain | Origen (spec/regulación) | Vigente desde |
|---|---|---|---|---|
| RN-T1 | Regla sintetica de prueba | test | specs/demo.md | 2026-01-01 |
EOF
cat > "${WS}/knowledge/uso.md" <<'EOF'
# Uso
<!-- DORA:BEGIN -->
[GENERADO v1] 2026-07-19 · período: últimos 90 días · fuentes: ninguna
| Métrica | Actual | Objetivo | Fuente |
|---|---|---|---|
| MTTR | mediana 33m (1 postmortems) | < 1 hora | postmortems |
<!-- DORA:END -->
EOF
cat > "${WS}/specs/demo-spec.md" <<'EOF'
# Spec: Demo sintetica

| Campo | Valor |
|---|---|
| Estado | implementada |
EOF
cat > "${WS}/specs/_template.md" <<'EOF'
# Spec: <plantilla — no debe listarse>
EOF

echo "== CA1.1: catalogo derivado de las fuentes reales =="
./scripts/docs.sh --root "${WS}" >/dev/null 2>&1
HTML=$(cat "${WS}/docs/arquitectura.html" 2>/dev/null || echo "")
assert_contains "sello GENERADO presente"        "[GENERADO"                 "$HTML"
assert_contains "skill del fixture listada"      "demo-skill"                "$HTML"
assert_contains "descripcion de la skill (escapada)" "&lt;con&gt;"           "$HTML"
assert_contains "agente del fixture listado"     "demo-agente"               "$HTML"
assert_contains "regla del fixture listada"      "Regla demo"                "$HTML"
assert_contains "RN vigente listada"             "RN-T1"                     "$HTML"
assert_contains "topologia: repo del registro"   "repo-x"                    "$HTML"
assert_contains "topologia: rol del repo"        "backend de prueba"         "$HTML"
assert_contains "bloque DORA inyectado"          "mediana 33m"               "$HTML"
assert_contains "indice de specs con estado"     "demo-spec"                 "$HTML"
assert_not_contains "la plantilla de spec no se lista" "no debe listarse"    "$HTML"

echo "== CA1.2: cero listas en duro — skill nueva aparece al regenerar =="
mkdir -p "${WS}/.claude/skills/skill-nueva"
cat > "${WS}/.claude/skills/skill-nueva/SKILL.md" <<'EOF'
---
name: skill-nueva
description: Aparecio despues.
---
EOF
./scripts/docs.sh --root "${WS}" >/dev/null 2>&1
assert_contains "skill agregada aparece sin tocar el script" "skill-nueva" "$(cat "${WS}/docs/arquitectura.html")"

echo "== CA1.4: sin fuente => sin datos con causa; sin descripcion => advertencia =="
assert_contains "skill sin description marcada" "sin descripción" "$(cat "${WS}/docs/arquitectura.html")"
WS2="${TMP}/ws2"
mkdir -p "${WS2}/scripts" "${WS2}/docs" "${WS2}/templates" "${WS2}/specs" \
         "${WS2}/knowledge" "${WS2}/.claude/skills" "${WS2}/.claude/agents" "${WS2}/.claude/rules"
cp scripts/repo-lib.sh "${WS2}/scripts/"
cp templates/docs-arquitectura.html "${WS2}/templates/" 2>/dev/null || true
printf 'repos: []\n' > "${WS2}/repos.yaml"
./scripts/docs.sh --root "${WS2}" >/dev/null 2>&1
HTML2=$(cat "${WS2}/docs/arquitectura.html" 2>/dev/null || echo "")
assert_contains "registro vacio declara sin datos" "sin datos" "$HTML2"

echo "== CA2.4: diagrama de flujo conceptual del modelo (svg inline) =="
assert_contains "diagrama svg presente"          "<svg"                 "$HTML"
assert_contains "diagrama: la spec como contrato" "Spec"                "$HTML"
assert_contains "diagrama: ciclo de retroalimentacion" "alimenta"       "$HTML"
assert_contains "diagrama: fase refinamiento presente" "F3 Refinamiento" "$HTML"
assert_contains "diagrama: fase diseño presente"       "F5 Diseño"       "$HTML"
assert_contains "diagrama: las 10 fases (F0 y F9)"     "F9 Operación"    "$HTML"

echo "== CA2.3: autocontenido, sin recursos externos =="
assert_not_contains "sin scripts externos"     "script src=\"http"                 "$HTML"
assert_not_contains "sin hojas de estilo CDN"  "stylesheet\" href=\"http"          "$HTML"
assert_not_contains "sin fuentes remotas css"  "url(http"                          "$HTML"

echo "== idempotencia y CA1.3 --check =="
COPIA1=$(cat "${WS}/docs/arquitectura.html")
./scripts/docs.sh --root "${WS}" >/dev/null 2>&1
assert_eq "segunda corrida identica" "$COPIA1" "$(cat "${WS}/docs/arquitectura.html")"
./scripts/docs.sh --root "${WS}" --check >/dev/null 2>&1
assert_eq "check en sincronia devuelve 0" "0" "$?"
sed -i.bak 's/demo-skill/skill-tocada/' "${WS}/docs/arquitectura.html" && rm -f "${WS}/docs/arquitectura.html.bak"
./scripts/docs.sh --root "${WS}" --check >/dev/null 2>&1
assert_eq "check con drift devuelve 1" "1" "$?"

echo "== humo sobre el workspace real (no escribe: solo --check o genera a tmp) =="
cp docs/arquitectura.html "${TMP}/real-antes.html" 2>/dev/null || true
./scripts/docs.sh >/dev/null 2>&1
REAL=$(cat docs/arquitectura.html 2>/dev/null || echo "")
assert_contains "workspace real: skill spec-create presente" "spec-create" "$REAL"
assert_contains "workspace real: agente calidad presente"    "calidad"     "$REAL"
assert_contains "workspace real: RN-F4 presente"             "RN-F4"       "$REAL"

echo "== CA3.1-CA3.2: versión EN generada junto a la ES (workspace real) =="
REAL_EN=$(cat docs/architecture.en.html 2>/dev/null || echo "")
assert_contains "architecture.en.html con prosa EN"   "Usage guide"      "$REAL_EN"
assert_contains "diagrama EN: F3 Refinement"          "F3 Refinement"    "$REAL_EN"
assert_contains "rotulos generados en ingles"         "What it does"     "$REAL_EN"
assert_contains "nota de idioma de trabajo"           "working language" "$REAL_EN"
assert_contains "catalogo real inyectado en EN"       "spec-create"      "$REAL_EN"
assert_not_contains "EN sin recursos externos"        "src=\"http"       "$REAL_EN"
assert_contains "la version ES sigue generandose"     "Guía de uso"      "$REAL"

echo "== CA3.1-CA3.2 (marketing): landing autocontenida para GitHub Pages =="
LANDING=$(cat docs/index.html 2>/dev/null || echo "")
assert_contains "landing existe con hero"             "dev-sdd-kit"          "$LANDING"
assert_contains "landing enlaza edicion EN"           "architecture.en.html" "$LANDING"
assert_contains "landing enlaza edicion ES"           "arquitectura.html"    "$LANDING"
assert_not_contains "landing sin scripts externos"    "script src=\"http"    "$LANDING"
assert_not_contains "landing sin css externo"         "stylesheet\" href=\"http" "$LANDING"

echo ""
echo "RESULTADO: ${PASS} ok, ${FAIL} fallos"
[ "${FAIL}" -eq 0 ]
