---
name: context-report
description: Generates the CONTEXT DOCUMENTATION of a repository — the maximum-detail application architecture & context report (arc42 + C4 + 42010 per docs/architecture-documentation-standard.md) that lets agents and humans work on the repo without re-reading its code. Use when asked to "generate the context/architecture documentation of <repo>", to onboard a new repo after /repo-add, or to refresh an existing report (--update). Output: knowledge/architecture/<repo>.md + .html, committee-reviewed, with file:line evidence and a business-flow traceability matrix.
argument-hint: "<repo-name> [--update]"
---

## Objective

Produce the **context documentation** of repository `$0`:
`knowledge/architecture/<repo>.md` (agent-facing source) + `.html` (human
twin, corporate template). The document must make it possible to answer
questions about the repo **without re-reading its code** (the workspace's
documentation-first policy). Nothing else: this skill does not open specs,
does not remediate findings and does not deploy — findings are recorded as
risks and stop there.

Prerequisite: the repo is cloned under `repos/` (new repo → `/repo-add`
first, which also indexes it into the codebase-memory graph).

## Process

### F1 · Collection (parallel, evidence-first)
1. **Two read-only miner agents** over `repos/$0`, output = structured data
   with `file:line` anchors relative to the repo:
   - *Integration/config*: consumed API domains/endpoints (exact count +
     anchor + usage count), environments and where security flags REALLY
     live, exact dependency versions, native plugins/extensions from ALL
     sources (in-repo, manifest, package manager, git refs), auth/crypto
     implementation, HTTP interceptors/middleware.
   - *Structure/navigation*: full routing (routes + lazy modules + guards),
     module counts by folder, guard taxonomy, the REALITY of local storage
     (key by key), step-by-step traces of the critical flows (entry/login +
     one main business flow) ready for sequence diagrams, analytics and
     error handling.
2. **Graph (codebase-memory MCP)**: `get_architecture` (overview, clusters,
   routes, entry_points) and `query_graph` (counts, top complexity).
   **Reconcile every count graph ↔ repo, stating the scope** (files ≠
   classes ≠ importers — mismatched scopes create phantom discrepancies).
3. **Obsolescence**: WebSearch the EOL status of the frameworks, the
   Dockerfile base image and the security-relevant libraries; record the
   lockfile situation.

### F2 · Document (100% of the standard)
Instantiate the arc42 skeleton (`templates/knowledge-architecture.md`) with
EVERYTHING `docs/architecture-documentation-standard.md` §3 requires:
42010 front-matter (seals + pace_layer) · Goals/**Non-Goals** · requirements
table · C4 L1 + **valid CML context map** (every consumed domain assigned to
a bounded context; be honest about ACL violations) · strategy with
trade-offs · C4 **L2 and L3** · Information view (complete key-by-key storage
inventory, data-at-rest verdict) · Integration view · TOGAF matrices
(function ↔ role from the real guards) · **business-flow matrix** (below) ·
**end-to-end view** (below) · ≥2 **sequence diagrams** anchored per step ·
deployment (anchor who serves the build) · operational view · crosscutting ·
**enriched ADRs** (Status/Confidence/Traces/Options/Decision/Consequences;
append-only) · **numbered verifiable quality scenarios** (failing ones are
declared RED/AMBER, never hidden) · risks with TOGAF gap analysis and
pace-layer · glossary · annexes A (full inventories), B (dependencies + EOL
with sources), C (method + committee record), D (traceability matrix),
**E (repository file structure)**. Close with the Zachman W5H checklist.

**Annex E — repository file structure** (proven format):
- E.1: repo-root tree via `scripts/repo-tree.sh <repo> 2` (tracked files
  only, recursive per-directory counts).
- E.2: first level of the source directory
  (`scripts/repo-tree.sh <repo>/src... 1`) — do NOT go deeper: at depth 2 a
  source tree explodes into hundreds of lines.
- E.3: **annotation table** `| Directory | Files | Role | Section |` mapping
  every relevant directory to the document's building blocks.
- Mine the structure for findings: it exposes debt no other view shows
  (loose SQL migration scripts with no migration engine, deprecated k8s
  trees living next to current ones, tracked tool residues) — each finding
  gets recorded toward the risks section.
- **System-doc counterpart**: derived trees are injected only by the
  generator (`{{FILE_TREES}}` → §5.2.1); curated annotations for sibling
  repos belong in the system narrative
  (`knowledge/architecture/<system>.narrative.md`, BUILDING_BLOCKS section).
- **E.4 (sibling repos)**: when the application report is consumed as a
  standalone document, also include an E.4 section with the tree +
  annotation table of the sibling repos in the end-to-end flow, explicitly
  marking the system doc as the canonical source — standalone completeness
  at the cost of that declared copy.

**Business-flow matrix (§5.6)** — one row per functional flow:
UI route(s) → front module/directory → service (anchor) → consumed
domains/APIs → **upstream service route → upstream** (the backend side comes
from ITS architecture document; cite both). Include transversal rows
(anti-fraud, audit) when they exist.

**End-to-end view (§6.3)** — one mermaid diagram showing a SINGLE business
request crossing the whole chain (client → front components →
interceptor/crypto → gateway/proxy routes → upstreams → audit trail),
color-coded with the template's semantic palette (front=accent, gateway=gw,
core=core, external=bus, data=seg), plus a **hop table**: what each hop adds
or verifies, with an anchor.

### F3 · Review committee (mandatory before publishing)
Two adversarial reviewer agents in parallel (roles from `.claude/agents/`):
- **architecture**: standard compliance section by section, internal
  coherence and coherence against the system doc / diagram baseline, CML
  validity, ADR form, mermaid syntax. Verdict FIT FOR GATE / DO NOT PASS.
- **quality**: sample ≥15 anchors against the repo (exact / approximate /
  false), try to REFUTE every security claim, re-verify every count and
  version.
Apply ALL findings (in the doc, and in the system doc or the diagram
baseline when they contradict each other — same gate). Committee record goes
into Annex C. Final approval: the human gate.

### F4 · Publication
1. HTML twin with the corporate template:
   `python3 scripts/app-architecture-html.py <repo>` (uses
   `templates/knowledge-architecture-app.html` — palette, typography, header
   with provenance box, figure styling).
1b. If the system narrative changed (structure annotations, cross-doc
   corrections): regenerate the system document with
   `./scripts/generate-architecture.sh` (rebuilds md+html and injects fresh
   §5.2.1 trees).
2. If the diagram baseline changed: sync the YAML source + derived
   projections and validate their syntax.
3. `scripts/assertions.sh <system>` · `scripts/freshness.sh check` · one
   commit (Conventional Commits).

### `--update` mode (refresh on a new seal)
Diff the new commit against the sealed one; re-mine only the affected areas;
re-run the committee only if substantive sections changed; always bump
`verificado:` and the seals. Accepted ADRs are never edited — supersede them.

## Non-negotiables (hard-won gotchas — do not skip)

- Read the standard BEFORE writing: a partial instantiation will not pass
  the committee.
- Documentation-first, but **re-derive every number inherited from another
  document** — inherited counts have proven wrong on re-verification.
- Every claim carries a `file:line` anchor or a reproducible query.
- Security claims ("no data at rest", "token never persisted") get
  **adversarial refutation** with an exhaustive counterexample hunt, not a
  happy-path grep — first passes have missed persisted financial data and
  native credential stores.
- Graph labels lie at cluster level: a top node inside a vendored
  plugin/dependency is NOT an app component — verify component claims in the
  app's own source before drawing them.
