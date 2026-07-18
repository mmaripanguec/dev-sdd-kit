#!/usr/bin/env bash
# repo-lib.sh - Libreria compartida del registro de repos (repos.yaml).
# Se carga con `source` desde setup.sh, repo-add.sh y generate-as-is.sh.
# Compatible con bash 3.2 (macOS): sin arrays asociativos, ${var} con llaves.
#
# El registro es la UNICA fuente de verdad de la topologia (RN-G1 de
# specs/2026-07-generalizacion-workspace.md): nombres de repos, proveedor,
# roles, entrypoint y orden de despliegue salen SIEMPRE de aqui.

REGISTRY_FILE="${REGISTRY_FILE:-repos.yaml}"

# Todo el parseo/escritura del YAML vive en un unico interprete python3
# (prerequisito del workspace). Usa PyYAML si existe; si no, un parser del
# subconjunto exacto que escribe registry_upsert - sin dependencias nuevas.
_registry_py() {
  python3 - "${REGISTRY_FILE}" "$@" <<'PYEOF'
import json, sys

path = sys.argv[1]
cmd = sys.argv[2] if len(sys.argv) > 2 else "json"
args = sys.argv[3:]

PROVIDERS = ("github", "gitlab", "bitbucket", "local")
REPO_FIELDS = ("name", "url", "provider", "role", "deploy_order", "domain",
               "vcs", "pack")
SYSTEM_FIELDS = ("name", "entrypoint", "pack_prefix")


def parse_mini(text):
    """Subconjunto YAML de repos.yaml: system{...} + lista repos[- k: v]."""
    system, repos, cur, section = {}, [], None, None
    for raw in text.splitlines():
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        if s == "system:":
            section = "system"
            continue
        if s == "repos:":
            section = "repos"
            continue
        if section == "repos" and s.startswith("- "):
            cur = {}
            repos.append(cur)
            s = s[2:].strip()
            if not s:
                continue
        if ":" not in s:
            continue
        k, v = s.split(":", 1)
        v = v.strip()
        if v and v[0] in "\"'" and len(v) > 1 and v[-1] == v[0]:
            v = v[1:-1]
        elif " #" in v:
            v = v.split(" #", 1)[0].strip()
        if section == "system":
            system[k.strip()] = v
        elif section == "repos" and cur is not None:
            cur[k.strip()] = v
    return {"system": system, "repos": repos}


def load():
    try:
        text = open(path, encoding="utf-8").read()
    except OSError:
        return None
    try:
        import yaml  # opcional
        return yaml.safe_load(text) or {}
    except ImportError:
        return parse_mini(text)
    except Exception as e:
        print(f"REGISTRY_INVALID: YAML ilegible: {e}")
        sys.exit(4)


def dump(data):
    sysd, repos = data.get("system") or {}, data.get("repos") or []
    out = [
        "# Registro de repositorios del sistema - UNICA fuente de verdad de la topologia.",
        "# Alta de repos: ./scripts/repo-add.sh <url-o-ruta>  (o la skill /repo-add)",
        "# Campos: name/url/provider obligatorios; role, deploy_order (menor = antes),",
        "# domain (generic|banking) opcionales. Regenerado por registry_upsert.",
        "system:",
        f"  name: {sysd.get('name', 'sistema')}",
    ]
    for f in ("entrypoint", "pack_prefix"):
        if sysd.get(f):
            out.append(f"  {f}: {sysd[f]}")
    out.append("repos:")
    for r in repos:
        out.append(f"  - name: {r['name']}")
        for f in [f for f in REPO_FIELDS if f != "name"]:
            if r.get(f) not in (None, ""):
                v = r[f]
                if f == "role":
                    v = '"%s"' % str(v).replace('"', "'")
                out.append(f"    {f}: {v}")
    open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")


data = load()

if cmd == "upsert":
    # args: k=v ... con name/url/provider obligatorios;
    # extras: entrypoint=true, system_name=X (solo se aplican si vienen)
    kv = dict(a.split("=", 1) for a in args)
    if data is None:
        data = {"system": {}, "repos": []}
    sysd = data.setdefault("system", {})
    repos = data.setdefault("repos", [])
    entry = {f: kv[f] for f in REPO_FIELDS if kv.get(f)}
    existing = next((r for r in repos if r.get("name") == entry["name"]), None)
    if existing:
        existing.update(entry)
        print("updated")
    else:
        if not entry.get("deploy_order"):
            orders = [int(r["deploy_order"]) for r in repos
                      if str(r.get("deploy_order", "")).isdigit()]
            entry["deploy_order"] = str(max(orders) + 1 if orders else 1)
        repos.append(entry)
        print("added")
    if kv.get("system_name"):
        sysd["name"] = kv["system_name"]
    elif not sysd.get("name"):
        sysd["name"] = entry["name"]
    if kv.get("pack_prefix"):
        sysd["pack_prefix"] = kv["pack_prefix"]
    if kv.get("entrypoint") == "true" or not sysd.get("entrypoint"):
        sysd["entrypoint"] = entry["name"]
    dump(data)
    sys.exit(0)

if data is None:
    print("REGISTRY_MISSING")
    sys.exit(3)

system = data.get("system") or {}
repos = [r for r in (data.get("repos") or []) if isinstance(r, dict)]

if cmd == "json":
    print(json.dumps(data, ensure_ascii=False))
elif cmd == "validate":
    errors = []
    if not repos:
        errors.append("no hay repos declarados bajo 'repos:'")
    names = []
    for i, r in enumerate(repos):
        label = r.get("name") or f"repos[{i}]"
        for field in ("name", "url", "provider"):
            if not r.get(field):
                errors.append(f"{label}: falta el campo obligatorio '{field}'")
        if r.get("name"):
            if r["name"] in names:
                errors.append(f"{label}: nombre duplicado")
            names.append(r["name"])
        if r.get("provider") and r["provider"] not in PROVIDERS:
            errors.append(
                f"{label}: provider '{r['provider']}' no soportado ({'|'.join(PROVIDERS)})")
        if r.get("vcs") and r["vcs"] not in ("git", "none"):
            errors.append(f"{label}: vcs '{r['vcs']}' no soportado (git|none)")
    if not system.get("name"):
        errors.append("falta system.name")
    ep = system.get("entrypoint")
    if ep and ep not in names:
        errors.append(f"system.entrypoint '{ep}' no es un repo registrado")
    if errors:
        for e in errors:
            print(f"REGISTRY_INVALID: {e}")
        sys.exit(4)
    print("OK")
elif cmd == "system":
    print(system.get(args[0]) or "")
elif cmd == "repos":
    for r in repos:
        if r.get("name"):
            print(r["name"])
elif cmd == "repos-by-deploy":
    def order(r):
        v = str(r.get("deploy_order", ""))
        return (0, int(v)) if v.isdigit() else (1, 0)
    for r in sorted((r for r in repos if r.get("name")), key=order):
        print(r["name"])
elif cmd == "get":
    for r in repos:
        if r.get("name") == args[0]:
            print(r.get(args[1]) or "")
            break
else:
    print(f"REGISTRY_INVALID: comando interno desconocido '{cmd}'")
    sys.exit(2)
PYEOF
}

# ---------- API del registro ----------
registry_validate() {
  _rl_out=$(_registry_py validate 2>&1) && return 0
  case "${_rl_out}" in
    REGISTRY_MISSING*)
      echo "ERROR - no existe ${REGISTRY_FILE} en $(pwd)."
      echo "        Registra el primer repo con:  ./scripts/repo-add.sh <url-o-ruta>"
      echo "        (o desde Claude Code: /repo-add <url-o-ruta>)" ;;
    *)
      echo "ERROR - ${REGISTRY_FILE} invalido:"
      printf '%s\n' "${_rl_out}" | sed 's/^REGISTRY_INVALID: /  - /' ;;
  esac
  return 1
}
registry_system()          { _registry_py system "$1"; }
registry_repos()           { _registry_py repos; }
registry_repos_by_deploy() { _registry_py repos-by-deploy; }
registry_get()             { _registry_py get "$1" "$2"; }
# registry_upsert name=N url=U provider=P [role=R] [deploy_order=N] [domain=D]
#                 [entrypoint=true] [system_name=S]
registry_upsert()          { _registry_py upsert "$@"; }

# ---------- Entorno y proveedores ----------
load_env() {
  if [ -f .env ]; then
    set -a
    . ./.env
    set +a
  fi
}

# Proveedor inferido de una URL o ruta (vacio si no se reconoce el host)
provider_for_url() {
  case "$1" in
    *bitbucket.org*) echo "bitbucket" ;;
    *github.com*)    echo "github" ;;
    *gitlab.*|*//gitlab*) echo "gitlab" ;;
    /*|~*|.*)        echo "local" ;;
    *)               echo "" ;;
  esac
}

host_of_url() {
  case "$1" in
    git@*)            _h="${1#git@}";  printf '%s' "${_h%%[:/]*}" ;;
    ssh://*)          _h="${1#ssh://}"; _h="${_h#git@}"; printf '%s' "${_h%%[:/]*}" ;;
    http://*|https://*) _h="${1#*://}"; printf '%s' "${_h%%/*}" ;;
    *)                printf '%s' "" ;;
  esac
}

token_var_for() {
  case "$1" in
    bitbucket) echo "BITBUCKET_TOKEN" ;;
    github)    echo "GITHUB_TOKEN" ;;
    gitlab)    echo "GITLAB_TOKEN" ;;
    *)         echo "" ;;
  esac
}

token_for() {
  case "$1" in
    bitbucket) printf '%s' "${BITBUCKET_TOKEN:-}" ;;
    github)    printf '%s' "${GITHUB_TOKEN:-}" ;;
    gitlab)    printf '%s' "${GITLAB_TOKEN:-}" ;;
  esac
}

# Usuario git para el token, segun las reglas de cada proveedor.
# Bitbucket conserva la logica v5: API tokens de Atlassian CON scopes (ATATT
# largos) exigen el usuario especial x-bitbucket-api-token-auth en git.
git_user_for() {
  case "$1" in
    bitbucket)
      _u="${BITBUCKET_GIT_USER:-${BITBUCKET_USER:-}}"
      case "${BITBUCKET_TOKEN:-}" in
        ATATT*)
          if [ ${#BITBUCKET_TOKEN} -gt 100 ] && [ -z "${BITBUCKET_GIT_USER:-}" ]; then
            _u="x-bitbucket-api-token-auth"
          fi ;;
      esac
      printf '%s' "${_u}" ;;
    github) printf '%s' "${GITHUB_USER:-x-access-token}" ;;
    gitlab) printf '%s' "${GITLAB_USER:-oauth2}" ;;
  esac
}

# git con credenciales EFIMERAS por proveedor: el token se inyecta al vuelo
# via credential helper y nunca queda en .git/config, URLs ni historial.
# El insteadOf identidad (prefijo mas largo gana) anula reescrituras
# corporativas HTTPS->SSH que romperian el modo token.
# Uso: git_auth <provider> <host> <args de git...>
git_auth() {
  _prov="$1"; _host="$2"; shift 2
  GIT_AUTH_USER="$(git_user_for "${_prov}")" \
  GIT_AUTH_TOKEN="$(token_for "${_prov}")" \
  git -c credential.helper= \
      -c credential.helper='!f() { printf "username=%s\npassword=%s\n" "${GIT_AUTH_USER}" "${GIT_AUTH_TOKEN}"; }; f' \
      -c url."https://${_host}/".insteadOf="https://${_host}/" \
      "$@"
}

# Huella corta de un snapshot sin .git (rutas+tamano+mtime; suficiente para
# detectar cambios sin hashear el contenido completo).
huella_snapshot() {
  find -L "$1" -type f -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null \
    | sort | while IFS= read -r _f; do
        stat -f "%N %z %m" "${_f}" 2>/dev/null || stat -c "%n %s %Y" "${_f}" 2>/dev/null
      done | shasum -a 256 | cut -c1-12
}

# Sello de procedencia de un repo registrado: commit git corto si hay .git,
# huella de snapshot si no (repos exportados sin historia).
stamp_of_repo() {
  if git -C "repos/$1" rev-parse --short HEAD > /dev/null 2>&1; then
    git -C "repos/$1" rev-parse --short HEAD
  else
    huella_snapshot "repos/$1"
  fi
}

# Prefijo de packs de contexto del sistema (default: nombre del sistema)
registry_pack_prefix() {
  _pp="$(registry_system pack_prefix)"
  if [ -n "${_pp}" ]; then printf '%s' "${_pp}"; else registry_system name; fi
}

# Nombre del pack de contexto de un repo: campo `pack` o "<prefijo>-<repo>"
pack_name_for_repo() {
  _pk="$(registry_get "$1" pack)"
  if [ -n "${_pk}" ]; then printf '%s' "${_pk}"; else printf '%s-%s' "$(registry_pack_prefix)" "$1"; fi
}

# Siembra el CLAUDE.md de un repo desde la plantilla si no existe.
seed_repo_claude_md() {
  _name="$1"
  if [ ! -f "repos/${_name}/CLAUDE.md" ] && [ -f "templates/CLAUDE.repo.md" ]; then
    sed "s/{{REPO}}/${_name}/g" templates/CLAUDE.repo.md > "repos/${_name}/CLAUDE.md"
    echo "   -> CLAUDE.md sembrado en ${_name} (completar y commitear en ESE repo)"
  fi
}
