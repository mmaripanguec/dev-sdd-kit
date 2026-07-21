#!/usr/bin/env bash
# dora.sh - Deriva las metricas DORA de fuentes verificables y reescribe la
# tabla de knowledge/usage.md SOLO entre <!-- DORA:BEGIN --> y <!-- DORA:END -->.
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

USO="knowledge/usage.md"
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
for f in knowledge/incidents/INC-*.md; do
  [ -f "${f}" ] || continue
  fecha=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "${f}" | head -1)
  mttr=$(grep -i 'MTTR' "${f}" | head -1)
  echo "INC|${fecha:-}|${mttr:-}" >> "${DATA}"
done

# ---- calcular, componer el bloque y escribir/comparar ----
LANG_WS="$(registry_system lang 2>/dev/null || true)"; LANG_WS="${LANG_WS:-en}"
python3 - "${DATA}" "${USO}" "${SINCE}" "${DIAS}" "${CHECK}" "${LANG_WS}" <<'PYEOF' 
import re, sys
from datetime import date
from statistics import median

data_path, uso_path, since, dias, check, lang = sys.argv[1:7]
lang = lang if lang in ("en", "es") else "en"
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

S = {
  "en": {"nd": "no data ({})", "nd_repos": "no repos cloned — run scripts/setup.sh",
         "freq": "{} deployments in {} days ({:.1f}/week)",
         "med": "median {}m ({} postmortems)", "lead": "median {}d ({} merges)",
         "nd_merges": "no merges in the period",
         "cfr": "{}% ({} incidents / {} deployments)",
         "nd_deploys": "no deployments in the period",
         "nd_mttr": "no postmortems with MTTR in the period"},
  "es": {"nd": "sin datos ({})", "nd_repos": "ningún repo clonado — correr scripts/setup.sh",
         "freq": "{} despliegues en {} días ({:.1f}/semana)",
         "med": "mediana {}m ({} postmortems)", "lead": "mediana {}d ({} merges)",
         "nd_merges": "sin merges en el período",
         "cfr": "{}% ({} incidentes / {} despliegues)",
         "nd_deploys": "sin despliegues en el período",
         "nd_mttr": "sin postmortems con MTTR en el período"},
}[lang]
if sin_repos:
    causa = S["nd"].format(S["nd_repos"])
    freq = lead = cfr = causa
    mttr = causa if not mttrs else S["med"].format(int(median(mttrs)), len(mttrs))
else:
    freq = S["freq"].format(deploys, dias, deploys / (dias / 7))
    lead = (S["lead"].format(int(median(leads)), len(leads))
            if leads else S["nd"].format(S["nd_merges"]))
    cfr = (S["cfr"].format(round(100 * len(inc_periodo) / deploys), len(inc_periodo), deploys)
           if deploys else S["nd"].format(S["nd_deploys"]))
    mttr = (S["med"].format(int(median(mttrs)), len(mttrs))
            if mttrs else S["nd"].format(S["nd_mttr"]))

fuentes = " ".join(f"{n}@{s}" for n, _, s in repos) or "ninguna"
SEAL = {"en": ("[GENERATED v1] {} · period: last {} days · sources: {} · do not edit by hand (scripts/dora.sh)"),
        "es": ("[GENERADO v1] {} · período: últimos {} días · fuentes: {} · no editar a mano (scripts/dora.sh)")}[lang]
CAB = {"en": ["Metric", "Current", "Target", "Source"],
       "es": ["Métrica", "Actual", "Objetivo", "Fuente"]}[lang]
FILAS_N = {"en": [("Deployment frequency", "≥ 1/day", "v* tags or merges to default branch"),
                  ("Lead time (commit→prod)", "< 1 day", "first branch commit → merge"),
                  ("Change failure rate", "< 15%", "knowledge/incidents vs deployments"),
                  ("MTTR", "< 1 hour", "MTTR field of the postmortems")],
           "es": [("Frecuencia de despliegue", "≥ 1/día", "tags v* o merges a rama por defecto"),
                  ("Lead time (commit→prod)", "< 1 día", "primer commit de la rama → merge"),
                  ("Change failure rate", "< 15%", "knowledge/incidents vs despliegues"),
                  ("MTTR", "< 1 hora", "campo MTTR de los postmortems")]}[lang]
sello = SEAL.format(date.today().isoformat(), dias, fuentes)
valores = [freq, lead, cfr, mttr]
filas = [(n, valores[i], o, fu) for i, (n, o, fu) in enumerate(FILAS_N)]
bloque = [sello, "", "| " + " | ".join(CAB) + " |", "|---|---|---|---|"]
bloque += [f"| {a} | {b} | {c} | {d} |" for a, b, c, d in filas]
if missing:
    FALTA = {"en": "No data from: {} (not cloned — run scripts/setup.sh)",
             "es": "Sin datos de: {} (no clonado — correr scripts/setup.sh)"}[lang]
    bloque += ["", FALTA.format(", ".join(missing))]
nuevo = "\n".join(bloque)

contenido = open(uso_path, encoding="utf-8").read()
patron = re.compile(r"(<!-- DORA:BEGIN -->)(.*?)(<!-- DORA:END -->)", re.S)
actual = patron.search(contenido)
if not actual:
    sys.exit("ERROR: marcadores DORA malformados en " + uso_path)

def sin_fecha(texto):  # el dia de generacion no cuenta como drift
    return re.sub(r"\[GENERA(?:DO|TED) v1\] \d{4}-\d{2}-\d{2}", "[SEAL]", texto)

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
