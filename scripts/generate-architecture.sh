#!/usr/bin/env bash
# generate-architecture.sh - Generates the system's AS-IS architecture document
# (arc42 + C4) as part of the knowledge, in .md and .html, so that agents
# consume it as CONTEXT and do NOT have to re-index or re-read the code. Runs
# after indexing (called by generate-as-is.sh) and on demand.
#
# Sources: templates/knowledge-architecture.{md,html} (structure) +
# knowledge/architecture/<system>.narrative.md (curated analysis, maintained by
# /system-map and agents) + data DERIVED from the real code (registry topology,
# stacks, dependencies, counts). bash 3.2 compatible.
#
# Usage:  ./scripts/generate-architecture.sh
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

registry_validate || exit 1
SYSTEM_NAME="$(registry_system name)"
PREFIX="$(registry_pack_prefix)"
LANG_WS="$(registry_system lang 2>/dev/null || true)"; LANG_WS="${LANG_WS:-en}"
FECHA=$(date -u +"%Y-%m-%d %H:%M UTC")

OUT="knowledge/architecture"
mkdir -p "${OUT}"
NARRATIVE="${OUT}/${SYSTEM_NAME}.narrative.md"
TPL_MD="templates/knowledge-architecture.md"
TPL_HTML="templates/knowledge-architecture.html"
TPL_NARR="templates/knowledge-architecture.narrative.md"

[ -f "${TPL_MD}" ]   || { echo "ERROR: missing ${TPL_MD}"; exit 1; }
[ -f "${TPL_HTML}" ] || { echo "ERROR: missing ${TPL_HTML}"; exit 1; }
# Seed the curated narrative from the template on first run.
if [ ! -f "${NARRATIVE}" ]; then
  if [ -f "${TPL_NARR}" ]; then
    cp "${TPL_NARR}" "${NARRATIVE}"
    echo "NOTE: seeded ${NARRATIVE} from the template (author the analysis there,"
    echo "      e.g. via /system-map). The document will show placeholder sections"
    echo "      until it is filled in."
  else
    echo "NOTE: no ${NARRATIVE} and no ${TPL_NARR}; analysis sections will be empty."
  fi
fi

# ---- DERIVED per-repo data -> temp file for python ----
DATA=$(mktemp); trap 'rm -f "${DATA}"' EXIT
for name in $(registry_repos 2>/dev/null); do
  [ -d "repos/${name}" ] || continue
  role=$(registry_get "${name}" role 2>/dev/null || echo "")
  orden=$(registry_get "${name}" deploy_order 2>/dev/null || echo "")
  dom=$(registry_get "${name}" domain 2>/dev/null || echo "")
  stamp=$(stamp_of_repo "${name}" 2>/dev/null || echo "")
  files=$( { git -C "repos/${name}" ls-files 2>/dev/null || true; } | wc -l | tr -d ' ')
  echo "REPO|${name}|${role}|${orden}|${dom}|${stamp}|${files}" >> "${DATA}"
done

SYSTEM_NAME="${SYSTEM_NAME}" PREFIX="${PREFIX}" LANG_WS="${LANG_WS}" \
FECHA="${FECHA}" OUT="${OUT}" NARRATIVE="${NARRATIVE}" \
TPL_MD="${TPL_MD}" TPL_HTML="${TPL_HTML}" \
python3 - "${DATA}" <<'PYEOF'
import os, re, sys, json

data_path = sys.argv[1]
SYSTEM = os.environ["SYSTEM_NAME"]; PREFIX = os.environ["PREFIX"]
LANG = os.environ["LANG_WS"];       FECHA = os.environ["FECHA"]
OUT = os.environ["OUT"];            NARRATIVE = os.environ["NARRATIVE"]
TPL_MD = os.environ["TPL_MD"];      TPL_HTML = os.environ["TPL_HTML"]

# ---------- read derived data ----------
repos = []
with open(data_path) as f:
    for line in f:
        line = line.rstrip("\n")
        if not line.startswith("REPO|"): continue
        _, name, role, orden, dom, stamp, files = line.split("|")
        repos.append(dict(name=name, role=role, orden=orden, dom=dom,
                          stamp=stamp, files=files))

def detect_stack(name):
    base = os.path.join("repos", name)
    gomod = os.path.join(base, "go.mod")
    pkg = os.path.join(base, "package.json")
    if os.path.exists(gomod):
        ver = ""; mods = []
        with open(gomod) as fh:
            for ln in fh:
                m = re.match(r"\s*go\s+([0-9.]+)\s*$", ln)
                if m: ver = m.group(1); continue
                line = ln.strip()
                if line.startswith("module") or line in ("require (", ")", ""):
                    continue
                line = re.sub(r"^require\s+", "", line)          # single-line form
                m2 = re.match(r"([a-z0-9./_-]+\.[a-z0-9]+/[^\s]+)\s+(\S+)", line)
                if m2:
                    mods.append((m2.group(1), m2.group(2)))
        return ("Go " + ver, mods, "go")
    if os.path.exists(pkg):
        try: d = json.load(open(pkg))
        except Exception: d = {}
        deps = d.get("dependencies", {})
        ang = deps.get("@angular/core", ""); ion = deps.get("@ionic/angular", "")
        s = "Node/JS"
        if ang: s = "Angular %s" % ang + (" / Ionic %s" % ion if ion else "")
        return (s, deps, "npm")
    return ("(unknown)", {}, "")

# ---------- derived tables ----------
def repos_table():
    rows = ["| Repo | Role | Stack | Deploy | Domain | Files |",
            "|---|---|---|---:|---|---:|"]
    for r in sorted(repos, key=lambda x: (x["orden"] or "9")):
        stack, _, _ = detect_stack(r["name"])
        rows.append("| `%s` | %s | %s | %s | %s | %s |" % (
            r["name"], r["role"] or "—", stack, r["orden"] or "—",
            r["dom"] or "generic", r["files"]))
    return "\n".join(rows)

def metrics_table():
    rows = ["| Repo | Files (git) | Seal | Graph metric |",
            "|---|---:|---|---|"]
    for r in sorted(repos, key=lambda x: (x["orden"] or "9")):
        rows.append("| `%s` | %s | `%s` | functions/CALLS via `query_graph` |" % (
            r["name"], r["files"], r["stamp"]))
    rows.append("")
    rows.append("> File counts derived from `git ls-files` at indexing time. "
                "Functions, calls and hotpaths live in the code graph "
                "(codebase-memory); do not re-query them unless a question is "
                "undocumented.")
    return "\n".join(rows)

def deps_tables():
    out = []
    for r in sorted(repos, key=lambda x: (x["orden"] or "9")):
        stack, deps, kind = detect_stack(r["name"])
        out.append("### %s — dependencies\n" % r["name"])
        if kind == "go":
            out.append("| Module | Version |\n|---|---|")
            for mod, ver in deps: out.append("| `%s` | `%s` |" % (mod, ver))
            if not deps: out.append("| — | — |")
        elif kind == "npm":
            cats = {}
            for k in deps:
                if k.startswith("@angular"): c = "@angular/*"
                elif k.startswith("@ionic"): c = "@ionic/*"
                elif k.startswith("@awesome-cordova"): c = "@awesome-cordova-plugins/*"
                elif k.startswith("cordova"): c = "cordova-plugin-*"
                elif k.startswith("@capacitor"): c = "@capacitor/*"
                elif "firebase" in k: c = "firebase"
                else: c = "other"
                cats[c] = cats.get(c, 0) + 1
            out.append("| Category | # |\n|---|---:|")
            for c, n in sorted(cats.items(), key=lambda x: -x[1]):
                out.append("| `%s` | %d |" % (c, n))
            out.append("")
            out.append("Total: **%d** dependencies. Exhaustive list in "
                       "`repos/%s/package.json`." % (len(deps), r["name"]))
        else:
            out.append("(no dependency manifest detected)")
        out.append("")
    return "\n".join(out)

# ---------- narrative ----------
sections = {}
if os.path.exists(NARRATIVE):
    txt = open(NARRATIVE).read()
    parts = re.split(r"<!--\s*@@\s*([A-Z_]+)\s*-->", txt)
    for i in range(1, len(parts) - 1, 2):
        sections[parts[i].strip()] = parts[i + 1].strip()

def narrative(key):
    body = sections.get(key, "")
    # drop guidance-only comment bodies from the scaffold
    stripped = re.sub(r"<!--.*?-->", "", body, flags=re.S).strip()
    if not stripped:
        return "_(section pending: author it in %s)_" % os.path.basename(NARRATIVE)
    return body

# ---------- seals ----------
seals_fm = "\n".join("  %s: %s" % (r["name"], r["stamp"]) for r in repos)
seals_inline = " · ".join("`%s @%s`" % (r["name"], r["stamp"]) for r in repos)
gen_tag = "GENERATED"

# ---------- fill MD template ----------
md = open(TPL_MD).read()
repl = {
    "{{SYSTEM}}": SYSTEM, "{{PREFIX}}": PREFIX, "{{LANG}}": LANG,
    "{{FECHA}}": FECHA, "{{GEN_TAG}}": gen_tag,
    "{{SEALS_FRONTMATTER}}": seals_fm, "{{SEALS_INLINE}}": seals_inline,
    "{{REPOS_TABLE}}": repos_table(), "{{METRICS_TABLE}}": metrics_table(),
    "{{DEPS_TABLES}}": deps_tables(), "{{NARRATIVE_FILE}}": NARRATIVE,
}
for k, v in repl.items(): md = md.replace(k, v)
md = re.sub(r"<!--\s*NARRATIVE:\s*([A-Z_]+)\s*-->",
            lambda m: narrative(m.group(1)), md)

md_path = os.path.join(OUT, SYSTEM + ".md")
open(md_path, "w").write(md)

# ---------- md -> html (dependency-free) ----------
def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

def inline(s):
    s = esc(s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', s)
    return s

def md_to_html(text):
    lines = text.split("\n")
    if lines and lines[0].strip() == "---":            # skip YAML frontmatter
        for i in range(1, len(lines)):
            if lines[i].strip() == "---":
                lines = lines[i + 1:]; break
    html = []; i = 0; n = len(lines)
    while i < n:
        st = lines[i].strip()
        if st.startswith("```"):
            lang = st[3:].strip(); body = []; i += 1
            while i < n and lines[i].strip() != "```":
                body.append(lines[i]); i += 1
            i += 1; code = "\n".join(body)
            if lang == "mermaid":
                html.append('<pre class="mermaid">\n%s\n</pre>' % esc(code))
            else:
                html.append("<pre><code>%s</code></pre>" % esc(code))
            continue
        if st.startswith("|") and i + 1 < n and re.match(r"^\s*\|?[\s:|-]+\|?\s*$", lines[i+1]):
            head = [c.strip() for c in st.strip("|").split("|")]; i += 2; rows = []
            while i < n and lines[i].strip().startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")]); i += 1
            t = ['<div class="tablewrap"><table><thead><tr>']
            t += ["<th>%s</th>" % inline(h) for h in head]
            t.append("</tr></thead><tbody>")
            for row in rows:
                t.append("<tr>" + "".join("<td>%s</td>" % inline(c) for c in row) + "</tr>")
            t.append("</tbody></table></div>"); html.append("".join(t)); continue
        if st.startswith(">"):
            body = []
            while i < n and lines[i].strip().startswith(">"):
                body.append(lines[i].strip()[1:].strip()); i += 1
            html.append("<blockquote><p>%s</p></blockquote>" % inline(" ".join(body))); continue
        if st == "---":
            html.append("<hr>"); i += 1; continue
        m = re.match(r"^(#{1,4})\s+(.*)$", st)
        if m:
            lvl = len(m.group(1)); html.append("<h%d>%s</h%d>" % (lvl, inline(m.group(2)), lvl)); i += 1; continue
        if re.match(r"^[-*]\s+", st):
            items = []
            while i < n and re.match(r"^[-*]\s+", lines[i].strip()):
                items.append(re.sub(r"^[-*]\s+", "", lines[i].strip())); i += 1
            html.append("<ul>" + "".join("<li>%s</li>" % inline(it) for it in items) + "</ul>"); continue
        if re.match(r"^\d+\.\s+", st):
            items = []
            while i < n and re.match(r"^\d+\.\s+", lines[i].strip()):
                items.append(re.sub(r"^\d+\.\s+", "", lines[i].strip())); i += 1
            html.append("<ol>" + "".join("<li>%s</li>" % inline(it) for it in items) + "</ol>"); continue
        if st == "":
            i += 1; continue
        para = []
        while i < n and lines[i].strip() != "" and not lines[i].strip().startswith(("|", ">", "#", "```", "- ", "* ")) and lines[i].strip() != "---":
            para.append(lines[i].strip()); i += 1
        if para: html.append("<p>%s</p>" % inline(" ".join(para)))
        else: i += 1
    return "\n".join(html)

content_html = md_to_html(md)
html = (open(TPL_HTML).read().replace("{{SYSTEM}}", SYSTEM)
        .replace("{{LANG}}", LANG).replace("{{CONTENT}}", content_html))
html_path = os.path.join(OUT, SYSTEM + ".html")
open(html_path, "w").write(html)

print("OK - architecture generated:")
print("     %s" % md_path)
print("     %s" % html_path)
PYEOF
