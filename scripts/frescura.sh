#!/usr/bin/env bash
# frescura.sh - Detecta si un pack de contexto caduco respecto del codigo.
#
# Cada pack (skill con frontmatter `generado_desde:`) declara desde que
# estado de cada repo fue escrito: commit git corto, o huella de snapshot
# para repos sin .git (stamp_of_repo de repo-lib.sh). Este script compara
# esos sellos con el estado ACTUAL de repos/.
#
# USO
#   scripts/frescura.sh comprobar          # todos los packs; rc=1 si alguno caduco
#   scripts/frescura.sh comprobar <pack>   # solo ese pack (nombre de la skill)
#   scripts/frescura.sh sellar <pack>      # re-sella el pack al estado actual
#                                          # (SOLO tras re-verificar su contenido)
# Compatible bash 3.2 (macOS).
set -uo pipefail
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

MODE="${1:-comprobar}"
PACK_ARG="${2:-}"

pack_files() {
  if [ -n "${PACK_ARG}" ]; then
    if [ ! -f ".claude/skills/${PACK_ARG}/SKILL.md" ]; then
      echo "ERROR - no existe la skill '${PACK_ARG}'" >&2; return 1
    fi
    echo ".claude/skills/${PACK_ARG}/SKILL.md"
  else
    grep -l '^generado_desde:' .claude/skills/*/SKILL.md 2>/dev/null || true
  fi
}

# Imprime "repo sello" por linea desde el frontmatter del pack
stamps_of_pack() {
  awk '
    /^generado_desde:/ { f=1; next }
    f && /^[^ ]/ { f=0 }
    f && /^  [A-Za-z0-9._-]+:/ {
      gsub(/[:#].*$/, "", $1); stamp=$2; sub(/#.*/, "", stamp)
      print $1, stamp
    }
  ' "$1" | sed 's/:$//'
}

case "${MODE}" in
  comprobar)
    FILES=$(pack_files) || exit 2
    if [ -z "${FILES}" ]; then
      echo "Sin packs con 'generado_desde:' - nada que comprobar."
      echo "(los generan /repo-map y /system-map)"
      exit 0
    fi
    RC=0
    for f in ${FILES}; do
      pack=$(basename "$(dirname "${f}")")
      CADUCO=""
      while IFS=' ' read -r repo sello; do
        [ -z "${repo}" ] && continue
        if [ ! -e "repos/${repo}" ]; then
          echo "  ?         ${pack}: repos/${repo} no esta presente (setup.sh)"
          continue
        fi
        actual=$(stamp_of_repo "${repo}")
        if [ "${actual}" != "${sello}" ]; then
          CADUCO="si"
          echo "  OBSOLETO  ${pack}: ${repo} ${sello} -> ${actual}"
        fi
      done <<EOF
$(stamps_of_pack "${f}")
EOF
      if [ -z "${CADUCO}" ]; then
        echo "  vigente   ${pack}"
      else
        RC=1
      fi
    done
    if [ "${RC}" -ne 0 ]; then
      echo ""
      echo "Packs OBSOLETOS: regenerarlos con /repo-map o /system-map"
      echo "(re-verificar contenido; luego scripts/frescura.sh sellar <pack>)."
    fi
    exit "${RC}" ;;
  sellar)
    if [ -z "${PACK_ARG}" ]; then echo "uso: $0 sellar <pack>"; exit 2; fi
    FILES=$(pack_files) || exit 2
    f="${FILES}"
    TMPF=$(mktemp)
    stamps_of_pack "${f}" | while IFS=' ' read -r repo _old; do
      [ -z "${repo}" ] && continue
      if [ -e "repos/${repo}" ]; then
        printf '%s %s\n' "${repo}" "$(stamp_of_repo "${repo}")"
      fi
    done > "${TMPF}"
    python3 - "${f}" "${TMPF}" <<'PY'
import re, sys
path, stamps_file = sys.argv[1], sys.argv[2]
stamps = dict(line.split() for line in open(stamps_file) if line.strip())
out, in_block = [], False
for line in open(path):
    if line.startswith("generado_desde:"):
        in_block = True
        out.append(line)
        continue
    if in_block and not line.startswith("  "):
        in_block = False
    if in_block:
        m = re.match(r"^(  )([A-Za-z0-9._-]+):\s*(\S+)(.*)$", line.rstrip("\n"))
        if m and m.group(2) in stamps:
            line = f"{m.group(1)}{m.group(2)}: {stamps[m.group(2)]}{m.group(4)}\n"
    if line.startswith("verificado:"):
        import datetime
        line = f"verificado: {datetime.date.today().isoformat()}\n"
    out.append(line)
open(path, "w").write("".join(out))
print(f"sellado: {path}")
PY
    rm -f "${TMPF}" ;;
  *)
    echo "uso: $0 comprobar [pack] | sellar <pack>"; exit 2 ;;
esac
