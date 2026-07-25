#!/usr/bin/env python3
"""app-architecture-html.py — HTML twin of an APPLICATION architecture report.

Renders knowledge/architecture/<app>.md with the corporate template
(templates/knowledge-architecture-app.html), reusing the md->html converter
embedded in scripts/generate-architecture.sh (extracted at runtime — single
source of truth, no duplicated logic). The document header and the provenance
box are built from the report's YAML front-matter.

Usage:  python3 scripts/app-architecture-html.py <app> [lang]
        (app = basename of knowledge/architecture/<app>.md; lang default: en)
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = sys.argv[1] if len(sys.argv) > 1 else ""
LANG = sys.argv[2] if len(sys.argv) > 2 else "en"

if not APP:
    sys.exit("usage: app-architecture-html.py <app> [lang]")

md_path = os.path.join(ROOT, "knowledge", "architecture", APP + ".md")
if not os.path.isfile(md_path):
    sys.exit(f"ERROR: report not found: {md_path}")

# Reuse the converter from the system generator (single source of truth).
gen = open(os.path.join(ROOT, "scripts", "generate-architecture.sh")).read()
m = re.search(
    r"(# ---------- md -> html[^\n]*----------\n.*?\n    return \"\\n\"\.join\(html\)\n)",
    gen, re.S)
if not m:
    sys.exit("ERROR: could not extract md_to_html from generate-architecture.sh")
ns = {"re": re}
exec(m.group(1), ns)  # defines esc/inline/md_to_html

md = open(md_path).read()

# Front-matter -> header + provenance box.
fm, body, seals = {}, md, []
if md.startswith("---"):
    end = md.index("\n---", 3)
    for ln in md[3:end].splitlines():
        mm = re.match(r"^(\w[\w_-]*):\s*(.*)$", ln)
        if mm:
            fm[mm.group(1)] = mm.group(2).strip().strip('"')
        ms = re.match(r"^\s{2}([\w-]+):\s*(.+)$", ln)
        if ms:
            seals.append((ms.group(1), ms.group(2).strip().strip('"')))
    body = md[end + 4:]

# The template header replaces the report's own H1 + leading blockquote.
body = re.sub(r"^\s*# .*\n", "", body, count=1)
body = re.sub(r"^\s*(?:>.*\n)+", "", body, count=1)

seal_html = " · ".join(
    f"<code>{k} @{v.split(' ')[0].split(';')[0][:60]}</code>" for k, v in seals)
prov = (f"<b>Provenance seals:</b> {seal_html}<br>"
        f"<b>Verified:</b> {fm.get('verificado', fm.get('verified', ''))}<br>"
        f"<b>Standard:</b> {fm.get('standard', 'arc42 + C4 + ISO/IEC/IEEE 42010')} · "
        f"agent-facing source: <code>knowledge/architecture/{APP}.md</code>")

content = ns["md_to_html"](body)
tpl = open(os.path.join(ROOT, "templates", "knowledge-architecture-app.html")).read()
html = (tpl.replace("{{TITLE}}", f"Architecture — {APP}")
           .replace("{{SUBTITLE}}",
                    "AS-IS application architecture · arc42 + C4 · committee-reviewed")
           .replace("{{PROVENANCE}}", prov)
           .replace("{{SYSTEM}}", APP)
           .replace("{{LANG}}", LANG)
           .replace("{{CONTENT}}", content))
out = os.path.join(ROOT, "knowledge", "architecture", APP + ".html")
open(out, "w").write(html)
print(f"OK {out} ({len(html)} bytes)")
