#!/bin/bash
# repo-tree.sh - Derived file-structure tree of a repository, for the
# architecture/context documentation (development view complement).
# Tracked files only (respects .gitignore); recursive file count per
# directory; root-level files listed individually; deterministic output.
#   ./scripts/repo-tree.sh <path> [depth]     (depth default: 2)
set -u

DIR="${1:-}"
DEPTH="${2:-2}"

if [ -z "${DIR}" ] || [ ! -d "${DIR}" ]; then
  echo "ERROR: no such directory: '${DIR}'"
  echo "usage: $0 <path> [depth]"
  exit 1
fi

if git -C "${DIR}" rev-parse --git-dir >/dev/null 2>&1; then
  LIST=$(git -C "${DIR}" ls-files)
else
  # Fallback for non-git dirs: best effort, skipping VCS internals.
  LIST=$(cd "${DIR}" && find . -type f -not -path './.git/*' | sed 's|^\./||' | sort)
fi

# El programa python viaja por heredoc (ocupa stdin): la lista va por archivo.
LISTFILE=$(mktemp)
trap 'rm -f "${LISTFILE}"' EXIT
printf '%s\n' "${LIST}" > "${LISTFILE}"

LISTFILE="${LISTFILE}" DEPTH="${DEPTH}" NAME="$(basename "$(cd "${DIR}" && pwd)")" python3 - <<'PY'
import os
from collections import defaultdict

depth = max(1, int(os.environ["DEPTH"]))
name = os.environ["NAME"]
files = [l.strip() for l in open(os.environ["LISTFILE"]) if l.strip()]

counts = defaultdict(int)       # dir tuple -> recursive tracked-file count
children = defaultdict(set)     # dir tuple -> immediate child dir names
rootfiles = []

for f in files:
    parts = f.split("/")
    if len(parts) == 1:
        rootfiles.append(f)
        continue
    for i in range(1, len(parts)):
        d = tuple(parts[:i])
        counts[d] += 1
        children[tuple(parts[:i - 1])].add(parts[i - 1])

print(f"{name}/ — {len(files)} files")

def render(dpath, depth_left, prefix):
    dirs = sorted(children.get(dpath, ()))
    fils = sorted(rootfiles) if dpath == () else []
    entries = [(d, True) for d in dirs] + [(f, False) for f in fils]
    for i, (nm, isdir) in enumerate(entries):
        last = i == len(entries) - 1
        glyph = "└── " if last else "├── "
        if isdir:
            print(f"{prefix}{glyph}{nm}/ ({counts[dpath + (nm,)]})")
            if depth_left > 1:
                render(dpath + (nm,), depth_left - 1,
                       prefix + ("    " if last else "│   "))
        else:
            print(f"{prefix}{glyph}{nm}")

render((), depth, "")
PY
