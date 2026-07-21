#!/usr/bin/env bash
# dora.sh - Deriva las metricas DORA de fuentes verificables y reescribe la
# tabla de knowledge/uso.md SOLO entre <!-- DORA:BEGIN --> y <!-- DORA:END -->.
# Fuentes: historial git de los repos registrados (tags v* o merges a la rama
# por defecto = despliegues; primer commit de la rama -> merge = lead time) y
# postmortems INC-*.md (fecha y campo MTTR). Nunca inventa: sin fuente => la
# celda dice "sin datos" y el motivo (RN-F4).
# Compatible con bash 3.2. Uso:
#   ./scripts/dora.sh [--root <workspace>] [--check]
#   --check: exit 1 si la tabla publicada difiere de lo recalculado (CI).
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=$(cd "$2" && pwd) || exit 2; shift 2 ;;
    --check) CHECK=1; shift ;;
    *) echo "uso: dora.sh [--root <workspace>] [--check]" >&2; exit 2 ;;
  esac
done
cd "${ROOT}"
. scripts/repo-lib.sh

USO="knowledge/uso.md"
DIAS=90
[ -f "${USO}" ] || { echo "ERROR: no existe ${USO}" >&2; exit 1; }
grep -q 'DORA:BEGIN' "${USO}" || { echo "ERROR: ${USO} sin marcadores <!-- DORA:BEGIN/END -->" >&2; exit 1; }

SINCE=$(python3 -c "from datetime import datetime,timedelta;print((datetime.now()-timedelta(days=${DIAS})).strftime('%Y-%m-%d'))")

DATA=$(mktemp)
trap 'rm -f "${DATA}"' EXIT

# ---- recolectar despliegues y lead times por repo registrado ----
for name in $(registry_repos 2>/dev/null); do
  dir="repos/${name}"
  if [ -d "${dir}/.git" ]; then
    sello=$(git -C "${dir}" rev-parse --short HEAD 2>/dev/null || echo "?")
    branch=$(git -C "${dir}" symbolic-ref --short HEAD 2>/dev/null || echo "HEAD")
    # despliegues: tags v* del periodo si existen; si no, merges first-parent
    tags=$(git -C "${dir}" for-each-ref 'refs/tags/v*' --format='%(creatordate:short)' 2>/dev/null \
           | awk -v s="${SINCE}" '$1 >= s' | wc -l | tr -d ' ')
    merges=$(git -C "${dir}" log --merges --first-parent --since="${SINCE}" \
             --format='%H' "${branch}" 2>/dev/null)
    nmerges=0
    for m in ${merges}; do
      nmerges=$((nmerges + 1))
      mct=$(git -C "${dir}" log -1 --format='%ct' "${m}")
      fct=$(git -C "${dir}" log --format='%ct' "${m}^1..${m}^2" 2>/dev/null | tail -1)
      [ -n "${fct}" ] && echo "LEAD|$(( (mct - fct) / 86400 ))" >> "${DATA}"
    done
    if [ "${tags}" -gt 0 ]; then deploys=${tags}; else deploys=${nmerges}; fi
    echo "REPO|${name}|${deploys}|${sello}" >> "${DATA}"
  else
    echo "MISSING|${name}" >> "${DATA}"
  fi
done

# ---- recolectar incidentes del periodo ----
for f in knowledge/incidentes/INC-*.md; do
  [ -f "${f}" ] || continue
  fecha=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "${f}" | head -1)
  mttr=$(grep -i 'MTTR' "${f}" | head -1)
  echo "INC|${fecha:-}|${mttr:-}" >> "${DATA}"
done

# ---- calcular, componer el bloque y escribir/comparar ----
python3 - "${DATA}" "${USO}" "${SINCE}" "${DIAS}" "${CHECK}" <<'PYEOF'
import re, sys
from datetime import date
from statistics import median

data_path, uso_path, since, dias, check = sys.argv[1:6]
dias = int(dias)

repos, missing, leads, incs = [], [], [], []
for line in open(data_path, encoding="utf-8"):
    parts = line.rstrip("\n").split("|")
    if parts[0] == "REPO":
        repos.append((parts[1], int(parts[2]), parts[3]))
    elif parts[0] == "MISSING":
        missing.append(parts[1])
    elif parts[0] == "LEAD":
        leads.append(max(0, int(parts[1])))
    elif parts[0] == "INC":
        incs.append((parts[1], "|".join(parts[2:])))

def mttr_minutos(texto):
    h = re.search(r"(\d+)\s*h", texto)
    m = re.search(r"(\d+)\s*m", texto)
    if not h and not m:
        return None
    return (int(h.group(1)) * 60 if h else 0) + (int(m.group(1)) if m else 0)

inc_periodo = [(f, t) for f, t in incs if f and f >= since]
mttrs = [v for v in (mttr_minutos(t) for _, t in inc_periodo) if v is not None]

deploys = sum(d for _, d, _ in repos)
sin_repos = not repos

if sin_repos:
    causa = "sin datos (ningún repo clonado — correr scripts/setup.sh)"
    freq = lead = cfr = causa
    mttr = causa if not mttrs else f"mediana {int(median(mttrs))}m ({len(mttrs)} postmortems)"
else:
    freq = f"{deploys} despliegues en {dias} días ({deploys / (dias / 7):.1f}/semana)"
    lead = (f"mediana {int(median(leads))}d ({len(leads)} merges)"
            if leads else "sin datos (sin merges en el período)")
    cfr = (f"{round(100 * len(inc_periodo) / deploys)}% ({len(inc_periodo)} incidentes / {deploys} despliegues)"
           if deploys else "sin datos (sin despliegues en el período)")
    mttr = (f"mediana {int(median(mttrs))}m ({len(mttrs)} postmortems)"
            if mttrs else "sin datos (sin postmortems con MTTR en el período)")

fuentes = " ".join(f"{n}@{s}" for n, _, s in repos) or "ninguna"
sello = (f"[GENERADO v1] {date.today().isoformat()} · período: últimos {dias} días "
         f"· fuentes: {fuentes} · no editar a mano (scripts/dora.sh)")
filas = [
    ("Frecuencia de despliegue", freq, "≥ 1/día", "tags v* o merges a rama por defecto"),
    ("Lead time (commit→prod)", lead, "< 1 día", "primer commit de la rama → merge"),
    ("Change failure rate", cfr, "< 15%", "knowledge/incidentes vs despliegues"),
    ("MTTR", mttr, "< 1 hora", "campo MTTR de los postmortems"),
]
bloque = [sello, "", "| Métrica | Actual | Objetivo | Fuente |", "|---|---|---|---|"]
bloque += [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in filas]
if missing:
    bloque += ["", "Sin datos de: " + ", ".join(missing) + " (no clonado — correr scripts/setup.sh)"]
nuevo = "\n".join(bloque)

contenido = open(uso_path, encoding="utf-8").read()
patron = re.compile(r"(<!-- DORA:BEGIN -->)(.*?)(<!-- DORA:END -->)", re.S)
actual = patron.search(contenido)
if not actual:
    sys.exit("ERROR: marcadores DORA malformados en " + uso_path)

def sin_fecha(texto):  # el dia de generacion no cuenta como drift
    return re.sub(r"\[GENERADO v1\] \d{4}-\d{2}-\d{2}", "[GENERADO v1]", texto)

vigente = actual.group(2).strip("\n")
if check == "1":
    if sin_fecha(vigente) != sin_fecha(nuevo):
        print("DRIFT: la tabla DORA publicada difiere de lo recalculado. Correr scripts/dora.sh")
        sys.exit(1)
    print("OK: tabla DORA en sincronia")
    sys.exit(0)

if vigente == nuevo:
    print("Sin cambios: tabla DORA ya en sincronia")
    sys.exit(0)
open(uso_path, "w", encoding="utf-8").write(
    patron.sub(lambda m: m.group(1) + "\n" + nuevo + "\n" + m.group(3), contenido))
print("Tabla DORA regenerada en " + uso_path)
PYEOF
