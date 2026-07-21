---
name: as-is
description: Query the repository's real as-is map (modules, dependencies, APIs, data). Use when asked how the application is structured, what depends on what, which APIs exist, or before designing (F5).
allowed-tools: Read Glob Grep
---

## LIVE state (computed now, not persisted)
- Registered repos: !`. scripts/repo-lib.sh 2>/dev/null && registry_repos | tr '\n' ' '`
- Working tree: !`git status --short 2>/dev/null | head -15`
- Latest map seal: !`head -2 knowledge/as-is/INDEX.md 2>/dev/null | tail -1`

## Instructions
1. Compare the seal date with the latest change in the repos
   (`git -C repos/<repo> log -1 --format=%cs`). If the map fell behind,
   WARN that it may be outdated and suggest /as-is-sync before
   architecture decisions.
2. CODE GRAPH FIRST: for fine-grained structure questions (which functions
   exist, who calls whom, call chains, impact of a change)
   use the codebase-memory MCP — search_graph, trace_path, get_architecture,
   get_code_snippet — over the indexed repos (`list_projects` to see
   which ones). If a repo is not indexed, say so and suggest /repo-add or
   index_repository.
3. The markdown map is the persisted, citable backup. Load ONLY the view
   relevant to the question:
   - System overview / which repo does what / who calls whom →
     knowledge/as-is/system.md
   - Structure of ONE repo → knowledge/as-is/<repo>/modules.md
   - Contracts/endpoints of ONE repo → knowledge/as-is/<repo>/api-surface.md
4. Answer citing the source (file and seal, or graph query) —
   traceability always.
5. If the question is about INTENT (why it is this way, where it is heading),
   complement with specs/ and knowledge/decisions/ — the as-is says WHAT
   THERE IS, the ADRs say WHY and the to-be WHAT THERE SHOULD BE. Point out gaps.
