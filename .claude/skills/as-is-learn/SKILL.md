---
name: as-is-learn
description: Analyzes the REAL repos to learn how routes are defined and consumed, writes exact per-repo extractors and regenerates the as-is map. Use when the cross-repo graph comes out empty or incomplete, or when a repo's framework changes.
allowed-tools: Read Glob Grep Write Edit Bash(./scripts/generate-as-is.sh *) Bash(chmod *)
---

Goal: make the graph in knowledge/as-is/system.md reflect the REAL
communication between repos, with evidence from the code — zero assumptions.

## 0. Declared topology
Read the registry (`. scripts/repo-lib.sh && registry_repos` and the
`role`/`entrypoint` fields of repos.yaml): which repos exist and what role
each one declares. The analysis in step 1 is done FOR EACH registered and
cloned repo.

## 1. Investigate with the code in front of you (cite file:line in every finding)
For each repo in the registry, according to its role:
- If it EXPOSES an API (backend, service): where are its endpoints
  registered/defined? (framework, struct table, config file, serverless.yml,
  dynamic handlers, gRPC via .proto, worker with no API — and why the
  generic extractor did not see it).
- If it INTERMEDIATES (proxy/BFF/gateway): how does it define what it exposes
  and how does it call its providers? (HTTP with base URL + literal,
  reverse proxy by prefix/config, gRPC, message queue — the config is more
  faithful than any grep of the code).
- If it CONSUMES (frontend, client): how does it build the URLs to its
  providers? (environment constants + literals, central HTTP service,
  endpoints in json).

## 2. Write the exact extractor for each repo that needs it
- Create scripts/as-is.d/<repo>.sh (executable) following the contract in that
  folder's README. In comments: the evidence (files:lines) justifying
  each pattern. Shell compatible with bash 3.2: ${var} with braces, ASCII only.
- If the communication is gRPC: derive logical "routes" from the
  services/methods in the .proto (format /grpc/Service/Method) so the graph
  can represent it.
- If the proxy routes by config: read THAT config file and emit its
  prefixes/paths — the config is more faithful than any grep of the code.

## 3. Verify against reality, not against the script
- Run ./scripts/generate-as-is.sh and review system.md.
- Check every arrow (and every absence) against what was seen in step 1.
  An arrow without evidence gets investigated; an expected absence (e.g. worker
  with no API) gets documented in the repo's api-surface.md via the extractor.
- Run ./scripts/generate-as-is.sh --check (it must end up green).

## 4. Wrap up
- Summary: route mechanism per repo (with citations), resulting arrows,
  known limitations.
- Remember to commit: knowledge/as-is/ + scripts/as-is.d/ to the workspace.
Do NOT modify code in the repos. Do NOT invent routes without evidence.
