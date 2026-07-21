#!/usr/bin/env bash
# init-system.sh - Turns a CLONE of the factory template into the clean
# instance of a new system. It is the "step -1" of the how-to guide:
#
#   git clone <template> my-system-workspace && cd my-system-workspace
#   git remote rename origin upstream        # the template remains for updates
#   ./scripts/init-system.sh my-system --pack-prefix ms
#   ./scripts/repo-add.sh <url-of-first-repo> --entrypoint
#
# Cleans the INSTANCE data the template ships as examples (registry, specs,
# generated as-is, packs) and leaves the PRODUCT intact (scripts, generic
# skills, rules, agents, templates, docs).
#
# Usage:
#   ./scripts/init-system.sh <system-name> [--pack-prefix <px>] [--lang en|es] [--force]
#     --pack-prefix  short prefix for the context packs (default: the name)
#     --lang         working language for specs and interactions (en|es).
#                    Without the flag and with an interactive terminal, it asks;
#                    non-interactive default: en. Commands are ALWAYS English.
#     --force        reset even if a system is already registered (DESTROYS
#                    repos.yaml, specs and the instance's generated knowledge)
# Compatible with bash 3.2 (macOS).
set -euo pipefail
cd "$(dirname "$0")/.."

SISTEMA="${1:-}"
if [ -z "${SISTEMA}" ] || [ "${SISTEMA}" = "-h" ] || [ "${SISTEMA}" = "--help" ]; then
  sed -n '/^# Usage:/,/^# Compatible/p' "$0" | sed 's/^# \{0,1\}//;$d'
  exit 1
fi
shift
PREFIX=""; FORCE=""; LANG_TRABAJO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --pack-prefix) PREFIX="$2"; shift 2 ;;
    --lang)        LANG_TRABAJO="$2"; shift 2 ;;
    --force)       FORCE="si"; shift ;;
    *) echo "ERROR - unknown option: $1"; exit 1 ;;
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
[ -n "${SISTEMA}" ] || { echo "ERROR - invalid system name"; exit 1; }
PREFIX="${PREFIX:-${SISTEMA}}"

# ---------- Guards ----------
# .instancia is written by this script: it distinguishes an already
# initialized INSTANCE (with real work to protect) from a fresh clone of the
# template (which ships example data and is reset without asking).
if [ -f .instancia ] && [ -z "${FORCE}" ]; then
  echo "ERROR - this workspace is ALREADY the instance of a system:"
  sed 's/^/    /' .instancia
  echo ""
  echo "  If you really want to RESET it (deletes registry, specs and generated"
  echo "  context; the previous state remains in git history): --force."
  echo "  If you wanted a NEW system: clone the template into another folder and"
  echo "  run this script there (see docs/instructivo-repo-existente.md)."
  exit 1
fi
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "ERROR - this workspace is not a git repo. Clone it from the template"
  echo "        (git clone <template> <system>-workspace) and retry."
  exit 1
fi

echo ">> Initializing instance of system '${SISTEMA}' (pack prefix: ${PREFIX})"

# ---------- Clean instance data ----------
# Specs: only the template remains
find specs -type f -name "*.md" ! -name "_template.md" -exec rm -f {} \;
# ADRs and incidents: templates only
find knowledge/decisions -type f ! -name "_template-adr.md" -exec rm -f {} \; 2>/dev/null || true
find knowledge/incidents -type f ! -name "_template-postmortem.md" -exec rm -f {} \; 2>/dev/null || true
# generated as-is
rm -rf knowledge/as-is
mkdir -p knowledge/as-is
{ echo "# AS-IS map of system ${SISTEMA}"
  echo "> No repos registered yet. Generated with ./scripts/generate-as-is.sh"
  echo "> after onboarding the first repo (./scripts/repo-add.sh or /repo-add)."
} > knowledge/as-is/INDEX.md
# Generated context packs (skills with provenance) + systems index
for f in $(grep -l '^generado_desde:' .claude/skills/*/SKILL.md 2>/dev/null || true); do
  rm -rf "$(dirname "${f}")"
done
rm -rf .claude/skills/mapa-sistemas
# Assertion suites and per-repo extractors: READMEs only
find scripts/assertions.d -type f ! -name "README.md" -exec rm -f {} \; 2>/dev/null || true
find scripts/as-is.d -type f ! -name "README.md" -exec rm -f {} \; 2>/dev/null || true
# Repos cloned by the previous instance (gitignored, but in the way)
if [ -d repos ]; then
  find repos -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null || true
fi
# Harness: back to the initial state declared in its own templates
if [ -f harness/feature_list.json ]; then
  python3 - <<'PY' 2>/dev/null || true
import json
p = "harness/feature_list.json"
d = json.load(open(p))
d["features"] = [f for f in d.get("features", []) if "EJEMPLO" in f.get("description", "")]
json.dump(d, open(p, "w"), ensure_ascii=False, indent=2)
PY
fi

# ---------- New registry (skeleton; the first repo-add populates it) ----------
{ echo "# System repository registry - the ONLY source of truth for the topology."
  echo "# Add repos with: ./scripts/repo-add.sh <url-or-path>  (or the /repo-add skill)"
  echo "system:"
  echo "  name: ${SISTEMA}"
  echo "  pack_prefix: ${PREFIX}"
  echo "  lang: ${LANG_TRABAJO}"
  echo "repos:"
} > repos.yaml

# ---------- Instance marker ----------
{ echo "sistema: ${SISTEMA}"
  echo "pack_prefix: ${PREFIX}"
  echo "inicializada: $(date -u +%Y-%m-%d)"
} > .instancia

# ---------- Initial commit of the instance ----------
git add -A
git commit -q -m "chore(init): instance of system ${SISTEMA} from the template" || true

echo ""
echo "OK - instance '${SISTEMA}' ready (initial commit created)."
echo "Next steps (docs/instructivo-repo-existente.md):"
echo "  1) [private repos] cp .env.example .env && chmod 600 .env  (fill it in)"
echo "  2) ./scripts/repo-add.sh <url-or-path-of-first-repo> --entrypoint"
echo "     (or from Claude Code: /repo-add <url> — also runs as-is and indexing)"
echo "  3) /repo-map <repo> and, with 2+ repos, /system-map"
echo "  4) /spec-create <first-requirement>"
