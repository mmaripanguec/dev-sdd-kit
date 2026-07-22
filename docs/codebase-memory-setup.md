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

1. Seed the repositories into the fleet graph with the fleet tooling, e.g.:

   ```bash
   run_local.py seed --repo repos/<name> [--repo repos/<other> ...]
   run_local.py list        # confirm the projects are present
   ```

2. Point the workspace at the seeded project(s). Create/adjust a workspace
   `.mcp.json` with one HTTP MCP entry per project (the URL selects the project;
   the token is your fleet dev token):

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

3. Keep `.mcp.json` out of version control — it holds machine-specific paths and
   a token. Add it to `.gitignore`.

Re-seed after structural code changes (new modules, endpoints, migrations);
the graph does not refresh itself.

## Which mode am I in?

- `list_projects()` works and `index_repository` is offered → **Mode A**.
- Write tools return `-32601 ... no equivalent in the fleet graph` → **Mode B**.

## If indexing is unavailable

Onboarding does **not** block on the graph. `/repo-add` records "indexing
pending" and the rest of the pipeline (registry, per-repo CLAUDE.md, as-is map,
context packs, architecture document) proceeds from static analysis. Index later
when the engine/fleet is reachable.
