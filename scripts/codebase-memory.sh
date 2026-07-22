#!/usr/bin/env bash
# codebase-memory.sh - Index a repo into the code graph and wire the workspace
# .mcp.json, handling BOTH deployment modes without ever blocking onboarding:
#
#   - Direct engine: the /repo-add skill (agent) calls the MCP `index_repository`
#     tool. This script only prints guidance for that path.
#   - Fleet / Postgres facade (read-only): `index_repository` is not exposed
#     (returns -32601), so this script seeds the repo through the fleet's own
#     CLI and points a gitignored workspace .mcp.json at the seeded project.
#
# Everything fleet-specific is CONFIGURED in .env (see .env.example); nothing is
# hardcoded. Compatible with bash 3.2.
#
# Usage:
#   ./scripts/codebase-memory.sh index <repo>       # seed (fleet) + .mcp.json
#   ./scripts/codebase-memory.sh mcp-config [repo…] # (re)write .mcp.json entries
#   ./scripts/codebase-memory.sh mode               # print the resolved mode
#
# Config (.env):
#   CBM_MODE            auto (default) | fleet | direct | off
#   CBM_FLEET_SEED      seed command template; `{repo}` -> repos/<name>
#                       (its presence enables fleet mode under CBM_MODE=auto)
#   CBM_FLEET_URL       fleet gateway base URL, e.g. http://127.0.0.1:8787
#   CBM_FLEET_TOKEN     bearer token for the fleet gateway
#   CBM_FLEET_PROJECT   project-id template; `{name}` and `{abspath_dashes}`
#                       (default: {abspath_dashes})
#   CBM_MCP_FILE        workspace MCP config path (default: .mcp.json)
set -u
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh
load_env 2>/dev/null || true

CBM_MODE="${CBM_MODE:-auto}"
CBM_MCP_FILE="${CBM_MCP_FILE:-.mcp.json}"
CBM_FLEET_PROJECT="${CBM_FLEET_PROJECT:-{abspath_dashes}}"

resolve_mode() {  # prints: fleet | direct | off
  case "${CBM_MODE}" in
    off)    echo "off" ;;
    fleet)  echo "fleet" ;;
    direct) echo "direct" ;;
    auto|*) if [ -n "${CBM_FLEET_SEED:-}" ]; then echo "fleet"; else echo "direct"; fi ;;
  esac
}

# fleet project id for a repo, from the template
project_id() {  # <name>
  _name="$1"; _abs="$(cd "repos/${_name}" 2>/dev/null && pwd || echo "repos/${_name}")"
  _dashes="$(printf '%s' "${_abs}" | sed 's#^/##; s#[/ ]#-#g')"
  printf '%s' "${CBM_FLEET_PROJECT}" | sed "s#{name}#${_name}#g; s#{abspath_dashes}#${_dashes}#g"
}

# upsert one server entry into CBM_MCP_FILE (safe JSON via python)
mcp_upsert() {  # <name>
  _name="$1"; _pid="$(project_id "${_name}")"
  if [ -z "${CBM_FLEET_URL:-}" ]; then
    echo "   (skip .mcp.json: set CBM_FLEET_URL to wire the MCP endpoint)"; return 0
  fi
  CBM_MCP_FILE="${CBM_MCP_FILE}" NAME="${_name}" PID="${_pid}" \
  URL="${CBM_FLEET_URL%/}" TOKEN="${CBM_FLEET_TOKEN:-}" python3 - <<'PY'
import json, os
path = os.environ["CBM_MCP_FILE"]; name = os.environ["NAME"]; pid = os.environ["PID"]
url = os.environ["URL"] + "/mcp/" + pid; token = os.environ["TOKEN"]
try:
    doc = json.load(open(path))
    if not isinstance(doc, dict): doc = {}
except Exception:
    doc = {}
servers = doc.setdefault("mcpServers", {})
entry = {"type": "http", "url": url}
if token: entry["headers"] = {"Authorization": "Bearer " + token}
servers["cbm-" + name] = entry
with open(path, "w") as f:
    json.dump(doc, f, indent=2); f.write("\n")
print("   .mcp.json: cbm-%s -> %s" % (name, url))
PY
}

cmd_index() {  # <name>
  _name="${1:-}"; [ -n "${_name}" ] || { echo "ERROR - index needs <repo>"; return 2; }
  _mode="$(resolve_mode)"
  case "${_mode}" in
    off)
      echo ">> codebase-memory: disabled (CBM_MODE=off)"; return 0 ;;
    direct)
      echo ">> codebase-memory: direct-engine mode — the /repo-add skill runs"
      echo "   index_repository via MCP. (Set CBM_FLEET_SEED in .env for fleet"
      echo "   mode; see docs/codebase-memory-setup.md.)"
      return 0 ;;
    fleet)
      _cmd="$(printf '%s' "${CBM_FLEET_SEED}" | sed "s#{repo}#repos/${_name}#g")"
      echo ">> codebase-memory: seeding '${_name}' into the fleet…"
      echo "   \$ ${_cmd}"
      if sh -c "${_cmd}"; then
        mcp_upsert "${_name}"
        echo ">> codebase-memory: '${_name}' seeded + wired."
      else
        echo "WARN - fleet seed failed for '${_name}'; onboarding continues."
        echo "       Fix CBM_FLEET_SEED (.env) or seed manually. See"
        echo "       docs/codebase-memory-setup.md. Indexing pending."
      fi
      return 0 ;;
  esac
}

cmd_mcp_config() {  # [name…]
  if [ -n "${CBM_FLEET_URL:-}" ]; then :; else
    echo "ERROR - mcp-config needs CBM_FLEET_URL (and usually CBM_FLEET_TOKEN) in .env"; return 2
  fi
  _list="$*"; [ -n "${_list}" ] || _list="$(registry_repos 2>/dev/null)"
  for n in ${_list}; do mcp_upsert "${n}"; done
  echo ">> codebase-memory: .mcp.json updated (${CBM_MCP_FILE})."
}

case "${1:-}" in
  index)      shift; cmd_index "$@" ;;
  mcp-config) shift; cmd_mcp_config "$@" ;;
  mode)       resolve_mode ;;
  -h|--help|"") sed -n '/^# Usage:/,/^set -u/p' "$0" | sed '$d;s/^# \{0,1\}//' ;;
  *) echo "ERROR - unknown command: $1"; exit 2 ;;
esac
