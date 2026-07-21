# Per-system assertion suites

One `<system>.sh` suite per system with context packs. They are seeded by
`/repo-map` and `/system-map` when generating each pack, and extended by
every later correction (rule: verifiable correction => assertion).

Format (they are executed with `source` from `scripts/assertions.sh`, which
provides `afirmar` and the functions from `repo-lib.sh`):

```bash
# <system>.sh - claims of the <prefix>-* packs
afirmar "the proxy exposes N routes in handler.go" 45 \
  "grep -c 'HandleFunc' repos/mi-proxy/internal/handlers/handler.go"
afirmar "the core does NOT know about JWT" 0 \
  "grep -ril jwt repos/mi-core/src | wc -l"
```

- `<expected>` is compared against the command's output with spaces removed.
- ALWAYS use `repos/<name>/` paths (they also work for linked snapshots)
  and read-only commands (grep/find/wc).
