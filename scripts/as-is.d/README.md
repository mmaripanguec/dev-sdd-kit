# Per-repository route extractors

If the generic extractor in `generate-as-is.sh` does not capture a repo's
routes (unusual framework, routes in config, gRPC), an EXACT extractor is
written here:

- Name: `<repo-name>.sh` (e.g. `homebanking-pwa-proxy.sh`), executable.
- Contract: it receives the repo path as `$1`; prints one route per line
  in the format `/segment[/...]`.
- Who writes them: the `/as-is-learn` skill (Claude Code analyzes the real
  code and leaves the extractor here with the evidence cited in comments).
- They are committed to the workspace: they are system knowledge.
