#!/usr/bin/env bash
# docs.sh - Genera la documentacion HTML derivada del workspace en sus dos
# ediciones: docs/arquitectura.html (ES) y docs/architecture.en.html (EN),
# desde templates/docs-arquitectura.html y templates/docs-architecture.en.html.
# El catalogo VIVO (skills, agentes, reglas, scripts, topologia, RN, specs,
# DORA) se recolecta UNA vez y se inyecta en ambas; los rotulos generados
# (cabeceras, "sin datos"/"no data") salen de un diccionario por idioma.
# La prosa estable vive en cada plantilla (RN-G1, RN-F4).
# Compatible con bash 3.2. Uso:
#   ./scripts/docs.sh [--root <workspace>] [--check]
#   --check: exit 1 si alguna edicion difiere de lo recalculado (CI).
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

[ -f "templates/docs-arquitectura.html" ] || { echo "ERROR: no existe templates/docs-arquitectura.html" >&2; exit 1; }
mkdir -p docs

# ---- topologia: derivada del registro via repo-lib (RN-G1) ----
DATA=$(mktemp)
trap 'rm -f "${DATA}"' EXIT
for name in $(registry_repos 2>/dev/null); do
  prov=$(registry_get "${name}" provider 2>/dev/null || echo "")
  role=$(registry_get "${name}" role 2>/dev/null || echo "")
  orden=$(registry_get "${name}" deploy_order 2>/dev/null || echo "")
  dom=$(registry_get "${name}" domain 2>/dev/null || echo "")
  clonado="no"; [ -d "repos/${name}/.git" ] && clonado="si"
  echo "TOPO|${name}|${prov}|${role}|${orden}|${dom}|${clonado}" >> "${DATA}"
done

python3 - "${DATA}" "${CHECK}" <<'PYEOF'
import glob, html, os, re, sys
from datetime import date

data_path, check = sys.argv[1:3]
esc = html.escape

PARES = [
    ("templates/docs-arquitectura.html", "docs/arquitectura.html", "es"),
    ("templates/docs-architecture.en.html", "docs/architecture.en.html", "en"),
]

S = {
  "es": {
    "sello": "[GENERADO v1] {} · scripts/docs.sh — no editar a mano",
    "sin_datos": "sin datos ({})",
    "clonado": {"si": "sí", "no": "no"},
    "sin_desc_skill": "(sin descripción — completar frontmatter)",
    "sin_desc": "(sin descripción)",
    "sin_desc_script": "(sin descripción de cabecera)",
    "topo_h": ["Repo", "Proveedor", "Rol", "Orden despliegue", "Dominio", "Clonado"],
    "topo_v": "registro sin repos — dar de alta con /repo-add",
    "skills_h": ["Comando", "Qué hace (frontmatter)"],
    "skills_v": "sin skills en .claude/skills",
    "agentes_h": ["Agente", "Fase y propósito"],
    "agentes_v": "sin agentes en .claude/agents",
    "reglas_h": ["Archivo", "Regla", "Estándares base"],
    "reglas_v": "sin reglas en .claude/rules",
    "scripts_h": ["Script", "Qué hace"],
    "scripts_v": "sin scripts",
    "rn_h": ["ID", "Regla", "Dominio", "Origen", "Vigente desde"],
    "rn_v": "sin reglas registradas en knowledge/business-rules.md",
    "specs_h": ["Archivo", "Spec", "Estado"],
    "specs_v": "sin specs en specs/",
    "dora_v": "knowledge/usage.md sin bloque DORA — correr scripts/dora.sh",
  },
  "en": {
    "sello": "[GENERATED v1] {} · scripts/docs.sh — do not edit by hand",
    "sin_datos": "no data ({})",
    "clonado": {"si": "yes", "no": "no"},
    "sin_desc_skill": "(no description — fill in the frontmatter)",
    "sin_desc": "(no description)",
    "sin_desc_script": "(no header description)",
    "topo_h": ["Repo", "Provider", "Role", "Deploy order", "Domain", "Cloned"],
    "topo_v": "no repos registered — add one with /repo-add",
    "skills_h": ["Command", "What it does (frontmatter)"],
    "skills_v": "no skills under .claude/skills",
    "agentes_h": ["Agent", "Phase and purpose"],
    "agentes_v": "no agents under .claude/agents",
    "reglas_h": ["File", "Rule", "Base standards"],
    "reglas_v": "no rules under .claude/rules",
    "scripts_h": ["Script", "What it does"],
    "scripts_v": "no scripts",
    "rn_h": ["ID", "Rule", "Domain", "Origin", "In force since"],
    "rn_v": "no rules registered in knowledge/business-rules.md",
    "specs_h": ["File", "Spec", "Status"],
    "specs_v": "no specs under specs/",
    "dora_v": "knowledge/usage.md has no DORA block — run scripts/dora.sh",
  },
}

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

# ---------- recoleccion (una sola vez; datos crudos, sin idioma) ----------
topo = []
for linea in open(data_path, encoding="utf-8"):
    p = linea.rstrip("\n").split("|")
    if p[0] == "TOPO":
        topo.append(p[1:7])  # name, prov, role, orden, dom, clonado(si/no)

skills = []
for f in sorted(glob.glob(".claude/skills/*/SKILL.md")):
    fm = frontmatter(f)
    nombre = fm.get("name") or os.path.basename(os.path.dirname(f))
    skills.append((nombre, fm.get("description")))

agentes = []
for f in sorted(glob.glob(".claude/agents/*.md")):
    fm = frontmatter(f)
    nombre = fm.get("name") or os.path.splitext(os.path.basename(f))[0]
    agentes.append((nombre, fm.get("description")))

reglas = []
for f in sorted(glob.glob(".claude/rules/*.md")):
    titulo = base = ""
    for linea in open(f, encoding="utf-8"):
        if not titulo and linea.startswith("# "):
            titulo = linea[2:].strip()
        elif not base and linea.startswith("> "):
            base = linea[2:].strip()
        if titulo and base:
            break
    reglas.append((os.path.basename(f), titulo, base))

scripts = []
for f in sorted(glob.glob("scripts/*.sh")):
    desc = None
    for linea in open(f, encoding="utf-8"):
        m = re.match(r"#\s*[\w.-]+\.sh\s*-\s*(.+)", linea)
        if m:
            desc = m.group(1).strip()
            break
    scripts.append((os.path.basename(f), desc))

rn = []
try:
    for linea in open("knowledge/business-rules.md", encoding="utf-8"):
        m = re.match(r"\|\s*(RN-[\w-]+)\s*\|(.*)", linea)
        if m and "<ej" not in m.group(2):
            celdas = [c.strip() for c in m.group(2).split("|") if c.strip() != ""]
            rn.append([m.group(1)] + celdas[:4])
except FileNotFoundError:
    pass

especs = []
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
    especs.append((os.path.basename(f), titulo, estado or "?"))

dora_md = None
try:
    uso = open("knowledge/usage.md", encoding="utf-8").read()
    m = re.search(r"<!-- DORA:BEGIN -->\n?(.*?)\n?<!-- DORA:END -->", uso, re.S)
    if m and m.group(1).strip():
        dora_md = m.group(1).strip()
except FileNotFoundError:
    pass

# ---------- render por idioma ----------
def tabla(cabeceras, filas, vacio, s):
    if not filas:
        return '<p class="muted">%s</p>' % esc(s["sin_datos"].format(vacio))
    out = ['<div class="wide"><table>',
           "<tr>" + "".join(f"<th>{esc(c)}</th>" for c in cabeceras) + "</tr>"]
    out += ["<tr>" + "".join(f"<td>{v}</td>" for v in fila) + "</tr>" for fila in filas]
    out.append("</table></div>")
    return "\n".join(out)

def render(lang):
    s = S[lang]
    valores = {}
    valores["SELLO"] = s["sello"].format(date.today().isoformat())
    valores["TOPOLOGIA"] = tabla(s["topo_h"],
        [[esc(n), esc(p), esc(r), esc(o), esc(d), esc(s["clonado"].get(c, c))]
         for n, p, r, o, d, c in topo], s["topo_v"], s)
    valores["SKILLS"] = tabla(s["skills_h"],
        [[f"<code>/{esc(n)}</code>",
          esc(d) if d else f'<em>{esc(s["sin_desc_skill"])}</em>'] for n, d in skills],
        s["skills_v"], s)
    valores["AGENTES"] = tabla(s["agentes_h"],
        [[f"<code>{esc(n)}</code>",
          esc(d) if d else f'<em>{esc(s["sin_desc"])}</em>'] for n, d in agentes],
        s["agentes_v"], s)
    valores["REGLAS"] = tabla(s["reglas_h"],
        [[f"<code>{esc(a)}</code>", esc(t), esc(b)] for a, t, b in reglas],
        s["reglas_v"], s)
    valores["SCRIPTS"] = tabla(s["scripts_h"],
        [[f"<code>{esc(a)}</code>",
          esc(d) if d else f'<em>{esc(s["sin_desc_script"])}</em>'] for a, d in scripts],
        s["scripts_v"], s)
    valores["REGLAS_NEGOCIO"] = tabla(s["rn_h"],
        [[f"<code>{esc(f[0])}</code>"] + [esc(c) for c in f[1:]] for f in rn],
        s["rn_v"], s)
    valores["SPECS"] = tabla(s["specs_h"],
        [[f"<code>{esc(a)}</code>", esc(t), esc(e)] for a, t, e in especs],
        s["specs_v"], s)
    if dora_md is None:
        valores["DORA"] = '<p class="muted">%s</p>' % esc(s["sin_datos"].format(s["dora_v"]))
    else:
        piezas, celdas_md = [], []
        for linea in dora_md.splitlines():
            if linea.startswith("|"):
                if "---" in linea:
                    continue
                celdas_md.append(["<td>%s</td>" % esc(c.strip())
                                  for c in linea.strip("|").split("|")])
            elif linea.strip():
                piezas.append(f'<p class="muted">{esc(linea.strip())}</p>')
        if celdas_md:
            cab = "".join(celdas_md[0]).replace("<td>", "<th>").replace("</td>", "</th>")
            cuerpo = "".join("<tr>%s</tr>" % "".join(f) for f in celdas_md[1:])
            piezas.append(f'<div class="wide"><table><tr>{cab}</tr>{cuerpo}</table></div>')
        valores["DORA"] = "\n".join(piezas)
    return valores

def sin_sello(texto):  # la fecha de generacion no cuenta como drift
    return re.sub(r"\[GENERA(?:DO|TED) v1\] \d{4}-\d{2}-\d{2}", "[SELLO]", texto)

drift = escritos = 0
for tpl_path, out_path, lang in PARES:
    if not os.path.exists(tpl_path):
        print(f"aviso: {tpl_path} no existe — se omite la edicion '{lang}'")
        continue
    salida = open(tpl_path, encoding="utf-8").read()
    for clave, valor in render(lang).items():
        salida = salida.replace("{{%s}}" % clave, valor)
    vigente = open(out_path, encoding="utf-8").read() if os.path.exists(out_path) else None
    if check == "1":
        if vigente is None or sin_sello(vigente) != sin_sello(salida):
            print(f"DRIFT: {out_path} difiere de lo recalculado. Correr scripts/docs.sh")
            drift += 1
        continue
    if vigente == salida:
        continue
    open(out_path, "w", encoding="utf-8").write(salida)
    escritos += 1
    print("Regenerado " + out_path)

if check == "1":
    if drift:
        sys.exit(1)
    print("OK: documentacion en sincronia")
elif not escritos:
    print("Sin cambios: documentacion ya en sincronia")
PYEOF
