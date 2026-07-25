# codebase-memory (code graph) — setup & troubleshooting

The factory indexes each onboarded repository into a **code knowledge graph**
(the `codebase-memory` MCP server) so that `/repo-map`, `/system-map` and the
as-is/architecture generators can ask structural questions (routes, callers,
dependencies, hotpaths) without re-reading the whole codebase.

There are **two deployment modes**. The one you have determines how indexing
happens — and explains a common, expected error.

## Mode A — Direct engine (single-project MCP)

The MCP server runs the engine locally and exposes the write tool
`index_repository`. This is the default assumed by `/repo-add`.

```
index_repository(repo_path="repos/<name>")     # build/refresh the graph
index_status(project="<name>")                 # coverage & node/edge counts
list_projects()                                 # what is indexed
```

`/repo-add` calls `index_repository` for you and reports the status.

## Mode B — Fleet / Postgres facade (read-only)

In a shared/team setup the MCP is a thin **fleet facade** in front of a central
Postgres graph. It exposes **only read tools** (`search_graph`, `query_graph`,
`trace_path`, `get_architecture`, `get_code_snippet`, …). It does **not** expose
`index_repository`.

### Expected error (not a bug)

Calling a write tool against the facade returns:

```
MCP error -32601: 'index_repository' has no equivalent in the fleet graph
```

This is **expected**. Indexing in fleet mode is done out-of-band by the fleet's
own seed/ingest workflow, not through the MCP write path. `/repo-add` treats
this as "indexing pending" and continues — the as-is map and context packs are
built from grep and still work.

### How to index in fleet mode

**Automatic (recommended).** Configure the fleet once in `.env` and
`repo-add.sh` seeds each repo and writes the workspace `.mcp.json` for you —
no manual steps. The relevant `.env` variables (see `.env.example`):

```bash
CBM_MODE=auto                      # auto | fleet | direct | off
CBM_FLEET_SEED=uv run python /path/to/flota/run_local.py seed --repo {repo}
CBM_FLEET_URL=http://127.0.0.1:8787
CBM_FLEET_TOKEN=<your-dev-token>
# CBM_FLEET_PROJECT={abspath_dashes}   # project-id template; default shown
```

With `CBM_FLEET_SEED` set, `auto` resolves to **fleet** mode: on `/repo-add`
(or `./scripts/repo-add.sh <url>`), the factory runs the seed command with
`{repo}` → `repos/<name>` and upserts a `cbm-<name>` entry into `.mcp.json`.
You can also run it directly:

```bash
./scripts/codebase-memory.sh index <name>       # seed one repo + wire .mcp.json
./scripts/codebase-memory.sh mcp-config          # (re)write .mcp.json for all repos
./scripts/codebase-memory.sh mode                # print the resolved mode
```

It never blocks onboarding: if the seed command fails or the fleet is down, it
prints a warning and continues; the as-is map, packs and architecture document
are still built from static analysis.

**Manual.** If you prefer not to configure `.env`, seed and wire by hand:

```bash
run_local.py seed --repo repos/<name>            # seed the project
run_local.py list                                # confirm it is present
```

Then create `.mcp.json` with one HTTP entry per project (URL selects the
project, token is your fleet dev token):

```json
{
  "mcpServers": {
    "cbm-<name>": {
      "type": "http",
      "url": "http://127.0.0.1:8787/mcp/<fleet-project-id>",
      "headers": { "Authorization": "Bearer <token>" }
    }
  }
}
```

`.mcp.json` is **gitignored** (machine-specific paths + token). Re-seed after
structural code changes (new modules, endpoints, migrations); the graph does
not refresh itself.

### Remote fleet — Cloud Run deployment (codebase-memory-pg)

The fleet facade can also run as a **managed cloud service** (the
`codebase-memory-pg` service: MCP facade + central Postgres graph with
per-project row-level security + audited `/publish` ingestion; it ships with
Terraform for Cloud Run, a private Cloud SQL instance and an optional
LB/WAF edge — see that repository's README/RUNBOOK to deploy it).
Client-side configuration:

```json
{
  "mcpServers": {
    "cbm-<name>": {
      "type": "http",
      "url": "https://<your-service-url>/mcp/<fleet-project-id>",
      "headers": {
        "X-Serverless-Authorization": "Bearer <google-id-token>",
        "X-Flota-Authorization": "Bearer <google-id-token>"
      }
    }
  }
}
```

Things that WILL bite you if skipped:

- **Do not put the application token in `Authorization`.** When the service
  sits behind Cloud Run IAM, the platform consumes the `Authorization`
  header for its own access check and **strips the token signature** before
  the request reaches the container — the facade would then reject it
  ("could not verify token signature"). Send the platform token in
  `X-Serverless-Authorization` and the application token in
  `X-Flota-Authorization` (the facade gives it precedence; plain
  `Authorization` still works for deployments without a platform auth hop,
  e.g. the local gateway).
- **Audience matters.** Mint the Google ID token with `audience` equal to
  the configured `FLOTA_AUDIENCE` (normally the service URL); the facade
  verifies signature, issuer and audience — fail-closed.
- **Identities are the token's `sub`.** Fleet memberships and publishers
  (declared via `/admin/apply`) match the ID token's subject; the admin
  allowlist matches subject **or** verified email.
- **Project naming.** The fleet project name must equal the project name
  INSIDE the published artifact (the engine resolves by that internal name);
  a prettier alias will route but resolve to "project not found".

**Remote seeding** (no direct DB access — the instance is private):
1. `POST /admin/apply` (admin identity) declaring tenant, project,
   memberships (readers) and publishers.
2. Build the sync bundle (graph artifact + source blobs + git context; the
   bundle builder runs a secret scan and excludes findings) and upload it to
   the service's staging bucket.
3. `POST /publish` with `{project, bundle_uri, cbm_version, sha256}` —
   transactional, idempotent and audited (metadata-only) in the fleet's
   audit log.

## Which mode am I in?

- `list_projects()` works and `index_repository` is offered → **Mode A**.
- Write tools return `-32601 ... no equivalent in the fleet graph` → **Mode B**.

## If indexing is unavailable

Onboarding does **not** block on the graph. `/repo-add` records "indexing
pending" and the rest of the pipeline (registry, per-repo CLAUDE.md, as-is map,
context packs, architecture document) proceeds from static analysis. Index later
when the engine/fleet is reachable.
