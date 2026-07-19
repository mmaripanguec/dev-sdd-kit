#!/usr/bin/env bash
# docs.sh - Genera docs/arquitectura.html desde templates/docs-arquitectura.html
# inyectando el catalogo VIVO del workspace: skills, agentes, reglas, scripts,
# topologia (repos.yaml), reglas de negocio, indice de specs y bloque DORA.
# La prosa estable vive en la plantilla; aqui solo se derivan datos (RN-G1,
# RN-F4: sin fuente => "sin datos" con causa, nunca se inventa).
# Compatible con bash 3.2. Uso:
#   ./scripts/docs.sh [--root <workspace>] [--check]
#   --check: exit 1 si el HTML publicado difiere de lo recalculado (CI).
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=$(cd "$2" && pwd) || exit 2; shift 2 ;;
    --check) CHECK=1; shift ;;
    *) echo "uso: docs.sh [--root <workspace>] [--check]" >&2; exit 2 ;;
  esac
done
cd "${ROOT}"
. scripts/repo-lib.sh

TPL="templates/docs-arquitectura.html"
OUT="docs/arquitectura.html"
[ -f "${TPL}" ] || { echo "ERROR: no existe ${TPL}" >&2; exit 1; }
mkdir -p docs

# ---- topologia: derivada del registro via repo-lib (RN-G1) ----
DATA=$(mktemp)
trap 'rm -f "${DATA}"' EXIT
for name in $(registry_repos); do
  prov=$(registry_get "${name}" provider 2>/dev/null || echo "")
  role=$(registry_get "${name}" role 2>/dev/null || echo "")
  orden=$(registry_get "${name}" deploy_order 2>/dev/null || echo "")
  dom=$(registry_get "${name}" domain 2>/dev/null || echo "")
  clonado="no"; [ -d "repos/${name}/.git" ] && clonado="sí"
  echo "TOPO|${name}|${prov}|${role}|${orden}|${dom}|${clonado}" >> "${DATA}"
done

python3 - "${DATA}" "${TPL}" "${OUT}" "${CHECK}" <<'PYEOF'
import glob, html, os, re, sys
from datetime import date

data_path, tpl_path, out_path, check = sys.argv[1:5]
esc = html.escape

def tabla(cabeceras, filas, vacio):
    if not filas:
        return f'<p class="muted">sin datos ({esc(vacio)})</p>'
    out = ['<div class="wide"><table>',
           "<tr>" + "".join(f"<th>{esc(c)}</th>" for c in cabeceras) + "</tr>"]
    out += ["<tr>" + "".join(f"<td>{v}</td>" for v in f) + "</tr>" for f in filas]
    out.append("</table></div>")
    return "\n".join(out)

def frontmatter(path):
    texto = open(path, encoding="utf-8").read()
    m = re.match(r"---\n(.*?)\n---", texto, re.S)
    campos = {}
    if m:
        for linea in m.group(1).splitlines():
            kv = re.match(r"(\w[\w-]*):\s*(.*)", linea)
            if kv:
                campos[kv.group(1)] = kv.group(2).strip()
    return campos

# topologia (recolectada por bash desde el registro)
topo = []
for linea in open(data_path, encoding="utf-8"):
    p = linea.rstrip("\n").split("|")
    if p[0] == "TOPO":
        topo.append([esc(x) for x in p[1:7]])
TOPOLOGIA = tabla(["Repo", "Proveedor", "Rol", "Orden despliegue", "Dominio", "Clonado"],
                  topo, "registro sin repos — dar de alta con /repo-add")

# skills
filas = []
for f in sorted(glob.glob(".claude/skills/*/SKILL.md")):
    fm = frontmatter(f)
    nombre = fm.get("name") or os.path.basename(os.path.dirname(f))
    desc = fm.get("description") or '<em>(sin descripción — completar frontmatter)</em>'
    if fm.get("description"):
        desc = esc(desc)
    filas.append([f"<code>/{esc(nombre)}</code>", desc])
SKILLS = tabla(["Comando", "Qué hace (frontmatter)"], filas, "sin skills en .claude/skills")

# agentes
filas = []
for f in sorted(glob.glob(".claude/agents/*.md")):
    fm = frontmatter(f)
    nombre = fm.get("name") or os.path.splitext(os.path.basename(f))[0]
    desc = esc(fm.get("description", "")) or '<em>(sin descripción)</em>'
    filas.append([f"<code>{esc(nombre)}</code>", desc])
AGENTES = tabla(["Agente", "Fase y propósito"], filas, "sin agentes en .claude/agents")

# reglas transversales
filas = []
for f in sorted(glob.glob(".claude/rules/*.md")):
    titulo = base = ""
    for linea in open(f, encoding="utf-8"):
        if not titulo and linea.startswith("# "):
            titulo = linea[2:].strip()
        elif not base and linea.startswith("> "):
            base = linea[2:].strip()
        if titulo and base:
            break
    filas.append([f"<code>{esc(os.path.basename(f))}</code>", esc(titulo), esc(base)])
REGLAS = tabla(["Archivo", "Regla", "Estándares base"], filas, "sin reglas en .claude/rules")

# scripts (cabecera "# nombre.sh - descripcion")
filas = []
for f in sorted(glob.glob("scripts/*.sh")):
    desc = ""
    for linea in open(f, encoding="utf-8"):
        m = re.match(r"#\s*[\w.-]+\.sh\s*-\s*(.+)", linea)
        if m:
            desc = m.group(1).strip()
            break
    filas.append([f"<code>{esc(os.path.basename(f))}</code>",
                  esc(desc) or '<em>(sin descripción de cabecera)</em>'])
SCRIPTS = tabla(["Script", "Qué hace"], filas, "sin scripts")

# reglas de negocio vigentes (tabla markdown -> filas, sin la fila de ejemplo)
filas = []
try:
    for linea in open("knowledge/reglas-negocio.md", encoding="utf-8"):
        m = re.match(r"\|\s*(RN-[\w-]+)\s*\|(.*)", linea)
        if m and "<ej" not in m.group(2):
            celdas = [c.strip() for c in m.group(2).split("|") if c.strip() != ""]
            filas.append([f"<code>{esc(m.group(1))}</code>"] + [esc(c) for c in celdas[:4]])
except FileNotFoundError:
    pass
REGLAS_NEGOCIO = tabla(["ID", "Regla", "Dominio", "Origen", "Vigente desde"],
                       filas, "sin reglas registradas en knowledge/reglas-negocio.md")

# indice de specs (titulo + estado)
filas = []
for f in sorted(glob.glob("specs/*.md")):
    if os.path.basename(f).startswith("_"):
        continue
    titulo = estado = ""
    for linea in open(f, encoding="utf-8"):
        if not titulo and linea.startswith("# "):
            titulo = re.sub(r"^#\s*Spec:\s*", "", linea[2:]).strip()
        m = re.match(r"\|\s*Estado\s*\|\s*(.+?)\s*\|", linea)
        if m:
            estado = m.group(1)
        if titulo and estado:
            break
    filas.append([f"<code>{esc(os.path.basename(f))}</code>", esc(titulo),
                  esc(estado) or "?"])
SPECS = tabla(["Archivo", "Spec", "Estado"], filas, "sin specs en specs/")

# bloque DORA de uso.md (markdown -> html)
DORA = '<p class="muted">sin datos (knowledge/uso.md sin bloque DORA — correr scripts/dora.sh)</p>'
try:
    uso = open("knowledge/uso.md", encoding="utf-8").read()
    m = re.search(r"<!-- DORA:BEGIN -->\n?(.*?)\n?<!-- DORA:END -->", uso, re.S)
    if m and m.group(1).strip():
        piezas, celdas_md = [], []
        for linea in m.group(1).strip().splitlines():
            if linea.startswith("|"):
                if re.match(r"\|[\s|:-]+\|$", linea.replace("-", "-")) and "---" in linea:
                    continue
                celdas_md.append(["<td>%s</td>" % esc(c.strip())
                                  for c in linea.strip("|").split("|")])
            elif linea.strip():
                piezas.append(f'<p class="muted">{esc(linea.strip())}</p>')
        if celdas_md:
            cab = "".join(celdas_md[0]).replace("<td>", "<th>").replace("</td>", "</th>")
            cuerpo = "".join("<tr>%s</tr>" % "".join(f) for f in celdas_md[1:])
            piezas.append(f'<div class="wide"><table><tr>{cab}</tr>{cuerpo}</table></div>')
        DORA = "\n".join(piezas)
except FileNotFoundError:
    pass

SELLO = f"[GENERADO v1] {date.today().isoformat()} · scripts/docs.sh — no editar a mano"

htmlout = open(tpl_path, encoding="utf-8").read()
for clave, valor in [("SELLO", SELLO), ("TOPOLOGIA", TOPOLOGIA), ("SKILLS", SKILLS),
                     ("AGENTES", AGENTES), ("REGLAS", REGLAS), ("SCRIPTS", SCRIPTS),
                     ("REGLAS_NEGOCIO", REGLAS_NEGOCIO), ("SPECS", SPECS), ("DORA", DORA)]:
    htmlout = htmlout.replace("{{%s}}" % clave, valor)

def sin_sello(texto):  # la fecha de generacion no cuenta como drift
    return re.sub(r"\[GENERADO v1\] \d{4}-\d{2}-\d{2}", "[GENERADO v1]", texto)

vigente = open(out_path, encoding="utf-8").read() if os.path.exists(out_path) else None
if check == "1":
    if vigente is None or sin_sello(vigente) != sin_sello(htmlout):
        print("DRIFT: docs/arquitectura.html difiere de lo recalculado. Correr scripts/docs.sh")
        sys.exit(1)
    print("OK: documentacion en sincronia")
    sys.exit(0)

if vigente == htmlout:
    print("Sin cambios: documentacion ya en sincronia")
    sys.exit(0)
open(out_path, "w", encoding="utf-8").write(htmlout)
print("Documentacion regenerada en " + out_path)
PYEOF
