#!/usr/bin/env bash
# init-sistema.sh - Convierte un CLON de la plantilla de la fabrica en la
# instancia limpia de un sistema nuevo. Es el "paso -1" del instructivo:
#
#   git clone <plantilla> mi-sistema-workspace && cd mi-sistema-workspace
#   git remote rename origin upstream        # la plantilla queda para updates
#   ./scripts/init-sistema.sh mi-sistema --pack-prefix ms
#   ./scripts/repo-add.sh <url-del-primer-repo> --entrypoint
#
# Limpia los datos de INSTANCIA que la plantilla trae de ejemplo (registro,
# specs, as-is generado, packs) y deja intacto el PRODUCTO (scripts, skills
# genericas, reglas, agentes, plantillas, docs).
#
# Uso:
#   ./scripts/init-system.sh <system-name> [--pack-prefix <px>] [--lang en|es] [--force]
#     --pack-prefix  prefijo corto de los packs de contexto (default: el nombre)
#     --lang         working language for specs and interactions (en|es).
#                    Sin flag y con terminal interactiva, se pregunta;
#                    default no interactivo: en. Commands are ALWAYS English.
#     --force        resetear aunque ya exista un sistema registrado (DESTRUYE
#                    repos.yaml, specs y knowledge generado de la instancia)
# Compatible bash 3.2 (macOS).
set -euo pipefail
cd "$(dirname "$0")/.."

SISTEMA="${1:-}"
if [ -z "${SISTEMA}" ] || [ "${SISTEMA}" = "-h" ] || [ "${SISTEMA}" = "--help" ]; then
  sed -n '/^# Uso:/,/^# Compatible/p' "$0" | sed 's/^# \{0,1\}//;$d'
  exit 1
fi
shift
PREFIX=""; FORCE=""; LANG_TRABAJO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --pack-prefix) PREFIX="$2"; shift 2 ;;
    --lang)        LANG_TRABAJO="$2"; shift 2 ;;
    --force)       FORCE="si"; shift ;;
    *) echo "ERROR - opcion desconocida: $1"; exit 1 ;;
  esac
done
# Working language: asked once, persisted in the registry (system.lang).
if [ -z "${LANG_TRABAJO}" ]; then
  if [ -t 0 ]; then
    printf "Working language for specs and interactions? [en/es] (default en): "
    read -r LANG_TRABAJO || true
  fi
  LANG_TRABAJO="${LANG_TRABAJO:-en}"
fi
case "${LANG_TRABAJO}" in
  en|es) ;;
  *) echo "ERROR - --lang must be 'en' or 'es' (got: ${LANG_TRABAJO})"; exit 1 ;;
esac
SISTEMA="$(printf '%s' "${SISTEMA}" | tr -cd 'A-Za-z0-9._-')"
[ -n "${SISTEMA}" ] || { echo "ERROR - nombre de sistema invalido"; exit 1; }
PREFIX="${PREFIX:-${SISTEMA}}"

# ---------- Guardas ----------
# .instancia lo escribe este script: distingue una INSTANCIA ya inicializada
# (con trabajo real que proteger) de un clon fresco de la plantilla (que trae
# datos de ejemplo y se resetea sin preguntar).
if [ -f .instancia ] && [ -z "${FORCE}" ]; then
  echo "ERROR - este workspace YA es la instancia de un sistema:"
  sed 's/^/    /' .instancia
  echo ""
  echo "  Si de verdad quieres RESETEARLA (borra registro, specs y contexto"
  echo "  generado; el estado anterior queda en la historia git): --force."
  echo "  Si querias un sistema NUEVO: clona la plantilla en otra carpeta y"
  echo "  corre alli este script (ver docs/instructivo-repo-existente.md)."
  exit 1
fi
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "ERROR - este workspace no es un repo git. Clonalo desde la plantilla"
  echo "        (git clone <plantilla> <sistema>-workspace) y reintenta."
  exit 1
fi

echo ">> Inicializando instancia del sistema '${SISTEMA}' (prefijo de packs: ${PREFIX})"

# ---------- Limpiar datos de instancia ----------
# Specs: solo queda la plantilla
find specs -type f -name "*.md" ! -name "_template.md" -exec rm -f {} \;
# ADRs e incidentes: solo plantillas
find knowledge/decisiones -type f ! -name "_template-adr.md" -exec rm -f {} \; 2>/dev/null || true
find knowledge/incidentes -type f ! -name "_template-postmortem.md" -exec rm -f {} \; 2>/dev/null || true
# as-is generado
rm -rf knowledge/as-is
mkdir -p knowledge/as-is
{ echo "# Mapa AS-IS del sistema ${SISTEMA}"
  echo "> Sin repos registrados aun. Se genera con ./scripts/generate-as-is.sh"
  echo "> tras dar de alta el primer repo (./scripts/repo-add.sh o /repo-add)."
} > knowledge/as-is/INDEX.md
# Packs de contexto generados (skills con procedencia) + indice de sistemas
for f in $(grep -l '^generado_desde:' .claude/skills/*/SKILL.md 2>/dev/null || true); do
  rm -rf "$(dirname "${f}")"
done
rm -rf .claude/skills/mapa-sistemas
# Suites de aserciones y extractores por repo: solo READMEs
find scripts/afirmaciones.d -type f ! -name "README.md" -exec rm -f {} \; 2>/dev/null || true
find scripts/as-is.d -type f ! -name "README.md" -exec rm -f {} \; 2>/dev/null || true
# Repos clonados de la instancia anterior (gitignorados, pero estorban)
if [ -d repos ]; then
  find repos -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null || true
fi
# Harness: volver al estado inicial declarado en sus propias plantillas
if [ -f harness/feature_list.json ]; then
  python3 - <<'PY' 2>/dev/null || true
import json
p = "harness/feature_list.json"
d = json.load(open(p))
d["features"] = [f for f in d.get("features", []) if "EJEMPLO" in f.get("description", "")]
json.dump(d, open(p, "w"), ensure_ascii=False, indent=2)
PY
fi

# ---------- Registro nuevo (esqueleto; el primer repo-add lo puebla) ----------
{ echo "# Registro de repositorios del sistema - UNICA fuente de verdad de la topologia."
  echo "# Alta de repos: ./scripts/repo-add.sh <url-o-ruta>  (o la skill /repo-add)"
  echo "system:"
  echo "  name: ${SISTEMA}"
  echo "  pack_prefix: ${PREFIX}"
  echo "  lang: ${LANG_TRABAJO}"
  echo "repos:"
} > repos.yaml

# ---------- Marcador de instancia ----------
{ echo "sistema: ${SISTEMA}"
  echo "pack_prefix: ${PREFIX}"
  echo "inicializada: $(date -u +%Y-%m-%d)"
} > .instancia

# ---------- Commit inicial de la instancia ----------
git add -A
git commit -q -m "chore(init): instancia del sistema ${SISTEMA} desde la plantilla" || true

echo ""
echo "OK - instancia '${SISTEMA}' lista (commit inicial creado)."
echo "Siguientes pasos (docs/instructivo-repo-existente.md):"
echo "  1) [repos privados] cp .env.example .env && chmod 600 .env  (completar)"
echo "  2) ./scripts/repo-add.sh <url-o-ruta-del-primer-repo> --entrypoint"
echo "     (o desde Claude Code: /repo-add <url> — hace ademas as-is e indexado)"
echo "  3) /repo-map <repo> y, con 2+ repos, /system-map"
echo "  4) /spec-create <primer-requerimiento>"
